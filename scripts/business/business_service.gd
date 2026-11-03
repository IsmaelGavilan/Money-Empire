class_name BusinessService
extends RefCounted
signal businesses_changed
signal business_purchased(id: String, order: int)
signal business_upgraded(id: String, kind: String, level: int)
signal business_automated(id: String)
signal production_collected(id: String, amount: BigMoney, cycles: int, automatic: bool)
signal expansion_milestone(count: int, reward: BigMoney)

var _wallet: EconomyService
var _catalog: BusinessCatalog
var _states: Array[BusinessState] = []
var _payouts: Array[BigMoney] = []
var _cycles: Array[int] = []
var _auto_rate := BigMoney.parse("0")
var _owned_count: int = 0
var _busy: bool = false
var _running: bool = false

func _init(wallet: EconomyService, catalog: BusinessCatalog = null) -> void:
	_wallet = wallet
	_catalog = catalog if catalog != null else BusinessCatalog.load_default()
	if _catalog != null:
		for row in _catalog.rows:
			_states.append(BusinessState.new())
		_rebuild()

func is_ready() -> bool:
	return _catalog != null and _wallet != null

func set_running(enabled: bool) -> void:
	_running = enabled

func is_running() -> bool:
	return _running

func owned_count() -> int:
	return _owned_count

func get_districts() -> Array:
	return _catalog.districts.duplicate() if is_ready() else []

func _valid(index: int) -> bool:
	return is_ready() and index >= 0 and index < _states.size()

func get_definition(index: int) -> Dictionary:
	return _catalog.rows[index].duplicate(true) if _valid(index) else {}

func get_state(index: int) -> Dictionary:
	if not _valid(index):
		return {}
	var result := _states[index].snapshot()
	result["unlocked"] = index <= _owned_count
	result["ready"] = result.owned and not result.automated and result.elapsed_ms >= _cycles[index]
	return result

func get_payout(index: int) -> BigMoney:
	return BigMoney.parse(_payouts[index].decimal()) if _valid(index) and _payouts[index] != null else null

func get_cycle_ms(index: int) -> int:
	return _cycles[index] if _valid(index) else 0

func get_rate_milli(index: int) -> BigMoney:
	return BusinessMath.rate_milli(get_payout(index), get_cycle_ms(index)) if _valid(index) else null

func get_auto_rate_milli() -> BigMoney:
	return BigMoney.parse(_auto_rate.decimal())

func get_upgrade_rate_gain_milli(index: int, kind: String) -> BigMoney:
	if not _valid(index) or get_upgrade_cost(index, kind) == null:
		return null
	var proposed := BusinessState.new()
	proposed.production_level = _states[index].production_level + (1 if kind == "production" else 0)
	proposed.speed_level = _states[index].speed_level + (1 if kind == "speed" else 0)
	var row: Dictionary = _catalog.rows[index]
	var amount := BusinessMath.payout(row, proposed, _frontier(), _owned_count, _catalog.settings)
	var rate := BusinessMath.rate_milli(amount, BusinessMath.cycle_ms(row, proposed, _catalog.settings))
	return rate.subtract(get_rate_milli(index)) if rate != null else null

func get_upgrade_cost(index: int, kind: String) -> BigMoney:
	return BusinessMath.upgrade_cost(_catalog.rows[index], _states[index], kind) if _valid(index) else null

func _frontier() -> BigMoney:
	return BigMoney.parse(_catalog.rows[maxi(0, _owned_count - 1)].base_payout)

func _rebuild() -> void:
	_payouts.clear()
	_cycles.clear()
	_auto_rate = BigMoney.parse("0")
	for index in _states.size():
		var payout := BusinessMath.payout(_catalog.rows[index], _states[index], _frontier(), _owned_count, _catalog.settings)
		_payouts.append(payout)
		_cycles.append(BusinessMath.cycle_ms(_catalog.rows[index], _states[index], _catalog.settings))
		if _states[index].owned and _states[index].automated and payout != null:
			var rate := BusinessMath.rate_milli(payout, _cycles[index])
			_auto_rate = _auto_rate.add(rate) if _auto_rate != null else null

func _can_expand() -> bool:
	# Preflight the future shared dividend and all upgraded payouts before charging.
	var count := _owned_count + 1
	var frontier := BigMoney.parse(_catalog.rows[_owned_count].base_payout)
	var total := BigMoney.parse("0")
	for index in count:
		var amount := BusinessMath.payout(_catalog.rows[index], _states[index], frontier, count, _catalog.settings)
		var rate := BusinessMath.rate_milli(amount, _cycles[index])
		if amount == null or rate == null:
			return false
		total = total.add(rate)
		if total == null:
			return false
	return true

func buy(index: int) -> Error:
	if _busy:
		return ERR_BUSY
	if not _valid(index):
		return ERR_INVALID_PARAMETER
	if index != _owned_count or _states[index].owned:
		return ERR_UNAVAILABLE
	if not _can_expand():
		return ERR_OUT_OF_MEMORY
	var row: Dictionary = _catalog.rows[index]
	var cost := BigMoney.parse(row.price)
	var milestone := (_owned_count + 1) % int(_catalog.settings.milestone_every) == 0
	var reward := cost.divide_small_floor(int(_catalog.settings.milestone_reward_divisor)) if milestone else BigMoney.parse("0")
	_busy = true
	var result := _wallet.exchange(cost, reward, &"business_purchase", func():
		_states[index].owned = true
		_owned_count += 1
		_rebuild())
	if result == OK:
		business_purchased.emit(row.id, _owned_count)
		if milestone:
			expansion_milestone.emit(_owned_count, BigMoney.parse(reward.decimal()))
		businesses_changed.emit()
	_busy = false
	return result

func automate(index: int) -> Error:
	if _busy:
		return ERR_BUSY
	if not _valid(index):
		return ERR_INVALID_PARAMETER
	if not _states[index].owned or _states[index].automated:
		return ERR_UNAVAILABLE
	if _auto_rate.add(get_rate_milli(index)) == null:
		return ERR_OUT_OF_MEMORY
	_busy = true
	var row: Dictionary = _catalog.rows[index]
	var result := _wallet.exchange(BigMoney.parse(row.automation_cost), BigMoney.parse("0"), &"business_automation", func():
		_states[index].automated = true
		_rebuild())
	if result == OK:
		business_automated.emit(row.id)
		businesses_changed.emit()
	_busy = false
	return result

func upgrade(index: int, kind: String) -> Error:
	if _busy:
		return ERR_BUSY
	if not _valid(index) or not kind in ["production", "speed"]:
		return ERR_INVALID_PARAMETER
	if not _states[index].owned:
		return ERR_UNAVAILABLE
	var cost := get_upgrade_cost(index, kind)
	if cost == null:
		return ERR_UNAVAILABLE
	# Check the proposed production and rate without mutating the actual state.
	var proposed := BusinessState.new()
	proposed.production_level = _states[index].production_level + (1 if kind == "production" else 0)
	proposed.speed_level = _states[index].speed_level + (1 if kind == "speed" else 0)
	var row: Dictionary = _catalog.rows[index]
	var amount := BusinessMath.payout(row, proposed, _frontier(), _owned_count, _catalog.settings)
	var rate := BusinessMath.rate_milli(amount, BusinessMath.cycle_ms(row, proposed, _catalog.settings))
	if amount == null or rate == null or _auto_rate.add(rate) == null:
		return ERR_OUT_OF_MEMORY
	_busy = true
	var result := _wallet.exchange(cost, BigMoney.parse("0"), &"business_upgrade", func():
		_states[index].production_level = proposed.production_level
		_states[index].speed_level = proposed.speed_level
		_states[index].elapsed_ms = mini(_states[index].elapsed_ms, BusinessMath.cycle_ms(row, proposed, _catalog.settings))
		_rebuild())
	if result == OK:
		business_upgraded.emit(row.id, kind, proposed.production_level if kind == "production" else proposed.speed_level)
		businesses_changed.emit()
	_busy = false
	return result

func collect(index: int) -> Error:
	if _busy:
		return ERR_BUSY
	if not _valid(index):
		return ERR_INVALID_PARAMETER
	if not get_state(index).ready:
		return ERR_UNAVAILABLE
	var amount := get_payout(index)
	if amount == null:
		return ERR_OUT_OF_MEMORY
	_busy = true
	var result := _wallet.exchange(BigMoney.parse("0"), amount, &"business_manual", func(): _states[index].elapsed_ms = 0)
	if result == OK:
		production_collected.emit(_catalog.rows[index].id, BigMoney.parse(amount.decimal()), 1, false)
	_busy = false
	return result

func advance_ms(milliseconds: int) -> Error:
	if _busy:
		return ERR_BUSY
	if not is_ready():
		return ERR_UNCONFIGURED
	if not _running:
		return ERR_UNAVAILABLE
	if milliseconds < 0 or milliseconds > int(_catalog.settings.max_step_ms):
		return ERR_INVALID_PARAMETER
	var elapsed: Array[int] = []
	var rewards: Array[Dictionary] = []
	var total := BigMoney.parse("0")
	for index in _owned_count:
		var time := _states[index].elapsed_ms + milliseconds
		if _states[index].automated:
			var completed: int = time / _cycles[index]
			elapsed.append(time % _cycles[index])
			if completed > 0:
				var amount := _payouts[index].multiply_small(completed) if _payouts[index] != null else null
				if amount == null:
					return ERR_OUT_OF_MEMORY
				total = total.add(amount)
				if total == null:
					return ERR_OUT_OF_MEMORY
				rewards.append({"index": index, "amount": amount, "cycles": completed})
		else:
			elapsed.append(mini(time, _cycles[index]))
	var commit := func():
		for index in _owned_count:
			_states[index].elapsed_ms = elapsed[index]
	_busy = true
	var result: Error = OK
	if total.decimal() == "0":
		commit.call()
	else:
		result = _wallet.exchange(BigMoney.parse("0"), total, &"business_automatic", commit)
	if result == OK:
		for reward in rewards:
			production_collected.emit(_catalog.rows[reward.index].id, BigMoney.parse(reward.amount.decimal()), reward.cycles, true)
	_busy = false
	return result

func get_driver_max_frame_ms() -> int:
	return int(_catalog.settings.driver_max_frame_ms) if is_ready() else 0
