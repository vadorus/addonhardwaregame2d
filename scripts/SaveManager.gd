extends Node

signal save_completed(ok, message)
signal slots_changed

const SAVE_DIR := "user://saves"
const LEGACY_SAVE_PATH := "user://tech_empire_save.json"
const SAVE_VERSION := 23
const SLOT_IDS := ["slot_1", "slot_2", "slot_3", "slot_4", "slot_5"]

var current_slot_id := "slot_1"

func _ready() -> void:
	_ensure_save_dir()

func _ensure_save_dir() -> void:
	var absolute_path := ProjectSettings.globalize_path(SAVE_DIR)
	if not DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.make_dir_recursive_absolute(absolute_path)

func _valid_slot(slot_id: String) -> String:
	return slot_id if SLOT_IDS.has(slot_id) else "slot_1"

func _slot_path(slot_id: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, _valid_slot(slot_id)]

func set_current_slot(slot_id: String) -> void:
	current_slot_id = _valid_slot(slot_id)

func get_current_slot() -> String:
	return current_slot_id

func slot_exists(slot_id: String) -> bool:
	return FileAccess.file_exists(_slot_path(slot_id))

func has_any_save() -> bool:
	for slot_id in SLOT_IDS:
		if slot_exists(slot_id):
			return true
	return FileAccess.file_exists(LEGACY_SAVE_PATH)

func first_empty_slot() -> String:
	for slot_id in SLOT_IDS:
		if not slot_exists(slot_id):
			return slot_id
	return "slot_1"

func _read_state(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _slot_metadata(slot_id: String) -> Dictionary:
	var state := _read_state(_slot_path(slot_id))
	if state.is_empty():
		return {
			"slot_id": slot_id,
			"exists": false,
			"slot_name": "Emplacement %d" % (SLOT_IDS.find(slot_id) + 1)
		}
	var meta_value = state.get("meta", {})
	var meta: Dictionary = meta_value if typeof(meta_value) == TYPE_DICTIONARY else {}
	var company_state = state.get("company", {})
	var company: Dictionary = company_state if typeof(company_state) == TYPE_DICTIONARY else {}
	var time_state = state.get("time", {})
	var game_time: Dictionary = time_state if typeof(time_state) == TYPE_DICTIONARY else {}
	var economy_state = state.get("economy", {})
	var economy: Dictionary = economy_state if typeof(economy_state) == TYPE_DICTIONARY else {}
	return {
		"slot_id": slot_id,
		"exists": true,
		"slot_name": str(meta.get("slot_name", company.get("company_name", "Entreprise"))),
		"company_name": str(meta.get("company_name", company.get("company_name", "Entreprise"))),
		"year": int(meta.get("year", game_time.get("year", 1971))),
		"month": int(meta.get("month", game_time.get("month", 1))),
		"day": int(meta.get("day", game_time.get("day", 1))),
		"money": int(meta.get("money", economy.get("money", 0))),
		"saved_unix": int(meta.get("saved_unix", 0)),
		"version": int(state.get("version", 0))
	}

func list_slots() -> Array:
	var slots: Array = []
	var has_modern_save := false
	for slot_id in SLOT_IDS:
		var metadata := _slot_metadata(slot_id)
		slots.append(metadata)
		if bool(metadata.get("exists", false)):
			has_modern_save = true
	if not has_modern_save and FileAccess.file_exists(LEGACY_SAVE_PATH):
		var legacy_state := _read_state(LEGACY_SAVE_PATH)
		if not legacy_state.is_empty():
			var company_state = legacy_state.get("company", {})
			var company: Dictionary = company_state if typeof(company_state) == TYPE_DICTIONARY else {}
			var time_state = legacy_state.get("time", {})
			var game_time: Dictionary = time_state if typeof(time_state) == TYPE_DICTIONARY else {}
			slots.append({
				"slot_id": "legacy",
				"exists": true,
				"legacy": true,
				"slot_name": "Ancienne sauvegarde",
				"company_name": str(company.get("company_name", "Entreprise")),
				"year": int(game_time.get("year", 1971)),
				"month": int(game_time.get("month", 1)),
				"day": int(game_time.get("day", 1)),
				"money": int(legacy_state.get("economy", {}).get("money", 0)),
				"saved_unix": 0,
				"version": int(legacy_state.get("version", 0))
			})
	return slots

func get_latest_slot_id() -> String:
	var latest_slot := ""
	var latest_time := -1
	for slot in list_slots():
		if not bool(slot.get("exists", false)):
			continue
		if bool(slot.get("legacy", false)):
			if latest_slot.is_empty():
				latest_slot = "legacy"
			continue
		var saved_unix := int(slot.get("saved_unix", 0))
		if latest_slot.is_empty() or saved_unix >= latest_time:
			latest_slot = str(slot.get("slot_id", "slot_1"))
			latest_time = saved_unix
	return latest_slot

func _build_state(slot_id: String, slot_name: String) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"meta": {
			"slot_id": slot_id,
			"slot_name": slot_name,
			"company_name": CompanyManager.company_name,
			"year": TimeManager.year,
			"month": TimeManager.month,
			"day": TimeManager.day,
			"money": Economy.money,
			"saved_unix": int(Time.get_unix_time_from_system())
		},
		"time": TimeManager.get_state(),
		"balance": BalanceManager.get_state(),
		"economy": Economy.get_state(),
		"company": CompanyManager.get_state(),
		"divisions": DivisionManager.get_state(),
		"personnel": PersonnelManager.get_state(),
		"executive": ExecutiveManager.get_state(),
		"research": ResearchManager.get_state(),
		"foundry": FoundryManager.get_state(),
		"production": ProductionManager.get_state(),
		"patents": PatentManager.get_state(),
		"products": ProductManager.get_state(),
		"after_sales": AfterSalesManager.get_state(),
		"market": MarketManager.get_state(),
		"media": MediaManager.get_state()
	}

func save_game(slot_id: String = "", slot_name: String = "") -> bool:
	if not CompanyManager.created:
		save_completed.emit(false, "Aucune partie à sauvegarder.")
		return false
	_ensure_save_dir()
	var target_slot := current_slot_id if slot_id.is_empty() else _valid_slot(slot_id)
	current_slot_id = target_slot
	var existing := _slot_metadata(target_slot)
	var display_name := slot_name.strip_edges()
	if display_name.is_empty():
		display_name = str(existing.get("slot_name", "")).strip_edges() if bool(existing.get("exists", false)) else ""
	if display_name.is_empty() or display_name.begins_with("Emplacement "):
		display_name = CompanyManager.company_name
	var state := _build_state(target_slot, display_name)
	var file := FileAccess.open(_slot_path(target_slot), FileAccess.WRITE)
	if file == null:
		save_completed.emit(false, "Impossible d'ouvrir l'emplacement de sauvegarde.")
		return false
	file.store_string(JSON.stringify(state))
	file.close()
	save_completed.emit(true, "Partie sauvegardée — %s." % display_name)
	slots_changed.emit()
	return true

func _apply_state(state: Dictionary) -> bool:
	if state.is_empty():
		return false
	CompanyManager.load_state(state.get("company", {}))
	TimeManager.load_state(state.get("time", {}))
	BalanceManager.load_state(state.get("balance", {"active_profile":"STANDARD"}))
	DivisionManager.load_state(state.get("divisions", {}))
	Economy.load_state(state.get("economy", {}))
	PersonnelManager.load_state(state.get("personnel", {}))
	ExecutiveManager.load_state(state.get("executive", {}))
	ResearchManager.load_state(state.get("research", {}))
	FoundryManager.load_state(state.get("foundry", {}))
	ProductionManager.load_state(state.get("production", {}))
	PatentManager.load_state(state.get("patents", {}))
	ProductManager.load_state(state.get("products", {}))
	AfterSalesManager.load_state(state.get("after_sales", {}))
	MarketManager.load_state(state.get("market", {}))
	MediaManager.load_state(state.get("media", {}))
	return true

func load_game(slot_id: String = "") -> bool:
	var requested := current_slot_id if slot_id.is_empty() else slot_id
	var path := ""
	if requested == "legacy":
		path = LEGACY_SAVE_PATH
	else:
		current_slot_id = _valid_slot(requested)
		path = _slot_path(current_slot_id)
		if not FileAccess.file_exists(path) and FileAccess.file_exists(LEGACY_SAVE_PATH):
			path = LEGACY_SAVE_PATH
	if not FileAccess.file_exists(path):
		save_completed.emit(false, "Aucune sauvegarde trouvée.")
		return false
	var state := _read_state(path)
	if state.is_empty():
		save_completed.emit(false, "Sauvegarde invalide.")
		return false
	if not _apply_state(state):
		save_completed.emit(false, "Impossible de charger la sauvegarde.")
		return false
	if path == LEGACY_SAVE_PATH:
		current_slot_id = first_empty_slot()
		save_completed.emit(true, "Ancienne sauvegarde chargée. Elle sera migrée au prochain enregistrement.")
	else:
		save_completed.emit(true, "Partie chargée.")
	return true

func load_latest_game() -> bool:
	var latest := get_latest_slot_id()
	if latest.is_empty():
		save_completed.emit(false, "Aucune sauvegarde trouvée.")
		return false
	return load_game(latest)

func delete_slot(slot_id: String) -> bool:
	if not SLOT_IDS.has(slot_id):
		return false
	var path := _slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return true
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error != OK:
		return false
	if current_slot_id == slot_id:
		current_slot_id = first_empty_slot()
	slots_changed.emit()
	return true
