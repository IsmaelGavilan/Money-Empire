class_name PlatformAdapter
extends RefCounted
## SDK-independent contract. Unsupported calls return an explicit error.
func get_platform_name() -> String:
	return "Desktop"
func supports_achievements() -> bool:
	return false
func unlock_achievement(_id: StringName) -> Error:
	return ERR_UNAVAILABLE
