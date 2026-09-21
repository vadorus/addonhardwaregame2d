extends Node

var failures := 0

func _ready() -> void:
	_test_save_round_trip()
	_test_future_version_validation()
	_test_rng_state_serialization()

	if failures > 0:
		push_error("[CI] save_integrity_test: %d échec(s)." % failures)
		get_tree().quit(1)
	else:
		print("[CI] save_integrity_test: OK")
		get_tree().quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("[CI] " + message)

func _snapshot() -> Dictionary:
	return {
		"company": CompanyManager.get_state(),
		"time": TimeManager.get_state(),
		"balance": BalanceManager.get_state(),
		"economy": Economy.get_state(),
		"research": ResearchManager.get_state(),
		"foundry": FoundryManager.get_state(),
		"production": ProductionManager.get_state(),
		"products": ProductManager.get_state(),
		"after_sales": AfterSalesManager.get_state(),
		"market": MarketManager.get_state()
	}

func _canonical(value) -> Variant:
	return JSON.parse_string(JSON.stringify(value))

func _test_save_round_trip() -> void:
	SimulationManager.reset_all("CI Save Integrity", "CPU", "STANDARD")
	SaveManager.set_current_slot("slot_5")
	var before := _canonical(_snapshot())
	var saved := SaveManager.save_game("slot_5", "CI Save Integrity")
	_check(saved, "Impossible d'écrire le slot de test.")
	if not saved:
		return

	Economy.add_expense(12345, "Mutation test")
	TimeManager.day = 17

	var loaded := SaveManager.load_game("slot_5")
	_check(loaded, "Impossible de recharger le slot de test.")
	if loaded:
		var after := _canonical(_snapshot())
		_check(before == after, "L'état n'est pas identique après sauvegarde/rechargement.")

	SaveManager.delete_slot("slot_5")

func _test_future_version_validation() -> void:
	var path := "user://saves/slot_5.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "Impossible de créer la sauvegarde future de test.")
	if file == null:
		return
	file.store_string(JSON.stringify({
		"version": SaveManager.SAVE_VERSION + 100,
		"company": {},
		"time": {},
		"balance": {},
		"economy": {}
	}))
	file.close()

	var loaded := SaveManager.load_game("slot_5")
	_check(not loaded, "Une sauvegarde créée par une version future a été acceptée.")
	SaveManager.delete_slot("slot_5")

func _test_rng_state_serialization() -> void:
	var managers := [AfterSalesManager, MarketManager, FoundryManager]
	for manager in managers:
		var state: Dictionary = manager.get_state()
		_check(typeof(state.get("rng_state", null)) == TYPE_STRING, "%s n'enregistre pas rng_state comme chaîne." % manager.name)
		var encoded := JSON.stringify(state)
		var decoded = JSON.parse_string(encoded)
		_check(typeof(decoded) == TYPE_DICTIONARY, "%s : état JSON illisible." % manager.name)
		if typeof(decoded) == TYPE_DICTIONARY:
			_check(str(decoded.get("rng_state", "")) == str(state.get("rng_state", "")), "%s : rng_state change après passage JSON." % manager.name)
