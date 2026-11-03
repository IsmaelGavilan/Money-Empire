class_name BusinessCatalog
extends RefCounted
## Validated static content, not runtime ownership. All currency is decimal text.
var rows: Array[Dictionary] = []
var districts: Array = []
var settings: Dictionary = {}

static func load_default() -> BusinessCatalog:
	var file := FileAccess.open("res://data/businesses.json", FileAccess.READ)
	return from_data(JSON.parse_string(file.get_as_text())) if file != null else null

static func from_data(data: Variant) -> BusinessCatalog:
	if not data is Dictionary or data.get("schema_version") != 1:
		return null
	if not data.get("businesses") is Array or data.businesses.size() != 40:
		return null
	if not data.get("districts") is Array or data.districts.size() != 4:
		return null
	for title in data.districts:
		if not title is String or title.is_empty():
			return null
	var settings_data: Variant = data.get("settings")
	if not settings_data is Dictionary:
		return null
	for field in ["max_step_ms", "min_cycle_ms", "shared_dividend_divisor", "milestone_every", "milestone_reward_divisor", "driver_max_frame_ms"]:
		if not EconomyCatalog._integer(settings_data.get(field), 1, 60000):
			return null
	if int(settings_data.max_step_ms) > 60000 or int(settings_data.min_cycle_ms) < 1000 or int(settings_data.milestone_every) > 40 or int(settings_data.driver_max_frame_ms) > 1000:
		return null
	if int(settings_data.shared_dividend_divisor) > BigMoney.MAX_SMALL / 40 or int(settings_data.driver_max_frame_ms) > int(settings_data.max_step_ms):
		return null
	var catalog := BusinessCatalog.new()
	catalog.settings = settings_data.duplicate(true)
	catalog.districts = data.districts.duplicate()
	var ids: Dictionary = {}
	var placements: Dictionary = {}
	var previous_price := BigMoney.parse("0")
	for index in data.businesses.size():
		var row: Variant = data.businesses[index]
		if not row is Dictionary:
			return null
		for field in ["id", "name_es", "description_es"]:
			if not row.get(field) is String or row[field].is_empty():
				return null
		if ids.has(row.id) or row.get("order") != index + 1 or row.get("district") != index / 10:
			return null
		ids[row.id] = true
		for field in ["price", "base_payout", "production_upgrade_cost", "speed_upgrade_cost", "automation_cost"]:
			var amount := EconomyCatalog._money(row.get(field))
			if amount == null or amount.decimal() == "0":
				return null
		var price := BigMoney.parse(row.price)
		if price.compare(previous_price) <= 0:
			return null
		previous_price = price
		if not EconomyCatalog._integer(row.get("cycle_ms"), int(settings_data.min_cycle_ms), 60000):
			return null
		for field in ["max_production_level", "max_speed_level"]:
			if not EconomyCatalog._integer(row.get(field), 1, 10):
				return null
		for field in ["production_factor", "upgrade_cost_growth"]:
			if not EconomyCatalog._integer(row.get(field), 2, 100):
				return null
		var visual: Variant = row.get("visual")
		if not visual is Dictionary:
			return null
		for field in ["tint", "roof_tint"]:
			if not visual.get(field) is String or not Color.html_is_valid(visual[field]):
				return null
		if not visual.get("silhouette") in ["shop", "factory", "tower", "dome"]:
			return null
		for field in ["footprint", "district_slot"]:
			if not visual.get(field) is Array or visual[field].size() != 2:
				return null
			for number in visual[field]:
				if not EconomyCatalog._integer(number, 0 if field == "district_slot" else 1, 10):
					return null
		var placement := "%d:%d:%d" % [int(row.district), int(visual.district_slot[0]), int(visual.district_slot[1])]
		if placements.has(placement):
			return null
		placements[placement] = true
		catalog.rows.append(row.duplicate(true))
	return catalog
