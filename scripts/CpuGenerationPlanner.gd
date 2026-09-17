extends RefCounted
class_name CpuGenerationPlannerModel

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

const PLAN_PROFILES := [
	{
		"key":"SAFE", "tag":"PRUDENT", "title":"Révision maîtrisée",
		"duration_factor":0.84, "risk_delta":-12.0, "confidence_delta":10.0,
		"life_base":14.0, "model_base":3,
		"promise":"Capitaliser sur l'existant pour sortir vite une génération fiable."
	},
	{
		"key":"BALANCED", "tag":"ÉQUILIBRÉ", "title":"Nouvelle génération",
		"duration_factor":1.00, "risk_delta":0.0, "confidence_delta":0.0,
		"life_base":20.0, "model_base":4,
		"promise":"Faire progresser la plateforme sans mettre toute l'entreprise en danger."
	},
	{
		"key":"BOLD", "tag":"AUDACIEUX", "title":"Projet Horizon",
		"duration_factor":1.28, "risk_delta":11.0, "confidence_delta":-12.0,
		"life_base":26.0, "model_base":5,
		"promise":"Tenter une rupture capable de porter plusieurs années de produits."
	}
]

static func generate(base_input: Dictionary, context: Dictionary) -> Array:
	var base_design := CPU_DESIGN.normalize(base_input)
	var base_evaluation := CPU_DESIGN.evaluate(base_design)
	var capability := _capability_score(context)
	var generation_index := maxi(int(context.get("generation_index", 1)), 1)
	var proposals: Array = []
	for profile_value in PLAN_PROFILES:
		var profile: Dictionary = profile_value
		var design := _design_for(str(profile.key), base_design, context, capability)
		var evaluation := CPU_DESIGN.evaluate(design)
		proposals.append(_build_proposal(profile, generation_index, design, evaluation, base_evaluation, context, capability))
	_mark_recommendation(proposals, context, capability)
	return proposals

static func normalize_saved_proposal(input: Dictionary) -> Dictionary:
	var proposal := input.duplicate(true)
	var design := CPU_DESIGN.normalize(proposal.get("design", {}))
	proposal["design"] = design
	proposal["evaluation"] = CPU_DESIGN.evaluate(design)
	proposal["risks"] = proposal.get("risks", []).duplicate(true)
	proposal["strengths"] = proposal.get("strengths", []).duplicate(true)
	proposal["potential_models"] = clampi(maxi(int(proposal.get("potential_models", 3)), 3), 3, 6)
	proposal["recommended"] = bool(proposal.get("recommended", false))
	return proposal

static func _capability_score(context: Dictionary) -> float:
	var team := clampf(float(context.get("team_score", 20.0)), 0.0, 100.0)
	var technology := clampf(float(context.get("technology_score", 0.0)), 0.0, 100.0)
	var maturity := clampf(float(context.get("division_maturity", 0.0)), 0.0, 100.0)
	var equipment := clampf(float(context.get("equipment_score", 25.0)), 0.0, 100.0)
	var management_modifier := clampf(float(context.get("management_modifier", 1.0)), 0.65, 1.15)
	var management_score := remap(management_modifier, 0.65, 1.15, 0.0, 100.0)
	return clampf(team * 0.45 + technology * 0.20 + maturity * 0.12 + equipment * 0.13 + management_score * 0.10, 0.0, 100.0)

static func _design_for(archetype: String, base: Dictionary, context: Dictionary, capability: float) -> Dictionary:
	var design := base.duplicate(true)
	match archetype:
		"SAFE":
			design.cores = int(base.cores) + (2 if int(base.cores) < 12 else 0)
			design.frequency_ghz = float(base.frequency_ghz) + 0.1
			design.cache_mb = int(base.cache_mb) + 4
			design.tdp_w = int(base.tdp_w)
		"BOLD":
			design.cores = int(base.cores) + 4 + int(floor(capability / 35.0)) * 2
			design.frequency_ghz = float(base.frequency_ghz) + 0.6
			design.cache_mb = int(base.cache_mb) + 16
			design.node_nm = _next_advanced_node(int(base.node_nm))
			design.tdp_w = int(base.tdp_w) + 30
		_:
			design.cores = int(base.cores) + 4
			design.frequency_ghz = float(base.frequency_ghz) + 0.3
			design.cache_mb = int(base.cache_mb) + 8
			if capability >= 66.0:
				design.node_nm = _next_advanced_node(int(base.node_nm))
			design.tdp_w = int(base.tdp_w) + 10
	_apply_segment(design, str(context.get("segment", "MAINSTREAM")), archetype)
	_apply_focus(design, str(context.get("focus", "BALANCED")), archetype, capability)
	return CPU_DESIGN.normalize(design)

static func _apply_segment(design: Dictionary, segment: String, archetype: String) -> void:
	match segment:
		"BUDGET":
			design.cache_mb = maxi(int(design.cache_mb) - 4, 4)
			design.tdp_w = maxi(int(design.tdp_w) - 10, 35)
		"ENTHUSIAST":
			design.frequency_ghz = float(design.frequency_ghz) + 0.2
			design.tdp_w = int(design.tdp_w) + 10
		"PRO":
			design.cores = int(design.cores) + 2
			design.cache_mb = int(design.cache_mb) + 4
		"ENTERPRISE":
			design.cores = int(design.cores) + 4
			design.cache_mb = int(design.cache_mb) + 8
			design.tdp_w = int(design.tdp_w) + (10 if archetype != "SAFE" else 0)
		"PREMIUM":
			design.frequency_ghz = float(design.frequency_ghz) + 0.1
			design.cache_mb = int(design.cache_mb) + 4

static func _apply_focus(design: Dictionary, focus: String, archetype: String, capability: float) -> void:
	match focus:
		"PERFORMANCE":
			design.cores = int(design.cores) + 2
			design.frequency_ghz = float(design.frequency_ghz) + 0.2
			design.tdp_w = int(design.tdp_w) + 10
		"EFFICIENCY", "SUSTAINABILITY":
			design.frequency_ghz = float(design.frequency_ghz) - 0.1
			design.tdp_w = maxi(int(design.tdp_w) - 15, 35)
		"RELIABILITY":
			design.frequency_ghz = float(design.frequency_ghz) - 0.1
			design.tdp_w = int(design.tdp_w) + 5
		"INNOVATION":
			design.cache_mb = int(design.cache_mb) + 4
			if archetype != "SAFE" and capability >= 56.0:
				design.node_nm = _next_advanced_node(int(design.node_nm))

static func _next_advanced_node(node_nm: int) -> int:
	var nodes := CPU_DESIGN.available_nodes()
	var index := nodes.find(node_nm)
	if index < 0:
		return node_nm
	return int(nodes[mini(index + 1, nodes.size() - 1)])

static func _build_proposal(profile: Dictionary, generation_index: int, design: Dictionary, evaluation: Dictionary, base_evaluation: Dictionary, context: Dictionary, capability: float) -> Dictionary:
	var monthly_budget := maxi(int(context.get("monthly_budget", 42000)), 10000)
	var base_development_cost := maxf(float(context.get("base_development_cost", 42000.0)), 10000.0)
	var budget_ratio := clampf(float(monthly_budget) / base_development_cost, 0.25, 2.2)
	var approach_speed := maxf(float(context.get("approach_speed", 1.0)), 0.25)
	var approach_cost := maxf(float(context.get("approach_cost", 1.0)), 0.25)
	var budget_time_factor := clampf(1.0 - (budget_ratio - 1.0) * 0.22, 0.74, 1.24)
	var estimated_months := maxi(1, int(ceil(float(evaluation.estimated_months) * float(profile.duration_factor) * budget_time_factor / approach_speed)))
	var prototype_cost := int(float(evaluation.unit_cost) * (120.0 + float(evaluation.complexity) * 3.0))
	var program_cost := int(float(estimated_months * monthly_budget) * approach_cost) + prototype_cost

	var capability_gap := maxf(float(evaluation.complexity) - capability, 0.0)
	var risk := float(evaluation.risk) + float(profile.risk_delta) + capability_gap * 0.28
	risk += maxf(1.0 - budget_ratio, 0.0) * 14.0
	risk = clampf(risk, 5.0, 95.0)

	var management_modifier := float(context.get("management_modifier", 1.0))
	var confidence := 45.0 + float(context.get("team_score", 20.0)) * 0.30
	confidence += float(context.get("technology_score", 0.0)) * 0.12
	confidence += float(context.get("division_maturity", 0.0)) * 0.08
	confidence += float(context.get("equipment_score", 25.0)) * 0.08
	confidence += (management_modifier - 0.8) * 25.0
	confidence -= float(evaluation.complexity) * 0.10
	confidence += float(profile.confidence_delta)
	confidence = clampf(confidence, 28.0, 96.0)

	var competitive_months := float(profile.life_base) + float(evaluation.innovation) * 0.10
	competitive_months += float(evaluation.reliability) * 0.06 + float(context.get("technology_score", 0.0)) * 0.10
	competitive_months += capability * 0.04 - risk * 0.04
	competitive_months = clampf(competitive_months, 16.0, 52.0)
	var potential_models := clampi(int(profile.model_base) + int(floor(capability / 40.0)), 3, 6)

	var metric_deltas := {}
	for metric in ["performance", "efficiency", "reliability", "innovation", "sustainability"]:
		metric_deltas[metric] = float(evaluation.get(metric, 0.0)) - float(base_evaluation.get(metric, 0.0))
	var target_fit := CPU_DESIGN.segment_fit(evaluation, str(context.get("segment", "MAINSTREAM")))
	var strengths := _strengths_for(str(profile.key), metric_deltas, target_fit, potential_models)
	var risks := _risks_for(str(profile.key), design, evaluation, context, capability_gap, budget_ratio)

	return {
		"id":"CPU-G%02d-%s" % [generation_index, str(profile.key)],
		"generation_index":generation_index,
		"archetype":str(profile.key),
		"tag":str(profile.tag),
		"title":str(profile.title),
		"promise":str(profile.promise),
		"design":design.duplicate(true),
		"evaluation":evaluation.duplicate(true),
		"metric_deltas":metric_deltas,
		"segment":str(context.get("segment", "MAINSTREAM")),
		"approach":str(context.get("approach", "INTERNAL")),
		"focus":str(context.get("focus", "BALANCED")),
		"monthly_budget":monthly_budget,
		"estimated_months":estimated_months,
		"program_cost":program_cost,
		"competitive_months":int(round(competitive_months)),
		"potential_models":potential_models,
		"risk":risk,
		"confidence":confidence,
		"target_fit":target_fit,
		"capability":capability,
		"team_score":float(context.get("team_score", 20.0)),
		"technology_score":float(context.get("technology_score", 0.0)),
		"equipment_score":float(context.get("equipment_score", 25.0)),
		"division_maturity":float(context.get("division_maturity", 0.0)),
		"strengths":strengths,
		"risks":risks,
		"recommended":false,
		"recommendation":""
	}

static func _strengths_for(archetype: String, deltas: Dictionary, target_fit: float, potential_models: int) -> Array:
	var strengths: Array = []
	match archetype:
		"SAFE": strengths.append("Délai et validation mieux maîtrisés")
		"BOLD": strengths.append("Potentiel de rupture et image technologique")
		_: strengths.append("Bon équilibre entre progrès et risque")
	if float(deltas.get("performance", 0.0)) >= 3.0:
		strengths.append("Gain de performance estimé à +%.0f" % float(deltas.performance))
	elif float(deltas.get("efficiency", 0.0)) >= 3.0:
		strengths.append("Efficacité énergétique en progrès")
	if target_fit >= 72.0:
		strengths.append("Très adapté au client ciblé")
	strengths.append("Jusqu'à %d modèles sur la génération" % potential_models)
	return strengths.slice(0, 3)

static func _risks_for(archetype: String, design: Dictionary, evaluation: Dictionary, context: Dictionary, capability_gap: float, budget_ratio: float) -> Array:
	var risks: Array = []
	if capability_gap >= 8.0:
		risks.append("Charge de validation supérieure aux capacités actuelles")
	if float(evaluation.power_deficit) >= 6.0:
		risks.append("Marge thermique insuffisante")
	if int(design.node_nm) <= 5 and float(context.get("equipment_score", 25.0)) < 62.0:
		risks.append("Procédé avancé avec laboratoire encore limité")
	if budget_ratio < 0.85:
		risks.append("Budget mensuel serré")
	var approach := str(context.get("approach", "INTERNAL"))
	if approach == "INTERNAL" and float(context.get("technology_score", 0.0)) < 25.0:
		risks.append("Savoir-faire interne encore jeune")
	elif approach == "EXTERNAL":
		risks.append("Dépendance forte au partenaire externe")
	elif approach == "HYBRID" and archetype == "BOLD":
		risks.append("Coordination complexe avec le partenaire")
	if risks.is_empty():
		risks.append("Aucun risque critique identifié à ce stade")
	return risks.slice(0, 3)

static func _mark_recommendation(proposals: Array, context: Dictionary, capability: float) -> void:
	var recommended_key := "BALANCED"
	var treasury := int(context.get("treasury", 0))
	var safe: Dictionary = proposals[0]
	var balanced: Dictionary = proposals[1]
	var bold: Dictionary = proposals[2]
	if capability < 44.0 or (treasury > 0 and treasury < int(balanced.program_cost * 0.75)):
		recommended_key = "SAFE"
	else:
		var focus := str(context.get("focus", "BALANCED"))
		var strategy := str(context.get("division_strategy", "BALANCED"))
		var aggressive := focus in ["PERFORMANCE", "INNOVATION"] or strategy in ["PERFORMANCE", "INNOVATION"]
		if aggressive and capability >= 65.0 and (treasury <= 0 or treasury >= int(bold.program_cost * 0.65)):
			recommended_key = "BOLD"
		elif treasury > 0 and treasury < int(safe.program_cost * 0.85):
			recommended_key = "SAFE"
	for proposal_value in proposals:
		var proposal: Dictionary = proposal_value
		proposal.recommended = str(proposal.archetype) == recommended_key
		if bool(proposal.recommended):
			proposal.recommendation = "Camille recommande ce plan au vu de votre équipe, de votre trésorerie et du risque accepté."
		elif str(proposal.archetype) == "SAFE":
			proposal.recommendation = "À choisir si vous privilégiez la trésorerie, la fiabilité et une sortie rapide."
		elif str(proposal.archetype) == "BOLD":
			proposal.recommendation = "À réserver à une entreprise prête à absorber retards, surcoûts et validation lourde."
		else:
			proposal.recommendation = "Le compromis de référence si vous voulez progresser sans pari extrême."
