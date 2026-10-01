extends RefCounted
## Lot B (29/09) : contrats d'études, prêt bancaire, grands moments du premier CPU.

const INTERACTIONS := preload("res://scripts/Interactions.gd")

static func run() -> String:
	SimulationManager.reset_all("CI Garage Business", "CPU", "STANDARD")
	ExecutiveManager.months_operated = 3
	# V0.10 / I2 : personne ne vient avant le premier CPU en vente (le novice a son premier projet à mener).
	for _i in range(4):
		GarageBusiness.process_month()
	if not GarageBusiness.open_offers().is_empty():
		return "I2: no client offer before the first CPU is on sale"
	var first_cpu := {"id":"I2-CPU", "name":"Garage 1", "sector":"CPU", "status":"LAUNCHED", "company":CompanyManager.company_name,
		"price":120, "unit_cost":40, "production_capacity":300, "months_on_market":3, "target_segment":"EMBEDDED",
		"metrics":{"performance":80.0, "efficiency":80.0, "reliability":85.0, "usability":70.0, "innovation":70.0, "ecosystem":60.0, "sustainability":60.0}}
	ProductManager.products.append(first_cpu)
	# 1. Une fois le premier CPU en vente, un client arrive vite.
	for _i in range(3):
		GarageBusiness.process_month()
		if not GarageBusiness.open_offers().is_empty():
			break
	var offers := GarageBusiness.open_offers()
	if offers.size() != 1:
		return "Garage business: a design contract offer should appear after a few months (got %d)" % offers.size()
	var study: Dictionary = offers[0]
	var key := "STUDY:%s" % str(study.get("id", ""))
	var found := false
	for item in INTERACTIONS.pending():
		if str((item as Dictionary).get("key", "")) == key and str((item as Dictionary).get("speaker", "")).begins_with("CLIENT:"):
			found = true
	if not found:
		return "Garage business: the client offer should be a visitor waiting at the garage"
	if INTERACTIONS.dialogue(key).is_empty():
		return "Garage business: the client offer has no conversation"
	# I2 : une seule offre à la fois — tant que ce client attend, aucun contrat ni appel d'offres de plus.
	for _i in range(40):
		MarketManager.maybe_generate_b2b(first_cpu)
	for contract_value in MarketManager.contracts:
		if str((contract_value as Dictionary).get("status", "")) == "PENDING":
			return "I2: a second client offer appeared while the first one was still waiting"
	# I2 : jamais sur le bouton vert ni dans « prochaine étape ».
	var hub: Control = (load("res://ui/GarageHub.gd") as Script).new() as Control
	hub.set("decision_source", func(): return ExecutiveManager.get_ceo_decisions())
	var focus: Dictionary = hub.call("_compute_focus")
	hub.free()
	if str(focus.get("category", "")) in ["CLIENT", "SOUS-TRAITANCE", "CONTRAT"]:
		return "I2: a client offer must never take the green button (%s)" % str(focus.get("title", ""))
	var decision_found := false
	for decision in ExecutiveManager.get_ceo_decisions():
		if str((decision as Dictionary).get("id", "")) == key:
			decision_found = true
	if not decision_found:
		return "Garage business: the client offer should appear in « À faire »"
	var money_before := Economy.money
	if not bool(INTERACTIONS.choose(key, "SIGN").get("ok", false)):
		return "Garage business: signing the contract failed"
	if Economy.money <= money_before:
		return "Garage business: signing should pay an advance right away"
	if GarageBusiness.development_speed_factor() >= 1.0:
		return "Garage business: an active contract should occupy part of the development team"
	var money_signed := Economy.money
	for _i in range(int(study.get("months", 2))):
		GarageBusiness.process_month()
	if str(study.get("status", "")) != "DONE" or Economy.money <= money_signed:
		return "Garage business: the contract should be delivered and the balance paid"
	if GarageBusiness.development_speed_factor() < 1.0:
		return "Garage business: the team should be free again after delivery"
	# Pas d'offre si le joueur vit déjà de ses CPU (grande équipe).
	for _i in range(10):
		PersonnelManager.generate_candidate("Développement")
		PersonnelManager.hire_candidate()
	if GarageBusiness.study_window_open() and PersonnelManager.staff.size() >= 12:
		return "Garage business: design contracts should fade out once the company has grown"

	# 2. Prêt bancaire.
	var terms := GarageBusiness.loan_terms()
	if int(terms.get("amount", 0)) < 60000 or int(terms.get("total", 0)) <= int(terms.get("amount", 0)):
		return "Garage business: loan terms should lend at least 60 000 € with a real cost (%s)" % str(terms)
	var before_loan := Economy.money
	if not GarageBusiness.accept_loan():
		return "Garage business: the loan could not be signed"
	if Economy.money != before_loan + int(terms.amount):
		return "Garage business: the loan amount was not credited"
	if GarageBusiness.accept_loan():
		return "Garage business: a second loan should not be possible while one is running"
	var before_payment := Economy.money
	GarageBusiness.process_month()
	if Economy.money != before_payment - int(terms.monthly):
		return "Garage business: the monthly loan payment was not charged"

	# 3. Premier silicium : la revue prototype du premier CPU devient un moment.
	ResearchManager.projects.append({"id":"CI-SILICON", "name":"CI Silicon", "sector":"CPU", "status":"DEVELOPMENT",
		"pending_decision":{"type":"PROTOTYPE_REVIEW", "confidence":72.0, "weakness":"efficiency"}})
	if GarageBusiness.first_silicon_project().is_empty():
		return "Garage business: the first prototype review should trigger the « premier silicium » moment"
	var silicon := INTERACTIONS.dialogue("MILESTONE:FIRST_SILICON")
	if silicon.is_empty() or str(silicon.get("kicker", "")) != "PREMIER SILICIUM":
		return "Garage business: « premier silicium » conversation missing"
	INTERACTIONS.choose("MILESTONE:FIRST_SILICON", "SEE")
	if not GarageBusiness.first_silicon_project().is_empty():
		return "Garage business: « premier silicium » should only be shown once"

	# 4. Sauvegarde.
	var state := GarageBusiness.get_state().duplicate(true)
	GarageBusiness.reset()
	GarageBusiness.load_state(state)
	if GarageBusiness.active_loan().is_empty() or not bool(GarageBusiness.flags.get("first_silicon_shown", false)):
		return "Garage business: state was not restored from the save"
	ResearchManager.projects = ResearchManager.projects.filter(func(p): return str(p.get("id", "")) != "CI-SILICON")
	GarageBusiness.reset()
	return ""
