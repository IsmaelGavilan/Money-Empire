class_name BusinessStatistics
extends RefCounted
## Signal consumer only; does not decide production, unlocks, or trophies.
var purchased: int = 0
var contracts: int = 0
var upgrades: int = 0
var manual_cycles: int = 0
var automatic_cycles: int = 0
var income := BigMoney.parse("0")
var milestones: Array[int] = []
var income_at_capacity: bool = false

func attach(service: BusinessService) -> void:
	service.business_purchased.connect(_purchased)
	service.business_automated.connect(_automated)
	service.business_upgraded.connect(_upgraded)
	service.production_collected.connect(_produced)
	service.expansion_milestone.connect(_milestone)

func _purchased(_id: String, _order: int) -> void:
	purchased += 1
func _automated(_id: String) -> void:
	contracts += 1
func _upgraded(_id: String, _kind: String, _level: int) -> void:
	upgrades += 1
func _produced(_id: String, amount: BigMoney, cycles: int, automatic: bool) -> void:
	if automatic:
		automatic_cycles += cycles
	else:
		manual_cycles += cycles
	var next := income.add(amount)
	if next != null:
		income = next
	else:
		income_at_capacity = true
func _milestone(count: int, _reward: BigMoney) -> void:
	milestones.append(count)
