extends Control
var money_label: Label
var income_label: Label
var business_button: Button
var benefit_label: Label
var bonus_label: Label
var status_label: Label
var headquarters: HeadquartersButton
var upgrade_buttons: Dictionary = {}
var _pulse: Tween
var _feedback: Control

func _ready() -> void:
	Services.businesses.set_running(true)
	income_label = ScreenUI.label("", 28)
	income_label.position = Vector2(100, 300)
	add_child(income_label)
	Services.businesses.businesses_changed.connect(_refresh_income)
	money_label = ScreenUI.label("", 40)
	money_label.position = Vector2(100, 110)
	money_label.size = Vector2(1050, 60)
	money_label.clip_text = true
	add_child(money_label)
	var title := ScreenUI.label("MONEY CLICKER EMPIRE • CIUDAD", 38)
	title.position = Vector2(100, 50)
	add_child(title)
	benefit_label = ScreenUI.label("", 32)
	benefit_label.position = Vector2(100, 180)
	add_child(benefit_label)
	bonus_label = ScreenUI.label("", 28)
	bonus_label.position = Vector2(100, 235)
	add_child(bonus_label)
	headquarters = HeadquartersButton.new()
	headquarters.position = Vector2(760, 190)
	headquarters.size = Vector2(430, 320)
	headquarters.pivot_offset = headquarters.size / 2
	add_child(headquarters)
	var sign := ScreenUI.label("SEDE DEL IMPERIO", 34)
	sign.position = Vector2(35, 270)
	sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	headquarters.add_child(sign)
	headquarters.activated.connect(_click)
	_feedback = Control.new()
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_feedback)
	var shop := VBoxContainer.new()
	shop.position = Vector2(1260, 190)
	shop.size = Vector2(560, 600)
	shop.add_theme_constant_override("separation", 18)
	add_child(shop)
	shop.add_child(ScreenUI.label("MEJORAS DE SEDE", 38))
	var focus_items: Array[Control] = [headquarters]
	for row in Services.economy.get_upgrades():
		var button := ScreenUI.button("")
		button.custom_minimum_size = Vector2(560, 120)
		button.add_theme_font_size_override("font_size", 26)
		shop.add_child(button)
		button.pressed.connect(_buy.bind(String(row.id)))
		upgrade_buttons[row.id] = button
		focus_items.append(button)
	var note := ScreenUI.label("Costes y saldo: valores abreviados.\nES: B = billón (10¹²); mil M = 10⁹.", 24)
	shop.add_child(note)
	status_label = ScreenUI.label("", 28)
	status_label.position = Vector2(100, 820)
	add_child(status_label)
	var hint := ScreenUI.label("Selecciona la sede y pulsa A / ✕ / Enter, o haz clic.\nFlechas / cruceta / stick: navegar. B / ○ / Esc: volver. • Arte provisional", 28)
	hint.position = Vector2(100, 875)
	add_child(hint)
	var back := ScreenUI.button("Volver al menú")
	back.position = Vector2(100, 975)
	add_child(back)
	back.pressed.connect(_back)
	focus_items.append(back)
	business_button = ScreenUI.button("Negocios y contratos")
	business_button.position = Vector2(550, 975)
	business_button.custom_minimum_size.x = 540
	add_child(business_button)
	business_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game/businesses.tscn"))
	focus_items.append(business_button)
	ScreenUI.focus_ring(focus_items)
	_refresh_income()
	Services.economy.balance_changed.connect(_update_money)
	Services.economy.benefit_changed.connect(_refresh_shop)
	Services.economy.click_registered.connect(_click_feedback)
	_update_money(Services.economy.get_balance())

func _exit_tree() -> void:
	Services.businesses.set_running(false)

func _refresh_income() -> void:
	income_label.text = "%d / 40 negocios • Automático: $ %s" % [Services.businesses.owned_count(), MoneyFormat.rate(Services.businesses.get_auto_rate_milli())]

func _process(_delta: float) -> void:
	var remaining: int = Services.economy.bonus_remaining_ms()
	var bonus: Dictionary = Services.economy.get_active_bonus()
	bonus_label.text = "%s ×%d • %.1f s" % [bonus.name_es, int(bonus.factor), remaining / 1000.0] if remaining > 0 else "Sin bonificación temporal"

func _update_money(value: BigMoney) -> void:
	money_label.text = "DINERO  $ " + MoneyFormat.abbreviated(value)
	money_label.tooltip_text = "$ " + value.decimal()
	_refresh_shop()

func _refresh_shop() -> void:
	benefit_label.text = "+ $ " + MoneyFormat.abbreviated(Services.economy.get_click_benefit()) + " por pulsación"
	for row in Services.economy.get_upgrades():
		var cost: BigMoney = Services.economy.get_cost(row.id)
		var level: int = Services.economy.get_level(row.id)
		var effect := "+" + MoneyFormat.abbreviated(BigMoney.parse(row.amount)) + " base" if row.kind == "power" else "×%d" % int(row.factor)
		if row.kind == "temporary":
			effect += " · %d s" % (int(row.duration_ms) / 1000)
		var availability := "MÁXIMO"
		if cost != null:
			availability = "$ " + MoneyFormat.abbreviated(cost)
			if row.kind == "temporary" and Services.economy.bonus_remaining_ms() > 0:
				availability += " • ACTIVA"
			elif Services.economy.get_balance().compare(cost) < 0:
				availability += " • Falta dinero"
		upgrade_buttons[row.id].text = "%s · Nv. %d · %s\n%s" % [row.name_es, level, effect, availability]
		# Keep unaffordable controls focusable, and explain rejection on activation.
		upgrade_buttons[row.id].tooltip_text = cost.decimal() if cost != null else "Nivel máximo o límite numérico"

func _click() -> void:
	var result: Error = Services.economy.click()
	if result != OK and result != ERR_BUSY:
		status_label.text = "No se pudo generar dinero: límite económico o datos inválidos."

func _buy(id: String) -> void:
	var result: Error = Services.economy.purchase(id)
	if result == OK:
		status_label.text = "¡Mejora adquirida! Beneficio actualizado."
	elif result == ERR_BUSY:
		status_label.text = "La bonificación ya está activa. Espera a que termine."
	else:
		status_label.text = "Compra rechazada: saldo insuficiente, nivel máximo o límite económico."

func _click_feedback(amount: BigMoney, _count: int) -> void:
	status_label.text = "¡Tu imperio crece!"
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	headquarters.scale = Vector2(0.96, 0.96)
	headquarters.modulate = Color(1.25, 1.18, 0.85)
	_pulse = create_tween().set_parallel(true)
	_pulse.tween_property(headquarters, "scale", Vector2.ONE, 0.16)
	_pulse.tween_property(headquarters, "modulate", Color.WHITE, 0.16)
	var floating := ScreenUI.label("+ $ " + MoneyFormat.abbreviated(amount), 40)
	floating.add_theme_color_override("font_color", ScreenUI.GOLD)
	floating.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating.position = Vector2(860, 150)
	_feedback.add_child(floating)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(floating, "position:y", 80.0, 0.65)
	tween.tween_property(floating, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(floating.queue_free)

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("294b47"))
	draw_rect(Rect2(0, 520, 1920, 160), Color("344252"))
	draw_rect(Rect2(610, 160, 150, 700), Color("344252"))
	for x in range(30, 1920, 130):
		draw_rect(Rect2(x, 595, 65, 8), Color("e4cb80"))
	for position_ in [Vector2(160,220), Vector2(370,240), Vector2(1350,250), Vector2(1580,260), Vector2(1000,740), Vector2(1370,740)]:
		draw_rect(Rect2(position_ + Vector2(10, 12), Vector2(150, 130)), Color("203834"))
		draw_rect(Rect2(position_, Vector2(150, 130)), Color("6b8d8c"))
		draw_rect(Rect2(position_ + Vector2(20, 20), Vector2(110, 25)), Color("b9cbb6"))
