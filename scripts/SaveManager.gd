extends Node

signal save_completed(ok, message)

const SAVE_PATH := "user://tech_empire_save.json"
const TEMP_SAVE_PATH := "user://tech_empire_save.json.tmp"
const BACKUP_SAVE_PATH := "user://tech_empire_save.json.bak"
const SAVE_VERSION := 29
const RNG_STATE_SECTIONS := ["personnel", "suppliers", "research", "foundry", "production", "after_sales", "market"]

func save_game():
	if not CompanyManager.created:
		save_completed.emit(false, "Aucune partie à sauvegarder.")
		return
	var state := {
		"version":SAVE_VERSION,
		"time":TimeManager.get_state(),
		"balance":BalanceManager.get_state(),
		"economy":Economy.get_state(),
		"company":CompanyManager.get_state(),
		"divisions":DivisionManager.get_state(),
		"personnel":PersonnelManager.get_state(),
		"executive":ExecutiveManager.get_state(),
		"suppliers":SupplierManager.get_state(),
		"research":ResearchManager.get_state(),
		"foundry":FoundryManager.get_state(),
		"production":ProductionManager.get_state(),
		"patents":PatentManager.get_state(),
		"products":ProductManager.get_state(),
		"after_sales":AfterSalesManager.get_state(),
		"market":MarketManager.get_state(),
		"media":MediaManager.get_state()
	}
	if not _write_atomic(JSON.stringify(state)):
		save_completed.emit(false, "Impossible d'écrire la sauvegarde de façon sûre.")
		return
	save_completed.emit(true, "Partie sauvegardée.")

func load_game() -> bool:
	var state := _read_save_state(SAVE_PATH)
	if state.is_empty() and FileAccess.file_exists(BACKUP_SAVE_PATH):
		state = _read_save_state(BACKUP_SAVE_PATH)
		if not state.is_empty():
			save_completed.emit(true, "Sauvegarde principale invalide : copie de secours récupérée.")
	if state.is_empty():
		save_completed.emit(false, "Aucune sauvegarde valide trouvée.")
		return false

	var source_version := int(state.get("version", 1))
	if source_version > SAVE_VERSION:
		save_completed.emit(false, "Cette sauvegarde provient d'une version plus récente du jeu.")
		return false
	state = _migrate_state(state, source_version)

	CompanyManager.load_state(state.get("company", {}))
	TimeManager.load_state(state.get("time", {}))
	BalanceManager.load_state(state.get("balance", {"active_profile":"STANDARD"}))
	DivisionManager.load_state(state.get("divisions", {}))
	Economy.load_state(state.get("economy", {}))
	PersonnelManager.load_state(state.get("personnel", {}))
	ExecutiveManager.load_state(state.get("executive", {}))
	SupplierManager.load_state(state.get("suppliers", {}))
	ResearchManager.load_state(state.get("research", {}))
	FoundryManager.load_state(state.get("foundry", {}))
	ProductionManager.load_state(state.get("production", {}))
	PatentManager.load_state(state.get("patents", {}))
	ProductManager.load_state(state.get("products", {}))
	AfterSalesManager.load_state(state.get("after_sales", {}))
	MarketManager.load_state(state.get("market", {}))
	MediaManager.load_state(state.get("media", {}))
	save_completed.emit(true, "Partie chargée.")
	return true

func _write_atomic(json_text: String) -> bool:
	var temp_file := FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if temp_file == null:
		return false
	temp_file.store_string(json_text)
	temp_file.flush()
	temp_file.close()

	var target_abs := ProjectSettings.globalize_path(SAVE_PATH)
	var temp_abs := ProjectSettings.globalize_path(TEMP_SAVE_PATH)
	var backup_abs := ProjectSettings.globalize_path(BACKUP_SAVE_PATH)

	if FileAccess.file_exists(BACKUP_SAVE_PATH):
		DirAccess.remove_absolute(backup_abs)
	if FileAccess.file_exists(SAVE_PATH):
		if DirAccess.rename_absolute(target_abs, backup_abs) != OK:
			DirAccess.remove_absolute(temp_abs)
			return false

	if DirAccess.rename_absolute(temp_abs, target_abs) != OK:
		if FileAccess.file_exists(BACKUP_SAVE_PATH):
			DirAccess.rename_absolute(backup_abs, target_abs)
		DirAccess.remove_absolute(temp_abs)
		return false

	if FileAccess.file_exists(BACKUP_SAVE_PATH):
		DirAccess.remove_absolute(backup_abs)
	return true

func _read_save_state(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _migrate_state(state: Dictionary, source_version: int) -> Dictionary:
	var migrated := state.duplicate(true)
	if source_version < 29:
		for section_name_value in RNG_STATE_SECTIONS:
			var section_name := str(section_name_value)
			var section_value = migrated.get(section_name, {})
			if typeof(section_value) != TYPE_DICTIONARY:
				continue
			var section: Dictionary = section_value
			for key in ["rng_seed", "rng_state"]:
				if section.has(key):
					section[key] = SaveCodec.int64_to_json(SaveCodec.int64_from_json(section[key], 0))
			migrated[section_name] = section
	migrated["version"] = SAVE_VERSION
	return migrated
