extends Node

signal save_completed(ok, message)
signal slots_changed
signal loading_started
signal loading_finished(ok)

const SAVE_DIR := "user://saves"
const LEGACY_SAVE_PATH := "user://tech_empire_save.json"
const SAVE_VERSION := 25
const SLOT_IDS := ["slot_1", "slot_2", "slot_3", "slot_4", "slot_5"]

const STATE_SECTIONS := [
	"time", "balance", "founder", "startup", "economy", "company", "divisions", "personnel",
	"executive", "research", "foundry", "production", "patents",
	"products", "after_sales", "market", "media"
]

var current_slot_id := "slot_1"
var _legacy_loaded_pending := false

func _ready() -> void:
	_ensure_save_dir()

func _ensure_save_dir() -> void:
	var absolute_path := ProjectSettings.globalize_path(SAVE_DIR)
	if not DirAccess.dir_exists_absolute(absolute_path):
		var error := DirAccess.make_dir_recursive_absolute(absolute_path)
		if error != OK:
			push_error("SaveManager: impossible de créer le dossier de sauvegarde (%s)." % error_string(error))

func _valid_slot(slot_id: String) -> String:
	return slot_id if SLOT_IDS.has(slot_id) else "slot_1"

func _slot_path(slot_id: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, _valid_slot(slot_id)]

func _backup_path(path: String) -> String:
	return path + ".bak"

func _temp_path(path: String) -> String:
	return path + ".tmp"

func set_current_slot(slot_id: String) -> void:
	current_slot_id = _valid_slot(slot_id)

func get_current_slot() -> String:
	return current_slot_id

func _read_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: lecture impossible pour %s (%s)." % [path, error_string(FileAccess.get_open_error())])
		return {}
	var text := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		push_warning("SaveManager: erreur de lecture pour %s (%s)." % [path, error_string(read_error)])
		return {}
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		push_warning("SaveManager: JSON invalide dans %s (ligne %d : %s)." % [path, json.get_error_line(), json.get_error_message()])
		return {}
	var parsed = json.data
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _validate_state(state: Dictionary) -> String:
	if state.is_empty():
		return "Sauvegarde vide ou illisible."
	var version := int(state.get("version", 0))
	if version > SAVE_VERSION:
		return "Sauvegarde créée par une version plus récente du jeu (v%d)." % version
	for section in STATE_SECTIONS:
		if state.has(section) and typeof(state[section]) != TYPE_DICTIONARY:
			return "Sauvegarde corrompue : section « %s » invalide." % section
	if state.has("meta") and typeof(state["meta"]) != TYPE_DICTIONARY:
		return "Sauvegarde corrompue : métadonnées invalides."
	return ""

func _migrate_state(raw_state: Dictionary) -> Dictionary:
	var state := raw_state.duplicate(true)
	var version := int(state.get("version", 0))
	if version > SAVE_VERSION:
		return {}
	if version <= 22:
		var meta_value = state.get("meta", {})
		var meta: Dictionary = meta_value if typeof(meta_value) == TYPE_DICTIONARY else {}
		var company_value = state.get("company", {})
		var company: Dictionary = company_value if typeof(company_value) == TYPE_DICTIONARY else {}
		var time_value = state.get("time", {})
		var game_time: Dictionary = time_value if typeof(time_value) == TYPE_DICTIONARY else {}
		var economy_value = state.get("economy", {})
		var economy: Dictionary = economy_value if typeof(economy_value) == TYPE_DICTIONARY else {}
		if not meta.has("company_name"):
			meta["company_name"] = str(company.get("company_name", "Entreprise"))
		if not meta.has("year"):
			meta["year"] = int(game_time.get("year", 1971))
		if not meta.has("month"):
			meta["month"] = int(game_time.get("month", 1))
		if not meta.has("day"):
			meta["day"] = int(game_time.get("day", 1))
		if not meta.has("money"):
			meta["money"] = int(economy.get("money", 0))
		state["meta"] = meta
		state["version"] = 23
		version = 23
	if version <= 23:
		# V24 introduit le parcours garage. Les anciennes sauvegardes sans section
		# startup sont reconnues par StartupManager comme des parties déjà avancées.
		state["version"] = 24
		version = 24
	if version <= 24:
		# V25 ajoute le profil du fondateur et les spécialisations logicielles.
		state["version"] = 25
	return state

func _read_valid_state(path: String) -> Dictionary:
	var raw := _read_json_dictionary(path)
	if raw.is_empty():
		return {}
	var validation_error := _validate_state(raw)
	if not validation_error.is_empty():
		push_warning("SaveManager: %s (%s)" % [validation_error, path])
		return {}
	var migrated := _migrate_state(raw)
	if migrated.is_empty():
		return {}
	validation_error = _validate_state(migrated)
	if not validation_error.is_empty():
		push_warning("SaveManager: migration refusée pour %s : %s" % [path, validation_error])
		return {}
	return migrated

func _read_with_backup(path: String) -> Dictionary:
	var state := _read_valid_state(path)
	if not state.is_empty():
		return state
	var backup := _backup_path(path)
	state = _read_valid_state(backup)
	if not state.is_empty():
		push_warning("SaveManager: sauvegarde principale invalide, récupération depuis %s." % backup)
	return state

func _write_atomic(path: String, state: Dictionary) -> bool:
	var temp := _temp_path(path)
	var backup := _backup_path(path)
	var temp_abs := ProjectSettings.globalize_path(temp)
	var path_abs := ProjectSettings.globalize_path(path)
	var backup_abs := ProjectSettings.globalize_path(backup)

	if FileAccess.file_exists(temp):
		DirAccess.remove_absolute(temp_abs)

	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: ouverture temporaire impossible (%s)." % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(state))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("SaveManager: écriture temporaire échouée (%s)." % error_string(write_error))
		DirAccess.remove_absolute(temp_abs)
		return false

	var written := _read_valid_state(temp)
	if written.is_empty():
		push_error("SaveManager: la sauvegarde temporaire n'est pas relisible.")
		DirAccess.remove_absolute(temp_abs)
		return false

	var main_is_valid := not _read_valid_state(path).is_empty()
	if main_is_valid:
		if FileAccess.file_exists(backup):
			var remove_error := DirAccess.remove_absolute(backup_abs)
			if remove_error != OK:
				push_error("SaveManager: impossible de remplacer la sauvegarde de secours (%s)." % error_string(remove_error))
				DirAccess.remove_absolute(temp_abs)
				return false
		var backup_error := DirAccess.rename_absolute(path_abs, backup_abs)
		if backup_error != OK:
			push_error("SaveManager: impossible de créer la sauvegarde de secours (%s)." % error_string(backup_error))
			DirAccess.remove_absolute(temp_abs)
			return false
	elif FileAccess.file_exists(path):
		# Le principal est illisible : on le retire mais on conserve un .bak valide s'il existe.
		var remove_invalid_error := DirAccess.remove_absolute(path_abs)
		if remove_invalid_error != OK:
			push_error("SaveManager: impossible d'écarter la sauvegarde principale corrompue (%s)." % error_string(remove_invalid_error))
			DirAccess.remove_absolute(temp_abs)
			return false

	var promote_error := DirAccess.rename_absolute(temp_abs, path_abs)
	if promote_error != OK:
		push_error("SaveManager: impossible d'activer la nouvelle sauvegarde (%s)." % error_string(promote_error))
		if not FileAccess.file_exists(path) and FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup_abs, path_abs)
		DirAccess.remove_absolute(temp_abs)
		return false
	return true

func slot_exists(slot_id: String) -> bool:
	return not _read_with_backup(_slot_path(slot_id)).is_empty()

func has_any_save() -> bool:
	for slot_id in SLOT_IDS:
		if slot_exists(slot_id):
			return true
	return not _read_valid_state(LEGACY_SAVE_PATH).is_empty()

func first_empty_slot() -> String:
	for slot_id in SLOT_IDS:
		if not slot_exists(slot_id):
			return slot_id
	return "slot_1"

func _slot_metadata(slot_id: String) -> Dictionary:
	var state := _read_with_backup(_slot_path(slot_id))
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
	if not has_modern_save:
		var legacy_state := _read_valid_state(LEGACY_SAVE_PATH)
		if not legacy_state.is_empty():
			var company_state = legacy_state.get("company", {})
			var company: Dictionary = company_state if typeof(company_state) == TYPE_DICTIONARY else {}
			var time_state = legacy_state.get("time", {})
			var game_time: Dictionary = time_state if typeof(time_state) == TYPE_DICTIONARY else {}
			var economy_state = legacy_state.get("economy", {})
			var economy: Dictionary = economy_state if typeof(economy_state) == TYPE_DICTIONARY else {}
			slots.append({
				"slot_id": "legacy",
				"exists": true,
				"legacy": true,
				"slot_name": "Ancienne sauvegarde",
				"company_name": str(company.get("company_name", "Entreprise")),
				"year": int(game_time.get("year", 1971)),
				"month": int(game_time.get("month", 1)),
				"day": int(game_time.get("day", 1)),
				"money": int(economy.get("money", 0)),
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
		"founder": FounderManager.get_state(),
		"startup": StartupManager.get_state(),
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

func _archive_legacy_after_migration() -> void:
	if not _legacy_loaded_pending or not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	var migrated_path := LEGACY_SAVE_PATH + ".migrated"
	var source_abs := ProjectSettings.globalize_path(LEGACY_SAVE_PATH)
	var target_abs := ProjectSettings.globalize_path(migrated_path)
	if FileAccess.file_exists(migrated_path):
		DirAccess.remove_absolute(target_abs)
	var error := DirAccess.rename_absolute(source_abs, target_abs)
	if error == OK:
		_legacy_loaded_pending = false
	else:
		push_warning("SaveManager: ancienne sauvegarde conservée, archivage impossible (%s)." % error_string(error))

func save_game(slot_id: String = "", slot_name: String = "") -> bool:
	if not CompanyManager.created:
		save_completed.emit(false, "Aucune partie à sauvegarder.")
		return false
	_ensure_save_dir()
	var target_slot := current_slot_id if slot_id.is_empty() else _valid_slot(slot_id)
	var existing := _slot_metadata(target_slot)
	var display_name := slot_name.strip_edges()
	if display_name.is_empty():
		display_name = str(existing.get("slot_name", "")).strip_edges() if bool(existing.get("exists", false)) else ""
	if display_name.is_empty() or display_name.begins_with("Emplacement "):
		display_name = CompanyManager.company_name
	var state := _build_state(target_slot, display_name)
	if not _write_atomic(_slot_path(target_slot), state):
		save_completed.emit(false, "Écriture de la sauvegarde échouée.")
		return false
	current_slot_id = target_slot
	_archive_legacy_after_migration()
	save_completed.emit(true, "Partie sauvegardée — %s." % display_name)
	slots_changed.emit()
	return true

func _apply_state(state: Dictionary) -> bool:
	if state.is_empty():
		return false
	CompanyManager.load_state(state.get("company", {}))
	TimeManager.load_state(state.get("time", {}))
	BalanceManager.load_state(state.get("balance", {"active_profile":"STANDARD"}))
	FounderManager.load_state(state.get("founder", {}))
	StartupManager.load_state(state.get("startup", {}))
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
	var target_slot := current_slot_id
	var path := ""
	var is_legacy := requested == "legacy"
	if is_legacy:
		path = LEGACY_SAVE_PATH
	else:
		target_slot = _valid_slot(requested)
		path = _slot_path(target_slot)

	var state := _read_valid_state(path) if is_legacy else _read_with_backup(path)
	if state.is_empty():
		save_completed.emit(false, "Aucune sauvegarde valide trouvée.")
		return false

	var validation_error := _validate_state(state)
	if not validation_error.is_empty():
		save_completed.emit(false, validation_error)
		return false

	loading_started.emit()
	var loaded := _apply_state(state)
	loading_finished.emit(loaded)
	if not loaded:
		save_completed.emit(false, "Impossible de charger la sauvegarde.")
		return false

	if is_legacy:
		current_slot_id = first_empty_slot()
		_legacy_loaded_pending = true
		save_completed.emit(true, "Ancienne sauvegarde chargée. Elle sera migrée au prochain enregistrement.")
	else:
		current_slot_id = target_slot
		_legacy_loaded_pending = false
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
	var paths := [path, _backup_path(path), _temp_path(path)]
	for candidate in paths:
		if FileAccess.file_exists(candidate):
			var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
			if error != OK:
				push_error("SaveManager: suppression impossible pour %s (%s)." % [candidate, error_string(error)])
				return false
	if current_slot_id == slot_id:
		current_slot_id = first_empty_slot()
	slots_changed.emit()
	return true
