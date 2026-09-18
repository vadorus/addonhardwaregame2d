extends Node

signal money_changed(amount)
signal month_closed(report)
signal transaction_recorded(kind, category, amount)
signal financing_changed(debt)
signal solvency_warning(message)
signal bankruptcy_triggered(report)

const MAX_DEBT := 1_000_000
const MONTHLY_INTEREST_RATE := 0.012
const BANKRUPTCY_CASH_THRESHOLD := -1_000_000
const BANKRUPTCY_NEGATIVE_MONTHS := 3

var money: int = 500_000
var debt: int = 0
var negative_months: int = 0
var monthly_income: int = 0
var monthly_expenses: int = 0
var income_breakdown: Dictionary = {}
var expense_breakdown: Dictionary = {}
var history: Array = []
var bankrupt := false

func reset(starting_capital: int = 500_000):
	money = starting_capital
	debt = 0
	negative_months = 0
	monthly_income = 0
	monthly_expenses = 0
	income_breakdown = {}
	expense_breakdown = {}
	history = []
	bankrupt = false
	money_changed.emit(money)
	financing_changed.emit(debt)

func request_financing(amount: int = 250_000) -> bool:
	if amount <= 0 or debt + amount > MAX_DEBT:
		return false
	debt += amount
	money += amount
	money_changed.emit(money)
	financing_changed.emit(debt)
	transaction_recorded.emit("financing", "Financement bancaire", amount)
	return true

func repay_financing(amount: int = 100_000) -> bool:
	var repayment := mini(maxi(amount, 0), debt)
	if repayment <= 0 or money < repayment:
		return false
	debt -= repayment
	money -= repayment
	money_changed.emit(money)
	financing_changed.emit(debt)
	transaction_recorded.emit("financing_repayment", "Remboursement financement", repayment)
	return true

func effective_monthly_interest_rate() -> float:
	return MONTHLY_INTEREST_RATE * CompanyManager.get_finance_interest_modifier()

func projected_monthly_interest() -> int:
	if debt <= 0:
		return 0
	return maxi(1, int(round(float(debt) * effective_monthly_interest_rate())))

func process_financing_month():
	var interest := projected_monthly_interest()
	if interest <= 0:
		return
	add_expense(interest, "Intérêts financement")

func solvency_status() -> String:
	if bankrupt:
		return "BANKRUPT"
	if money <= -500_000 or debt >= 900_000:
		return "CRITICAL"
	if money < 0 or debt >= 500_000:
		return "TENSE"
	return "STABLE"

func _largest_breakdown_entry(data: Dictionary) -> Dictionary:
	var best_category := ""
	var best_amount := 0
	for category_value in data.keys():
		var category := str(category_value)
		var amount := int(data.get(category, 0))
		if amount > best_amount:
			best_amount = amount
			best_category = category
	return {"category": best_category, "amount": best_amount}

func financial_snapshot() -> Dictionary:
	var recent_results: Array[int] = []
	var start_index := maxi(history.size() - 3, 0)
	for i in range(start_index, history.size()):
		recent_results.append(int(history[i].get("result", 0)))

	var average_result := 0.0
	if not recent_results.is_empty():
		for result_value in recent_results:
			average_result += float(result_value)
		average_result /= float(recent_results.size())

	var latest: Dictionary = {}
	var previous: Dictionary = {}
	if history.size() > 0:
		latest = history[history.size() - 1]
	if history.size() > 1:
		previous = history[history.size() - 2]

	var trend := "NO_DATA"
	if not latest.is_empty():
		trend = "STABLE"
		if not previous.is_empty():
			var delta := int(latest.get("result", 0)) - int(previous.get("result", 0))
			if delta >= 10_000:
				trend = "IMPROVING"
			elif delta <= -10_000:
				trend = "WORSENING"

	var runway_months := -1.0
	if average_result < 0.0:
		runway_months = maxf(float(money), 0.0) / maxf(absf(average_result), 1.0)

	var expense_source: Dictionary = latest.get("expense_breakdown", {}) if not latest.is_empty() else expense_breakdown
	var income_source: Dictionary = latest.get("income_breakdown", {}) if not latest.is_empty() else income_breakdown
	var top_expense := _largest_breakdown_entry(expense_source)
	var top_income := _largest_breakdown_entry(income_source)
	var projected_interest := projected_monthly_interest()

	var recommendation := "Continuez à investir sans dépasser votre capacité de financement."
	var status := solvency_status()
	if status == "BANKRUPT":
		recommendation = "La partie est terminée : l'entreprise est insolvable."
	elif status == "CRITICAL":
		recommendation = "Réduisez le principal poste de dépense ou sécurisez rapidement du financement."
	elif status == "TENSE":
		recommendation = "Priorisez le prochain lancement rentable et évitez une nouvelle hausse des charges fixes."
	elif average_result < 0.0 and runway_months >= 0.0 and runway_months < 4.0:
		recommendation = "Moins de 4 mois de trésorerie au rythme récent : réduisez les dépenses ou accélérez un lancement."
	elif average_result > 0.0:
		recommendation = "Les trois derniers mois sont globalement positifs : gardez une réserve avant d'augmenter les charges fixes."

	return {
		"average_result_3m": average_result,
		"trend": trend,
		"runway_months": runway_months,
		"top_expense": top_expense,
		"top_income": top_income,
		"projected_interest": projected_interest,
		"effective_interest_rate": effective_monthly_interest_rate(),
		"debt_capacity_remaining": maxi(MAX_DEBT - debt, 0),
		"recommendation": recommendation
	}

func add_income(amount: int, category: String = "Autres revenus"):
	if amount <= 0:
		return
	monthly_income += amount
	money += amount
	income_breakdown[category] = int(income_breakdown.get(category, 0)) + amount
	money_changed.emit(money)
	transaction_recorded.emit("income", category, amount)

func add_expense(amount: int, category: String = "Autres dépenses"):
	if amount <= 0:
		return
	monthly_expenses += amount
	money -= amount
	expense_breakdown[category] = int(expense_breakdown.get(category, 0)) + amount
	money_changed.emit(money)
	transaction_recorded.emit("expense", category, amount)

func close_month() -> Dictionary:
	if money < 0:
		negative_months += 1
	else:
		negative_months = 0
	var bankruptcy_now := false
	if not bankrupt and money <= BANKRUPTCY_CASH_THRESHOLD and negative_months >= BANKRUPTCY_NEGATIVE_MONTHS:
		bankrupt = true
		bankruptcy_now = true
	var status := solvency_status()
	if status == "BANKRUPT":
		solvency_warning.emit("Faillite : l'entreprise est durablement insolvable.")
	elif status == "CRITICAL":
		solvency_warning.emit("Trésorerie critique : réduisez les dépenses, lancez un produit ou cherchez un financement.")
	elif status == "TENSE":
		solvency_warning.emit("Trésorerie sous tension : surveillez votre dette et votre prochain lancement.")
	var report := {
		"income": monthly_income,
		"expenses": monthly_expenses,
		"result": monthly_income - monthly_expenses,
		"money": money,
		"debt": debt,
		"negative_months": negative_months,
		"solvency_status": status,
		"bankrupt": bankrupt,
		"income_breakdown": income_breakdown.duplicate(true),
		"expense_breakdown": expense_breakdown.duplicate(true),
		"month": TimeManager.month,
		"year": TimeManager.year
	}
	history.append(report.duplicate(true))
	if history.size() > 36:
		history.pop_front()
	monthly_income = 0
	monthly_expenses = 0
	income_breakdown = {}
	expense_breakdown = {}
	month_closed.emit(report)
	if bankruptcy_now:
		bankruptcy_triggered.emit(report)
	return report

func get_state() -> Dictionary:
	return {
		"money":money, "debt":debt, "negative_months":negative_months,
		"monthly_income":monthly_income, "monthly_expenses":monthly_expenses,
		"income_breakdown":income_breakdown, "expense_breakdown":expense_breakdown,
		"history":history, "bankrupt":bankrupt
	}

func load_state(state: Dictionary):
	money = int(state.get("money", 500000))
	debt = int(state.get("debt", 0))
	negative_months = int(state.get("negative_months", 0))
	monthly_income = int(state.get("monthly_income", 0))
	monthly_expenses = int(state.get("monthly_expenses", 0))
	income_breakdown = state.get("income_breakdown", {}).duplicate(true)
	expense_breakdown = state.get("expense_breakdown", {}).duplicate(true)
	history = state.get("history", []).duplicate(true)
	bankrupt = bool(state.get("bankrupt", false))
	money_changed.emit(money)
	financing_changed.emit(debt)
