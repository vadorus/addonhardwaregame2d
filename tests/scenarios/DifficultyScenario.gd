extends RefCounted

static func run() -> String:
	if BalanceManager.active_profile != "STANDARD":
		return "Default CI game did not start on Standard economic balance"
	var balance_state := BalanceManager.get_state().duplicate(true)
	var standard_salary_cost := BalanceManager.expense_amount(10000, "Salaires")
	var standard_market_units := MarketManager.segment_market_units("EMBEDDED")
	var standard_runway := BalanceManager.starting_runway_months()

	BalanceManager.reset("ACCESSIBLE")
	var accessible_salary_cost := BalanceManager.expense_amount(10000, "Salaires")
	var accessible_market_units := MarketManager.segment_market_units("EMBEDDED")
	var accessible_capital := BalanceManager.starting_capital()
	var accessible_runway := BalanceManager.starting_runway_months()

	BalanceManager.reset("REALISTIC")
	var realistic_salary_cost := BalanceManager.expense_amount(10000, "Salaires")
	var realistic_market_units := MarketManager.segment_market_units("EMBEDDED")
	var realistic_capital := BalanceManager.starting_capital()
	var realistic_runway := BalanceManager.starting_runway_months()

	if not (accessible_salary_cost < standard_salary_cost and standard_salary_cost < realistic_salary_cost):
		BalanceManager.load_state(balance_state)
		return "Difficulty profiles do not change real payroll costs in the expected direction"
	if not (accessible_market_units > standard_market_units and standard_market_units > realistic_market_units):
		BalanceManager.load_state(balance_state)
		return "Difficulty profiles do not change available market demand"
	if accessible_capital <= 500000 or realistic_capital >= 500000:
		BalanceManager.load_state(balance_state)
		return "Difficulty profiles do not change starting liquidity"
	if accessible_runway <= standard_runway or realistic_runway >= standard_runway:
		BalanceManager.load_state(balance_state)
		return "Difficulty profiles do not create distinct starting runway pressure"

	var realistic_ai := BalanceManager.company_ai_profile()
	BalanceManager.reset("STANDARD")
	var standard_ai := BalanceManager.company_ai_profile()
	BalanceManager.reset("ACCESSIBLE")
	var accessible_ai := BalanceManager.company_ai_profile()
	if not (
		float(accessible_ai.get("decision_quality", 1.0)) < float(standard_ai.get("decision_quality", 0.0))
		and float(standard_ai.get("decision_quality", 1.0)) < float(realistic_ai.get("decision_quality", 0.0))
	):
		BalanceManager.load_state(balance_state)
		return "Difficulty does not scale competitor decision quality progressively"
	if not (
		int(accessible_ai.get("decision_interval_months", 0)) > int(standard_ai.get("decision_interval_months", 0))
		and int(standard_ai.get("decision_interval_months", 0)) > int(realistic_ai.get("decision_interval_months", 0))
	):
		BalanceManager.load_state(balance_state)
		return "Difficulty does not scale competitor reaction cadence progressively"

	BalanceManager.reset("REALISTIC")
	if absf(BalanceManager.competitor_pressure_factor() - 1.0) > 0.001:
		BalanceManager.load_state(balance_state)
		return "Realistic difficulty still gives competitors a hidden market/stat multiplier"
	if BalanceManager.expense_amount(10000, "Production — test CPU") != 10000:
		BalanceManager.load_state(balance_state)
		return "Difficulty changed literal per-unit production economics"
	if BalanceManager.expense_amount(10000, "SAV garanties — test CPU") != 10000:
		BalanceManager.load_state(balance_state)
		return "Difficulty changed literal warranty unit economics"

	BalanceManager.load_state(balance_state)
	if BalanceManager.active_profile != "STANDARD":
		return "Economic difficulty did not survive a state round-trip"
	return ""
