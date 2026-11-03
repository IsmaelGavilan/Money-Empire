extends Node
## Composition root. Domain services do not depend on scenes or this autoload.
var economy := EconomyService.new()
var businesses := BusinessService.new(economy)
var business_statistics := BusinessStatistics.new()
var saves := SaveService.new()
var settings := SettingsService.new()
var achievements := AchievementService.new()
var platform: PlatformAdapter
var _frame_fraction_ms: float = 0.0
var _application_focused: bool = true
var _production_error_reported: bool = false
var _timeline_paused: bool = true

func _ready() -> void:
	business_statistics.attach(businesses)
	if not businesses.is_ready():
		push_error("El catálogo de negocios no es válido.")
	platform = WindowsAdapter.new() if OS.get_name() == "Windows" else PlatformAdapter.new()
	var result := settings.load_settings()
	if result != OK and result != ERR_FILE_NOT_FOUND:
		push_warning("No se pudo cargar la configuración: %s" % error_string(result))
	settings.apply_display()

func _process(delta: float) -> void:
	economy.tick()
	if not businesses.is_running() or not _application_focused:
		_frame_fraction_ms = 0.0
		_timeline_paused = true
		return
	if _timeline_paused:
		_timeline_paused = false
		return
	# Frame deltas only: never read system dates or replay a suspended interval.
	var elapsed := minf(maxf(delta, 0.0) * 1000.0, businesses.get_driver_max_frame_ms()) + _frame_fraction_ms
	var whole_ms := int(elapsed)
	_frame_fraction_ms = elapsed - whole_ms
	var result := businesses.advance_ms(whole_ms)
	if result != OK and not _production_error_reported:
		push_warning("Producción detenida por límite o transacción ocupada: " + error_string(result))
		_production_error_reported = true
	elif result == OK:
		_production_error_reported = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_application_focused = false
		_timeline_paused = true
		_frame_fraction_ms = 0.0
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_application_focused = true
