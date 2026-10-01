extends RefCounted
## V0.10 / I5 — page Vendre après lancement (étude Astra / Claude, synthèse Codex, décision d'Alexandre).
## - « Tout va bien, laissez vendre » quand rien ne cloche ; « Premières ventes » avant le 1er bilan ;
## - chaque conseil a une condition mesurable, juste en dessous rien, au-dessus le conseil ;
## - une perte par puce passe avant la rupture ; « Plus tard » met en pause sans cacher du portefeuille ;
## - le devis ne dépense rien ; pas d'alerte de trésorerie pour une action gratuite ;
## - portefeuille : À examiner, En vente, Fin de série, Archives ;
## - la contribution compte désormais la part des distributeurs (relevé par Astra).

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const ADVISOR := preload("res://scripts/SalesAdvisor.gd")
const CARD := preload("res://ui/components/SalesMonthCard.gd")

static func run(host: Node) -> String:
	var snapshot := {
		"time":TimeManager.get_state().duplicate(true), "economy":Economy.get_state().duplicate(true),
		"company":CompanyManager.get_state().duplicate(true), "executive":ExecutiveManager.get_state().duplicate(true),
		"research":ResearchManager.get_state().duplicate(true), "products":ProductManager.get_state().duplicate(true),
		"after_sales":AfterSalesManager.get_state().duplicate(true), "market":MarketManager.get_state().duplicate(true),
		"balance":BalanceManager.get_state().duplicate(true), "divisions":DivisionManager.get_state().duplicate(true),
		"personnel":PersonnelManager.get_state().duplicate(true), "suppliers":SupplierManager.get_state().duplicate(true),
		"foundry":FoundryManager.get_state().duplicate(true), "production":ProductionManager.get_state().duplicate(true),
		"patents":PatentManager.get_state().duplicate(true), "media":MediaManager.get_state().duplicate(true),
	}
	var error := _check(host)
	CompanyManager.load_state(snapshot.company)
	TimeManager.load_state(snapshot.time)
	BalanceManager.load_state(snapshot.balance)
	DivisionManager.load_state(snapshot.divisions)
	Economy.load_state(snapshot.economy)
	PersonnelManager.load_state(snapshot.personnel)
	ExecutiveManager.load_state(snapshot.executive)
	SupplierManager.load_state(snapshot.suppliers)
	ResearchManager.load_state(snapshot.research)
	FoundryManager.load_state(snapshot.foundry)
	ProductionManager.load_state(snapshot.production)
	PatentManager.load_state(snapshot.patents)
	ProductManager.load_state(snapshot.products)
	AfterSalesManager.load_state(snapshot.after_sales)
	MarketManager.load_state(snapshot.market)
	MediaManager.load_state(snapshot.media)
	return error

static func _product(id: String, price: int, generation: int) -> Dictionary:
	return {"id":id, "project_id":"PRJ-" + id, "name":"CI %s" % id, "company":CompanyManager.company_name, "sector":"CPU",
		"target_segment":"EMBEDDED", "application_profile":"GENERAL", "approach":"INTERNAL",
		"sourcing":GameData.sourcing_profile("INTERNAL"), "supplier_contract_id":"", "royalty_rate":0.0,
		"cpu_design":CPU_DESIGN.default_design(), "generation_index":generation, "sku_label":"Modèle",
		"metrics":{"performance":78.0, "efficiency":76.0, "reliability":82.0, "usability":70.0, "innovation":72.0, "ecosystem":68.0, "sustainability":70.0},
		"unit_cost":30, "price":price, "recommended_capacity":100, "max_monthly_capacity":2000, "production_capacity":100,
		"manufacturing_quality":82.0, "defect_rate":0.012, "status":"READY", "months_on_market":0, "units_sold_total":0,
		"last_month_sales":0, "last_month_score":0.0, "last_month_share":0.0, "last_month_returns":0, "customer_satisfaction":50.0}

## Un mois de vente « calme » : 90 puces sur 100 (le garage plafonne à 350 puces en tout), dans la prévision, bénéfice positif.
static func _calm(product: Dictionary) -> void:
	product["status"] = "LAUNCHED"
	product["months_on_market"] = 3
	product["last_month_sales"] = 90
	product["last_month_lost_sales"] = 0
	product["last_month_demand"] = 90
	product["last_month_consumer_demand"] = 90
	product["customer_satisfaction"] = 72.0
	product["promotion_type"] = "NONE"
	product["advice_snooze"] = {}
	var feedback := {"units":90, "net_contribution":6000, "capacity_reservation_cost":200, "capacity_utilization":0.9, "verdict":"Dans la prévision"}
	product["last_market_feedback"] = feedback
	product["market_feedback_history"] = [feedback.duplicate(), feedback.duplicate()]

static func _kinds(product: Dictionary) -> Array:
	var out: Array = []
	for advice in ADVISOR.product_signals(product):
		out.append(str((advice as Dictionary).kind))
	return out

static func _check(host: Node) -> String:
	SimulationManager.reset_all("CI Sales Advisor", "CPU", "STANDARD")
	# --- La contribution compte la part des distributeurs (Astra).
	var fee_product := _product("FEE", 120, 1)
	ProductManager.products = [fee_product]
	ProductManager.cpu_generations = []
	if not ProductManager.launch_product("FEE", 120, 100):
		return "I5: could not launch the distributor-fee CPU"
	var reports: Array = []
	var catch := func(report: Dictionary): reports.append(report)
	ProductManager.sales_report_created.connect(catch)
	ProductManager.process_month()
	ProductManager.sales_report_created.disconnect(catch)
	if reports.is_empty():
		return "I5: no sales report"
	var report: Dictionary = reports[0]
	var expected := int(report.revenue) - int(report.production_cost) - int(report.get("distributor_cost", 0)) - int(report.capacity_reservation_cost) - int(report.royalty_cost) - int(report.warranty_cost)
	if int(report.get("distributor_cost", 0)) <= 0 or int(report.net_contribution) != expected:
		return "I5: the contribution must subtract the distributors' share (%s)" % str(report)

	# --- Avant le premier bilan : pas de conseil, « Premières ventes ».
	var a := _product("A", 120, 2)
	var b := _product("B", 180, 2)
	ProductManager.products = [a, b]
	a["status"] = "LAUNCHED"
	b["status"] = "LAUNCHED"
	var summary := ADVISOR.month_summary()
	if bool(summary.measured) or not (summary.top as Dictionary).is_empty() or str(summary.headline).find("Premières ventes") < 0:
		return "I5: before the first month closes, Nora must say sales are starting, with no advice (%s)" % str(summary)

	# --- Calme : « Tout va bien, laissez vendre », aucun bouton.
	_calm(a)
	_calm(b)
	summary = ADVISOR.month_summary()
	if not (summary.top as Dictionary).is_empty() or str(summary.calm) != "Tout va bien, laissez vendre.":
		return "I5: a calm month must give no advice (%s)" % str(summary.top)

	# --- Rupture : seuil 20 ventes ET 20 % ; juste en dessous, rien.
	a["last_month_consumer_demand"] = 215
	a["last_month_lost_sales"] = 19
	if "STOCKOUT" in _kinds(a):
		return "I5: 19 lost sales must not trigger the stockout advice"
	a["last_month_lost_sales"] = 40
	if "STOCKOUT" in _kinds(a):
		return "I5: 40 lost of 215 (19 %) must not trigger the stockout advice"
	a["last_month_lost_sales"] = 72
	var kinds := _kinds(a)
	if kinds.is_empty() or kinds[0] != "STOCKOUT":
		return "I5: 72 lost of 215 must trigger the stockout advice (%s)" % str(kinds)
	summary = ADVISOR.month_summary()
	var top: Dictionary = summary.top
	if str(top.get("kind", "")) != "STOCKOUT" or str(top.get("cta_kind", "")) != "EXAMINE":
		return "I5: the stockout must be the one advice of the month, behind « Examiner » (%s)" % str(top)

	# --- Le devis ne dépense rien ; action gratuite = pas d'alerte de trésorerie.
	var cash := Economy.money
	var quote := CARD.quote_for(top)
	if quote.is_empty() or str(quote.action) != "update_capacity" or int((quote.payload as Dictionary).capacity) <= 100 or Economy.money != cash:
		return "I5: the capacity quote must prepare update_capacity without spending (%s)" % str(quote)
	Economy.money = 100
	quote = CARD.quote_for(top)
	if int(quote.cost) == 0 and str(quote.warning) != "":
		return "I5: a free action must not show a cash warning"
	if int(quote.cost) > 0 and bool(quote.can):
		return "I5: a paid action the company cannot afford must not be confirmable"
	Economy.money = cash

	# --- Une perte par puce passe avant la rupture.
	var losing := {"units":90, "net_contribution":-900, "capacity_reservation_cost":200, "capacity_utilization":1.0, "verdict":"Dans la prévision"}
	a["last_market_feedback"] = losing
	a["market_feedback_history"] = [losing, losing.duplicate()]
	kinds = _kinds(a)
	if kinds.is_empty() or kinds[0] != "LOSING":
		return "I5: losing money per chip must come before the stockout (%s)" % str(kinds)
	_calm(a)

	# --- « Plus tard » : plus de bouton ce mois-ci, mais toujours « À examiner » dans le portefeuille.
	a["last_month_consumer_demand"] = 215
	a["last_month_lost_sales"] = 72
	ADVISOR.snooze("A", "STOCKOUT")
	summary = ADVISOR.month_summary()
	if not (summary.top as Dictionary).is_empty():
		return "I5: a snoozed advice must leave the month card (%s)" % str(summary.top)
	var groups := ADVISOR.portfolio()
	if (groups.EXAMINE as Array).size() != 1 or str(((groups.EXAMINE as Array)[0] as Dictionary).product.id) != "A":
		return "I5: a snoozed problem must stay « À examiner » in the portfolio"
	if (groups.SELLING as Array).size() != 1:
		return "I5: the healthy CPU must be « En vente »"
	_calm(a)

	# --- Retour Pixel : rupture au plafond des locaux → pas de bouton, et surtout pas « Tout va bien ».
	a["production_capacity"] = 250
	a["last_month_consumer_demand"] = 400
	a["last_month_lost_sales"] = 150
	summary = ADVISOR.month_summary()
	if not (summary.top as Dictionary).is_empty() or str(summary.calm).find("locaux") < 0:
		return "I5: a stockout at the premises ceiling must say the premises are full, with no button (%s)" % str(summary.calm)
	if (ADVISOR.portfolio().EXAMINE as Array).size() != 1:
		return "I5: a stockout at the premises ceiling must stay « À examiner »"
	a["production_capacity"] = 100
	_calm(a)

	# --- Usine sous-utilisée : campagne si la demande déçoit, sinon moins de capacité.
	var low := {"units":30, "net_contribution":1500, "capacity_reservation_cost":150, "capacity_utilization":0.3, "verdict":"Dans la prévision"}
	b["last_month_sales"] = 30
	b["unit_cost"] = 2000  # assez cher pour que réduire fasse économiser plus de 1 000 €/mois
	b["last_market_feedback"] = low
	b["market_feedback_history"] = [low, low.duplicate()]
	kinds = _kinds(b)
	if kinds != ["OVERCAPACITY"]:
		return "I5: an under-used factory must suggest less capacity (%s)" % str(kinds)
	var weak := low.duplicate()
	weak["verdict"] = "Sous la prévision"
	b["last_market_feedback"] = weak
	b["market_feedback_history"] = [weak, weak.duplicate()]
	kinds = _kinds(b)
	if kinds != ["PROMOTION"]:
		return "I5: a liked CPU selling under forecast must suggest a campaign (%s)" % str(kinds)
	b["promotion_type"] = "AWARENESS"
	if not _kinds(b).is_empty():
		return "I5: no new campaign advice while one is running"
	b["unit_cost"] = 30
	b["promotion_type"] = "NONE"
	b["last_market_feedback"] = low
	b["market_feedback_history"] = [low, low.duplicate()]
	if not _kinds(b).is_empty():
		return "I5: saving a few euros a month is not worth an advice (%s)" % str(_kinds(b))
	_calm(b)

	# --- Portefeuille : fin de série et archives à leur place.
	b["clearance_months_remaining"] = 2
	var c := _product("C", 90, 1)
	c["status"] = "RETIRED"
	ProductManager.products.append(c)
	groups = ADVISOR.portfolio()
	if (groups.CLEARANCE as Array).size() != 1:
		return "I5: a CPU in clearance must be in « Fin de série »"
	if (groups.ARCHIVE as Array).size() != 1:
		return "I5: a retired CPU must be in the archives"
	return ""
