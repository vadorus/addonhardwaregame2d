extends Node
## Branche Software — projets, versions, licences, base installée et maintenance.
## Aucun coût de fabrication physique : le coût récurrent vient du support logiciel.

signal software_changed
signal work_event(event)
signal software_launched(product)

const CAT := preload("res://scripts/SoftwareCatalog.gd")
const ACTIVITY := preload("res://scripts/SoftwareActivityCatalog.gd")
const PLAY := preload("res://scripts/SoftwarePlayCatalog.gd")
const STUDIO := preload("res://scripts/SoftwareStudio.gd")
const PALMARES := preload("res://scripts/CpuPalmares.gd")
## Logiciel 2.0 : un logiciel touche une part du marché de son type selon son public et sa plateforme.
## Ce facteur ramène la part d'un public (0,2 à 0,6) au niveau des anciens produits « tout public ».
const STUDIO_REACH_SCALE := 2.6
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
## Le carnet de Nora (Logiciel 2.0) : combinaisons essayées, domaines appris, meilleur score par type.
var notebook: Dictionary = {}
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
	notebook = empty_notebook()
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
	var terms := PLAY.contract_terms(ACTIVITY.data(activity_id), approach_id)
	var current: Dictionary = active_activity()
	var task := {"id":"ACT:" + activity_id, "kind":"SOFTWARE", "need":1.0}
	var allocation := PersonnelManager.allocation_for(task)
	var rate := float(allocation.get("factor", 0.0))
	var done := float(current.get("work_done", current.get("months_done", 0))) if str(current.get("id", "")) == activity_id else 0.0
	terms["assigned"] = float(allocation.get("assigned", 0.0))
	terms["progress"] = done / maxf(float(terms.get("months", 1)), 1.0) * 100.0
	terms["calendar_months"] = int(ceil(maxf(0.0, float(terms.get("months", 1)) - done) / rate)) if rate > 0.0001 else -1
	terms["monthly_cash_cost"] = Economy.quoted_expense(int(terms.get("monthly_cost", 0)), "Activité software")
	terms["net_estimate"] = int(terms.get("payout", 0)) - int(terms.monthly_cash_cost) * maxi(int(terms.calendar_months), 0) - (int(current.get("spent", 0)) if str(current.get("id", "")) == activity_id else 0)
	return terms

func skill_xp(skill_id: String) -> int:
	return int(skills.get(skill_id, 0))

func can_start_activity(activity_id: String, approach_id: String = "BALANCED") -> Dictionary:
	if PersonnelManager.count_department("Développement") <= 0:
		return {"ok":false, "reason":"Affectez au moins une personne au Développement avant de démarrer."}
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
	return _funding_check(first_month, 1, "Activité software")

func _funding_check(monthly_base: int, months: int, category: String) -> Dictionary:
	var quote := Economy.project_funding_quote(monthly_base, months, category)
	quote["reason"] = "" if bool(quote.ok) else "Trésorerie insuffisante : %d € disponibles, %d € requis (%d mois à %d €), il manque %d €." % [int(quote.treasury), int(quote.required_cash), months, int(quote.monthly_cash), int(quote.shortfall)]
	return quote

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
	var forecast := work_preview({"id":"SW-PREVIEW", "kind":"UTILITY_SLICE", "months_total":maxi(3, int(plan.get("months", 3)))})
	plan["calendar_months"] = int(forecast.get("remaining", 0))
	plan["monthly_cash_cost"] = Economy.quoted_expense(int(plan.get("monthly_cost", 0)), "Développement software")
	plan["total_cost"] = int(plan.monthly_cash_cost) * maxi(int(plan.calendar_months), 0)
	plan["assigned"] = float(forecast.get("assigned", 0.0))
	return plan

func work_preview(project: Dictionary) -> Dictionary:
	var task := PersonnelManager.software_task(project)
	var allocation := PersonnelManager.allocation_for(task)
	var rate := float(allocation.get("factor", 0.0))
	var done := float(project.get("work_done", project.get("months_done", 0)))
	var total := float(project.get("months_total", 1))
	if str(project.get("status", "")) == "BETA":
		done = float(project.get("beta_work_done", 0.0))
		total = 1.0
	return {"assigned":float(allocation.get("assigned", 0.0)), "rate":rate,
		"remaining":int(ceil(maxf(0.0, total - done) / rate)) if rate > 0.0001 else -1,
		"progress":clampf(done / maxf(total, 1.0) * 100.0, 0.0, 100.0)}

func _advance_work(project: Dictionary, rate: float) -> float:
	var before := float(project.get("work_done", project.get("months_done", 0)))
	var total := float(project.get("months_total", 1))
	var limit := total
	if bool(project.get("cockpit_interactive", false)):
		var phase := software_cockpit_phase(project)
		if phase == "PLANNING":
			limit = float(maxi(1, int(floor(total * 0.25))))
		elif phase == "BUILD":
			limit = float(mini(int(total) - 1, int(ceil(total * 0.75))))
	var after := minf(limit, before + rate)
	project["work_done"] = after
	project["months_done"] = int(floor(after + 0.0001))
	project["elapsed_months"] = int(project.get("elapsed_months", 0)) + 1
	return maxf(0.0, after - before)

func can_start_utility(feature_ids: Array, target_id: String = "HOME") -> Dictionary:
	if PersonnelManager.count_department("Développement") <= 0:
		return {"ok":false, "reason":"Affectez au moins une personne au Développement avant de démarrer."}
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
	return _funding_check(int(plan.get("monthly_cost", 0)), 2, "Développement software")

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
		"months_total":maxi(3, int(plan.get("months", 1))) if player_controlled else int(plan.get("months", 1)),
		"months_done":0,
		"work_done":0.0,
		"elapsed_months":0,
		"spent":0,
		"spend_tracking_complete":true,
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
		"cockpit_directive_history":[],
		"cockpit_last_choice":"",
		"cockpit_last_outcome":""
	}
	_next_id += 1
	projects.append(project)
	software_changed.emit()
	return true

# --- Logiciel 2.0 : le studio --------------------------------------------------------------

static func empty_notebook() -> Dictionary:
	return {"combos":{}, "areas":{}, "best":{}, "history":[]}

func _notebook() -> Dictionary:
	for key in ["combos", "areas", "best"]:
		if typeof(notebook.get(key, null)) != TYPE_DICTIONARY:
			notebook[key] = {}
	if typeof(notebook.get("history", null)) != TYPE_ARRAY:
		notebook["history"] = []
	return notebook

## La combinaison type × public déjà essayée : -1 si jamais, sinon 0 à 3.
func known_fit(type_id: String, audience_id: String) -> int:
	return int((_notebook().combos as Dictionary).get("%s:%s" % [type_id, audience_id], -1))

## Les domaines d'effort déjà compris pour ce type : {area: importance}.
## Lecture seule : regarder le carnet ne doit jamais modifier la partie.
func known_areas(type_id: String) -> Dictionary:
	var value = (_notebook().areas as Dictionary).get(type_id, null)
	return value if typeof(value) == TYPE_DICTIONARY else {}

func _writable_areas(type_id: String) -> Dictionary:
	var areas: Dictionary = _notebook().areas
	if typeof(areas.get(type_id, null)) != TYPE_DICTIONARY:
		areas[type_id] = {}
	return areas[type_id]

func best_score(type_id: String) -> float:
	return float((_notebook().best as Dictionary).get(type_id, 0.0))

## Avez-vous au moins un CPU en vente (plateforme « Vos processeurs ») ?
func has_own_cpu() -> bool:
	for value in ProductManager.products:
		var product: Dictionary = value
		if str(product.get("sector", "CPU")) == "CPU" and str(product.get("status", "")) == "LAUNCHED":
			return true
	return false

## Part des machines équipées de vos CPU, rapportée au CPU le plus répandu (0,2 à 1).
func own_cpu_reach() -> float:
	if not has_own_cpu():
		return 0.0
	var ranked := PALMARES.scores("SALES")
	if ranked.is_empty():
		return 0.2
	var leader := maxf(float((ranked[0] as Dictionary).get("score", 0.0)), 1.0)
	for value in ranked:
		var row: Dictionary = value
		if bool(row.get("player", false)):
			return clampf(float(row.get("score", 0.0)) / leader, 0.2, 1.0)
	return 0.2

func studio_context(type_id: String) -> Dictionary:
	return {"year":TimeManager.year, "month":TimeManager.month, "skills":skills, "mastery":mastery(type_id),
		"own_reach":own_cpu_reach()}

func open_types() -> Array:
	return CAT.FAMILY_ORDER.filter(func(id): return is_open(str(id)))

## Un plan complet et lisible : coûts, durée avec l'équipe actuelle, notes prévues.
func studio_preview(spec: Dictionary) -> Dictionary:
	var type_id := str(spec.get("type", "UTILITY"))
	var plan := STUDIO.plan(spec, studio_context(type_id))
	var forecast := work_preview({"id":"SW-PREVIEW", "kind":"STUDIO", "months_total":int(plan.months)})
	plan["calendar_months"] = int(forecast.get("remaining", 0))
	plan["monthly_cash_cost"] = Economy.quoted_expense(int(plan.monthly_cost), "Développement software")
	plan["total_cash_cost"] = int(plan.monthly_cash_cost) * maxi(int(plan.calendar_months), 0)
	plan["assigned"] = float(forecast.get("assigned", 0.0))
	plan["check"] = can_start_studio(spec)
	return plan

func can_start_studio(spec: Dictionary) -> Dictionary:
	var type_id := str(spec.get("type", ""))
	if PersonnelManager.count_department("Développement") <= 0:
		return {"ok":false, "reason":"Affectez au moins une personne au Développement avant de démarrer."}
	if not CAT.FAMILIES.has(type_id) or not is_open(type_id):
		return {"ok":false, "reason":"Ce type de logiciel n'existe pas encore à cette époque."}
	if not project_for(type_id).is_empty():
		return {"ok":false, "reason":"Un logiciel de ce type est déjà en développement."}
	var audience_id := str(spec.get("audience", ""))
	if not STUDIO.open_audiences(TimeManager.year).has(audience_id):
		return {"ok":false, "reason":"Choisissez un public."}
	var platform_id := str(spec.get("platform", ""))
	if not STUDIO.open_platforms(TimeManager.year, has_own_cpu()).has(platform_id):
		return {"ok":false, "reason":"Plateforme indisponible : sortez d'abord un CPU pour développer sur vos processeurs." if platform_id == "OWN" else "Choisissez une plateforme."}
	var chosen: Array = (spec.get("features", []) as Array).filter(func(id): return STUDIO.open_features(TimeManager.year).has(str(id)))
	var sequel_of := str(spec.get("sequel_of", ""))
	if sequel_of != "":
		var check := can_start_sequel(sequel_of)
		if not bool(check.get("ok", false)):
			return check
		if str(product_by_id(sequel_of).get("family", "")) != type_id:
			return {"ok":false, "reason":"Une suite garde le type de logiciel de l'original."}
	if chosen.is_empty():
		return {"ok":false, "reason":"Une nouvelle version sans nouveauté ? Choisissez au moins une fonction." if sequel_of != "" else "Choisissez au moins une fonction."}
	if chosen.size() > STUDIO.feature_slots(mastery(type_id)):
		return {"ok":false, "reason":"Trop de fonctions pour l'expérience de l'équipe (%d au plus)." % STUDIO.feature_slots(mastery(type_id))}
	var plan := STUDIO.plan(spec, studio_context(type_id))
	return _funding_check(int(plan.monthly_cost), 2, "Développement software")

func start_studio_project(spec: Dictionary, product_name: String = "") -> bool:
	if not bool(can_start_studio(spec).get("ok", false)):
		return false
	var type_id := str(spec.get("type", "UTILITY"))
	var price_mode := str(spec.get("price_mode", "MARKET"))
	if not CAT.PRICE_MODES.has(price_mode):
		price_mode = "MARKET"
	var clean_spec := {"type":type_id, "audience":str(spec.audience), "platform":str(spec.platform),
		"features":(spec.get("features", []) as Array).duplicate(), "tokens":STUDIO.normalize_tokens(spec.get("tokens", {})),
		"price_mode":price_mode}
	var sequel_of := str(spec.get("sequel_of", ""))
	if sequel_of != "":
		var base_spec := sequel_spec(sequel_of)
		clean_spec["sequel_of"] = sequel_of
		clean_spec["inherited"] = (base_spec.get("inherited", []) as Array).duplicate()
		clean_spec["version"] = int(base_spec.get("version", 2))
	var plan := STUDIO.plan(clean_spec, studio_context(type_id))
	clean_spec["features"] = (plan.features as Array).duplicate()
	var project := {
		"id":"SW-%03d" % _next_id,
		"kind":"STUDIO",
		"family":type_id,
		"name":product_name.strip_edges() if product_name.strip_edges() != "" else (sequel_name(sequel_of) if sequel_of != "" else next_name(type_id)),
		"base_name":str(product_by_id(sequel_of).get("base_name", product_by_id(sequel_of).get("name", ""))) if sequel_of != "" else (product_name.strip_edges() if product_name.strip_edges() != "" else next_name(type_id)),
		"spec":clean_spec,
		"target":str(spec.audience),
		"features":(plan.features as Array).duplicate(),
		"metrics":(plan.metrics as Dictionary).duplicate(true),
		"levels":_utility_levels_from_metrics(plan.metrics),
		"bugs":int(plan.bugs),
		"price_mode":price_mode,
		"months_total":int(plan.months),
		"months_done":0,
		"work_done":0.0,
		"elapsed_months":0,
		"spent":0,
		"spend_tracking_complete":true,
		"monthly_cost":int(plan.monthly_cost),
		"status":"DEVELOPMENT",
		"phase_reported":0,
		"phase_notes":[]
	}
	_next_id += 1
	projects.append(project)
	software_changed.emit()
	return true

## 0 fondations, 1 fonctions, 2 finition — selon le travail déjà fait.
func studio_phase_index(project: Dictionary) -> int:
	var total := maxf(float(project.get("months_total", 1)), 1.0)
	var done := float(project.get("work_done", project.get("months_done", 0)))
	return clampi(int(floor(done / total * 3.0 + 0.0001)), 0, 2)

## On peut encore changer la répartition d'une phase qui n'a pas commencé.
func can_edit_studio_phase(project: Dictionary, phase_id: String) -> bool:
	return str(project.get("kind", "")) == "STUDIO" and str(project.get("status", "")) == "DEVELOPMENT" \
		and STUDIO.PHASE_ORDER.find(phase_id) > studio_phase_index(project)

func set_studio_tokens(project_id: String, phase_id: String, row: Dictionary) -> bool:
	var project := project_by_id(project_id)
	if project.is_empty() or not can_edit_studio_phase(project, phase_id):
		return false
	var spec: Dictionary = (project.get("spec", {}) as Dictionary).duplicate(true)
	var tokens: Dictionary = STUDIO.normalize_tokens(spec.get("tokens", {}))
	var candidate := tokens.duplicate(true)
	candidate[phase_id] = row.duplicate()
	if STUDIO.normalize_tokens(candidate) != candidate:
		return false
	spec["tokens"] = candidate
	var before := STUDIO.plan(project.spec, studio_context(str(project.family)))
	var after := STUDIO.plan(spec, studio_context(str(project.family)))
	project["spec"] = spec
	var metrics: Dictionary = project.get("metrics", {})
	for axis in STUDIO.AXES:
		metrics[axis] = clampf(float(metrics.get(axis, 50.0)) + float(after.metrics[axis]) - float(before.metrics[axis]), 10.0, 98.0)
	project["metrics"] = metrics
	project["levels"] = _utility_levels_from_metrics(metrics)
	project["bugs"] = maxi(0, int(project.get("bugs", 0)) + int(after.bugs) - int(before.bugs))
	software_changed.emit()
	return true

## Fin d'une phase : Camille fait le point. Le conseil n'arrive que si l'équipe connaît déjà ce domaine.
func _studio_phase_report(project: Dictionary, finished_index: int) -> void:
	var phase_id := str(STUDIO.PHASE_ORDER[finished_index])
	var type_id := str(project.get("family", "UTILITY"))
	var row: Dictionary = ((project.get("spec", {}) as Dictionary).get("tokens", {}) as Dictionary).get(phase_id, {})
	var align := STUDIO.phase_alignment(type_id, phase_id, row)
	var known := known_areas(type_id)
	var text := "%s : phase %s terminée." % [str(project.get("name", "Logiciel")), STUDIO.phase_label(phase_id).to_lower()]
	var known_here := false
	for area in (STUDIO.PHASES[phase_id] as Dictionary).areas:
		if known.has(str(area)):
			known_here = true
	if known_here:
		text += " Camille : %s" % ("« pile ce qu'il fallait. »" if align >= 0.85 else "« ça ira. »" if align >= 0.65 else "« on a mis l'effort au mauvais endroit. »")
	else:
		text += " Camille : « on saura à la sortie si c'était le bon dosage. »"
	(project["phase_notes"] as Array).append({"phase":phase_id, "alignment":align, "text":text})
	work_event.emit({"kind":"SOFTWARE", "id":str(project.id), "name":str(project.get("name", "Logiciel")), "text":"%s terminées" % STUDIO.phase_label(phase_id)})
	CompanyManager.add_alert(text)

## Sortie : la presse note, Nora remplit son carnet.
func _studio_launch(project: Dictionary, product: Dictionary) -> void:
	var spec: Dictionary = project.get("spec", {})
	var type_id := str(project.get("family", "UTILITY"))
	var subject := {"type":type_id, "audience":str(spec.get("audience", "HOBBY")), "features":project.get("features", []),
		"inherited":spec.get("inherited", []), "tokens":spec.get("tokens", {}), "metrics":project.get("metrics", {}),
		"bugs":int(project.get("bugs", 0)), "price_mode":str(spec.get("price_mode", "MARKET"))}
	var best_before := best_score(type_id)
	var review := STUDIO.review(subject, TimeManager.year, best_before)
	var own_reach := own_cpu_reach()
	product["kind"] = "STUDIO"
	product["audience"] = str(spec.get("audience", "HOBBY"))
	product["target"] = str(spec.get("audience", "HOBBY"))
	product["platform"] = str(spec.get("platform", "LEADER"))
	product["tokens"] = (spec.get("tokens", {}) as Dictionary).duplicate(true)
	product["features"] = (project.get("features", []) as Array).duplicate()
	product["inherited"] = (spec.get("inherited", []) as Array).duplicate()
	product["base_name"] = str(project.get("base_name", product.name))
	product["sequel_of"] = str(spec.get("sequel_of", ""))
	product["metrics"] = (project.get("metrics", {}) as Dictionary).duplicate(true)
	product["levels"] = _utility_levels_from_metrics(project.get("metrics", {}))
	product["bugs_known"] = int(project.get("bugs", 0))
	product["bugs_at_launch"] = int(project.get("bugs", 0))
	product["version_major"] = maxi(1, int(spec.get("version", 1)))
	product["version_minor"] = 0
	product["version_patch"] = 0
	product["note"] = float(review.note)
	product["review"] = review
	product["review_score"] = float(review.score)
	product["expectation"] = float(review.expectation)
	product["missed"] = STUDIO.missed_line(review)
	product["own_reach"] = own_reach
	product["price"] = studio_price(type_id, str(product.audience), str(product.get("price_mode", "MARKET")))
	product["quality_launch"] = float(review.score)
	# Le carnet de Nora : la combinaison, et le domaine le plus mal servi (si on ne le connaissait pas).
	var book := _notebook()
	var combo_key := "%s:%s" % [type_id, str(product.audience)]
	var combo_new := not (book.combos as Dictionary).has(combo_key)
	(book.combos as Dictionary)[combo_key] = int(review.combo)
	var learned := {}
	var known := _writable_areas(type_id)
	var worst: Dictionary = review.get("worst_area", {})
	if not worst.is_empty() and not known.has(str(worst.area)):
		learned = {"area":str(worst.area), "importance":float(worst.importance)}
	else:
		for phase in STUDIO.PHASE_ORDER:
			for area in (STUDIO.PHASES[phase] as Dictionary).areas:
				if learned.is_empty() and not known.has(str(area)):
					learned = {"area":str(area), "importance":STUDIO.importance(type_id, str(area))}
	if not learned.is_empty():
		known[str(learned.area)] = float(learned.importance)
	(book.best as Dictionary)[type_id] = maxf(best_before, float(review.score))
	(book.history as Array).append({"name":str(product.name), "type":type_id, "audience":str(product.audience),
		"platform":str(product.platform), "note":float(review.note), "year":TimeManager.year, "month":TimeManager.month})
	while (book.history as Array).size() > 40:
		(book.history as Array).pop_front()
	product["lessons"] = {"combo_new":combo_new, "combo":int(review.combo), "area":learned}
	var gains := PLAY.utility_skill_gains([])
	for id in product.features:
		for skill_id in (STUDIO.feature(str(id)).get("axes", {}) as Dictionary).keys():
			match str(skill_id):
				"features": gains["development"] = int(gains.get("development", 0)) + 4
				"usability": gains["interface"] = int(gains.get("interface", 0)) + 4
				"stability": gains["reliability"] = int(gains.get("reliability", 0)) + 3
				"performance": gains["systems"] = int(gains.get("systems", 0)) + 3
	for skill_id in gains.keys():
		skills[str(skill_id)] = skill_xp(str(skill_id)) + int(gains[skill_id])
	var note := float(review.note)
	CompanyManager.change_reputation({"innovation":(note - 5.5) * 0.05, "prestige":(note - 5.5) * 0.04})
	_studio_upgrade_wave(product)
	_studio_press(product, subject, review)

## Le jour J : trois journaux de l'époque testent le logiciel ; l'écran de révélation s'ouvre comme pour un CPU.
func _studio_press(product: Dictionary, subject: Dictionary, review: Dictionary) -> void:
	var reviews := STUDIO.press_reviews(subject, review, MediaManager.available_outlets(TimeManager.year), str(product.name))
	var lesson := studio_lesson(product)
	for value in reviews:
		var item: Dictionary = value
		item["channel_label"] = MediaManager.channel_label(str(item.channel))
		item["product_id"] = str(product.id)
		item["product_name"] = str(product.name)
		item["product_kind"] = "SOFTWARE"
		item["software_lesson"] = lesson
		MediaManager.add_news(str(item.channel_label), str(item.headline), str(item.body), {
			"source_id":str(item.source_id), "source_name":str(item.source_name), "channel":str(item.channel),
			"product_id":str(product.id), "product_name":str(product.name), "product_kind":"SOFTWARE",
			"review_score":float(item.score), "sentiment":clampf((float(item.score) - 56.0) / 34.0, -1.0, 1.0)})
	if not reviews.is_empty():
		if MediaManager.MOMENTS.is_good_press(reviews):
			MediaManager.front_pages += 1
		MediaManager.reviews_published.emit(str(product.name), reviews)

## Ce que Nora note dans son carnet après cette sortie (affiché sous le verdict de la presse).
func studio_lesson(product: Dictionary) -> String:
	var lessons: Dictionary = product.get("lessons", {})
	var parts: Array[String] = []
	var combo := int(lessons.get("combo", 1))
	var combo_text := "%s pour %s : %s" % [CAT.family_label(str(product.family)), STUDIO.audience_label(str(product.get("audience", ""))).to_lower(), STUDIO.FIT_LABELS[clampi(combo, 0, 3)].to_lower()]
	parts.append(("nouvelle découverte, " if bool(lessons.get("combo_new", false)) else "") + combo_text)
	var area: Dictionary = lessons.get("area", {})
	if not area.is_empty():
		parts.append("%s est %s pour ce type" % [STUDIO.area_label(str(area.area)).to_lower(), STUDIO.importance_label(float(area.importance))])
	if int(product.get("upgrade_units", 0)) > 0:
		parts.append("%s mises à niveau vendues aux utilisateurs de la version précédente" % _thousands(int(product.upgrade_units)))
	return "Carnet de Nora : " + " ; ".join(parts) + "."

static func _thousands(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	while text.length() > 3:
		out = " " + text.substr(text.length() - 3) + out
		text = text.substr(0, text.length() - 3)
	return ("-" if value < 0 else "") + text + out

## Versions 2 et 3 : à la sortie, l'ancienne version quitte le catalogue et une partie de ses utilisateurs
## paie la mise à niveau (une vente immédiate, à moitié prix).
func _studio_upgrade_wave(product: Dictionary) -> void:
	var previous := product_by_id(str(product.get("sequel_of", "")))
	if previous.is_empty():
		return
	var note_factor := clampf(float(product.get("note", 5.0)) / 7.0, 0.3, 1.3)
	var units := int(floor(float(int(previous.get("licenses_total", 0))) * STUDIO.UPGRADE_SHARE * note_factor))
	var revenue := int(round(float(units) * float(product.get("price", 0.0)) * STUDIO.UPGRADE_PRICE))
	product["upgrade_units"] = units
	product["upgrade_revenue"] = revenue
	product["licenses_total"] = int(product.get("licenses_total", 0)) + units
	product["installed_users"] = int(product.get("installed_users", 0)) + units
	if revenue > 0:
		Economy.add_income(revenue, "Mises à niveau software — %s" % CAT.family_label(str(product.family)))
		product["margin_total"] = int(product.get("margin_total", 0)) + revenue
	previous["status"] = "RETIRED"
	previous["replaced_by"] = str(product.id)
	previous["licenses_last"] = 0
	previous["revenue_last"] = 0
	previous["support_last"] = 0
	previous["margin_last"] = 0

# --- Synergie CPU (Logiciel 2.0, étape 3) ----------------------------------------------------

## Combien chaque type de logiciel « sur vos processeurs » donne envie d'acheter vos CPU.
## Un OS maison compte le plus ; serveurs et outils de développement attirent les pros ; les jeux un peu.
const ECOSYSTEM_WEIGHTS := {"OS":1.0, "SERVER":0.6, "DEVTOOLS":0.5, "GAME":0.4}
const ECOSYSTEM_DEFAULT_WEIGHT := 0.25
const ECOSYSTEM_PER_PRODUCT := 0.10
const ECOSYSTEM_CAP := 0.15

## Les logiciels écrits pour vos CPU et ce que chacun apporte à leurs ventes (note qui vieillit comprise).
func ecosystem_breakdown() -> Array:
	var rows: Array = []
	var now := CAT.year_f(TimeManager.year, TimeManager.month)
	for value in active_products():
		var product: Dictionary = value
		if str(product.get("kind", "")) != "STUDIO" or str(product.get("platform", "")) != "OWN":
			continue
		var note := studio_live_note(product, now)
		var quality := clampf((note - 5.0) / 4.0, 0.0, 1.0)
		var weight := float(ECOSYSTEM_WEIGHTS.get(str(product.family), ECOSYSTEM_DEFAULT_WEIGHT))
		rows.append({"id":str(product.id), "name":str(product.name), "family":str(product.family), "note":note,
			"bonus":ECOSYSTEM_PER_PRODUCT * weight * quality})
	return rows

## Multiplicateur de demande de vos CPU (1,00 à 1,15) : l'écosystème logiciel qui tourne sur vos puces.
func cpu_ecosystem_factor() -> float:
	var total := 0.0
	for row in ecosystem_breakdown():
		total += float((row as Dictionary).bonus)
	return 1.0 + minf(total, ECOSYSTEM_CAP)

## La suite d'un logiciel : même type, mêmes réglages de départ, les fonctions déjà écrites sont reprises.
func sequel_spec(product_id: String) -> Dictionary:
	var product := product_by_id(product_id)
	if product.is_empty() or str(product.get("kind", "")) != "STUDIO":
		return {}
	var inherited: Array = []
	for id in (product.get("features", []) as Array) + (product.get("inherited", []) as Array):
		if not inherited.has(str(id)) and not STUDIO.feature_standard(str(id), TimeManager.year):
			inherited.append(str(id))
	return {"type":str(product.family), "audience":str(product.get("audience", "HOBBY")), "platform":str(product.get("platform", "LEADER")),
		"features":[], "inherited":inherited, "tokens":(product.get("tokens", {}) as Dictionary).duplicate(true),
		"price_mode":str(product.get("price_mode", "MARKET")), "sequel_of":product_id, "version":int(product.get("version_major", 1)) + 1}

func sequel_name(product_id: String) -> String:
	var product := product_by_id(product_id)
	var base := str(product.get("base_name", product.get("name", "Logiciel")))
	return "%s %d" % [base, int(product.get("version_major", 1)) + 1]

func can_start_sequel(product_id: String) -> Dictionary:
	var product := product_by_id(product_id)
	if product.is_empty() or str(product.get("kind", "")) != "STUDIO":
		return {"ok":false, "reason":"Seuls les logiciels du studio peuvent avoir une suite."}
	if str(product.get("status", "")) != "ACTIVE":
		return {"ok":false, "reason":"Cette version n'est plus en vente."}
	if not project_for(str(product.family)).is_empty():
		return {"ok":false, "reason":"Un logiciel de ce type est déjà en développement."}
	if int(product.get("market_months", 0)) < 6:
		return {"ok":false, "reason":"Laissez la version actuelle vivre au moins six mois."}
	return {"ok":true, "reason":""}

static func _note_text(note: float) -> String:
	return ("%.1f" % note).replace(".", ",")

func studio_price(type_id: String, audience_id: String, price_mode: String) -> float:
	return maxf(1.0, snappedf(CAT.license_price(type_id, price_mode) * float(STUDIO.audience(audience_id).get("price", 1.0)), 1.0))

## La note qu'aurait ce logiciel aujourd'hui : il vieillit face aux nouveautés.
func studio_live_note(product: Dictionary, now: float) -> float:
	var aging := float(CAT.family(str(product.get("family", "UTILITY"))).get("aging_per_year", 0.4)) * maxf(0.0, now - float(product.get("launch_f", now))) * CAT.POINTS_PER_LEVEL * 0.6
	# Un correctif retire des bugs : le logiciel remonte un peu (la note de sortie en comptait 0,5 point chacun).
	var bug_delta := float(int(product.get("bugs_at_launch", product.get("bugs_known", 0))) - int(product.get("bugs_known", 0))) * 0.5
	var score := float(product.get("review_score", 50.0)) - aging + bug_delta
	return clampf(5.5 + (score - float(product.get("expectation", 58.0))) / STUDIO.REVIEW_SPREAD, 1.0, 10.0)

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
	if str(project.get("kind", "")) == "STUDIO":
		return ["PLANNING", "BUILD", "STABILIZE"][studio_phase_index(project)]
	var total := maxi(int(project.get("months_total", 1)), 3)
	var done := clampf(float(project.get("work_done", project.get("months_done", 0))), 0.0, float(total))
	var phase_index := 0
	if done >= maxi(1, int(floor(float(total) * 0.25))):
		phase_index = 1
	if done >= mini(total - 1, int(ceil(float(total) * 0.75))):
		phase_index = 2
	var phases := ["PLANNING", "BUILD", "STABILIZE"]
	# A rewrite or a delay cannot take an already chosen phase backwards.
	for value in project.get("cockpit_directive_history", []):
		phase_index = maxi(phase_index, phases.find(str((value as Dictionary).get("phase", ""))))
	return phases[phase_index]

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
	var phase := software_cockpit_phase(project)
	var cost_once := maxi(int(option.get("cost_once", 0)), 0)
	var delay_months := maxi(int(option.get("delay_months", 0)), 0)
	if cost_once > 0 and not Economy.can_afford(cost_once, "Décision Software — %s" % str(project.get("name", "Logiciel"))):
		return false
	var metrics: Dictionary = project.get("metrics", {})
	var outcome_parts: Array[String] = []
	var labels := {"features":"fonctions", "usability":"ergonomie", "stability":"stabilité", "performance":"performance"}
	for axis_value in SOFTWARE_COCKPIT_AXES:
		var axis := str(axis_value)
		var delta := float((option.get("metrics", {}) as Dictionary).get(axis, 0.0))
		metrics[axis] = clampf(float(metrics.get(axis, 50.0)) + delta, 10.0, 98.0)
		if absf(delta) >= 0.05:
			outcome_parts.append("%s %+.1f" % [str(labels.get(axis, axis)), delta])
	project["metrics"] = metrics
	project["levels"] = _utility_levels_from_metrics(metrics)
	var bugs_delta := int(option.get("bugs", 0))
	project["bugs"] = maxi(0, int(project.get("bugs", 0)) + bugs_delta)
	if bugs_delta != 0:
		outcome_parts.append("bugs %+d" % bugs_delta)
	if cost_once > 0:
		Economy.add_expense(cost_once, "Décision Software — %s" % str(project.get("name", "Logiciel")))
		project["spent"] = int(project.get("spent", 0)) + Economy.quoted_expense(cost_once, "Décision Software")
		outcome_parts.append("coût %d €" % Economy.quoted_expense(cost_once, "Décision Software"))
	if delay_months > 0:
		project["months_total"] = int(project.get("months_total", 1)) + delay_months
		outcome_parts.append("+%d mois" % delay_months)
	var label := str(option.get("label", option_id))
	var outcome := "%s — %s" % [label, " • ".join(outcome_parts)] if not outcome_parts.is_empty() else label
	project["cockpit_last_choice"] = label
	project["cockpit_last_outcome"] = outcome
	var history: Array = project.get("cockpit_directive_history", [])
	history.append({
		"phase":phase,
		"option_id":option_id,
		"label":label,
		"cost":cost_once,
		"delay_months":delay_months,
		"outcome":outcome
	})
	project["cockpit_directive_history"] = history
	project["cockpit_directive_pending"] = {}
	CompanyManager.add_alert("%s : %s." % [str(project.get("name", "Logiciel")), outcome])
	software_changed.emit()
	return true

func _apply_software_cockpit_month(project: Dictionary, effort: float = 1.0) -> void:
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
		influence[axis] = float(influence.get(axis, 0.0)) + float(priorities.get(axis, 25)) / 100.0 * leverage * effort
	project["cockpit_influence"] = influence
	project["cockpit_months"] = int(project.get("cockpit_months", 0)) + 1

	var metrics: Dictionary = project.get("metrics", {})
	var bias := PROJECT_COCKPIT.month_bias(priorities, SOFTWARE_COCKPIT_AXES, 1.2)
	for axis_value in SOFTWARE_COCKPIT_AXES:
		var axis := str(axis_value)
		var leverage := float(phase_weights.get(axis, 1.0))
		metrics[axis] = clampf(float(metrics.get(axis, 50.0)) + float(bias.get(axis, 0.0)) * leverage * effort, 10.0, 98.0)
	project["metrics"] = metrics
	project["levels"] = _utility_levels_from_metrics(metrics)

	var stability_priority := int(priorities.get("stability", 25))
	var feature_priority := int(priorities.get("features", 25))
	project["test_effort"] = float(project.get("test_effort", 0.0)) + effort
	if float(project.test_effort) < 1.0:
		return
	project["test_effort"] = float(project.test_effort) - 1.0
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
	var feature_label := str(PLAY.utility_feature(feature_id).get("label", feature_id))
	var bugs_before := int(project.get("bugs", 0))
	var decision_outcome := ""
	var choice_label := ""
	match choice:
		"REWRITE":
			choice_label = "Réécrire proprement"
			project["months_total"] = int(project.get("months_total", 1)) + 1
			project["bugs"] = maxi(0, int(project.get("bugs", 0)) - 5)
			var metrics: Dictionary = project.get("metrics", {})
			metrics["stability"] = clampf(float(metrics.get("stability", 50.0)) + 6.0, 0.0, 100.0)
			project["levels"] = _utility_levels_from_metrics(metrics)
			decision_outcome = "%s — stabilité +6 • bugs %+d • +1 mois" % [choice_label, int(project.get("bugs", 0)) - bugs_before]
		"CUT":
			choice_label = "Retirer la fonction"
			var features: Array = (project.get("features", []) as Array).duplicate()
			if features.size() <= 2 or not features.has(feature_id):
				return false
			var old_features := features.duplicate()
			features.erase(feature_id)
			var plan := PLAY.utility_plan(features, str(project.get("target", "HOME")), skills)
			_rebase_utility_metrics(project, old_features, features)
			var old_plan := PLAY.utility_plan(old_features, str(project.get("target", "HOME")), skills)
			project["features"] = features
			project["bugs"] = maxi(0, int(project.get("bugs", 0)) + int(plan.get("bugs", 0)) - int(old_plan.get("bugs", 0)))
			project["monthly_cost"] = int(plan.get("monthly_cost", project.get("monthly_cost", 0)))
			project["months_total"] = maxi(3, maxi(int(project.get("months_done", 0)) + 1, int(plan.get("months", 1))))
			decision_outcome = "%s — %s supprimé • bugs %+d • planning recalculé" % [choice_label, feature_label, int(project.get("bugs", 0)) - bugs_before]
		"QUICK_FIX":
			choice_label = "Corriger vite"
			project["bugs"] = int(project.get("bugs", 0)) + 6
			var metrics: Dictionary = project.get("metrics", {})
			metrics["stability"] = clampf(float(metrics.get("stability", 50.0)) - 4.0, 0.0, 100.0)
			project["levels"] = _utility_levels_from_metrics(metrics)
			decision_outcome = "%s — stabilité -4 • bugs +6 • aucun retard" % choice_label
		_:
			return false
	project["cockpit_last_choice"] = choice_label
	project["cockpit_last_outcome"] = decision_outcome
	project["pending_decision"] = {}
	project["status"] = "DEVELOPMENT"
	_ensure_software_directive(project)
	CompanyManager.add_alert("%s : %s." % [str(project.get("name", "Logiciel")), decision_outcome])
	software_changed.emit()
	return true

func _rebase_utility_metrics(subject: Dictionary, old_features: Array, new_features: Array) -> void:
	var target := str(subject.get("target", "HOME"))
	var old_plan := PLAY.utility_plan(old_features, target, skills)
	var new_plan := PLAY.utility_plan(new_features, target, skills)
	var metrics: Dictionary = subject.get("metrics", {}).duplicate(true)
	for axis in SOFTWARE_COCKPIT_AXES:
		var before := float((old_plan.get("metrics", {}) as Dictionary).get(axis, 50.0))
		var after := float((new_plan.get("metrics", {}) as Dictionary).get(axis, 50.0))
		metrics[axis] = clampf(float(metrics.get(axis, before)) + after - before, 10.0, 98.0)
	subject["metrics"] = metrics
	subject["levels"] = _utility_levels_from_metrics(metrics)

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
			project["beta_work_done"] = 0.0
			project["cockpit_last_choice"] = "Ouvrir une bêta"
			project["cockpit_last_outcome"] = "Bêta ouverte — +1 mois de tests • bugs réduits avant la prochaine revue"
			CompanyManager.add_alert("Bêta ouverte pour %s : encore un mois de tests." % str(project.get("name", "le logiciel")))
		"DELAY":
			project["status"] = "DEVELOPMENT"
			project["months_total"] = int(project.get("months_total", 1)) + 1
			project["polish_pending"] = true
			project["cockpit_last_choice"] = "Repousser la sortie"
			project["cockpit_last_outcome"] = "Sortie repoussée — +1 mois • stabilité +4 • jusqu'à 5 bugs corrigés"
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
	if str(product.get("kind", "")) not in ["UTILITY_SLICE", "STUDIO"]:
		return {"ok":false, "reason":"Les correctifs jouables sont encore réservés aux utilitaires."}
	if not project_for(str(product.get("family", "UTILITY"))).is_empty():
		return {"ok":false, "reason":"L'équipe Software travaille déjà sur cette famille."}
	if int(product.get("bugs_known", 0)) <= 0:
		return {"ok":false, "reason":"Aucun bug connu ne justifie un correctif."}
	var cost := 1800 + int(product.get("bugs_known", 0)) * 40
	return _funding_check(cost, 1, "Correctif software")

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
	return _funding_check(monthly_cost, 2, "Mise à jour software")

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
	product["maintenance_spent"] = int(product.get("maintenance_spent", 0)) + int(project.get("spent", 0))
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
			var old_features := features.duplicate()
			if not features.has(feature_id):
				features.append(feature_id)
			_rebase_utility_metrics(product, old_features, features)
			product["features"] = features
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
	var forecast := work_preview({"id":"SW-PREVIEW", "months_total":months})
	var cash_cost := Economy.quoted_expense(monthly, "Développement software")
	return {"months":months, "calendar_months":int(forecast.remaining), "monthly_cost":monthly, "monthly_cash_cost":cash_cost, "total_cost":cash_cost * maxi(int(forecast.remaining), 0), "price":CAT.license_price(family_id, price_mode), "quality":quality, "scores":scores}
func can_start(family_id: String, levels: Dictionary) -> Dictionary:
	if PersonnelManager.count_department("Développement") <= 0:
		return {"ok":false, "reason":"Affectez au moins une personne au Développement avant de démarrer."}
	if not is_open(family_id):
		return {"ok":false, "reason":"Ce domaine software n'est pas encore ouvert."}
	if not project_for(family_id).is_empty():
		return {"ok":false, "reason":"Une version est déjà en développement dans cette famille."}
	for setting_id in CAT.settings_of(family_id):
		var level := int(levels.get(setting_id, 3))
		if level < 1 or level > max_level(family_id):
			return {"ok":false, "reason":"Ambition trop élevée pour l'expérience de l'équipe."}
	var monthly := CAT.dev_monthly_cost(family_id, levels, TimeManager.year)
	return _funding_check(monthly, 2, "Développement software")

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
		var forecast := work_preview(project)
		var rate := float(forecast.get("rate", 0.0))
		project["assigned_engineers"] = float(forecast.get("assigned", 0.0))
		if rate <= 0.0:
			continue

		if status == "BETA":
			var beta_cost := int(round(float(project.get("monthly_cost", 0)) * 0.60))
			Economy.add_expense(beta_cost, "Bêta software — %s" % str(project.get("name", "Produit")))
			project["spent"] = int(project.get("spent", 0)) + Economy.quoted_expense(beta_cost, "Bêta software")
			work_event.emit({"kind":"SOFTWARE", "id":str(project.id), "text":"Tests utilisateurs : +%.0f %%" % (rate * 100.0)})
			project["beta_months_done"] = int(project.get("beta_months_done", 0)) + 1
			project["beta_work_done"] = float(project.get("beta_work_done", 0.0)) + rate
			if float(project.get("beta_work_done", 0.0)) >= 1.0:
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

		var monthly_cost := int(project.get("monthly_cost", 0))
		Economy.add_expense(monthly_cost, "Développement software — %s" % CAT.family_label(str(project.family)))
		project["spent"] = int(project.get("spent", 0)) + Economy.quoted_expense(monthly_cost, "Développement software")
		var before_work := float(project.get("work_done", project.get("months_done", 0)))
		var effort := _advance_work(project, rate)
		var bugs_before := int(project.get("bugs", 0))
		if kind == "STUDIO":
			var finished := mini(studio_phase_index(project), 3) if int(project.get("months_done", 0)) < int(project.get("months_total", 1)) else 3
			while int(project.get("phase_reported", 0)) < finished:
				_studio_phase_report(project, int(project.get("phase_reported", 0)))
				project["phase_reported"] = int(project.get("phase_reported", 0)) + 1
		if kind == "UTILITY_SLICE":
			# Use the phase at the start of this work, then expose the next checkpoint.
			var after_work := float(project.work_done)
			project["work_done"] = before_work
			_apply_software_cockpit_month(project, effort)
			project["work_done"] = after_work
		var event := {"kind":"SOFTWARE", "id":str(project.id), "name":str(project.get("name", "Logiciel")),
			"text":"Avancement +%.0f %%" % (effort / maxf(float(project.get("months_total", 1)), 1.0) * 100.0)}
		if int(project.get("bugs", 0)) < bugs_before:
			event["text"] = "%d défauts corrigés" % (bugs_before - int(project.get("bugs", 0)))
		project["work_last"] = str(event.text)
		work_event.emit(event)

		if kind in ["PATCH", "UPDATE"] and int(project.get("months_done", 0)) >= int(project.get("months_total", 1)):
			projects.erase(project)
			_complete_maintenance(project)
			continue

		if kind == "UTILITY_SLICE" and not bool(project.get("incident_done", false)) and int(project.get("months_total", 1)) >= 3:
			var midpoint := maxi(1, int(ceil(float(project.get("months_total", 1)) / 2.0)))
			if int(project.get("months_done", 0)) >= midpoint:
				project["incident_done"] = true
				var stability := float((project.get("metrics", {}) as Dictionary).get("stability", 50.0))
				if int(project.get("bugs", 0)) < 10 and stability >= 55.0:
					project["cockpit_last_outcome"] = "Tests internes validés : la préparation a évité un incident."
					CompanyManager.add_alert(str(project.name) + " : tests validés, aucun incident bloquant.")
					_ensure_software_directive(project)
					continue
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
			if kind == "UTILITY_SLICE":
				_ensure_software_directive(project)
			continue

		if kind in ["UTILITY_SLICE", "STUDIO"]:
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
		"licenses_last":0, "licenses_total":0, "installed_users":0, "supported_users":0,
		"support_cohorts":CAT.support_cohorts({"licenses_total":0}, TimeManager.year, TimeManager.month),
		"revenue_last":0, "support_last":0, "margin_last":0}
	if str(project.get("kind", "")) == "UTILITY_SLICE":
		product["kind"] = "UTILITY_SLICE"
		product["target"] = str(project.get("target", "HOME"))
		product["features"] = (project.get("features", []) as Array).duplicate()
		product["metrics"] = explicit_metrics.duplicate(true)
		product["cockpit_directive_history"] = (project.get("cockpit_directive_history", []) as Array).duplicate(true)
		product["bugs_known"] = int(project.get("bugs", 0))
		product["version_major"] = 1
		product["version_minor"] = 0
		product["version_patch"] = 0
		var gains := PLAY.utility_skill_gains(product["features"])
		for skill_value in gains.keys():
			var skill_id := str(skill_value)
			skills[skill_id] = skill_xp(skill_id) + int(gains[skill_id])
	if str(project.get("kind", "")) == "STUDIO":
		_studio_launch(project, product)
	product["development_spent"] = int(project.get("spent", 0))
	product["spend_tracking_complete"] = bool(project.get("spend_tracking_complete", false))
	product["margin_total"] = 0
	products.append(product)
	var state := family_state(family_id)
	state["launches"] = int(state.get("launches", 0)) + 1
	if product_mastery < LAUNCH_MASTERY_CAP: state["mastery"] = product_mastery + 1
	reveals.append(str(product.id))
	if str(product.get("kind", "")) == "STUDIO":
		CompanyManager.add_alert("%s v1.0 est sorti : la presse lui donne %s/10. %s" % [str(product.name), _note_text(float(product.note)), str(product.get("missed", ""))])
	else:
		CompanyManager.add_alert("%s v1.0 est sorti : %d bugs connus, qualité %.0f/100. Premier bilan des licences au prochain mois." % [str(product.name), int(product.get("bugs_known", 0)), quality])
	software_launched.emit(product)
func _process_sales() -> void:
	var now := CAT.year_f(TimeManager.year, TimeManager.month)
	# Age all licences, including suspended products, before this month's sales.
	for product_value in products:
		var product: Dictionary = product_value
		var cohorts := CAT.support_cohorts(product, TimeManager.year, TimeManager.month)
		cohorts.pop_front()
		cohorts.append(0)
		product["support_cohorts"] = cohorts
		product["supported_users"] = CAT.supported_licenses(cohorts)
	for family_value in CAT.FAMILY_ORDER:
		var family_id := str(family_value)
		var active := active_products(family_id)
		if active.is_empty(): continue
		var market := CAT.market_users(family_id, now) * BalanceManager.market_demand_factor()
		var weights: Array[float] = []
		var reaches: Array[float] = []
		var total_weight := 0.0
		for value in active:
			var product: Dictionary = value
			var scores := CAT.axis_scores(family_id, product.levels, int(product.mastery), float(product.launch_f), now)
			var quality := 0.0
			for score in scores.values(): quality += float(score)
			quality /= maxf(float(scores.size()), 1.0)
			if str(product.get("kind", "")) == "UTILITY_SLICE" and not (product.get("metrics", {}) as Dictionary).is_empty():
				var target_data: Dictionary = (CAT.SEGMENTS.get(family_id, {}) as Dictionary).get(str(product.get("target", "HOME")), {})
				var target_weights: Dictionary = target_data.get("weights", {})
				quality = 0.0
				var quality_weight := 0.0
				for axis in SOFTWARE_COCKPIT_AXES:
					var axis_weight := float(target_weights.get(axis, 0.25))
					quality += float((product.get("metrics", {}) as Dictionary).get(axis, 50.0)) * axis_weight
					quality_weight += axis_weight
				quality /= maxf(quality_weight, 0.001)
				var aging := float(CAT.family(family_id).get("aging_per_year", 0.35)) * maxf(0.0, now - float(product.launch_f)) * CAT.POINTS_PER_LEVEL
				quality = clampf(quality - aging, 3.0, 99.0)
			var price_penalty := CAT.price_factor(str(product.price_mode)) - 1.0
			var weight := maxf(0.2, 1.0 + (quality - 50.0) / 25.0 - price_penalty)
			var reach_factor := 1.0
			if str(product.get("kind", "")) == "STUDIO":
				# Logiciel 2.0 : la note de la presse (qui vieillit) fait la demande ; le public et la plateforme la portée.
				var live_note := studio_live_note(product, now)
				product["note_live"] = live_note
				quality = 50.0 + (live_note - 5.5) * 4.5
				weight = clampf(pow(live_note / 6.0, 1.6) - price_penalty * 0.8, 0.12, 3.5)
				if str(product.get("platform", "")) == "OWN":
					product["own_reach"] = own_cpu_reach()
				reach_factor = STUDIO.reach(family_id, str(product.get("audience", "HOBBY")), str(product.get("platform", "LEADER")), float(product.get("own_reach", 0.2))) * STUDIO_REACH_SCALE
			if str(product.get("kind", "")) == "UTILITY_SLICE":
				var bug_penalty := clampf(1.0 - float(product.get("bugs_known", 0)) / 80.0, 0.55, 1.0)
				weight *= bug_penalty
			product["quality_live"] = quality
			product["demand_weight"] = weight
			product["reach_factor"] = reach_factor
			weights.append(weight); reaches.append(reach_factor); total_weight += weight
		var player_share := clampf(0.08 + CompanyManager.get_brand_score() / 500.0, 0.08, 0.30)
		# One external offer competes for a finite reachable market. At weight 1,
		# a single product keeps the original share; quality/price/bugs affect demand.
		var reachable_market := market * minf(player_share * 2.0, 0.60)
		for i in range(active.size()):
			var product: Dictionary = active[i]
			var licenses := int(floor(reachable_market * float(reaches[i]) * float(weights[i]) / (1.0 + total_weight)))
			var revenue := int(round(float(licenses) * float(product.price)))
			product["installed_users"] = int(product.installed_users) + licenses
			var cohorts: Array = product.support_cohorts
			cohorts[CAT.SUPPORT_MONTHS - 1] = licenses
			product["supported_users"] = CAT.supported_licenses(cohorts)
			var support_raw := CAT.support_monthly_cost(family_id, int(product.supported_users), float(product.get("price", 0.0)))
			var support := Economy.quoted_expense(support_raw, "Support software")
			product["licenses_last"] = licenses; product["licenses_total"] = int(product.licenses_total) + licenses
			product["revenue_last"] = revenue; product["support_last"] = support; product["margin_last"] = revenue - support
			product["margin_total"] = int(product.get("margin_total", 0)) + revenue - support
			product["market_months"] = int(product.get("market_months", 0)) + 1
			if str(product.get("kind", "")) == "STUDIO" and int(product.market_months) == 1:
				CompanyManager.add_alert("Premier mois de %s : %s licences, %s € de recettes." % [str(product.name), _thousands(licenses), _thousands(revenue)])
			product["feedback"] = product_feedback(product)
			Economy.add_income(revenue, "Licences software — %s" % CAT.family_label(family_id))
			Economy.add_expense(support_raw, "Support software — %s" % CAT.family_label(family_id))
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
		var rate := float(PersonnelManager.allocation_for({"id":"ACT:" + activity_id, "kind":"SOFTWARE", "need":1.0}).get("factor", 0.0))
		if rate <= 0.0:
			continue
		var cost := int(terms.get("monthly_cost", 0))
		if cost > 0:
			Economy.add_expense(cost, "Activité software — %s" % ACTIVITY.label(activity_id))
		current["spent"] = int(current.get("spent", 0)) + Economy.quoted_expense(cost, "Activité software")
		current["work_done"] = float(current.get("work_done", current.get("months_done", 0))) + rate
		current["months_done"] = int(floor(float(current.work_done) + 0.0001))
		current["elapsed_months"] = int(current.get("elapsed_months", 0)) + 1
		work_event.emit({"kind":"SOFTWARE", "id":"ACT:" + activity_id, "text":"Contrat : +%.0f %%" % (rate / maxf(float(terms.get("months", 1)), 1.0) * 100.0)})
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
		"notebook":notebook,
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
	for product in products:
		product["support_cohorts"] = CAT.support_cohorts(product, TimeManager.year, TimeManager.month)
		product["supported_users"] = CAT.supported_licenses(product.support_cohorts)
	reveals = state.get("reveals", []).duplicate(true)
	activities = state.get("activities", []).duplicate(true)
	completed_activities = int(state.get("completed_activities", 0))
	var saved_skills = state.get("skills", {})
	if typeof(saved_skills) == TYPE_DICTIONARY:
		for skill_id in PLAY.SKILL_ORDER:
			skills[str(skill_id)] = int((saved_skills as Dictionary).get(str(skill_id), skills.get(str(skill_id), 0)))
	var saved_notebook = state.get("notebook", {})
	notebook = (saved_notebook as Dictionary).duplicate(true) if typeof(saved_notebook) == TYPE_DICTIONARY else empty_notebook()
	_notebook()
	_next_id = int(state.get("next_id", projects.size() + products.size() + 1))
	software_changed.emit()

func set_product_price(product_id: String, price_mode: String) -> bool:
	if not CAT.PRICE_MODES.has(price_mode):
		return false
	for value in products:
		var product: Dictionary = value
		if str(product.get("id", "")) == product_id:
			product["price_mode"] = price_mode
			if str(product.get("kind", "")) == "STUDIO":
				product["price"] = studio_price(str(product.family), str(product.get("audience", "HOBBY")), price_mode)
			else:
				product["price"] = CAT.license_price(str(product.family), price_mode)
			software_changed.emit()
			return true
	return false

func set_product_active(product_id: String, active: bool) -> bool:
	for value in products:
		var product: Dictionary = value
		if str(product.get("id", "")) == product_id:
			if not active and projects.any(func(p): return str(p.get("product_id", "")) == product_id):
				return false
			product["status"] = "ACTIVE" if active else "RETIRED"
			product["licenses_last"] = 0
			product["revenue_last"] = 0
			product["support_last"] = 0
			product["margin_last"] = 0
			software_changed.emit()
			return true
	return false

func product_feedback(product: Dictionary) -> String:
	if str(product.get("status", "")) != "ACTIVE":
		return "Catalogue suspendu : aucune nouvelle vente ni charge de support. Reprise possible."
	if int(product.get("market_months", 0)) == 0:
		return "Premiers résultats disponibles au prochain bilan mensuel."
	if int(product.get("bugs_known", 0)) >= 10:
		return "Les défauts freinent la demande. Un correctif améliore la confiance et les ventes."
	if str(product.get("kind", "")) == "STUDIO" and float(product.get("note_live", product.get("note", 5.0))) < float(product.get("note", 5.0)) - 1.5:
		return "Le logiciel a vieilli : la presse ne lui donnerait plus que %s/10. Une nouvelle version le relancerait." % _note_text(float(product.get("note_live", 5.0)))
	if int(product.get("margin_last", 0)) < 0:
		return "Le support coûte plus que les ventes. Revoyez le prix ou préparez une nouvelle version."
	if float(product.get("quality_live", 50.0)) < 45.0:
		return "Le produit vieillit face aux alternatives. Une mise à jour peut renforcer son intérêt."
	if str(product.get("price_mode", "")) == "PREMIUM":
		return "Le tarif premium rapporte plus par licence et réduit la demande. Comparez la marge au prochain mois."
	return "Le produit trouve son public. Les résultats dépendent de sa qualité, du prix, des bugs et de la concurrence."
