extends Control
var money_label: Label
func _ready() -> void:
	money_label = ScreenUI.label("", 40)
	money_label.position = Vector2(1380, 60)
	add_child(money_label)
	Services.economy.balance_changed.connect(_update_money)
	_update_money(Services.economy.get_balance())
	var title := ScreenUI.label("DISTRITO 01 • CIUDAD PROVISIONAL", 38)
	title.position = Vector2(100, 60)
	add_child(title)
	var headquarters := ScreenUI.label("SEDE DEL IMPERIO", 40)
	headquarters.position = Vector2(740, 420)
	add_child(headquarters)
	var hint := ScreenUI.label("La economía y las pulsaciones llegarán en la fase 2.", 30)
	hint.position = Vector2(100, 890)
	add_child(hint)
	var back := ScreenUI.button("Volver al menú")
	back.position = Vector2(100, 950)
	add_child(back)
	back.pressed.connect(_back)
	ScreenUI.focus_ring([back])
func _update_money(value: int) -> void:
	money_label.text = "DINERO  $ %d" % value
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
	draw_rect(Rect2(810, 210, 360, 190), Color("b27f36"))
	draw_rect(Rect2(830, 190, 320, 180), ScreenUI.GOLD)
	for x in range(860, 1150, 70):
		draw_rect(Rect2(x, 230, 35, 80), Color("3d536c"))
	draw_circle(Vector2(990, 170), 42, ScreenUI.GOLD)
