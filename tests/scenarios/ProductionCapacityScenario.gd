extends RefCounted
## Lot M (29/09) : la capacité n'est plus figée au lancement. Une demande supérieure à la capacité
## est mesurée (ventes perdues) et signalée ; le joueur peut ajuster puis étendre la capacité.

static func run() -> String:
	SimulationManager.reset_all("CI Capacité", "CPU", "STANDARD")
	# K4 : avril est un mois « neutre » du calendrier commercial (demande ×1).
	TimeManager.month = 4
	Economy.money = 2000000
	var product := {
		"id":"PROD-CI-CAP", "name":"Capa 1", "sector":"CPU", "company":CompanyManager.company_name,
		"status":"LAUNCHED", "price":180, "unit_cost":60, "production_capacity":100,
		"max_monthly_capacity":140, "recommended_capacity":100, "months_on_market":4,
		"units_sold_total":0, "last_month_sales":0, "target_segment":"EMBEDDED",
		"metrics":{"performance":70.0, "efficiency":70.0, "reliability":85.0, "usability":60.0, "innovation":60.0, "ecosystem":50.0, "sustainability":50.0},
		"defect_rate":0.02, "royalty_rate":0.0
	}
	ProductManager.products.append(product)
	# Demande forcée à 400 unités : 300 clients repartent sans CPU.
	ProductManager._sell_product_month(product, {"units":400, "score":70.0})
	if int(product.get("last_month_sales", 0)) != 100:
		return "Capacity: sales should be capped by capacity (got %d)" % int(product.get("last_month_sales", 0))
	if int(product.get("last_month_lost_sales", 0)) != 300:
		return "Capacity: lost sales should be measured (got %d)" % int(product.get("last_month_lost_sales", 0))
	if not bool(product.get("lost_sales_alerted", false)):
		return "Capacity: a strong shortage should warn the player once"
	# Dans la limite actuelle : gratuit.
	var money_before := Economy.money
	if not ProductManager.set_production_capacity("PROD-CI-CAP", 140):
		return "Capacity: raising capacity within the current maximum failed"
	if Economy.money != money_before:
		return "Capacity: raising capacity within the current maximum should not charge an extension"
	# Au-delà : extension payante, bornée à ×2 du maximum.
	var quote := ProductManager.capacity_change_quote("PROD-CI-CAP", 1000)
	if int(quote.get("capacity", 0)) != 280 or int(quote.get("cost", 0)) <= 0:
		return "Capacity: extension quote should cap at twice the maximum and cost money (%s)" % str(quote)
	if not ProductManager.set_production_capacity("PROD-CI-CAP", 1000):
		return "Capacity: paid extension failed despite enough cash"
	if int(product.get("production_capacity", 0)) != 280 or Economy.money >= money_before:
		return "Capacity: extension did not apply or was free"
	ProductManager._sell_product_month(product, {"units":400, "score":70.0})
	# V0.10 / H5 : après la grosse rupture du premier mois, une partie des clients déçus est partie chez
	# les rivaux : la demande servie n'est plus 400 mais un peu moins, donc moins de 120 ventes perdues.
	if int(product.get("last_month_sales", 0)) != 280 or int(product.get("last_month_lost_sales", 0)) >= 120 or int(product.get("last_month_lost_sales", 0)) <= 0:
		return "Capacity: extended capacity should serve more demand (sold %d, lost %d)" % [int(product.get("last_month_sales", 0)), int(product.get("last_month_lost_sales", 0))]
	# Un produit pas encore lancé ne se règle pas ici.
	product["status"] = "READY"
	if ProductManager.set_production_capacity("PROD-CI-CAP", 150):
		return "Capacity: a product not on the market should not be adjusted after launch"
	ProductManager.products.erase(product)
	return ""
