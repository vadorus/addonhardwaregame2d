extends RefCounted
## Bugs trouvés sur le Pixel (partie d'Alexandre, 27-28/09) :
## 1. « Traiter : Décider des locaux » ouvrait Entreprise tout en haut, décision enfouie plus bas,
##    et le temps continuait en ×2 pendant qu'on cherchait.
## 2. Nora conseillait un déménagement à 75 000 € pour un garage simplement usé (3/8 places).
## 3. « Continuer » relançait la partie à la vitesse sauvegardée au lieu de la mettre en pause.

static func _find(decision_id: String) -> Dictionary:
	for value in ExecutiveManager.get_ceo_decisions():
		if str(value.get("id", "")) == decision_id:
			return value
	return {}

static func _crew_member(crew: Control, member_id: String) -> Control:
	for member in crew.get("_members"):
		if str((member as Control).get("member_id")) == member_id:
			return member
	return null

static func _crew_alert(crew: Control, member_id: String) -> bool:
	var member := _crew_member(crew, member_id)
	return member != null and bool(member.get("alert"))

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Decisions PDG", "CPU", "STANDARD")
	Economy.money = 400000
	ExecutiveManager.workplace["condition"] = 30.0
	ExecutiveManager.workplace["upgrade_reminder_at"] = -1
	var locaux := _find("WORKPLACE:1")
	if locaux.is_empty():
		return "CEO decision: a worn garage should raise « Décider des locaux »"
	if str(locaux.get("recommendation", "")).find("remise en état") < 0:
		return "CEO decision: Nora recommends moving out of a half-empty garage (%s)" % str(locaux.get("recommendation", ""))

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	host.add_child(viewport)
	var game := (load("res://main.gd") as Script).new() as Control
	viewport.add_child(game)
	var error := _run_in_game(game)
	viewport.queue_free()
	return error

static func _run_in_game(game: Control) -> String:
	var tabs: TabContainer = game.get("tabs")
	tabs.current_tab = 0
	TimeManager.time_scale = 2.0

	# Le bouton vert du garage doit mener à la carte de décision, pas à l'onglet brut.
	var dashboard: Control = game.get("dashboard_screen")
	var garage: Control = dashboard.get("dashboard_garage")
	# L'équipe est visible dans le garage : un personnage par salarié (5 postes max) + Nora.
	garage.call("_refresh_gameplay_overlays")
	var crew: Control = garage.call("crew")
	var expected_crew := mini(PersonnelManager.staff.size(), 5) + 1
	if int(crew.call("member_count")) != expected_crew:
		return "Garage crew: expected %d characters, got %d" % [expected_crew, int(crew.call("member_count"))]
	var first_member: Control = (crew.get("_members") as Array)[0]
	if str(crew.call("line_for", first_member)) == "":
		return "Garage crew: characters have nothing to say"
	var focus: Dictionary = garage.call("focus_decision")
	if not str(focus.get("context", "")).begins_with("CEO:"):
		return "CEO decision: garage focus does not route to the decision card (%s)" % str(focus)
	game.call("_on_dashboard_navigation", int(focus.get("tab", 1)), str(focus.get("context", "")))
	if not bool(game.call("ceo_decision_visible")):
		return "CEO decision: « Traiter : … » did not open the decision card"
	if tabs.current_tab != 0:
		return "CEO decision: the card should open over the garage, not switch tab"
	if TimeManager.time_scale != 0.0:
		return "CEO decision: time keeps running while the decision card is open"
	game.call("close_ceo_decision")
	var panel: Control = game.get("ceo_panel")
	if not bool(game.call("open_ceo_decision", "WORKPLACE:1")):
		return "CEO decision: locaux card did not open"
	var actions: Array = panel.call("option_actions")
	for wanted in ["WORKPLACE_MAINTAIN", "WORKPLACE_DEFER", "WORKPLACE_MOVE", "DETAIL", "LATER"]:
		if not actions.has(wanted):
			return "CEO decision: locaux card misses action %s (%s)" % [wanted, str(actions)]

	# Retour Android / Échap ferme la carte et rend la vitesse d'avant.
	game.call("_handle_back_request")
	if bool(game.call("ceo_decision_visible")):
		return "CEO decision: Back did not close the decision card"
	if TimeManager.time_scale != 2.0:
		return "CEO decision: closing the card did not restore the previous speed"

	# Choisir « remise en état » traite réellement la décision.
	game.call("open_ceo_decision", "WORKPLACE:1")
	var money_before := Economy.money
	if not bool(panel.call("choose", "WORKPLACE_MAINTAIN")):
		return "CEO decision: maintenance failed (%s)" % str(panel.call("feedback_text"))
	if bool(game.call("ceo_decision_visible")) or not _find("WORKPLACE:1").is_empty():
		return "CEO decision: locaux decision still pending after maintenance"
	if Economy.money >= money_before:
		return "CEO decision: maintenance was free"

	# Un dossier RH devient une conversation avec la personne concernée.
	var staff_id := str((PersonnelManager.staff[0] as Dictionary).get("id", ""))
	ExecutiveManager._add_hr_issue("MORALE", "Test moral", staff_id, "Un salarié décroche.", 60.0)
	var hr_id := "HR:%s" % str(ExecutiveManager.hr_issues[0].get("id", ""))
	game.call("_refresh_all")
	if not bool(crew.call("member_count")) or not _crew_alert(crew, staff_id):
		return "Dialogue: the unhappy employee has no « ! » in the garage"
	if not bool(game.call("open_ceo_decision", hr_id)) or not bool(game.call("dialogue_visible")):
		return "Dialogue: the HR decision should open a conversation with the employee"
	if TimeManager.time_scale != 0.0:
		return "Dialogue: time keeps running during a conversation"
	game.call("_on_dialogue_choice", hr_id, "DISCUSS")
	if bool(game.call("dialogue_visible")) or not _find(hr_id).is_empty():
		return "Dialogue: HR issue not resolved by the conversation"

	# Découverte R&D : la chercheuse vient l'annoncer.
	ResearchManager._create_research_event("RELIABILITY", 25.0)
	if not bool(game.call("dialogue_visible")):
		return "Dialogue: an R&D discovery should open a conversation"
	var rnd_key := str((game.get("dialogue_panel").get("dialogue") as Dictionary).get("key", ""))
	game.call("_on_dialogue_choice", rnd_key, "PURSUE")
	if not ResearchManager.get_pending_research_events().is_empty():
		return "Dialogue: R&D discovery not resolved"

	# Un client passe au garage avec une offre.
	var contract := {"id":"B2B-777", "product_id":"PROD-X", "product_name":"tv9", "customer":"Nova Laboratories",
		"units_per_month":40, "unit_price":120, "remaining_months":6, "months_total":6, "status":"PENDING", "sized_to_capacity":true}
	MarketManager.contracts.append(contract)
	game.call("_refresh_all")
	if not _crew_alert(crew, "CLIENT:Nova Laboratories"):
		return "Dialogue: the visiting client does not appear at the garage door"
	crew.call("_on_member_tapped", _crew_member(crew, "CLIENT:Nova Laboratories"))
	if not bool(game.call("dialogue_visible")):
		return "Dialogue: tapping the client should open the conversation"
	game.call("_on_dialogue_choice", "CLIENT:B2B-777", "SIGN")
	if str(contract.get("status", "")) != "ACTIVE":
		return "Dialogue: signing with the client did not activate the contract"
	MarketManager.contracts.erase(contract)
	game.call("_refresh_all")

	# « Voir le dossier complet » emmène à l'onglet en gardant la pause.
	ExecutiveManager.workplace["condition"] = 30.0
	ExecutiveManager.workplace["upgrade_reminder_at"] = -1
	TimeManager.time_scale = 3.0
	game.call("open_ceo_decision", "WORKPLACE:1")
	panel.call("choose", "DETAIL")
	if tabs.current_tab != 1 or TimeManager.time_scale != 0.0:
		return "CEO decision: detail should open Entreprise with time paused (tab %d, speed %.1f)" % [tabs.current_tab, TimeManager.time_scale]
	# … et directement sur la sous-page « Locaux & RH », pas en haut d'une page de 4 écrans.
	var company: Control = game.get("company_screen")
	if str(company.call("current_section")) != "WORKPLACE":
		return "CEO decision: detail should open the « Locaux & RH » sub-page (got %s)" % str(company.call("current_section"))

	# Sous-pages : le garage mène à la bonne page du Laboratoire.
	var lab: Control = game.get("lab_screen")
	game.call("_on_dashboard_navigation", 3, "R&D")
	if str(lab.call("current_section")) != "RESEARCH":
		return "Lab: « Recherche & technologies » should open the Recherche sub-page (got %s)" % str(lab.call("current_section"))
	game.call("_on_dashboard_navigation", 3, "Réglages avancés")
	if str(lab.call("current_section")) != "NEW":
		return "Lab: the workbench should open the Nouveau CPU sub-page"
	# Lot A : le SAV n'existe plus qu'en Produits › SAV ; un ancien repère « Marché + SAV » y mène.
	var products: Control = game.get("products_screen")
	game.call("_on_dashboard_navigation", 5, "SAV")
	if tabs.current_tab == 5:
		return "SAV context should no longer open the Market tab"
	# (l'onglet Produits peut être encore verrouillé en début de partie)
	if tabs.current_tab == 4 and str(products.call("current_section")) != "SUPPORT":
		return "Products: SAV context should open the SAV stage"
	game.call("_show_tab", 0)

	# Une partie chargée repart en pause, même sauvegardée en ×3.
	# (l'emplacement 3 d'un joueur qui lance les tests sur son PC est préservé)
	var slot_path := SaveManager.slot_path(3)
	var previous := FileAccess.get_file_as_string(slot_path) if FileAccess.file_exists(slot_path) else ""
	TimeManager.time_scale = 3.0
	if not SaveManager.save_to_slot(3, true):
		return "CEO decision: could not save test slot"
	TimeManager.time_scale = 3.0
	game.call("_load_game_slot", 3)
	SaveManager.delete_slot(3)
	if previous != "":
		var restore := FileAccess.open(slot_path, FileAccess.WRITE)
		restore.store_string(previous)
		restore.close()
	if TimeManager.time_scale != 0.0:
		return "Loaded game resumes at saved speed instead of paused (%.1f)" % TimeManager.time_scale
	return ""
