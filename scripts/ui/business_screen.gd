extends Control
var district: int = 0
var selected: int = 0
var row_buttons: Array[Button] = []
var district_label: Label
var balance_label: Label
var title_label: Label
var description_label: Label
var info_label: Label
var status_label: Label
var preview: BusinessPreview
var action_buttons: Dictionary = {}
var _poll_time: float = 0.0
var _milestone_notified: bool = false

func _label_at(text: String, font_size: int, position_: Vector2, width: float = 0) -> Label:
	var label := ScreenUI.label(text, font_size)
	label.position = position_
	if width > 0:
		label.size.x = width
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label

func _ready() -> void:
	Services.businesses.set_running(true)
	_label_at("NEGOCIOS DEL IMPERIO", 44, Vector2(100, 40))
	balance_label = _label_at("", 30, Vector2(1050, 55), 770)
	district_label = _label_at("", 30, Vector2(100, 115), 1720)
	var previous := ScreenUI.button("◀ Distrito anterior")
	previous.position = Vector2(100, 170)
	previous.custom_minimum_size = Vector2(320, 55)
	previous.add_theme_font_size_override("font_size", 25)
	add_child(previous)
	var next := ScreenUI.button("Distrito siguiente ▶")
	next.position = Vector2(440, 170)
	next.custom_minimum_size = Vector2(320, 55)
	next.add_theme_font_size_override("font_size", 25)
	add_child(next)
	previous.pressed.connect(_change_district.bind(-1))
	next.pressed.connect(_change_district.bind(1))
	var focus_items: Array[Control] = [previous, next]
	for slot in 10:
		var button := ScreenUI.button("")
		button.position = Vector2(100, 240 + slot * 66)
		button.custom_minimum_size = Vector2(660, 60)
		button.add_theme_font_size_override("font_size", 23)
		button.clip_text = true
		button.pressed.connect(_select.bind(slot))
		button.focus_entered.connect(_focus_row.bind(slot))
		add_child(button)
		row_buttons.append(button)
		focus_items.append(button)
	title_label = _label_at("", 32, Vector2(810, 180), 700)
	description_label = _label_at("", 26, Vector2(810, 310), 1010)
	preview = BusinessPreview.new()
	preview.position = Vector2(1590, 165)
	preview.size = Vector2(220, 140)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)
	info_label = _label_at("", 27, Vector2(810, 405), 1010)
	for index in 5:
		var kind: String = ["buy", "collect", "production", "speed", "auto"][index]
		var button := ScreenUI.button("")
		button.position = Vector2(810, 550 + index * 67)
		button.custom_minimum_size = Vector2(1010, 58)
		button.add_theme_font_size_override("font_size", 27)
		button.pressed.connect(_act.bind(kind))
		add_child(button)
		action_buttons[kind] = button
		focus_items.append(button)
	status_label = _label_at("Selecciona un negocio. Producción solo durante la sesión activa.", 25, Vector2(100, 915), 1720)
	var back := ScreenUI.button("Volver a la ciudad")
	back.position = Vector2(100, 975)
	add_child(back)
	back.pressed.connect(_back)
	focus_items.append(back)
	ScreenUI.focus_ring(focus_items)
	# A row's right neighbor enters its detail actions; left returns to that row.
	for button in row_buttons:
		button.focus_neighbor_right = button.get_path_to(action_buttons.buy)
	for button in action_buttons.values():
		button.focus_neighbor_left = button.get_path_to(row_buttons[0])
	Services.businesses.businesses_changed.connect(_refresh)
	Services.businesses.expansion_milestone.connect(_milestone)
	Services.economy.balance_changed.connect(_balance_changed)
	_refresh()
	row_buttons[0].grab_focus()

func _exit_tree() -> void:
	Services.businesses.set_running(false)

func _process(delta: float) -> void:
	_poll_time += delta
	if _poll_time >= 0.25:
		_poll_time = 0.0
		_refresh_detail()

func _balance_changed(_value: BigMoney) -> void:
	balance_label.text = "$ " + MoneyFormat.abbreviated(Services.economy.get_balance())
	_refresh_detail()

func _change_district(direction: int) -> void:
	district = posmod(district + direction, 4)
	selected = district * 10
	for button in action_buttons.values():
		button.focus_neighbor_left = button.get_path_to(row_buttons[0])
	_refresh()

func _focus_row(slot: int) -> void:
	selected = district * 10 + slot
	for button in action_buttons.values():
		button.focus_neighbor_left = button.get_path_to(row_buttons[slot])
	_refresh_detail()

func _select(slot: int) -> void:
	selected = district * 10 + slot
	for button in action_buttons.values():
		button.focus_neighbor_left = button.get_path_to(row_buttons[slot])
	_refresh_detail()
	action_buttons.buy.grab_focus()

func _refresh() -> void:
	district_label.text = "%d / 4 • %s • %d / 40 comprados" % [district + 1, Services.businesses.get_districts()[district], Services.businesses.owned_count()]
	for slot in 10:
		var index := district * 10 + slot
		var row: Dictionary = Services.businesses.get_definition(index)
		var state: Dictionary = Services.businesses.get_state(index)
		var tag := "AUTO" if state.automated else "COMPRADO" if state.owned else "DISPONIBLE" if state.unlocked else "BLOQUEADO"
		row_buttons[slot].text = "%02d %s • %s" % [index + 1, row.name_es, tag]
		row_buttons[slot].modulate = Color("9ce6b9") if state.owned else ScreenUI.GOLD if state.unlocked else Color("a6aab5")
	balance_label.text = "$ " + MoneyFormat.abbreviated(Services.economy.get_balance())
	_refresh_detail()

func _price_label(value: BigMoney) -> String:
	return "$ " + MoneyFormat.abbreviated(value) if value != null else "MÁXIMO"

func _refresh_detail() -> void:
	var row: Dictionary = Services.businesses.get_definition(selected)
	if row.is_empty():
		return
	var state: Dictionary = Services.businesses.get_state(selected)
	title_label.text = "%02d · %s" % [selected + 1, row.name_es]
	description_label.text = row.description_es
	var cycle: int = Services.businesses.get_cycle_ms(selected)
	var remaining: int = maxi(0, cycle - int(state.elapsed_ms))
	var operation := "Automatizado" if state.automated else "Listo para recoger" if state.ready else "Ciclo manual" if state.owned else "Compra el anterior para desbloquear" if not state.unlocked else "Disponible para comprar"
	info_label.text = "Nivel %d · Potencia %d/%d · Velocidad %d/%d · %s\nCiclo: %.1f s · Falta: %.1f s · Pago: %s\nPotencial: %s · Automático total: %s" % [state.level, state.production_level, int(row.max_production_level), state.speed_level, int(row.max_speed_level), operation, cycle / 1000.0, remaining / 1000.0, _price_label(Services.businesses.get_payout(selected)), MoneyFormat.rate(Services.businesses.get_rate_milli(selected)), MoneyFormat.rate(Services.businesses.get_auto_rate_milli())]
	action_buttons.buy.text = "Comprar • " + _price_label(BigMoney.parse(row.price)) + (" • COMPRADO" if state.owned else " • BLOQUEADO" if not state.unlocked else "")
	action_buttons.collect.text = "Recoger producción" + (" • LISTA" if state.ready else " • Contrato activo" if state.automated else " • Esperando ciclo")
	action_buttons.production.text = "Mejorar producción ×%d • " % int(row.production_factor) + _price_label(Services.businesses.get_upgrade_cost(selected, "production"))
	action_buttons.speed.text = "Mejorar velocidad • " + _price_label(Services.businesses.get_upgrade_cost(selected, "speed"))
	action_buttons.auto.text = "Contrato automático • " + ("ACTIVO" if state.automated else _price_label(BigMoney.parse(row.automation_cost)))
	preview.show_business(row, state)

func _act(kind: String) -> void:
	var state: Dictionary = Services.businesses.get_state(selected)
	if not state.owned and (not state.unlocked or kind != "buy"):
		status_label.text = "Compra primero el negocio anterior." if not state.unlocked else "Primero compra este negocio."
		return
	var result: Error
	_milestone_notified = false
	match kind:
		"buy": result = Services.businesses.buy(selected)
		"collect": result = Services.businesses.collect(selected)
		"auto": result = Services.businesses.automate(selected)
		_: result = Services.businesses.upgrade(selected, kind)
	if result == OK:
		# Preserve the milestone text emitted synchronously by a successful purchase.
		if not _milestone_notified:
			status_label.text = "Operación completada."
	elif result == ERR_OUT_OF_MEMORY:
		status_label.text = "Operación rechazada: límite numérico. No se ha cobrado."
	elif kind == "collect":
		status_label.text = "El ciclo no ha terminado o ya tienes contrato automático."
	elif state.owned and kind == "buy" or state.automated and kind == "auto":
		status_label.text = "Este negocio o contrato ya está comprado. No se ha cobrado."
	elif kind in ["production", "speed"] and Services.businesses.get_upgrade_cost(selected, kind) == null:
		status_label.text = "Esta mejora está al máximo."
	else:
		status_label.text = "No tienes dinero suficiente. No se ha cobrado."
	_refresh()

func _milestone(count: int, reward: BigMoney) -> void:
	_milestone_notified = true
	status_label.text = "¡Hito: %d negocios! Recompensa: %s. Prima de expansión actualizada." % [count, _price_label(reward)]

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/game/city.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()
