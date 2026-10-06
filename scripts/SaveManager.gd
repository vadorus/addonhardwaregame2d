extends Node

signal save_completed(ok, message)

# Emplacement 0 = sauvegarde automatique (même fichier qu'avant : les anciennes parties restent lisibles).
const SAVE_PATH := "user://tech_empire_save.json"
const TEMP_SAVE_PATH := "user://tech_empire_save.json.tmp"
const BACKUP_SAVE_PATH := "user://tech_empire_save.json.bak"
const SLOT_COUNT := 3 # emplacements manuels 1..3
const SAVE_VERSION := 33
const RNG_STATE_SECTIONS := ["personnel", "suppliers", "research", "foundry", "production", "after_sales", "market"]
const TEST_ROOT := "user://ci_tests/"

## C1 : dossier des sauvegardes. Les tests passent dans un sous-dossier à part (use_test_folder) :
## lancer les tests sur un PC où l'on joue n'efface plus jamais la vraie partie.
var save_root := "user://"
## Faux pendant les outils de capture : le jeu peut charger une partie mais ne peut rien écrire.
var writes_enabled := true

# --- Chemins ----------------------------------------------------------------

func use_test_folder() -> void:
	save_root = TEST_ROOT
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_ROOT))

func _rooted(user_path: String) -> String:
	return save_root + user_path.trim_prefix("user://")

func save_path() -> String:
	return _rooted(SAVE_PATH)

func temp_path() -> String:
	return _rooted(TEMP_SAVE_PATH)

func backup_path() -> String:
	return _rooted(BACKUP_SAVE_PATH)

func slot_path(slot: int) -> String:
	return save_path() if slot <= 0 else _rooted("user://tech_empire_slot_%d.json" % slot)

func _slot_temp(slot: int) -> String:
	return temp_path() if slot <= 0 else slot_path(slot) + ".tmp"

func _slot_backup(slot: int) -> String:
	return backup_path() if slot <= 0 else slot_path(slot) + ".bak"

# --- Sauvegarde -------------------------------------------------------------

func save_game(quiet: bool = false) -> bool:
	# quiet = sauvegarde automatique : pas de message de succès (évite d'écraser la ligne de statut).
	return save_to_slot(0, quiet)

func save_to_slot(slot: int, quiet: bool = false) -> bool:
	if not writes_enabled:
		return false
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
		"media":MediaManager.get_state(),
		"architectures":ArchitectureManager.get_state(),
		"garage_business":GarageBusiness.get_state(),
		"components":ComponentManager.get_state(),
		"software":SoftwareManager.get_state(),
		"objectives":Objectives.get_state()
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
	var best := _best_state(slot)
	var state: Dictionary = best.get("state", {})
	if str(best.get("path", "")) == _slot_backup(slot):
		save_completed.emit(true, "Sauvegarde principale invalide : copie de secours récupérée.")
	elif str(best.get("path", "")) == _slot_temp(slot):
		save_completed.emit(true, "Sauvegarde interrompue récupérée.")
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
	# V0.9 : en dernier, car une ancienne partie déduit ses architectures et gammes des produits et projets.
	ArchitectureManager.load_state(state.get("architectures", {}))
	# Lot B : après les produits (une ancienne partie déjà lancée ne rejoue pas le « premier silicium »).
	GarageBusiness.load_state(state.get("garage_business", {}))
	# V0.10 / Gammes : absent des anciennes parties -> marchés fermés, ouverts au prochain mois si leur date est passée.
	ComponentManager.load_state(state.get("components", {}))
	# Branche Software : absente des anciennes parties -> état neuf selon l'année chargée.
	SoftwareManager.load_state(state.get("software", {}))
	# Lot C : tout en dernier (les objectifs lisent l'état de tous les systèmes).
	Objectives.load_state(state.get("objectives", {}))
	save_completed.emit(true, "Partie chargée.")
	return true

# --- Informations d'emplacement (écran de choix) -----------------------------

## C1 : la meilleure sauvegarde lisible d'un emplacement, et son fichier.
## - La principale et la temporaire : la plus récente des deux qui se relit en entier. Une temporaire complète
##   veut dire que l'appli a été tuée (Android, coupure) entre l'écriture et le remplacement : c'est la plus fraîche.
##   Une temporaire coupée en cours d'écriture ne se relit pas et est ignorée.
## - Sinon la copie de secours (.bak).
func _best_state(slot: int) -> Dictionary:
	var best := {}
	var best_time := -1
	for path in [slot_path(slot), _slot_temp(slot)]:
		var state := _read_save_state(path)
		if state.is_empty() or not state.has("company"):
			continue
		var saved_at := int((state.get("meta", {}) as Dictionary).get("saved_at", 0))
		if saved_at > best_time:
			best_time = saved_at
			best = {"state":state, "path":path}
	if best.is_empty():
		var backup := _read_save_state(_slot_backup(slot))
		if not backup.is_empty() and backup.has("company"):
			best = {"state":backup, "path":_slot_backup(slot)}
	return best

func slot_info(slot: int) -> Dictionary:
	var best := _best_state(slot)
	if best.is_empty():
		return {"exists":false, "slot":slot}
	var path := str(best.path)
	var state: Dictionary = best.state
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

func _write_atomic(json_text: String, target: String = "", temp: String = "", backup: String = "") -> bool:
	if target == "":
		target = save_path()
	if temp == "":
		temp = temp_path()
	if backup == "":
		backup = backup_path()
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
	# JSON.parse (et non parse_string) : un fichier abîmé est un cas prévu, pas une erreur à afficher.
	var json := JSON.new()
	if json.parse(raw) != OK:
		return {}
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}

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
	if source_version < 31:
		var personnel: Dictionary = migrated.get("personnel", {})
		personnel["development_focus"] = "BALANCED"
		migrated["personnel"] = personnel
		var software: Dictionary = migrated.get("software", {})
		var objectives: Dictionary = migrated.get("objectives", {})
		objectives["product_path"] = "CPU" if not (migrated.get("research", {}).get("projects", []) as Array).is_empty() or not (migrated.get("products", {}).get("products", []) as Array).is_empty() else "SOFTWARE" if not (software.get("products", []) as Array).is_empty() or not (software.get("projects", []) as Array).is_empty() else ""
		objectives["new_software_objectives"] = str(objectives.product_path) == "SOFTWARE"
		migrated["objectives"] = objectives
		for list_name in ["projects", "activities"]:
			for value in software.get(list_name, []):
				var project: Dictionary = value
				project["work_done"] = float(project.get("months_done", 0))
				project["elapsed_months"] = int(project.get("months_done", 0))
				if str(project.get("status", "")) == "BETA":
					project["beta_work_done"] = float(project.get("beta_months_done", 0))
	if source_version < 32:
		# Older transferred saves contain a UTF-8 department decoded as CP850/Latin-1.
		# Repair only the known department identifiers, retaining employee IDs and payroll.
		var personnel: Dictionary = migrated.get("personnel", {})
		for list_name in ["staff", "shortlist"]:
			for employee in personnel.get(list_name, []):
				employee["department"] = _canonical_saved_department(str(employee.get("department", "")))
		var candidate: Dictionary = personnel.get("candidate", {})
		if candidate.has("department"):
			candidate["department"] = _canonical_saved_department(str(candidate.department))
		var company: Dictionary = migrated.get("company", {})
		var departments: Dictionary = company.get("departments", {})
		for key in departments.keys():
			var canonical := _canonical_saved_department(str(key))
			if canonical == str(key):
				continue
			var legacy: Dictionary = departments[key]
			if not departments.has(canonical):
				departments[canonical] = legacy.duplicate(true)
			elif str(departments[canonical].get("leader_id", "")) == "":
				departments[canonical]["leader_id"] = str(legacy.get("leader_id", ""))
			departments.erase(key)
		company["departments"] = departments
		migrated["company"] = company
		migrated["personnel"] = personnel
	if source_version < 33:
		# Legacy monthly autosaves were written inside month_processed, before the clock rollover.
		var clock: Dictionary = migrated.get("time", {})
		var history: Array = migrated.get("economy", {}).get("history", [])
		if int(clock.get("day", 1)) > 30 and not history.is_empty():
			var closed: Dictionary = history.back()
			if int(closed.get("month", -1)) == int(clock.get("month", 1)) and int(closed.get("year", -1)) == int(clock.get("year", 1971)):
				clock["day"] = 1
				clock["month"] = int(clock.get("month", 1)) + 1
				if int(clock.month) > 12:
					clock["month"] = 1
					clock["year"] = int(clock.get("year", 1971)) + 1
				migrated["time"] = clock
	migrated["version"] = SAVE_VERSION
	return migrated

func _canonical_saved_department(value: String) -> String:
	if value in ["D├®veloppement", "DÃ©veloppement", "DÃƒÂ©veloppement"]:
		return "Développement"
	return value
