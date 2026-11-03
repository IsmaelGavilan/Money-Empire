class_name BusinessPreview
extends Control
## Provisional reusable visual; district_slot/footprint are reserved for city phase.
var definition: Dictionary = {}
var state: Dictionary = {}

func show_business(row: Dictionary, business_state: Dictionary) -> void:
	definition = row
	state = business_state
	queue_redraw()

func _draw() -> void:
	if definition.is_empty():
		return
	var color := Color(definition.visual.tint)
	var roof := Color(definition.visual.roof_tint)
	if not state.owned:
		color = color.darkened(0.65 if not state.unlocked else 0.3)
	var body := Rect2(25, 45, 170, 75)
	match definition.visual.silhouette:
		"tower":
			body = Rect2(65, 15, 90, 105)
		"factory":
			draw_rect(Rect2(135, 10, 25, 55), roof)
		"dome":
			draw_circle(Vector2(110, 65), 65, roof)
	draw_rect(body, color)
	draw_rect(Rect2(body.position, Vector2(body.size.x, 15)), roof)
	for x in range(int(body.position.x) + 15, int(body.end.x) - 10, 35):
		draw_rect(Rect2(x, body.position.y + 30, 15, 25), Color("253a50"))
	draw_rect(Rect2(5, 2, 210, 130), Color("f7c85a") if state.owned else Color("76858c"), false, 3)
	if state.automated:
		draw_circle(Vector2(195, 20), 10, Color("71edaf"))
