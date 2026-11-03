extends Node
## Composition root. Domain services do not depend on scenes or this autoload.
var economy := EconomyService.new()
var saves := SaveService.new()
var settings := SettingsService.new()
var achievements := AchievementService.new()
var platform: PlatformAdapter
func _ready() -> void:
	platform = WindowsAdapter.new() if OS.get_name() == "Windows" else PlatformAdapter.new()
	var result := settings.load_settings()
	if result != OK and result != ERR_FILE_NOT_FOUND:
		push_warning("No se pudo cargar la configuración: %s" % error_string(result))
	settings.apply_display()
