extends Node

signal save_completed(ok, message)

const SAVE_PATH := "user://tech_empire_save.json"
const SAVE_VERSION := 21

func save_game():
	if not CompanyManager.created:
		save_completed.emit(false, "Aucune partie à sauvegarder.")
		return
	var state := {
		"version":SAVE_VERSION,
		"time":TimeManager.get_state(),
		"economy":Economy.get_state(),
		"company":CompanyManager.get_state(),
		"divisions":DivisionManager.get_state(),
		"personnel":PersonnelManager.get_state(),
		"executive":ExecutiveManager.get_state(),
		"research":ResearchManager.get_state(),
		"foundry":FoundryManager.get_state(),
		"production":ProductionManager.get_state(),
		"patents":PatentManager.get_state(),
		"products":ProductManager.get_state(),
		"after_sales":AfterSalesManager.get_state(),
		"market":MarketManager.get_state(),
		"media":MediaManager.get_state()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_completed.emit(false, "Impossible d'ouvrir le fichier de sauvegarde.")
		return
	file.store_string(JSON.stringify(state))
	file.close()
	save_completed.emit(true, "Partie sauvegardée.")

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
	ExecutiveManager.load_state(state.get("executive", {}))
	ResearchManager.load_state(state.get("research", {}))
	FoundryManager.load_state(state.get("foundry", {}))
	ProductionManager.load_state(state.get("production", {}))
	PatentManager.load_state(state.get("patents", {}))
	ProductManager.load_state(state.get("products", {}))
	AfterSalesManager.load_state(state.get("after_sales", {}))
	TimeManager.load_state(state.get("time", {}))
	MarketManager.load_state(state.get("market", {}))
	MediaManager.load_state(state.get("media", {}))
	save_completed.emit(true, "Partie chargée.")
	return true
