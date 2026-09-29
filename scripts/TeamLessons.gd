extends RefCounted
## Lot E1 (29/09) — « l'équipe te parle ».
## Question d'Alexandre : « l'équipe de développement voit-elle les problèmes d'un CPU ? ».
## La simulation apprenait déjà (SAV, retours marché, presse) mais ne le disait qu'au formulaire expert.
## Ici, trois voix : ce que l'équipe a appris (parcours Nouveau CPU), ses conseils sur les CPU en vente
## (stepping, firmware) et ce que disent les clients, par type de client.

const AXES := {"performance":"Vitesse", "efficiency":"Énergie", "reliability":"Fiabilité"}
const AXIS_PROFILE := {"performance":"PERF", "efficiency":"LOWPOWER", "reliability":"ROBUST"}

# --- 1. Ce que l'équipe a appris (génération précédente) --------------------------------

## Génération de référence : la dernière sur ce marché, sinon la dernière tout court.
static func reference_generation(segment: String) -> Dictionary:
	var fallback: Dictionary = {}
	for i in range(ProductManager.cpu_generations.size() - 1, -1, -1):
		var generation: Dictionary = ProductManager.cpu_generations[i]
		if fallback.is_empty():
			fallback = generation
		for product in generation_products(str(generation.get("id", ""))):
			if MarketManager.normalize_segment(str((product as Dictionary).get("target_segment", ""))) == MarketManager.normalize_segment(segment):
				return generation
	return fallback

static func generation_products(generation_id: String) -> Array:
	return ProductManager.products.filter(func(p): return str(p.get("generation_id", "")) == generation_id)

static func _main_product(generation_id: String) -> Dictionary:
	var best: Dictionary = {}
	for product_value in generation_products(generation_id):
		var product: Dictionary = product_value
		if best.is_empty() or int(product.get("units_sold_total", 0)) > int(best.get("units_sold_total", 0)):
			best = product
	return best

## {has_data, generation_name, lines[], suggested_profile, suggestion}
static func lessons(segment: String) -> Dictionary:
	var generation := reference_generation(segment)
	if generation.is_empty():
		return {"has_data":false}
	var gid := str(generation.get("id", ""))
	var product := _main_product(gid)
	var lines: Array[String] = []
	var weak_axis := ""
	# SAV : les pannes remontées par le terrain.
	for case_value in AfterSalesManager.cases:
		var case_data: Dictionary = case_value
		if str(case_data.get("generation_id", "")) != gid:
			continue
		match str(case_data.get("issue_type", "")):
			"THERMAL":
				lines.append("SAV : des %s chauffent trop chez les clients. Il faut plus de marge thermique." % str(generation.get("name", "CPU")))
				weak_axis = "efficiency"
			"MANUFACTURING":
				lines.append("SAV : trop de puces défectueuses à la sortie d'usine. Le rendement doit progresser.")
				weak_axis = "reliability"
			"FIRMWARE":
				lines.append("SAV : des plantages liés au microcode. Il faut plus de validation logicielle.")
				weak_axis = "reliability"
			_:
				lines.append("SAV : des instabilités sous charge. La fiabilité doit être la priorité.")
				weak_axis = "reliability"
		break
	# Marché : le verdict du premier mois de vente.
	var feedback: Dictionary = product.get("last_market_feedback", {}) if not product.is_empty() else {}
	if not feedback.is_empty():
		var verdict := str(feedback.get("verdict", ""))
		var lesson := str(feedback.get("lesson", ""))
		if verdict != "" or lesson != "":
			lines.append("Marché : %s%s" % [verdict, (". " + lesson) if lesson != "" else ""])
	# Presse : la comparaison au meilleur rival.
	if not product.is_empty():
		var comparison := MarketManager.press_comparison(product)
		if bool(comparison.get("has_rival", false)):
			var delta := float(comparison.get("rival_delta", 0.0))
			if delta <= -2.5:
				lines.append("Presse : %s gardait %.0f points d'avance au banc d'essai." % [str(comparison.get("rival_name", "le meilleur rival")), absf(delta)])
			elif delta >= 2.5:
				lines.append("Presse : nous étions devant %s de %.0f points. À confirmer !" % [str(comparison.get("rival_name", "le meilleur rival")), delta])
	# Axe le plus faible face aux rivaux de ce marché.
	if not product.is_empty():
		var rival := rival_metrics(MarketManager.normalize_segment(str(product.get("target_segment", segment))))
		var metrics: Dictionary = product.get("metrics", {})
		var worst := 999.0
		var worst_axis := ""
		for axis in AXES.keys():
			var gap := float(metrics.get(axis, 50.0)) - float(rival.get(axis, 50.0))
			if gap < worst:
				worst = gap
				worst_axis = str(axis)
		if worst_axis != "" and worst < -3.0:
			lines.append("Équipe : notre point faible face aux rivaux, c'est l'axe %s (%.0f points de retard)." % [str(AXES[worst_axis]), absf(worst)])
			if weak_axis == "":
				weak_axis = worst_axis
	# Architecture fatiguée (voir usure, lot E4).
	var arch_id := str(generation.get("architecture", {}).get("id", "")) if typeof(generation.get("architecture", {})) == TYPE_DICTIONARY else ""
	if arch_id != "" and ArchitectureManager.has_method("wear_of") and float(ArchitectureManager.call("wear_of", arch_id)) >= 0.5:
		lines.append("Équipe : l'architecture %s arrive au bout de ce qu'elle peut donner. Pensez à la suivante." % arch_id)
	var suggested := str(AXIS_PROFILE.get(weak_axis, ""))
	return {"has_data":not lines.is_empty(), "generation_name":str(generation.get("name", "CPU")), "lines":lines,
		"suggested_profile":suggested,
		"suggestion":"Corriger l'axe %s sur la prochaine génération." % str(AXES.get(weak_axis, "")) if weak_axis != "" else ""}

## Moyenne des métriques des CPU rivaux sur un marché (à défaut : tous les rivaux).
static func rival_metrics(segment: String) -> Dictionary:
	var total := {"performance":0.0, "efficiency":0.0, "reliability":0.0}
	var count := 0
	var fallback_total := total.duplicate()
	var fallback_count := 0
	for comp_value in MarketManager.competitors.get("CPU", []):
		var comp: Dictionary = comp_value
		var metrics: Dictionary = comp.get("metrics", {})
		if metrics.is_empty():
			continue
		for axis in total.keys():
			fallback_total[axis] = float(fallback_total[axis]) + float(metrics.get(axis, 50.0))
		fallback_count += 1
		if MarketManager.normalize_segment(str(comp.get("target_segment", ""))) == segment:
			for axis in total.keys():
				total[axis] = float(total[axis]) + float(metrics.get(axis, 50.0))
			count += 1
	var result := {}
	for axis in total.keys():
		if count > 0:
			result[axis] = float(total[axis]) / float(count)
		elif fallback_count > 0:
			result[axis] = float(fallback_total[axis]) / float(fallback_count)
		else:
			result[axis] = 50.0
	return result

# --- 2. Conseils de l'équipe sur les CPU en vente ------------------------------------------

const ADVICE := {
	"FIX_QUALITY":{"kind":"REVISION", "revision":"QUALITY", "label":"stepping fiabilité"},
	"FIX_THERMAL":{"kind":"REVISION", "revision":"EFFICIENCY", "label":"stepping efficacité"},
	"FW_STABILITY":{"kind":"FIRMWARE", "firmware":"STABILITY", "label":"firmware stabilité"},
	"FW_PERFORMANCE":{"kind":"FIRMWARE", "firmware":"PERFORMANCE", "label":"firmware performance"},
	"FIX_COST":{"kind":"REVISION", "revision":"COST", "label":"stepping coût"},
}

## Un conseil à la fois : {generation_id, type, reason, effect, cost} ou vide.
static func pending_advice() -> Dictionary:
	for generation_value in ProductManager.cpu_generations:
		var generation: Dictionary = generation_value
		var gid := str(generation.get("id", ""))
		var launched := generation_products(gid).filter(func(p): return str(p.get("status", "")) == "LAUNCHED")
		if launched.is_empty():
			continue
		var product := _main_product(gid)
		if str(product.get("status", "")) != "LAUNCHED":
			product = launched[0]
		var done: Array = generation.get("team_advice_done", [])
		var months := int(product.get("months_on_market", 0))
		var metrics: Dictionary = product.get("metrics", {})
		# a) Un dossier SAV ouvert sur cette gamme, pas encore de révision.
		for case_value in AfterSalesManager.get_open_cases():
			var case_data: Dictionary = case_value
			if str(case_data.get("generation_id", "")) != gid:
				continue
			var thermal := str(case_data.get("issue_type", "")) == "THERMAL"
			var key := "FIX_THERMAL" if thermal else "FIX_QUALITY"
			if key not in done and int(product.get("hardware_revision", 0)) == 0:
				return _advice(generation, launched, key, "le SAV signale %s" % AfterSalesManager.issue_label(str(case_data.get("issue_type", ""))).to_lower(),
					"moins de pannes sur toutes les puces fabriquées à partir de maintenant")
		# b) Fiabilité faible : un firmware de stabilité (déployé aussi sur les puces déjà vendues).
		if months >= 3 and float(metrics.get("reliability", 80.0)) < 70.0 and "FW_STABILITY" not in done and ProductManager.firmware_available(product):
			return _advice(generation, launched, "FW_STABILITY", "la fiabilité est notre point faible (%.0f/100)" % float(metrics.get("reliability", 0.0)),
				"+2 fiabilité, y compris sur les puces déjà vendues")
		# c) Un rival nous dépasse au banc d'essai : on pousse les performances par microcode.
		if months >= 2 and "FW_PERFORMANCE" not in done and ProductManager.firmware_available(product):
			var comparison := MarketManager.press_comparison(product)
			if bool(comparison.get("has_rival", false)) and float(comparison.get("rival_delta", 0.0)) <= -3.0:
				return _advice(generation, launched, "FW_PERFORMANCE", "%s nous dépasse de %.0f points au banc d'essai" % [str(comparison.get("rival_name", "un rival")), absf(float(comparison.get("rival_delta", 0.0)))],
					"+1,6 performance (un peu moins de fiabilité)")
		# d) Marge trop mince : on réduit le coût de fabrication.
		var price := float(product.get("price", 1))
		if months >= 6 and "FIX_COST" not in done and int(product.get("hardware_revision", 0)) == 0 and price > 0.0 and (price - float(product.get("unit_cost", 0))) / price < 0.30:
			return _advice(generation, launched, "FIX_COST", "notre marge est trop mince (%.0f %%)" % ((price - float(product.get("unit_cost", 0))) / price * 100.0),
				"-5 % sur le coût de chaque puce")
	return {}

static func _advice(generation: Dictionary, launched: Array, key: String, reason: String, effect: String) -> Dictionary:
	var data: Dictionary = ADVICE[key]
	var cost := 0
	for product_value in launched:
		cost += _action_cost(product_value, data)
	return {"generation_id":str(generation.get("id", "")), "generation_name":str(generation.get("name", "CPU")), "type":key,
		"label":str(data.label), "reason":reason, "effect":effect, "cost":cost, "products":launched.size()}

static func _action_cost(product: Dictionary, data: Dictionary) -> int:
	if str(data.kind) == "REVISION":
		var revision: Dictionary = ProductManager.REVISION_TYPES[str(data.revision)]
		return int(revision.base_cost) + int(product.get("hardware_revision", 0)) * 4500 + int(float(product.get("unit_cost", 1)) * 55.0)
	var firmware: Dictionary = ProductManager.FIRMWARE_TYPES[str(data.firmware)]
	return int(firmware.cost) + int(product.get("units_sold_total", 0)) / 25 + (int(product.get("firmware_version", 1)) + 1) * 850

static func _mark_done(generation_id: String, key: String) -> void:
	var generation := ProductManager.get_generation(generation_id)
	if generation.is_empty():
		return
	var done: Array = generation.get("team_advice_done", [])
	if key not in done:
		done.append(key)
	generation["team_advice_done"] = done

## Applique le conseil à tous les modèles en vente de la gamme. Renvoie le nombre de modèles traités.
static func apply_advice(generation_id: String, key: String) -> int:
	if not ADVICE.has(key):
		return 0
	var data: Dictionary = ADVICE[key]
	var applied := 0
	for product_value in generation_products(generation_id):
		var product: Dictionary = product_value
		if str(product.get("status", "")) != "LAUNCHED":
			continue
		var ok := false
		if str(data.kind) == "REVISION":
			ok = ProductManager.apply_hardware_revision(str(product.get("id", "")), str(data.revision))
		else:
			ok = ProductManager.release_firmware(str(product.get("id", "")), str(data.firmware))
		if ok:
			applied += 1
	if applied > 0:
		_mark_done(generation_id, key)
	return applied

static func decline_advice(generation_id: String, key: String) -> void:
	_mark_done(generation_id, key)

# --- 3. Ce que disent les clients -----------------------------------------------------------

const VOICE_PROFILES := {
	"PRO":[["Ingénieurs industriels", "reliability"], ["Acheteurs", "price"], ["Intégrateurs", "performance"]],
	"SCIENCE":[["Chercheurs", "performance"], ["Services informatiques", "reliability"], ["Direction financière", "price"]],
	"CONSUMER":[["Passionnés", "performance"], ["Familles", "price"], ["Utilisateurs nomades", "efficiency"]],
}
const SEGMENT_VOICES := {
	"CALCULATOR":"PRO", "EMBEDDED":"PRO", "INDUSTRIAL":"PRO",
	"SCIENTIFIC":"SCIENCE", "WORKSTATION":"SCIENCE", "SERVER":"SCIENCE", "DATACENTER":"SCIENCE",
	"HOBBYIST":"CONSUMER", "BUSINESS_PC":"CONSUMER", "HOME_PC":"CONSUMER", "GAMING":"CONSUMER", "MOBILE_COMPUTING":"CONSUMER",
}
const PRAISE := {
	"performance":["Enfin une puce qui tient la charge.", "Plus rapide que ce qu'on utilisait avant, net."],
	"efficiency":["Elle consomme peu et chauffe à peine.", "L'autonomie a vraiment progressé."],
	"reliability":["Pas une seule panne depuis l'installation.", "On peut compter dessus, c'est l'essentiel."],
	"price":["Le prix est juste pour ce qu'elle offre.", "Imbattable à ce tarif."],
}
const COMPLAINT := {
	"performance":["Un peu juste face à la concurrence.", "On attendait plus de vitesse."],
	"efficiency":["Elle chauffe trop dans nos boîtiers.", "Trop gourmande en énergie."],
	"reliability":["Quelques plantages, ça inquiète.", "On a eu des retours au SAV, ce n'est pas rassurant."],
	"price":["Trop cher pour ce que c'est.", "À ce prix-là, on regarde ailleurs."],
}

## Trois phrases de clients, selon ce que chaque type de client regarde sur ce marché.
static func customer_voices(product: Dictionary) -> Array:
	var segment := MarketManager.normalize_segment(str(product.get("target_segment", MarketManager.default_segment())))
	var profiles: Array = VOICE_PROFILES[str(SEGMENT_VOICES.get(segment, "CONSUMER"))]
	var rival := rival_metrics(segment)
	var metrics: Dictionary = product.get("metrics", {})
	var result: Array = []
	var voice_seed := absi(hash(str(product.get("id", ""))))
	for i in range(profiles.size()):
		var who := str(profiles[i][0])
		var axis := str(profiles[i][1])
		var gap := 0.0
		if axis == "price":
			gap = MarketManager.price_score(product, segment) - 55.0
		else:
			gap = float(metrics.get(axis, 50.0)) - float(rival.get(axis, 50.0))
		var text := ""
		var mood := "NEUTRAL"
		if gap >= 4.0:
			text = str(PRAISE[axis][(voice_seed + i) % 2])
			mood = "HAPPY"
		elif gap <= -4.0:
			text = str(COMPLAINT[axis][(voice_seed + i) % 2])
			mood = "UNHAPPY"
		else:
			text = "Correct, dans la moyenne du marché."
		result.append({"who":who, "axis":axis, "text":text, "mood":mood})
	return result
