extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func _focus_domain(focus: String) -> String:
	var domain := ResearchManager.research_domain_for_focus(focus)
	return domain if domain != "" else "ARCHITECTURE"

static func context(focus: String) -> Dictionary:
	var division := DivisionManager.get_division("CPU")
	var generations := int(division.get("generation_count", 0))
	var development_confidence := ResearchManager.development_confidence()
	var research_confidence := ResearchManager.research_confidence_for_focus(focus)
	var field_experience := ResearchManager.field_experience_for_focus(focus)
	var capabilities := ResearchManager.get_cpu_capabilities()
	var capability_total := 0.0
	var capability_count := 0
	for value in capabilities.values():
		capability_total += float(value)
		capability_count += 1
	var capability_average := capability_total / maxf(float(capability_count), 1.0)
	var practical_mastery := clampf(float(generations) * 12.0 + field_experience * 0.45 + development_confidence * 0.20, 0.0, 100.0)
	var theoretical_mastery := clampf(research_confidence * 0.55 + capability_average * 0.45, 0.0, 100.0)

	var level := 0
	if generations >= 1:
		level = 1
	if generations >= 2 and practical_mastery >= 48.0 and theoretical_mastery >= 42.0:
		level = 2
	if generations >= 3 and practical_mastery >= 66.0 and theoretical_mastery >= 58.0:
		level = 3

	return {
		"level":level,
		"generations":generations,
		"development_confidence":development_confidence,
		"research_confidence":research_confidence,
		"field_experience":field_experience,
		"capability_average":capability_average,
		"practical_mastery":practical_mastery,
		"theoretical_mastery":theoretical_mastery,
		"domain":_focus_domain(focus)
	}

static func detail_level(focus: String = "BALANCED") -> int:
	return int(context(focus).get("level", 0))

static func _mastery_label(value: float) -> String:
	if value >= 72.0:
		return "maîtrisée"
	if value >= 52.0:
		return "solide"
	if value >= 34.0:
		return "en développement"
	return "encore limitée"

static func knowledge_summary(focus: String) -> String:
	var ctx := context(focus)
	var domain := str(ctx.get("domain", "ARCHITECTURE"))
	var domain_data := ResearchManager.get_cpu_research_domain(domain)
	var knowledge := float(domain_data.get("knowledge", 0.0))
	var experience := float(domain_data.get("experience", 0.0))
	return "Savoir théorique %s • expérience pratique %s • expérience terrain %s" % [
		_mastery_label(knowledge),
		_mastery_label(float(ctx.get("practical_mastery", 0.0))),
		_mastery_label(float(ctx.get("field_experience", 0.0)) + experience * 4.0)
	]

static func next_generation_path(focus: String) -> String:
	var active := ResearchManager.get_active_cpu_concept_programs()
	if not active.is_empty():
		var program: Dictionary = active[0]
		var axis := str(program.get("axis", "ARCHITECTURE"))
		return "Piste R&D en cours : %s. Elle pourra nourrir une génération future si les essais confirment son intérêt." % ResearchManager.get_cpu_concept_axis_label(axis)

	var domain := _focus_domain(focus)
	var domain_data := ResearchManager.get_cpu_research_domain(domain)
	var knowledge := float(domain_data.get("knowledge", 0.0))
	if knowledge >= 40.0:
		return "La R&D possède assez de base pour approfondir %s sur la prochaine génération." % ResearchManager.get_cpu_research_label(domain)
	return "Pour la prochaine génération, les retours de ce CPU aideront la R&D à choisir une piste crédible plutôt qu'un déblocage arbitraire."

static func advice(design_input: Dictionary, evaluation: Dictionary, focus: String) -> Dictionary:
	var design := CPU_DESIGN.normalize(design_input)
	var ctx := context(focus)
	var level := int(ctx.get("level", 0))
	var frequency := CPU_DESIGN.frequency_mhz(design)
	var risk := float(evaluation.get("risk", 50.0))
	var reliability := float(evaluation.get("reliability", 50.0))
	var efficiency := float(evaluation.get("efficiency", 50.0))
	var performance := float(evaluation.get("performance", 50.0))

	if level <= 0:
		var short := "Le design paraît raisonnable, mais nous manquons encore de recul."
		if risk >= 65.0:
			short = "C'est ambitieux pour une première génération. Je garderais davantage de marge."
		elif reliability < 52.0:
			short = "Je renforcerais la stabilité avant de pousser plus loin."
		elif efficiency < 48.0:
			short = "La consommation semble élevée, mais notre estimation reste encore large."
		elif performance < 48.0:
			short = "Nous pouvons probablement viser un peu plus haut, sans certitude fine."
		return {
			"level":0,
			"speaker":"Équipe CPU",
			"text":short,
			"confidence":"faible",
			"detail":"Premier produit : l'équipe connaît la théorie, pas encore les limites réelles de notre architecture.",
			"path":next_generation_path(focus)
		}

	var low := maxf(frequency * (0.88 if level == 1 else 0.92), 0.1)
	var high := frequency * (1.10 if level == 1 else (1.06 if level == 2 else 1.04))
	var faster := design.duplicate(true)
	faster["frequency_ghz"] = float(design.get("frequency_ghz", 0.001)) * 1.10
	var faster_eval := CPU_DESIGN.evaluate(faster, ResearchManager.get_cpu_capabilities())
	var risk_delta := float(faster_eval.get("risk", risk)) - risk
	var perf_delta := float(faster_eval.get("performance", performance)) - performance
	var eff_delta := float(faster_eval.get("efficiency", efficiency)) - efficiency

	if level == 1:
		return {
			"level":1,
			"speaker":"Équipe CPU",
			"text":"Nos premiers retours placent une zone raisonnable autour de %.1f à %.1f MHz." % [low, high],
			"confidence":"moyenne",
			"detail":"La fourchette reste large : une génération précédente ne suffit pas encore à isoler toutes les causes.",
			"path":next_generation_path(focus)
		}
	if level == 2:
		return {
			"level":2,
			"speaker":"Équipe CPU",
			"text":"La zone maîtrisée se resserre autour de %.1f–%.1f MHz pour ce type de design." % [low, high],
			"confidence":"bonne",
			"detail":"L'expérience des générations précédentes permet maintenant de distinguer plus clairement risque, rendement et stabilité.",
			"path":next_generation_path(focus)
		}

	return {
		"level":3,
		"speaker":"Équipe CPU",
		"text":"Zone maîtrisée estimée : %.1f–%.1f MHz. Nous savons maintenant quantifier les compromis avec beaucoup plus de confiance." % [low, high],
		"confidence":"élevée",
		"detail":"+10%% de fréquence donnerait environ %+0.1f performance, %+0.1f efficacité et %+0.1f risque avec nos connaissances actuelles." % [
			perf_delta,
			eff_delta,
			risk_delta
		],
		"path":next_generation_path(focus)
	}
