extends Control
var play_button: Button
var options_panel: VBoxContainer
var menu_panel: VBoxContainer
func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("101d32")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	menu_panel = VBoxContainer.new()
	menu_panel.position = Vector2(200, 170)
	menu_panel.add_theme_constant_override("separation", 24)
	add_child(menu_panel)
	menu_panel.add_child(ScreenUI.label("MONEY CLICKER", 80))
	var empire := ScreenUI.label("EMPIRE", 110)
	empire.add_theme_color_override("font_color", ScreenUI.GOLD)
	menu_panel.add_child(empire)
	menu_panel.add_child(ScreenUI.label("Tu imperio empieza aquí. • FASE 3", 28))
	play_button = ScreenUI.button("Jugar")
	var options := ScreenUI.button("Opciones")
	var exit_button := ScreenUI.button("Salir")
	for item in [play_button, options, exit_button]:
		menu_panel.add_child(item)
	play_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game/city.tscn"))
	options.pressed.connect(_open_options)
	exit_button.pressed.connect(func(): get_tree().quit())
	ScreenUI.focus_ring([play_button, options, exit_button])
func _open_options() -> void:
	menu_panel.hide()
	options_panel = VBoxContainer.new()
	options_panel.position = Vector2(200, 230)
	options_panel.add_theme_constant_override("separation", 30)
	add_child(options_panel)
	options_panel.add_child(ScreenUI.label("OPCIONES", 64))
	var display := ScreenUI.button("Pantalla completa: " + ("Sí" if Services.settings.fullscreen else "No"))
	var back := ScreenUI.button("Volver")
	var status := ScreenUI.label("Configuración local • Arte provisional", 28)
	options_panel.add_child(display)
	options_panel.add_child(back)
	options_panel.add_child(status)
	display.pressed.connect(func():
		var result := Services.settings.set_fullscreen(not Services.settings.fullscreen)
		status.text = "Configuración guardada" if result == OK else "Error al guardar: " + error_string(result)
		display.text = "Pantalla completa: " + ("Sí" if Services.settings.fullscreen else "No"))
	back.pressed.connect(_close_options)
	ScreenUI.focus_ring([display, back])
func _close_options() -> void:
	options_panel.queue_free()
	options_panel = null
	menu_panel.show()
	play_button.grab_focus()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_instance_valid(options_panel):
		_close_options()
		get_viewport().set_input_as_handled()
