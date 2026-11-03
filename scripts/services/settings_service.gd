class_name SettingsService
extends RefCounted
signal settings_changed
const PATH: String = "user://settings.cfg"
var fullscreen: bool = false
func load_settings() -> Error:
	var config := ConfigFile.new()
	var result := config.load(PATH)
	if result == OK:
		fullscreen = bool(config.get_value("display", "fullscreen", false))
	return result
func set_fullscreen(enabled: bool) -> Error:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", enabled)
	var result := config.save(PATH)
	if result != OK:
		return result
	fullscreen = enabled
	apply_display()
	settings_changed.emit()
	return OK
func apply_display() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
