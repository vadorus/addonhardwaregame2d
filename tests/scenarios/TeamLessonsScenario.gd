extends RefCounted
## Lot E1 (29/09) : l'équipe voit les problèmes et le dit (parcours, conseils, voix des clients).

const TEAM_LESSONS := preload("res://scripts/TeamLessons.gd")
const INTERACTIONS := preload("res://scripts/Interactions.gd")

static func run() -> String:
	SimulationManager.reset_all("CI Equipe", "CPU", "STANDARD")
	Economy.money = 1000000
	ProductManager.cpu_generations.append({"id":"GEN-CI-E1", "name":"Ci Nova", "generation_index":1})
	var product := {
		"id":"PROD-CI-E1", "name":"Ci Nova", "sector":"CPU", "company":CompanyManager.company_name,
		"generation_id":"GEN-CI-E1", "status":"LAUNCHED", "price":200, "unit_cost":70, "production_capacity":500,
		"months_on_market":4, "units_sold_total":3000, "last_month_sales":400, "target_segment":"EMBEDDED",
		"metrics":{"performance":60.0, "efficiency":45.0, "reliability":72.0, "usability":55.0, "innovation":55.0, "ecosystem":50.0, "sustainability":50.0},
		"defect_rate":0.03, "royalty_rate":0.0, "cpu_design":{},
		"last_market_feedback":{"verdict":"Ventes sous la prévision", "lesson":"Le prix était trop haut pour ce marché."}
	}
	ProductManager.products.append(product)
	AfterSalesManager.cases.append({"id":"SAV-CI-E1", "sector":"CPU", "generation_id":"GEN-CI-E1", "product_id":"PROD-CI-E1",
		"product_name":"Ci Nova", "issue_type":"THERMAL", "status":"OPEN", "severity":45.0})

	# 1. Parcours Nouveau CPU : ce que l'équipe a appris.
	var lessons: Dictionary = TEAM_LESSONS.lessons("EMBEDDED")
	if not bool(lessons.get("has_data", false)):
		return "Team lessons: the previous generation should produce lessons"
	var text := "\n".join(lessons.get("lines", []))
	if text.find("SAV") < 0 or text.find("Marché") < 0:
		return "Team lessons: SAV and market lessons should both be told (%s)" % text
	if str(lessons.get("suggested_profile", "")) != "LOWPOWER":
		return "Team lessons: overheating should suggest a low-power design (got %s)" % str(lessons.get("suggested_profile", ""))

	# 2. Conseil de l'équipe sur un CPU en vente.
	var advice: Dictionary = TEAM_LESSONS.pending_advice()
	if str(advice.get("type", "")) != "FIX_THERMAL":
		return "Team advice: an open thermal SAV case should bring an efficiency stepping advice (got %s)" % str(advice)
	var key := "ADVICE:GEN-CI-E1:FIX_THERMAL"
	var found := false
	for item in INTERACTIONS.pending():
		if str((item as Dictionary).get("key", "")) == key:
			found = true
	if not found or INTERACTIONS.dialogue(key).is_empty():
		return "Team advice: the development lead should come and talk about it"
	var money_before := Economy.money
	if not bool(INTERACTIONS.choose(key, "APPLY").get("ok", false)):
		return "Team advice: applying the stepping failed"
	if int(product.get("hardware_revision", 0)) != 1 or Economy.money >= money_before:
		return "Team advice: the stepping should be applied and paid"
	var next_advice: Dictionary = TEAM_LESSONS.pending_advice()
	if str(next_advice.get("type", "")) == "FIX_THERMAL":
		return "Team advice: the same advice should not come back once applied"

	# 3. Voix des clients.
	var voices: Array = TEAM_LESSONS.customer_voices(product)
	if voices.size() != 3:
		return "Customer voices: three kinds of customers should speak (got %d)" % voices.size()
	for voice in voices:
		if str((voice as Dictionary).get("text", "")) == "" or str((voice as Dictionary).get("who", "")) == "":
			return "Customer voices: every customer needs a name and a sentence"

	ProductManager.products.erase(product)
	AfterSalesManager.cases = AfterSalesManager.cases.filter(func(c): return str(c.get("id", "")) != "SAV-CI-E1")
	ProductManager.cpu_generations = ProductManager.cpu_generations.filter(func(g): return str(g.get("id", "")) != "GEN-CI-E1")
	return ""
