extends RefCounted
## V0.10 / I5 — Nora lit vos CPU en vente et dit ce qui mérite votre attention.
## Étude croisée Astra / Claude, synthèse Codex, décision d'Alexandre (docs/design/I5-cockpit/) :
## - « Tout va bien, laissez vendre » est une réponse normale ;
## - un conseil n'apparaît que sur un problème ou une occasion mesurable, sur un mois de vente terminé ;
## - un seul gros bouton à la fois ; une dépense passe toujours par « Examiner » puis confirmation ;
## - « Plus tard » met un conseil en pause 3 mois sur ce modèle ; il reste visible dans le portefeuille.

const SNOOZE_MONTHS := 3
## Rupture : même garde-fou que l'alerte de Nora (ProductManager) — 20 ventes perdues et 20 % de la demande.
## Comparé à 10 % au banc 10 ans par Codex : 20 % ne coûte rien sur la durée.
const STOCKOUT_MIN_LOST := 20
const STOCKOUT_SHARE := 0.20
## Sous-utilisation : moins de 70 % de l'usine utilisée deux mois de suite.
const LOW_UTILIZATION := 0.70
const PROMOTION_MIN_SATISFACTION := 60.0
## Réduire la capacité doit faire économiser au moins ça par mois (et 5 % du bénéfice du modèle).
const OVERCAPACITY_MIN_SAVING := 1000

## Plus le nombre est petit, plus c'est urgent.
const PRIORITY := {"SAV":10, "LOSING":20, "STOCKOUT":30, "RIVAL":40, "CLEARANCE":50, "OVERCAPACITY":60, "PROMOTION":70, "SOFTWARE":80}

static func month_index() -> int:
	return TimeManager.year * 12 + TimeManager.month

static func launched_products() -> Array:
	var out: Array = []
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "LAUNCHED" and str(product.get("sector", "CPU")) == "CPU":
			out.append(product)
	return out

static func is_snoozed(product: Dictionary, kind: String) -> bool:
	var snooze: Dictionary = product.get("advice_snooze", {})
	return month_index() < int(snooze.get(kind, 0))

static func snooze(product_id: String, kind: String, months: int = SNOOZE_MONTHS) -> void:
	if kind == "CLEARANCE":
		ProductManager.snooze_range_advice(months)
		return
	var product := ProductManager.get_product(product_id)
	if product.is_empty():
		return
	var snooze_map: Dictionary = product.get("advice_snooze", {})
	snooze_map[kind] = month_index() + months
	product["advice_snooze"] = snooze_map
	ProductManager.products_changed.emit()

static func consumer_demand(product: Dictionary) -> int:
	return int(product.get("last_month_consumer_demand", product.get("last_month_demand", 0)))

static func _history(product: Dictionary) -> Array:
	var history_value = product.get("market_feedback_history", [])
	return history_value if typeof(history_value) == TYPE_ARRAY else []

static func _round_up(value: int, step: int = 10) -> int:
	return int(ceil(float(value) / float(step))) * step

## Tous les signaux d'un modèle (y compris ceux mis en pause) : c'est ce que montre le portefeuille.
static func product_signals(product: Dictionary, retire_ids: Array = [], attack: Dictionary = {}) -> Array:
	var out: Array = []
	if str(product.get("status", "")) != "LAUNCHED" or int(product.get("months_on_market", 0)) < 1:
		return out
	var product_id := str(product.get("id", ""))
	var name := str(product.get("name", "CPU"))
	var history := _history(product)
	var feedback: Dictionary = history[0] if not history.is_empty() else {}
	# 1. Un dossier SAV est ouvert : on comprend la cause avant de payer une correction.
	var case_data: Dictionary = AfterSalesManager._active_case_for_product(product_id)
	if not case_data.is_empty():
		out.append(_signal("SAV", product, "Le SAV a ouvert un dossier sur %s : %s." % [name, str(case_data.get("title", "retours clients")).to_lower()],
			"Comprenons la cause avant de payer une correction (firmware, révision ou geste commercial).", "Ouvrir le dossier SAV", "NAVIGATE_SAV"))
	# 2. Chaque puce vendue perd de l'argent (la réservation d'usine, elle, est un coût fixe).
	if not feedback.is_empty():
		var units := maxi(int(feedback.get("units", 0)), 1)
		var variable_margin := int(feedback.get("net_contribution", 0)) + int(feedback.get("capacity_reservation_cost", 0))
		if variable_margin <= 0:
			out.append(_signal("LOSING", product, "%s perd de l'argent à chaque puce vendue (~%s € par puce)." % [name, _money(int(round(float(variable_margin) / float(units))))],
				"Produire plus aggraverait la perte. Revoyez d'abord le prix.", "Revoir le prix", "NAVIGATE_MANAGE"))
	# 3. Rupture : des clients repartent sans CPU.
	var lost := int(product.get("last_month_lost_sales", 0))
	var demand := consumer_demand(product)
	if lost >= STOCKOUT_MIN_LOST and float(lost) >= float(demand) * STOCKOUT_SHARE:
		var current := int(product.get("production_capacity", 0))
		var quote := ProductManager.capacity_change_quote(product_id, _round_up(current + lost))
		if int(quote.get("capacity", current)) > current:
			var entry := _signal("STOCKOUT", product, "%s : %s clients sont repartis sans CPU le mois dernier." % [name, _money(lost)],
				"L'usine est pleine. Nora a préparé un devis pour produire davantage.", "Examiner la capacité", "EXAMINE")
			entry["capacity_target"] = int(quote.get("capacity", current))
			out.append(entry)
		else:
			# Au plafond, rien à acheter ici : le portefeuille le signale, mais la carte du mois ne répète
			# pas chaque mois un problème que seul un déménagement (objectifs de Nora) résout.
			var capped := _signal("STOCKOUT", product, "%s : %s clients sont repartis sans CPU, et l'usine est à son plafond." % [name, _money(lost)],
				"Pour produire plus, il faut des locaux plus grands ou votre propre usine.", "", "")
			capped["portfolio_only"] = true
			out.append(capped)
	# 4. Un rival écrase ce marché (logique existante, garde-fou : coût ≤ 25 % de la caisse).
	if not attack.is_empty() and str(attack.get("product_id", "")) == product_id:
		out.append(_signal("RIVAL", product, "Sur ce marché, %s vend %s puces par mois contre %s pour %s." % [str(attack.get("company", "")), _money(int(attack.get("rival_units", 0))), _money(int(attack.get("player_units", 0))), name],
			"Une offensive commerciale peut lui prendre des clients. Elle se prépare dans Marché.", "Voir dans Marché", "NAVIGATE_MARKET"))
	# 5. Modèle dépassé (logique existante retire_candidates).
	if product_id in retire_ids:
		out.append(_signal("CLEARANCE", product, "%s a fait son temps (%d mois, %s ventes par mois)." % [name, int(product.get("months_on_market", 0)), _money(int(product.get("last_month_sales", 0)))],
			"Comparer : le garder, une fin de série (−25 %% pendant %d mois) ou un retrait." % ProductManager.CLEARANCE_MONTHS, "Examiner la fin de vie", "EXAMINE"))
	# 6-7. Usine sous-utilisée deux mois de suite : campagne si la demande déçoit, sinon moins de capacité.
	var promo_active := str(product.get("promotion_type", "NONE")) != "NONE"
	if history.size() >= 2 and lost == 0 and not promo_active:
		var low := float((history[0] as Dictionary).get("capacity_utilization", 1.0)) < LOW_UTILIZATION and float((history[1] as Dictionary).get("capacity_utilization", 1.0)) < LOW_UTILIZATION
		var under_forecast := str((history[0] as Dictionary).get("verdict", "")) == "Sous la prévision" and str((history[1] as Dictionary).get("verdict", "")) == "Sous la prévision"
		var positive := int(feedback.get("net_contribution", 0)) > 0
		if low and under_forecast and positive and float(product.get("customer_satisfaction", 0.0)) >= PROMOTION_MIN_SATISFACTION:
			var promo: Dictionary = ProductManager.PROMOTION_TYPES["AWARENESS"]
			var entry := _signal("PROMOTION", product, "%s plaît (%.0f/100) mais se vend moins que prévu." % [name, float(product.get("customer_satisfaction", 0.0))],
				"Peu de clients le connaissent. Une campagne de notoriété coûte %s €." % _money(int(promo.cost)), "Examiner une campagne", "EXAMINE")
			entry["promotion"] = "AWARENESS"
			out.append(entry)
		elif low and int(feedback.get("capacity_reservation_cost", 0)) > 0:
			var sold := int(product.get("last_month_sales", 0))
			var target := maxi(_round_up(int(ceil(float(sold) * 1.2))), 10)
			# On ne dérange pas le joueur pour quelques euros : il faut une vraie économie mensuelle.
			var smaller := product.duplicate()
			smaller["production_capacity"] = target
			var saving := ProductManager.monthly_capacity_reservation_cost(product, sold) - ProductManager.monthly_capacity_reservation_cost(smaller, sold)
			if target < int(product.get("production_capacity", 0)) and saving >= maxi(OVERCAPACITY_MIN_SAVING, int(float(feedback.get("net_contribution", 0)) * 0.05)):
				var entry := _signal("OVERCAPACITY", product, "%s n'utilise que %.0f %% de son usine." % [name, float((history[0] as Dictionary).get("capacity_utilization", 0.0)) * 100.0],
					"La capacité réservée et inutilisée coûte ~%s € par mois. Réduire est gratuit." % _money(saving), "Examiner la capacité", "EXAMINE")
				entry["capacity_target"] = target
				out.append(entry)
	# 8. Nouvel outil : le logiciel de contrôle vient d'être débloqué.
	var software: Dictionary = product.get("control_software", {})
	if ProductManager.control_software_available(product) and not bool(software.get("released", false)) and _newest_generation(product):
		out.append(_signal("SOFTWARE", product, "Nouveau : un logiciel de contrôle peut accompagner la gamme %s." % name.split(" ")[0],
			"Il fidélise les clients de tous les modèles de cette génération.", "Examiner le logiciel", "EXAMINE"))
	out.sort_custom(func(a, b): return int(a.priority) < int(b.priority))
	return out

static func _newest_generation(product: Dictionary) -> bool:
	var generation := int(product.get("generation_index", 0))
	for other_value in launched_products():
		if int((other_value as Dictionary).get("generation_index", 0)) > generation:
			return false
	return true

static func _signal(kind: String, product: Dictionary, title: String, text: String, cta: String, cta_kind: String) -> Dictionary:
	return {"kind":kind, "priority":int(PRIORITY.get(kind, 99)), "product_id":str(product.get("id", "")),
		"product_name":str(product.get("name", "CPU")), "title":title, "text":text, "cta":cta, "cta_kind":cta_kind}

static func _money(value: int) -> String:
	var negative := value < 0
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if negative else "") + digits + out

## Le portefeuille : chaque modèle, son état et son premier signal.
## Ordre (décision d'Alexandre) : À examiner, En vente, Fin de série, Archives ; puis génération récente d'abord.
const GROUPS := ["EXAMINE", "SELLING", "CLEARANCE", "ARCHIVE"]
const GROUP_LABELS := {"EXAMINE":"À examiner", "SELLING":"En vente", "CLEARANCE":"Fin de série", "ARCHIVE":"Archives"}

static func portfolio() -> Dictionary:
	var retire_ids := ProductManager.retire_candidate_ids()
	var attack := MarketManager.attack_advice()
	var groups := {}
	for key in GROUPS:
		groups[key] = []
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		var status := str(product.get("status", ""))
		if status == "READY":
			continue
		var group := "ARCHIVE"
		var signals: Array = []
		if status == "LAUNCHED":
			if ProductManager.is_in_clearance(product):
				group = "CLEARANCE"
			else:
				signals = product_signals(product, retire_ids, attack)
				group = "EXAMINE" if not signals.is_empty() else "SELLING"
		(groups[group] as Array).append({"product":product, "signals":signals})
	for key in GROUPS:
		(groups[key] as Array).sort_custom(func(a, b):
			var pa: Dictionary = a.product
			var pb: Dictionary = b.product
			var ga := int(pa.get("generation_index", 0))
			var gb := int(pb.get("generation_index", 0))
			if ga != gb:
				return ga > gb
			if key == "EXAMINE":
				return int((a.signals[0] as Dictionary).priority) < int((b.signals[0] as Dictionary).priority)
			return int(pa.get("price", 0)) < int(pb.get("price", 0)))
	return groups

## La carte « Ce mois-ci » : 3 chiffres, le conseil le plus urgent (hors pauses) et un second en texte.
static func month_summary() -> Dictionary:
	var launched := launched_products()
	if launched.is_empty():
		return {}
	var retire_ids := ProductManager.retire_candidate_ids()
	var attack := MarketManager.attack_advice()
	var sales := 0
	var lost := 0
	var contribution := 0
	var satisfaction_weight := 0.0
	var satisfaction_total := 0.0
	var measured := false
	var active: Array = []
	var clearance_ids: Array = []
	var capped := 0
	for product_value in launched:
		var product: Dictionary = product_value
		if int(product.get("months_on_market", 0)) >= 1:
			measured = true
		var units := int(product.get("last_month_sales", 0))
		sales += units
		lost += int(product.get("last_month_lost_sales", 0))
		contribution += int((product.get("last_market_feedback", {}) as Dictionary).get("net_contribution", 0))
		satisfaction_total += float(product.get("customer_satisfaction", 0.0)) * float(maxi(units, 1))
		satisfaction_weight += float(maxi(units, 1))
		for signal_value in product_signals(product, retire_ids, attack):
			var advice: Dictionary = signal_value
			if str(advice.kind) == "CLEARANCE":
				clearance_ids.append(str(advice.product_id))
				continue
			if bool(advice.get("portfolio_only", false)):
				capped += 1
			elif not is_snoozed(product, str(advice.kind)):
				active.append(advice)
	# Plusieurs modèles dépassés : un seul conseil pour toute la gamme.
	if not clearance_ids.is_empty() and month_index() >= ProductManager.range_advice_snooze_until:
		var names: Array[String] = []
		for product_id in clearance_ids:
			names.append(str(ProductManager.get_product(str(product_id)).get("name", "")))
		var entry := {"kind":"CLEARANCE", "priority":int(PRIORITY.CLEARANCE), "product_id":str(clearance_ids[0]), "product_ids":clearance_ids,
			"product_name":names[0], "cta":"Examiner la fin de vie", "cta_kind":"EXAMINE",
			"title":("%d modèles ont fait leur temps : %s." % [names.size(), ", ".join(names)]) if names.size() > 1 else "%s a fait son temps." % names[0],
			"text":"Une fin de série (−25 %% pendant %d mois) écoule le stock, puis le modèle est retiré. Vos CPU récents récupèrent les clients." % ProductManager.CLEARANCE_MONTHS}
		active.append(entry)
	active.sort_custom(func(a, b): return int(a.priority) < int(b.priority))
	# Retour Pixel (01/10) : après avoir monté la capacité jusqu'au plafond des locaux, la carte disait
	# « Tout va bien » alors que la liste montrait encore deux ruptures.
	var calm := "Tout va bien, laissez vendre." if measured else "Laissez le marché découvrir votre CPU."
	var calm_detail := "Vos CPU sont listés plus bas. Tous les réglages restent dans « Gérer ce modèle »." if measured else "Le premier bilan de ventes arrive à la fin du mois."
	if capped > 0:
		calm = "Rien à acheter ce mois-ci : vos locaux tournent à plein."
		calm_detail = "%s produit au maximum %s puces par mois, tous CPU confondus. Pour vendre plus, il faudra des locaux plus grands (objectifs de Nora, Entreprise › Locaux)." % [ProductManager.premises_name(), _money(ProductManager.premises_production_cap())]
	var headline := "Premières ventes en cours : le bilan arrive à la fin du mois."
	if measured:
		headline = "%s puces vendues le mois dernier, %s%s € de bénéfice des ventes." % [_money(sales), "+" if contribution >= 0 else "", _money(contribution)]
	return {"measured":measured, "sales":sales, "lost":lost, "contribution":contribution,
		"satisfaction":satisfaction_total / maxf(satisfaction_weight, 1.0),
		"served":float(sales) / maxf(float(sales + lost), 1.0),
		"headline":headline, "top":active[0] if not active.is_empty() else {},
		"second":active[1] if active.size() > 1 else {}, "count":active.size(),
		"calm":calm, "calm_detail":calm_detail}
