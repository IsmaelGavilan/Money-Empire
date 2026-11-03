class_name BusinessMath
extends RefCounted
## Pure economic formulas shared by gameplay, tests and the progress simulation.
static func payout(row: Dictionary, state: BusinessState, frontier: BigMoney, owned_count: int, settings: Dictionary) -> BigMoney:
	var shared := frontier.divide_small_ceil(maxi(1, owned_count * int(settings.shared_dividend_divisor)))
	var result := BigMoney.parse(row.base_payout).add(shared)
	for level in state.production_level:
		if result == null:
			return null
		result = result.multiply_small(int(row.production_factor))
	return result

static func cycle_ms(row: Dictionary, state: BusinessState, settings: Dictionary) -> int:
	return maxi(int(settings.min_cycle_ms), int(row.cycle_ms) / (state.speed_level + 1))

static func upgrade_cost(row: Dictionary, state: BusinessState, kind: String) -> BigMoney:
	if kind != "production" and kind != "speed":
		return null
	var level: int = state.production_level if kind == "production" else state.speed_level
	var maximum := int(row.max_production_level if kind == "production" else row.max_speed_level)
	if level >= maximum:
		return null
	var result := BigMoney.parse(row.production_upgrade_cost if kind == "production" else row.speed_upgrade_cost)
	for repetition in level:
		result = result.multiply_small(int(row.upgrade_cost_growth))
		if result == null:
			return null
	return result

static func rate_milli(payout_value: BigMoney, cycle: int) -> BigMoney:
	if payout_value == null:
		return null
	var scaled := payout_value.multiply_small(1000000)
	return scaled.divide_small_floor(cycle) if scaled != null else null
