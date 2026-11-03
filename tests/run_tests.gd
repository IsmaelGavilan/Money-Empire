extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	call_deferred("_run")
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
func _run() -> void:
	var services := root.get_node("Services")
	check(services.economy.get_balance() == 0, "Initial balance")
	check(services.saves.is_valid_slot(0) and services.saves.is_valid_slot(2), "Three slot bounds")
	check(not services.saves.is_valid_slot(-1) and not services.saves.is_valid_slot(3), "Reject invalid slots")
	check(services.saves.save_slot(0, {}) == ERR_UNAVAILABLE, "Persistence must not claim success")
	check(services.saves.save_slot(3, {}) == ERR_INVALID_PARAMETER, "Reject invalid writes")
	check(services.saves.load_slot(0).error == ERR_UNAVAILABLE, "Loading unavailable")
	check(services.achievements.unlock(&"test") == ERR_UNAVAILABLE, "Achievements unavailable")
	for adapter in [PlatformAdapter.new(), WindowsAdapter.new(), SteamAdapter.new(), ConsoleAdapter.new()]:
		check(not adapter.supports_achievements(), "No SDK capability claimed")
		check(adapter.unlock_achievement(&"test") == ERR_UNAVAILABLE, "No simulated SDK success")
	# Run with isolated XDG_DATA_HOME: never touch a real player's settings.
	var settings := SettingsService.new()
	check(settings.set_fullscreen(false) == OK, "Persist setting")
	var reloaded := SettingsService.new()
	check(reloaded.load_settings() == OK and not reloaded.fullscreen, "Reload persisted setting")
	for action in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel"]:
		var has_joy := false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_joy = true
		check(has_joy, "Gamepad binding: " + action)
	check(change_scene_to_file("res://scenes/menu/main_menu.tscn") == OK, "Menu loads")
	await process_frame
	await process_frame
	var menu := current_scene
	check(menu.play_button.has_focus(), "Play initially focused")
	check(not menu.play_button.focus_neighbor_bottom.is_empty(), "Explicit focus navigation")
	menu._open_options()
	check(menu.options_panel.get_child(1).has_focus(), "Options focused")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	menu._unhandled_input(cancel)
	await process_frame
	check(menu.play_button.has_focus(), "Cancel restores focus")
	menu.play_button.pressed.emit()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/game/city.tscn", "Play opens city")
	check(current_scene.money_label.text == "DINERO  $ 0", "Balance presentation")
	check(root.get_viewport().gui_get_focus_owner() is Button, "City has controller focus")
	current_scene._unhandled_input(cancel)
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/menu/main_menu.tscn", "Cancel returns to menu")
	print("PHASE1 TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
