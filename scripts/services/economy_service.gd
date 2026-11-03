class_name EconomyService
extends RefCounted
## Phase 1 read model. Mutations and click rules belong to phase 2.
signal balance_changed(value: int)
var _balance: int = 0
func get_balance() -> int:
	return _balance
