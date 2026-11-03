class_name AchievementService
extends RefCounted
## No catalogue, local unlocks or platform trophies in phase 1.
func unlock(_achievement_id: StringName) -> Error:
	return ERR_UNAVAILABLE
