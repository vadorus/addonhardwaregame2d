extends Node

signal executive_changed
signal hr_issue_created(issue)

const BENEFIT_OPTIONS := {
	"HEALTH": {
		"label":"Couverture santé / mutuelle",
		"NONE":{"label":"Aucune aide","cost_per_employee":0,"morale":-0.08,"retention":-0.10,"training":0.0},
		"BASIC":{"label":"Couverture de base","cost_per_employee":180,"morale":0.16,"retention":0.20,"training":0.0},
		"STRONG":{"label":"Bonne couverture","cost_per_employee":340,"morale":0.34,"retention":0.45,"training":0.0}
	},
	"MEALS": {
		"label":"Repas / restauration",
		"NONE":{"label":"Aucun dispositif","cost_per_employee":0,"morale":-0.04,"retention":-0.04,"training":0.0},
		"BASIC":{"label":"Participation repas","cost_per_employee":110,"morale":0.13,"retention":0.08,"training":0.0},
		"STRONG":{"label":"Restauration entreprise","cost_per_employee":230,"morale":0.28,"retention":0.16,"training":0.0}
	},
	"TRAINING": {
		"label":"Formation continue",
		"NONE":{"label":"Au besoin","cost_per_employee":0,"morale":0.0,"retention":-0.03,"training":0.0},
		"BASIC":{"label":"Budget formation","cost_per_employee":150,"morale":0.08,"retention":0.13,"training":0.010},
		"STRONG":{"label":"Programme de développement","cost_per_employee":360,"morale":0.18,"retention":0.28,"training":0.025}
	},
	"REST": {
		"label":"Espaces et qualité de vie",
		"NONE":{"label":"Le strict nécessaire","cost_per_employee":0,"morale":-0.06,"retention":-0.04,"training":0.0},
		"BASIC":{"label":"Coin repos / confort","cost_per_employee":90,"morale":0.13,"retention":0.08,"training":0.0},
		"STRONG":{"label":"Espaces salariés complets","cost_per_employee":210,"morale":0.27,"retention":0.18,"training":0.0}
	}
}

const WORKPLACE_TIERS := {
	0: {"name":"Garage aménagé","capacity":8,"environment":38.0,"upgrade_cost":0,"monthly_cost":900},
	1: {"name":"Atelier + bureaux","capacity":16,"environment":54.0,"upgrade_cost":75000,"monthly_cost":2100},
	2: {"name":"Siège technique","capacity":36,"environment":70.0,"upgrade_cost":220000,"monthly_cost":5600},
	3: {"name":"Campus R&D","capacity":80,"environment":84.0,"upgrade_cost":650000,"monthly_cost":15500}
}

var right_hand := {
	"name":"Nora Bernard",
	"role":"Bras droit / vice-présidente",
	"strengths":["priorisation","coordination","lecture des risques"]
}
var benefit_policy := {
	"HEALTH":"BASIC",
	"MEALS":"NONE",
	"TRAINING":"NONE",
	"REST":"BASIC"
}
var workplace := {
	"tier":0,
	"condition":62.0,
	"last_renovation_year":1971,
	"last_renovation_month":1
}
var hr_issues: Array = []
var _next_hr_issue_id := 1
var months_operated := 0
var interface_unlocks := {
	"QG":true,
	"LAB":true,
	"COMPANY":false,
	"TEAM":false,
	"PRODUCTS":false,
	"MARKET":false,
	"PRESS":false
}
var unlock_history: Array = []

func reset():
	benefit_policy = {"HEALTH":"BASIC","MEALS":"NONE","TRAINING":"NONE","REST":"BASIC"}
	workplace = {"tier":0,"condition":62.0,"last_renovation_year":TimeManager.year,"last_renovation_month":TimeManager.month}
	hr_issues = []
	_next_hr_issue_id = 1
	months_operated = 0
	interface_unlocks = {
		"QG":true,
		"LAB":true,
		"COMPANY":false,
		"TEAM":false,
		"PRODUCTS":false,
		"MARKET":false,
		"PRESS":false
	}
	unlock_history = []
	executive_changed.emit()

func is_interface_feature_unlocked(feature: String) -> bool:
	return bool(interface_unlocks.get(feature, false))

func get_interface_unlocks() -> Dictionary:
	return interface_unlocks.duplicate(true)

func get_unlock_history() -> Array:
	return unlock_history.duplicate(true)

func sync_interface_unlocks() -> Array:
	var newly_unlocked: Array = []
	if not CompanyManager.created:
		return newly_unlocked

	var has_project := not ResearchManager.projects.is_empty()
	var has_production := not ProductionManager.jobs.is_empty()
	var has_products := not ProductManager.products.is_empty()
	var has_launched_product := false
	var has_market_history := false
	for product in ProductManager.products:
		if str(product.get("status", "")) == "LAUNCHED":
			has_launched_product = true
			if int(product.get("months_on_market", 0)) >= 1:
				has_market_history = true

	var rules := {
		"TEAM":has_project or has_production or has_products,
		"COMPANY":months_operated >= 1 or not get_open_hr_issues().is_empty() or int(workplace.get("tier", 0)) > 0,
		"PRODUCTS":has_production or has_products,
		"MARKET":has_launched_product,
		"PRESS":not MediaManager.news.is_empty() or has_market_history
	}
	for feature_value in rules.keys():
		var feature := str(feature_value)
		if bool(rules[feature]) and not is_interface_feature_unlocked(feature):
			_unlock_interface_feature(feature)
			newly_unlocked.append(feature)
	return newly_unlocked

func _unlock_interface_feature(feature: String):
	interface_unlocks[feature] = true
	var data := interface_feature_info(feature)
	var event := {
		"feature":feature,
		"label":str(data.get("label", feature)),
		"message":str(data.get("message", "")),
		"month":TimeManager.month,
		"year":TimeManager.year
	}
	unlock_history.push_front(event)
	if unlock_history.size() > 20:
		unlock_history.pop_back()
	CompanyManager.add_alert("Nora : nouveau panneau disponible — %s. %s" % [str(event.label), str(event.message)])

func interface_feature_info(feature: String) -> Dictionary:
	match feature:
		"QG":
			return {"label":"QG","message":"Votre point d'entrée : une priorité à la fois."}
		"LAB":
			return {"label":"Laboratoire CPU","message":"Commencez par construire et comprendre votre premier processeur."}
		"TEAM":
			return {"label":"Équipe","message":"Le projet est lancé : les compétences et l'organisation humaine ont maintenant un impact concret."}
		"COMPANY":
			return {"label":"Entreprise","message":"Après vos premiers mois, budgets, avantages, locaux et conseil financier deviennent utiles."}
		"PRODUCTS":
			return {"label":"Production & Produits","message":"Votre CPU quitte le laboratoire : industrialisation, binning et préparation commerciale entrent en jeu."}
		"MARKET":
			return {"label":"Marché","message":"Votre premier CPU est vendu : concurrence, demande, contrats et SAV deviennent visibles."}
		"PRESS":
			return {"label":"Presse","message":"Le marché commence à parler de vous. Les avis et événements publics comptent désormais."}
	return {"label":feature,"message":""}

func next_interface_unlock_hint() -> Dictionary:
	for feature in ["TEAM","COMPANY","PRODUCTS","MARKET","PRESS"]:
		if is_interface_feature_unlocked(feature):
			continue
		match feature:
			"TEAM":
				return {"feature":feature,"text":"Lancez votre premier projet CPU pour ouvrir la gestion de l'équipe."}
			"COMPANY":
				return {"feature":feature,"text":"Faites tourner l'entreprise un premier mois pour ouvrir budgets, RH et locaux."}
			"PRODUCTS":
				return {"feature":feature,"text":"Terminez le développement d'un CPU pour ouvrir l'industrialisation et les produits."}
			"MARKET":
				return {"feature":feature,"text":"Commercialisez un CPU pour ouvrir l'analyse du marché."}
			"PRESS":
				return {"feature":feature,"text":"Obtenez vos premiers retours publics pour ouvrir la presse."}
	return {}

func get_right_hand() -> Dictionary:
	return right_hand.duplicate(true)

func benefit_category_keys() -> Array:
	return ["HEALTH","MEALS","TRAINING","REST"]

func benefit_category_label(category: String) -> String:
	return str(BENEFIT_OPTIONS.get(category, {}).get("label", category.capitalize()))

func benefit_option_keys(category: String) -> Array:
	var result: Array = []
	if not BENEFIT_OPTIONS.has(category):
		return result
	for key in ["NONE","BASIC","STRONG"]:
		if BENEFIT_OPTIONS[category].has(key):
			result.append(key)
	return result

func benefit_option_label(category: String, option: String) -> String:
	return str(BENEFIT_OPTIONS.get(category, {}).get(option, {}).get("label", option.capitalize()))

func set_benefit_policy(category: String, option: String) -> bool:
	if not BENEFIT_OPTIONS.has(category) or not BENEFIT_OPTIONS[category].has(option):
		return false
	benefit_policy[category] = option
	CompanyManager.add_alert("RH : %s passe à « %s »." % [benefit_category_label(category), benefit_option_label(category, option)])
	executive_changed.emit()
	return true

func workplace_data() -> Dictionary:
	var tier := clampi(int(workplace.get("tier", 0)), 0, WORKPLACE_TIERS.size() - 1)
	var data: Dictionary = WORKPLACE_TIERS[tier].duplicate(true)
	data["tier"] = tier
	data["condition"] = float(workplace.get("condition", 60.0))
	data["occupancy"] = PersonnelManager.staff.size()
	data["over_capacity"] = maxi(PersonnelManager.staff.size() - int(data.capacity), 0)
	data["score"] = workplace_score()
	return data

func workplace_score() -> float:
	var tier := clampi(int(workplace.get("tier", 0)), 0, WORKPLACE_TIERS.size() - 1)
	var data: Dictionary = WORKPLACE_TIERS[tier]
	var score := float(data.environment) * 0.70 + float(workplace.get("condition", 60.0)) * 0.30
	var overflow := maxi(PersonnelManager.staff.size() - int(data.capacity), 0)
	score -= float(overflow) * 4.5
	return clampf(score, 10.0, 95.0)

func next_workplace_upgrade() -> Dictionary:
	var current := int(workplace.get("tier", 0))
	var next_tier := current + 1
	if not WORKPLACE_TIERS.has(next_tier):
		return {}
	var result: Dictionary = WORKPLACE_TIERS[next_tier].duplicate(true)
	result["tier"] = next_tier
	return result

func renovate_workplace() -> bool:
	var upgrade := next_workplace_upgrade()
	if upgrade.is_empty():
		return false
	var cost := int(upgrade.get("upgrade_cost", 0))
	if Economy.money < cost:
		return false
	Economy.add_expense(cost, "Rénovation / nouveaux locaux")
	workplace["tier"] = int(upgrade.tier)
	workplace["condition"] = 92.0
	workplace["last_renovation_year"] = TimeManager.year
	workplace["last_renovation_month"] = TimeManager.month
	CompanyManager.change_reputation({"professional":1.2,"prestige":0.45,"sustainability":0.18})
	CompanyManager.add_alert("Locaux : l'entreprise emménage dans « %s »." % str(upgrade.name))
	_resolve_matching_hr_issues("OVERCROWDING")
	executive_changed.emit()
	return true

func maintain_workplace() -> bool:
	var tier := int(workplace.get("tier", 0))
	var cost := 4000 + int(WORKPLACE_TIERS[tier].monthly_cost) * 2
	if Economy.money < cost:
		return false
	Economy.add_expense(cost, "Entretien des locaux")
	workplace["condition"] = clampf(float(workplace.get("condition", 60.0)) + 18.0, 0.0, 100.0)
	CompanyManager.add_alert("Locaux : une remise en état améliore les conditions de travail.")
	executive_changed.emit()
	return true

func monthly_benefit_cost() -> int:
	var employees := PersonnelManager.staff.size()
	var total := 0
	for category in benefit_category_keys():
		var option := str(benefit_policy.get(category, "NONE"))
		total += int(BENEFIT_OPTIONS[category][option].cost_per_employee) * employees
	return total

func monthly_workplace_cost() -> int:
	var tier := clampi(int(workplace.get("tier", 0)), 0, WORKPLACE_TIERS.size() - 1)
	return int(WORKPLACE_TIERS[tier].monthly_cost)

func benefits_morale_effect() -> float:
	var result := 0.0
	for category in benefit_category_keys():
		var option := str(benefit_policy.get(category, "NONE"))
		result += float(BENEFIT_OPTIONS[category][option].morale)
	return result

func benefits_retention_score() -> float:
	var score := 50.0
	for category in benefit_category_keys():
		var option := str(benefit_policy.get(category, "NONE"))
		score += float(BENEFIT_OPTIONS[category][option].retention) * 18.0
	return clampf(score, 15.0, 95.0)

func benefits_training_gain() -> float:
	var option := str(benefit_policy.get("TRAINING", "NONE"))
	return float(BENEFIT_OPTIONS.TRAINING[option].training)

func process_month():
	if not CompanyManager.created:
		return
	months_operated += 1
	var benefit_cost := monthly_benefit_cost()
	if benefit_cost > 0:
		Economy.add_expense(benefit_cost, "Avantages salariés")
	var workplace_cost := monthly_workplace_cost()
	if workplace_cost > 0:
		Economy.add_expense(workplace_cost, "Entretien / locaux")
	workplace["condition"] = clampf(float(workplace.get("condition", 60.0)) - 0.45 - float(PersonnelManager.staff.size()) * 0.015, 20.0, 100.0)

	var environment := workplace_score()
	var morale_delta := benefits_morale_effect() + (environment - 50.0) / 115.0
	var overflow := int(workplace_data().get("over_capacity", 0))
	if overflow > 0:
		morale_delta -= minf(0.18 * float(overflow), 1.2)
	PersonnelManager.apply_company_environment(morale_delta, benefits_training_gain())
	_detect_hr_issues()
	sync_interface_unlocks()
	executive_changed.emit()

func _detect_hr_issues():
	var data := workplace_data()
	if int(data.over_capacity) > 0 and not _has_open_issue("OVERCROWDING", ""):
		_add_hr_issue(
			"OVERCROWDING","Locaux saturés","",
			"Nous avons %d personne(s) pour %d places. La promiscuité commence à peser sur l'équipe." % [PersonnelManager.staff.size(), int(data.capacity)],
			72.0
		)

	var lowest: Dictionary = {}
	for emp in PersonnelManager.staff:
		if lowest.is_empty() or float(emp.get("morale", 75.0)) < float(lowest.get("morale", 101.0)):
			lowest = emp
	if not lowest.is_empty() and float(lowest.get("morale", 75.0)) < 52.0:
		var employee_id := str(lowest.get("id", ""))
		if not _has_open_issue("MORALE", employee_id):
			_add_hr_issue(
				"MORALE","Un salarié décroche",employee_id,
				"%s semble en difficulté : moral %.0f/100. Un entretien peut éviter que le problème s'installe." % [str(lowest.get("name", "Un salarié")), float(lowest.get("morale", 0.0))],
				clampf(72.0 - float(lowest.get("morale", 50.0)), 25.0, 88.0)
			)

	for department in CompanyManager.departments.keys():
		var cohesion := float(CompanyManager.departments[department].get("cohesion", 30.0))
		if cohesion < 22.0 and not _has_open_issue("COHESION", str(department)):
			_add_hr_issue(
				"COHESION","Tensions dans l'équipe",str(department),
				"Le département %s manque de cohésion. Le DRH recommande une intervention avant que cela ne ralentisse les projets." % str(department),
				55.0
			)

func _has_open_issue(issue_type: String, subject_id: String) -> bool:
	for issue in hr_issues:
		if str(issue.get("status", "")) == "OPEN" and str(issue.get("type", "")) == issue_type and str(issue.get("subject_id", "")) == subject_id:
			return true
	return false

func _add_hr_issue(issue_type: String, title: String, subject_id: String, text: String, severity: float):
	var issue := {
		"id":"HR-%03d" % _next_hr_issue_id,
		"type":issue_type,
		"title":title,
		"subject_id":subject_id,
		"text":text,
		"severity":severity,
		"status":"OPEN",
		"created_month":TimeManager.month,
		"created_year":TimeManager.year,
		"history":[]
	}
	_next_hr_issue_id += 1
	hr_issues.push_front(issue)
	if hr_issues.size() > 20:
		hr_issues.pop_back()
	CompanyManager.add_alert("RH : %s." % title)
	hr_issue_created.emit(issue.duplicate(true))

func get_open_hr_issues() -> Array:
	var result: Array = []
	for issue in hr_issues:
		if str(issue.get("status", "")) == "OPEN":
			result.append(issue.duplicate(true))
	return result

func get_hr_issue(issue_id: String) -> Dictionary:
	for issue in hr_issues:
		if str(issue.get("id", "")) == issue_id:
			return issue
	return {}

func resolve_hr_issue(issue_id: String, action: String) -> bool:
	var issue := get_hr_issue(issue_id)
	if issue.is_empty() or str(issue.get("status", "")) != "OPEN":
		return false
	var subject_id := str(issue.get("subject_id", ""))
	match action:
		"DISCUSS":
			if str(issue.get("type", "")) == "MORALE":
				PersonnelManager.change_employee_morale(subject_id, 8.0)
			elif str(issue.get("type", "")) == "COHESION" and CompanyManager.departments.has(subject_id):
				CompanyManager.departments[subject_id]["cohesion"] = clampf(float(CompanyManager.departments[subject_id].get("cohesion", 30.0)) + 7.0, 0.0, 100.0)
			elif str(issue.get("type", "")) == "OVERCROWDING":
				workplace["condition"] = clampf(float(workplace.get("condition", 60.0)) + 2.0, 0.0, 100.0)
		"BONUS":
			var cost := 3500
			if subject_id != "":
				var emp := PersonnelManager.get_employee(subject_id)
				if not emp.is_empty():
					cost = maxi(2500, int(emp.get("salary", 4000)) / 2)
			if Economy.money < cost:
				return false
			Economy.add_expense(cost, "Action RH exceptionnelle")
			if subject_id != "":
				PersonnelManager.change_employee_morale(subject_id, 14.0)
			else:
				PersonnelManager.apply_company_environment(2.5, 0.0)
		_:
			return false
	issue["status"] = "RESOLVED"
	issue["resolved_action"] = action
	var history: Array = issue.get("history", [])
	history.push_front("Résolu par %s." % ("entretien" if action == "DISCUSS" else "mesure financière"))
	issue["history"] = history
	CompanyManager.add_alert("RH : dossier « %s » traité." % str(issue.get("title", "")))
	executive_changed.emit()
	return true

func _resolve_matching_hr_issues(issue_type: String):
	for issue in hr_issues:
		if str(issue.get("type", "")) == issue_type and str(issue.get("status", "")) == "OPEN":
			issue["status"] = "RESOLVED"
			issue["resolved_action"] = "WORKPLACE_UPGRADE"

func staff_average_morale() -> float:
	if PersonnelManager.staff.is_empty():
		return 50.0
	var total := 0.0
	for emp in PersonnelManager.staff:
		total += float(emp.get("morale", 50.0))
	return total / float(PersonnelManager.staff.size())

func estimated_structural_monthly_cost() -> int:
	var payroll := 0
	for emp in PersonnelManager.staff:
		payroll += int(emp.get("salary", 0))
	var policy_cost := int(CompanyManager.policies.get("marketing_budget", 0)) + int(CompanyManager.policies.get("support_budget", 0)) + int(CompanyManager.policies.get("environment_budget", 0))
	return 7500 + payroll + policy_cost + monthly_benefit_cost() + monthly_workplace_cost()

func financial_advice(proposed_cost: int = 0, extra_monthly_cost: int = 0) -> Dictionary:
	var cash_after := Economy.money - maxi(proposed_cost, 0)
	var monthly_burn := estimated_structural_monthly_cost() + maxi(extra_monthly_cost, 0)
	if not Economy.history.is_empty():
		var recent_count := mini(Economy.history.size(), 3)
		var recent_burn := 0.0
		for i in range(Economy.history.size() - recent_count, Economy.history.size()):
			var report: Dictionary = Economy.history[i]
			recent_burn += maxf(float(report.get("expenses", 0)) - float(report.get("income", 0)), 0.0)
		recent_burn /= maxf(float(recent_count), 1.0)
		monthly_burn = maxi(monthly_burn, int(round(recent_burn)))
	var runway := float(cash_after) / maxf(float(monthly_burn), 1.0)
	var level := "CONFORTABLE"
	var recommendation := "La trésorerie reste confortable après cette décision."
	if cash_after <= 0:
		level = "IMPOSSIBLE"
		recommendation = "Cette décision épuise la trésorerie. Il faut réduire, reporter ou financer autrement."
	elif runway < 3.0:
		level = "DANGEREUX"
		recommendation = "Il resterait moins de trois mois de marge. Le conseil financier recommande de reporter ou réduire l'engagement."
	elif runway < 6.0:
		level = "TENDU"
		recommendation = "C'est faisable, mais la réserve deviendrait faible. Préservez une solution de financement ou réduisez le projet."
	elif runway < 12.0:
		level = "MAÎTRISÉ"
		recommendation = "La décision est finançable avec une réserve correcte, sous réserve de ne pas cumuler plusieurs gros engagements."
	return {
		"proposed_cost":maxi(proposed_cost, 0),
		"extra_monthly_cost":maxi(extra_monthly_cost, 0),
		"cash_before":Economy.money,
		"cash_after":cash_after,
		"monthly_burn":monthly_burn,
		"runway_months":maxf(runway, 0.0),
		"level":level,
		"can_afford":cash_after > 0,
		"recommendation":recommendation
	}

func get_executive_brief() -> Dictionary:
	var priorities: Array = []
	var finance := financial_advice()
	if str(finance.level) in ["IMPOSSIBLE","DANGEREUX","TENDU"]:
		priorities.append({"category":"FINANCE","severity":90 if str(finance.level) in ["IMPOSSIBLE","DANGEREUX"] else 68,"text":"Trésorerie : environ %.1f mois de marge structurelle." % float(finance.runway_months),"action":"Surveiller les dépenses avant tout nouvel engagement."})

	var open_hr := get_open_hr_issues()
	if not open_hr.is_empty():
		var issue: Dictionary = open_hr[0]
		priorities.append({"category":"RH","severity":float(issue.get("severity", 50.0)),"text":str(issue.get("text", "")),"action":"Ouvrir le dossier RH et choisir une réponse."})

	var workspace := workplace_data()
	if int(workspace.over_capacity) > 0:
		priorities.append({"category":"LOCAUX","severity":70,"text":"Les locaux dépassent leur capacité de %d personne(s)." % int(workspace.over_capacity),"action":"Préparer un agrandissement ou ralentir les recrutements."})

	var open_sav := AfterSalesManager.get_open_cases()
	if not open_sav.is_empty():
		var sav: Dictionary = open_sav[0]
		priorities.append({"category":"SAV","severity":float(sav.get("severity", 55.0)),"text":"Un dossier SAV important concerne %s." % str(sav.get("product_name", "un produit")),"action":"Faire diagnostiquer la cause avant qu'elle ne dégrade la réputation."})

	var remediation_project: Dictionary = {}
	var active_project: Dictionary = {}
	for project in ResearchManager.projects:
		if str(project.get("status", "")) != "DEVELOPMENT":
			continue
		if active_project.is_empty():
			active_project = project
		if int(project.get("remediation_months_remaining", 0)) > 0:
			remediation_project = project
			break
	if not remediation_project.is_empty():
		priorities.append({"category":"TECHNIQUE","severity":62,"text":"%s est en mise au point technique (%d mois restants)." % [str(remediation_project.get("name", "CPU")), int(remediation_project.get("remediation_months_remaining", 0))],"action":"Laisser l'équipe terminer la solution validée avant de juger le planning produit."})
	elif not active_project.is_empty():
		priorities.append({"category":"PROJET","severity":45,"text":"%s poursuit son développement." % str(active_project.get("name", "Le CPU")),"action":"Surveiller surtout budget, délai et prochain rapport de phase."})

	if ResearchManager.projects.is_empty() and ProductManager.products.is_empty():
		priorities.append({"category":"DÉMARRAGE","severity":72,"text":"Nous n'avons encore aucun produit en développement.","action":"Concentrez-vous sur un premier CPU simple et maîtrisable."})

	var unlock_hint := next_interface_unlock_hint()
	if not unlock_hint.is_empty() and priorities.size() < 3:
		priorities.append({"category":"GUIDE","severity":28,"text":"Prochaine fonction à découvrir : %s." % str(interface_feature_info(str(unlock_hint.feature)).get("label", "")),"action":str(unlock_hint.text)})

	for product in ProductManager.products:
		if str(product.get("status", "")) == "READY":
			priorities.append({"category":"LANCEMENT","severity":64,"text":"%s est prêt mais pas encore commercialisé." % str(product.get("name", "Un CPU")),"action":"Décidez du prix et de la capacité avant le lancement."})
			break

	priorities.sort_custom(func(a, b): return float(a.get("severity", 0.0)) > float(b.get("severity", 0.0)))
	if priorities.size() > 3:
		priorities = priorities.slice(0, 3)

	var headline := "Je garde l'entreprise lisible : une décision importante à la fois."
	var text := "Pour l'instant, concentrez-vous sur le premier CPU et la trésorerie."
	if not priorities.is_empty():
		var first: Dictionary = priorities[0]
		headline = str(first.get("text", headline))
		text = str(first.get("action", text))
	return {
		"advisor":right_hand.duplicate(true),
		"headline":headline,
		"text":text,
		"priorities":priorities,
		"hr_role":"DRH disponible" if PersonnelManager.staff.size() >= 8 else "Suivi RH assuré avec le bras droit",
		"finance_role":"DAF interne recommandé" if PersonnelManager.staff.size() >= 12 else "Conseil financier assuré avec le bras droit"
	}

func get_state() -> Dictionary:
	return {
		"right_hand":right_hand,
		"benefit_policy":benefit_policy,
		"workplace":workplace,
		"hr_issues":hr_issues,
		"next_hr_issue_id":_next_hr_issue_id,
		"months_operated":months_operated,
		"interface_unlocks":interface_unlocks,
		"unlock_history":unlock_history
	}

func load_state(state: Dictionary):
	var right_value = state.get("right_hand", right_hand)
	if typeof(right_value) == TYPE_DICTIONARY:
		right_hand = right_value.duplicate(true)
	benefit_policy = {"HEALTH":"BASIC","MEALS":"NONE","TRAINING":"NONE","REST":"BASIC"}
	var saved_benefits = state.get("benefit_policy", {})
	if typeof(saved_benefits) == TYPE_DICTIONARY:
		for category in benefit_category_keys():
			var option := str(saved_benefits.get(category, benefit_policy[category]))
			if BENEFIT_OPTIONS[category].has(option):
				benefit_policy[category] = option
	workplace = state.get("workplace", {"tier":0,"condition":62.0,"last_renovation_year":1971,"last_renovation_month":1}).duplicate(true)
	workplace["tier"] = clampi(int(workplace.get("tier", 0)), 0, WORKPLACE_TIERS.size() - 1)
	workplace["condition"] = clampf(float(workplace.get("condition", 62.0)), 0.0, 100.0)
	hr_issues = state.get("hr_issues", []).duplicate(true)
	_next_hr_issue_id = int(state.get("next_hr_issue_id", hr_issues.size() + 1))
	months_operated = int(state.get("months_operated", 0))
	interface_unlocks = {
		"QG":true,
		"LAB":true,
		"COMPANY":false,
		"TEAM":false,
		"PRODUCTS":false,
		"MARKET":false,
		"PRESS":false
	}
	var saved_unlocks = state.get("interface_unlocks", {})
	if typeof(saved_unlocks) == TYPE_DICTIONARY:
		for feature in interface_unlocks.keys():
			interface_unlocks[feature] = bool(saved_unlocks.get(feature, interface_unlocks[feature]))
	interface_unlocks["QG"] = true
	interface_unlocks["LAB"] = true
	unlock_history = state.get("unlock_history", []).duplicate(true)
	executive_changed.emit()
