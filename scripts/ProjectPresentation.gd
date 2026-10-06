extends RefCounted
## One presentation of simulation state shared by garage, cockpit and workshop.
const ACTIVITY := preload("res://scripts/SoftwareActivityCatalog.gd")

static func rows() -> Array:
	var result: Array = []
	for value in ResearchManager.projects:
		var project: Dictionary = value
		if str(project.get("status", "")) == "DEVELOPMENT" and str(project.get("sector", "")) == "CPU":
			result.append(cpu(project))
	for value in SoftwareManager.projects:
		result.append(software(value))
	for value in SoftwareManager.activities:
		result.append(contract(value))
	return result

static func cpu(project: Dictionary) -> Dictionary:
	var phase := clampi(int(project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
	var blocked := not ResearchManager.cpu_pending_directive(project).is_empty() or not (project.get("pending_decision", {}) as Dictionary).is_empty()
	var assigned := 0.0 if blocked else float(PersonnelManager.allocation_for({"id":str(project.id), "kind":"CPU", "need":2.0}).get("assigned", 0.0))
	var progress := clampf((float(phase) + float(project.get("phase_progress", 0.0)) / 100.0) / float(GameData.PHASES.size()) * 100.0, 0.0, 100.0)
	var phase_label := str(GameData.PHASES[phase])
	var state := "Choix requis" if blocked else "Sans équipe" if assigned <= 0.0 else phase_label
	return {"id":str(project.id), "kind":"CPU", "name":str(project.get("name", "CPU")), "phase":phase_label,
		"phase_index":phase, "phase_count":GameData.PHASES.size(), "progress":progress, "blocked":blocked,
		"assigned":assigned, "need":2.0, "remaining":-1, "cost":Economy.quoted_expense(int(project.get("monthly_cash_cost", 0)), "Développement CPU"),
		"state":state, "detail":state + _team_suffix(assigned, blocked), "context":"PROJECT_COCKPIT:" + str(project.id)}

static func software(project: Dictionary) -> Dictionary:
	var status := str(project.get("status", "DEVELOPMENT"))
	var blocked := status in ["DECISION", "REVIEW"] or not SoftwareManager.software_pending_directive(project).is_empty()
	var forecast := SoftwareManager.work_preview(project)
	var assigned := 0.0 if blocked else float(forecast.get("assigned", 0.0))
	var phase := SoftwareManager.software_cockpit_phase(project)
	var phases := ["PLANNING", "BUILD", "STABILIZE"]
	var phase_label := software_phase(phase)
	if str(project.get("kind", "")) == "PATCH": phase_label = "Correctif"
	if str(project.get("kind", "")) == "UPDATE": phase_label = "Mise à jour"
	if status == "BETA": phase_label = "Tests utilisateurs"
	var state := "Prêt à sortir" if status == "REVIEW" else "Choix requis" if blocked else "Sans équipe" if assigned <= 0.0 else phase_label
	var remaining := int(forecast.get("remaining", -1))
	var detail := state + _team_suffix(assigned, blocked)
	if not blocked and remaining >= 0: detail += " • ~%d mois" % remaining
	return {"id":str(project.id), "kind":"SOFTWARE", "name":str(project.get("name", "Logiciel")), "phase":phase_label,
		"phase_index":maxi(0, phases.find(phase)), "phase_count":3, "progress":float(forecast.get("progress", 0.0)),
		"blocked":blocked, "assigned":assigned, "need":float(PersonnelManager.software_task(project).need),
		"remaining":remaining, "cost":Economy.quoted_expense(int(round(float(project.get("monthly_cost", 0)) * (0.6 if status == "BETA" else 1.0))), "Bêta software" if status == "BETA" else "Développement software"), "state":state, "detail":detail,
		"context":"PROJECT_COCKPIT:" + str(project.id)}

static func contract(activity: Dictionary) -> Dictionary:
	var activity_id := str(activity.id)
	var terms := SoftwareManager.activity_terms(activity_id, str(activity.get("approach", "BALANCED")))
	var assigned := float(terms.get("assigned", 0.0))
	return {"id":"ACT:" + activity_id, "kind":"CONTRACT", "name":ACTIVITY.label(activity_id), "phase":"Livraison client",
		"phase_index":1, "phase_count":3, "progress":float(terms.get("progress", 0.0)), "blocked":false,
		"assigned":assigned, "need":1.0, "remaining":int(terms.get("calendar_months", -1)), "cost":int(terms.get("monthly_cash_cost", 0)),
		"state":"Contrat", "detail":"~%d mois • %.1f pers." % [int(terms.get("calendar_months", -1)), assigned],
		"context":"SOFTWARE_CONTRACTS"}

static func software_phase(phase: String) -> String:
	return str({"PLANNING":"Planification", "BUILD":"Construction", "STABILIZE":"Stabilisation"}.get(phase, phase))

static func _team_suffix(assigned: float, blocked: bool) -> String:
	return " • en attente de votre décision" if blocked else " • %.1f pers." % assigned
