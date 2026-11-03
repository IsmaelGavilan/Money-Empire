class_name EconomyCatalog
extends RefCounted
## Validated configuration boundary. No partially accepted catalogues.
var base_click: BigMoney
var click_cooldown_ms: int
var upgrades: Array[Dictionary] = []

static func load_default() -> EconomyCatalog:
	var file := FileAccess.open("res://data/economy.json", FileAccess.READ)
	if file == null:
		return null
	return from_data(JSON.parse_string(file.get_as_text()))

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and value >= minimum and value <= maximum and value == floor(value)

static func _money(value: Variant) -> BigMoney:
	return BigMoney.parse(value) if value is String else null

static func from_data(data: Variant) -> EconomyCatalog:
	if not data is Dictionary or data.get("schema_version") != 1:
		return null
	var base := _money(data.get("base_click"))
	if base == null or base.decimal() == "0" or not _integer(data.get("click_cooldown_ms"), 40, 1000):
		return null
	var rows: Variant = data.get("upgrades")
	if not rows is Array or rows.is_empty() or rows.size() > 20:
		return null
	var catalog := EconomyCatalog.new()
	catalog.base_click = base
	catalog.click_cooldown_ms = int(data.click_cooldown_ms)
	var identifiers: Dictionary = {}
	for row in rows:
		if not row is Dictionary:
			return null
		var id: Variant = row.get("id")
		if not id is String or id.is_empty() or identifiers.has(id) or not row.get("name_es") is String:
			return null
		identifiers[id] = true
		var cost := _money(row.get("base_cost"))
		if cost == null or cost.decimal() == "0":
			return null
		if not _integer(row.get("growth_numerator"), 2, 100) or not _integer(row.get("growth_denominator"), 1, 100) or row.growth_numerator <= row.growth_denominator:
			return null
		if not _integer(row.get("max_level"), 1, 100):
			return null
		var kind: Variant = row.get("kind")
		if kind == "power":
			var amount := _money(row.get("amount"))
			if amount == null or amount.decimal() == "0":
				return null
		elif kind == "multiplier" or kind == "temporary":
			if not _integer(row.get("factor"), 2, 100):
				return null
			if kind == "temporary" and not _integer(row.get("duration_ms"), 100, 600000):
				return null
		else:
			return null
		catalog.upgrades.append(row.duplicate(true))
	return catalog
