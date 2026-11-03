extends SceneTree
var checks: int = 0
var failures: int = 0
var wallet: EconomyService
var businesses: BusinessService
var statistics: BusinessStatistics
var events: Dictionary = {"changes": 0, "wallet": 0}

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func same(value: BigMoney, expected: String, message: String) -> void:
	check(value != null and value.decimal() == expected, message)

func fresh() -> void:
	wallet = EconomyService.new()
	businesses = BusinessService.new(wallet)
	statistics = BusinessStatistics.new()
	statistics.attach(businesses)

func _data() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/businesses.json"))
	var catalog := BusinessCatalog.from_data(data)
	check(catalog != null and catalog.rows.size() == 40, "All forty definitions loaded")
	var counts := [0, 0, 0, 0]
	var previous := BigMoney.parse("0")
	for index in 40:
		var row: Dictionary = catalog.rows[index]
		counts[int(row.district)] += 1
		check(row.order == index + 1, "Fixed business ordering")
		check(not row.name_es.is_empty() and not row.description_es.is_empty(), "Business name and description")
		var price := BigMoney.parse(row.price)
		check(price.compare(previous) > 0, "Strictly growing price")
		if index > 0:
			check(price.compare(previous.multiply_small(4)) == 0, "Configured price curve times four")
		check(BigMoney.parse(row.base_payout).decimal() != "0", "Positive production")
		check(Color.html_is_valid(row.visual.tint), "Valid visual tint")
		check(int(row.visual.district_slot[0]) == index % 5 and int(row.visual.district_slot[1]) == (index % 10) / 5, "Unique district slot")
		previous = price
	check(counts == [10, 10, 10, 10], "Ten businesses per district")
	check(catalog.rows[18].name_es == "Casino de Monedas de Caramelo", "Humorous casino in correct position")
	check(catalog.rows[18].description_es.contains("sin apuestas"), "Casino has deterministic production description")
	for field in ["price", "base_payout", "cycle_ms", "visual", "production_factor"]:
		var bad := data.duplicate(true)
		bad.businesses[0].erase(field)
		check(BusinessCatalog.from_data(bad) == null, "Reject incomplete business definition")
	for value in ["-1", "NaN", "Infinity", "1.5", "0"]:
		var bad := data.duplicate(true)
		bad.businesses[0].price = value
		check(BusinessCatalog.from_data(bad) == null, "Reject invalid money definition")
	var bad := data.duplicate(true)
	bad.businesses[1].id = bad.businesses[0].id
	check(BusinessCatalog.from_data(bad) == null, "Reject duplicate business IDs")
	bad = data.duplicate(true)
	bad.businesses.pop_back()
	check(BusinessCatalog.from_data(bad) == null, "Reject missing fortieth business")
	bad = data.duplicate(true)
	bad.businesses[10].district = 0
	check(BusinessCatalog.from_data(bad) == null, "Reject wrong district order")
	bad = data.duplicate(true)
	bad.businesses[0].visual.tint = "wrong"
	check(BusinessCatalog.from_data(bad) == null, "Reject invalid visuals")
	bad = data.duplicate(true)
	bad.businesses[1].visual.district_slot = bad.businesses[0].visual.district_slot.duplicate()
	check(BusinessCatalog.from_data(bad) == null, "Reject overlapping district slots")
	bad = data.duplicate(true)
	bad.settings.min_cycle_ms = 0
	check(BusinessCatalog.from_data(bad) == null, "Reject unsafe timing")
	same(BigMoney.parse("5").divide_small_floor(2), "2", "Exact floor helper")
	check(MoneyFormat.rate(BigMoney.parse("333")) == "0,333 /s", "Fractional IPS visible")
	check(MoneyFormat.rate(BigMoney.parse("1000")) == "1 /s", "Integral IPS visible")
	check(MoneyFormat.rate(BigMoney.parse("1250500"), "en") == "1.25K /s", "Large rate formatting")

func _all_businesses() -> void:
	fresh()
	check(businesses.is_ready(), "Business service configured")
	check(businesses.get_districts().size() == 4, "Four districts")
	same(wallet.get_balance(), "0", "Zero initial money")
	check(businesses.get_state(0).unlocked and not businesses.get_state(1).unlocked, "Only first unlocked initially")
	check(businesses.buy(0) == ERR_UNAVAILABLE, "Unaffordable first purchase rejected")
	check(businesses.buy(1) == ERR_UNAVAILABLE, "Locked purchase rejected")
	check(businesses.automate(0) == ERR_UNAVAILABLE, "No contract before ownership")
	check(businesses.upgrade(0, "production") == ERR_UNAVAILABLE, "No upgrade before ownership")
	check(businesses.get_definition(-1).is_empty() and businesses.get_state(40).is_empty(), "Bounds checks")
	check(businesses.buy(-1) == ERR_INVALID_PARAMETER and businesses.collect(40) == ERR_INVALID_PARAMETER, "Invalid indices rejected")
	wallet.earn(BigMoney.parse("1" + "0".repeat(50)))
	var early_payout := businesses.get_payout(0)
	for index in 40:
		var row := businesses.get_definition(index)
		check(businesses.get_state(index).unlocked, "Next fixed business unlocked")
		if index < 39:
			check(businesses.buy(index + 1) == ERR_UNAVAILABLE, "Cannot skip next business")
		var expected := wallet.get_balance().subtract(BigMoney.parse(row.price))
		if (index + 1) % 5 == 0:
			expected = expected.add(BigMoney.parse(row.price).divide_small_floor(2))
		check(businesses.buy(index) == OK, "Purchase business %d" % (index + 1))
		check(wallet.get_balance().compare(expected) == 0, "Exact cost and expansion reward")
		check(businesses.get_state(index).owned and businesses.get_state(index).level == 1, "Ownership and base level")
		var before := wallet.get_balance().decimal()
		check(businesses.buy(index) == ERR_UNAVAILABLE and wallet.get_balance().decimal() == before, "No duplicate charge or milestone")
		var initial := businesses.get_payout(index)
		for level in int(row.max_production_level):
			var cost := businesses.get_upgrade_cost(index, "production")
			var expected_cost := BigMoney.parse(row.production_upgrade_cost)
			for repetition in level:
				expected_cost = expected_cost.multiply_small(int(row.upgrade_cost_growth))
			check(cost.compare(expected_cost) == 0, "Production cost progression")
			before = wallet.get_balance().decimal()
			check(businesses.upgrade(index, "production") == OK, "Production upgrade")
			check(wallet.get_balance().compare(BigMoney.parse(before).subtract(cost)) == 0, "Upgrade exact spending")
		check(businesses.get_payout(index).compare(initial.multiply_small(8)) == 0, "Three production tiers times eight")
		check(businesses.upgrade(index, "production") == ERR_UNAVAILABLE, "Production level cap")
		for level in int(row.max_speed_level):
			var cost := businesses.get_upgrade_cost(index, "speed")
			before = wallet.get_balance().decimal()
			check(businesses.upgrade(index, "speed") == OK, "Speed upgrade")
			check(wallet.get_balance().compare(BigMoney.parse(before).subtract(cost)) == 0, "Speed exact spending")
		check(businesses.get_cycle_ms(index) == 2000, "Configured speed cycle 6 to 2 seconds")
		check(businesses.upgrade(index, "speed") == ERR_UNAVAILABLE, "Speed level cap")
		before = wallet.get_balance().decimal()
		check(businesses.automate(index) == OK, "Contract purchased")
		check(wallet.get_balance().compare(BigMoney.parse(before).subtract(BigMoney.parse(row.automation_cost))) == 0, "Contract exact spending")
		check(businesses.get_state(index).automated, "Automation state")
		before = wallet.get_balance().decimal()
		check(businesses.automate(index) == ERR_UNAVAILABLE and wallet.get_balance().decimal() == before, "No double contract charge")
	check(businesses.owned_count() == 40, "Own all forty businesses")
	check(statistics.purchased == 40 and statistics.contracts == 40 and statistics.upgrades == 200, "Independent statistics event consumer")
	check(statistics.milestones == [5, 10, 15, 20, 25, 30, 35, 40], "Eight single expansion milestones")
	check(businesses.get_payout(0).compare(early_payout.multiply_small(1000)) > 0, "First business benefits from later expansion")
	businesses.set_running(true)
	var total := BigMoney.parse("0")
	for index in 40:
		total = total.add(businesses.get_payout(index))
	var before_value := wallet.get_balance()
	check(businesses.advance_ms(1999) == OK, "No cycle before exact boundary")
	check(wallet.get_balance().compare(before_value) == 0, "No premature production")
	check(businesses.advance_ms(1) == OK, "Complete all forty cycles")
	check(wallet.get_balance().compare(before_value.add(total)) == 0, "Exact production from all forty")
	check(statistics.automatic_cycles == 40, "Forty automated production events")
	check(statistics.income.compare(total) == 0, "Statistics exact income")
	before_value = wallet.get_balance()
	check(businesses.advance_ms(60000) == OK, "Batch production")
	check(wallet.get_balance().compare(before_value.add(total.multiply_small(30))) == 0, "No cycles lost in batch")
	check(statistics.automatic_cycles == 1240, "Batch event cycle counts")

func _timing_and_atomicity() -> void:
	fresh()
	wallet.earn(BigMoney.parse("10000"))
	businesses.buy(0)
	check(businesses.advance_ms(6000) == ERR_UNAVAILABLE, "No production before active session")
	businesses.set_running(true)
	check(businesses.advance_ms(60001) == ERR_INVALID_PARAMETER and businesses.advance_ms(-1) == ERR_INVALID_PARAMETER, "Reject invalid time steps")
	var before := wallet.get_balance().decimal()
	check(businesses.advance_ms(60000) == OK, "Manual business fills one cycle")
	check(wallet.get_balance().decimal() == before and businesses.get_state(0).ready, "Manual production waits for collection")
	check(businesses.collect(0) == OK, "Manual collection")
	same(wallet.get_balance(), BigMoney.parse(before).add(businesses.get_payout(0)).decimal(), "One manual payout only, no backlog")
	check(businesses.collect(0) == ERR_UNAVAILABLE, "Duplicate manual collection rejected")
	check(statistics.manual_cycles == 1, "Manual statistics")
	businesses.advance_ms(3000)
	var partial: int = businesses.get_state(0).elapsed_ms
	businesses.set_running(false)
	before = wallet.get_balance().decimal()
	check(businesses.advance_ms(60000) == ERR_UNAVAILABLE, "Paused production rejected")
	check(businesses.get_state(0).elapsed_ms == partial and wallet.get_balance().decimal() == before, "Pause retains partial cycle, no money")
	businesses.set_running(true)
	businesses.automate(0)
	before = wallet.get_balance().decimal()
	businesses.advance_ms(3000)
	check(wallet.get_balance().compare(BigMoney.parse(before).add(businesses.get_payout(0))) == 0, "Partial cycle survives contract purchase")
	var restarted := BusinessService.new(EconomyService.new())
	check(restarted.owned_count() == 0 and not restarted.is_running(), "New process/session has no offline state")
	# Chunking invariance: same exact time, same income and remainder.
	var wallet_a := EconomyService.new()
	var a := BusinessService.new(wallet_a)
	var wallet_b := EconomyService.new()
	var b := BusinessService.new(wallet_b)
	for service in [a, b]:
		var account: EconomyService = wallet_a if service == a else wallet_b
		account.earn(BigMoney.parse("1000"))
		service.buy(0)
		service.automate(0)
		service.set_running(true)
	a.advance_ms(13337)
	for milliseconds in [123, 6000, 214, 3000, 4000]:
		b.advance_ms(milliseconds)
	check(wallet_a.get_balance().compare(wallet_b.get_balance()) == 0 and a.get_state(0).elapsed_ms == b.get_state(0).elapsed_ms, "Delta chunking gives exact same production")
	# Insufficient upgrade must not mutate state, consume progress or emit events.
	fresh()
	wallet.earn(BigMoney.parse("100"))
	businesses.buy(0)
	var state := businesses.get_state(0)
	check(businesses.upgrade(0, "production") == ERR_UNAVAILABLE and businesses.get_state(0) == state, "Insufficient upgrade is atomic")
	check(businesses.automate(0) == ERR_UNAVAILABLE and not businesses.get_state(0).automated, "Insufficient contract is atomic")
	check(businesses.upgrade(0, "wrong") == ERR_INVALID_PARAMETER, "Unknown upgrade rejected")
	# Reentry across wallet and business signals is rejected; observers see committed state.
	wallet.earn(BigMoney.parse("10000"))
	var nested: Array[int] = []
	var observed: Array[int] = []
	var callback := func(_value):
		nested.append(businesses.buy(2))
		observed.append(businesses.owned_count())
	wallet.balance_changed.connect(callback)
	check(businesses.buy(1) == OK, "Cross-service transaction succeeds")
	wallet.balance_changed.disconnect(callback)
	check(nested == [ERR_BUSY] and observed == [2], "Observers see committed ownership and cannot reenter")
	# A full wallet cannot accept production: time and events remain uncommitted.
	businesses.automate(0)
	businesses.set_running(true)
	wallet.earn(BigMoney.parse("9".repeat(300)).subtract(wallet.get_balance()))
	state = businesses.get_state(0)
	var income_before := statistics.income.decimal()
	check(businesses.advance_ms(6000) == ERR_OUT_OF_MEMORY, "Overflow production rejected")
	check(businesses.get_state(0) == state and statistics.income.decimal() == income_before, "Overflow produces no partial time or statistics")

func _joy(down: bool, button: int = JOY_BUTTON_A) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _ui() -> void:
	var services := root.get_node("Services")
	services.economy = EconomyService.new()
	services.businesses = BusinessService.new(services.economy)
	services.business_statistics = BusinessStatistics.new()
	services.business_statistics.attach(services.businesses)
	check(change_scene_to_file("res://scenes/game/city.tscn") == OK, "Existing city loads")
	await process_frame
	await process_frame
	check(services.businesses.is_running(), "City starts production driver")
	current_scene.business_button.pressed.emit()
	await process_frame
	await process_frame
	var screen := current_scene
	check(screen.row_buttons.size() == 10 and screen.row_buttons[0].has_focus(), "Ten visible businesses, initial gamepad focus")
	screen._act("buy")
	check(screen.status_label.text.contains("dinero suficiente"), "Clear insufficient money feedback")
	screen._change_district(1)
	check(screen.district == 1 and screen.selected == 10, "District browsing")
	screen._act("buy")
	check(screen.status_label.text.contains("anterior"), "Clear fixed unlock explanation")
	screen._change_district(-1)
	services.economy.earn(BigMoney.parse("1000"))
	screen._select(0)
	_joy(true)
	await process_frame
	_joy(false)
	await process_frame
	check(services.businesses.get_state(0).owned, "Gamepad purchase through GUI")
	check(screen.row_buttons[0].text.contains("COMPRADO"), "Purchase visual state")
	check(screen.preview.state.owned, "Reusable preview receives purchase state")
	check(screen.row_buttons[1].text.contains("DISPONIBLE"), "Next unlock is shown")
	screen.action_buttons.auto.grab_focus()
	_joy(true)
	await process_frame
	_joy(false)
	await process_frame
	check(services.businesses.get_state(0).automated and screen.row_buttons[0].text.contains("AUTO"), "Gamepad automation and visual state")
	screen.row_buttons[1].grab_focus()
	check(screen.selected == 1, "Focus navigation updates detail selection")
	_joy(true, JOY_BUTTON_DPAD_RIGHT)
	await process_frame
	_joy(false, JOY_BUTTON_DPAD_RIGHT)
	await process_frame
	check(screen.action_buttons.buy.has_focus(), "Dpad enters selected details")
	_joy(true, JOY_BUTTON_DPAD_LEFT)
	await process_frame
	_joy(false, JOY_BUTTON_DPAD_LEFT)
	await process_frame
	check(screen.row_buttons[1].has_focus(), "Dpad returns to the selected row")

	# Going back to city and menu must pause production and retain session ownership.
	_joy(true, JOY_BUTTON_B)
	await process_frame
	_joy(false, JOY_BUTTON_B)
	await process_frame
	check(current_scene.scene_file_path.ends_with("city.tscn") and services.businesses.is_running(), "Return to city keeps driver running")
	check(current_scene.income_label.text.contains("1 / 40"), "City shows expansion and IPS")
	_joy(true, JOY_BUTTON_B)
	await process_frame
	_joy(false, JOY_BUTTON_B)
	await process_frame
	check(not services.businesses.is_running(), "Menu stops business production")
	var before: String = services.economy.get_balance().decimal()
	services._process(100000.0)
	check(services.economy.get_balance().decimal() == before, "No menu catch-up income")
	current_scene.play_button.pressed.emit()
	await process_frame
	await process_frame
	check(services.businesses.owned_count() == 1, "Scene changes retain session businesses")
	var elapsed: int = services.businesses.get_state(0).elapsed_ms
	services._process(100000.0)
	check(services.businesses.get_state(0).elapsed_ms <= elapsed + 250, "Long frame is clamped, no suspended interval catch-up")
	services._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	elapsed = services.businesses.get_state(0).elapsed_ms
	services._process(1.0)
	check(services.businesses.get_state(0).elapsed_ms == elapsed, "Unfocused application stops production")
	services._notification(NOTIFICATION_APPLICATION_FOCUS_IN)

func _run() -> void:
	_data()
	_all_businesses()
	_timing_and_atomicity()
	await _ui()
	print("PHASE3 TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
