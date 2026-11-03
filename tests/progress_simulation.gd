extends SceneTree
## Real domain services, no free money. Policy controls choices, never formula results.
var clock_ms: int = 0
var wallet: EconomyService
var businesses: BusinessService
var rows: Array[Dictionary] = []
var click_rows: Dictionary = {}
var purchases: Array[Dictionary] = []
var output_path: String = "user://progress-simulation.json"
var clicks_per_second: int = 2
var investment_horizon: int = 180
var max_seconds: int = 18000
var error_count: int = 0
var last_action: int = 0
var longest_action_gap: int = 0
var action_count: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _eligible(cost: BigMoney, gain_milli: BigMoney, next_price: BigMoney, automated: bool = false) -> bool:
	if cost == null or cost.compare(wallet.get_balance()) > 0 or cost.multiply_small(4).compare(next_price) >= 0:
		return false
	if automated:
		return true
	return gain_milli != null and gain_milli.multiply_small(investment_horizon).compare(cost.multiply_small(1000)) >= 0

func _acted(second: int) -> void:
	longest_action_gap = maxi(longest_action_gap, second - last_action)
	last_action = second
	action_count += 1

func _record_purchase(second: int) -> void:
	var count := businesses.owned_count()
	var gap := second - int(purchases[-1].second) if not purchases.is_empty() else second
	purchases.append({"business": count, "name": rows[count - 1].name_es, "second": second,
		"gap_seconds": gap, "price": rows[count - 1].price,
		"balance": wallet.get_balance().decimal(), "automatic_rate_milli": businesses.get_auto_rate_milli().decimal()})
	_acted(second)

func _invest(second: int) -> void:
	for attempt in 250:
		var count := businesses.owned_count()
		if count == 40:
			return
		var next_price := BigMoney.parse(rows[count].price)
		if wallet.get_balance().compare(next_price) >= 0:
			if businesses.buy(count) != OK:
				error_count += 1
				return
			_record_purchase(second)
			continue
		var candidates: Array[Dictionary] = []
		for kind in ["power", "multiplier"]:
			var cost := wallet.get_cost(kind)
			var gain := wallet.get_click_benefit().multiply_small(int(click_rows[kind].factor) - 1) if kind == "multiplier" else BigMoney.parse(click_rows[kind].amount)
			if kind == "power":
				for repetition in wallet.get_level("multiplier"):
					gain = gain.multiply_small(int(click_rows.multiplier.factor))
			gain = gain.multiply_small(clicks_per_second * 1000)
			if _eligible(cost, gain, next_price):
				candidates.append({"kind": kind, "index": -1, "cost": cost})
		for index in count:
			var state := businesses.get_state(index)
			var row := rows[index]
			var contract_cost := BigMoney.parse(row.automation_cost)
			if not state.automated and _eligible(contract_cost, null, next_price, true):
				candidates.append({"kind": "auto", "index": index, "cost": contract_cost})
			for kind in ["production", "speed"]:
				var cost := businesses.get_upgrade_cost(index, kind)
				var gain := businesses.get_upgrade_rate_gain_milli(index, kind)
				if _eligible(cost, gain, next_price):
					candidates.append({"kind": kind, "index": index, "cost": cost})
		if candidates.is_empty():
			return
		# Contracts first, then cheapest eligible upgrade; all comparisons exact.
		var best := candidates[0]
		for candidate in candidates:
			if (candidate.kind == "auto" and best.kind != "auto") or (candidate.kind == best.kind or candidate.kind != "auto" and best.kind != "auto") and candidate.cost.compare(best.cost) < 0:
				best = candidate
		var result: Error
		if best.index == -1:
			result = wallet.purchase(best.kind)
		elif best.kind == "auto":
			result = businesses.automate(best.index)
		else:
			result = businesses.upgrade(best.index, best.kind)
		if result != OK:
			error_count += 1
			return
		_acted(second)
	error_count += 1 # Policy loop guard: an unexpected unlimited purchase loop.

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("output="):
			output_path = argument.trim_prefix("output=")
		elif argument.begins_with("clicks="):
			clicks_per_second = clampi(int(argument.trim_prefix("clicks=")), 1, 10)
		elif argument.begins_with("horizon="):
			investment_horizon = clampi(int(argument.trim_prefix("horizon=")), 30, 600)
	wallet = EconomyService.new(null, func() -> int: return clock_ms)
	for row in wallet.get_upgrades():
		click_rows[row.id] = row
	businesses = BusinessService.new(wallet)
	if not businesses.is_ready():
		push_error("Invalid business catalog")
		quit(1)
		return
	businesses.set_running(true)
	for index in 40:
		rows.append(businesses.get_definition(index))
	var finished_second := -1
	for second in range(max_seconds + 1):
		for click in clicks_per_second:
			clock_ms = second * 1000 + click * (1000 / clicks_per_second)
			if wallet.click() != OK:
				error_count += 1
		if businesses.advance_ms(1000) != OK:
			error_count += 1
		# Active manual collection every two seconds until a contract is bought.
		if second % 2 == 0:
			for index in businesses.owned_count():
				if businesses.get_state(index).ready:
					if businesses.collect(index) != OK:
						error_count += 1
		_invest(second)
		if businesses.owned_count() == 40:
			finished_second = second
			break
	var max_expansion_gap := 0
	var instant_expansions := 0
	for purchase in purchases:
		max_expansion_gap = maxi(max_expansion_gap, purchase.gap_seconds)
		if purchase.gap_seconds == 0:
			instant_expansions += 1
	var total_rate := businesses.get_auto_rate_milli()
	var early_rate := BigMoney.parse("0")
	for index in mini(10, businesses.owned_count()):
		if businesses.get_state(index).automated:
			early_rate = early_rate.add(businesses.get_rate_milli(index))
	var report := {"schema": 1, "clicks_per_second": clicks_per_second, "investment_horizon_seconds": investment_horizon,
		"completed": finished_second >= 0, "completion_second": finished_second, "errors": error_count,
		"owned": businesses.owned_count(), "actions": action_count, "longest_action_gap_seconds": longest_action_gap,
		"max_expansion_gap_seconds": max_expansion_gap, "same_second_expansions": instant_expansions,
		"balance": wallet.get_balance().decimal(), "automatic_rate_milli": total_rate.decimal(),
		"first_district_rate_milli": early_rate.decimal(), "purchases": purchases}
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write simulation report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("PROGRESS SIMULATION: owned=%d seconds=%d errors=%d longest_expansion_gap=%d report=%s" % [businesses.owned_count(), finished_second, error_count, max_expansion_gap, output_path])
	quit(0 if finished_second >= 0 and error_count == 0 else 1)
