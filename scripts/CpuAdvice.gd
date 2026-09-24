extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func detail_level() -> int:
	var division := DivisionManager.get_division("CPU")
	var generations := int(division.get("generation_count", 0))
	var field_experience := float(division.get("field_experience", 0.0))
	if generations >= 3 or field_experience >= 65.0:
		return 2
	if generations >= 1 or field_experience >= 30.0:
		return 1
	return 0

static func advice(design_input: Dictionary, evaluation: Dictionary, segment: String) -> Dictionary:
	var design := CPU_DESIGN.normalize(design_input)
	var level := detail_level()
	var frequency := CPU_DESIGN.frequency_mhz(design)
	var risk := float(evaluation.get("risk", 50.0))
	var reliability := float(evaluation.get("reliability", 50.0))
	var efficiency := float(evaluation.get("efficiency", 50.0))
	var performance := float(evaluation.get("performance", 50.0))

	if level <= 0:
		var short := "Le design me paraît équilibré."
		if risk >= 65.0:
			short = "C'est ambitieux. Je garderais davantage de marge."
		elif reliability < 52.0:
			short = "Je renforcerais la fiabilité avant d'aller plus loin."
		elif efficiency < 48.0:
			short = "La consommation me paraît élevée pour notre niveau actuel."
		elif performance < 48.0:
			short = "On peut probablement viser un peu plus de performances."
		return {
			"level":0,
			"speaker":"Camille",
			"text":short,
			"confidence":"faible",
			"detail":"Notre équipe manque encore de recul : le conseil reste volontairement prudent."
		}

	var low := maxf(frequency * 0.90, 0.1)
	var high := frequency * (1.08 if level == 1 else 1.04)
	var faster := design.duplicate(true)
	faster["frequency_ghz"] = float(design.get("frequency_ghz", 0.001)) * 1.10
	var faster_eval := CPU_DESIGN.evaluate(faster, ResearchManager.get_cpu_capabilities())
	var risk_delta := float(faster_eval.get("risk", risk)) - risk
	var perf_delta := float(faster_eval.get("performance", performance)) - performance
	var eff_delta := float(faster_eval.get("efficiency", efficiency)) - efficiency

	if level == 1:
		return {
			"level":1,
			"speaker":"Camille",
			"text":"Je viserais environ %.1f à %.1f MHz pour rester dans une zone que l'équipe connaît mieux." % [low, high],
			"confidence":"moyenne",
			"detail":"Au-delà, le risque semble monter plus vite que le gain attendu."
		}

	return {
		"level":2,
		"speaker":"Camille",
		"text":"Zone maîtrisée estimée : %.1f–%.1f MHz pour cette architecture." % [low, high],
		"confidence":"élevée",
		"detail":"+10%% de fréquence donnerait environ %+0.1f performance, %+0.1f efficacité et %+0.1f risque selon nos données actuelles." % [
			perf_delta,
			eff_delta,
			risk_delta
		]
	}
