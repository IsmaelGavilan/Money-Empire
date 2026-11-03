class_name EconomyService
extends RefCounted
## Domain service: exact currency, transactional mutations, injectable monotonic clock.
signal balance_changed(value: BigMoney)
signal money_earned(amount: BigMoney, source: StringName)
signal money_spent(amount: BigMoney, source: StringName)
signal click_registered(amount: BigMoney, count: int)
signal upgrade_purchased(id: String, level: int)
signal benefit_changed

var _balance := BigMoney.parse("0")
var _catalog: EconomyCatalog
var _clock: Callable
var _levels: Dictionary = {}
var _last_click_ms: int = -1000000
var _click_count: int = 0
var _bonus_id: String = ""
var _bonus_until: int = 0
var _notifying: bool = false

func _init(catalog: EconomyCatalog = null, clock: Callable = Callable()) -> void:
	_catalog = catalog if catalog != null else EconomyCatalog.load_default()
	_clock = clock if clock.is_valid() else func() -> int: return Time.get_ticks_msec()
	if _catalog != null:
		for row in _catalog.upgrades:
			_levels[row.id] = 0

func is_ready() -> bool:
	return _catalog != null

func get_balance() -> BigMoney:
	return BigMoney.parse(_balance.decimal())

func get_click_count() -> int:
	return _click_count

func get_upgrades() -> Array[Dictionary]:
	return _catalog.upgrades.duplicate(true) if is_ready() else []

func get_level(id: String) -> int:
	return _levels.get(id, 0)

func _find(id: String) -> Dictionary:
	for row in get_upgrades():
		if row.id == id:
			return row
	return {}

func get_cost(id: String) -> BigMoney:
	var row := _find(id)
	if row.is_empty() or get_level(id) >= int(row.max_level):
		return null
	var cost := BigMoney.parse(row.base_cost)
	for level in get_level(id):
		cost = cost.multiply_small(int(row.growth_numerator))
		if cost == null:
			return null
		cost = cost.divide_small_ceil(int(row.growth_denominator))
	return cost

func bonus_remaining_ms() -> int:
	return maxi(0, _bonus_until - int(_clock.call())) if not _bonus_id.is_empty() else 0

func get_active_bonus() -> Dictionary:
	return _find(_bonus_id) if bonus_remaining_ms() > 0 else {}

func tick() -> void:
	if _notifying:
		return
	if not _bonus_id.is_empty() and bonus_remaining_ms() == 0:
		_bonus_id = ""
		_notifying = true
		benefit_changed.emit()
		_notifying = false

func _benefit(extra_id: String = "") -> BigMoney:
	if not is_ready():
		return null
	var amount := BigMoney.parse(_catalog.base_click.decimal())
	for row in _catalog.upgrades:
		var level := get_level(row.id) + (1 if row.id == extra_id else 0)
		if row.kind == "power":
			var increase := BigMoney.parse(row.amount).multiply_small(level)
			amount = amount.add(increase)
			if amount == null:
				return null
	for row in _catalog.upgrades:
		if row.kind != "multiplier":
			continue
		var level := get_level(row.id) + (1 if row.id == extra_id else 0)
		for repetition in level:
			amount = amount.multiply_small(int(row.factor))
			if amount == null:
				return null
	var bonus := _find(extra_id)
	if bonus.is_empty() or bonus.kind != "temporary":
		bonus = _find(_bonus_id) if bonus_remaining_ms() > 0 else {}
	if not bonus.is_empty():
		amount = amount.multiply_small(int(bonus.factor))
	return amount

func get_click_benefit() -> BigMoney:
	return _benefit()

func earn(amount: BigMoney, source: StringName = &"external") -> Error:
	if _notifying:
		return ERR_BUSY
	if amount == null or amount.decimal() == "0":
		return ERR_INVALID_PARAMETER
	var next := _balance.add(amount)
	if next == null:
		return ERR_OUT_OF_MEMORY
	_balance = next
	_notifying = true
	balance_changed.emit(get_balance())
	money_earned.emit(BigMoney.parse(amount.decimal()), source)
	_notifying = false
	return OK

func spend(amount: BigMoney, source: StringName = &"external") -> Error:
	if _notifying:
		return ERR_BUSY
	if amount == null or amount.decimal() == "0":
		return ERR_INVALID_PARAMETER
	var next := _balance.subtract(amount)
	if next == null:
		return ERR_UNAVAILABLE
	_balance = next
	_notifying = true
	balance_changed.emit(get_balance())
	money_spent.emit(BigMoney.parse(amount.decimal()), source)
	_notifying = false
	return OK

func click() -> Error:
	if _notifying:
		return ERR_BUSY
	if not is_ready():
		return ERR_UNCONFIGURED
	tick()
	var now := int(_clock.call())
	if now - _last_click_ms < _catalog.click_cooldown_ms:
		return ERR_BUSY
	var amount := get_click_benefit()
	if amount == null:
		return ERR_OUT_OF_MEMORY
	var next := _balance.add(amount)
	if next == null or _click_count == 9223372036854775807:
		return ERR_OUT_OF_MEMORY
	_balance = next
	_last_click_ms = now
	_click_count += 1
	_notifying = true
	balance_changed.emit(get_balance())
	money_earned.emit(BigMoney.parse(amount.decimal()), &"click")
	click_registered.emit(BigMoney.parse(amount.decimal()), _click_count)
	_notifying = false
	return OK

func purchase(id: String) -> Error:
	if _notifying:
		return ERR_BUSY
	tick()
	var row := _find(id)
	if row.is_empty():
		return ERR_INVALID_PARAMETER
	if row.kind == "temporary" and bonus_remaining_ms() > 0:
		return ERR_BUSY
	var cost := get_cost(id)
	if cost == null:
		return ERR_UNAVAILABLE
	var next := _balance.subtract(cost)
	if next == null:
		return ERR_UNAVAILABLE
	# Validate resulting benefit before spending, including bonuses and numeric cap.
	if _benefit(id) == null:
		return ERR_OUT_OF_MEMORY
	_balance = next
	_levels[id] = get_level(id) + 1
	if row.kind == "temporary":
		_bonus_id = id
		_bonus_until = int(_clock.call()) + int(row.duration_ms)
	_notifying = true
	balance_changed.emit(get_balance())
	money_spent.emit(BigMoney.parse(cost.decimal()), &"upgrade")
	upgrade_purchased.emit(id, get_level(id))
	benefit_changed.emit()
	_notifying = false
	return OK

func exchange(cost: BigMoney, credit: BigMoney, source: StringName, commit_state: Callable = Callable()) -> Error:
	# Cross-service transaction: validate money first; commit trusted, synchronous
	# domain state before observers can query it. Callback must not fail or await.
	if _notifying:
		return ERR_BUSY
	if cost == null or credit == null:
		return ERR_INVALID_PARAMETER
	var next := _balance.subtract(cost)
	if next == null:
		return ERR_UNAVAILABLE
	next = next.add(credit)
	if next == null:
		return ERR_OUT_OF_MEMORY
	_notifying = true
	_balance = next
	if commit_state.is_valid():
		commit_state.call()
	balance_changed.emit(get_balance())
	if cost.decimal() != "0":
		money_spent.emit(BigMoney.parse(cost.decimal()), source)
	if credit.decimal() != "0":
		money_earned.emit(BigMoney.parse(credit.decimal()), source)
	_notifying = false
	return OK
