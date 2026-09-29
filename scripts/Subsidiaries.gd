extends RefCounted
## Lot F2 (29/09) : les filiales. Avant, « Créer une filiale » prenait le capital sans aucun effet,
## et une société rachetée (lot F1) disparaissait. Désormais une filiale vit : elle a un chiffre
## d'affaires, un potentiel (ce que son marché et son capital lui permettent), un mandat choisi par le
## joueur, et de petits événements (demande de fonds, gros contrat, client perdu).
## Mandats :
## - CASH (verser des dividendes) : 80 % du bénéfice remonte au groupe, le potentiel s'érode lentement ;
## - GROWTH (grandir) : tout est réinvesti, chaque euro réinvesti ou injecté élève le potentiel ;
## - INTEGRATE (intégrer au groupe) : 12 mois, ses clients passent chez le joueur, puis elle disparaît.
## L'état vit dans CompanyManager.subsidiaries (déjà sauvegardé) ; ce fichier ne contient que les règles.
## Unité de valeur : une filiale vaut environ 10 mois de chiffre d'affaires (comme un rival, lot F1).

const VALUE_MONTHS := 10.0
const CASH_PAYOUT := 0.80
const CASH_EROSION := 0.004
const GROWTH_MARKET_DRIFT := 0.002
const REVENUE_CONVERGENCE := 0.05
const ACQUIRED_MARGIN := 0.15
const FOUNDED_MARGIN := 0.14
# Sonde 29/09 : sans plafond, 11 filiales atteignaient 339 M EUR de CA par mois en 2030 (plus que leurs
# marchés). Une filiale ne dépasse pas 25 % de son marché ; plus elle s'en approche, moins un euro investi
# la fait grandir.
const MARKET_SHARE_CAP := 0.25
const MIN_MARKET_CAP := 2_000_000.0
const MIN_GROWTH_EFFICIENCY := 0.05
const REQUEST_REVENUE_MONTHS := 6.0
const REQUEST_BONUS := 0.5
const STARTUP_MONTHS := 24
const STARTUP_COST_RATE := 0.05
const INTEGRATE_MONTHS := 12
const INTEGRATE_REVENUE_DECAY := 0.92
const SALE_DISCOUNT := 0.90
const REQUEST_CHANCE := 0.015
const CONTRACT_CHANCE := 0.010
const SETBACK_CHANCE := 0.008
const REQUEST_MONTHS := 3
const MIN_CAPITAL := 50_000
const MANDATES := ["CASH", "GROWTH", "INTEGRATE"]
const MANDATE_LABELS := {"CASH":"Verser des dividendes", "GROWTH":"Grandir", "INTEGRATE":"Intégrer au groupe"}
const MANDATE_HINTS := {
	"CASH":"80 % du bénéfice remonte chaque mois ; sans investissement, elle s'essouffle lentement.",
	"GROWTH":"Elle réinvestit tout ; votre capital l'aide à grossir. Pas de dividendes.",
	"INTEGRATE":"Pendant 12 mois ses clients passent chez vous (+25 % de demande sur son marché), puis elle rejoint votre marque."
}

static func list() -> Array:
	return CompanyManager.subsidiaries

static func get_subsidiary(id: String) -> Dictionary:
	for sub_value in CompanyManager.subsidiaries:
		if str((sub_value as Dictionary).get("id", "")) == id:
			return sub_value
	return {}

static func value_of(sub: Dictionary) -> int:
	return int(round(float(sub.get("revenue", 0.0)) * VALUE_MONTHS / 10_000.0)) * 10_000 + maxi(int(sub.get("cash", 0)), 0)

static func sale_price(sub: Dictionary) -> int:
	return int(round(float(value_of(sub)) * SALE_DISCOUNT / 10_000.0)) * 10_000

## Capital proposé par le bouton « Injecter » : environ 6 mois de chiffre d'affaires (au moins 500 000 EUR).
static func injection_step(sub: Dictionary) -> int:
	return maxi(500_000, int(round(float(sub.get("revenue", 0.0)) * 6.0 / 100_000.0)) * 100_000)

static func mandate_label(mandate: String) -> String:
	return str(MANDATE_LABELS.get(mandate, mandate))

## Chiffre d'affaires maximal d'une filiale : 25 % de son marché (qui peut grandir ou décliner).
static func market_cap(sub: Dictionary) -> float:
	var segment := str(sub.get("segment", ""))
	var market := diversification_market(segment) if DIVERSIFICATION.has(segment) \
		else float(MarketManager.segment_market_units(segment)) * MarketManager.segment_reference_price(segment)
	return maxf(market * MARKET_SHARE_CAP, MIN_MARKET_CAP)

# --- Lot F3 : diversification sans nouvelle technologie (PC, mémoire, cartes graphiques) ------------
# Le joueur ne conçoit pas ces produits : il crée (ou rachète) une filiale qui les fabrique. Chaque marché a
# sa taille, qui grandit jusqu'à un plateau. Une filiale PC achète les processeurs du groupe (client captif) ;
# une filiale GPU pousse les CPU gaming et stations de travail.
const DIVERSIFICATION := {
	"PC":{"label":"Ordinateurs (PC)", "first_year":1977, "base_market":3_000_000.0, "growth":0.10, "plateau_year":2008,
		"boost_segments":["HOME_PC", "BUSINESS_PC"]},
	"RAM":{"label":"Mémoire (RAM)", "first_year":1971, "base_market":1_500_000.0, "growth":0.10, "plateau_year":2010,
		"boost_segments":[]},
	"GPU":{"label":"Cartes graphiques (GPU)", "first_year":1995, "base_market":8_000_000.0, "growth":0.12, "plateau_year":2020,
		"boost_segments":["GAMING", "WORKSTATION"]}
}
const DIVERSIFICATION_ORDER := ["PC", "RAM", "GPU"]
const CAPTIVE_BOOST_PER_SHARE := 1.5
const CAPTIVE_BOOST_MAX := 0.30

static func is_diversification_open(sector: String) -> bool:
	return DIVERSIFICATION.has(sector) and TimeManager.year >= int(DIVERSIFICATION[sector].first_year)

## Chiffre d'affaires mensuel de tout le marché (toutes marques confondues) cette année.
static func diversification_market(sector: String) -> float:
	if not DIVERSIFICATION.has(sector):
		return 0.0
	var data: Dictionary = DIVERSIFICATION[sector]
	var years := clampi(TimeManager.year, int(data.first_year), int(data.plateau_year)) - int(data.first_year)
	return float(data.base_market) * pow(1.0 + float(data.growth), float(years))

static func segment_label(sub: Dictionary) -> String:
	var segment := str(sub.get("segment", ""))
	if DIVERSIFICATION.has(segment):
		return str(DIVERSIFICATION[segment].label)
	return MarketManager.segment_label(segment)

## Client captif : une filiale PC (ou GPU) achète les CPU du groupe sur ses marchés.
static func captive_demand_factor(product: Dictionary) -> float:
	if str(product.get("company", CompanyManager.company_name)) != CompanyManager.company_name:
		return 1.0
	var target := MarketManager.normalize_segment(str(product.get("target_segment", "")))
	var boost := 0.0
	for sub_value in CompanyManager.subsidiaries:
		var sub: Dictionary = sub_value
		var segment := str(sub.get("segment", ""))
		if not DIVERSIFICATION.has(segment) or str(sub.get("mandate", "")) == "INTEGRATE":
			continue
		if not (DIVERSIFICATION[segment].boost_segments as Array).has(target):
			continue
		var share := float(sub.get("revenue", 0.0)) / maxf(diversification_market(segment), 1.0)
		boost += share * CAPTIVE_BOOST_PER_SHARE
	return 1.0 + minf(boost, CAPTIVE_BOOST_MAX)

## Secteurs proposés à la création d'une filiale : processeurs, puis la diversification ouverte cette année.
static func founding_sectors() -> Array:
	var rows: Array = [{"key":"CPU", "label":"Processeurs", "open":true}]
	for sector in DIVERSIFICATION_ORDER:
		var data: Dictionary = DIVERSIFICATION[sector]
		var open := is_diversification_open(sector)
		rows.append({"key":sector, "label":str(data.label) if open else "%s - à partir de %d" % [str(data.label), int(data.first_year)], "open":open})
	return rows

## Rendement d'un euro investi : plein effet loin du plafond, presque nul tout près.
static func growth_efficiency(sub: Dictionary) -> float:
	return clampf(1.0 - float(sub.get("potential", 0.0)) / market_cap(sub), MIN_GROWTH_EFFICIENCY, 1.0)

static func _grow(sub: Dictionary, euros: float) -> void:
	sub["potential"] = float(sub.get("potential", 0.0)) + euros / VALUE_MONTHS * growth_efficiency(sub)

# --- Naissance d'une filiale ------------------------------------------------------------------------

static func _next_id() -> String:
	var highest := 0
	for sub_value in CompanyManager.subsidiaries:
		var id := str((sub_value as Dictionary).get("id", ""))
		if id.begins_with("SUB-"):
			highest = maxi(highest, int(id.substr(4)))
	return "SUB-%03d" % (highest + 1)

static func _base(name: String, origin: String, sector: String, segment: String) -> Dictionary:
	return {
		"id":_next_id(), "name":name, "origin":origin, "sector":sector, "segment":segment,
		"mandate":"CASH", "revenue":0.0, "potential":0.0, "margin":ACQUIRED_MARGIN, "brand":45.0,
		"cash":0, "invested":0, "dividends":0, "last_profit":0, "last_dividend":0,
		"age_months":0, "integrate_months":0, "request":{}, "year":TimeManager.year, "month":TimeManager.month
	}

## Lot F1 -> F2 : un rival racheté devient une filiale qui garde ses clients et son chiffre d'affaires.
static func adopt_acquired(competitor: Dictionary, price: int) -> Dictionary:
	var revenue := float(maxi(int(competitor.get("structure_revenue", competitor.get("last_month_revenue", 0))), 0))
	revenue = maxf(revenue, float(price) / VALUE_MONTHS * 0.5)
	var sub := _base(str(competitor.get("company", "Filiale")), "ACQUIRED", "CPU",
		MarketManager.normalize_segment(str(competitor.get("target_segment", "EMBEDDED"))))
	sub["revenue"] = revenue
	sub["potential"] = revenue * 1.05
	sub["brand"] = float(competitor.get("brand", 50.0))
	sub["invested"] = price
	CompanyManager.subsidiaries.append(sub)
	CompanyManager.company_changed.emit()
	return sub

## Filiale créée de toutes pièces : le capital fixe son potentiel, elle démarre petite et perd de
## l'argent pendant sa montée en charge (2 ans).
static func found(name: String, sector: String, capital: int) -> bool:
	var clean := name.strip_edges()
	if clean == "" or capital < MIN_CAPITAL or not Economy.can_afford(capital, "Capital filiale"):
		return false
	if sector != "CPU" and not is_diversification_open(sector):
		return false
	Economy.add_expense(capital, "Capital filiale")
	var segment := MarketManager.default_segment() if sector == "CPU" else sector
	var sub := _base(clean, "FOUNDED", sector, segment)
	sub["mandate"] = "GROWTH"
	sub["margin"] = FOUNDED_MARGIN
	sub["potential"] = float(capital) / VALUE_MONTHS
	sub["revenue"] = float(capital) / VALUE_MONTHS * 0.15
	sub["invested"] = capital
	CompanyManager.subsidiaries.append(sub)
	CompanyManager.add_alert("Nouvelle filiale créée : %s. Elle démarre petite et grandira pendant 2 ans (Entreprise > Groupe)." % clean)
	MediaManager.publish_business_event("%s crée %s" % [CompanyManager.company_name, clean],
		"Nouvelle filiale dotée de %s EUR de capital." % _group(capital), "found_%s" % str(sub.id))
	CompanyManager.company_changed.emit()
	return true

## Anciennes sauvegardes : l'ébauche {name, sector, capital, reputation} devient une vraie filiale.
static func migrate(entry: Dictionary) -> Dictionary:
	if entry.has("id") and entry.has("mandate"):
		return entry
	var capital := int(entry.get("capital", MIN_CAPITAL))
	var sub := _base(str(entry.get("name", "Filiale")), "FOUNDED", str(entry.get("sector", "CPU")), MarketManager.default_segment())
	sub["id"] = "SUB-%03d" % (CompanyManager.subsidiaries.find(entry) + 1)
	sub["mandate"] = "GROWTH"
	sub["margin"] = FOUNDED_MARGIN
	sub["potential"] = float(capital) / VALUE_MONTHS
	sub["revenue"] = float(capital) / VALUE_MONTHS * 0.5
	sub["invested"] = capital
	sub["age_months"] = STARTUP_MONTHS
	return sub

# --- Tour mensuel ------------------------------------------------------------------------------------

static func process_month() -> void:
	var finished: Array = []
	var total_dividends := 0
	for sub_value in CompanyManager.subsidiaries:
		var sub: Dictionary = sub_value
		sub["age_months"] = int(sub.get("age_months", 0)) + 1
		var mandate := str(sub.get("mandate", "CASH"))
		var revenue := float(sub.get("revenue", 0.0))
		var potential := float(sub.get("potential", 0.0))
		# Le chiffre d'affaires rejoint peu à peu le potentiel (clients gagnés ou perdus).
		if mandate == "INTEGRATE":
			revenue *= INTEGRATE_REVENUE_DECAY
		else:
			# Au-delà du plafond de son marché (marché qui décline, gros rachat), l'excédent fond.
			var cap := market_cap(sub)
			if potential > cap:
				potential = lerpf(potential, cap, REVENUE_CONVERGENCE)
			revenue = lerpf(revenue, minf(potential, cap), REVENUE_CONVERGENCE)
		var profit := revenue * float(sub.get("margin", ACQUIRED_MARGIN))
		if str(sub.get("origin", "")) == "FOUNDED" and int(sub.age_months) <= STARTUP_MONTHS:
			profit -= potential * STARTUP_COST_RATE
		var dividend := 0
		match mandate:
			"CASH":
				dividend = maxi(int(profit * CASH_PAYOUT), 0)
				potential *= 1.0 - CASH_EROSION
			"GROWTH":
				potential *= 1.0 + GROWTH_MARKET_DRIFT
				if profit > 0.0:
					potential += profit / VALUE_MONTHS * growth_efficiency({"potential":potential, "segment":sub.get("segment", "")})
			"INTEGRATE":
				dividend = maxi(int(profit), 0)
				sub["integrate_months"] = int(sub.get("integrate_months", 0)) - 1
				if int(sub.integrate_months) <= 0:
					finished.append(sub)
		if profit < 0.0:
			sub["cash"] = int(sub.get("cash", 0)) + int(profit)
		sub["revenue"] = revenue
		sub["potential"] = potential
		sub["last_profit"] = int(profit)
		sub["last_dividend"] = dividend
		sub["dividends"] = int(sub.get("dividends", 0)) + dividend
		total_dividends += dividend
		_tick_request(sub)
		if mandate != "INTEGRATE":
			_maybe_event(sub)
	if total_dividends > 0:
		Economy.add_income(total_dividends, "Dividendes des filiales")
	for sub_value in finished:
		_complete_integration(sub_value)
	if not CompanyManager.subsidiaries.is_empty():
		CompanyManager.company_changed.emit()

static func group_revenue() -> int:
	var total := 0.0
	for sub_value in CompanyManager.subsidiaries:
		total += float((sub_value as Dictionary).get("revenue", 0.0))
	return int(total)

static func group_dividends() -> int:
	var total := 0
	for sub_value in CompanyManager.subsidiaries:
		total += int((sub_value as Dictionary).get("last_dividend", 0))
	return total

# --- Décisions du joueur -----------------------------------------------------------------------------

static func can_integrate(sub: Dictionary) -> bool:
	return not DIVERSIFICATION.has(str(sub.get("segment", "")))

static func set_mandate(id: String, mandate: String) -> bool:
	var sub := get_subsidiary(id)
	if sub.is_empty() or not MANDATES.has(mandate) or str(sub.get("mandate", "")) == "INTEGRATE":
		return false
	if str(sub.get("mandate", "")) == mandate:
		return false
	# Lot F3 : une filiale PC, RAM ou GPU vend d'autres produits ; ses clients n'achètent pas des CPU.
	if mandate == "INTEGRATE" and not can_integrate(sub):
		return false
	sub["mandate"] = mandate
	if mandate == "INTEGRATE":
		sub["integrate_months"] = INTEGRATE_MONTHS
		MarketManager.acquisition_boosts.append({"segment":str(sub.get("segment", "")), "months":INTEGRATE_MONTHS + 12, "company":str(sub.name)})
		CompanyManager.add_alert("%s rejoint le groupe : ses clients passent chez vous pendant 12 mois." % str(sub.name))
	CompanyManager.company_changed.emit()
	return true

## Le vrai puits d'argent de fin de partie : chaque euro injecté élève le potentiel d'un dixième.
static func inject(id: String, amount: int) -> bool:
	var sub := get_subsidiary(id)
	if sub.is_empty() or amount <= 0 or str(sub.get("mandate", "")) == "INTEGRATE":
		return false
	if not Economy.can_afford(amount, "Capital filiale"):
		return false
	Economy.add_expense(amount, "Capital filiale")
	_grow(sub, float(amount))
	sub["invested"] = int(sub.get("invested", 0)) + amount
	if int(sub.get("cash", 0)) < 0:
		sub["cash"] = mini(int(sub.cash) + amount, 0)
	CompanyManager.company_changed.emit()
	return true

static func sell(id: String) -> bool:
	var sub := get_subsidiary(id)
	if sub.is_empty() or str(sub.get("mandate", "")) == "INTEGRATE":
		return false
	var price := sale_price(sub)
	CompanyManager.subsidiaries.erase(sub)
	if price > 0:
		Economy.add_income(price, "Vente de filiale")
	MediaManager.publish_business_event("%s cède %s" % [CompanyManager.company_name, str(sub.name)],
		"La filiale change de mains pour %s EUR." % _group(price), "sale_%s" % str(sub.id))
	CompanyManager.add_alert("%s vendue pour %s EUR." % [str(sub.name), _group(price)])
	CompanyManager.company_changed.emit()
	return true

static func _complete_integration(sub: Dictionary) -> void:
	CompanyManager.subsidiaries.erase(sub)
	CompanyManager.change_reputation({"prestige":1.5, "professional":1.0})
	MediaManager.publish_business_event("%s disparaît dans %s" % [str(sub.name), CompanyManager.company_name],
		"Fin de l'intégration : les équipes et les clients de %s portent désormais la marque %s." % [str(sub.name), CompanyManager.company_name],
		"integrated_%s" % str(sub.id))
	CompanyManager.add_alert("Intégration de %s terminée : ses clients sont les vôtres." % str(sub.name))

# --- Vie de la filiale : demandes de fonds, gros contrats, clients perdus -----------------------------

static func _maybe_event(sub: Dictionary) -> void:
	if not (sub.get("request", {}) as Dictionary).is_empty() or int(sub.get("age_months", 0)) < 6:
		return
	var rng: RandomNumberGenerator = MarketManager.rng
	var roll := rng.randf()
	var name := str(sub.get("name", "La filiale"))
	if roll < REQUEST_CHANCE:
		var amount := maxi(500_000, int(round(float(sub.get("revenue", 0.0)) * REQUEST_REVENUE_MONTHS / 100_000.0)) * 100_000)
		sub["request"] = {"amount":amount, "months_left":REQUEST_MONTHS}
		CompanyManager.add_alert("Le directeur de %s demande %s EUR pour s'agrandir." % [name, _group(amount)])
	elif roll < REQUEST_CHANCE + CONTRACT_CHANCE:
		sub["revenue"] = float(sub.get("revenue", 0.0)) * 1.15
		sub["potential"] = float(sub.get("potential", 0.0)) * (1.0 + 0.10 * growth_efficiency(sub))
		MediaManager.publish_business_event("%s décroche un gros contrat" % name,
			"La filiale de %s signe un client important : son chiffre d'affaires bondit." % CompanyManager.company_name, "contract_%s" % str(sub.id))
	elif roll < REQUEST_CHANCE + CONTRACT_CHANCE + SETBACK_CHANCE:
		sub["potential"] = float(sub.get("potential", 0.0)) * 0.88
		MediaManager.publish_business_event("%s perd un client historique" % name,
			"Coup dur pour la filiale de %s : un grand compte part à la concurrence." % CompanyManager.company_name, "setback_%s" % str(sub.id))

static func _tick_request(sub: Dictionary) -> void:
	var request: Dictionary = sub.get("request", {})
	if request.is_empty():
		return
	request["months_left"] = int(request.get("months_left", 0)) - 1
	if int(request.months_left) <= 0:
		sub["request"] = {}
		sub["potential"] = float(sub.get("potential", 0.0)) * 0.97
		CompanyManager.add_alert("Sans réponse, le directeur de %s renonce à son projet (et le prend mal)." % str(sub.get("name", "")))

static func open_requests() -> Array:
	var result: Array = []
	for sub_value in CompanyManager.subsidiaries:
		var sub: Dictionary = sub_value
		if not (sub.get("request", {}) as Dictionary).is_empty():
			result.append(sub)
	return result

## Financer le projet du directeur : le capital compte 1,5 fois (il sait où l'investir).
static func answer_request(id: String, fund: bool) -> bool:
	var sub := get_subsidiary(id)
	var request: Dictionary = sub.get("request", {}) if not sub.is_empty() else {}
	if request.is_empty():
		return false
	if fund:
		var amount := int(request.get("amount", 0))
		if not inject(id, amount):
			return false
		_grow(sub, float(amount) * REQUEST_BONUS)
		CompanyManager.add_alert("Projet de %s financé : la filiale va grossir." % str(sub.get("name", "")))
	else:
		sub["potential"] = float(sub.get("potential", 0.0)) * 0.98
	sub["request"] = {}
	CompanyManager.company_changed.emit()
	return true

static func _group(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out
