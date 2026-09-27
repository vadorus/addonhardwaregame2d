extends RefCounted
## V0.8.1 — toute décision du PDG doit être visible depuis le garage (zone, bouton vert, Nora).

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Garage Decisions", "CPU", "STANDARD")
	var garage_script: Script = load("res://ui/GarageHub.gd")
	var garage: Control = garage_script.new() as Control
	var fake_decisions: Array = [
		{"id":"HR:1", "category":"RH", "severity":40.0, "title":"Tension dans l'équipe", "recommendation":"Rencontrez l'équipe.", "target_tab":1},
		{"id":"SAV:1", "category":"SAV", "severity":72.0, "title":"Crise SAV — Nova 1", "recommendation":"Lancez une enquête terrain.", "target_tab":5}
	]
	garage.set("decision_source", func() -> Array: return fake_decisions)
	host.add_child(garage)
	garage.size = Vector2(1280, 600)
	var all_unlocked := {"QG":true, "LAB":true, "COMPANY":true, "TEAM":true, "PRODUCTS":true, "MARKET":true, "PRESS":true}
	garage.call("set_progression", all_unlocked)
	garage.call("set_onboarding_stage", "NORMAL")

	var focus: Dictionary = garage.call("focus_decision")
	if str(focus.get("zone", "")) != "Stock & production" or int(focus.get("tab", -1)) != 5:
		garage.queue_free()
		return "Garage does not surface the most severe CEO decision (SAV) on the stock zone: %s" % focus
	if not str(garage.call("primary_action_text")).begins_with("Traiter"):
		garage.queue_free()
		return "Garage primary action does not lead to the pending CEO decision"
	if not str(garage.call("nora_message")).contains("Crise SAV"):
		garage.queue_free()
		return "Nora does not tell the player about the pending CEO decision"
	if not bool(garage.call("open_zone_menu", "Stock & production")):
		garage.queue_free()
		return "Stock zone menu could not be opened while a SAV decision is pending"
	var labels: Array = garage.call("context_action_labels")
	if labels.is_empty() or not str(labels[0]).begins_with("⚠"):
		garage.queue_free()
		return "Stock zone menu does not list the pending SAV decision first"
	garage.call("close_context_menu")

	# Zone verrouillée : la décision doit passer par le rail de gauche, pas disparaître.
	var no_products := all_unlocked.duplicate()
	no_products["PRODUCTS"] = false
	garage.call("set_progression", no_products)
	focus = garage.call("focus_decision")
	if bool(focus.get("zone_visible", true)):
		garage.queue_free()
		return "Locked stock zone is still reported as visible for the SAV decision"
	if not str(garage.call("nora_message")).contains("Marché"):
		garage.queue_free()
		return "Nora does not redirect to the Market shortcut when the stock zone is locked"

	# Plus aucune décision : pas de faux signal.
	fake_decisions.clear()
	garage.call("set_progression", all_unlocked)
	focus = garage.call("focus_decision")
	if not focus.is_empty():
		garage.queue_free()
		return "Garage still shows a decision after all CEO decisions were handled"
	garage.queue_free()
	return ""
