class_name ScreenUI
extends RefCounted
const GOLD := Color("f7c85a")
static func label(text: String, size: int = 32) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", Color("f6edd9"))
	return item
static func button(text: String) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(360, 80)
	item.add_theme_font_size_override("font_size", 32)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("344764") if state == "normal" else Color("536a8b")
		style.set_corner_radius_all(16)
		style.set_border_width_all(4 if state == "focus" else 2)
		style.border_color = GOLD if state == "focus" else Color("8b754a")
		item.add_theme_stylebox_override(state, style)
	return item
static func focus_ring(buttons: Array[Button]) -> void:
	for i in buttons.size():
		var previous := buttons[(i - 1 + buttons.size()) % buttons.size()]
		var following := buttons[(i + 1) % buttons.size()]
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(previous)
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(following)
		buttons[i].focus_neighbor_left = buttons[i].get_path_to(previous)
		buttons[i].focus_neighbor_right = buttons[i].get_path_to(following)
	buttons[0].grab_focus()
