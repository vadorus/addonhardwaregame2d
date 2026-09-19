extends Node

signal discoveries_changed
signal discovery_created(discovery)
signal discovery_resolved(discovery, action_id)
signal derived_research_completed(research)

const TEMPLATES := {
	"POWER_MANAGEMENT": {
		"title":"Gestion de puissance adaptative",
		"technology":"ADAPTIVE_POWER",
		"summary":"L'équipe a identifié une méthode de gestion de puissance qui peut améliorer l'efficacité des futures conceptions.",
		"metric":"efficiency",
		"immediate_metric":3.0,
		"tech_key":"$FAMILY",
		"immediate_tech":1.0,
		"research_tech":4.0,
		"secondary_key":"integration",
		"secondary_gain":1.2,
		"research_cost":12_000,
		"research_months":2
	},
	"CACHE_POLICY": {
		"title":"Politique de cache optimisée",
		"technology":"SMART_CACHE",
		"summary":"Les mesures de prototype révèlent une politique de cache réutilisable pour augmenter les performances sans pousser uniquement la fréquence.",
		"metric":"performance",
		"immediate_metric":3.0,
		"tech_key":"$FAMILY",
		"immediate_tech":1.2,
		"research_tech":4.5,
		"secondary_key":"integration",
		"secondary_gain":0.8,
		"research_cost":14_000,
		"research_months":2
	},
	"VALIDATION_RULES": {
		"title":"Méthode de validation croisée",
		"technology":"CROSS_VALIDATION",
		"summary":"Une faiblesse du prototype a conduit l'équipe à formaliser une méthode de validation qui peut améliorer la fiabilité des générations suivantes.",
		"metric":"reliability",
		"immediate_metric":3.5,
		"tech_key":"integration",
		"immediate_tech":1.2,
		"research_tech":4.0,
		"secondary_key":"$FAMILY",
		"secondary_gain":1.2,
		"research_cost":13_000,
		"research_months":2
	},
	"FOUNDRY_RULES": {
		"title":"Règles de conception fonderie",
		"technology":"FOUNDRY_DRC",
		"summary":"Le partenariat industriel a permis d'identifier des règles de conception qui améliorent rendement et préparation industrielle.",
		"metric":"",
		"immediate_metric":0.0,
		"tech_key":"manufacturing",
		"immediate_tech":1.5,
		"research_tech":5.0,
		"secondary_key":"$FAMILY",
		"secondary_gain":1.0,
		"research_cost":16_000,
		"research_months":2
	},
	"SAV_RELIABILITY": {
		"title":"Retour SAV transformé en savoir",
		"technology":"FIELD_FAILURE_ANALYTICS",
		"summary":"L'analyse d'un défaut terrain a produit une règle de conception réutilisable pour améliorer la fiabilité des futures générations.",
		"metric":"reliability",
		"immediate_metric":0.0,
		"tech_key":"$FAMILY",
		"immediate_tech":1.5,
		"research_tech":4.0,
		"secondary_key":"manufacturing",
		"secondary_gain":1.5,
		"research_cost":11_000,
		"research_months":2
	},
	"MICROCODE_TOOLING": {
		"title":"Outillage microcode réutilisable",
		"technology":"MICROCODE_TOOLING",
		"summary":"Le correctif logiciel a permis de formaliser de nouveaux outils de validation firmware et compatibilité.",
		"metric":"",
		"immediate_metric":0.0,
		"tech_key":"software",
		"immediate_tech":1.5,
		"research_tech":4.5,
		"secondary_key":"integration",
		"secondary_gain":1.5,
		"research_cost":12_000,
		"research_months":2
	}
}

var pending: Array = []
var active_research: Array = []
var completed: Array = []
var seen_keys: Dictionary = {}
var _next_id := 1

func _ready():
	if not ResearchManager.phase_report_created.is_connected(_on_phase_report):
		ResearchManager.phase_report_created.connect(_on_phase_report)
	if not ProductManager.quality_incident_resolved.is_connected(_on_quality_incident_resolved):
		ProductManager.quality_incident_resolved.connect(_on_quality_incident_resolved)
	if not ProductManager.software_fix_completed.is_connected(_on_software_fix_completed):
		ProductManager.software_fix_completed.connect(_on_software_fix_completed)
	if not ProductManager.product_launched.is_connected(_on_product_launched):
		ProductManager.product_launched.connect(_on_product_launched)

func reset():
	pending = []
	active_research = []
	completed = []
	seen_keys = {}
	_next_id = 1
	discoveries_changed.emit()

func _template_supports_family(template_id: String, family: String) -> bool:
	if not TEMPLATES.has(template_id):
		return false
	var families = TEMPLATES[template_id].get("families", [])
	if typeof(families) != TYPE_ARRAY or families.is_empty():
		return true
	return families.has(family)

func _template_for_weakness(weakness: String, family: String) -> String:
	var preferred := "CACHE_POLICY"
	match weakness:
		"efficiency", "sustainability":
			preferred = "POWER_MANAGEMENT"
		"reliability", "ecosystem":
			preferred = "VALIDATION_RULES"
		_:
			preferred = "CACHE_POLICY"
	if _template_supports_family(preferred, family):
		return preferred
	return "VALIDATION_RULES"

func _family_tech_key(family: String) -> String:
	return GameData.get_product_family_specialization(family)

func _resolve_tech_key(raw_key: String, family: String) -> String:
	return _family_tech_key(family) if raw_key == "$FAMILY" else raw_key

func _on_phase_report(project: Dictionary, report: Dictionary):
	var family := str(project.get("sector", ""))
	if family.is_empty() or not GameData.is_product_family_active(family):
		return
	if str(report.get("phase", "")) != "Prototype":
		return
	var project_id := str(project.get("id", ""))
	var template_id := _template_for_weakness(str(report.get("weakness", "performance")), family)
	_create_discovery(template_id, family, "PROJECT", project_id, project_id, "", _research_team_context(family))

func _research_team_context(family: String) -> Dictionary:
	var specialization := GameData.get_product_family_specialization(family)
	var leader_id := str(CompanyManager.departments.get("R&D", {}).get("leader_id", ""))
	var lead := PersonnelManager.get_employee(leader_id)
	if str(lead.get("department", "")) != "R&D" or str(lead.get("specialization", "")) != specialization:
		lead = {}
		for employee_value in PersonnelManager.staff:
			var employee: Dictionary = employee_value
			if str(employee.get("department", "")) == "R&D" and str(employee.get("specialization", "")) == specialization:
				lead = employee
				break
	if lead.is_empty():
		return {"family":family, "specialization":specialization}
	return {
		"family":family,
		"specialization":specialization,
		"team_department":"R&D",
		"team_lead":str(lead.get("name", "")),
		"team_score":PersonnelManager.team_score("R&D", specialization)
	}

func _on_product_launched(product: Dictionary):
	var choices: Dictionary = product.get("industrialization", {})
	if str(choices.get("contract", "")) != "PARTNER":
		return
	var family := str(product.get("sector", CompanyManager.starting_sector))
	if not _template_supports_family("FOUNDRY_RULES", family):
		return
	var generation_id := str(product.get("generation_id", product.get("id", "")))
	_create_discovery("FOUNDRY_RULES", family, "INDUSTRIALIZATION", generation_id, "", str(product.get("id", "")))

func _on_quality_incident_resolved(incident: Dictionary, action_id: String):
	if action_id == "MINIMAL_SUPPORT":
		return
	var product_id := str(incident.get("product_id", ""))
	var product := ProductManager.get_product(product_id)
	var family := str(product.get("sector", CompanyManager.starting_sector))
	if _template_supports_family("SAV_RELIABILITY", family):
		_create_discovery("SAV_RELIABILITY", family, "SAV", product_id, "", product_id)

func _on_software_fix_completed(product_id: String, _fix: Dictionary):
	var product := ProductManager.get_product(product_id)
	var family := str(product.get("sector", CompanyManager.starting_sector))
	if _template_supports_family("MICROCODE_TOOLING", family):
		_create_discovery("MICROCODE_TOOLING", family, "SOFTWARE", product_id, "", product_id)

func _create_discovery(template_id: String, family: String, source_type: String, source_id: String, project_id: String, product_id: String, team_context: Dictionary = {}) -> Dictionary:
	if not TEMPLATES.has(template_id) or not _template_supports_family(template_id, family):
		return {}
	var seen_key := "%s:%s" % [source_type, source_id]
	if seen_keys.has(seen_key):
		return {}
	seen_keys[seen_key] = true
	var template: Dictionary = TEMPLATES[template_id]
	var discovery := {
		"id":"DISC-%03d" % _next_id,
		"template_id":template_id,
		"family":family,
		"family_label":GameData.get_product_family_label(family),
		"title":str(template.get("title", template_id)),
		"summary":str(template.get("summary", "")),
		"source_type":source_type,
		"source_id":source_id,
		"project_id":project_id,
		"product_id":product_id,
		"status":"PENDING"
	}
	discovery.merge(team_context, true)
	_next_id += 1
	pending.append(discovery)
	CompanyManager.add_alert("Découverte : %s." % str(discovery.title))
	MediaManager.publish_business_event(
		"Nouvelle piste technique chez %s" % CompanyManager.company_name,
		"%s L'équipe doit choisir entre exploitation immédiate et recherche dérivée." % str(discovery.summary)
	)
	discovery_created.emit(discovery.duplicate(true))
	discoveries_changed.emit()
	return discovery

func create_test_discovery(template_id: String, source_id: String = "TEST", family: String = "CPU") -> Dictionary:
	return _create_discovery(template_id, family, "TEST", source_id, "", "")

func get_pending_discovery() -> Dictionary:
	if pending.is_empty():
		return {}
	return pending[0].duplicate(true)

func get_active_research() -> Array:
	return active_research.duplicate(true)

func resolution_options(discovery_id: String) -> Array[Dictionary]:
	var discovery := _find_pending(discovery_id)
	if discovery.is_empty():
		return []
	var template: Dictionary = TEMPLATES.get(str(discovery.get("template_id", "")), {})
	if template.is_empty():
		return []
	var research_months := int(template.get("research_months", 2))
	if str(discovery.get("source_type", "")) == "PROJECT" and float(discovery.get("team_score", 0.0)) >= 95.0:
		research_months = maxi(research_months - 1, 1)
	return [
		{
			"id":"EXPLOIT_NOW",
			"label":"Exploiter maintenant",
			"cost":4_000,
			"months":0,
			"summary":"Petit gain immédiat et savoir-faire limité."
		},
		{
			"id":"DERIVED_RESEARCH",
			"label":"Lancer une recherche dérivée",
			"cost":int(template.get("research_cost", 12_000)),
			"months":research_months,
			"summary":"Équipe experte : savoir-faire durable obtenu plus vite." if research_months < int(template.get("research_months", 2)) else "Plus cher et plus lent, mais bonus technologique durable nettement supérieur."
		}
	]

func _find_pending(discovery_id: String) -> Dictionary:
	for discovery in pending:
		if str(discovery.get("id", "")) == discovery_id:
			return discovery
	return {}

func resolve_discovery(discovery_id: String, action_id: String) -> bool:
	var discovery := _find_pending(discovery_id)
	if discovery.is_empty():
		return false
	var template: Dictionary = TEMPLATES.get(str(discovery.get("template_id", "")), {})
	if template.is_empty():
		return false
	var cost := 0
	var months := 0
	var valid_action := false
	for option in resolution_options(discovery_id):
		if str(option.get("id", "")) == action_id:
			cost = int(option.get("cost", 0))
			months = int(option.get("months", 0))
			valid_action = true
			break
	if not valid_action:
		return false
	if cost > Economy.money:
		return false
	if cost > 0:
		Economy.add_expense(cost, "Découverte technique — %s" % str(discovery.get("title", "R&D")))

	if action_id == "EXPLOIT_NOW":
		var project_id := str(discovery.get("project_id", ""))
		var metric := str(template.get("metric", ""))
		var metric_gain := float(template.get("immediate_metric", 0.0))
		var applied_to_project := false
		if not project_id.is_empty() and not metric.is_empty() and metric_gain > 0.0:
			applied_to_project = ResearchManager.apply_project_metric_bonus(project_id, metric, metric_gain)
		var family := str(discovery.get("family", CompanyManager.starting_sector))
		ResearchManager.add_technology_bonus(_resolve_tech_key(str(template.get("tech_key", "$FAMILY")), family), float(template.get("immediate_tech", 1.0)))
		discovery["resolution"] = "EXPLOIT_NOW"
		discovery["applied_to_project"] = applied_to_project
		discovery["status"] = "COMPLETED"
		pending.erase(discovery)
		completed.append(discovery)
		CompanyManager.add_alert("%s : piste exploitée immédiatement." % str(discovery.get("title", "Découverte")))
		discovery_resolved.emit(discovery.duplicate(true), action_id)
		discoveries_changed.emit()
		return true

	if action_id == "DERIVED_RESEARCH":
		var research := discovery.duplicate(true)
		research["resolution"] = "DERIVED_RESEARCH"
		research["status"] = "RESEARCH"
		research["remaining_months"] = months
		research["total_months"] = months
		research["cost"] = cost
		pending.erase(discovery)
		active_research.append(research)
		CompanyManager.add_alert("%s : recherche dérivée lancée pour %d mois." % [
			str(discovery.get("title", "Découverte")),
			int(research.get("remaining_months", 0))
		])
		discovery_resolved.emit(discovery.duplicate(true), action_id)
		discoveries_changed.emit()
		return true
	return false

func process_month():
	var finished: Array = []
	for research in active_research:
		research["remaining_months"] = maxi(int(research.get("remaining_months", 1)) - 1, 0)
		if int(research.get("remaining_months", 0)) <= 0:
			finished.append(research)
	for research in finished:
		var template: Dictionary = TEMPLATES.get(str(research.get("template_id", "")), {})
		var family := str(research.get("family", CompanyManager.starting_sector))
		ResearchManager.add_technology_bonus(_resolve_tech_key(str(template.get("tech_key", "$FAMILY")), family), float(template.get("research_tech", 4.0)))
		var reusable_technology := str(template.get("technology", ""))
		if not reusable_technology.is_empty():
			TechnologyManager.unlock(
				reusable_technology,
				str(research.get("title", "Recherche dérivée")),
				family
			)
		var secondary_key := _resolve_tech_key(str(template.get("secondary_key", "")), family)
		if not secondary_key.is_empty():
			ResearchManager.add_technology_bonus(secondary_key, float(template.get("secondary_gain", 1.0)))
		research["status"] = "COMPLETED"
		research["remaining_months"] = 0
		active_research.erase(research)
		completed.append(research)
		CompanyManager.change_reputation({"innovation":0.8,"professional":0.4})
		CompanyManager.add_alert("Recherche dérivée terminée : %s." % str(research.get("title", "Découverte")))
		MediaManager.publish_business_event(
			"%s transforme une découverte en savoir-faire" % CompanyManager.company_name,
			"%s devient une technologie réutilisable dans les futurs projets." % str(research.get("title", "La découverte"))
		)
		derived_research_completed.emit(research.duplicate(true))
	if not finished.is_empty():
		discoveries_changed.emit()

func get_state() -> Dictionary:
	return {
		"pending":pending,
		"active_research":active_research,
		"completed":completed,
		"seen_keys":seen_keys,
		"next_id":_next_id
	}

func load_state(state: Dictionary):
	pending = state.get("pending", []).duplicate(true)
	active_research = state.get("active_research", []).duplicate(true)
	completed = state.get("completed", []).duplicate(true)
	seen_keys = state.get("seen_keys", {}).duplicate(true)
	_next_id = int(state.get("next_id", 1))
	discoveries_changed.emit()
