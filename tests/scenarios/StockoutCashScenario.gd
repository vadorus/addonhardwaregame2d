extends RefCounted
## V0.10 / H5 — une rupture a des conséquences (clients déçus, satisfaction) qui s'effacent quand on
## sert de nouveau tout le monde ; avant de s'engager, le joueur voit « il vous restera X € au lancement ».

static func run() -> String:
	var saved_money := Economy.money
	var saved_history: Array = Economy.history.duplicate(true)
	var error := _check()
	Economy.money = saved_money
	Economy.history = saved_history
	return error

static func _check() -> String:
	# Rupture : la moitié des clients repart → frustration ; servi de nouveau → elle retombe.
	var f := ProductManager.next_stockout_frustration(0.0, 0.5)
	if f < 0.2:
		return "H5: losing half the customers must frustrate them (%.2f)" % f
	var g := ProductManager.next_stockout_frustration(f, 0.6)
	if g <= f or g > 1.0:
		return "H5: repeated stock-outs must add up, capped at 1"
	var calm := g
	for _i in range(8):
		calm = ProductManager.next_stockout_frustration(calm, 0.0)
	if calm > 0.05:
		return "H5: frustration must fade once every customer is served again (%.2f)" % calm
	if ProductManager.next_stockout_frustration(0.0, 0.05) != 0.0:
		return "H5: a tiny shortage (5 %) must not frustrate anyone"
	# Projection de trésorerie jusqu'au lancement.
	Economy.money = 100000
	Economy.history = [{"result":-8000}, {"result":-8000}, {"result":-8000}]
	var ok := ExecutiveManager.launch_cash_projection(6, 2000)
	if int(ok.cash_end) != 100000 - 6 * 10000 or int(ok.negative_month) != -1:
		return "H5: projection should end at 40 000 € without going negative (%s)" % str(ok)
	if not ExecutiveManager.launch_cash_text(ok).contains("Il vous restera ~40 000 €"):
		return "H5: the player must read how much will remain at launch: %s" % ExecutiveManager.launch_cash_text(ok)
	var tight := ExecutiveManager.launch_cash_projection(8, 2000)
	if not ExecutiveManager.launch_cash_text(tight).begins_with("Serré"):
		return "H5: 20 000 € left with 10 000 €/month of costs must be flagged as tight: %s" % ExecutiveManager.launch_cash_text(tight)
	var bad := ExecutiveManager.launch_cash_projection(14, 2000)
	if int(bad.negative_month) != 11:
		return "H5: cash should hit zero in month 11 (%s)" % str(bad)
	if not ExecutiveManager.launch_cash_text(bad).begins_with("⚠"):
		return "H5: a project that empties the bank must be flagged"
	# Les ventes récentes comptent : avec des ventes, la même dépense devient tenable.
	Economy.history = [{"result":20000}]
	if int(ExecutiveManager.launch_cash_projection(14, 2000).negative_month) != -1:
		return "H5: recent profits must be part of the projection"
	return ""
