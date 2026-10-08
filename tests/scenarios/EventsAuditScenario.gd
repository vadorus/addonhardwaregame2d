extends RefCounted
## Revue des événements (08/10) : les choix font ce qu'ils annoncent, et aucun ne piège le joueur.
## - SAV : surveiller n'efface plus un diagnostic payé ; un dossier grave ignoré pèse ; un dossier calme se referme ;
## - validation finale : deux reprises au plus, ensuite il faut valider ;
## - revue prototype : l'effet annoncé est l'effet appliqué ;
## - trouvaille de développeur : une idée en suspens à la fin d'un CPU passe au carnet au lieu de bloquer ;
## - RH : un dossier traité ne revient pas le mois suivant, la prime collective agit sur la cohésion.

const GATES := preload("res://scripts/DevelopmentGates.gd")
const DISCOVERIES := preload("res://scripts/WorkshopDiscoveries.gd")
const PROTO_MODEL := preload("res://scripts/CpuPrototypeModel.gd")

static func run(_host: Node) -> String:
	SimulationManager.reset_all("CI Événements", "CPU", "STANDARD")

	# 1. SAV.
	AfterSalesManager.cases = [
		{"id":"SAV-D", "status":"DIAGNOSED", "product_name":"CI", "severity":70.0, "last_return_rate":0.06, "history":[]},
		{"id":"SAV-O", "status":"OPEN", "product_name":"CI", "severity":70.0, "last_return_rate":0.06, "history":[]},
		{"id":"SAV-M", "status":"MONITORING", "product_name":"CI", "severity":30.0, "last_return_rate":0.01, "history":[]},
	]
	if AfterSalesManager.monitor_case("SAV-D") or str(AfterSalesManager.get_case("SAV-D").status) != "DIAGNOSED":
		return "Events: monitoring must not erase a paid diagnosis"
	var support_before := float(CompanyManager.reputation.get("support", 50.0))
	for month in range(AfterSalesManager.CALM_MONTHS_TO_CLOSE):
		AfterSalesManager.process_month()
	if float(CompanyManager.reputation.get("support", 50.0)) >= support_before:
		return "Events: a serious case left open should weigh on support reputation"
	if str(AfterSalesManager.get_case("SAV-M").status) != "CLOSED":
		return "Events: a monitored case with calm returns should close after %d months" % AfterSalesManager.CALM_MONTHS_TO_CLOSE

	# 2. Validation finale bornée.
	var project := {"name":"CI", "validation_rechecks":GATES.MAX_VALIDATION_RECHECKS, "validation_metrics":{"performance":60.0, "reliability":60.0}}
	var review := GATES.build_validation_review(project, {}, project.validation_metrics, {}, 1, 1975)
	if (review.options as Array).size() != 1 or str((review.options as Array)[0].id) != "APPROVE":
		return "Events: after two reworks, the final review should only offer « Valider »"
	if bool(GATES.apply_choice(project, review, "CORRECT").get("ok", true)):
		return "Events: a third rework must be refused"

	# 3. Revue prototype : annoncé = appliqué.
	var proto := {"name":"CI", "cockpit_directive_impact":{"performance":0.0, "efficiency":0.0, "reliability":0.0, "innovation":0.0}}
	var proto_review := GATES.build_prototype_review(proto, {"weakness":"efficiency"}, 1, 1975)
	var push: Dictionary = GATES.option_for(proto_review, "PUSH")
	GATES.apply_choice(proto, proto_review, "PUSH")
	for axis in (push.impact as Dictionary).keys():
		if absf(float((proto.cockpit_directive_impact as Dictionary).get(axis, 0.0)) - float(push.impact[axis])) > 0.001:
			return "Events: the prototype review applied %s, the card announced %s" % [str(proto.cockpit_directive_impact), str(push.impact)]

	# 3 bis. Phases 2 et 4 : des choix différents ; à la phase 4, il reste une option sans surcoût (polir l'efficacité).
	var cpu := {"name":"CI", "monthly_cash_cost":3000, "cpu_design":{}, "design_estimate":{"reliability":70.0, "required_tdp":10.0}}
	var ids_2 := []
	for option in PROTO_MODEL.milestone(cpu, 2).get("options", []): ids_2.append(str(option.id))
	var phase_4: Dictionary = PROTO_MODEL.milestone(cpu, 4)
	var ids_4 := []
	for option in phase_4.get("options", []):
		ids_4.append(str(option.id))
		if str(option.id) == "POWER" and int(option.get("cost_once", 0)) != 0:
			return "Events: redirecting the last phase (%s) should not cost extra budget" % str(option.id)
	if ids_4 == ids_2 or not ids_4.has("BENCH"):
		return "Events: phase 4 must offer its own choices, got %s after %s" % [str(ids_4), str(ids_2)]

	# 4. Trouvaille en suspens à la fin d'un CPU.
	var done := {"id":"CI-DONE", "status":"COMPLETED", "discovery_pending":{"id":"X", "text":"idée", "impact":{"reliability":2.0}}}
	ResearchManager.projects.append(done)
	var notebook_before := ResearchManager.discovery_notebook.size()
	if not DISCOVERIES.pending_project().is_empty():
		return "Events: an idea on a finished CPU must not block the next ones"
	ResearchManager._shelve_pending_discovery(done)
	if ResearchManager.discovery_notebook.size() != notebook_before + 1 or not (done.discovery_pending as Dictionary).is_empty():
		return "Events: a pending idea should move to Nora's notebook when the CPU ends"

	# 5. RH.
	ExecutiveManager._add_hr_issue("COHESION", "Tensions", "R&D", "CI", 50.0)
	var issue: Dictionary = ExecutiveManager.hr_issues[0]
	var cohesion_before := float(CompanyManager.departments["R&D"].get("cohesion", 30.0))
	Economy.money = 100000
	if not ExecutiveManager.resolve_hr_issue(str(issue.id), "BONUS"):
		return "Events: the collective HR bonus could not be paid"
	if float(CompanyManager.departments["R&D"].get("cohesion", 30.0)) < cohesion_before + 11.9:
		return "Events: the collective HR bonus should raise team cohesion"
	if not ExecutiveManager._has_open_issue("COHESION", "R&D"):
		return "Events: a handled HR case should not reopen the next month"
	return ""
