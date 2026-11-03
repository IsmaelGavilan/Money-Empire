class_name SaveService
extends RefCounted
## Slot contract only: persistence/autosave is deliberately not implemented yet.
const SLOT_COUNT: int = 3
func is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT
func save_slot(slot: int, _payload: Dictionary) -> Error:
	if not is_valid_slot(slot):
		return ERR_INVALID_PARAMETER
	return ERR_UNAVAILABLE
func load_slot(slot: int) -> Dictionary:
	return {"error": ERR_UNAVAILABLE if is_valid_slot(slot) else ERR_INVALID_PARAMETER}
