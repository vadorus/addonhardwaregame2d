extends RefCounted
## Bug trouvé dans la partie d'Alexandre (28/09) : « Clientèle pro » à 0/100 après 4 contrats B2B.
## Les contrats demandaient 589 à 1 212 unités/mois pour 201 de capacité → livraison incomplète
## chaque mois (pénalité + réputation pro en baisse), et un contrat honoré ne rapportait rien.

static func run() -> String:
	SimulationManager.reset_all("CI B2B", "CPU", "STANDARD")
	CompanyManager.reputation["professional"] = 20.0

	# Contrat ancien, trop gros pour l'usine : on ne punit plus l'impossible.
	var legacy := {"id":"B2B-900","product_id":"PROD-X","product_name":"X","customer":"Legacy","units_per_month":1212,
		"unit_price":100,"remaining_months":3,"status":"ACTIVE"}
	MarketManager.contracts.append(legacy)
	var money_before := Economy.money
	MarketManager.advance_contract("PROD-X", 201, 201)
	if Economy.money < money_before:
		return "B2B: a legacy oversized contract still charges a penalty for undeliverable units"
	if float(CompanyManager.reputation.get("professional", 0.0)) < 20.0:
		return "B2B: professional reputation drops on a legacy contract delivered at full capacity"

	# Contrat honoré jusqu'au bout : la réputation pro monte.
	var honored := {"id":"B2B-901","product_id":"PROD-Y","product_name":"Y","customer":"Honored","units_per_month":80,
		"unit_price":100,"remaining_months":2,"months_total":2,"status":"ACTIVE","sized_to_capacity":true,"missed_months":0}
	MarketManager.contracts.append(honored)
	var before := float(CompanyManager.reputation.get("professional", 0.0))
	MarketManager.advance_contract("PROD-Y", 80, 200)
	MarketManager.advance_contract("PROD-Y", 80, 200)
	if str(honored.get("status", "")) != "COMPLETED":
		return "B2B: honored contract did not complete"
	if float(CompanyManager.reputation.get("professional", 0.0)) <= before + 2.0:
		return "B2B: completing a contract does not raise professional reputation"

	# Un vrai manque de livraison reste sanctionné.
	var missed := {"id":"B2B-902","product_id":"PROD-Z","product_name":"Z","customer":"Missed","units_per_month":100,
		"unit_price":100,"remaining_months":5,"months_total":5,"status":"ACTIVE","sized_to_capacity":true,"missed_months":0}
	MarketManager.contracts.append(missed)
	before = float(CompanyManager.reputation.get("professional", 0.0))
	MarketManager.advance_contract("PROD-Z", 40, 200)
	if float(CompanyManager.reputation.get("professional", 0.0)) >= before or int(missed.get("missed_months", 0)) != 1:
		return "B2B: a real shortfall is no longer penalized"
	return ""
