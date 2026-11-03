class_name HeadquartersButton
extends Control
## One activation per physical press. UI focus and presentation stay outside economy.
signal activated
var _held: Dictionary = {}

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_entered.connect(queue_redraw)
	focus_exited.connect(func():
		_held.clear()
		queue_redraw())

func _gui_input(event: InputEvent) -> void:
	var source := ""
	var down := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		source = "mouse"
		down = event.pressed
	elif event.is_action("ui_accept"):
		source = "accept:%d:%s" % [event.device, event.get_class()]
		down = event.is_pressed()
		if event.is_echo():
			accept_event()
			return
	else:
		return
	accept_event()
	if down:
		if not _held.has(source):
			_held[source] = true
			grab_focus()
			activated.emit()
	else:
		_held.erase(source)

func _input(event: InputEvent) -> void:
	# Release may occur outside our rectangle after dragging or changing focus.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_held.erase("mouse")
	elif event.is_action_released("ui_accept"):
		_held.erase("accept:%d:%s" % [event.device, event.get_class()])

func _notification(what: int) -> void:
	# Avoid stuck input when the window loses focus during a press.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_held.clear()

func _draw() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("203834")
	frame.border_color = ScreenUI.GOLD if has_focus() else Color("779a82")
	frame.set_border_width_all(5 if has_focus() else 2)
	frame.set_corner_radius_all(20)
	draw_style_box(frame, Rect2(Vector2.ZERO, size))
	draw_rect(Rect2(55, 85, 320, 175), Color("b27f36"))
	draw_rect(Rect2(45, 70, 320, 175), ScreenUI.GOLD)
	for x in range(75, 350, 65):
		draw_rect(Rect2(x, 110, 35, 80), Color("3d536c"))
	draw_circle(Vector2(205, 55), 38, ScreenUI.GOLD)
