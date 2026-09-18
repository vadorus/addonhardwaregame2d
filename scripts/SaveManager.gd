extends Node

signal save_completed(ok, message)
signal autosave_completed(ok)

const SAVE_PATH := "user://tech_empire_save.json"
const SAVE_VERSION := 10

func _ready():
	if not TimeManager.month_changed.is_connected(_on_month_changed):
		TimeManager.month_changed.connect(_on_month_changed)

func _on_month_changed(_month: int, _year: int):
	if CompanyManager.created:
		autosave_game()

func _build_state() -> Dictionary:
	return {
		"version":SAVE_VERSION,
		"time":TimeManager.get_state(),
		"economy":Economy.get_state(),
		"company":CompanyManager.get_state(),
		"divisions":DivisionManager.get_state(),
		"personnel":PersonnelManager.get_state(),
		"research":ResearchManager.get_state(),
		"reusable_technologies":TechnologyManager.get_state(),
		"discoveries":DiscoveryManager.get_state(),
		"patents":PatentManager.get_state(),
		"products":ProductManager.get_state(),
		"market":MarketManager.get_state(),
		"media":MediaManager.get_state(),
		"department_progression":DepartmentProgression.get_state()
	}

func _write_state() -> bool:
	if not CompanyManager.created:
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_build_state()))
	file.close()
	return true

func save_game():
	if not CompanyManager.created:
		save_completed.emit(false, "Aucune partie à sauvegarder.")
		return
	var ok := _write_state()
	save_completed.emit(ok, "Partie sauvegardée." if ok else "Impossible d'ouvrir le fichier de sauvegarde.")

func autosave_game() -> bool:
	var ok := _write_state()
	autosave_completed.emit(ok)
	return ok

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		save_completed.emit(false, "Aucune sauvegarde trouvée.")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		save_completed.emit(false, "Impossible de lire la sauvegarde.")
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		save_completed.emit(false, "Sauvegarde invalide.")
		return false
	var state: Dictionary = parsed
	CompanyManager.load_state(state.get("company", {}))
	DivisionManager.load_state(state.get("divisions", {}))
	Economy.load_state(state.get("economy", {}))
	PersonnelManager.load_state(state.get("personnel", {}))
	ResearchManager.load_state(state.get("research", {}))
	TechnologyManager.load_state(state.get("reusable_technologies", {}))
	DiscoveryManager.load_state(state.get("discoveries", {}))
	PatentManager.load_state(state.get("patents", {}))
	ProductManager.load_state(state.get("products", {}))
	MarketManager.load_state(state.get("market", {}))
	MediaManager.load_state(state.get("media", {}))
	DepartmentProgression.load_state(state.get("department_progression", {}))
	TimeManager.load_state(state.get("time", {}))
	save_completed.emit(true, "Partie chargée.")
	return true
