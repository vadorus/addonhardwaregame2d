extends Node
## Branche Software — projets, versions, licences, base installée et maintenance.
## Aucun coût de fabrication physique : le coût récurrent vient du support logiciel.

signal software_changed
signal software_launched(product)

const CAT := preload("res://scripts/SoftwareCatalog.gd")
const ACTIVITY := preload("res://scripts/SoftwareActivityCatalog.gd")
const PLAY := preload("res://scripts/SoftwarePlayCatalog.gd")
const PROJECT_COCKPIT := preload("res://scripts/ProjectCockpitModel.gd")
const PROJECT_DIRECTIVES := preload("res://scripts/ProjectDirectiveCatalog.gd")
const SOFTWARE_COCKPIT_AXES := ["features", "usability", "stability", "performance"]
const SOFTWARE_COCKPIT_PHASE_WEIGHTS := {
	"PLANNING": {"features":1.20, "usability":1.45, "stability":0.80, "performance":0.65},
	"BUILD": {"features":1.45, "usability":1.00, "stability":0.80, "performance":1.15},
	"STABILIZE": {"features":0.50, "usability":0.90, "stability":1.65, "performance":1.25}
}
const LAUNCH_MASTERY_CAP := 2

var families: Dictionary = {}
var projects: Array = []
var products: Array = []
var reveals: Array = []
var activities: Array = []
var completed_activities := 0
var skills: Dictionary = {}
var _next_id := 1

func reset() -> void:
	families = {}
	for family_id in CAT.FAMILY_ORDER:
		families[str(family_id)] = _new_family_state(str(family_id))
	projects = []
	products = []
	reveals = []
	activities = []
	completed_activities = 0
	skills = PLAY.empty_skills()
	_next_id = 1
	software_changed.emit()

func _new_family_state(family_id: String) -> Dictionary:
	return {"open":TimeManager.year >= int(CAT.family(family_id).get("unlock_year", 9999)), "mastery":0, "launches":0, "activity_xp":0, "activities_done":0}
func family_state(family_id: String) -> Dictionary:
	if not families.has(family_id):
		families[family_id] = _new_family_state(family_id)
	return families[family_id]

func is_open(family_id: String) -> bool:
	return bool(family_state(family_id).get("open", false))

func any_open() -> bool:
	for family_id in CAT.FAMILY_ORDER:
		if is_open(str(family_id)):
			return true
	return false

func mastery(family_id: String) -> int:
	return int(family_state(family_id).get("mastery", 0))

func max_level(family_id: String) -> int:
	return CAT.max_level(mastery(family_id))

func active_products(family_id: String = "") -> Array:
	return products.filter(func(p): return str(p.get("status", "")) == "ACTIVE" and (family_id == "" or str(p.get("family", "")) == family_id))

func project_for(family_id: String) -> Dictionary:
	for value in projects:
		if str((value as Dictionary).get("family", "")) == family_id:
			return value
	return {}
func next_name(family_id: String) -> String:
	var stem := str(CAT.family(family_id).get("stem", "Software"))
	return "%s %d" % [stem, int(family_state(family_id).get("launches", 0)) + 1]

func monthly_margin() -> int:
	var total := 0
	for value in active_products():
		total += int((value as Dictionary).get("margin_last", 0))
	return total

func _check_unlocks() -> void:
	for family_value in CAT.FAMILY_ORDER:
		var family_id := str(family_value)
		if is_open(family_id):
			continue
		if TimeManager.year < int(CAT.family(family_id).get("unlock_year", 9999)):
			continue
		family_state(family_id)["open"] = true
		CompanyManager.add_alert("Nouveau domaine software : %s. %s" % [CAT.family_label(family_id), str(CAT.family(family_id).get("pitch", ""))])

func available_activities() -> Array:
	return ACTIVITY.available(TimeManager.year)

func active_activity() -> Dictionary:
	return activities[0] if not activities.is_empty() else {}

func activity_terms(activity_id: String, approach_id: String = "BALANCED") -> Dictionary:
	return PLAY.contract_terms(ACTIVITY.data(activity_id), approach_id)

func skill_xp(skill_id: String) -> int:
	return int(skills.get(skill_id, 0))

func can_start_activity(activity_id: String, approach_id: String = "BALANCED") -> Dictionary:
	var data := ACTIVITY.data(activity_id)
	if data.is_empty() or TimeManager.year < int(data.get("from", 9999)):
		return {"ok":false, "reason":"Cette activité n'est pas encore disponible."}
	if not PLAY.APPROACHES.has(approach_id):
		return {"ok":false, "reason":"Approche de travail inconnue."}
	if not activities.is_empty():
		return {"ok":false, "reason":"Une activité courte est déjà en cours."}
	var family_id := str(data.get("family", "UTILITY"))
	if not is_open(family_id):
		return {"ok":false, "reason":"Le domaine Software correspondant n'est pas encore ouvert."}
	var terms := activity_terms(activity_id, approach_id)
	var first_month := int(terms.get("monthly_cost", 0))
	if not Economy.can_afford(first_month, "Activité software"):
		return {"ok":false, "reason":"Trésorerie insuffisante pour démarrer cette activité."}
	return {"ok":true, "reason":""}

func start_activity(activity_id: String, approach_id: String = "BALANCED") -> bool:
	if not bool(can_start_activity(activity_id, approach_id).get("ok", false)):
		return false
	var data := ACTIVITY.data(activity_id)
	activities.append({
		"id":activity_id,
		"family":str(data.get("family", "UTILITY")),
		"approach":approach_id,
		"months_done":0
	})
	software_changed.emit()
	return true

func _gain_activity_xp(family_id: String, amount: int) -> void:
	var state := family_state(family_id)
	state["activity_xp"] = int(state.get("activity_xp", 0)) + maxi(amount, 0)
	while int(state.activity_xp) >= 100 and int(state.mastery) < CAT.MAX_MASTERY:
		state["activity_xp"] = int(state.activity_xp) - 100
		state["mastery"] = int(state.mastery) + 1

func _gain_skills(activity_data: Dictionary, total_xp: int) -> void:
	var weights: Dictionary = activity_data.get("skills", {})
	if weights.is_empty():
		skills["development"] = skill_xp("development") + maxi(total_xp, 0)
		return
	for skill_id_value in weights.keys():
		var skill_id := str(skill_id_value)
		var gain := maxi(1, int(round(float(total_xp) * float(weights[skill_id]))))
		skills[skill_id] = skill_xp(skill_id) + gain

func _utility_levels_from_metrics(metrics: Dictionary) -> Dictionary:
	var levels := {}
	for axis in ["features", "usability", "stability", "performance"]:
		levels[axis] = clampi(int(round(3.0 + (float(metrics.get(axis, 50.0)) - 50.0) / 15.0)), 1, 5)
	return levels

func utility_preview(feature_ids: Array, target_id: String, price_mode: String = "MARKET") -> Dictionary:
	var plan := PLAY.utility_plan(feature_ids, target_id, skills)
	plan["price"] = CAT.license_price("UTILITY", price_mode)
	return plan

func can_start_utility(feature_ids: Array, target_id: String = "HOME") -> Dictionary:
	if not is_open("UTILITY"):
		return {"ok":false, "reason":"Les utilitaires ne sont pas encore disponibles."}
	if not project_for("UTILITY").is_empty():
		return {"ok":false, "reason":"Un utilitaire est déjà en développement."}
	var chosen := PLAY.utility_feature_ids(feature_ids)
	if chosen.size() < 2:
		return {"ok":false, "reason":"Choisissez au moins 2 fonctionnalités."}
	if chosen.size() > 4:
		return {"ok":false, "reason":"Dans le garage, limitez la première version à 4 fonctionnalités."}
	if not PLAY.UTILITY_TARGETS.has(target_id):
		return {"ok":false, "reason":"Public cible inconnu."}
	var plan := PLAY.utility_plan(chosen, target_id, skills)
	if not Economy.can_afford(int(plan.get("monthly_cost", 0)) * 2, "Développement software"):
		return {"ok":false, "reason":"Trésorerie insuffisante pour financer les deux premiers mois."}
	return {"ok":true, "reason":""}

func start_utility_project(feature_ids: Array, target_id: String = "HOME", price_mode: String = "MARKET", product_name: String = "", player_controlled: bool = false) -> bool:
	if not bool(can_start_utility(feature_ids, target_id).get("ok", false)):
		return false
	if not CAT.PRICE_MODES.has(price_mode):
		price_mode = "MARKET"
	var plan := utility_preview(feature_ids, target_id, price_mode)
	var project := {
		"id":"SW-%03d" % _next_id,
		"kind":"UTILITY_SLICE",
		"family":"UTILITY",
		"name":product_name.strip_edges() if product_name.strip_edges() != "" else next_name("UTILITY"),
		"target":target_id,
		"features":(plan.get("features", []) as Array).duplicate(),
		"levels":(plan.get("levels", {}) as Dictionary).duplicate(true),
		"metrics":(plan.get("metrics", {}) as Dictionary).duplicate(true),
		"bugs":int(plan.get("bugs", 0)),
		"price_mode":price_mode,
		"months_total":int(plan.get("months", 1)),
		"months_done":0,
		"monthly_cost":int(plan.get("monthly_cost", 0)),
		"status":"DEVELOPMENT",
		"incident_done":false,
		"pending_decision":{},
		"polish_pending":false,
		"cockpit_priorities":PROJECT_COCKPIT.balanced(SOFTWARE_COCKPIT_AXES),
		"cockpit_influence":{"features":0.0, "usability":0.0, "stability":0.0, "performance":0.0},
		"cockpit_months":0,
		"cockpit_interactive":player_controlled,
		"cockpit_directive_pending":PROJECT_DIRECTIVES.software_milestone("PLANNING") if player_controlled else {},
		"cockpit_directive_history":[]
	}
	_next_id += 1
	projects.append(project)
	software_changed.emit()
	return true

func project_by_id(project_id: String) -> Dictionary:
	for value in projects:
		var project: Dictionary = value
		if str(project.get("id", "")) == project_id:
			return project
	return {}

func active_development_project() -> Dictionary:
	for value in projects:
		var project: Dictionary = value
		if str(project.get("status", "")) == "DEVELOPMENT" and str(project.get("kind", "")) == "UTILITY_SLICE":
			return project
	return {}

func project_cockpit_priorities(project_id: String) -> Dictionary:
	var project := project_by_id(project_id)
	if project.is_empty() or str(project.get("kind", "")) != "UTILITY_SLICE":
		return {}
	return PROJECT_COCKPIT.normalize(project.get("cockpit_priorities", {}), SOFTWARE_COCKPIT_AXES)

func adjust_project_cockpit_priority(project_id: String, axis_id: String, delta: int) -> bool:
	if not SOFTWARE_COCKPIT_AXES.has(axis_id):
		return false
	var project := project_by_id(project_id)
	if project.is_empty() or str(project.get("kind", "")) != "UTILITY_SLICE":
		return false
	if str(project.get("status", "")) != "DEVELOPMENT":
		return false
	project["cockpit_priorities"] = PROJECT_COCKPIT.adjust(
		project.get("cockpit_priorities", {}),
		SOFTWARE_COCKPIT_AXES,
		axis_id,
		delta
	)
	software_changed.emit()
	return true

func software_cockpit_phase(project: Dictionary) -> String:
	var total := maxi(int(project.get("months_total", 1)), 1)
	var done := clampi(int(project.get("months_done", 0)), 0, total)
	var ratio := float(done) / float(total)
	if ratio <= 0.25:
		return "PLANNING"
	if ratio < 0.75:
		return "BUILD"
	return "STABILIZE"

func software_cockpit_phase_weights(project: Dictionary) -> Dictionary:
	return (SOFTWARE_COCKPIT_PHASE_WEIGHTS.get(software_cockpit_phase(project), {}) as Dictionary).duplicate(true)

func software_pending_directive(project: Dictionary) -> Dictionary:
	var value = project.get("cockpit_directive_pending", {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return (value as Dictionary).duplicate(true)

func _software_has_directive_for_phase(project: Dictionary, phase: String) -> bool:
	for value in project.get("cockpit_directive_history", []):
		var entry: Dictionary = value
		if str(entry.get("phase", "")) == phase:
			return true
	return false

func _ensure_software_directive(project: Dictionary) -> bool:
	if not bool(project.get("cockpit_interactive", false)):
		return false
	var pending := software_pending_directive(project)
	if not pending.is_empty():
		return true
	var phase := software_cockpit_phase(project)
	if _software_has_directive_for_phase(project, phase):
		return false
	var milestone := PROJECT_DIRECTIVES.software_milestone(phase)
	if milestone.is_empty():
		return false
	project["cockpit_directive_pending"] = milestone
	CompanyManager.add_alert("%s : choisissez l'orientation de la phase %s." % [
		str(project.get("name", "Logiciel")),
		phase.to_lower()
	])
	software_changed.emit()
	return true

func resolve_software_directive(project_id: String, option_id: String) -> bool:
	var project := project_by_id(project_id)
	if project.is_empty() or str(project.get("status", "")) != "DEVELOPMENT":
		return false
	var pending := software_pending_directive(project)
	if pending.is_empty():
		return false
	var option := PROJECT_DIRECTIVES.option_for(pending, option_id)
	if option.is_empty():
		return false
	var metrics: Dictionary = project.get("metrics", {})
	for axis_value in SOFTWARE_COCKPIT_AXES:
		var axis := str(axis_value)
		metrics[axis] = clampf(
			float(metrics.get(axis, 50.0)) + float((option.get("metrics", {}) as Dictionary).get(axis, 0.0)),
			10.0,
			98.0
		)
	project["metrics"] = metrics
	project["levels"] = _utility_levels_from_metrics(metrics)
	project["bugs"] = maxi(0, int(project.get("bugs", 0)) + int(option.get("bugs", 0)))
	var phase := software_cockpit_phase(project)
	var history: Array = project.get("cockpit_directive_history", [])
	history.append({
		"phase":phase,
		"option_id":option_id,
		"label":str(option.get("label", option_id))
	})
	project["cockpit_directive_history"] = history
	project["cockpit_directive_pending"] = {}
	CompanyManager.add_alert("%s : orientation %s — %s." % [
		str(project.get("name", "Logiciel")),
		phase.to_lower(),
		str(option.get("label", option_id))
	])
	software_changed.emit()
	return true

func _apply_software_cockpit_month(project: Dictionary) -> void:
	if str(project.get("kind", "")) != "UTILITY_SLICE":
		return
	var priorities := PROJECT_COCKPIT.normalize(project.get("cockpit_priorities", {}), SOFTWARE_COCKPIT_AXES)
	project["cockpit_priorities"] = priorities
	var phase := software_cockpit_phase(project)
	var phase_weights := software_cockpit_phase_weights(project)
	var influence: Dictionary = project.get("cockpit_influence", {})
	for axis_value in SOFTWARE_COCKPIT_AXES:
		var axis := str(axis_value)
		var leverage := float(phase_weights.get(axis, 1.0))
		influence[axis] = float(influence.get(axis, 0.0)) + float(priorities.get(axis, 25)) / 100.0 * leverage
	project["cockpit_influence"] = influence
	project["cockpit_months"] = int(project.get("cockpit_months", 0)) + 1

	var metrics: Dictionary = project.get("metrics", {})
	var bias := PROJECT_COCKPIT.month_bias(priorities, SOFTWARE_COCKPIT_AXES, 1.2)
	for axis_value in SOFTWARE_COCKPIT_AXES:
		var axis := str(axis_value)
		var leverage := float(phase_weights.get(axis, 1.0))
		metrics[axis] = clampf(float(metrics.get(axis, 50.0)) + float(bias.get(axis, 0.0)) * leverage, 10.0, 98.0)
	project["metrics"] = metrics
	project["levels"] = _utility_levels_from_metrics(metrics)

	var stability_priority := int(priorities.get("stability", 25))
	var feature_priority := int(priorities.get("features", 25))
	if phase == "STABILIZE" and stability_priority >= 35 and int(project.get("bugs", 0)) > 0:
		project["bugs"] = maxi(0, int(project.get("bugs", 0)) - 2)
	elif stability_priority >= 40 and int(project.get("bugs", 0)) > 0:
		project["bugs"] = maxi(0, int(project.get("bugs", 0)) - 1)
	if phase == "BUILD" and feature_priority >= 45:
		project["bugs"] = int(project.get("bugs", 0)) + 1
	elif phase == "STABILIZE" and feature_priority >= 45:
		project["bugs"] = int(project.get("bugs", 0)) + 2

func pending_project_decision() -> Dictionary:
	for value in projects:
		var project: Dictionary = value
		if str(project.get("status", "")) == "DECISION":
			return project
	return {}

func ready_software_project() -> Dictionary:
	for value in projects:
		var project: Dictionary = value
		if str(project.get("status", "")) == "REVIEW":
			return project
	return {}

func resolve_project_decision(project_id: String, choice: String) -> bool:
	var project := project_by_id(project_id)
	if project.is_empty() or str(project.get("status", "")) != "DECISION":
		return false
	var decision: Dictionary = project.get("pending_decision", {})
	var feature_id := str(decision.get("feature_id", ""))
	match choice:
		"REWRITE":
			project["months_total"] = int(project.get("months_total", 1)) + 1
			project["bugs"] = maxi(0, int(project.get("bugs", 0)) - 5)
			var metrics: Dictionary = project.get("metrics", {})
			metrics["stability"] = clampf(float(metrics.get("stability", 50.0)) + 6.0, 0.0, 100.0)
			project["levels"] = _utility_levels_from_metrics(metrics)
		"CUT":
			var features: Array = (project.get("features", []) as Array).duplicate()
			if features.size() <= 2 or not features.has(feature_id):
				return false
			features.erase(feature_id)
			var plan := PLAY.utility_plan(features, str(project.get("target", "HOME")), skills)
			project["features"] = features
			project["metrics"] = (plan.get("metrics", {}) as Dictionary).duplicate(true)
			project["levels"] = (plan.get("levels", {}) as Dictionary).duplicate(true)
			project["bugs"] = int(plan.get("bugs", 0))
			project["monthly_cost"] = int(plan.get("monthly_cost", project.get("monthly_cost", 0)))
			project["months_total"] = maxi(int(project.get("months_done", 0)) + 1, int(plan.get("months", 1)))
		"QUICK_FIX":
			project["bugs"] = int(project.get("bugs", 0)) + 6
			var metrics: Dictionary = project.get("metrics", {})
			metrics["stability"] = clampf(float(metrics.get("stability", 50.0)) - 4.0, 0.0, 100.0)
			project["levels"] = _utility_levels_from_metrics(metrics)
		_:
			return false
	project["pending_decision"] = {}
	project["status"] = "DEVELOPMENT"
	software_changed.emit()
	return true

func choose_release(project_id: String, choice: String) -> bool:
	var project := project_by_id(project_id)
	if project.is_empty() or str(project.get("status", "")) != "REVIEW":
		return false
	match choice:
		"RELEASE":
			projects.erase(project)
			_launch(project)
		"BETA":
			project["status"] = "BETA"
			project["beta_months_done"] = 0
			CompanyManager.add_alert("Bêta ouverte pour %s : encore un mois de tests." % str(project.get("name", "le logiciel")))
		"DELAY":
			project["status"] = "DEVELOPMENT"
			project["months_total"] = int(project.get("months_total", 1)) + 1
			project["polish_pending"] = true
		_:
			return false
	software_changed.emit()
	return true

func product_by_id(product_id: String) -> Dictionary:
	for value in products:
		var product: Dictionary = value
		if str(product.get("id", "")) == product_id:
			return product
	return {}

func can_start_patch(product_id: String) -> Dictionary:
	var product := product_by_id(product_id)
	if product.is_empty() or str(product.get("status", "")) != "ACTIVE":
		return {"ok":false, "reason":"Produit Software introuvable."}
	if str(product.get("kind", "")) != "UTILITY_SLICE":
		return {"ok":false, "reason":"Les correctifs jouables sont encore réservés aux utilitaires."}
	if not project_for(str(product.get("family", "UTILITY"))).is_empty():
		return {"ok":false, "reason":"L'équipe Software travaille déjà sur cette famille."}
	if int(product.get("bugs_known", 0)) <= 0:
		return {"ok":false, "reason":"Aucun bug connu ne justifie un correctif."}
	var cost := 1800 + int(product.get("bugs_known", 0)) * 40
	if not Economy.can_afford(cost, "Correctif software"):
		return {"ok":false, "reason":"Trésorerie insuffisante pour préparer le correctif."}
	return {"ok":true, "reason":""}

func start_patch(product_id: String) -> bool:
	if not bool(can_start_patch(product_id).get("ok", false)):
		return false
	var product := product_by_id(product_id)
	var cost := 1800 + int(product.get("bugs_known", 0)) * 40
	projects.append({
		"id":"SW-%03d" % _next_id,
		"kind":"PATCH",
		"family":str(product.get("family", "UTILITY")),
		"product_id":product_id,
		"name":"Correctif %s" % str(product.get("name", "Produit")),
		"months_total":1,
		"months_done":0,
		"monthly_cost":cost,
		"status":"DEVELOPMENT"
	})
	_next_id += 1
	software_changed.emit()
	return true

func available_update_features(product_id: String) -> Array:
	var product := product_by_id(product_id)
	if product.is_empty() or str(product.get("kind", "")) != "UTILITY_SLICE":
		return []
	var current: Array = product.get("features", [])
	var result: Array = []
	for feature_value in PLAY.UTILITY_FEATURE_ORDER:
		var feature_id := str(feature_value)
		if not current.has(feature_id):
			result.append(feature_id)
	return result

func can_start_update(product_id: String, feature_id: String) -> Dictionary:
	var product := product_by_id(product_id)
	if product.is_empty() or str(product.get("status", "")) != "ACTIVE":
		return {"ok":false, "reason":"Produit Software introuvable."}
	if str(product.get("kind", "")) != "UTILITY_SLICE":
		return {"ok":false, "reason":"Les mises à jour jouables sont encore réservées aux utilitaires."}
	if not available_update_features(product_id).has(feature_id):
		return {"ok":false, "reason":"Cette fonctionnalité est déjà présente ou indisponible."}
	if not project_for(str(product.get("family", "UTILITY"))).is_empty():
		return {"ok":false, "reason":"L'équipe Software travaille déjà sur cette famille."}
	var feature := PLAY.utility_feature(feature_id)
	var monthly_cost := 2400 + int(round(float(feature.get("cost", 1000)) * 0.45))
	if not Economy.can_afford(monthly_cost * 2, "Mise à jour software"):
		return {"ok":false, "reason":"Trésorerie insuffisante pour lancer cette mise à jour."}
	return {"ok":true, "reason":""}

func start_update(product_id: String, feature_id: String) -> bool:
	if not bool(can_start_update(product_id, feature_id).get("ok", false)):
		return false
	var product := product_by_id(product_id)
	var feature := PLAY.utility_feature(feature_id)
	var months := 2 + maxi(int(feature.get("months", 1)) - 1, 0)
	var monthly_cost := 2400 + int(round(float(feature.get("cost", 1000)) * 0.45))
	projects.append({
		"id":"SW-%03d" % _next_id,
		"kind":"UPDATE",
		"family":str(product.get("family", "UTILITY")),
		"product_id":product_id,
		"feature_id":feature_id,
		"name":"Mise à jour %s" % str(product.get("name", "Produit")),
		"months_total":months,
		"months_done":0,
		"monthly_cost":monthly_cost,
		"status":"DEVELOPMENT"
	})
	_next_id += 1
	software_changed.emit()
	return true

func _complete_maintenance(project: Dictionary) -> void:
	var product := product_by_id(str(project.get("product_id", "")))
	if product.is_empty():
		return
	match str(project.get("kind", "")):
		"PATCH":
			var before := int(product.get("bugs_known", 0))
			product["bugs_known"] = maxi(0, before - maxi(4, int(ceil(float(before) * 0.65))))
			product["version_patch"] = int(product.get("version_patch", 0)) + 1
			var metrics: Dictionary = product.get("metrics", {})
			metrics["stability"] = clampf(float(metrics.get("stability", 50.0)) + 2.0, 0.0, 100.0)
			product["levels"] = _utility_levels_from_metrics(metrics)
			skills["reliability"] = skill_xp("reliability") + 6
			skills["development"] = skill_xp("development") + 3
			CompanyManager.change_reputation({"reliability":0.05, "support":0.04})
			CompanyManager.add_alert("Correctif publié pour %s." % str(product.get("name", "le logiciel")))
		"UPDATE":
			var feature_id := str(project.get("feature_id", ""))
			var features: Array = (product.get("features", []) as Array).duplicate()
			if not features.has(feature_id):
				features.append(feature_id)
			var plan := PLAY.utility_plan(features, str(product.get("target", "HOME")), skills)
			product["features"] = features
			product["metrics"] = (plan.get("metrics", {}) as Dictionary).duplicate(true)
			product["levels"] = (plan.get("levels", {}) as Dictionary).duplicate(true)
			product["bugs_known"] = int(product.get("bugs_known", 0)) + maxi(1, int(ceil(float(PLAY.utility_feature(feature_id).get("bugs", 0)) * 0.50)))
			product["version_minor"] = int(product.get("version_minor", 0)) + 1
			product["version_patch"] = 0
			product["launch_f"] = CAT.year_f(TimeManager.year, TimeManager.month)
			var quality := 0.0
			for score in (product.get("metrics", {}) as Dictionary).values():
				quality += float(score)
			product["quality_launch"] = quality / maxf(float((product.get("metrics", {}) as Dictionary).size()), 1.0)
			var gains := PLAY.utility_skill_gains([feature_id])
			for skill_value in gains.keys():
				var skill_id := str(skill_value)
				skills[skill_id] = skill_xp(skill_id) + int(gains[skill_id])
			CompanyManager.change_reputation({"innovation":0.06, "support":0.03})
			CompanyManager.add_alert("Mise à jour %d.%d publiée pour %s." % [
				int(product.get("version_major", 1)),
				int(product.get("version_minor", 0)),
				str(product.get("name", "le logiciel"))
			])

func preview(family_id: String, levels: Dictionary, price_mode: String) -> Dictionary:
	var months := CAT.dev_months(family_id, levels)
	var monthly := CAT.dev_monthly_cost(family_id, levels, TimeManager.year)
	var scores := CAT.axis_scores(family_id, levels, mastery(family_id), CAT.year_f(TimeManager.year, TimeManager.month), CAT.year_f(TimeManager.year, TimeManager.month))
	var quality := 0.0
	for score in scores.values(): quality += float(score)
	quality /= maxf(float(scores.size()), 1.0)
	return {"months":months, "monthly_cost":monthly, "total_cost":monthly * months, "price":CAT.license_price(family_id, price_mode), "quality":quality, "scores":scores}
func can_start(family_id: String, levels: Dictionary) -> Dictionary:
	if not is_open(family_id):
		return {"ok":false, "reason":"Ce domaine software n'est pas encore ouvert."}
	if not project_for(family_id).is_empty():
		return {"ok":false, "reason":"Une version est déjà en développement dans cette famille."}
	for setting_id in CAT.settings_of(family_id):
		var level := int(levels.get(setting_id, 3))
		if level < 1 or level > max_level(family_id):
			return {"ok":false, "reason":"Ambition trop élevée pour l'expérience de l'équipe."}
	var monthly := CAT.dev_monthly_cost(family_id, levels, TimeManager.year)
	if not Economy.can_afford(monthly * 2, "Développement software"):
		return {"ok":false, "reason":"Trésorerie insuffisante pour financer les premiers mois."}
	return {"ok":true, "reason":""}

func start_project(family_id: String, levels: Dictionary, price_mode: String = "MARKET", product_name: String = "") -> bool:
	if not bool(can_start(family_id, levels).get("ok", false)):
		return false
	if not CAT.PRICE_MODES.has(price_mode): price_mode = "MARKET"
	var clean_levels := {}
	for setting_id in CAT.settings_of(family_id): clean_levels[str(setting_id)] = int(levels.get(setting_id, 3))
	var project := {"id":"SW-%03d" % _next_id, "family":family_id,
		"name":product_name.strip_edges() if product_name.strip_edges() != "" else next_name(family_id),
		"levels":clean_levels, "price_mode":price_mode, "months_total":CAT.dev_months(family_id, clean_levels),
		"months_done":0, "monthly_cost":CAT.dev_monthly_cost(family_id, clean_levels, TimeManager.year)}
	_next_id += 1
	projects.append(project)
	software_changed.emit()
	return true
func _process_projects() -> void:
	for value in projects.duplicate():
		var project: Dictionary = value
		var kind := str(project.get("kind", "LEGACY"))
		var status := str(project.get("status", "DEVELOPMENT"))
		if status in ["DECISION", "REVIEW"]:
			continue

		if status == "BETA":
			var beta_cost := int(round(float(project.get("monthly_cost", 0)) * 0.60))
			Economy.add_expense(beta_cost, "Bêta software — %s" % str(project.get("name", "Produit")))
			project["beta_months_done"] = int(project.get("beta_months_done", 0)) + 1
			if int(project.get("beta_months_done", 0)) >= 1:
				var bugs := int(project.get("bugs", 0))
				project["bugs"] = maxi(0, bugs - maxi(5, int(ceil(float(bugs) * 0.45))))
				var beta_metrics: Dictionary = project.get("metrics", {})
				beta_metrics["stability"] = clampf(float(beta_metrics.get("stability", 50.0)) + 5.0, 0.0, 100.0)
				project["levels"] = _utility_levels_from_metrics(beta_metrics)
				project["status"] = "REVIEW"
				CompanyManager.add_alert("Bêta terminée : %s est prêt pour une nouvelle décision de sortie." % str(project.get("name", "le logiciel")))
			continue

		if kind == "UTILITY_SLICE" and status == "DEVELOPMENT" and _ensure_software_directive(project):
			continue

		Economy.add_expense(int(project.get("monthly_cost", 0)), "Développement software — %s" % CAT.family_label(str(project.family)))
		project["months_done"] = int(project.get("months_done", 0)) + 1
		if kind == "UTILITY_SLICE":
			_apply_software_cockpit_month(project)

		if kind in ["PATCH", "UPDATE"] and int(project.get("months_done", 0)) >= int(project.get("months_total", 1)):
			projects.erase(project)
			_complete_maintenance(project)
			continue

		if kind == "UTILITY_SLICE" and not bool(project.get("incident_done", false)) and int(project.get("months_total", 1)) >= 3:
			var midpoint := maxi(1, int(ceil(float(project.get("months_total", 1)) / 2.0)))
			if int(project.get("months_done", 0)) >= midpoint:
				var risky_feature := PLAY.utility_riskiest_feature(project.get("features", []))
				var feature_label := str(PLAY.utility_feature(risky_feature).get("label", "une fonctionnalité"))
				project["pending_decision"] = {
					"feature_id": risky_feature,
					"title": "%s pose problème" % feature_label,
					"text": "Les tests révèlent trop de défauts. Réécrire prend du temps, retirer la fonction réduit l'ambition, corriger vite augmente le risque de bugs."
				}
				project["incident_done"] = true
				project["status"] = "DECISION"
				CompanyManager.add_alert("Décision Software requise sur %s." % str(project.get("name", "le projet")))
				continue

		if int(project.get("months_done", 0)) < int(project.get("months_total", 1)):
			continue

		if kind == "UTILITY_SLICE":
			if bool(project.get("polish_pending", false)):
				project["bugs"] = maxi(0, int(project.get("bugs", 0)) - 5)
				var polish_metrics: Dictionary = project.get("metrics", {})
				polish_metrics["stability"] = clampf(float(polish_metrics.get("stability", 50.0)) + 4.0, 0.0, 100.0)
				project["levels"] = _utility_levels_from_metrics(polish_metrics)
				project["polish_pending"] = false
			project["status"] = "REVIEW"
			CompanyManager.add_alert("%s est terminé : choisissez bêta, sortie ou report." % str(project.get("name", "Le logiciel")))
			continue

		projects.erase(project)
		_launch(project)

func _launch(project: Dictionary) -> void:
	var family_id := str(project.family)
	var now := CAT.year_f(TimeManager.year, TimeManager.month)
	var product_mastery := mastery(family_id)
	var scores := CAT.axis_scores(family_id, project.levels, product_mastery, now, now)
	var quality := 0.0
	var explicit_metrics: Dictionary = project.get("metrics", {})
	if not explicit_metrics.is_empty():
		for score in explicit_metrics.values():
			quality += float(score)
		quality /= maxf(float(explicit_metrics.size()), 1.0)
	else:
		for score in scores.values():
			quality += float(score)
		quality /= maxf(float(scores.size()), 1.0)
	var product := {"id":str(project.id), "family":family_id, "name":str(project.name),
		"levels":project.levels.duplicate(), "price_mode":str(project.price_mode), "price":CAT.license_price(family_id, str(project.price_mode)),
		"mastery":product_mastery, "launch_f":now, "quality_launch":quality, "status":"ACTIVE",
		"licenses_last":0, "licenses_total":0, "installed_users":0, "revenue_last":0, "support_last":0, "margin_last":0}
	if str(project.get("kind", "")) == "UTILITY_SLICE":
		product["kind"] = "UTILITY_SLICE"
		product["target"] = str(project.get("target", "HOME"))
		product["features"] = (project.get("features", []) as Array).duplicate()
		product["metrics"] = explicit_metrics.duplicate(true)
		product["bugs_known"] = int(project.get("bugs", 0))
		product["version_major"] = 1
		product["version_minor"] = 0
		product["version_patch"] = 0
		var gains := PLAY.utility_skill_gains(product["features"])
		for skill_value in gains.keys():
			var skill_id := str(skill_value)
			skills[skill_id] = skill_xp(skill_id) + int(gains[skill_id])
	products.append(product)
	var state := family_state(family_id)
	state["launches"] = int(state.get("launches", 0)) + 1
	if product_mastery < LAUNCH_MASTERY_CAP: state["mastery"] = product_mastery + 1
	reveals.append(str(product.id))
	software_launched.emit(product)
func _process_sales() -> void:
	var now := CAT.year_f(TimeManager.year, TimeManager.month)
	for family_value in CAT.FAMILY_ORDER:
		var family_id := str(family_value)
		var active := active_products(family_id)
		if active.is_empty(): continue
		var market := CAT.market_users(family_id, now) * BalanceManager.market_demand_factor()
		var weights: Array[float] = []
		var total_weight := 0.0
		for value in active:
			var product: Dictionary = value
			var scores := CAT.axis_scores(family_id, product.levels, int(product.mastery), float(product.launch_f), now)
			var quality := 0.0
			for score in scores.values(): quality += float(score)
			quality /= maxf(float(scores.size()), 1.0)
			var price_penalty := CAT.price_factor(str(product.price_mode)) - 1.0
			var weight := maxf(0.2, 1.0 + (quality - 50.0) / 25.0 - price_penalty)
			if str(product.get("kind", "")) == "UTILITY_SLICE":
				var bug_penalty := clampf(1.0 - float(product.get("bugs_known", 0)) / 80.0, 0.55, 1.0)
				weight *= bug_penalty
			weights.append(weight); total_weight += weight
		var player_share := clampf(0.08 + CompanyManager.get_brand_score() / 500.0, 0.08, 0.30)
		for i in range(active.size()):
			var product: Dictionary = active[i]
			var licenses := int(round(market * player_share * float(weights[i]) / maxf(total_weight, 0.001)))
			var revenue := int(round(float(licenses) * float(product.price)))
			product["installed_users"] = int(product.installed_users) + licenses
			var support := CAT.support_monthly_cost(family_id, int(product.installed_users))
			product["licenses_last"] = licenses; product["licenses_total"] = int(product.licenses_total) + licenses
			product["revenue_last"] = revenue; product["support_last"] = support; product["margin_last"] = revenue - support
			Economy.add_income(revenue, "Licences software — %s" % CAT.family_label(family_id))
			Economy.add_expense(support, "Support software — %s" % CAT.family_label(family_id))
func _process_activities() -> void:
	for value in activities.duplicate():
		var current: Dictionary = value
		var activity_id := str(current.get("id", ""))
		var data := ACTIVITY.data(activity_id)
		if data.is_empty():
			activities.erase(current)
			continue
		var approach_id := str(current.get("approach", "BALANCED"))
		var terms := activity_terms(activity_id, approach_id)
		var cost := int(terms.get("monthly_cost", 0))
		if cost > 0:
			Economy.add_expense(cost, "Activité software — %s" % ACTIVITY.label(activity_id))
		current["months_done"] = int(current.get("months_done", 0)) + 1
		if int(current.months_done) < int(terms.get("months", 1)):
			continue
		activities.erase(current)
		var payout := int(terms.get("payout", 0))
		if payout > 0:
			Economy.add_income(payout, "Contrat software — %s" % ACTIVITY.label(activity_id))
		var family_id := str(current.get("family", "UTILITY"))
		var gained_xp := int(terms.get("xp", data.get("xp", 0)))
		_gain_activity_xp(family_id, gained_xp)
		_gain_skills(data, gained_xp)
		var state := family_state(family_id)
		state["activities_done"] = int(state.get("activities_done", 0)) + 1
		completed_activities += 1

		var rep_changes := {}
		var rep_factor := float(terms.get("reputation_factor", 1.0))
		for key_value in (data.get("reputation", {}) as Dictionary).keys():
			var key := str(key_value)
			rep_changes[key] = float((data.get("reputation", {}) as Dictionary)[key]) * rep_factor
		if int(terms.get("bug_pressure", 0)) >= 10:
			rep_changes["reliability"] = float(rep_changes.get("reliability", 0.0)) - 0.08
		CompanyManager.change_reputation(rep_changes)
		CompanyManager.add_alert("Contrat Software terminé : %s (%s)." % [
			ACTIVITY.label(activity_id), PLAY.approach_label(approach_id)
		])

func process_month() -> void:
	if not CompanyManager.created: return
	_check_unlocks()
	_process_activities()
	_process_projects()
	_process_sales()
	software_changed.emit()

func active_departments() -> Array:
	return ["Développement"] if not projects.is_empty() or not activities.is_empty() else []

func get_state() -> Dictionary:
	return {
		"families":families,
		"projects":projects,
		"products":products,
		"reveals":reveals,
		"activities":activities,
		"completed_activities":completed_activities,
		"skills":skills,
		"next_id":_next_id
	}

func load_state(state: Dictionary) -> void:
	reset()
	var saved_families: Dictionary = state.get("families", {})
	for family_id in saved_families.keys():
		var merged := _new_family_state(str(family_id))
		merged.merge((saved_families[family_id] as Dictionary).duplicate(true), true)
		families[str(family_id)] = merged
	projects = state.get("projects", []).duplicate(true)
	products = state.get("products", []).duplicate(true)
	reveals = state.get("reveals", []).duplicate(true)
	activities = state.get("activities", []).duplicate(true)
	completed_activities = int(state.get("completed_activities", 0))
	var saved_skills = state.get("skills", {})
	if typeof(saved_skills) == TYPE_DICTIONARY:
		for skill_id in PLAY.SKILL_ORDER:
			skills[str(skill_id)] = int((saved_skills as Dictionary).get(str(skill_id), skills.get(str(skill_id), 0)))
	_next_id = int(state.get("next_id", projects.size() + products.size() + 1))
	software_changed.emit()
