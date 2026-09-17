extends Node

signal divisions_changed
signal division_milestone(division, message)

const STATUS_ACTIVE := "ACTIVE"
const STATUS_LOCKED := "LOCKED"
const STRATEGIES := ["BALANCED", "PERFORMANCE", "EFFICIENCY", "RELIABILITY", "INNOVATION"]

var divisions: Dictionary = {}

func reset(starting_sector: String = "CPU") -> void:
	_build_defaults(starting_sector)
	divisions_changed.emit()

func _build_defaults(starting_sector: String) -> void:
	divisions = {}
	for sector_value in GameData.get_sector_keys():
		var sector := str(sector_value)
		var status := STATUS_ACTIVE if sector == starting_sector and GameData.is_sector_active(sector) else STATUS_LOCKED
		divisions[sector] = _new_division(sector, status)
	if not divisions.has("CPU"):
		divisions["CPU"] = _new_division("CPU", STATUS_ACTIVE)
	# La vertical slice doit toujours rester récupérable, y compris depuis une ancienne sauvegarde.
	divisions["CPU"].status = STATUS_ACTIVE

func _new_division(sector: String, status: String) -> Dictionary:
	var sector_data: Dictionary = GameData.SECTORS.get(sector, {})
	return {
		"id": sector,
		"sector": sector,
		"label": str(sector_data.get("label", sector)),
		"status": status,
		"strategy": "BALANCED",
		"maturity": 12.0 if status == STATUS_ACTIVE else 0.0,
		"generation_count": 0,
		"leader_id": "",
		"monthly_budget": 0
	}

func get_active_division_keys() -> Array:
	var result: Array = []
	for sector_value in divisions.keys():
		var sector := str(sector_value)
		if is_operational(sector):
			result.append(sector)
	result.sort()
	return result

func get_division(sector: String) -> Dictionary:
	return divisions.get(sector, {}).duplicate(true)

func is_operational(sector: String) -> bool:
	if not divisions.has(sector) or not GameData.is_sector_active(sector):
		return false
	return str(divisions[sector].get("status", STATUS_LOCKED)) == STATUS_ACTIVE

func set_strategy(sector: String, strategy: String) -> bool:
	if not is_operational(sector) or not STRATEGIES.has(strategy):
		return false
	divisions[sector].strategy = strategy
	divisions_changed.emit()
	return true

func set_monthly_budget(sector: String, amount: int) -> bool:
	if not is_operational(sector):
		return false
	divisions[sector].monthly_budget = maxi(amount, 0)
	divisions_changed.emit()
	return true

func set_leader(sector: String, employee_id: String) -> bool:
	if not is_operational(sector):
		return false
	divisions[sector].leader_id = employee_id
	divisions_changed.emit()
	return true

func record_completed_generation(sector: String) -> void:
	if not is_operational(sector):
		return
	var division: Dictionary = divisions[sector]
	division.generation_count = int(division.get("generation_count", 0)) + 1
	division.maturity = clampf(float(division.get("maturity", 0.0)) + 6.0, 0.0, 100.0)
	var message := "%s gagne en maturité après une génération terminée." % str(division.get("label", sector))
	division_milestone.emit(division.duplicate(true), message)
	divisions_changed.emit()

func get_state() -> Dictionary:
	return {"divisions": divisions.duplicate(true)}

func load_state(state: Dictionary) -> void:
	var starting_sector := str(CompanyManager.starting_sector) if CompanyManager.created else "CPU"
	_build_defaults(starting_sector)
	var saved_value = state.get("divisions", {})
	if typeof(saved_value) == TYPE_DICTIONARY:
		var saved: Dictionary = saved_value
		for sector_value in saved.keys():
			var sector := str(sector_value)
			if not divisions.has(sector) or typeof(saved[sector_value]) != TYPE_DICTIONARY:
				continue
			var source: Dictionary = saved[sector_value]
			var target: Dictionary = divisions[sector]
			target.strategy = str(source.get("strategy", target.strategy))
			if not STRATEGIES.has(str(target.strategy)):
				target.strategy = "BALANCED"
			target.maturity = clampf(float(source.get("maturity", target.maturity)), 0.0, 100.0)
			target.generation_count = maxi(int(source.get("generation_count", 0)), 0)
			target.leader_id = str(source.get("leader_id", ""))
			target.monthly_budget = maxi(int(source.get("monthly_budget", 0)), 0)
			var requested_status := str(source.get("status", target.status))
			target.status = STATUS_ACTIVE if requested_status == STATUS_ACTIVE and GameData.is_sector_active(sector) else STATUS_LOCKED
	# Migration des sauvegardes V3 et antérieures : la division CPU n'existait pas encore.
	divisions["CPU"].status = STATUS_ACTIVE
	divisions_changed.emit()
