class_name BusinessState
extends RefCounted
## Session-only runtime state. No wall-clock dates or offline accumulation.
var owned: bool = false
var production_level: int = 0
var speed_level: int = 0
var automated: bool = false
var elapsed_ms: int = 0

func snapshot() -> Dictionary:
	return {"owned": owned, "level": production_level + 1 if owned else 0,
		"production_level": production_level, "speed_level": speed_level,
		"automated": automated, "elapsed_ms": elapsed_ms}
