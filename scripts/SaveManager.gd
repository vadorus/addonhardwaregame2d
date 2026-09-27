extends Node

signal save_completed(ok, message)

# Emplacement 0 = sauvegarde automatique (même fichier qu'avant : les anciennes parties restent lisibles).
const SAVE_PATH := "user://tech_empire_save.json"
const TEMP_SAVE_PATH := "user://tech_empire_save.json.tmp"
const BACKUP_SAVE_PATH := "user://tech_empire_save.json.bak"
const SLOT_COUNT := 3 # emplacements manuels 1..3
const SAVE_VERSION := 29
const RNG_STATE_SECTIONS := ["personnel", "suppliers", "research", "foundry", "production", "after_sales", "market"]

# --- Chemins ----------------------------------------------------------------

func slot_path(slot: int) -> String:
	return SAVE_PATH if slot <= 0 else "user://tech_empire_slot_%d.json" % slot

func _slot_temp(slot: int) -> String:
	return TEMP_SAVE_PATH if slot <= 0 else slot_path(slot) + ".tmp"

func _slot_backup(slot: int) -> String:
	return BACKUP_SAVE_PATH if slot <= 0 else slot_path(slot) + ".bak"

# --- Sauvegarde -------------------------------------------------------------

func save_game(quiet: bool = false) -> bool:
	# quiet = sauvegarde automatique : pas de message de succès (évite d'écraser la ligne de statut).
	return save_to_slot(0, quiet)

func save_to_slot(slot: int, quiet: bool = false) -> bool:
	if not CompanyManager.created:
		if not quiet:
			save_completed.emit(false, "Aucune partie à sauvegarder.")
		return false
	slot = clampi(slot, 0, SLOT_COUNT)
	var state := {
		"version":SAVE_VERSION,
		"meta":{
			"company":CompanyManager.company_name, "month":TimeManager.month, "year":TimeManager.year,
			"money":Economy.money, "saved_at":int(Time.get_unix_time_from_system())
		},
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
	if not _write_atomic(JSON.stringify(state), slot_path(slot), _slot_temp(slot), _slot_backup(slot)):
		save_completed.emit(false, "Impossible d'écrire la sauvegarde de façon sûre.")
		return false
	if not quiet:
		save_completed.emit(true, "Partie sauvegardée." if slot == 0 else "Partie sauvegardée dans l'emplacement %d." % slot)
	return true

# --- Chargement -------------------------------------------------------------

func load_game() -> bool:
	return load_from_slot(0)

func load_from_slot(slot: int) -> bool:
	slot = clampi(slot, 0, SLOT_COUNT)
	var state := _read_save_state(slot_path(slot))
	if state.is_empty() and FileAccess.file_exists(_slot_backup(slot)):
		state = _read_save_state(_slot_backup(slot))
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

# --- Informations d'emplacement (écran de choix) -----------------------------

func slot_info(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		path = _slot_backup(slot)
		if not FileAccess.file_exists(path):
			return {"exists":false, "slot":slot}
	var state := _read_save_state(path)
	if state.is_empty():
		return {"exists":false, "slot":slot}
	var meta: Dictionary = state.get("meta", {})
	var company: Dictionary = state.get("company", {})
	var time_state: Dictionary = state.get("time", {})
	return {
		"exists":true, "slot":slot,
		"company":str(meta.get("company", company.get("company_name", "Entreprise"))),
		"month":int(meta.get("month", time_state.get("month", 1))),
		"year":int(meta.get("year", time_state.get("year", 1971))),
		"money":int(meta.get("money", 0)),
		"saved_at":int(meta.get("saved_at", FileAccess.get_modified_time(path)))
	}

func has_any_save() -> bool:
	for slot in range(SLOT_COUNT + 1):
		if bool(slot_info(slot).get("exists", false)):
			return true
	return false

## Emplacement le plus récent (-1 si aucune sauvegarde) : c'est ce que « Continuer » charge.
func most_recent_slot() -> int:
	var best := -1
	var best_time := -1
	for slot in range(SLOT_COUNT + 1):
		var info := slot_info(slot)
		if bool(info.get("exists", false)) and int(info.get("saved_at", 0)) > best_time:
			best_time = int(info.get("saved_at", 0))
			best = slot
	return best

func delete_slot(slot: int) -> void:
	for path in [slot_path(slot), _slot_backup(slot), _slot_temp(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

# --- Écriture atomique --------------------------------------------------------

func _write_atomic(json_text: String, target: String = SAVE_PATH, temp: String = TEMP_SAVE_PATH, backup: String = BACKUP_SAVE_PATH) -> bool:
	var temp_file := FileAccess.open(temp, FileAccess.WRITE)
	if temp_file == null:
		return false
	temp_file.store_string(json_text)
	temp_file.flush()
	temp_file.close()

	var target_abs := ProjectSettings.globalize_path(target)
	var temp_abs := ProjectSettings.globalize_path(temp)
	var backup_abs := ProjectSettings.globalize_path(backup)

	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup_abs)
	if FileAccess.file_exists(target):
		if DirAccess.rename_absolute(target_abs, backup_abs) != OK:
			DirAccess.remove_absolute(temp_abs)
			return false

	if DirAccess.rename_absolute(temp_abs, target_abs) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup_abs, target_abs)
		DirAccess.remove_absolute(temp_abs)
		return false

	# La sauvegarde précédente est conservée en .bak : c'est elle qui est récupérée
	# si la sauvegarde principale est un jour corrompue (coupure, appli tuée par Android…).
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
