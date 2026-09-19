extends RefCounted
class_name CpuDesignModel

# Les valeurs restent stockées en nm / GHz / Mo pour conserver la compatibilité
# des sauvegardes, mais l'interface peut les présenter en µm / MHz / Ko.
const NODE_ORDER := [
	10000, 8000, 6000, 3000, 1500, 1000, 800, 600, 350, 250, 180, 130,
	90, 65, 45, 32, 22, 14, 10, 7, 5, 3
]

const NODE_PROFILES := {
	10000: {"label":"10 µm — procédé pionnier", "score":36.0, "power_factor":1.15, "base_cost":24.0, "maturity":8.0, "difficulty":0.65, "reference_mhz":0.8, "core_reference":1.0, "cache_reference_kb":0.0, "base_power":1.30, "unlock":0.0},
	8000: {"label":"8 µm — expérimental", "score":40.0, "power_factor":1.12, "base_cost":27.0, "maturity":5.0, "difficulty":0.70, "reference_mhz":1.2, "core_reference":1.0, "cache_reference_kb":0.0, "base_power":1.45, "unlock":18.0},
	6000: {"label":"6 µm — miniaturisation", "score":45.0, "power_factor":1.08, "base_cost":31.0, "maturity":3.0, "difficulty":0.76, "reference_mhz":2.0, "core_reference":1.0, "cache_reference_kb":0.0, "base_power":1.70, "unlock":28.0},
	3000: {"label":"3 µm — haute densité", "score":51.0, "power_factor":1.04, "base_cost":36.0, "maturity":1.0, "difficulty":0.82, "reference_mhz":5.0, "core_reference":1.0, "cache_reference_kb":0.0, "base_power":2.10, "unlock":38.0},
	1500: {"label":"1,5 µm — avancé", "score":57.0, "power_factor":1.00, "base_cost":41.0, "maturity":0.0, "difficulty":0.88, "reference_mhz":8.0, "core_reference":1.0, "cache_reference_kb":0.0, "base_power":2.80, "unlock":48.0},
	1000: {"label":"1 µm", "score":61.0, "power_factor":0.97, "base_cost":46.0, "maturity":0.0, "difficulty":0.92, "reference_mhz":12.0, "core_reference":1.0, "cache_reference_kb":1.0, "base_power":3.30, "unlock":55.0},
	800: {"label":"0,8 µm", "score":64.0, "power_factor":0.94, "base_cost":50.0, "maturity":0.0, "difficulty":0.96, "reference_mhz":16.0, "core_reference":1.0, "cache_reference_kb":2.0, "base_power":4.00, "unlock":60.0},
	600: {"label":"0,6 µm", "score":67.0, "power_factor":0.91, "base_cost":54.0, "maturity":0.0, "difficulty":1.00, "reference_mhz":25.0, "core_reference":1.0, "cache_reference_kb":8.0, "base_power":5.00, "unlock":65.0},
	350: {"label":"0,35 µm", "score":70.0, "power_factor":0.87, "base_cost":59.0, "maturity":0.0, "difficulty":1.04, "reference_mhz":66.0, "core_reference":1.0, "cache_reference_kb":16.0, "base_power":8.00, "unlock":70.0},
	250: {"label":"0,25 µm", "score":73.0, "power_factor":0.83, "base_cost":64.0, "maturity":0.0, "difficulty":1.08, "reference_mhz":300.0, "core_reference":1.0, "cache_reference_kb":512.0, "base_power":18.0, "unlock":74.0},
	180: {"label":"0,18 µm", "score":76.0, "power_factor":0.80, "base_cost":69.0, "maturity":0.0, "difficulty":1.11, "reference_mhz":1200.0, "core_reference":1.0, "cache_reference_kb":256.0, "base_power":35.0, "unlock":78.0},
	130: {"label":"0,13 µm", "score":79.0, "power_factor":0.77, "base_cost":73.0, "maturity":0.0, "difficulty":1.14, "reference_mhz":1800.0, "core_reference":1.0, "cache_reference_kb":512.0, "base_power":45.0, "unlock":81.0},
	90: {"label":"90 nm", "score":82.0, "power_factor":0.74, "base_cost":77.0, "maturity":0.0, "difficulty":1.17, "reference_mhz":2800.0, "core_reference":2.0, "cache_reference_kb":1024.0, "base_power":65.0, "unlock":84.0},
	65: {"label":"65 nm", "score":84.0, "power_factor":0.71, "base_cost":81.0, "maturity":0.0, "difficulty":1.19, "reference_mhz":3200.0, "core_reference":4.0, "cache_reference_kb":2048.0, "base_power":70.0, "unlock":86.0},
	45: {"label":"45 nm", "score":86.0, "power_factor":0.68, "base_cost":85.0, "maturity":0.0, "difficulty":1.21, "reference_mhz":3400.0, "core_reference":4.0, "cache_reference_kb":4096.0, "base_power":75.0, "unlock":88.0},
	32: {"label":"32 nm", "score":88.0, "power_factor":0.65, "base_cost":89.0, "maturity":0.0, "difficulty":1.23, "reference_mhz":3800.0, "core_reference":6.0, "cache_reference_kb":8192.0, "base_power":80.0, "unlock":90.0},
	22: {"label":"22 nm", "score":90.0, "power_factor":0.62, "base_cost":94.0, "maturity":0.0, "difficulty":1.25, "reference_mhz":4200.0, "core_reference":8.0, "cache_reference_kb":12288.0, "base_power":85.0, "unlock":92.0},
	14: {"label":"14 nm", "score":91.5, "power_factor":0.59, "base_cost":99.0, "maturity":0.0, "difficulty":1.27, "reference_mhz":4600.0, "core_reference":12.0, "cache_reference_kb":16384.0, "base_power":95.0, "unlock":94.0},
	10: {"label":"10 nm", "score":93.0, "power_factor":0.56, "base_cost":104.0, "maturity":0.0, "difficulty":1.29, "reference_mhz":5000.0, "core_reference":16.0, "cache_reference_kb":24576.0, "base_power":105.0, "unlock":95.0},
	7: {"label":"7 nm", "score":94.0, "power_factor":0.53, "base_cost":109.0, "maturity":0.0, "difficulty":1.31, "reference_mhz":5200.0, "core_reference":24.0, "cache_reference_kb":32768.0, "base_power":120.0, "unlock":96.0},
	5: {"label":"5 nm", "score":95.0, "power_factor":0.50, "base_cost":116.0, "maturity":0.0, "difficulty":1.34, "reference_mhz":5600.0, "core_reference":32.0, "cache_reference_kb":65536.0, "base_power":145.0, "unlock":98.0},
	3: {"label":"3 nm", "score":96.0, "power_factor":0.47, "base_cost":124.0, "maturity":0.0, "difficulty":1.38, "reference_mhz":6000.0, "core_reference":48.0, "cache_reference_kb":98304.0, "base_power":170.0, "unlock":100.0}
}

const PRESETS := {
	"EFFICIENT": {"cores":1, "frequency_ghz":0.0005, "cache_mb":0.0, "node_nm":10000, "tdp_w":2},
	"BALANCED": {"cores":1, "frequency_ghz":0.0008, "cache_mb":0.0, "node_nm":10000, "tdp_w":2},
	"PERFORMANCE": {"cores":1, "frequency_ghz":0.0014, "cache_mb":0.0, "node_nm":10000, "tdp_w":4}
}

static func default_design() -> Dictionary:
	return PRESETS.BALANCED.duplicate(true)

static func preset(key: String) -> Dictionary:
	return normalize(PRESETS.get(key, PRESETS.BALANCED))

static func available_nodes() -> Array:
	return NODE_ORDER.duplicate()

static func available_nodes_for_mastery(manufacturing_mastery: float) -> Array:
	return available_nodes_for_capabilities(manufacturing_mastery, manufacturing_mastery)

static func available_nodes_for_capabilities(manufacturing_mastery: float, miniaturization_knowledge: float) -> Array:
	var effective_mastery := minf(manufacturing_mastery, miniaturization_knowledge)
	var result: Array = []
	for node_value in NODE_ORDER:
		var node_nm := int(node_value)
		var profile: Dictionary = NODE_PROFILES[node_nm]
		if effective_mastery + 0.001 >= float(profile.get("unlock", 0.0)):
			result.append(node_nm)
	if result.is_empty():
		result.append(10000)
	return result

static func node_profile(node_nm: int) -> Dictionary:
	return NODE_PROFILES.get(node_nm, NODE_PROFILES[10000]).duplicate(true)

static func node_label(node_nm: int) -> String:
	return str(NODE_PROFILES.get(node_nm, NODE_PROFILES[10000]).label)

static func frequency_mhz(input: Dictionary) -> float:
	var design := normalize(input)
	return float(design.frequency_ghz) * 1000.0

static func cache_kb(input: Dictionary) -> float:
	var design := normalize(input)
	return float(design.cache_mb) * 1024.0

static func format_frequency(input: Dictionary) -> String:
	var mhz := frequency_mhz(input)
	if mhz < 1000.0:
		if mhz < 10.0:
			return "%.1f MHz" % mhz
		return "%.0f MHz" % mhz
	return "%.2f GHz" % (mhz / 1000.0)

static func format_cache(input: Dictionary) -> String:
	var kb := cache_kb(input)
	if kb < 0.5:
		return "sans cache"
	if kb < 1024.0:
		return "%d Ko" % int(round(kb))
	return "%.1f Mo" % (kb / 1024.0)

static func normalize(input: Dictionary) -> Dictionary:
	var design := default_design()
	for key in input.keys():
		design[key] = input[key]
	var cores := clampi(int(round(float(design.get("cores", 1)))), 1, 64)
	var frequency := clampf(float(design.get("frequency_ghz", 0.0008)), 0.0001, 8.0)
	if frequency < 0.01:
		frequency = snappedf(frequency, 0.0001)
	elif frequency < 0.1:
		frequency = snappedf(frequency, 0.001)
	elif frequency < 1.0:
		frequency = snappedf(frequency, 0.01)
	else:
		frequency = snappedf(frequency, 0.1)
	var cache := clampf(float(design.get("cache_mb", 0.0)), 0.0, 256.0)
	cache = snappedf(cache, 1.0 / 1024.0)
	var requested_node := int(design.get("node_nm", 10000))
	var closest_node := 10000
	var closest_distance := 1000000
	for available_node in NODE_ORDER:
		var distance := absi(int(available_node) - requested_node)
		if distance < closest_distance:
			closest_distance = distance
			closest_node = int(available_node)
	var tdp := clampi(int(round(float(design.get("tdp_w", 2)))), 1, 400)
	return {
		"cores": cores,
		"frequency_ghz": frequency,
		"cache_mb": cache,
		"node_nm": closest_node,
		"tdp_w": tdp
	}

static func evaluate(input: Dictionary, capabilities: Dictionary = {}) -> Dictionary:
	var design := normalize(input)
	var cores := int(design.cores)
	var frequency_ghz := float(design.frequency_ghz)
	var frequency_mhz_value := frequency_ghz * 1000.0
	var cache_mb_value := float(design.cache_mb)
	var cache_kb_value := cache_mb_value * 1024.0
	var node_nm := int(design.node_nm)
	var tdp := int(design.tdp_w)
	var node: Dictionary = NODE_PROFILES[node_nm]
	var architecture_skill := float(capabilities.get("ARCHITECTURE", 18.0))
	var layout_skill := float(capabilities.get("LAYOUT", 14.0))
	var architecture_delta := architecture_skill - 18.0
	var layout_delta := layout_skill - 14.0

	var reference_mhz := maxf(float(node.reference_mhz), 0.1)
	var reference_cores := maxf(float(node.core_reference), 1.0)
	var reference_cache_kb := maxf(float(node.cache_reference_kb), 0.0)
	var frequency_ratio := maxf(frequency_mhz_value / reference_mhz, 0.05)
	var core_ratio := maxf(float(cores) / reference_cores, 0.10)
	var cache_ratio := 1.0
	if reference_cache_kb > 0.0:
		cache_ratio = maxf((cache_kb_value + 1.0) / (reference_cache_kb + 1.0), 0.05)
	elif cache_kb_value > 0.0:
		cache_ratio = 1.0 + log(cache_kb_value + 1.0) / log(2.0) * 0.22

	var core_score := clampf(60.0 + log(core_ratio) / log(2.0) * 18.0, 20.0, 98.0)
	var frequency_score := clampf(60.0 + log(frequency_ratio) / log(2.0) * 18.0, 20.0, 98.0)
	var cache_score := 56.0
	if reference_cache_kb > 0.0:
		cache_score = clampf(60.0 + log(cache_ratio) / log(2.0) * 9.0, 25.0, 98.0)
	elif cache_kb_value > 0.0:
		cache_score = clampf(58.0 + log(cache_kb_value + 1.0) / log(2.0) * 4.0, 25.0, 94.0)

	var required_tdp := float(node.base_power) * (
		0.50
		+ core_ratio * 0.30
		+ pow(frequency_ratio, 1.35) * 0.45
		+ minf(maxf(cache_ratio - 1.0, 0.0), 4.0) * 0.07
	) * float(node.power_factor)
	required_tdp *= clampf(1.0 - layout_delta * 0.0022, 0.82, 1.08)
	required_tdp = maxf(required_tdp, 0.5)
	var power_deficit := maxf(required_tdp - float(tdp), 0.0)
	var power_deficit_ratio := power_deficit / required_tdp
	var frequency_pressure := maxf(frequency_ratio - 1.0, 0.0)
	var core_pressure := maxf(core_ratio - 1.0, 0.0)
	var cache_pressure := maxf(cache_ratio - 1.0, 0.0)

	var performance := 18.0 + core_score * 0.38 + frequency_score * 0.42 + cache_score * 0.08 + float(node.score) * 0.12
	performance += architecture_delta * 0.075
	performance -= power_deficit_ratio * 20.0
	var efficiency := 79.0 - frequency_pressure * 12.0 - core_pressure * 8.0 - cache_pressure * 2.5
	efficiency += (1.0 - float(node.power_factor)) * 18.0
	efficiency -= power_deficit_ratio * 18.0
	var reliability := 82.0 + float(node.maturity) - frequency_pressure * 17.0 - core_pressure * 9.0
	reliability += layout_delta * 0.065
	reliability -= cache_pressure * 3.0 + power_deficit_ratio * 24.0
	var innovation := 24.0 + float(node.score) * 0.34 + core_score * 0.15 + frequency_score * 0.16 + cache_score * 0.08
	var sustainability := efficiency * 0.70 + reliability * 0.20 + (100.0 - float(node.score)) * 0.10

	performance = clampf(performance, 20.0, 98.0)
	efficiency = clampf(efficiency, 18.0, 98.0)
	reliability = clampf(reliability, 18.0, 98.0)
	innovation = clampf(innovation, 20.0, 98.0)
	sustainability = clampf(sustainability, 20.0, 96.0)

	var cache_cost := log(cache_kb_value + 1.0) / log(2.0) * 1.8
	var frequency_cost := maxf(frequency_ratio - 0.55, 0.0) * 7.0
	var core_cost := maxf(float(cores) - reference_cores * 0.75, 0.0) * 4.2
	var raw_cost := float(node.base_cost) + core_cost + cache_cost + frequency_cost + float(tdp) * 0.65
	var unit_cost := int(round(raw_cost * (1.0 + (100.0 - reliability) * 0.0025)))

	var cache_novelty := 0.0
	if reference_cache_kb <= 0.0 and cache_kb_value > 0.0:
		cache_novelty = log(cache_kb_value + 1.0) / log(2.0) * 2.2
	var complexity := 16.0 + float(node.difficulty) * 18.0
	complexity += maxf(frequency_ratio - 0.80, 0.0) * 13.0
	complexity += core_pressure * 12.0 + cache_pressure * 4.0 + cache_novelty
	complexity -= maxf(layout_delta, 0.0) * 0.10 + maxf(architecture_delta, 0.0) * 0.045
	complexity = clampf(complexity, 10.0, 100.0)
	var risk := clampf((100.0 - reliability) * 0.55 + complexity * 0.45, 5.0, 94.0)
	var estimated_months := int(round(4.0 + complexity * 0.085))
	var recommended_price := int(round(float(unit_cost) * 2.35 / 5.0) * 5.0)

	var profile := "CPU équilibré"
	if performance >= 84.0:
		profile = "Projet très performant"
	elif efficiency >= 84.0:
		profile = "Architecture économe"
	elif reliability >= 91.0:
		profile = "Conception très robuste"
	elif unit_cost <= 45:
		profile = "Conception économique"

	var tradeoff := "Architecture cohérente avec les moyens techniques actuels."
	if power_deficit_ratio >= 0.18:
		tradeoff = "L'enveloppe électrique bride la puce : augmentez-la ou réduisez la fréquence et la complexité."
	elif reliability < 62.0:
		tradeoff = "Architecture risquée : validation, rendement et retours terrain pourraient souffrir."
	elif frequency_ratio >= 1.55:
		tradeoff = "La fréquence dépasse nettement la référence du procédé : davantage de validation et de marge électrique seront nécessaires."
	elif core_ratio >= 1.75:
		tradeoff = "Le nombre de cœurs dépasse fortement ce que cette génération de procédé maîtrise normalement."
	elif cache_kb_value > 0.0 and reference_cache_kb <= 0.0:
		tradeoff = "Le cache intégré est encore expérimental pour ce niveau technologique et augmente fortement la complexité."

	return {
		"performance": performance,
		"efficiency": efficiency,
		"reliability": reliability,
		"innovation": innovation,
		"sustainability": sustainability,
		"required_tdp": required_tdp,
		"power_deficit": power_deficit,
		"power_deficit_ratio": power_deficit_ratio,
		"unit_cost": unit_cost,
		"complexity": complexity,
		"risk": risk,
		"estimated_months": estimated_months,
		"recommended_price": recommended_price,
		"profile": profile,
		"tradeoff": tradeoff,
		"frequency_mhz": frequency_mhz_value,
		"cache_kb": cache_kb_value,
		"frequency_ratio": frequency_ratio,
		"core_ratio": core_ratio,
		"architecture_skill": architecture_skill,
		"layout_skill": layout_skill
	}

static func guidance_ranges(reference_input: Dictionary, confidence: float) -> Dictionary:
	var reference := normalize(reference_input)
	var confidence_clamped := clampf(confidence, 28.0, 96.0)
	var uncertainty_scale := remap(confidence_clamped, 28.0, 96.0, 1.35, 0.85)
	var reference_frequency := maxf(float(reference.frequency_ghz), 0.0001)
	var reference_cache := maxf(float(reference.cache_mb), 0.0)
	var reference_tdp := maxf(float(reference.tdp_w), 1.0)
	return {
		"cores": _guidance_range(float(reference.cores), 0.0, maxf(1.0, float(reference.cores)), 1.0, 1.0, maxf(8.0, float(reference.cores) + 6.0)),
		"frequency_ghz": _guidance_range(
			reference_frequency,
			reference_frequency * 0.18 * uncertainty_scale,
			reference_frequency * 0.35,
			0.0001,
			maxf(0.0001, reference_frequency * 0.20),
			minf(8.0, maxf(reference_frequency * 2.8, 0.005))
		),
		"cache_mb": _guidance_range(
			reference_cache,
			0.0 if reference_cache <= 0.0 else reference_cache * 0.22 * uncertainty_scale,
			(4.0 / 1024.0) if reference_cache <= 0.0 else maxf(reference_cache * 0.45, 4.0 / 1024.0),
			1.0 / 1024.0,
			0.0,
			maxf(reference_cache * 3.0, 32.0 / 1024.0)
		),
		"tdp_w": _guidance_range(
			reference_tdp,
			maxf(1.0, reference_tdp * 0.20 * uncertainty_scale),
			maxf(2.0, reference_tdp * 0.55),
			1.0,
			1.0,
			minf(400.0, maxf(reference_tdp * 4.0, 25.0))
		)
	}

static func guidance_report(input: Dictionary, reference_input: Dictionary, confidence: float, capabilities: Dictionary = {}) -> Dictionary:
	var design := normalize(input)
	var reference := normalize(reference_input)
	var ranges := guidance_ranges(reference, confidence)
	var states := {}
	var worst_rank := 0
	var strongest_deviation := ""
	var strongest_ratio := 0.0
	for key in ["cores", "frequency_ghz", "cache_mb", "tdp_w"]:
		var zone: Dictionary = ranges[key]
		var current := float(design.get(key, 0.0))
		var state := _guidance_state(current, zone)
		states[key] = state
		var rank := 0
		if state == "AMBITIOUS":
			rank = 1
		elif state == "OUTSIDE":
			rank = 2
		worst_rank = maxi(worst_rank, rank)
		var center := (float(zone.recommended_min) + float(zone.recommended_max)) * 0.5
		var green_half := maxf((float(zone.recommended_max) - float(zone.recommended_min)) * 0.5, 0.0001)
		var ratio := absf(current - center) / green_half
		if ratio > strongest_ratio:
			strongest_ratio = ratio
			strongest_deviation = key

	var node_changed := int(design.node_nm) != int(reference.node_nm)
	if node_changed:
		worst_rank = maxi(worst_rank, 1)

	var overall := "RECOMMENDED"
	var summary := "L'équipe valide cette configuration : elle reste dans la zone que nous savons actuellement bien maîtriser."
	if worst_rank == 1:
		overall = "AMBITIOUS"
		summary = "L'équipe juge cette configuration ambitieuse : elle reste crédible, mais demande davantage de validation."
	elif worst_rank >= 2:
		overall = "OUTSIDE"
		summary = "L'équipe ne valide pas encore totalement cette configuration : au moins un réglage sort de notre zone de maîtrise actuelle."

	var consequences: Array[String] = []
	if strongest_deviation == "frequency_ghz":
		if float(design.frequency_ghz) > float(reference.frequency_ghz):
			consequences.append("La fréquence vise plus de performance, mais augmente la difficulté électrique, la chaleur et la charge de validation.")
		else:
			consequences.append("La fréquence plus basse réduit la pression électrique et thermique, au prix d'une partie des performances.")
	elif strongest_deviation == "tdp_w":
		if int(design.tdp_w) > int(reference.tdp_w):
			consequences.append("Une enveloppe électrique supérieure donne plus de marge au CPU, mais demande alimentation, boîtier et refroidissement adaptés.")
		else:
			consequences.append("Une enveloppe électrique inférieure simplifie le refroidissement, mais peut brider les objectifs de fréquence ou de complexité.")
	elif strongest_deviation == "cores":
		if int(design.cores) > int(reference.cores):
			consequences.append("Davantage de cœurs augmentent le potentiel de calcul parallèle, mais aussi surface, consommation, routage et validation.")
		else:
			consequences.append("Moins de cœurs simplifient la puce et son coût, mais réduisent son potentiel parallèle.")
	elif strongest_deviation == "cache_mb":
		if float(design.cache_mb) > float(reference.cache_mb):
			consequences.append("Ajouter du cache peut réduire certains accès mémoire, mais agrandit le circuit et complique fortement le layout aux débuts de l'industrie.")
		else:
			consequences.append("Réduire le cache économise de la surface, avec un risque de pénaliser certains usages.")

	if node_changed:
		if int(design.node_nm) < int(reference.node_nm):
			consequences.append("Le procédé choisi est plus fin que la référence : potentiel supérieur, mais industrialisation et rendement plus incertains.")
		else:
			consequences.append("Le procédé choisi est plus conservateur : il peut être plus facile à maîtriser mais limite la densité.")

	var evaluation := evaluate(design, capabilities)
	if float(evaluation.power_deficit_ratio) >= 0.08:
		consequences.append("Notre modèle estime que l'enveloppe électrique est insuffisante d'environ %.1f W pour exploiter pleinement ce design." % float(evaluation.power_deficit))

	var confidence_text := "Confiance limitée"
	if confidence >= 80.0:
		confidence_text = "Confiance élevée"
	elif confidence >= 60.0:
		confidence_text = "Confiance correcte"

	return {
		"overall": overall,
		"summary": summary,
		"details": " ".join(consequences.slice(0, 2)),
		"confidence": clampf(confidence, 0.0, 100.0),
		"confidence_text": confidence_text,
		"ranges": ranges,
		"states": states
	}

static func guidance_state(value: float, zone: Dictionary) -> String:
	return _guidance_state(value, zone)

static func guidance_parameter_label(key: String) -> String:
	match key:
		"cores":
			return "cœurs"
		"frequency_ghz":
			return "fréquence"
		"cache_mb":
			return "cache"
		"tdp_w":
			return "enveloppe électrique"
		_:
			return key

static func _guidance_range(center: float, recommended_half: float, ambitious_extra: float, step: float, minimum: float, maximum: float) -> Dictionary:
	var recommended_min := clampf(snappedf(center - recommended_half, step), minimum, maximum)
	var recommended_max := clampf(snappedf(center + recommended_half, step), minimum, maximum)
	if recommended_max < recommended_min:
		var swap := recommended_min
		recommended_min = recommended_max
		recommended_max = swap
	var ambitious_min := clampf(snappedf(recommended_min - ambitious_extra, step), minimum, maximum)
	var ambitious_max := clampf(snappedf(recommended_max + ambitious_extra, step), minimum, maximum)
	return {
		"min": minimum,
		"max": maximum,
		"ambitious_min": ambitious_min,
		"recommended_min": recommended_min,
		"recommended_max": recommended_max,
		"ambitious_max": ambitious_max
	}

static func _guidance_state(value: float, zone: Dictionary) -> String:
	if value >= float(zone.recommended_min) and value <= float(zone.recommended_max):
		return "RECOMMENDED"
	if value >= float(zone.ambitious_min) and value <= float(zone.ambitious_max):
		return "AMBITIOUS"
	return "OUTSIDE"

static func decision_axes(evaluation: Dictionary, effective_months: int = -1) -> Dictionary:
	var unit_cost := float(evaluation.get("unit_cost", 120.0))
	var risk := float(evaluation.get("risk", 50.0))
	var months := effective_months
	if months < 0:
		months = int(evaluation.get("estimated_months", 8))
	var cost_control := clampf(100.0 - maxf(unit_cost - 35.0, 0.0) * 0.48, 10.0, 100.0)
	var time_score := clampf(105.0 - maxf(float(months) - 5.0, 0.0) * 9.5, 10.0, 100.0)
	var delivery_confidence := clampf(time_score * 0.58 + (100.0 - risk) * 0.42, 5.0, 100.0)
	return {
		"performance": float(evaluation.get("performance", 50.0)),
		"efficiency": float(evaluation.get("efficiency", 50.0)),
		"cost_control": cost_control,
		"reliability": float(evaluation.get("reliability", 50.0)),
		"delivery": delivery_confidence
	}

static func decision_axis_delta(current_axes: Dictionary, reference_axes: Dictionary) -> Dictionary:
	var result := {}
	for key in ["performance", "efficiency", "cost_control", "reliability", "delivery"]:
		result[key] = float(current_axes.get(key, 0.0)) - float(reference_axes.get(key, 0.0))
	return result

static func decision_delta_summary(delta: Dictionary) -> String:
	var changed: Array[String] = []
	for key in ["performance", "efficiency", "cost_control", "reliability", "delivery"]:
		var value := float(delta.get(key, 0.0))
		if absf(value) < 0.5:
			continue
		var sign := "+" if value > 0.0 else ""
		changed.append("%s %s%.0f" % [decision_axis_label(key), sign, value])
	if changed.is_empty():
		return "Aucun écart par rapport à la référence."
	return "Écart vs référence : " + " • ".join(changed)

static func decision_axis_label(key: String) -> String:
	match key:
		"performance":
			return "Performance"
		"efficiency":
			return "Efficacité / thermique"
		"cost_control":
			return "Maîtrise du coût"
		"reliability":
			return "Fiabilité"
		"delivery":
			return "Délai / risque"
		_:
			return key.capitalize()

static func decision_summary(axes: Dictionary) -> String:
	var strongest := ""
	var weakest := ""
	var strongest_score := -1.0
	var weakest_score := 101.0
	for key in ["performance", "efficiency", "cost_control", "reliability", "delivery"]:
		var score := float(axes.get(key, 0.0))
		if score > strongest_score:
			strongest_score = score
			strongest = key
		if score < weakest_score:
			weakest_score = score
			weakest = key
	return "Point fort : %s (%.0f/100) • compromis principal : %s (%.0f/100)" % [
		decision_axis_label(strongest), strongest_score,
		decision_axis_label(weakest), weakest_score
	]

static func segment_fit(evaluation: Dictionary, segment: String) -> float:
	var performance := float(evaluation.get("performance", 50.0))
	var efficiency := float(evaluation.get("efficiency", 50.0))
	var reliability := float(evaluation.get("reliability", 50.0))
	var innovation := float(evaluation.get("innovation", 50.0))
	var unit_cost := float(evaluation.get("unit_cost", 120.0))
	var value_score := clampf((220.0 - unit_cost) / 1.60, 0.0, 100.0)
	var fit := 0.0
	match segment:
		"BUDGET":
			fit = performance * 0.12 + efficiency * 0.13 + reliability * 0.20 + innovation * 0.05 + value_score * 0.50
		"ENTHUSIAST":
			fit = performance * 0.55 + efficiency * 0.08 + reliability * 0.12 + innovation * 0.20 + value_score * 0.05
		"PRO":
			fit = performance * 0.36 + efficiency * 0.12 + reliability * 0.30 + innovation * 0.12 + value_score * 0.10
		"ENTERPRISE":
			fit = performance * 0.18 + efficiency * 0.27 + reliability * 0.40 + innovation * 0.08 + value_score * 0.07
		"PREMIUM":
			fit = performance * 0.28 + efficiency * 0.10 + reliability * 0.18 + innovation * 0.34 + value_score * 0.10
		_:
			fit = performance * 0.24 + efficiency * 0.18 + reliability * 0.24 + innovation * 0.14 + value_score * 0.20
	return clampf(fit, 0.0, 100.0)
