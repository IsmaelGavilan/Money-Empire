extends SceneTree
var checks: int = 0
var failures: int = 0
var now_ms: int = 0
var events: Dictionary = {"balance": 0, "earn": 0, "click": 0, "buy": 0, "spent": 0, "benefit": 0}

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func money(text: String) -> BigMoney:
	return BigMoney.parse(text)

func fresh(catalog: EconomyCatalog = null) -> EconomyService:
	return EconomyService.new(catalog, func() -> int: return now_ms)

func same(value: BigMoney, expected: String, message: String) -> void:
	check(value != null and value.decimal() == expected, message)

func _numbers() -> void:
	for text in ["", "-1", "+1", "1.5", "NaN", "Infinity", "1e9", " 10", "١", "9".repeat(301)]:
		check(money(text) == null, "Reject invalid money: " + text.left(20))
	same(money("00010"), "10", "Normalize zeros")
	same(money("999999999999999999999999").add(money("1")), "1000000000000000000000000", "Carry beyond int64")
	same(money("1000000000000000000000000").subtract(money("1")), "999999999999999999999999", "Borrow beyond int64")
	check(money("1").subtract(money("2")) == null, "No negative currency")
	same(money("3").subtract(money("3")), "0", "Exact subtraction to zero")
	same(money("999").multiply_small(1000000), "999000000", "Bounded multiplier")
	check(money("1").multiply_small(-1) == null and money("1").multiply_small(1000001) == null, "Reject unsafe factor")
	check(money("1").divide_small_ceil(0) == null, "Reject division by zero")
	same(money("31").divide_small_ceil(2), "16", "Costs round upwards")
	var maximum := money("9".repeat(300))
	check(maximum != null and maximum.add(money("1")) == null, "300-digit cap")
	check(maximum.multiply_small(2) == null, "Multiply overflow rejected")
	same(maximum.subtract(money("8".repeat(300))), "1".repeat(300), "300-digit subtraction exact")
	check(MoneyFormat.abbreviated(money("1000"), "es") == "1 mil", "Spanish thousand")
	check(MoneyFormat.abbreviated(money("1000000000"), "es") == "1 mil M", "Spanish long scale 1e9")
	check(MoneyFormat.abbreviated(money("1000000000"), "en") == "1B", "English short scale 1e9")
	check(MoneyFormat.abbreviated(money("1000000000000"), "es") == "1 B", "Spanish billon 1e12")
	check(MoneyFormat.abbreviated(money("1000000000000"), "en") == "1T", "English trillion 1e12")
	check(MoneyFormat.abbreviated(money("12345"), "es") == "12,34 mil", "Spanish decimal separator")
	check(MoneyFormat.abbreviated(money("999999"), "en") == "999.99K", "Truncate display safely")
	check(MoneyFormat.abbreviated(money("1" + "0".repeat(299)), "en") == "1e299", "Scientific fallback")
	# Deterministic arithmetic properties against native safe integers.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for index in 150:
		var a := rng.randi_range(0, 100000000)
		var b := rng.randi_range(0, 100000000)
		var factor := rng.randi_range(0, 1000)
		var sum := money(str(a)).add(money(str(b)))
		same(sum, str(a + b), "Reference sum")
		same(sum.subtract(money(str(b))), str(a), "Add/subtract round trip")
		same(money(str(a)).multiply_small(factor), str(a * factor), "Reference product")

func _catalogs() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	check(EconomyCatalog.from_data(data) != null, "Default data valid")
	for field in ["base_click", "click_cooldown_ms", "upgrades", "schema_version"]:
		var bad := data.duplicate(true)
		bad.erase(field)
		check(EconomyCatalog.from_data(bad) == null, "Missing catalogue field rejected")
	var malformed := data.duplicate(true)
	malformed.upgrades[0].growth_denominator = 0
	check(EconomyCatalog.from_data(malformed) == null, "Invalid cost growth rejected")
	malformed = data.duplicate(true)
	malformed.upgrades[1].id = "power"
	check(EconomyCatalog.from_data(malformed) == null, "Duplicate IDs rejected")
	malformed = data.duplicate(true)
	malformed.upgrades[1].factor = INF
	check(EconomyCatalog.from_data(malformed) == null, "Nonfinite configuration rejected")
	malformed = data.duplicate(true)
	malformed.upgrades[0].max_level = 1
	var limited := fresh(EconomyCatalog.from_data(malformed))
	limited.earn(money("1000"))
	check(limited.purchase("power") == OK, "Reach level cap")
	var before := limited.get_balance().decimal()
	check(limited.purchase("power") == ERR_UNAVAILABLE and limited.get_balance().decimal() == before, "Level cap never spends")
	malformed = data.duplicate(true)
	malformed.base_click = "8".repeat(300)
	var overflow_purchase := fresh(EconomyCatalog.from_data(malformed))
	overflow_purchase.earn(money("1000"))
	check(overflow_purchase.purchase("multiplier") == ERR_OUT_OF_MEMORY, "Reject benefit overflow before spending")
	same(overflow_purchase.get_balance(), "1000", "Failed benefit transaction leaves balance")
	check(overflow_purchase.get_level("multiplier") == 0, "Failed transaction leaves upgrade level")
	malformed = data.duplicate(true)
	malformed.upgrades[0].base_cost = "9".repeat(300)
	var overflow_cost := fresh(EconomyCatalog.from_data(malformed))
	overflow_cost.earn(money("9".repeat(300)))
	check(overflow_cost.purchase("power") == OK, "Huge exact purchase")
	check(overflow_cost.get_cost("power") == null, "Progressive cost overflow unavailable")
	check(overflow_cost.purchase("power") == ERR_UNAVAILABLE, "Overflow cost never charged")


func _economy() -> void:
	var economy := fresh()
	check(economy.is_ready(), "Catalog loaded")
	economy.balance_changed.connect(func(_value): events.balance += 1)
	economy.money_earned.connect(func(_amount, _source): events.earn += 1)
	economy.money_spent.connect(func(_amount, _source): events.spent += 1)
	economy.click_registered.connect(func(_amount, _count): events.click += 1)
	economy.upgrade_purchased.connect(func(_id, _level): events.buy += 1)
	economy.benefit_changed.connect(func(): events.benefit += 1)
	same(economy.get_balance(), "0", "Initial balance zero")
	same(economy.get_click_benefit(), "10", "Base click")
	check(economy.purchase("power") == ERR_UNAVAILABLE, "Unaffordable purchase")
	check(economy.click() == OK, "First click accepted")
	same(economy.get_balance(), "10", "Immediate balance")
	check(economy.click() == ERR_BUSY, "Duplicate click blocked")
	check(events.click == 1 and events.earn == 1 and events.balance == 1, "Exactly one event per accepted click")
	now_ms = 79
	check(economy.click() == ERR_BUSY, "Cooldown below boundary")
	now_ms = 80
	check(economy.click() == OK, "Cooldown boundary inclusive")
	now_ms = 160
	check(economy.click() == OK, "Third click funds first upgrade")
	check(economy.purchase("power") == OK, "Purchase first power")
	same(economy.get_balance(), "0", "Purchase exact balance")
	same(economy.get_click_benefit(), "20", "Power effect")
	same(economy.get_cost("power"), "45", "Progressive cost 30 to 45")
	var levels_test := fresh()
	levels_test.earn(money("10000"))
	levels_test.purchase("power")
	levels_test.purchase("power")
	same(levels_test.get_cost("power"), "68", "Progressive price ceil 45 times 1.5")
	levels_test.purchase("multiplier")
	levels_test.purchase("multiplier")
	same(levels_test.get_click_benefit(), "120", "Power levels and compounded multiplier levels")

	check(economy.purchase("missing") == ERR_INVALID_PARAMETER, "Unknown upgrade rejected")
	check(economy.earn(null) == ERR_INVALID_PARAMETER and economy.spend(null) == ERR_INVALID_PARAMETER, "Invalid money rejected")
	check(economy.earn(money("0")) == ERR_INVALID_PARAMETER, "Zero income rejected")
	check(economy.spend(money("1")) == ERR_UNAVAILABLE, "Insufficient spending rejected")
	check(economy.earn(money("1000")) == OK, "External addition")
	check(economy.purchase("multiplier") == OK, "Permanent multiplier purchase")
	same(economy.get_click_benefit(), "40", "Power then multiplier order")
	check(economy.purchase("rush") == OK, "Temporary bonus purchase")
	same(economy.get_click_benefit(), "120", "Permanent times temporary")
	check(economy.bonus_remaining_ms() == 10000, "Bonus duration")
	var before := economy.get_balance().decimal()
	check(economy.purchase("rush") == ERR_BUSY and economy.get_balance().decimal() == before, "No stacking or double charge")
	now_ms += 9999
	same(economy.get_click_benefit(), "120", "Bonus before expiry")
	var benefit_events: int = events.benefit
	now_ms += 1
	same(economy.get_click_benefit(), "40", "Exact bonus expiry without float drift")
	economy.tick()
	economy.tick()
	check(events.benefit == benefit_events + 1, "Expiry signalled once")
	check(economy.purchase("rush") == OK, "Repurchase after expiry")
	same(economy.get_cost("rush"), "320", "Temporary repurchase cost growth")
	check(economy.spend(money("1")) == OK, "Explicit spending")
	check(events.buy == 4 and events.spent == 5, "Purchase and spending events")
	var huge := fresh()
	var maximum := "9".repeat(300)
	check(huge.earn(money(maximum)) == OK, "Accept 300-digit balance")
	check(huge.earn(money("1")) == ERR_OUT_OF_MEMORY, "Overflow addition rejected")
	check(huge.click() == ERR_OUT_OF_MEMORY and huge.get_click_count() == 0, "Overflow click atomic")
	same(huge.get_balance(), maximum, "Overflow leaves balance unchanged")
	check(huge.spend(money(maximum)) == OK, "Spend entire large balance")
	same(huge.get_balance(), "0", "No precision residue")
	# Signal observers cannot perform nested transactions during a commit.
	var guarded := fresh()
	var nested: Array[int] = []
	var nested_callback := func(_amount, _source): nested.append(guarded.click())
	guarded.money_earned.connect(nested_callback)
	check(guarded.click() == OK and nested == [ERR_BUSY], "Reentrancy guard")
	same(guarded.get_balance(), "10", "No nested reward")
	guarded.money_earned.disconnect(nested_callback)

func _joy(pressed: bool, button: int = JOY_BUTTON_A) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _run() -> void:
	_numbers()
	_catalogs()
	_economy()
	await _presentation()
	print("PHASE2 TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _presentation() -> void:
	var services := root.get_node("Services")
	now_ms = 0
	services.economy = fresh()
	check(change_scene_to_file("res://scenes/game/city.tscn") == OK, "City scene loads")
	await process_frame
	await process_frame
	var city := current_scene
	check(city.headquarters.has_focus(), "HQ initially focused")
	# Observe the immediate response synchronously: frame duration is variable on CI.
	var observed_feedback := {"count": 0, "pulse": false}
	var observe_click := func(_amount, _count):
		observed_feedback.count = city._feedback.get_child_count()
		observed_feedback.pulse = city.headquarters.scale.x < 1.0
	services.economy.click_registered.connect(observe_click)

	_joy(true)
	await process_frame
	_joy(false)
	await process_frame
	same(services.economy.get_balance(), "10", "Synthetic controller click routed through GUI")
	check(city.money_label.text == "DINERO  $ 10", "Balance updated immediately in UI")
	services.economy.click_registered.disconnect(observe_click)
	check(observed_feedback.count == 1, "Floating income created")
	check(observed_feedback.pulse, "Click pulse animation started")
	now_ms = 100
	_joy(true)
	await process_frame
	now_ms = 200
	_joy(true)
	await process_frame
	same(services.economy.get_balance(), "20", "Held/repeated gamepad press does not repeat")
	_joy(false)
	await process_frame
	# Mouse and gamepad share the economic cooldown.
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	city.headquarters._gui_input(mouse)
	mouse.pressed = false
	city.headquarters._gui_input(mouse)
	same(services.economy.get_balance(), "30", "Mouse press earns")
	_joy(true)
	await process_frame
	_joy(false)
	await process_frame
	same(services.economy.get_balance(), "30", "Simultaneous sources blocked")
	city.upgrade_buttons.power.grab_focus()
	_joy(true)
	await process_frame
	_joy(false)
	await process_frame
	same(services.economy.get_balance(), "0", "Gamepad buys focused upgrade")
	same(services.economy.get_click_benefit(), "20", "Purchased benefit shown")
	check(city.benefit_label.text.contains("20"), "Benefit UI refreshed")
	# Keyboard echo is consumed even after the economic debounce window.
	city.headquarters.grab_focus()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_ENTER
	key.pressed = true
	key.echo = true
	now_ms = 400
	city.headquarters._gui_input(key)
	same(services.economy.get_balance(), "0", "Keyboard echo ignored")
	_joy(true, JOY_BUTTON_DPAD_DOWN)
	await process_frame
	_joy(false, JOY_BUTTON_DPAD_DOWN)
	await process_frame
	check(city.upgrade_buttons.power.has_focus(), "Dpad navigates to upgrade")
	# Let feedback finish: floating labels are removed and scale restored.
	await create_timer(0.8).timeout
	check(city._feedback.get_child_count() == 0, "Floating feedback cleaned up")
	check(city.headquarters.scale.is_equal_approx(Vector2.ONE), "Animation returns to baseline")
	_joy(true, JOY_BUTTON_B)
	await process_frame
	_joy(false, JOY_BUTTON_B)
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/menu/main_menu.tscn", "Gamepad cancel returns to menu")
	current_scene.play_button.pressed.emit()
	await process_frame
	await process_frame
	same(services.economy.get_click_benefit(), "20", "Session upgrades survive scene changes")
	# Left stick uses the same focus navigation actions as the dpad.
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_Y
	motion.axis_value = 1.0
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await process_frame
	check(current_scene.upgrade_buttons.power.has_focus(), "Left stick navigates to upgrade")
	motion.axis_value = 0.0
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await process_frame

