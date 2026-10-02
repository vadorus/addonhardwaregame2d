extends Node

signal market_changed
signal opportunity_created(contract)
signal market_need_unlocked(need)

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const RIVAL_LIFE := preload("res://scripts/RivalLife.gd")
const STRATEGIC := preload("res://scripts/StrategicMarkets.gd")
const LATE_GAME := preload("res://scripts/LateGameEvents.gd")
const TECH_LAG := preload("res://scripts/TechnologyLag.gd")

# Les dates sont des repères historiques, pas des verrous rigides :
# une partie technologiquement en avance peut faire émerger un besoin plus tôt.
const MARKET_NEED_ORDER := [
	"CALCULATOR", "EMBEDDED", "INDUSTRIAL", "SCIENTIFIC", "HOBBYIST",
	"BUSINESS_PC", "HOME_PC", "WORKSTATION", "SERVER", "GAMING",
	"MOBILE_COMPUTING", "DATACENTER"
]

const MAX_EARLY_NEED_YEARS := 7
## Rythme de la campagne (28/09) : les concurrents atteignaient 95-100 partout dès 1986.
## L'état de l'art du secteur suit maintenant un plafond daté qui atteint 100 en
## FINAL_TECH_YEAR. Au-delà, le contenu technologique de cette version est épuisé
## (Nora l'annonce) ; la suite viendra avec les mises à jour / DLC.
const FINAL_TECH_YEAR := 2010
const ERA_CEILING_START := 32.0
const ERA_CEILING_SOFT_SPAN := 8.0

func era_technology_ceiling(year: int = -1) -> float:
	var y := TimeManager.year if year < 0 else year
	var t := clampf(float(y - 1971) / float(FINAL_TECH_YEAR - 1971), 0.0, 1.0)
	return lerpf(ERA_CEILING_START, 100.0, t)

## Freine une progression qui approche le plafond de l'époque (0 au plafond).
func era_gain_factor(current: float) -> float:
	return clampf((era_technology_ceiling() - current) / ERA_CEILING_SOFT_SPAN, 0.0, 1.0)

## C3 / P0 : l'état de l'art du procédé = le plus fin utilisé par un rival CPU ;
## sans rival (bac à sable, tests isolés) : le plus fin procédé que l'époque permet.
func state_of_the_art_node() -> int:
	var best := -1
	for comp_value in competitors.get("CPU", []):
		best = maxi(best, CPU_DESIGN.NODE_ORDER.find(int((comp_value as Dictionary).get("node_nm", 10000))))
	if best < 0:
		var ceiling := era_technology_ceiling()
		best = 0
		for i in range(CPU_DESIGN.NODE_ORDER.size()):
			if float(CPU_DESIGN.node_profile(int(CPU_DESIGN.NODE_ORDER[i])).get("unlock", 0.0)) <= ceiling + 0.001:
				best = i
	return int(CPU_DESIGN.NODE_ORDER[best])

## C3 / P0 : un CPU du joueur dépassé par l'état de l'art se vend moins (1.0 = à jour).
func product_technology_factor(product: Dictionary) -> float:
	if str(product.get("sector", "CPU")) != "CPU" or str(product.get("company", "")) != CompanyManager.company_name:
		return 1.0
	var design_value = product.get("cpu_design", {})
	if typeof(design_value) != TYPE_DICTIONARY or (design_value as Dictionary).is_empty():
		return 1.0
	return TECH_LAG.demand_factor(technology_lag(int((design_value as Dictionary).get("node_nm", 10000)), str(product.get("architecture_id", ""))))

## C3 / P0 : ajustements « retard technologique » d'un CPU du joueur (voir scripts/TechnologyLag.gd).
func technology_lag(node_nm: int, arch_id: String = "") -> Dictionary:
	var latest := ArchitectureManager.latest_id()
	return TECH_LAG.adjustments(node_nm, state_of_the_art_node(), arch_id if arch_id != "" else latest, latest)

const MARKET_NEEDS := {
	"CALCULATOR":{"historical_year":1971,"tech_trigger":0.0,"base_units":9000,"price_factor":0.72,"growth":0.020,"description":"Calculatrices, terminaux simples et logique programmable à bas coût."},
	"EMBEDDED":{"historical_year":1971,"tech_trigger":0.0,"base_units":15000,"price_factor":0.58,"growth":0.026,"description":"Contrôle embarqué pour équipements, automatismes et électronique spécialisée."},
	"INDUSTRIAL":{"historical_year":1971,"tech_trigger":0.0,"base_units":7000,"price_factor":1.12,"growth":0.018,"description":"Automatisation industrielle, instrumentation et systèmes où la fiabilité prime."},
	"SCIENTIFIC":{"historical_year":1972,"tech_trigger":30.0,"base_units":4500,"price_factor":1.42,"growth":0.022,"description":"Instrumentation scientifique et calcul spécialisé à forte valeur."},
	"HOBBYIST":{"historical_year":1975,"tech_trigger":36.0,"base_units":8500,"price_factor":0.82,"growth":0.040,"description":"Kits, clubs et passionnés qui expérimentent avec les microprocesseurs."},
	"BUSINESS_PC":{"historical_year":1978,"tech_trigger":46.0,"base_units":18000,"price_factor":1.08,"growth":0.050,"description":"Micro-informatique professionnelle, bureautique et gestion."},
	"HOME_PC":{"historical_year":1980,"tech_trigger":50.0,"base_units":26000,"price_factor":0.90,"growth":0.060,"description":"Ordinateurs personnels destinés au foyer et à l'éducation."},
	"WORKSTATION":{"historical_year":1982,"tech_trigger":60.0,"base_units":9000,"price_factor":1.55,"growth":0.038,"description":"Stations techniques pour ingénierie, graphisme et calcul professionnel."},
	"SERVER":{"historical_year":1988,"tech_trigger":68.0,"base_units":13000,"price_factor":1.70,"growth":0.045,"description":"Serveurs et infrastructure informatique à forte exigence de fiabilité."},
	"GAMING":{"historical_year":1993,"tech_trigger":76.0,"base_units":30000,"price_factor":1.12,"growth":0.060,"description":"Jeu, hautes performances et marché passionné sensible aux benchmarks."},
	"MOBILE_COMPUTING":{"historical_year":1997,"tech_trigger":82.0,"base_units":42000,"price_factor":1.00,"growth":0.070,"description":"Portables et appareils où consommation, autonomie et intégration deviennent centrales."},
	"DATACENTER":{"historical_year":2002,"tech_trigger":90.0,"base_units":30000,"price_factor":1.90,"growth":0.055,"description":"Calcul à grande échelle, densité, disponibilité et efficacité énergétique."}
}

# M2 — échelle économique des marchés. Ce ne sont pas des verrous : le joueur peut
# tenter un gros marché trop tôt, mais l'équipe et le budget influencent alors le délai.
const SEGMENT_PROJECT_SCALE := {
	"CALCULATOR":{"team":2,"budget":30000,"market_scale":1.0},
	"EMBEDDED":{"team":2,"budget":40000,"market_scale":1.0},
	# Claude 29/09 : les marchés du garage (1971-72) restent jouables avec les 2 développeurs du départ ;
	# à 5 requis, choisir « Industriel » en premier CPU menait à la faillite au mois 19 (sonde 40 ans).
	"INDUSTRIAL":{"team":2,"budget":45000,"market_scale":1.15},
	"SCIENTIFIC":{"team":3,"budget":55000,"market_scale":1.35},
	"HOBBYIST":{"team":4,"budget":55000,"market_scale":1.60},
	"BUSINESS_PC":{"team":10,"budget":85000,"market_scale":2.60},
	"HOME_PC":{"team":12,"budget":95000,"market_scale":3.20},
	"WORKSTATION":{"team":16,"budget":120000,"market_scale":2.80},
	"SERVER":{"team":25,"budget":160000,"market_scale":5.00},
	"GAMING":{"team":18,"budget":135000,"market_scale":5.50},
	"MOBILE_COMPUTING":{"team":24,"budget":175000,"market_scale":7.00},
	"DATACENTER":{"team":32,"budget":240000,"market_scale":8.00}
}

# Cycle historique des marchés : croissance, maturité, puis éventuel déclin.
# Les marchés structurels (embarqué, industriel, serveur...) restent durables ;
# les premiers marchés grand public peuvent être remplacés par de nouveaux usages.
const SEGMENT_LIFECYCLE := {
	"CALCULATOR":{"growth_years":6.0,"plateau_years":5.0,"decline_years":12.0,"floor":0.18},
	"EMBEDDED":{"growth_years":18.0,"plateau_years":20.0,"decline_years":30.0,"floor":0.82},
	"INDUSTRIAL":{"growth_years":15.0,"plateau_years":20.0,"decline_years":30.0,"floor":0.76},
	"SCIENTIFIC":{"growth_years":14.0,"plateau_years":18.0,"decline_years":24.0,"floor":0.62},
	"HOBBYIST":{"growth_years":7.0,"plateau_years":6.0,"decline_years":12.0,"floor":0.24},
	"BUSINESS_PC":{"growth_years":10.0,"plateau_years":9.0,"decline_years":12.0,"floor":0.32},
	"HOME_PC":{"growth_years":12.0,"plateau_years":15.0,"decline_years":15.0,"floor":0.45},
	"WORKSTATION":{"growth_years":12.0,"plateau_years":16.0,"decline_years":18.0,"floor":0.58},
	"SERVER":{"growth_years":15.0,"plateau_years":20.0,"decline_years":24.0,"floor":0.72},
	"GAMING":{"growth_years":12.0,"plateau_years":20.0,"decline_years":20.0,"floor":0.68},
	"MOBILE_COMPUTING":{"growth_years":13.0,"plateau_years":18.0,"decline_years":20.0,"floor":0.72},
	"DATACENTER":{"growth_years":12.0,"plateau_years":20.0,"decline_years":24.0,"floor":0.78}
}

const MARKET_THREAT_ORDER := ["PRICE_WAR", "RECESSION", "SILICON_SHORTAGE", "PATENT_LAWSUIT", "NEW_ENTRANT"]
const MARKET_THREAT_TEMPLATES := {
	"PRICE_WAR":{"title":"Guerre des prix","text":"Un rival casse ses prix pour prendre des parts de marché.","duration":12,"response":18000,"ignore":42000,"demand":0.80,"mitigated_demand":0.93,"cost":1.00,"mitigated_cost":1.00},
	"RECESSION":{"title":"Récession technologique","text":"Les clients reportent leurs achats et les volumes se contractent.","duration":15,"response":24000,"ignore":56000,"demand":0.72,"mitigated_demand":0.88,"cost":1.00,"mitigated_cost":1.00},
	"SILICON_SHORTAGE":{"title":"Pénurie de silicium","text":"Les capacités de fonderie se tendent et chaque puce coûte plus cher.","duration":12,"response":30000,"ignore":68000,"demand":0.96,"mitigated_demand":0.99,"cost":1.40,"mitigated_cost":1.12},
	"PATENT_LAWSUIT":{"title":"Procès de brevet","text":"Un détenteur de brevets conteste une partie de votre technologie.","duration":10,"response":38000,"ignore":88000,"demand":0.94,"mitigated_demand":0.99,"cost":1.04,"mitigated_cost":1.00},
	"NEW_ENTRANT":{"title":"Nouvel entrant agressif","text":"Nexus Micro arrive avec des ingénieurs expérimentés et une première gamme ambitieuse.","duration":14,"response":28000,"ignore":62000,"demand":0.84,"mitigated_demand":0.94,"cost":1.00,"mitigated_cost":1.00}
}

const COMPETITOR_ARCHETYPES := {
	"ASTER":{
		"company":"Aster Systems","product_prefix":"Aster",
		"strategy":"EFFICIENCY","cash":310000,
		"architecture":20.0,"layout":22.0,"miniaturization":18.0,"manufacturing":24.0,"integration":18.0,
		"brand":47.0,"risk_tolerance":42.0,"capacity":10500,
		"ai_price_aggression":42.0,"ai_research_drive":58.0,"ai_financial_prudence":76.0,"ai_adaptability":48.0,"ai_growth_drive":50.0
	},
	"HELIX":{
		"company":"Helix Global","product_prefix":"Helix",
		"strategy":"PERFORMANCE","cash":390000,
		"architecture":27.0,"layout":18.0,"miniaturization":21.0,"manufacturing":20.0,"integration":20.0,
		"brand":58.0,"risk_tolerance":72.0,"capacity":9000,
		"ai_price_aggression":72.0,"ai_research_drive":84.0,"ai_financial_prudence":38.0,"ai_adaptability":68.0,"ai_growth_drive":80.0
	},
	"QUANTUM":{
		"company":"Quantum Works","product_prefix":"Quantum",
		"strategy":"BALANCED","cash":345000,
		"architecture":23.0,"layout":23.0,"miniaturization":20.0,"manufacturing":23.0,"integration":22.0,
		"brand":52.0,"risk_tolerance":56.0,"capacity":11500,
		"ai_price_aggression":54.0,"ai_research_drive":66.0,"ai_financial_prudence":58.0,"ai_adaptability":74.0,"ai_growth_drive":64.0
	}
}

const TENDER_TEMPLATES := {
	"INDUSTRIAL_CONTROL":{
		"customer":"Atlas Automation",
		"title":"Plateforme de contrôle industriel",
		"application_profile":"INDUSTRIAL",
		"segment":"INDUSTRIAL",
		"historical_year":1971,
		"tech_trigger":0.0,
		"requirements":{"performance":44.0,"efficiency":54.0,"reliability":74.0},
		"base_volume":900,
		"duration_months":12,
		"deadline_months":4,
		"max_price_factor":1.12,
		"confidentiality":48.0,
		"exclusivity":false,
		"penalty_rate":0.10
	},
	"SPACE_GUIDANCE":{
		"customer":"Orbital Systems Agency",
		"title":"Calculateur embarqué mission critique",
		"application_profile":"SPACE",
		"segment":"SCIENTIFIC",
		"historical_year":1971,
		"tech_trigger":0.0,
		"requirements":{"performance":38.0,"efficiency":68.0,"reliability":86.0},
		"base_volume":180,
		"duration_months":18,
		"deadline_months":6,
		"max_price_factor":2.10,
		"confidentiality":92.0,
		"exclusivity":true,
		"penalty_rate":0.18
	},
	"CONSOLE_PLATFORM":{
		"customer":"Aurora Interactive",
		"title":"CPU pour future console domestique",
		"application_profile":"CONSOLE",
		"segment":"HOME_PC",
		"historical_year":1976,
		"tech_trigger":44.0,
		"requirements":{"performance":60.0,"efficiency":58.0,"reliability":66.0},
		"base_volume":4200,
		"duration_months":18,
		"deadline_months":5,
		"max_price_factor":0.90,
		"confidentiality":76.0,
		"exclusivity":true,
		"penalty_rate":0.14
	},
	"SERVER_FLEET":{
		"customer":"Northstar Systems",
		"title":"Processeur pour gamme de serveurs",
		"application_profile":"SERVER",
		"segment":"SERVER",
		"historical_year":1983,
		"tech_trigger":62.0,
		"requirements":{"performance":66.0,"efficiency":64.0,"reliability":80.0},
		"base_volume":2100,
		"duration_months":24,
		"deadline_months":6,
		"max_price_factor":1.35,
		"confidentiality":70.0,
		"exclusivity":false,
		"penalty_rate":0.15
	},
	"MOBILE_PLATFORM":{
		"customer":"Mercury Mobile",
		"title":"CPU basse consommation pour appareil mobile",
		"application_profile":"MOBILE",
		"segment":"MOBILE_COMPUTING",
		"historical_year":1990,
		"tech_trigger":78.0,
		"requirements":{"performance":54.0,"efficiency":80.0,"reliability":70.0},
		"base_volume":8500,
		"duration_months":18,
		"deadline_months":5,
		"max_price_factor":0.82,
		"confidentiality":82.0,
		"exclusivity":true,
		"penalty_rate":0.16
	}
}

var competitors: Dictionary = {}
var contracts: Array = []
var tenders: Array = []
var market_events: Array = []
var market_threats: Array = []
var known_segments: Array = []
var _next_contract_id := 1
var _next_tender_id := 1
var _next_threat_id := 1
var _last_threat_market_age := 0
var market_age_months := 0
## Lot D : offensives commerciales du joueur contre un rival.
var attacks: Array = []
var _next_attack_id := 1
## Nora ne propose pas d'offensive avant ce mois (index année*12+mois).
var attack_advice_snooze_until := 0
# Lot F1 : vie des rivaux et rachats (règles dans RivalLife.gd).
var rival_offers: Array = []
var acquisitions: Array = []
var acquisition_boosts: Array = []
var corporate_log: Array = []
var offer_snooze: Dictionary = {}
var _next_offer_id := 1
var last_healthy_offer_age := 0
var last_entrant_age := 0
# Lot F3 : accréditations défense / aérospatial (règles dans StrategicMarkets.gd).
var strategic: Dictionary = {}
# Lot F4 : événements macro après 2010 + salon annuel interactif.
var late_game: Dictionary = {}
const ATTACK_MONTHS := 4
const ATTACK_PLAYER_BOOST := 1.20
const ATTACK_RIVAL_SHARE_FACTOR := 0.75
const ATTACK_RIVAL_SHARE_NO_REACTION := 0.62
var rng := RandomNumberGenerator.new()

func _ready():
	rng.seed = 43021

func reset():
	contracts = []
	tenders = []
	market_events = []
	market_threats = []
	_next_contract_id = 1
	_next_tender_id = 1
	_next_threat_id = 1
	_last_threat_market_age = 0
	market_age_months = 0
	attacks = []
	_next_attack_id = 1
	attack_advice_snooze_until = 0
	rival_offers = []
	acquisitions = []
	acquisition_boosts = []
	corporate_log = []
	offer_snooze = {}
	_next_offer_id = 1
	last_healthy_offer_age = 0
	last_entrant_age = 0
	strategic = {}
	late_game = {}
	competitors = {}
	for sector in GameData.SECTORS.keys():
		competitors[sector] = _make_competitors(str(sector))
	known_segments = available_segment_keys()
	for segment_value in known_segments:
		var segment := str(segment_value)
		market_events.append({
			"type":"MARKET_BASE",
			"segment":segment,
			"year":TimeManager.year,
			"month":TimeManager.month,
			"text":"Marché actif : %s." % segment_label(segment)
		})
	market_changed.emit()

func _make_competitors(sector: String) -> Array:
	if sector != "CPU":
		var sd: Dictionary = GameData.SECTORS[sector]
		var ref_price := float(sd.reference_price)
		return [
			{"name":"Aster %s" % sector,"company":"Aster Systems","price":int(ref_price*0.82),"metrics":_metrics(58,64,64,58,52,55,55),"sector":sector},
			{"name":"Helix %s Pro" % sector,"company":"Helix Global","price":int(ref_price*1.22),"metrics":_metrics(68,61,69,65,68,66,58),"sector":sector},
			{"name":"Quantum %s" % sector,"company":"Quantum Works","price":int(ref_price*1.01),"metrics":_metrics(64,67,66,62,63,60,62),"sector":sector}
		]
	var rows: Array = []
	for archetype_value in COMPETITOR_ARCHETYPES.keys():
		var archetype := str(archetype_value)
		var data: Dictionary = COMPETITOR_ARCHETYPES[archetype]
		var competitor := {
			"id":archetype,
			"sector":"CPU",
			"company":str(data.company),
			"product_prefix":str(data.product_prefix),
			"name":"%s 1" % str(data.product_prefix),
			"strategy":str(data.strategy),
			"cash":int(data.cash),
			"architecture_skill":float(data.architecture),
			"layout_skill":float(data.layout),
			"miniaturization_skill":float(data.miniaturization),
			"manufacturing_skill":float(data.manufacturing),
			"integration_skill":float(data.integration),
			"brand":float(data.brand),
			"risk_tolerance":float(data.risk_tolerance),
			"ai_price_aggression":float(data.get("ai_price_aggression", 50.0)),
			"ai_research_drive":float(data.get("ai_research_drive", 50.0)),
			"ai_financial_prudence":float(data.get("ai_financial_prudence", 50.0)),
			"ai_adaptability":float(data.get("ai_adaptability", 50.0)),
			"ai_growth_drive":float(data.get("ai_growth_drive", 50.0)),
			"generation_index":1,
			"development_progress":rng.randf_range(6.0, 28.0),
			"months_on_market":0,
			"node_nm":10000,
			"yield_rate":0.61,
			"defect_rate":0.035,
			"capacity":int(data.capacity),
			"unit_cost":72,
			"price":110,
			"target_segment":"EMBEDDED",
			"metrics":{},
			"history":[],
			"last_month_units":0,
			"last_month_profit":0,
			"restructurings":0,
			"ai_sourcing_generation":-1,
			"ai_sourcing_mode":"",
			"ai_supplier_id":"",
			"ai_supplier_name":"",
			"ai_supplier_speed_factor":1.0,
			"ai_supplier_quality_factor":1.0,
			"ai_supplier_unit_cost_factor":1.0,
			"ai_supplier_knowledge_factor":1.0,
			"ai_supplier_monthly_fee":0,
			"ai_supplier_public":false,
			"public_generation_partner":"",
			"b2b_contracts":[],
			"last_month_b2b_units":0,
			"last_month_b2b_profit":0
		}
		CompanyAIManager.ensure_company_state(competitor)
		_configure_competitor_product(competitor, true)
		rows.append(competitor)
	return rows

func _metrics(perf: float, eff: float, rel: float, use: float, innov: float, eco: float, sustain: float) -> Dictionary:
	return {"performance":perf,"efficiency":eff,"reliability":rel,"usability":use,"innovation":innov,"ecosystem":eco,"sustainability":sustain}

func segment_label(segment: String) -> String:
	return str(GameData.SEGMENTS.get(segment, {}).get("label", segment.capitalize()))

func is_legacy_segment(segment: String) -> bool:
	return bool(GameData.SEGMENTS.get(segment, {}).get("legacy", false))

func market_technology_signal() -> float:
	var cpu_tech := float(ResearchManager.technologies.get("cpu", 18.0))
	var capabilities := ResearchManager.get_cpu_capabilities()
	var capability_avg := (
		float(capabilities.get("ARCHITECTURE", 18.0))
		+ float(capabilities.get("LAYOUT", 14.0))
		+ float(capabilities.get("MINIATURIZATION", 12.0))
	) / 3.0
	var player_signal := cpu_tech * 0.48 + capability_avg * 0.52
	var competitor_signal := 0.0
	for competitor in competitors.get("CPU", []):
		competitor_signal = maxf(competitor_signal, _competitor_technology_signal(competitor))
	return maxf(player_signal, competitor_signal)

func _competitor_technology_signal(competitor: Dictionary) -> float:
	return (
		float(competitor.get("architecture_skill", 20.0)) * 0.34
		+ float(competitor.get("layout_skill", 20.0)) * 0.18
		+ float(competitor.get("miniaturization_skill", 20.0)) * 0.22
		+ float(competitor.get("manufacturing_skill", 20.0)) * 0.18
		+ float(competitor.get("integration_skill", 20.0)) * 0.08
	)

func is_segment_available(segment: String) -> bool:
	if not MARKET_NEEDS.has(segment):
		return false
	var need: Dictionary = MARKET_NEEDS[segment]
	if int(need.historical_year) <= 1971 or known_segments.has(segment):
		return true
	# Équilibrage (28/09) : une avance technologique fait émerger un besoin plus tôt,
	# mais pas des décennies avant (mesure : datacenters vendus dès 1977, historique 2002).
	if TimeManager.year < int(need.historical_year) - MAX_EARLY_NEED_YEARS:
		return false
	return TimeManager.year >= int(need.historical_year) or market_technology_signal() >= float(need.tech_trigger)

func available_segment_keys() -> Array:
	var result: Array = []
	for segment in MARKET_NEED_ORDER:
		if is_segment_available(str(segment)):
			result.append(str(segment))
	return result

func default_segment() -> String:
	var available := available_segment_keys()
	if available.has("EMBEDDED"):
		return "EMBEDDED"
	return str(available[0]) if not available.is_empty() else "CALCULATOR"

func normalize_segment(segment: String) -> String:
	if MARKET_NEEDS.has(segment):
		return segment
	match segment:
		"BUDGET":
			return "CALCULATOR"
		"MAINSTREAM":
			return "HOME_PC" if is_segment_available("HOME_PC") else "EMBEDDED"
		"ENTHUSIAST":
			if is_segment_available("GAMING"):
				return "GAMING"
			if is_segment_available("HOBBYIST"):
				return "HOBBYIST"
			if is_segment_available("SCIENTIFIC"):
				return "SCIENTIFIC"
			return default_segment()
		"PRO":
			if is_segment_available("BUSINESS_PC"):
				return "BUSINESS_PC"
			if is_segment_available("SCIENTIFIC"):
				return "SCIENTIFIC"
			return default_segment()
		"ENTERPRISE":
			return "SERVER" if is_segment_available("SERVER") else "INDUSTRIAL"
		"PREMIUM":
			if is_segment_available("WORKSTATION"):
				return "WORKSTATION"
			if is_segment_available("SCIENTIFIC"):
				return "SCIENTIFIC"
			return default_segment()
	return default_segment()

func segment_project_scale(segment: String) -> Dictionary:
	var normalized := normalize_segment(segment)
	return SEGMENT_PROJECT_SCALE.get(normalized, {"team":3,"budget":45000,"market_scale":1.0}).duplicate(true)

func segment_required_team(segment: String) -> int:
	return maxi(int(segment_project_scale(segment).get("team", 3)), 1)

func segment_recommended_budget(segment: String) -> int:
	return maxi(int(segment_project_scale(segment).get("budget", 45000)), 10000)

func segment_team_factor(segment: String, developers: int) -> float:
	var required := float(segment_required_team(segment))
	var ratio := maxf(float(maxi(developers, 0)) / required, 0.01)
	return clampf(pow(ratio, 0.60), 0.40, 1.20)

func segment_budget_factor(segment: String, monthly_budget: int) -> float:
	var recommended := float(segment_recommended_budget(segment))
	var ratio := maxf(float(maxi(monthly_budget, 0)) / recommended, 0.01)
	return clampf(pow(ratio, 0.50), 0.55, 1.12)

func active_market_threats() -> Array:
	var result: Array = []
	for threat_value in market_threats:
		var threat: Dictionary = threat_value
		if int(threat.get("remaining_months", 0)) > 0 and str(threat.get("status", "")) in ["OPEN", "MITIGATED", "IGNORED"]:
			result.append(threat)
	return result

func open_market_threats() -> Array:
	var result: Array = []
	for threat_value in market_threats:
		var threat: Dictionary = threat_value
		if str(threat.get("status", "")) == "OPEN":
			result.append(threat)
	return result

func get_market_threat(threat_id: String) -> Dictionary:
	for threat_value in market_threats:
		var threat: Dictionary = threat_value
		if str(threat.get("id", "")) == threat_id:
			return threat
	return {}

func market_threat_demand_factor() -> float:
	var factor := 1.0
	for threat_value in active_market_threats():
		var threat: Dictionary = threat_value
		var mitigated := str(threat.get("status", "")) == "MITIGATED"
		factor *= float(threat.get("mitigated_demand_factor" if mitigated else "demand_factor", 1.0))
	return clampf(factor, 0.52, 1.0)

func production_cost_threat_factor() -> float:
	var factor := 1.0
	for threat_value in active_market_threats():
		var threat: Dictionary = threat_value
		var mitigated := str(threat.get("status", "")) == "MITIGATED"
		factor *= float(threat.get("mitigated_cost_factor" if mitigated else "cost_factor", 1.0))
	factor *= LATE_GAME.production_cost_factor()
	return clampf(factor, 0.82, 1.65)

func threat_response_cost(threat_id: String) -> int:
	return int(get_market_threat(threat_id).get("response_cost", 0))

func threat_ignore_cost(threat_id: String) -> int:
	return int(get_market_threat(threat_id).get("ignore_cost", 0))

## Coût d'une menace : un minimum par époque, mais surtout proportionnel à la taille de l'entreprise.
## (Claude, 29/09 : à coût fixe, 40 000 € ne comptaient pas face aux 22 M€ d'une partie de 1985.)
func _scaled_threat_cost(base_cost: int, revenue_months: float = 0.0) -> int:
	var era_scale := clampf(1.0 + maxf(float(TimeManager.year - 1975), 0.0) * 0.025, 1.0, 2.1)
	var floor_cost := float(base_cost) * era_scale
	var revenue_cost := _recent_monthly_revenue() * revenue_months
	return maxi(1000, int(round(maxf(floor_cost, revenue_cost))))

func _recent_monthly_revenue() -> float:
	if Economy.history.is_empty():
		return float(Economy.monthly_income)
	var total := 0.0
	var count := 0
	for i in range(maxi(Economy.history.size() - 3, 0), Economy.history.size()):
		total += float((Economy.history[i] as Dictionary).get("income", 0))
		count += 1
	return total / float(maxi(count, 1))

func _spawn_market_threat(kind: String = "") -> Dictionary:
	var selected := kind
	if selected == "" or not MARKET_THREAT_TEMPLATES.has(selected):
		selected = str(MARKET_THREAT_ORDER[(_next_threat_id - 1) % MARKET_THREAT_ORDER.size()])
	var template: Dictionary = MARKET_THREAT_TEMPLATES[selected]
	var threat := {
		"id":"THREAT-%03d" % _next_threat_id,
		"kind":selected,
		"title":str(template.get("title", "Menace marché")),
		"text":str(template.get("text", "Le marché se tend.")),
		"status":"OPEN",
		"year":TimeManager.year,
		"month":TimeManager.month,
		"age_months":0,
		"decision_deadline_months":3,
		"remaining_months":int(template.get("duration", 12)),
		"response_cost":_scaled_threat_cost(int(template.get("response", 20000)), 0.45),
		"ignore_cost":_scaled_threat_cost(int(template.get("ignore", 50000)), 1.2),
		"demand_factor":float(template.get("demand", 0.90)),
		"mitigated_demand_factor":float(template.get("mitigated_demand", 0.97)),
		"cost_factor":float(template.get("cost", 1.0)),
		"mitigated_cost_factor":float(template.get("mitigated_cost", 1.0)),
		"penalty_applied":false
	}
	_next_threat_id += 1
	_last_threat_market_age = market_age_months
	market_threats.push_front(threat)
	if selected == "NEW_ENTRANT":
		_add_new_market_entrant()
	market_events.push_front({"type":"MARKET_THREAT","threat_id":str(threat.id),"year":TimeManager.year,"month":TimeManager.month,"text":str(threat.title)})
	if market_events.size() > 32:
		market_events.pop_back()
	CompanyManager.add_alert("Menace marché : %s. Nora attend votre décision." % str(threat.title))
	MediaManager.publish_business_event("Marché sous tension", "%s %s" % [str(threat.title), str(threat.text)], "MARKET_THREAT:%s" % selected)
	market_changed.emit()
	return threat

func _add_new_market_entrant() -> void:
	for competitor_value in competitors.get("CPU", []):
		if str((competitor_value as Dictionary).get("id", "")) == "NEXUS_ENTRANT":
			return
	# Lot F1 : une société rachetée ou disparue ne renaît pas sous le même nom.
	for entry_value in corporate_log:
		if str((entry_value as Dictionary).get("company", "")) == "Nexus Micro":
			return
	var era := era_technology_ceiling()
	var entrant := {
		"id":"NEXUS_ENTRANT","sector":"CPU","company":"Nexus Micro","product_prefix":"Nexus",
		"strategy":"BALANCED","cash":520000,"architecture_skill":clampf(era + 5.0, 28.0, 99.0),
		"layout_skill":clampf(era + 3.0, 26.0, 98.0),"miniaturization_skill":clampf(era + 4.0, 25.0, 99.0),
		"manufacturing_skill":clampf(era + 2.0, 26.0, 98.0),"integration_skill":clampf(era + 4.0, 26.0, 99.0),
		"brand":46.0,"risk_tolerance":68.0,"ai_price_aggression":68.0,"ai_research_drive":76.0,
		"ai_financial_prudence":52.0,"ai_adaptability":82.0,"ai_growth_drive":78.0,
		"generation_index":1,"development_progress":18.0,"months_on_market":0,"node_nm":10000,
		"capacity":10000,"unit_cost":70,"price":110,"target_segment":"EMBEDDED","metrics":{},"history":[]
	}
	entrant = _migrate_competitor(entrant, "CPU")
	entrant["born_age"] = market_age_months
	_configure_competitor_product(entrant, true)
	competitors["CPU"].append(entrant)

func resolve_market_threat(threat_id: String, mitigate: bool) -> bool:
	var threat := get_market_threat(threat_id)
	if threat.is_empty() or str(threat.get("status", "")) != "OPEN":
		return false
	var cost := int(threat.get("response_cost" if mitigate else "ignore_cost", 0))
	if mitigate and not Economy.can_afford(cost):
		return false
	if cost > 0:
		Economy.add_expense(cost, ("Réponse crise — " if mitigate else "Impact menace — ") + str(threat.get("title", "Marché")))
	threat["status"] = "MITIGATED" if mitigate else "IGNORED"
	threat["penalty_applied"] = not mitigate
	if not mitigate:
		CompanyManager.change_reputation({"professional":-1.2,"prestige":-0.5})
		if str(threat.get("kind", "")) == "PATENT_LAWSUIT":
			CompanyManager.change_reputation({"innovation":-1.6,"professional":-0.8})
	var result_text := "Plan de réponse financé" if mitigate else "Menace laissée sans réponse"
	CompanyManager.add_alert("%s : %s (%d €)." % [str(threat.get("title", "Menace")), result_text, cost])
	MediaManager.publish_business_event(str(threat.get("title", "Marché")), "%s. L'impact continuera encore %d mois." % [result_text, int(threat.get("remaining_months", 0))], "MARKET_THREAT_RESOLUTION:%s" % str(threat.get("kind", "")))
	market_changed.emit()
	return true

func _advance_market_threats() -> void:
	for threat_value in market_threats:
		var threat: Dictionary = threat_value
		if int(threat.get("remaining_months", 0)) <= 0:
			continue
		threat["age_months"] = int(threat.get("age_months", 0)) + 1
		threat["remaining_months"] = maxi(int(threat.get("remaining_months", 0)) - 1, 0)
		if str(threat.get("status", "")) == "OPEN" and int(threat.get("age_months", 0)) >= int(threat.get("decision_deadline_months", 3)):
			resolve_market_threat(str(threat.get("id", "")), false)
		if int(threat.get("remaining_months", 0)) <= 0:
			threat["status"] = "EXPIRED"
			CompanyManager.add_alert("Fin de crise : %s ne pèse plus directement sur le marché." % str(threat.get("title", "la menace")))

func _maybe_spawn_market_threat() -> void:
	if TimeManager.year < 1975 or ProductManager.products.is_empty():
		return
	if market_age_months - _last_threat_market_age < 48:
		return
	if not open_market_threats().is_empty():
		return
	_spawn_market_threat()

func segment_lifecycle_factor(segment: String) -> float:
	var normalized := normalize_segment(segment)
	if not MARKET_NEEDS.has(normalized):
		return 0.0
	var need: Dictionary = MARKET_NEEDS[normalized]
	var profile: Dictionary = SEGMENT_LIFECYCLE.get(normalized, {"growth_years":12.0,"plateau_years":18.0,"decline_years":24.0,"floor":0.65})
	var age_years := maxf(float(TimeManager.year - int(need.historical_year)), 0.0)
	var decline_start := float(profile.get("growth_years", 12.0)) + float(profile.get("plateau_years", 18.0))
	if age_years <= decline_start:
		return 1.0
	var decline_span := maxf(float(profile.get("decline_years", 24.0)), 1.0)
	var decline_t := clampf((age_years - decline_start) / decline_span, 0.0, 1.0)
	return lerpf(1.0, float(profile.get("floor", 0.65)), decline_t)

func segment_market_units(segment: String) -> int:
	var normalized := normalize_segment(segment)
	if not MARKET_NEEDS.has(normalized) or not is_segment_available(normalized):
		return 0
	var need: Dictionary = MARKET_NEEDS[normalized]
	var profile: Dictionary = SEGMENT_LIFECYCLE.get(normalized, {"growth_years":12.0})
	var years_since_anchor := maxi(TimeManager.year - int(need.historical_year), 0)
	var growth_years := minf(float(years_since_anchor), float(profile.get("growth_years", 12.0)))
	var maturity_growth := 1.0 + minf(growth_years * float(need.growth), 2.25)
	var tech_surplus := maxf(market_technology_signal() - float(need.tech_trigger), 0.0)
	var tech_growth := 1.0 + minf(tech_surplus * 0.010, 0.85)
	var lifecycle := segment_lifecycle_factor(normalized)
	var project_scale := float(segment_project_scale(normalized).get("market_scale", 1.0))
	return maxi(500, int(round(float(need.base_units) * project_scale * maturity_growth * tech_growth * lifecycle * BalanceManager.market_demand_factor() * market_threat_demand_factor() * LATE_GAME.segment_demand_factor(normalized))))

func segment_reference_price(segment: String, sector: String = "CPU") -> float:
	var normalized := normalize_segment(segment)
	var sd: Dictionary = GameData.SECTORS.get(sector, GameData.SECTORS.CPU)
	var need: Dictionary = MARKET_NEEDS.get(normalized, MARKET_NEEDS.EMBEDDED)
	return float(sd.reference_price) * float(need.price_factor)

func market_landscape() -> Array:
	var rows: Array = []
	for segment_value in available_segment_keys():
		var segment := str(segment_value)
		var need: Dictionary = MARKET_NEEDS[segment]
		rows.append({
			"segment":segment,
			"label":segment_label(segment),
			"units":segment_market_units(segment),
			"reference_price":int(round(segment_reference_price(segment))),
			"description":str(need.description),
			"historical_year":int(need.historical_year),
			"tech_trigger":float(need.tech_trigger)
		})
	return rows

func next_market_needs() -> Array:
	var rows: Array = []
	for segment in MARKET_NEED_ORDER:
		var key := str(segment)
		if is_segment_available(key):
			continue
		var need: Dictionary = MARKET_NEEDS[key]
		rows.append({
			"segment":key,
			"label":segment_label(key),
			"historical_year":int(need.historical_year),
			"tech_trigger":float(need.tech_trigger),
			"description":str(need.description)
		})
		if rows.size() >= 3:
			break
	return rows

func price_score(product: Dictionary, segment: String = "") -> float:
	var target := normalize_segment(segment if segment != "" else str(product.get("target_segment", default_segment())))
	var reference := segment_reference_price(target, str(product.get("sector", "CPU")))
	var ratio: float = float(product.get("price", 1)) / maxf(reference, 1.0)
	return clampf(118.0 - ratio * 58.0, 5.0, 100.0)

func price_demand_multiplier(product: Dictionary, segment: String = "") -> float:
	# Le score de prix mesure l'attractivité, mais ne suffit pas à modéliser
	# l'élasticité réelle. Un produit à 3–5x le prix du marché doit perdre
	# presque toute sa demande, même s'il est techniquement excellent.
	var target := normalize_segment(segment if segment != "" else str(product.get("target_segment", default_segment())))
	var reference := maxf(segment_reference_price(target, str(product.get("sector", "CPU"))), 1.0)
	var ratio := float(product.get("price", 1)) / reference
	if ratio <= 0.75:
		return 1.12
	if ratio <= 1.0:
		return lerpf(1.08, 1.0, (ratio - 0.75) / 0.25)
	if ratio <= 1.25:
		return lerpf(1.0, 0.72, (ratio - 1.0) / 0.25)
	if ratio <= 1.50:
		return lerpf(0.72, 0.38, (ratio - 1.25) / 0.25)
	if ratio <= 2.0:
		return lerpf(0.38, 0.10, (ratio - 1.50) / 0.50)
	if ratio <= 3.0:
		return lerpf(0.10, 0.015, ratio - 2.0)
	if ratio <= 5.0:
		return lerpf(0.015, 0.001, (ratio - 3.0) / 2.0)
	return 0.0005

func evaluate_product(product: Dictionary, segment: String) -> float:
	var target := normalize_segment(segment)
	var weights: Dictionary = GameData.SEGMENTS[target].weights
	var score := 0.0
	for metric in GameData.METRICS:
		score += float(product.get("metrics", {}).get(metric, 50.0)) * float(weights.get(metric, 0.0))
	score += price_score(product, target) * float(weights.get("price", 0.0))
	var is_player := str(product.get("company", "")) == CompanyManager.company_name
	var brand_bonus := (CompanyManager.get_brand_score() - 50.0) * 0.08 if is_player else 0.0
	var support_bonus := (float(CompanyManager.reputation.support) - 50.0) * 0.05 if is_player else 0.0
	var promotion_bonus := float(product.get("promotion_bonus", 0.0)) * 0.65 if is_player else 0.0
	var software_bonus := 0.0
	var software_value = product.get("control_software", {})
	if typeof(software_value) == TYPE_DICTIONARY and bool(software_value.get("released", false)):
		software_bonus = minf(float(software_value.get("quality", 0.0)) * 0.045, 4.5)
	var die_bonus := 0.0
	if str(product.get("sector", "")) == "CPU":
		var oc_headroom := float(product.get("oc_headroom_pct", 0.0))
		var undervolt := float(product.get("undervolt_headroom_pct", 0.0))
		var consistency := float(product.get("die_consistency", product.get("silicon_consistency", 50.0)))
		match target:
			"GAMING", "HOBBYIST":
				die_bonus = clampf(oc_headroom * 0.28 + (consistency - 50.0) * 0.035, -2.0, 8.0)
			"WORKSTATION", "SERVER", "DATACENTER", "INDUSTRIAL":
				die_bonus = clampf(undervolt * 0.12 + (consistency - 50.0) * 0.040, -2.0, 5.0)
			_:
				die_bonus = clampf((consistency - 50.0) * 0.018, -1.5, 2.5)
	return clampf(score + brand_bonus + support_bonus + promotion_bonus + software_bonus + die_bonus, 0.0, 100.0)

func segment_scores(product: Dictionary) -> Dictionary:
	var result := {}
	for segment_value in available_segment_keys():
		var segment := str(segment_value)
		result[segment] = evaluate_product(product, segment)
	return result

func benchmark_score(product: Dictionary) -> float:
	var m: Dictionary = product.get("metrics", {})
	var sector := str(product.get("sector", "CPU"))
	if sector == "SOFTWARE":
		return float(m.get("usability", 50.0))*0.28 + float(m.get("reliability", 50.0))*0.24 + float(m.get("performance", 50.0))*0.16 + float(m.get("innovation", 50.0))*0.16 + float(m.get("ecosystem", 50.0))*0.16
	var score := float(m.get("performance", 50.0))*0.34 + float(m.get("efficiency", 50.0))*0.22 + float(m.get("reliability", 50.0))*0.18 + float(m.get("innovation", 50.0))*0.16 + float(m.get("sustainability", 50.0))*0.10
	if sector == "CPU":
		var fallback_headroom := clampf((float(m.get("performance", 50.0)) - 55.0) * 0.09, 0.0, 8.0)
		var headroom := float(product.get("oc_headroom_pct", fallback_headroom))
		var consistency := float(product.get("die_consistency", product.get("silicon_consistency", m.get("reliability", 50.0))))
		score += clampf(headroom * 0.12 + (consistency - 50.0) * 0.015, -1.0, 3.5)
	return score

func benchmark_for(product: Dictionary) -> Array:
	var rows: Array = []
	rows.append({"name":product.get("name", "Votre produit"),"company":product.get("company", CompanyManager.company_name),"score":benchmark_score(product),"price":product.get("price", 0),"player":true})
	for comp in competitors.get(str(product.get("sector", "CPU")), []):
		rows.append({
			"name":str(comp.get("name", "Concurrent")),
			"company":str(comp.get("company", "")),
			"score":benchmark_score(comp),
			"price":int(comp.get("price", 0)),
			"player":false
		})
	rows.sort_custom(func(a, b): return float(a.score) > float(b.score))
	return rows

func benchmark_rank(product: Dictionary) -> int:
	var rows := benchmark_for(product)
	for i in range(rows.size()):
		if bool(rows[i].player):
			return i + 1
	return rows.size()

func press_comparison(product: Dictionary) -> Dictionary:
	var current_score := benchmark_score(product)
	var sector := str(product.get("sector", "CPU"))
	var target := normalize_segment(str(product.get("target_segment", default_segment())))
	var generation_id := str(product.get("generation_id", ""))
	var generation_index := int(product.get("generation_index", 0))
	var previous: Dictionary = {}
	var previous_generation := -1
	var previous_age := 999999
	for candidate_value in ProductManager.products:
		var candidate: Dictionary = candidate_value
		if str(candidate.get("id", "")) == str(product.get("id", "")) or str(candidate.get("sector", "")) != sector:
			continue
		if str(candidate.get("company", "")) != CompanyManager.company_name:
			continue
		if generation_id != "" and str(candidate.get("generation_id", "")) == generation_id:
			continue
		var candidate_generation := int(candidate.get("generation_index", 0))
		var candidate_age := maxi(int(candidate.get("months_on_market", 0)), 0)
		if generation_index > 0 and candidate_generation > 0:
			if candidate_generation >= generation_index or candidate_generation <= previous_generation:
				continue
			previous = candidate
			previous_generation = candidate_generation
		elif previous_generation < 0 and candidate_age > 0 and candidate_age < previous_age:
			previous = candidate
			previous_age = candidate_age

	var rival_pool: Array = []
	for rival_value in competitors.get(sector, []):
		var rival: Dictionary = rival_value
		if normalize_segment(str(rival.get("target_segment", target))) == target:
			rival_pool.append(rival)
	if rival_pool.is_empty():
		rival_pool = competitors.get(sector, []).duplicate()
	var best_rival: Dictionary = {}
	var best_rival_score := -1.0
	for rival_value in rival_pool:
		var rival: Dictionary = rival_value
		var rival_score := benchmark_score(rival)
		if rival_score > best_rival_score:
			best_rival = rival
			best_rival_score = rival_score

	var result := {"current_score":current_score,"has_previous":not previous.is_empty(),"has_rival":not best_rival.is_empty()}
	if not previous.is_empty():
		var previous_score := benchmark_score(previous)
		result.merge({"previous_name":str(previous.get("name", "Ancienne génération")),"previous_score":previous_score,"previous_delta":current_score-previous_score})
	if not best_rival.is_empty():
		result.merge({"rival_name":str(best_rival.get("name", "Concurrent")),"rival_company":str(best_rival.get("company", "")),"rival_score":best_rival_score,"rival_delta":current_score-best_rival_score})
	return result

func _segment_expectation_drift(segment: String) -> float:
	var target := normalize_segment(segment)
	var base := 0.08
	match target:
		"GAMING":
			base = 0.20
		"WORKSTATION":
			base = 0.17
		"SERVER", "DATACENTER":
			base = 0.15
		"HOBBYIST":
			base = 0.14
		"CALCULATOR":
			base = 0.06
		_:
			base = 0.10
	return minf(float(market_age_months) * base, 18.0)

func product_age_penalty(product: Dictionary) -> float:
	var age_months := maxi(int(product.get("months_on_market", 0)), 0)
	if age_months <= 12:
		return 0.0
	var monthly_penalty := 0.44
	match normalize_segment(str(product.get("target_segment", default_segment()))):
		"CALCULATOR", "INDUSTRIAL":
			monthly_penalty = 0.28
		"GAMING":
			monthly_penalty = 0.72
		"WORKSTATION":
			monthly_penalty = 0.58
		"SERVER", "DATACENTER":
			monthly_penalty = 0.42
		"HOBBYIST":
			monthly_penalty = 0.58
		_:
			monthly_penalty = 0.44
	return minf(float(age_months - 12) * monthly_penalty, 24.0)

## Cycle commercial M1 : lancement fort, plateau, maturité, déclin puis fin réelle.
## À huit ans, un produit grand public n'alimente plus les ventes courantes ; les
## contrats B2B déjà signés restent gérés séparément par leur propre durée.
func product_lifecycle_factor(product: Dictionary) -> float:
	var age_months := maxi(int(product.get("months_on_market", 0)), 0)
	if age_months <= 2:
		return lerpf(1.25, 1.15, float(age_months) / 2.0)
	if age_months <= 12:
		return lerpf(1.12, 1.0, float(age_months - 3) / 9.0)
	if age_months <= 24:
		return lerpf(1.0, 0.90, float(age_months - 12) / 12.0)
	if age_months <= 36:
		return lerpf(0.90, 0.72, float(age_months - 24) / 12.0)
	if age_months <= 60:
		return lerpf(0.72, 0.32, float(age_months - 36) / 24.0)
	if age_months <= 84:
		return lerpf(0.32, 0.08, float(age_months - 60) / 24.0)
	if age_months <= 96:
		return lerpf(0.08, 0.0, float(age_months - 84) / 12.0)
	return 0.0

func obsolescence_factor(product: Dictionary) -> float:
	return product_lifecycle_factor(product)

func product_lifecycle_label(product: Dictionary) -> String:
	var age_months := maxi(int(product.get("months_on_market", 0)), 0)
	if age_months <= 3:
		return "Lancement"
	if age_months <= 18:
		return "En rythme"
	if age_months <= 36:
		return "Mature"
	if age_months <= 60:
		return "En déclin"
	if age_months <= 96:
		return "Fin de série"
	return "Retiré du marché"

func _rival_pressure(product: Dictionary, segment: String, player_score: float) -> Dictionary:
	var sector := str(product.get("sector", "CPU"))
	var best_score := -1.0
	var best_age := 999
	var best_name := ""
	var best_company := ""
	var same_segment_found := false
	for comp_value in competitors.get(sector, []):
		var comp: Dictionary = comp_value
		var comp_segment := normalize_segment(str(comp.get("target_segment", segment)))
		if comp_segment == segment:
			same_segment_found = true
	for comp_value in competitors.get(sector, []):
		var comp: Dictionary = comp_value
		var comp_segment := normalize_segment(str(comp.get("target_segment", segment)))
		if same_segment_found and comp_segment != segment:
			continue
		var rival_score := _evaluate_competitor(comp, segment)
		if rival_score > best_score:
			best_score = rival_score
			best_age = maxi(int(comp.get("months_on_market", 0)), 0)
			best_name = str(comp.get("name", "CPU concurrent"))
			best_company = str(comp.get("company", "Concurrent"))
	var gap := maxf(best_score - player_score, 0.0)
	var recency := 1.0
	if best_age <= 2:
		recency = 1.35
	elif best_age <= 8:
		recency = 1.20
	elif best_age <= 18:
		recency = 1.08
	var multiplier := 1.0
	if best_score >= 0.0:
		multiplier = clampf(1.0 - gap * 0.018 * recency, 0.48, 1.0)
	return {"score":best_score,"age_months":best_age,"multiplier":multiplier,"name":best_name,"company":best_company}

func estimate_consumer_demand(product: Dictionary) -> Dictionary:
	var target := normalize_segment(str(product.get("target_segment", default_segment())))
	if not is_segment_available(target):
		return {"units":0,"score":0.0,"raw_score":0.0,"age_penalty":0.0,"lifecycle":product_lifecycle_label(product),"competitor_avg":0.0,"share":0.0,"expectation_gap":-50.0}
	var market_units := segment_market_units(target)
	var raw_score := evaluate_product(product, target)
	var age_penalty := product_age_penalty(product)
	var score := clampf(raw_score - age_penalty, 0.0, 100.0)
	var competitor_avg := 0.0
	var competitor_count := 0
	for comp in competitors.get(str(product.get("sector", "CPU")), []):
		competitor_avg += _evaluate_competitor(comp, target)
		competitor_count += 1
	competitor_avg /= maxf(float(competitor_count), 1.0)
	var awareness := CompanyManager.get_awareness_bonus()
	# Une jeune marque ne récupère plus automatiquement 7 % du marché.
	# L'avantage produit et la notoriété peuvent construire la part de marché,
	# tandis que le prix applique ensuite une vraie élasticité sur les unités.
	var raw_share: float = clampf(0.012 + (score - competitor_avg) * 0.0025 + awareness * 0.20, 0.0005, 0.28)
	# Une entreprise jeune ne peut pas transformer trois r?f?rences d'une m?me gamme
	# en trois parts de march? ind?pendantes. La notori?t? et la r?putation font
	# monter progressivement ce plafond au fil de la partie.
	if str(product.get("company", "")) == CompanyManager.company_name:
		raw_share = minf(raw_share, _player_portfolio_share_cap())
	var price_multiplier := price_demand_multiplier(product, target)
	var media_multiplier := MediaManager.product_visibility_modifier(str(product.get("id", "")))
	var lifecycle_multiplier := product_lifecycle_factor(product)
	var rival_pressure := _rival_pressure(product, target, score)
	var rival_multiplier := float(rival_pressure.get("multiplier", 1.0))
	var scale_fit := company_scale_fit(target) if str(product.get("company", "")) == CompanyManager.company_name else 1.0
	var attack_multiplier := attack_demand_factor(product) * RIVAL_LIFE.acquisition_demand_factor(product) * CompanyManager.SUBSIDIARIES.captive_demand_factor(product)
	var late_game_multiplier := LATE_GAME.player_demand_factor(product)
	var technology_multiplier := product_technology_factor(product)
	var units := maxi(0, int(round(float(market_units) * raw_share * price_multiplier * media_multiplier * lifecycle_multiplier * rival_multiplier * scale_fit * attack_multiplier * late_game_multiplier * technology_multiplier)))
	var share := float(units) / maxf(float(market_units), 1.0)
	var expectation: float = 48.0 + _segment_expectation_drift(target) + CompanyManager.get_awareness_bonus()*32.0 + maxf((float(product.get("price", 1))/maxf(segment_reference_price(target),1.0)-1.0)*18.0, 0.0)
	var gap := score - expectation
	return {
		"units":units,"score":score,"raw_score":raw_score,"age_penalty":age_penalty,
		"lifecycle":product_lifecycle_label(product),"competitor_avg":competitor_avg,"share":share,
		"raw_share":raw_share,"price_demand_multiplier":price_multiplier,"media_demand_multiplier":media_multiplier,
		"lifecycle_multiplier":lifecycle_multiplier,"rival_pressure_multiplier":rival_multiplier,
		"best_rival_score":float(rival_pressure.get("score", -1.0)),"best_rival_age_months":int(rival_pressure.get("age_months", 999)),
		"best_rival_name":str(rival_pressure.get("name", "")),"best_rival_company":str(rival_pressure.get("company", "")),
		"expectation_gap":gap,"promotion_bonus":float(product.get("promotion_bonus", 0.0)),
		"software_supported":bool(product.get("control_software", {}).get("released", false)),
		"segment":target,"market_units":market_units,"company_scale_fit":scale_fit,"attack_multiplier":attack_multiplier,
		"late_game_multiplier":late_game_multiplier,"technology_multiplier":technology_multiplier
	}

## Lot M (Claude, 29/09) : sonde 40 ans — une entreprise de 8 à 10 personnes atteignait 1 milliard d'euros
## en visant les grands marchés (datacenter ×8) sans jamais embaucher. Les grands clients jugent aussi la
## taille de l'équipe qui conçoit et suit leurs CPU : en sous-effectif, une partie des ventes ne se fait pas.
func company_scale_fit(segment: String) -> float:
	var required := float(segment_required_team(segment))
	var team := float(maxi(ResearchManager.get_development_team_size(), 1))
	if team >= required:
		return 1.0
	return clampf(pow(team / required, 0.6), 0.30, 1.0)

## V0.10 / H1 (Claude, 30/09) : une jeune marque ne vend pas en direct. Les distributeurs gardent une part
## du prix des ventes grand public (pas des contrats B2B, négociés en direct). Cette part baisse quand la marque
## grandit : réputation, notoriété, locaux plus grands (vraie équipe commerciale). Diagnostic : sans elle,
## une gamme de garage gardait 75-83 % de marge brute et rapportait ~60 k€/mois dès le premier mois.
const DISTRIBUTOR_BASE_SHARE := {"ACCESSIBLE":0.28, "STANDARD":0.35, "SIMULATION":0.38}
const DISTRIBUTOR_MIN_SHARE := 0.12

func distributor_share() -> float:
	var base := float(DISTRIBUTOR_BASE_SHARE.get(BalanceManager.active_profile, 0.35))
	var relief := maxf(CompanyManager.get_brand_score() - 45.0, 0.0) * 0.004
	relief += CompanyManager.get_awareness_bonus() * 0.25
	relief += float(int(ExecutiveManager.workplace.get("tier", 0))) * 0.025
	return clampf(base - relief, DISTRIBUTOR_MIN_SHARE, base)

func _player_portfolio_share_cap() -> float:
	var awareness := CompanyManager.get_awareness_bonus()
	var brand_score := CompanyManager.get_brand_score()
	# En garage, une marque inconnue plafonne autour de 3 % du besoin adress?.
	# Une entreprise reconnue peut d?passer ce niveau, mais doit le gagner par
	# la r?putation et la visibilit? plut?t que par le simple nombre de SKU.
	return clampf(
		0.026 + awareness * 0.18 + maxf(brand_score - 45.0, 0.0) * 0.0035,
		0.030,
		0.35
	)

func estimate_portfolio_demand(products: Array) -> Dictionary:
	var result := {}
	var ids_by_market := {}
	for product in products:
		var product_id := str(product.get("id", ""))
		if product_id.is_empty():
			continue
		var demand := estimate_consumer_demand(product)
		result[product_id] = demand
		var sector := str(product.get("sector", "CPU"))
		var segment := normalize_segment(str(product.get("target_segment", default_segment())))
		var key := "%s|%s" % [sector, segment]
		if not ids_by_market.has(key):
			ids_by_market[key] = []
		ids_by_market[key].append(product_id)

	for market_key_value in ids_by_market.keys():
		var market_key := str(market_key_value)
		var ids: Array = ids_by_market[market_key_value]
		var segment := market_key.get_slice("|", 1)
		var market_units := maxi(segment_market_units(segment), 1)
		var requested_units := 0
		var best_units := 0
		var best_id := ""
		var conversion_weight := 0.0
		var weighted_conversion := 0.0
		for product_id_value in ids:
			var product_id := str(product_id_value)
			var demand: Dictionary = result[product_id]
			var requested := int(demand.get("units", 0))
			requested_units += requested
			if requested > best_units:
				best_units = requested
				best_id = product_id
			# La part de marque est un plafond d'int?r?t. Le prix transforme ensuite
			# cet int?r?t en achats : augmenter toute la gamme doit r?duire la conversion.
			var weight := maxf(float(demand.get("raw_share", 0.001)), 0.001)
			conversion_weight += weight
			weighted_conversion += weight * float(demand.get("price_demand_multiplier", 1.0)) * float(demand.get("media_demand_multiplier", 1.0))

		# La largeur de gamme aide, mais trois bins ne triplent jamais la client?le.
		# Au maximum, deux r?f?rences suppl?mentaires apportent ~28 % au potentiel
		# du meilleur SKU avant application du plafond de marque.
		var breadth_factor := 1.0 + minf(float(maxi(ids.size() - 1, 0)) * 0.14, 0.35)
		var family_potential := int(round(float(best_units) * breadth_factor))
		var conversion := clampf(weighted_conversion / maxf(conversion_weight, 0.001), 0.05, 1.12)
		var share_cap_units := maxi(1, int(round(float(market_units) * _player_portfolio_share_cap() * conversion * attack_segment_boost(segment))))
		var portfolio_units := mini(requested_units, mini(family_potential, share_cap_units))
		var portfolio_share := float(portfolio_units) / float(market_units)

		var weight_total := 0.0
		for product_id_value in ids:
			weight_total += maxf(float(result[str(product_id_value)].get("units", 0)), 1.0)
		var allocated_total := 0
		for product_id_value in ids:
			var product_id := str(product_id_value)
			var demand: Dictionary = result[product_id]
			var original_units := int(demand.get("units", 0))
			var weight := maxf(float(original_units), 1.0)
			var allocated := int(floor(float(portfolio_units) * weight / maxf(weight_total, 1.0)))
			demand["units"] = allocated
			demand["share"] = float(allocated) / float(market_units)
			demand["portfolio_share"] = portfolio_share
			demand["portfolio_units"] = portfolio_units
			demand["portfolio_price_conversion"] = conversion
			demand["cannibalization_factor"] = float(allocated) / maxf(float(original_units), 1.0)
			demand["portfolio_limited"] = portfolio_units < requested_units
			allocated_total += allocated

		var remainder := maxi(portfolio_units - allocated_total, 0)
		if remainder > 0 and best_id != "":
			var best_demand: Dictionary = result[best_id]
			best_demand["units"] = int(best_demand.get("units", 0)) + remainder
			best_demand["share"] = float(best_demand.units) / float(market_units)

	return result

func _evaluate_competitor(product: Dictionary, segment: String) -> float:
	var target := normalize_segment(segment)
	var weights: Dictionary = GameData.SEGMENTS[target].weights
	var score := 0.0
	var metrics: Dictionary = product.get("metrics", {})
	for metric in GameData.METRICS:
		score += float(metrics.get(metric, 50.0)) * float(weights.get(metric, 0.0))
	var ratio := float(product.get("price", 1)) / maxf(segment_reference_price(target, str(product.get("sector", "CPU"))), 1.0)
	score += clampf(118.0 - ratio*58.0, 5.0, 100.0) * float(weights.get("price", 0.0))
	score += (float(product.get("brand", 50.0)) - 50.0) * 0.055
	if normalize_segment(str(product.get("target_segment", target))) != target:
		score -= 3.5
	return clampf(score, 0.0, 100.0)

func _advance_competitors() -> void:
	for sector_value in competitors.keys():
		var sector := str(sector_value)
		var rows: Array = competitors[sector_value]
		if sector != "CPU":
			continue
		for competitor in rows:
			_advance_cpu_competitor(competitor)
		competitors[sector_value] = rows

func _competitor_ai_context(competitor: Dictionary) -> Dictionary:
	var target := normalize_segment(str(competitor.get("target_segment", default_segment())))
	if not is_segment_available(target):
		target = _choose_competitor_segment(competitor)
	var capacity := maxi(int(competitor.get("capacity", 1)), 1)
	var last_units := maxi(int(competitor.get("last_month_units", 0)), 0)
	var utilization := clampf(float(last_units) / float(capacity), 0.0, 1.0)
	var price := maxi(int(competitor.get("price", 1)), 1)
	var unit_cost := maxi(int(competitor.get("unit_cost", 1)), 1)
	var margin_ratio := clampf(float(price - unit_cost) / float(price), 0.0, 0.95)
	var cash := int(competitor.get("cash", 0))
	var cash_health := clampf(float(cash + 50000) / 400000.0, 0.0, 1.0)
	var last_profit := int(competitor.get("last_month_profit", 0))
	var profit_scale := maxf(float(abs(last_profit)) + 25000.0, 25000.0)
	var profit_signal := clampf(float(last_profit) / profit_scale, -1.0, 1.0)
	var current_fit := _evaluate_competitor(competitor, target)
	var best_segment := target
	var best_fit := current_fit
	for segment_value in available_segment_keys():
		var segment := str(segment_value)
		var fit := _evaluate_competitor(competitor, segment)
		if fit > best_fit:
			best_fit = fit
			best_segment = segment
	return {
		"target_segment":target,
		"utilization":utilization,
		"margin_ratio":margin_ratio,
		"cash_health":cash_health,
		"profit_signal":profit_signal,
		"product_age":int(competitor.get("months_on_market", 0)),
		"best_alternative_segment":best_segment,
		"alternative_segment_gain":maxf(best_fit - current_fit, 0.0)
	}

func _apply_competitor_ai_decision(competitor: Dictionary, decision: Dictionary, context: Dictionary) -> void:
	var action := str(decision.get("action", "HOLD"))
	var before_price := int(competitor.get("price", 0))
	var before_capacity := int(competitor.get("capacity", 0))
	var public_text := ""
	match action:
		"CUT_PRICE":
			var floor_price := maxi(int(round(float(competitor.get("unit_cost", 1)) * 1.12)), int(competitor.get("unit_cost", 1)) + 3)
			competitor["price"] = maxi(floor_price, int(round(float(before_price) * 0.93)))
			if int(competitor.get("price", 0)) < before_price:
				public_text = "%s baisse le prix de %s de %d à %d €." % [str(competitor.get("company", "")), str(competitor.get("name", "son CPU")), before_price, int(competitor.get("price", 0))]
		"RAISE_PRICE":
			competitor["price"] = maxi(int(round(float(before_price) * 1.06)), before_price + 1)
			public_text = "%s relève le prix de %s à %d € face à une forte utilisation de sa capacité." % [str(competitor.get("company", "")), str(competitor.get("name", "son CPU")), int(competitor.get("price", 0))]
		"BOOST_RD":
			competitor["ai_rd_multiplier"] = 1.35
			competitor["ai_action_months"] = 3
		"CONSERVE_CASH":
			competitor["ai_rd_multiplier"] = 0.65
			competitor["ai_action_months"] = 3
		"EXPAND_CAPACITY":
			var expansion_cost := maxi(45000, int(round(float(before_capacity) * 5.0)))
			if int(competitor.get("cash", 0)) >= expansion_cost:
				competitor["cash"] = int(competitor.get("cash", 0)) - expansion_cost
				competitor["capacity"] = maxi(before_capacity + 1000, int(round(float(before_capacity) * 1.18)))
				public_text = "%s investit dans sa capacité industrielle (%d → %d unités/mois)." % [str(competitor.get("company", "")), before_capacity, int(competitor.get("capacity", 0))]
		"REPOSITION":
			var new_segment := str(context.get("best_alternative_segment", context.get("target_segment", default_segment())))
			if new_segment != str(context.get("target_segment", "")) and is_segment_available(new_segment):
				var reposition_cost := 12000
				if int(competitor.get("cash", 0)) >= reposition_cost:
					competitor["cash"] = int(competitor.get("cash", 0)) - reposition_cost
					competitor["target_segment"] = new_segment
					var strategy := str(competitor.get("strategy", "BALANCED"))
					var price_factor := 1.0
					if strategy == "PERFORMANCE":
						price_factor = 1.12
					elif strategy == "EFFICIENCY":
						price_factor = 0.86
					competitor["price"] = maxi(int(competitor.get("unit_cost", 1)) + 6, int(round(segment_reference_price(new_segment) * price_factor)))
					public_text = "%s repositionne %s vers le marché %s." % [str(competitor.get("company", "")), str(competitor.get("name", "son CPU")), segment_label(new_segment)]
		_:
			pass
	CompanyAIManager.apply_decision_state(competitor, decision)
	if public_text != "":
		competitor["ai_public_action"] = public_text
		var event := {
			"type":"COMPETITOR_ACTION",
			"company":str(competitor.get("company", "")),
			"year":TimeManager.year,
			"month":TimeManager.month,
			"text":public_text
		}
		market_events.push_front(event)
		if market_events.size() > 24:
			market_events.pop_back()

func _clear_competitor_sourcing(competitor: Dictionary, release_capacity: bool = true) -> void:
	if release_capacity:
		SupplierManager.release_rival_capacity(str(competitor.get("id", "")))
	competitor["ai_sourcing_generation"] = -1
	competitor["ai_sourcing_mode"] = ""
	competitor["ai_supplier_id"] = ""
	competitor["ai_supplier_name"] = ""
	competitor["ai_supplier_speed_factor"] = 1.0
	competitor["ai_supplier_quality_factor"] = 1.0
	competitor["ai_supplier_unit_cost_factor"] = 1.0
	competitor["ai_supplier_knowledge_factor"] = 1.0
	competitor["ai_supplier_monthly_fee"] = 0
	competitor["ai_supplier_public"] = false

func _set_internal_competitor_sourcing(competitor: Dictionary, generation_target: int) -> void:
	var profile := GameData.approach_data("INTERNAL")
	competitor["ai_sourcing_generation"] = generation_target
	competitor["ai_sourcing_mode"] = "INTERNAL"
	competitor["ai_supplier_id"] = ""
	competitor["ai_supplier_name"] = ""
	competitor["ai_supplier_speed_factor"] = float(profile.get("speed", 1.0))
	competitor["ai_supplier_quality_factor"] = float(profile.get("quality", 1.0))
	competitor["ai_supplier_unit_cost_factor"] = float(GameData.sourcing_profile("INTERNAL").get("unit_cost_factor", 1.0))
	competitor["ai_supplier_knowledge_factor"] = float(profile.get("knowledge", 1.0))
	competitor["ai_supplier_monthly_fee"] = 0
	competitor["ai_supplier_public"] = false

func _ensure_competitor_sourcing(competitor: Dictionary) -> void:
	var generation_target := int(competitor.get("generation_index", 1)) + 1
	var current_mode := str(competitor.get("ai_sourcing_mode", ""))
	if int(competitor.get("ai_sourcing_generation", -1)) == generation_target and current_mode != "":
		if current_mode == "INTERNAL":
			return
		var existing := SupplierManager.rival_reservation_for(str(competitor.get("id", "")))
		if not existing.is_empty():
			competitor["ai_supplier_monthly_fee"] = int(existing.get("monthly_fee", competitor.get("ai_supplier_monthly_fee", 0)))
			return
		_clear_competitor_sourcing(competitor, false)

	var mode := CompanyAIManager.choose_sourcing_mode(competitor, rng)
	if mode == "INTERNAL":
		_set_internal_competitor_sourcing(competitor, generation_target)
		return

	var duration := 12
	match mode:
		"PURCHASE":
			duration = 7
		"LICENSE":
			duration = 12
		"SUBCONTRACT":
			duration = 10
		"PARTNER":
			duration = 14
	var cash := maxi(int(competitor.get("cash", 0)), 0)
	var max_setup_cost := maxi(12000, int(round(float(cash) * 0.22)))
	var reservation := SupplierManager.request_rival_capacity(
		str(competitor.get("id", "")),
		str(competitor.get("company", "")),
		mode,
		duration,
		max_setup_cost
	)
	if reservation.is_empty():
		_set_internal_competitor_sourcing(competitor, generation_target)
		return

	var setup_cost := int(reservation.get("setup_cost", 0))
	if int(competitor.get("cash", 0)) < setup_cost:
		SupplierManager.release_rival_capacity(str(competitor.get("id", "")))
		_set_internal_competitor_sourcing(competitor, generation_target)
		return
	competitor["cash"] = int(competitor.get("cash", 0)) - setup_cost
	competitor["ai_sourcing_generation"] = generation_target
	competitor["ai_sourcing_mode"] = mode
	competitor["ai_supplier_id"] = str(reservation.get("supplier_id", ""))
	competitor["ai_supplier_name"] = str(reservation.get("supplier_name", ""))
	competitor["ai_supplier_speed_factor"] = float(reservation.get("speed_factor", 1.0))
	competitor["ai_supplier_quality_factor"] = float(reservation.get("quality_factor", 1.0))
	competitor["ai_supplier_unit_cost_factor"] = float(reservation.get("unit_cost_factor", 1.0))
	competitor["ai_supplier_knowledge_factor"] = float(reservation.get("knowledge_factor", 1.0))
	competitor["ai_supplier_monthly_fee"] = int(reservation.get("monthly_fee", 0))
	competitor["ai_supplier_public"] = bool(reservation.get("public", false))
	if bool(reservation.get("public", false)):
		var public_text := "%s annonce un co-développement avec %s pour sa prochaine génération CPU." % [
			str(competitor.get("company", "")), str(reservation.get("supplier_name", "un partenaire"))
		]
		competitor["ai_public_action"] = public_text
		market_events.push_front({
			"type":"COMPETITOR_PARTNERSHIP",
			"company":str(competitor.get("company", "")),
			"year":TimeManager.year,
			"month":TimeManager.month,
			"text":public_text
		})
		if market_events.size() > 24:
			market_events.pop_back()

func _process_competitor_b2b(competitor: Dictionary) -> Dictionary:
	var capacity := maxi(int(competitor.get("capacity", 0)), 0)
	var unit_cost := maxi(int(competitor.get("unit_cost", 1)), 1)
	var used_capacity := 0
	var b2b_profit := 0
	var active_contracts: Array = []
	for contract_value in competitor.get("b2b_contracts", []):
		var contract: Dictionary = contract_value
		if str(contract.get("status", "ACTIVE")) != "ACTIVE" or int(contract.get("remaining_months", 0)) <= 0:
			continue
		var promised := maxi(int(contract.get("units_per_month", 0)), 0)
		var delivered := mini(promised, maxi(capacity - used_capacity, 0))
		used_capacity += delivered
		var unit_margin := int(contract.get("unit_price", 1)) - unit_cost
		b2b_profit += delivered * unit_margin
		contract["last_delivered_units"] = delivered
		contract["remaining_months"] = maxi(int(contract.get("remaining_months", 0)) - 1, 0)
		if delivered < promised:
			var shortfall_ratio := float(promised - delivered) / maxf(float(promised), 1.0)
			competitor["brand"] = clampf(float(competitor.get("brand", 50.0)) - shortfall_ratio * 0.7, 20.0, 95.0)
		if int(contract.get("remaining_months", 0)) > 0:
			active_contracts.append(contract)
		else:
			contract["status"] = "COMPLETED"
	competitor["b2b_contracts"] = active_contracts
	competitor["last_month_b2b_units"] = used_capacity
	competitor["last_month_b2b_profit"] = b2b_profit
	return {"units":used_capacity,"profit":b2b_profit}

func _active_competitor_b2b_customer(competitor: Dictionary) -> String:
	for contract_value in competitor.get("b2b_contracts", []):
		var contract: Dictionary = contract_value
		if str(contract.get("status", "ACTIVE")) != "ACTIVE" or int(contract.get("remaining_months", 0)) <= 0:
			continue
		if float(contract.get("confidentiality", 100.0)) <= 75.0:
			return str(contract.get("customer", ""))
	return ""

func _advance_cpu_competitor(competitor: Dictionary):
	CompanyAIManager.tick_company_state(competitor)
	competitor["months_on_market"] = int(competitor.get("months_on_market", 0)) + 1
	var current_target := normalize_segment(str(competitor.get("target_segment", default_segment())))
	if not is_segment_available(current_target):
		current_target = _choose_competitor_segment(competitor)
		competitor["target_segment"] = current_target

	var ai_context := _competitor_ai_context(competitor)
	if CompanyAIManager.decision_due(competitor):
		var decision := CompanyAIManager.choose_action(competitor, ai_context, rng)
		_apply_competitor_ai_decision(competitor, decision, ai_context)

	_ensure_competitor_sourcing(competitor)

	var target := normalize_segment(str(competitor.get("target_segment", current_target)))
	var b2b_result := _process_competitor_b2b(competitor)
	var b2b_units := maxi(int(b2b_result.get("units", 0)), 0)
	var b2b_profit := int(b2b_result.get("profit", 0))
	var remaining_capacity := maxi(int(competitor.get("capacity", 5000)) - b2b_units, 0)
	var market_units := segment_market_units(target)
	var score := _evaluate_competitor(competitor, target)
	var share := clampf(0.06 + (score - 50.0) * 0.004 + (float(competitor.get("brand", 50.0)) - 50.0) * 0.0015, 0.012, 0.31)
	# Lot D : sous l'offensive du joueur, le rival perd une partie de ses clients.
	share *= attack_share_factor(str(competitor.get("id", "")))
	# Lot F1 : une génération ratée (ou réussie) pèse sur les ventes pendant un à deux ans.
	share *= RIVAL_LIFE.fortune_factor(competitor)
	var units := mini(remaining_capacity, int(float(market_units) * share))
	var margin := maxi(int(competitor.get("price", 1)) - int(competitor.get("unit_cost", 1)), 1)
	var operating_profit := units * margin + b2b_profit
	var cash := int(competitor.get("cash", 200000))
	var base_rd_budget := clampi(int(float(maxi(cash, 0)) * 0.035), 3500, 24000)
	var rd_budget := clampi(int(round(float(base_rd_budget) * float(competitor.get("ai_rd_multiplier", 1.0)))), 1800, 34000)
	var supplier_fee := maxi(int(competitor.get("ai_supplier_monthly_fee", 0)), 0)
	var fixed_cost := 7000 + int(competitor.get("generation_index", 1)) * 600 + supplier_fee
	# Lot F1 : les frais de structure suivent le chiffre d'affaires, et l'excédent de trésorerie ressort.
	var revenue := units * int(competitor.get("price", 1))
	var overhead := RIVAL_LIFE.overhead(competitor, revenue, operating_profit)
	cash += operating_profit - rd_budget - fixed_cost - overhead
	competitor["last_month_units"] = units
	competitor["last_month_revenue"] = revenue
	competitor["last_month_profit"] = operating_profit - rd_budget - fixed_cost - overhead
	competitor["cash"] = RIVAL_LIFE.after_payout(cash, revenue)

	var budget_factor := clampf(float(rd_budget) / 15000.0, 0.12, 2.2)
	var strategy := str(competitor.get("strategy", "BALANCED"))
	var arch_gain := 0.16 * budget_factor
	var layout_gain := 0.13 * budget_factor
	var mini_gain := 0.11 * budget_factor
	var manufacturing_gain := 0.12 * budget_factor
	var integration_gain := 0.08 * budget_factor
	var sourcing_knowledge := clampf(float(competitor.get("ai_supplier_knowledge_factor", 1.0)), 0.25, 1.40)
	arch_gain *= sourcing_knowledge
	layout_gain *= sourcing_knowledge
	mini_gain *= sourcing_knowledge
	manufacturing_gain *= sourcing_knowledge
	integration_gain *= sourcing_knowledge
	match strategy:
		"PERFORMANCE":
			arch_gain *= 1.55
			mini_gain *= 1.16
			manufacturing_gain *= 0.88
		"EFFICIENCY":
			layout_gain *= 1.45
			manufacturing_gain *= 1.18
		"BALANCED":
			integration_gain *= 1.22
	var skill_gains := {"architecture_skill":arch_gain, "layout_skill":layout_gain, "miniaturization_skill":mini_gain,
		"manufacturing_skill":manufacturing_gain, "integration_skill":integration_gain}
	for skill_key in skill_gains.keys():
		var skill_value := float(competitor.get(skill_key, 20.0))
		competitor[skill_key] = clampf(skill_value + float(skill_gains[skill_key]) * era_gain_factor(skill_value), 0.0, 100.0)

	var progress_gain := 4.8 + float(competitor.get("architecture_skill", 20.0)) * 0.035 + float(competitor.get("integration_skill", 20.0)) * 0.015
	progress_gain *= clampf(0.82 + budget_factor * 0.18, 0.62, 1.28)
	progress_gain *= clampf(float(competitor.get("ai_supplier_speed_factor", 1.0)), 0.75, 1.65)
	progress_gain += rng.randf_range(-0.45, 0.65)
	competitor["development_progress"] = clampf(float(competitor.get("development_progress", 0.0)) + progress_gain, 0.0, 100.0)
	var generation_cost := 24000 + int(competitor.get("generation_index", 1)) * 4500
	if float(competitor.development_progress) >= 100.0 and int(competitor.cash) >= generation_cost:
		competitor["cash"] = int(competitor.cash) - generation_cost
		_launch_competitor_generation(competitor)

	# Lot F1 : un rival à sec n'est plus renfloué ici ; RivalLife décide (rachat, fusion, faillite).

## Tout début de partie seulement (moins de 3 rivaux avant 1980) : l'ancien renflouement.
func _restructure_competitor(competitor: Dictionary) -> void:
	_clear_competitor_sourcing(competitor)
	competitor["cash"] = 90000
	competitor["restructurings"] = int(competitor.get("restructurings", 0)) + 1
	competitor["brand"] = clampf(float(competitor.get("brand", 50.0)) - 3.0, 20.0, 90.0)
	competitor["capacity"] = maxi(2500, int(float(competitor.get("capacity", 8000)) * 0.84))
	competitor["development_progress"] = minf(float(competitor.get("development_progress", 0.0)), 62.0)

## Retire un rival du marché (rachat, fusion, faillite). Les offensives en cours s'arrêtent d'elles-mêmes.
func remove_competitor(competitor_id: String) -> void:
	var rows: Array = competitors.get("CPU", [])
	var kept: Array = []
	for competitor_value in rows:
		if str((competitor_value as Dictionary).get("id", "")) != competitor_id:
			kept.append(competitor_value)
		else:
			_clear_competitor_sourcing(competitor_value)
	competitors["CPU"] = kept
	market_changed.emit()


func _launch_competitor_generation(competitor: Dictionary):
	var manufacturing := float(competitor.get("manufacturing_skill", 20.0))
	var miniaturization := float(competitor.get("miniaturization_skill", 20.0))
	var available_nodes := CPU_DESIGN.available_nodes_for_capabilities(manufacturing, miniaturization)
	var node_nm := int(available_nodes[available_nodes.size() - 1]) if not available_nodes.is_empty() else 10000
	competitor["node_nm"] = node_nm
	competitor["generation_index"] = int(competitor.get("generation_index", 1)) + 1
	competitor["development_progress"] = rng.randf_range(0.0, 8.0)
	competitor["months_on_market"] = 0
	var completed_sourcing_mode := str(competitor.get("ai_sourcing_mode", "INTERNAL"))
	var completed_supplier_name := str(competitor.get("ai_supplier_name", ""))
	var completed_supplier_public := bool(competitor.get("ai_supplier_public", false))
	_configure_competitor_product(competitor, false)
	if completed_supplier_public and completed_supplier_name != "":
		competitor["public_generation_partner"] = completed_supplier_name
	var history: Array = competitor.get("history", [])
	history.push_front({
		"generation":int(competitor.generation_index),
		"node_nm":node_nm,
		"target_segment":str(competitor.target_segment),
		"sourcing_mode":completed_sourcing_mode,
		"supplier_name":completed_supplier_name,
		"year":TimeManager.year,
		"month":TimeManager.month
	})
	if history.size() > 12:
		history.pop_back()
	competitor["history"] = history
	_clear_competitor_sourcing(competitor)
	RIVAL_LIFE.roll_generation_fortune(competitor, rng)

func _configure_competitor_product(competitor: Dictionary, initial: bool):
	# Les notes des CPU du joueur sont relatives au procédé de leur époque ; celles des
	# rivaux étaient absolues, si bien qu'en fin de partie ils dominaient mécaniquement
	# (mesure 28/09 : écart −17 en 2010 malgré des maîtrises égales). On note donc les
	# rivaux sur leur avance/retard par rapport à l'état de l'art — identique en 1971.
	var era_shift := maxf(era_technology_ceiling() - ERA_CEILING_START, 0.0)
	var arch := float(competitor.get("architecture_skill", 20.0)) - era_shift
	var layout := float(competitor.get("layout_skill", 20.0)) - era_shift
	var manufacturing := float(competitor.get("manufacturing_skill", 20.0)) - era_shift
	var integration := float(competitor.get("integration_skill", 20.0)) - era_shift
	var node_nm := int(competitor.get("node_nm", 10000))
	var node_profile: Dictionary = CPU_DESIGN.node_profile(node_nm)
	var node_score := float(node_profile.get("score", 8.0))
	var strategy := str(competitor.get("strategy", "BALANCED"))
	var performance := 35.0 + arch * 0.47 + node_score * 0.12 + integration * 0.08
	var efficiency := 39.0 + layout * 0.34 + manufacturing * 0.19 + node_score * 0.10
	var reliability := 42.0 + manufacturing * 0.31 + layout * 0.16
	var innovation := 34.0 + arch * 0.31 + float(competitor.get("miniaturization_skill", 20.0)) * 0.20
	if strategy == "PERFORMANCE":
		performance += 5.0
		efficiency -= 2.5
		reliability -= 1.5
	elif strategy == "EFFICIENCY":
		efficiency += 5.0
		reliability += 1.5
		performance -= 1.5
	var sourcing_quality := clampf(float(competitor.get("ai_supplier_quality_factor", 1.0)), 0.88, 1.16)
	performance += (sourcing_quality - 1.0) * 18.0
	efficiency += (sourcing_quality - 1.0) * 15.0
	reliability += (sourcing_quality - 1.0) * 28.0
	innovation += (sourcing_quality - 1.0) * 16.0
	var generation := int(competitor.get("generation_index", 1))
	var usability := 42.0 + integration * 0.22 + generation * 0.45
	var ecosystem := 38.0 + integration * 0.31 + float(competitor.get("brand", 50.0)) * 0.10
	var sustainability := 40.0 + efficiency * 0.25
	competitor["metrics"] = _metrics(
		clampf(performance, 20.0, 96.0), clampf(efficiency, 20.0, 96.0),
		clampf(reliability, 20.0, 97.0), clampf(usability, 20.0, 94.0),
		clampf(innovation, 20.0, 96.0), clampf(ecosystem, 20.0, 94.0),
		clampf(sustainability, 20.0, 94.0)
	)
	# Rendement, défauts et capacité restent absolus : une usine de 2005 produit plus qu'en 1975.
	manufacturing = float(competitor.get("manufacturing_skill", 20.0))
	layout = float(competitor.get("layout_skill", 20.0))
	var yield_rate := clampf(0.48 + manufacturing * 0.0042 + layout * 0.0012 - float(node_profile.get("difficulty", 0.65)) * 0.055, 0.42, 0.93)
	competitor["yield_rate"] = yield_rate
	competitor["defect_rate"] = clampf(0.075 - manufacturing * 0.00055 - layout * 0.00018, 0.006, 0.07)
	var base_cost := 58.0 + float(node_profile.get("base_cost", 40.0)) * 0.34
	var unit_cost := base_cost * (1.0 + (1.0 - yield_rate) * 0.52)
	if strategy == "EFFICIENCY":
		unit_cost *= 0.94
	elif strategy == "PERFORMANCE":
		unit_cost *= 1.10
	unit_cost *= clampf(float(competitor.get("ai_supplier_unit_cost_factor", 1.0)), 0.75, 1.75)
	competitor["unit_cost"] = maxi(20, int(round(unit_cost)))
	competitor["capacity"] = maxi(2500, int(round(6500.0 + manufacturing * 230.0 + yield_rate * 4200.0)))
	var target := _choose_competitor_segment(competitor)
	competitor["target_segment"] = target
	var price_factor := 0.92
	if strategy == "PERFORMANCE":
		price_factor = 1.14
	elif strategy == "EFFICIENCY":
		price_factor = 0.82
	var target_price := segment_reference_price(target) * price_factor
	competitor["price"] = maxi(int(competitor.unit_cost) + 8, int(round(maxf(target_price, float(competitor.unit_cost) * 1.42))))
	competitor["name"] = "%s G%d" % [str(competitor.get("product_prefix", competitor.get("company", "CPU"))), generation]
	if initial:
		competitor["development_progress"] = float(competitor.get("development_progress", 12.0))

func _choose_competitor_segment(competitor: Dictionary) -> String:
	var available := available_segment_keys()
	if available.is_empty():
		return "CALCULATOR"
	var strategy := str(competitor.get("strategy", "BALANCED"))
	var preferences: Array = []
	match strategy:
		"PERFORMANCE":
			preferences = ["GAMING","WORKSTATION","SCIENTIFIC","HOBBYIST","BUSINESS_PC","INDUSTRIAL","EMBEDDED","CALCULATOR"]
		"EFFICIENCY":
			preferences = ["MOBILE_COMPUTING","EMBEDDED","DATACENTER","SERVER","INDUSTRIAL","HOME_PC","CALCULATOR"]
		_:
			preferences = ["BUSINESS_PC","HOME_PC","SERVER","INDUSTRIAL","EMBEDDED","SCIENTIFIC","CALCULATOR"]
	for segment_value in preferences:
		var segment := str(segment_value)
		if available.has(segment):
			return segment
	return str(available[available.size() - 1])

func competitor_summaries() -> Array:
	var result: Array = []
	for competitor in competitors.get("CPU", []):
		result.append({
			"company":str(competitor.get("company", "")),
			"product":str(competitor.get("name", "")),
			"strategy":str(competitor.get("strategy", "")),
			"generation":int(competitor.get("generation_index", 1)),
			"node_nm":int(competitor.get("node_nm", 10000)),
			"target_segment":normalize_segment(str(competitor.get("target_segment", "EMBEDDED"))),
			"cash":int(competitor.get("cash", 0)),
			"development_progress":float(competitor.get("development_progress", 0.0)),
			"architecture":float(competitor.get("architecture_skill", 0.0)),
			"manufacturing":float(competitor.get("manufacturing_skill", 0.0)),
			"capacity":int(competitor.get("capacity", 0)),
			"yield_rate":float(competitor.get("yield_rate", 0.0)),
			"last_month_units":int(competitor.get("last_month_units", 0)),
			"last_month_profit":int(competitor.get("last_month_profit", 0)),
			"restructurings":int(competitor.get("restructurings", 0)),
			"current_action":str(competitor.get("ai_current_action", "HOLD")),
			"decision_cooldown":int(competitor.get("ai_decision_cooldown", 0)),
			"last_reason":str(competitor.get("ai_last_reason", "")),
			"sourcing_mode":str(competitor.get("ai_sourcing_mode", "")),
			"supplier_id":str(competitor.get("ai_supplier_id", "")),
			"supplier_name":str(competitor.get("ai_supplier_name", "")),
			"supplier_monthly_fee":int(competitor.get("ai_supplier_monthly_fee", 0)),
			"b2b_contracts":competitor.get("b2b_contracts", []).duplicate(true),
			"last_month_b2b_units":int(competitor.get("last_month_b2b_units", 0)),
			"last_month_b2b_profit":int(competitor.get("last_month_b2b_profit", 0))
		})
	return result

func cpu_competitor_public_profiles() -> Array:
	var result: Array = []
	for competitor_value in competitors.get("CPU", []):
		var competitor: Dictionary = competitor_value
		var metrics: Dictionary = competitor.get("metrics", {})
		var target := normalize_segment(str(competitor.get("target_segment", default_segment())))
		var market_units := maxi(segment_market_units(target), 1)
		var observed_share := clampf(float(competitor.get("last_month_units", 0)) / float(market_units), 0.0, 1.0)
		var market_signal := "Présence limitée"
		if observed_share >= 0.20:
			market_signal = "Très forte présence"
		elif observed_share >= 0.11:
			market_signal = "Présence solide"
		elif observed_share >= 0.05:
			market_signal = "Présence visible"
		result.append({
			"id":str(competitor.get("id", "")),
			"company":str(competitor.get("company", "")),
			"product":str(competitor.get("name", "")),
			"generation":int(competitor.get("generation_index", 1)),
			"node_nm":int(competitor.get("node_nm", 10000)),
			"target_segment":target,
			"price":int(competitor.get("price", 0)),
			"months_on_market":int(competitor.get("months_on_market", 0)),
			"benchmark_score":benchmark_score(competitor),
			"market_signal":market_signal,
			"recent_public_action":str(competitor.get("ai_public_action", "")),
			"technology_partner":str(competitor.get("ai_supplier_name", "")) if bool(competitor.get("ai_supplier_public", false)) else str(competitor.get("public_generation_partner", "")),
			"public_b2b_customer":_active_competitor_b2b_customer(competitor),
			# Lot F1 : ce que la presse sait de sa santé (génération ratée, pertes, difficultés).
			"health":RIVAL_LIFE.health_label(competitor),
			"metrics":{
				"performance":float(metrics.get("performance", 50.0)),
				"efficiency":float(metrics.get("efficiency", 50.0)),
				"reliability":float(metrics.get("reliability", 50.0)),
				"innovation":float(metrics.get("innovation", 50.0)),
				"sustainability":float(metrics.get("sustainability", 50.0))
			}
		})
	return result

func cpu_competitor_public_profile(competitor_id: String) -> Dictionary:
	for profile_value in cpu_competitor_public_profiles():
		var profile: Dictionary = profile_value
		if str(profile.get("id", "")) == competitor_id:
			return profile
	return {}

func _cpu_competitor_internal(competitor_id: String) -> Dictionary:
	for competitor_value in competitors.get("CPU", []):
		var competitor: Dictionary = competitor_value
		if str(competitor.get("id", "")) == competitor_id:
			return competitor
	return {}

func compare_cpu_public(product: Dictionary, competitor_id: String) -> Dictionary:
	var competitor := _cpu_competitor_internal(competitor_id)
	if competitor.is_empty():
		return {}
	var target := normalize_segment(str(product.get("target_segment", default_segment())))
	var player_metrics: Dictionary = product.get("metrics", {})
	var competitor_metrics: Dictionary = competitor.get("metrics", {})
	var rows: Array = []
	var metric_labels := {
		"performance":"Performance",
		"efficiency":"Efficacité",
		"reliability":"Fiabilité",
		"innovation":"Innovation",
		"sustainability":"Durabilité"
	}
	for metric in ["performance","efficiency","reliability","innovation","sustainability"]:
		var player_value := float(player_metrics.get(metric, 50.0))
		var competitor_value := float(competitor_metrics.get(metric, 50.0))
		rows.append({
			"key":metric,
			"label":str(metric_labels[metric]),
			"player":player_value,
			"competitor":competitor_value,
			"delta":player_value - competitor_value
		})
	var player_price := int(product.get("price", 0))
	var competitor_price := int(competitor.get("price", 0))
	var player_fit := evaluate_product(product, target)
	var competitor_fit := _evaluate_competitor(competitor, target)
	var player_benchmark := benchmark_score(product)
	var competitor_benchmark := benchmark_score(competitor)
	var premium_pct := 0.0
	if competitor_price > 0:
		premium_pct = (float(player_price) / float(competitor_price) - 1.0) * 100.0
	var summary := "Les deux produits sont proches sur la cible %s." % segment_label(target)
	if player_fit >= competitor_fit + 7.0:
		summary = "Votre CPU présente un avantage net sur la cible %s." % segment_label(target)
	elif player_fit <= competitor_fit - 7.0:
		summary = "%s garde un avantage net sur la cible %s." % [str(competitor.get("name", "Le concurrent")), segment_label(target)]
	if premium_pct >= 15.0:
		if player_fit >= competitor_fit + 6.0:
			summary += " Son avance technique peut soutenir un prix supérieur, mais le public jugera si l'écart de valeur justifie le premium."
		else:
			summary += " Le prix supérieur est peu soutenu par l'écart technique actuel et peut peser sur la demande."
	elif premium_pct <= -12.0:
		summary += " Votre prix plus bas renforce la proposition de valeur, à condition de préserver une marge suffisante."
	if float(player_metrics.get("reliability", 50.0)) + 6.0 < float(competitor_metrics.get("reliability", 50.0)):
		summary += " La fiabilité reste un point faible visible face à ce concurrent."
	return {
		"competitor_id":competitor_id,
		"competitor_name":str(competitor.get("name", "")),
		"competitor_company":str(competitor.get("company", "")),
		"target_segment":target,
		"player_price":player_price,
		"competitor_price":competitor_price,
		"price_premium_pct":premium_pct,
		"player_fit":player_fit,
		"competitor_fit":competitor_fit,
		"player_benchmark":player_benchmark,
		"competitor_benchmark":competitor_benchmark,
		"rows":rows,
		"summary":summary
	}

func forecast_cpu_launch(product: Dictionary, proposed_price: int) -> Dictionary:
	if str(product.get("sector", "CPU")) != "CPU":
		return {}
	var candidate: Dictionary = product.duplicate(true)
	candidate["price"] = maxi(proposed_price, 1)
	var target := normalize_segment(str(candidate.get("target_segment", default_segment())))
	if not is_segment_available(target):
		return {}
	var portfolio: Array = []
	for existing_value in ProductManager.products:
		var existing: Dictionary = existing_value
		if str(existing.get("id", "")) == str(candidate.get("id", "")):
			continue
		if str(existing.get("status", "")) != "LAUNCHED":
			continue
		if str(existing.get("sector", "CPU")) != "CPU":
			continue
		if normalize_segment(str(existing.get("target_segment", default_segment()))) != target:
			continue
		portfolio.append(existing)
	portfolio.append(candidate)
	var portfolio_demand := estimate_portfolio_demand(portfolio)
	var demand: Dictionary = portfolio_demand.get(str(candidate.get("id", "")), estimate_consumer_demand(candidate))
	var marketing_score := PersonnelManager.team_score("Marketing", "marketing")
	var confidence := clampf(34.0 + marketing_score * 0.58, 42.0, 92.0)
	var uncertainty := clampf(0.34 - confidence * 0.0025, 0.09, 0.24)
	var expected_units := maxi(int(demand.get("units", 0)), 0)
	var min_units := maxi(int(round(float(expected_units) * (1.0 - uncertainty))), 0)
	var max_units := maxi(int(round(float(expected_units) * (1.0 + uncertainty))), min_units)
	var expected_share := clampf(float(demand.get("share", 0.0)), 0.0, 1.0)
	var min_share := clampf(expected_share * (1.0 - uncertainty), 0.0, 1.0)
	var max_share := clampf(expected_share * (1.0 + uncertainty), 0.0, 1.0)
	var expectation_gap := float(demand.get("expectation_gap", 0.0))
	var perception := "Acceptable"
	if expectation_gap >= 12.0:
		perception = "Très convaincant"
	elif expectation_gap >= 5.0:
		perception = "Solide"
	elif expectation_gap < -12.0:
		perception = "Difficile"
	elif expectation_gap < -4.0:
		perception = "Contesté"
	var reference_price := segment_reference_price(target)
	var price_ratio := float(proposed_price) / maxf(reference_price, 1.0)
	var positioning := "Aligné au marché"
	if price_ratio < 0.84:
		positioning = "Prix agressif"
	elif price_ratio > 1.32:
		positioning = "Très premium"
	elif price_ratio > 1.10:
		positioning = "Premium"
	var value_signal := "Le prix et la proposition technique semblent cohérents."
	if price_ratio > 1.10 and expectation_gap < 5.0:
		value_signal = "Le premium risque d'être discuté si la marque ne prouve pas rapidement sa valeur."
	elif price_ratio > 1.10 and expectation_gap >= 5.0:
		value_signal = "L'avantage produit peut soutenir un premium, mais les tests publics resteront déterminants."
	elif price_ratio < 0.84:
		value_signal = "Le prix facilite l'adoption, mais la marge doit absorber SAV, promotions et variations de production."
	var reliability := float(candidate.get("metrics", {}).get("reliability", 50.0))
	var trust_signal := "Fiabilité perçue dans la norme."
	if reliability >= 72.0:
		trust_signal = "La fiabilité est un argument commercial fort."
	elif reliability < 52.0:
		trust_signal = "La fiabilité peut freiner l'adoption et amplifier l'impact de futurs retours SAV."
	return {
		"segment":target,
		"confidence":confidence,
		"uncertainty":uncertainty,
		"expected_units":expected_units,
		"min_units":min_units,
		"max_units":max_units,
		"expected_share":expected_share,
		"min_share":min_share,
		"max_share":max_share,
		"score":float(demand.get("score", 0.0)),
		"expectation_gap":expectation_gap,
		"perception":perception,
		"positioning":positioning,
		"reference_price":reference_price,
		"value_signal":value_signal,
		"trust_signal":trust_signal
	}

func get_tender(tender_id: String) -> Dictionary:
	for tender in tenders:
		if str(tender.get("id", "")) == tender_id:
			return tender
	return {}

func open_tenders() -> Array:
	var result: Array = []
	for tender in tenders:
		if str(tender.get("status", "")) in ["OPEN", "SUBMITTED"]:
			result.append(tender)
	return result

func _tender_template_available(template: Dictionary) -> bool:
	return TimeManager.year >= int(template.get("historical_year", 1971)) or market_technology_signal() >= float(template.get("tech_trigger", 0.0))

func create_tender_from_template(template_id: String) -> Dictionary:
	# Lot F3 : les appels d'offres stratégiques (défense, aérospatial) utilisent le même circuit.
	var template: Dictionary = TENDER_TEMPLATES.get(template_id, STRATEGIC.TEMPLATES.get(template_id, {}))
	if template.is_empty():
		return {}
	if not _tender_template_available(template):
		return {}
	for existing in tenders:
		if str(existing.get("template_id", "")) != template_id:
			continue
		if str(existing.get("status", "")) in ["OPEN", "SUBMITTED"]:
			return existing
		if market_age_months - int(existing.get("created_market_month", -999)) < 18:
			return {}
	var segment := normalize_segment(str(template.get("segment", default_segment())))
	var reference_price := segment_reference_price(segment)
	var volume_scale := clampf(BalanceManager.market_demand_factor(), 0.65, 1.55)
	var tender := {
		"id":"RFP-%03d" % _next_tender_id,
		"template_id":template_id,
		"customer":str(template.get("customer", "Client industriel")),
		"title":str(template.get("title", "Appel d'offres CPU")),
		"application_profile":str(template.get("application_profile", "GENERAL")),
		"segment":segment,
		"requirements":template.get("requirements", {}).duplicate(true),
		"units_per_month":maxi(20, int(round(float(template.get("base_volume", 500)) * volume_scale))),
		"duration_months":maxi(int(template.get("duration_months", 12)), 1),
		"deadline_months":maxi(int(template.get("deadline_months", 4)), 1),
		"max_unit_price":maxi(1, int(round(reference_price * float(template.get("max_price_factor", 1.0))))),
		"confidentiality":clampf(float(template.get("confidentiality", 50.0)), 0.0, 100.0),
		"exclusivity":bool(template.get("exclusivity", false)),
		"penalty_rate":clampf(float(template.get("penalty_rate", 0.10)), 0.0, 0.50),
		"status":"OPEN",
		"created_market_month":market_age_months,
		"bid":{},
		"rival_bids":[],
		"resolution_market_month":-1,
		"result_score":0.0,
		"winning_company":"",
		"winning_product":"",
		"winning_score":0.0,
		"result_text":""
	}
	_next_tender_id += 1
	tenders.push_front(tender)
	CompanyManager.add_alert("Appel d'offres : %s recherche un partenaire pour %s." % [str(tender.customer), str(tender.title)])
	MediaManager.publish_business_event("Nouvel appel d'offres CPU", "%s ouvre une consultation pour %s." % [str(tender.customer), str(tender.title)])
	market_changed.emit()
	return tender

func _product_application_evaluation(product: Dictionary) -> Dictionary:
	var metrics: Dictionary = product.get("metrics", {})
	return {
		"performance":float(metrics.get("performance", 50.0)),
		"efficiency":float(metrics.get("efficiency", 50.0)),
		"reliability":float(metrics.get("reliability", 50.0)),
		"innovation":float(metrics.get("innovation", 50.0)),
		"unit_cost":float(product.get("unit_cost", 100.0))
	}

func _tender_fit_for(tender: Dictionary, product: Dictionary, bid_price: int, reputation_score: float, intent_bonus: float = 0.0) -> Dictionary:
	if tender.is_empty() or product.is_empty() or str(product.get("sector", "")) != "CPU":
		return {}
	var evaluation := _product_application_evaluation(product)
	var application_key := str(tender.get("application_profile", "GENERAL"))
	var application_fit := CPU_DESIGN.application_fit(evaluation, application_key)
	var requirements: Dictionary = tender.get("requirements", {})
	var requirement_score := 0.0
	var requirement_count := 0
	var gaps: Array[String] = []
	for metric in ["performance", "efficiency", "reliability"]:
		if not requirements.has(metric):
			continue
		requirement_count += 1
		var current := float(evaluation.get(metric, 50.0))
		var required := maxf(float(requirements.get(metric, 1.0)), 1.0)
		requirement_score += clampf(current / required * 100.0, 0.0, 115.0)
		if current + 0.1 < required:
			gaps.append("%s %.0f/%.0f" % [metric, current, required])
	requirement_score /= maxf(float(requirement_count), 1.0)
	var max_price := maxi(int(tender.get("max_unit_price", 1)), 1)
	var price_ratio := float(maxi(bid_price, 1)) / float(max_price)
	var price_score := clampf(112.0 - maxf(price_ratio - 0.72, 0.0) * 115.0, 10.0, 100.0)
	if bid_price > max_price:
		price_score = maxf(price_score - (price_ratio - 1.0) * 70.0, 5.0)
	var total_score := clampf(application_fit * 0.34 + requirement_score * 0.31 + price_score * 0.20 + clampf(reputation_score, 0.0, 100.0) * 0.15 + intent_bonus, 0.0, 100.0)
	return {
		"score":total_score,
		"application_fit":application_fit,
		"requirement_score":requirement_score,
		"price_score":price_score,
		"reputation_score":clampf(reputation_score, 0.0, 100.0),
		"intent_bonus":intent_bonus,
		"gaps":gaps,
		"max_unit_price":max_price
	}

func tender_fit(tender: Dictionary, product: Dictionary, bid_price: int) -> Dictionary:
	var professional := float(CompanyManager.reputation.get("professional", 45.0))
	var reliability_reputation := float(CompanyManager.reputation.get("reliability", 50.0))
	var reputation_score := professional * 0.64 + reliability_reputation * 0.36
	var application_key := str(tender.get("application_profile", "GENERAL"))
	var intent_bonus := 6.0 if str(product.get("application_profile", "GENERAL")) == application_key else 0.0
	return _tender_fit_for(tender, product, bid_price, reputation_score, intent_bonus)

func _rival_tender_fit(tender: Dictionary, competitor: Dictionary, bid_price: int) -> Dictionary:
	var metrics: Dictionary = competitor.get("metrics", {})
	var brand := float(competitor.get("brand", 50.0))
	var reliability := float(metrics.get("reliability", 50.0))
	var reputation_score := brand * 0.62 + reliability * 0.38
	var intent_bonus := 4.0 if normalize_segment(str(competitor.get("target_segment", default_segment()))) == normalize_segment(str(tender.get("segment", default_segment()))) else 0.0
	return _tender_fit_for(tender, competitor, bid_price, reputation_score, intent_bonus)

func _rival_bid_price(tender: Dictionary, competitor: Dictionary) -> int:
	var max_price := maxi(int(tender.get("max_unit_price", 1)), 1)
	var unit_cost := maxi(int(competitor.get("unit_cost", 1)), 1)
	var aggression := clampf(float(competitor.get("ai_price_aggression", 50.0)) / 100.0, 0.0, 1.0)
	var prudence := clampf(float(competitor.get("ai_financial_prudence", 50.0)) / 100.0, 0.0, 1.0)
	var strategy := str(competitor.get("strategy", "BALANCED"))
	var target_ratio := 0.88 - aggression * 0.10 + prudence * 0.05
	if strategy == "PERFORMANCE":
		target_ratio += 0.04
	elif strategy == "EFFICIENCY":
		target_ratio -= 0.03
	var profile := BalanceManager.company_ai_profile()
	var noise := maxf(float(profile.get("decision_noise", 9.0)), 0.0) / 100.0
	var quality := clampf(float(profile.get("decision_quality", 0.74)), 0.0, 1.0)
	target_ratio += rng.randf_range(-noise, noise) * (0.9 - quality * 0.45)
	var floor_price := maxi(unit_cost + 4, int(round(float(unit_cost) * 1.10)))
	return maxi(floor_price, int(round(float(max_price) * clampf(target_ratio, 0.68, 1.08))))

func _competitor_has_exclusive_b2b(competitor: Dictionary) -> bool:
	for contract_value in competitor.get("b2b_contracts", []):
		var contract: Dictionary = contract_value
		if int(contract.get("remaining_months", 0)) > 0 and bool(contract.get("exclusivity", false)):
			return true
	return false

func _build_rival_tender_bids(tender: Dictionary) -> Array:
	var bids: Array = []
	for competitor_value in competitors.get("CPU", []):
		var competitor: Dictionary = competitor_value
		if _competitor_has_exclusive_b2b(competitor):
			continue
		var capacity := maxi(int(competitor.get("capacity", 0)), 1)
		var committed_units := 0
		for contract_value in competitor.get("b2b_contracts", []):
			var contract: Dictionary = contract_value
			if int(contract.get("remaining_months", 0)) > 0:
				committed_units += int(contract.get("units_per_month", 0))
		var free_capacity := maxi(capacity - committed_units, 0)
		var tender_units := maxi(int(tender.get("units_per_month", 0)), 0)
		if free_capacity < int(round(float(tender_units) * 0.75)):
			continue
		var bid_price := _rival_bid_price(tender, competitor)
		var fit := _rival_tender_fit(tender, competitor, bid_price)
		if fit.is_empty() or float(fit.get("score", 0.0)) < 52.0:
			continue
		bids.append({
			"company_id":str(competitor.get("id", "")),
			"company":str(competitor.get("company", "")),
			"product_name":str(competitor.get("name", "CPU")),
			"unit_price":bid_price,
			"score":float(fit.get("score", 0.0)),
			"gaps":fit.get("gaps", []).duplicate(),
			"capacity_available":free_capacity
		})
	bids.sort_custom(func(a, b): return float(a.get("score", 0.0)) > float(b.get("score", 0.0)))
	return bids

func estimated_rival_tender_interest(tender: Dictionary) -> int:
	if tender.is_empty():
		return 0
	var count := 0
	for competitor_value in competitors.get("CPU", []):
		var competitor: Dictionary = competitor_value
		if _competitor_has_exclusive_b2b(competitor):
			continue
		var capacity := maxi(int(competitor.get("capacity", 0)), 1)
		var committed_units := 0
		for contract_value in competitor.get("b2b_contracts", []):
			var contract: Dictionary = contract_value
			if str(contract.get("status", "ACTIVE")) == "ACTIVE" and int(contract.get("remaining_months", 0)) > 0:
				committed_units += int(contract.get("units_per_month", 0))
		var free_capacity := maxi(capacity - committed_units, 0)
		if free_capacity < int(tender.get("units_per_month", 0)):
			continue
		var reference_bid := maxi(int(competitor.get("unit_cost", 1)) + 4, mini(int(competitor.get("price", 1)), int(tender.get("max_unit_price", 1))))
		var fit := _rival_tender_fit(tender, competitor, reference_bid)
		if not fit.is_empty() and float(fit.get("score", 0.0)) >= 52.0:
			count += 1
	return count

func submit_tender_bid(tender_id: String, product_id: String, bid_price: int) -> bool:
	var tender := get_tender(tender_id)
	var product := ProductManager.get_product(product_id)
	if tender.is_empty() or product.is_empty() or str(tender.get("status", "")) != "OPEN":
		return false
	if str(product.get("status", "")) not in ["READY", "LAUNCHED"] or str(product.get("sector", "")) != "CPU":
		return false
	for contract in contracts:
		if str(contract.get("product_id", "")) == product_id and str(contract.get("status", "")) in ["ACTIVE", "RESERVED"]:
			return false
	var fit := tender_fit(tender, product, bid_price)
	if fit.is_empty():
		return false
	tender["bid"] = {
		"product_id":product_id,
		"product_name":str(product.get("name", "CPU")),
		"unit_price":maxi(bid_price, 1),
		"submitted_market_month":market_age_months,
		"preview_score":float(fit.get("score", 0.0))
	}
	tender["status"] = "SUBMITTED"
	tender["resolution_market_month"] = market_age_months + 1
	CompanyManager.add_alert("Offre envoyée à %s pour %s." % [str(tender.get("customer", "")), str(product.get("name", "CPU"))])
	market_changed.emit()
	return true

func _award_tender_to_rival(tender: Dictionary, rival_bid: Dictionary) -> bool:
	var competitor := _cpu_competitor_internal(str(rival_bid.get("company_id", "")))
	if competitor.is_empty():
		return false
	var contract := {
		"id":"RIVAL-B2B-%s-%s" % [str(tender.get("id", "")), str(competitor.get("id", ""))],
		"tender_id":str(tender.get("id", "")),
		"customer":str(tender.get("customer", "")),
		"title":str(tender.get("title", "")),
		"product_name":str(competitor.get("name", "CPU")),
		"application_profile":str(tender.get("application_profile", "GENERAL")),
		"segment":str(tender.get("segment", default_segment())),
		"units_per_month":int(tender.get("units_per_month", 0)),
		"unit_price":int(rival_bid.get("unit_price", 1)),
		"remaining_months":int(tender.get("duration_months", 12)),
		"status":"ACTIVE",
		"confidentiality":float(tender.get("confidentiality", 50.0)),
		"exclusivity":bool(tender.get("exclusivity", false)),
		"last_delivered_units":0
	}
	var rival_contracts: Array = competitor.get("b2b_contracts", [])
	rival_contracts.append(contract)
	competitor["b2b_contracts"] = rival_contracts
	return true

func _resolve_tender(tender: Dictionary):
	var player_bid: Dictionary = tender.get("bid", {})
	var player_product := ProductManager.get_product(str(player_bid.get("product_id", "")))
	var player_score := -1.0
	var player_fit := {}
	if not player_bid.is_empty() and not player_product.is_empty():
		player_fit = tender_fit(tender, player_product, int(player_bid.get("unit_price", 1)))
		player_score = float(player_fit.get("score", -1.0))

	var rival_bids := _build_rival_tender_bids(tender)
	tender["rival_bids"] = rival_bids.duplicate(true)
	var best_rival := {}
	var rival_score := -1.0
	if not rival_bids.is_empty():
		best_rival = rival_bids[0]
		rival_score = float(best_rival.get("score", -1.0))

	var player_credible := player_score >= 68.0
	var rival_credible := rival_score >= 68.0
	if player_credible and (not rival_credible or player_score >= rival_score):
		tender["status"] = "AWARDED"
		tender["result_score"] = player_score
		tender["winning_company"] = CompanyManager.company_name
		tender["winning_product"] = str(player_product.get("name", "CPU"))
		tender["winning_score"] = player_score
		var contract_status := "ACTIVE" if str(player_product.get("status", "")) == "LAUNCHED" else "RESERVED"
		var contract := {
			"id":"B2B-%03d" % _next_contract_id,
			"kind":"TENDER",
			"tender_id":str(tender.get("id", "")),
			"product_id":str(player_product.get("id", "")),
			"product_name":str(player_product.get("name", "CPU")),
			"customer":str(tender.get("customer", "")),
			"segment":str(tender.get("segment", default_segment())),
			"application_profile":str(tender.get("application_profile", "GENERAL")),
			"units_per_month":int(tender.get("units_per_month", 0)),
			"unit_price":int(player_bid.get("unit_price", 1)),
			"remaining_months":int(tender.get("duration_months", 12)),
			"status":contract_status,
			"penalty_rate":float(tender.get("penalty_rate", 0.10)),
			"confidentiality":float(tender.get("confidentiality", 50.0)),
			"exclusivity":bool(tender.get("exclusivity", false))
		}
		_next_contract_id += 1
		contracts.append(contract)
		tender["result_text"] = "Offre retenue face à %d concurrent(s). Le contrat %s %s." % [
			rival_bids.size(),
			str(contract.get("id", "")),
			"est réservé jusqu'au lancement du CPU" if contract_status == "RESERVED" else "entre en vigueur immédiatement"
		]
		CompanyManager.change_reputation({"professional":1.5,"prestige":0.5})
		CompanyManager.add_alert("%s retient votre offre pour %s." % [str(tender.get("customer", "")), str(tender.get("title", ""))])
		MediaManager.publish_business_event("Contrat remporté", "%s choisit %s pour son programme CPU." % [str(tender.get("customer", "")), CompanyManager.company_name])
	elif rival_credible and _award_tender_to_rival(tender, best_rival):
		var had_player_bid := not player_bid.is_empty()
		tender["status"] = "LOST" if had_player_bid else "AWARDED_RIVAL"
		tender["result_score"] = player_score if had_player_bid else rival_score
		tender["winning_company"] = str(best_rival.get("company", ""))
		tender["winning_product"] = str(best_rival.get("product_name", "CPU"))
		tender["winning_score"] = rival_score
		var confidentiality := float(tender.get("confidentiality", 50.0))
		var public_winner := str(best_rival.get("company", "un concurrent")) if confidentiality <= 75.0 else "une entreprise concurrente"
		if had_player_bid:
			tender["result_text"] = "Offre non retenue • votre dossier %.1f/100 • offre gagnante %.1f/100 • %s." % [player_score, rival_score, public_winner]
			CompanyManager.add_alert("%s retient une offre concurrente pour %s." % [str(tender.get("customer", "")), str(tender.get("title", ""))])
		else:
			tender["result_text"] = "Consultation remportée par %s avec un dossier évalué à %.1f/100." % [public_winner, rival_score]
		if confidentiality <= 75.0:
			var public_text := "%s choisit %s pour %s." % [str(tender.get("customer", "")), str(best_rival.get("company", "un fournisseur")), str(tender.get("title", "son programme CPU"))]
			market_events.push_front({
				"type":"RIVAL_B2B_AWARD",
				"company":str(best_rival.get("company", "")),
				"year":TimeManager.year,
				"month":TimeManager.month,
				"text":public_text
			})
			if market_events.size() > 24:
				market_events.pop_back()
			MediaManager.publish_business_event("Contrat B2B attribué", public_text)
	else:
		tender["status"] = "REJECTED" if not player_bid.is_empty() else "NO_AWARD"
		tender["result_score"] = player_score if not player_bid.is_empty() else 0.0
		tender["winning_company"] = ""
		tender["winning_product"] = ""
		tender["winning_score"] = 0.0
		if not player_bid.is_empty():
			var gaps: Array = player_fit.get("gaps", [])
			tender["result_text"] = "Aucune offre crédible n'a été retenue • votre score %.1f/100%s" % [
				player_score,
				(" • écarts : " + ", ".join(gaps)) if not gaps.is_empty() else ""
			]
			CompanyManager.add_alert("%s n'a pas retenu votre offre." % str(tender.get("customer", "")))
		else:
			tender["result_text"] = "Consultation clôturée sans offre répondant suffisamment au cahier des charges."
	market_changed.emit()


func _update_tenders():
	for tender in tenders:
		var status := str(tender.get("status", ""))
		if status == "OPEN":
			tender["deadline_months"] = maxi(int(tender.get("deadline_months", 1)) - 1, 0)
			if int(tender.get("deadline_months", 0)) <= 0:
				_resolve_tender(tender)
		elif status == "SUBMITTED" and market_age_months >= int(tender.get("resolution_market_month", market_age_months + 1)):
			_resolve_tender(tender)
	var active_open := 0
	for tender in tenders:
		if str(tender.get("status", "")) in ["OPEN", "SUBMITTED"]:
			active_open += 1
	if active_open >= 2:
		return
	# I2 : pas d'appel d'offres avant le premier CPU en vente, ni par-dessus une autre offre en attente.
	if not b2b_offers_open() or b2b_offer_waiting():
		return
	var eligible_templates: Array[String] = []
	for template_id_value in TENDER_TEMPLATES.keys():
		var template_id := str(template_id_value)
		var template: Dictionary = TENDER_TEMPLATES[template_id]
		if not _tender_template_available(template):
			continue
		var recently_used := false
		for tender in tenders:
			if str(tender.get("template_id", "")) == template_id and market_age_months - int(tender.get("created_market_month", -999)) < 18:
				recently_used = true
				break
		if not recently_used:
			eligible_templates.append(template_id)
	if eligible_templates.is_empty():
		return
	var professional_bonus := clampf((float(CompanyManager.reputation.get("professional", 45.0)) - 40.0) / 220.0, 0.0, 0.18)
	if rng.randf() <= 0.18 + professional_bonus:
		create_tender_from_template(str(eligible_templates[rng.randi_range(0, eligible_templates.size() - 1)]))

func activate_reserved_contracts(product_id: String):
	for contract in contracts:
		if str(contract.get("product_id", "")) == product_id and str(contract.get("status", "")) == "RESERVED":
			contract["status"] = "ACTIVE"
			CompanyManager.add_alert("Le contrat avec %s démarre avec le lancement de %s." % [str(contract.get("customer", "")), str(contract.get("product_name", ""))])
	market_changed.emit()

## V0.10 / I2 (Claude, 01/10) : les clients pros, calmement. Avant le premier CPU en vente, personne ne
## vient (le novice a assez à faire avec son premier projet) ; ensuite une seule offre à la fois
## (contrat, appel d'offres ou contrat d'études) : la suivante attend qu'on ait répondu à la première.
func b2b_offers_open() -> bool:
	for product_value in ProductManager.products:
		var status := str((product_value as Dictionary).get("status", ""))
		if status in ["LAUNCHED", "RETIRED", "CLEARANCE"]:
			return true
	return false

func b2b_offer_waiting() -> bool:
	for contract_value in contracts:
		if str((contract_value as Dictionary).get("status", "")) == "PENDING":
			return true
	for tender_value in tenders:
		if str((tender_value as Dictionary).get("status", "")) == "OPEN" and not bool((tender_value as Dictionary).get("ceo_ignored", false)):
			return true
	return not GarageBusiness.open_offers().is_empty()

func maybe_generate_b2b(product: Dictionary):
	if str(product.get("status", "")) != "LAUNCHED":
		return
	if b2b_offer_waiting():
		return
	# Personne ne signe un contrat de 2 ans sur un CPU en fin de vie.
	if obsolescence_factor(product) < 0.6:
		return
	for contract in contracts:
		if str(contract.get("product_id", "")) == str(product.get("id", "")) and str(contract.get("status", "")) == "PENDING":
			return
	var target := normalize_segment(str(product.get("target_segment", default_segment())))
	var score := evaluate_product(product, target)
	var metrics: Dictionary = product.get("metrics", {})
	var eligible := target in ["CALCULATOR","EMBEDDED","INDUSTRIAL","SCIENTIFIC","BUSINESS_PC","WORKSTATION","SERVER","DATACENTER"]
	if not eligible or score < 67.0:
		return
	if float(metrics.get("reliability", 50.0)) < 58.0 and target in ["INDUSTRIAL","SERVER","DATACENTER"]:
		return
	if rng.randf() > 0.28:
		return
	var market_units := segment_market_units(target)
	var units: int = maxi(20, int(float(market_units) * rng.randf_range(0.025, 0.09)))
	# Correctif (partie Pixel du 28/09) : les clients demandaient jusqu'à 1 212 unités/mois
	# à une usine qui en sort 201. Chaque mois finissait en livraison incomplète : pénalité
	# + réputation « Clientèle pro » qui tombait à 0. Un client sérieux commande ce que
	# vous pouvez livrer (35 à 60 % de la capacité, le reste reste au grand public).
	var capacity := maxi(int(product.get("production_capacity", 0)), 1)
	units = clampi(mini(units, int(float(capacity) * rng.randf_range(0.35, 0.60))), mini(20, capacity), capacity)
	# 29/09 : des contrats à 1 unité/mois apparaissaient sur les modèles haut de gamme
	# à très petite capacité. En dessous de 20 unités, aucun industriel ne signe.
	if units < 20:
		return
	var months := rng.randi_range(6, 24)
	var unit_price := int(float(product.get("price", 1)) * rng.randf_range(0.76, 0.92))
	var customers_by_segment := {
		"CALCULATOR":["Nippon Calculating","Mercury Instruments","Delta Office Machines"],
		"EMBEDDED":["Vector Controls","Northstar Electronics","Orion Instruments"],
		"INDUSTRIAL":["Atlas Automation","Continental Controls","BlueGrid Industry"],
		"SCIENTIFIC":["Vector Research","Nova Laboratories","Helios Instruments"],
		"BUSINESS_PC":["Atlas Systems","Northstar Office","Mercury Business Machines"],
		"WORKSTATION":["Vector CAD","Orion Engineering","Nova Graphics"],
		"SERVER":["Northstar Servers","Atlas Systems","BlueGrid Networks"],
		"DATACENTER":["Orion Cloud","BlueGrid Datacenter","Vector Compute"]
	}
	var customers: Array = customers_by_segment.get(target, ["Atlas Systems","Vector Research"])
	var customer: String = str(customers[rng.randi_range(0, customers.size() - 1)])
	var contract := {
		"id":"B2B-%03d" % _next_contract_id,"product_id":str(product.get("id", "")),"product_name":str(product.get("name", "")),
		"customer":customer,"segment":target,"units_per_month":units,"unit_price":unit_price,"remaining_months":months,
		"status":"PENDING","sized_to_capacity":true,"missed_months":0,"months_total":months
	}
	_next_contract_id += 1
	contracts.append(contract)
	CompanyManager.add_alert("Proposition B2B : %s souhaite négocier %d unités/mois de %s." % [customer, units, str(product.get("name", ""))])
	MediaManager.publish_b2b_interest(str(product.get("name", "")), customer)
	opportunity_created.emit(contract)
	market_changed.emit()

## Signer une offre B2B précise (conversation avec le client au garage).
func accept_contract(contract_id: String) -> bool:
	for contract in contracts:
		if str(contract.get("id", "")) == contract_id and str(contract.get("status", "")) == "PENDING":
			contract["status"] = "ACTIVE"
			CompanyManager.change_reputation({"professional":2.0,"prestige":0.5})
			CompanyManager.add_alert("Contrat signé avec %s pour %s." % [str(contract.get("customer", "")), str(contract.get("product_name", ""))])
			market_changed.emit()
			return true
	return false

## Refuser poliment une offre B2B : le client repart, sans pénalité.
func decline_contract(contract_id: String) -> bool:
	for contract in contracts:
		if str(contract.get("id", "")) == contract_id and str(contract.get("status", "")) == "PENDING":
			contract["status"] = "DECLINED"
			CompanyManager.add_alert("Offre de %s déclinée." % str(contract.get("customer", "")))
			market_changed.emit()
			return true
	return false

func accept_first_pending_contract() -> bool:
	for contract in contracts:
		if str(contract.get("status", "")) == "PENDING":
			contract["status"] = "ACTIVE"
			CompanyManager.change_reputation({"professional":2.0,"prestige":0.5})
			CompanyManager.add_alert("Contrat signé avec %s pour %s." % [str(contract.get("customer", "")), str(contract.get("product_name", ""))])
			market_changed.emit()
			return true
	return false

func active_contract_for(product_id: String) -> Dictionary:
	for contract in contracts:
		if str(contract.get("product_id", "")) == product_id and str(contract.get("status", "")) == "ACTIVE" and int(contract.get("remaining_months", 0)) > 0:
			return contract
	return {}

func advance_contract(product_id: String, delivered_units: int = -1, capacity: int = -1):
	for contract in contracts:
		if str(contract.get("product_id", "")) == product_id and str(contract.get("status", "")) == "ACTIVE":
			var promised := int(contract.get("units_per_month", 0))
			# Anciens contrats (avant le correctif) signés au-delà de la capacité de l'usine :
			# on ne punit que ce qui était réellement livrable.
			if not bool(contract.get("sized_to_capacity", false)) and capacity > 0:
				promised = mini(promised, capacity)
			if delivered_units >= 0 and delivered_units < promised:
				contract["missed_months"] = int(contract.get("missed_months", 0)) + 1
				var shortfall := promised - delivered_units
				var penalty := int(round(float(shortfall * int(contract.get("unit_price", 0))) * float(contract.get("penalty_rate", 0.08))))
				if penalty > 0:
					Economy.add_expense(penalty, "Pénalité contrat — %s" % str(contract.get("customer", "")))
				var severity := clampf(float(shortfall) / maxf(float(promised), 1.0), 0.0, 1.0)
				CompanyManager.change_reputation({"professional":-1.5 * severity,"reliability":-0.8 * severity})
				CompanyManager.add_alert("Contrat %s : livraison incomplète (%d/%d), pénalité %d €." % [str(contract.get("id", "")), delivered_units, promised, penalty])
			contract["remaining_months"] = int(contract.get("remaining_months", 0)) - 1
			if int(contract.get("remaining_months", 0)) <= 0:
				contract["status"] = "COMPLETED"
				# Un contrat honoré construit la réputation auprès des professionnels.
				var missed := int(contract.get("missed_months", 0))
				var total := maxi(int(contract.get("months_total", 12)), 1)
				var reliability_ratio := 1.0 - clampf(float(missed) / float(total), 0.0, 1.0)
				if reliability_ratio >= 0.75:
					CompanyManager.change_reputation({"professional":1.5 + 2.5 * reliability_ratio, "reliability":0.4, "prestige":0.3})
					CompanyManager.add_alert("Contrat B2B honoré avec %s : les clients professionnels vous font davantage confiance." % str(contract.get("customer", "")))
				else:
					CompanyManager.add_alert("Contrat B2B terminé avec %s (livraisons incomplètes %d mois sur %d)." % [str(contract.get("customer", "")), missed, total])
	market_changed.emit()

func _update_market_opportunities():
	var available := available_segment_keys()
	for segment_value in available:
		var segment := str(segment_value)
		if known_segments.has(segment):
			continue
		known_segments.append(segment)
		var need: Dictionary = MARKET_NEEDS[segment]
		var event := {
			"type":"MARKET_UNLOCK",
			"segment":segment,
			"year":TimeManager.year,
			"month":TimeManager.month,
			"text":"Nouveau besoin : %s — %s" % [segment_label(segment), str(need.description)]
		}
		market_events.push_front(event)
		if market_events.size() > 24:
			market_events.pop_back()
		CompanyManager.add_alert("Marché : %s devient une opportunité commerciale." % segment_label(segment))
		market_need_unlocked.emit(event.duplicate(true))

# --- Lot D : attaquer un rival -------------------------------------------------------------------

## Coût d'une offensive (publicité, remises aux revendeurs, force de vente) : 40 % d'un mois de CA,
## 20 000 € minimum.
func attack_cost() -> int:
	return clampi(int(round(maxf(20000.0, _recent_monthly_revenue() * 0.40))), 20000, 2500000)

## Rivaux présents sur le même marché que ce modèle.
func attack_targets(product: Dictionary) -> Array:
	var result: Array = []
	if str(product.get("status", "")) != "LAUNCHED":
		return result
	var segment := normalize_segment(str(product.get("target_segment", default_segment())))
	for comp_value in competitors.get(str(product.get("sector", "CPU")), []):
		var comp: Dictionary = comp_value
		if normalize_segment(str(comp.get("target_segment", ""))) != segment:
			continue
		result.append({"id":str(comp.get("id", "")), "company":str(comp.get("company", "")), "name":str(comp.get("name", "")),
			"price":int(comp.get("price", 0)), "units":int(comp.get("last_month_units", 0))})
	result.sort_custom(func(a, b): return int(a.units) > int(b.units))
	return result

func active_attacks() -> Array:
	return attacks.filter(func(a): return int(a.get("months_remaining", 0)) > 0)

func attack_for_product(product_id: String) -> Dictionary:
	for attack in active_attacks():
		if str(attack.get("product_id", "")) == product_id:
			return attack
	return {}

func _attack_on_competitor(competitor_id: String) -> Dictionary:
	for attack in active_attacks():
		if str(attack.get("competitor_id", "")) == competitor_id:
			return attack
	return {}

func attack_rival(product_id: String, competitor_id: String) -> bool:
	var product := ProductManager.get_product(product_id)
	if product.is_empty() or not attack_for_product(product_id).is_empty() or not _attack_on_competitor(competitor_id).is_empty():
		return false
	var competitor := _cpu_competitor_internal(competitor_id)
	var valid := false
	for target in attack_targets(product):
		if str(target.get("id", "")) == competitor_id:
			valid = true
	if competitor.is_empty() or not valid:
		return false
	var cost := attack_cost()
	var label := "Offensive commerciale — %s" % str(product.get("name", "CPU"))
	if not Economy.can_afford(cost, label):
		return false
	Economy.add_expense(cost, label)
	attacks.append({
		"id":"ATK-%03d" % _next_attack_id, "product_id":product_id, "product_name":str(product.get("name", "CPU")),
		"competitor_id":competitor_id, "company":str(competitor.get("company", "")), "rival_product":str(competitor.get("name", "")),
		"segment":normalize_segment(str(product.get("target_segment", default_segment()))),
		"months_remaining":ATTACK_MONTHS, "reaction":"", "cost":cost,
		"rival_units_before":int(competitor.get("last_month_units", 0)), "rival_price_before":int(competitor.get("price", 0)),
		"player_units_before":int(product.get("last_month_sales", 0)), "month":TimeManager.month, "year":TimeManager.year
	})
	_next_attack_id += 1
	MediaManager.publish_business_event(
		"%s part à l'assaut du marché %s" % [CompanyManager.company_name, segment_label(normalize_segment(str(product.get("target_segment", ""))))],
		"Remises, publicité et démarchage des revendeurs : %s vise directement les clients du %s de %s." % [str(product.get("name", "CPU")), str(competitor.get("name", "")), str(competitor.get("company", ""))],
		"attack_%s" % competitor_id)
	CompanyManager.add_alert("Offensive lancée contre %s pour %d mois. Surveillez sa réaction." % [str(competitor.get("company", "")), ATTACK_MONTHS])
	market_changed.emit()
	return true

## Nora repère un rival qui écrase l'un de vos marchés et propose une offensive (si vous en avez les moyens).
func attack_advice() -> Dictionary:
	if TimeManager.year * 12 + TimeManager.month < attack_advice_snooze_until or not active_attacks().is_empty():
		return {}
	var cost := attack_cost()
	if float(cost) > float(Economy.money) * 0.25:
		return {}
	var best_by_segment := {}
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) != "LAUNCHED" or ProductManager.is_in_clearance(product) or int(product.get("months_on_market", 0)) < 2:
			continue
		var segment := normalize_segment(str(product.get("target_segment", default_segment())))
		if not best_by_segment.has(segment) or int(product.get("last_month_sales", 0)) > int((best_by_segment[segment] as Dictionary).get("last_month_sales", 0)):
			best_by_segment[segment] = product
	var best: Dictionary = {}
	for segment in best_by_segment.keys():
		var product: Dictionary = best_by_segment[segment]
		var player_units := int(product.get("last_month_sales", 0))
		for target in attack_targets(product):
			var rival_units := int(target.get("units", 0))
			if rival_units < maxi(player_units * 2, 200):
				continue
			if best.is_empty() or rival_units > int(best.get("rival_units", 0)):
				best = {"product_id":str(product.get("id", "")), "product_name":str(product.get("name", "CPU")),
					"competitor_id":str(target.get("id", "")), "company":str(target.get("company", "")), "rival_product":str(target.get("name", "")),
					"rival_units":rival_units, "player_units":player_units, "segment":segment, "cost":cost}
	return best

func snooze_attack_advice(months: int = 12) -> void:
	attack_advice_snooze_until = TimeManager.year * 12 + TimeManager.month + months
	market_changed.emit()

## Bonus de demande pour le modèle qui mène l'offensive.
func attack_demand_factor(product: Dictionary) -> float:
	return ATTACK_PLAYER_BOOST if not attack_for_product(str(product.get("id", ""))).is_empty() else 1.0

## Le plafond de part de marché du joueur s'élargit sur le marché attaqué.
func attack_segment_boost(segment: String) -> float:
	for attack in active_attacks():
		if str(attack.get("segment", "")) == segment:
			return ATTACK_PLAYER_BOOST
	return 1.0

## Part de marché gardée par un rival attaqué (1,0 sans offensive).
func attack_share_factor(competitor_id: String) -> float:
	var attack := _attack_on_competitor(competitor_id)
	if attack.is_empty():
		return 1.0
	return ATTACK_RIVAL_SHARE_NO_REACTION if str(attack.get("reaction", "")) == "NONE" else ATTACK_RIVAL_SHARE_FACTOR

func attack_reaction_label(reaction: String) -> String:
	match reaction:
		"PRICE_CUT": return "baisse ses prix"
		"ADVERTISING": return "riposte par la publicité"
		"EARLY_RELEASE": return "avance sa prochaine génération"
		"NONE": return "ne réagit pas"
	return "n'a pas encore réagi"

## Le rival réagit le premier mois, selon son caractère : prix, publicité, sortie anticipée ou rien.
func _choose_attack_reaction(competitor: Dictionary) -> String:
	if float(competitor.get("development_progress", 0.0)) >= 55.0 and float(competitor.get("ai_research_drive", 50.0)) >= 55.0:
		return "EARLY_RELEASE"
	if float(competitor.get("ai_price_aggression", 50.0)) >= 50.0:
		return "PRICE_CUT"
	if int(competitor.get("cash", 0)) >= 250000:
		return "ADVERTISING"
	return "NONE"

func _apply_attack_reaction(attack: Dictionary, competitor: Dictionary) -> void:
	var reaction := _choose_attack_reaction(competitor)
	attack["reaction"] = reaction
	var company := str(competitor.get("company", "Le rival"))
	var headline := ""
	var body := ""
	match reaction:
		"PRICE_CUT":
			var old_price := int(competitor.get("price", 1))
			var new_price := maxi(int(competitor.get("unit_cost", 1)) + 2, int(round(float(old_price) * 0.85)))
			competitor["price"] = new_price
			attack["rival_price_after"] = new_price
			headline = "%s casse ses prix face à %s" % [company, CompanyManager.company_name]
			body = "Le %s passe de %d € à %d €. La guerre des prix est déclarée." % [str(competitor.get("name", "")), old_price, new_price]
		"ADVERTISING":
			competitor["cash"] = int(competitor.get("cash", 0)) - 60000
			competitor["brand"] = clampf(float(competitor.get("brand", 50.0)) + 4.0, 20.0, 95.0)
			headline = "%s lance une grande campagne publicitaire" % company
			body = "Pour contrer l'offensive de %s, %s affiche le %s partout." % [CompanyManager.company_name, company, str(competitor.get("name", ""))]
		"EARLY_RELEASE":
			competitor["development_progress"] = minf(float(competitor.get("development_progress", 0.0)) + 30.0, 100.0)
			headline = "%s avance la sortie de sa prochaine puce" % company
			body = "Sous pression, %s presse ses ingénieurs : sa nouvelle génération arrivera plus tôt que prévu." % company
		_:
			headline = "%s laisse filer ses clients" % company
			body = "Pas de réponse de %s à l'offensive de %s : ses revendeurs se tournent vers la concurrence." % [company, CompanyManager.company_name]
	MediaManager.publish_business_event(headline, body, "attack_reaction_%s" % str(competitor.get("id", "")))
	CompanyManager.add_alert("Offensive : %s %s." % [company, attack_reaction_label(reaction)])

func _advance_attacks() -> void:
	for attack_value in attacks:
		var attack: Dictionary = attack_value
		var remaining := int(attack.get("months_remaining", 0))
		if remaining <= 0:
			continue
		var competitor := _cpu_competitor_internal(str(attack.get("competitor_id", "")))
		if competitor.is_empty():
			attack["months_remaining"] = 0
			continue
		if str(attack.get("reaction", "")) == "":
			_apply_attack_reaction(attack, competitor)
		attack["months_remaining"] = remaining - 1
		if remaining - 1 <= 0:
			var before := maxi(int(attack.get("rival_units_before", 0)), 1)
			var after := int(competitor.get("last_month_units", 0))
			var lost := clampf(1.0 - float(after) / float(before), -1.0, 1.0)
			attack["rival_units_after"] = after
			CompanyManager.add_alert("Fin de l'offensive contre %s : ses ventes ont %s de %.0f %% (%s)." % [
				str(attack.get("company", "")), "baissé" if lost >= 0.0 else "augmenté", absf(lost) * 100.0, attack_reaction_label(str(attack.get("reaction", "")))])
	if attacks.size() > 12:
		attacks = attacks.slice(attacks.size() - 12)

func process_month(products: Array):
	market_age_months += 1
	_advance_market_threats()
	_advance_attacks()
	_advance_competitors()
	RIVAL_LIFE.process_month()
	_update_market_opportunities()
	_update_tenders()
	STRATEGIC.process_month()
	LATE_GAME.process_month()
	_maybe_spawn_market_threat()
	for product in products:
		if str(product.get("status", "")) == "LAUNCHED":
			maybe_generate_b2b(product)

func get_state() -> Dictionary:
	return {
		"competitors":competitors,
		"contracts":contracts,
		"tenders":tenders,
		"market_events":market_events,
		"market_threats":market_threats,
		"known_segments":known_segments,
		"next_contract_id":_next_contract_id,
		"next_tender_id":_next_tender_id,
		"next_threat_id":_next_threat_id,
		"last_threat_market_age":_last_threat_market_age,
		"market_age_months":market_age_months,
		"attacks":attacks,
		"next_attack_id":_next_attack_id,
		"attack_advice_snooze_until":attack_advice_snooze_until,
		"rival_offers":rival_offers,
		"acquisitions":acquisitions,
		"acquisition_boosts":acquisition_boosts,
		"corporate_log":corporate_log,
		"offer_snooze":offer_snooze,
		"next_offer_id":_next_offer_id,
		"last_healthy_offer_age":last_healthy_offer_age,
		"last_entrant_age":last_entrant_age,
		"strategic":strategic,
		"late_game":late_game,
		"rng_seed":SaveCodec.int64_to_json(rng.seed),
		"rng_state":SaveCodec.int64_to_json(rng.state)
	}

func _migrate_competitor(competitor: Dictionary, sector: String) -> Dictionary:
	if sector != "CPU":
		competitor["sector"] = sector
		return competitor
	var metrics: Dictionary = competitor.get("metrics", _metrics(55,55,55,55,55,55,55))
	var avg := (
		float(metrics.get("performance", 55.0)) + float(metrics.get("efficiency", 55.0))
		+ float(metrics.get("reliability", 55.0)) + float(metrics.get("innovation", 55.0))
	) / 4.0
	competitor["id"] = str(competitor.get("id", str(competitor.get("company", "COMP")).to_upper().replace(" ", "_")))
	competitor["sector"] = "CPU"
	competitor["product_prefix"] = str(competitor.get("product_prefix", str(competitor.get("company", "CPU")).get_slice(" ", 0)))
	competitor["strategy"] = str(competitor.get("strategy", "BALANCED"))
	competitor["cash"] = int(competitor.get("cash", 300000))
	competitor["architecture_skill"] = float(competitor.get("architecture_skill", avg * 0.38))
	competitor["layout_skill"] = float(competitor.get("layout_skill", avg * 0.36))
	competitor["miniaturization_skill"] = float(competitor.get("miniaturization_skill", avg * 0.34))
	competitor["manufacturing_skill"] = float(competitor.get("manufacturing_skill", avg * 0.38))
	competitor["integration_skill"] = float(competitor.get("integration_skill", avg * 0.32))
	competitor["brand"] = float(competitor.get("brand", 50.0))
	competitor["risk_tolerance"] = float(competitor.get("risk_tolerance", 55.0))
	competitor["ai_price_aggression"] = float(competitor.get("ai_price_aggression", 50.0))
	competitor["ai_research_drive"] = float(competitor.get("ai_research_drive", 50.0))
	competitor["ai_financial_prudence"] = float(competitor.get("ai_financial_prudence", 50.0))
	competitor["ai_adaptability"] = float(competitor.get("ai_adaptability", 50.0))
	competitor["ai_growth_drive"] = float(competitor.get("ai_growth_drive", 50.0))
	CompanyAIManager.ensure_company_state(competitor)
	competitor["generation_index"] = maxi(int(competitor.get("generation_index", 1)), 1)
	competitor["development_progress"] = clampf(float(competitor.get("development_progress", 20.0)), 0.0, 100.0)
	competitor["months_on_market"] = maxi(int(competitor.get("months_on_market", 0)), 0)
	competitor["node_nm"] = int(competitor.get("node_nm", 10000))
	competitor["yield_rate"] = clampf(float(competitor.get("yield_rate", 0.62)), 0.35, 0.96)
	competitor["defect_rate"] = clampf(float(competitor.get("defect_rate", 0.035)), 0.002, 0.15)
	competitor["capacity"] = maxi(int(competitor.get("capacity", 9000)), 1000)
	competitor["unit_cost"] = maxi(int(competitor.get("unit_cost", 70)), 1)
	competitor["target_segment"] = normalize_segment(str(competitor.get("target_segment", "EMBEDDED")))
	competitor["history"] = competitor.get("history", []).duplicate(true)
	competitor["last_month_units"] = maxi(int(competitor.get("last_month_units", 0)), 0)
	competitor["last_month_profit"] = int(competitor.get("last_month_profit", 0))
	competitor["restructurings"] = maxi(int(competitor.get("restructurings", 0)), 0)
	competitor["ai_sourcing_generation"] = int(competitor.get("ai_sourcing_generation", -1))
	competitor["ai_sourcing_mode"] = str(competitor.get("ai_sourcing_mode", ""))
	competitor["ai_supplier_id"] = str(competitor.get("ai_supplier_id", ""))
	competitor["ai_supplier_name"] = str(competitor.get("ai_supplier_name", ""))
	competitor["ai_supplier_speed_factor"] = float(competitor.get("ai_supplier_speed_factor", 1.0))
	competitor["ai_supplier_quality_factor"] = float(competitor.get("ai_supplier_quality_factor", 1.0))
	competitor["ai_supplier_unit_cost_factor"] = float(competitor.get("ai_supplier_unit_cost_factor", 1.0))
	competitor["ai_supplier_knowledge_factor"] = float(competitor.get("ai_supplier_knowledge_factor", 1.0))
	competitor["ai_supplier_monthly_fee"] = maxi(int(competitor.get("ai_supplier_monthly_fee", 0)), 0)
	competitor["ai_supplier_public"] = bool(competitor.get("ai_supplier_public", false))
	competitor["public_generation_partner"] = str(competitor.get("public_generation_partner", ""))
	var saved_b2b = competitor.get("b2b_contracts", [])
	competitor["b2b_contracts"] = saved_b2b.duplicate(true) if typeof(saved_b2b) == TYPE_ARRAY else []
	competitor["last_month_b2b_units"] = maxi(int(competitor.get("last_month_b2b_units", 0)), 0)
	competitor["last_month_b2b_profit"] = int(competitor.get("last_month_b2b_profit", 0))
	return competitor

func load_state(state: Dictionary):
	var saved_competitors = state.get("competitors", {})
	if typeof(saved_competitors) == TYPE_DICTIONARY and not saved_competitors.is_empty():
		competitors = saved_competitors.duplicate(true)
	else:
		competitors = {}
		for sector in GameData.SECTORS.keys():
			competitors[sector] = _make_competitors(str(sector))
	for sector_value in competitors.keys():
		var sector := str(sector_value)
		var rows: Array = competitors[sector_value]
		for i in range(rows.size()):
			var competitor: Dictionary = rows[i]
			rows[i] = _migrate_competitor(competitor, sector)
		competitors[sector_value] = rows
	contracts = state.get("contracts", []).duplicate(true)
	tenders = state.get("tenders", []).duplicate(true)
	market_events = state.get("market_events", []).duplicate(true)
	market_threats = state.get("market_threats", []).duplicate(true)
	known_segments = state.get("known_segments", []).duplicate(true)
	if known_segments.is_empty():
		known_segments = available_segment_keys()
	_next_contract_id = int(state.get("next_contract_id", 1))
	_next_tender_id = int(state.get("next_tender_id", tenders.size() + 1))
	market_age_months = int(state.get("market_age_months", 0))
	attacks = (state.get("attacks", []) as Array).duplicate(true)
	_next_attack_id = int(state.get("next_attack_id", attacks.size() + 1))
	attack_advice_snooze_until = int(state.get("attack_advice_snooze_until", 0))
	rival_offers = (state.get("rival_offers", []) as Array).duplicate(true)
	acquisitions = (state.get("acquisitions", []) as Array).duplicate(true)
	acquisition_boosts = (state.get("acquisition_boosts", []) as Array).duplicate(true)
	corporate_log = (state.get("corporate_log", []) as Array).duplicate(true)
	offer_snooze = (state.get("offer_snooze", {}) as Dictionary).duplicate(true)
	_next_offer_id = int(state.get("next_offer_id", rival_offers.size() + 1))
	# Anciennes parties : pas de rafale d'offres ni d'entrants au chargement.
	last_healthy_offer_age = int(state.get("last_healthy_offer_age", market_age_months))
	last_entrant_age = int(state.get("last_entrant_age", market_age_months))
	strategic = (state.get("strategic", {}) as Dictionary).duplicate(true)
	late_game = (state.get("late_game", {}) as Dictionary).duplicate(true)
	_next_threat_id = int(state.get("next_threat_id", market_threats.size() + 1))
	_last_threat_market_age = int(state.get("last_threat_market_age", maxi(market_age_months - 36, 0)))
	rng.seed = SaveCodec.int64_from_json(state.get("rng_seed", "43021"), 43021)
	rng.state = SaveCodec.int64_from_json(state.get("rng_state", SaveCodec.int64_to_json(rng.state)), rng.state)
	market_changed.emit()
