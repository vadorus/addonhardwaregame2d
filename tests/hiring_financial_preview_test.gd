extends Node
## BUD-01 : un devis de recrutement ne doit modifier aucune valeur de simulation.

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	SimulationManager.reset_all("Test recrutement", "CPU", "STANDARD")
	Economy.money = 20000
	var candidate := {"salary":6000, "name":"Profil de test"}
	var money_before := Economy.money
	var staff_before := PersonnelManager.staff.size()
	var quote: Dictionary = PersonnelManager.hiring_financial_preview(candidate)
	if int(quote.get("signing_cost", -1)) != Economy.quoted_expense(12000, "Recrutement"):
		_fail("Prime de recrutement incorrecte")
		return
	if int(quote.get("monthly_cost", -1)) != Economy.quoted_expense(6000, "Salaires"):
		_fail("Salaire mensuel incorrect")
		return
	if int(quote.get("cash_after", -1)) != money_before - int(quote.get("signing_cost", 0)):
		_fail("Trésorerie après recrutement incorrecte")
		return
	if not bool(quote.get("can_pay_signing", false)):
		_fail("Prime pourtant finançable signalée impossible")
		return
	if Economy.money != money_before or PersonnelManager.staff.size() != staff_before:
		_fail("Le devis a muté la partie")
		return
	Economy.money = 5000
	quote = PersonnelManager.hiring_financial_preview(candidate)
	if bool(quote.get("can_pay_signing", true)):
		_fail("Recrutement impossible présenté comme finançable")
		return
	if int(quote.get("shortfall", 0)) != int(quote.get("signing_cost", 0)) - Economy.money:
		_fail("Montant manquant incohérent")
		return
	if not PersonnelManager.hiring_financial_preview({}).is_empty():
		_fail("Devis vide doit rester vide")
		return
	print("[CI] HiringFinancialPreviewTest PASS")
	get_tree().quit(0)

func _fail(reason: String) -> void:
	push_error("[CI] HiringFinancialPreviewTest FAIL: " + reason)
	get_tree().quit(1)
