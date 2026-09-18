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

func process_financing_month():
	if debt <= 0:
		return
	var interest := maxi(1, int(round(float(debt) * MONTHLY_INTEREST_RATE)))
	add_expense(interest, "Intérêts financement")

func solvency_status() -> String:
	if bankrupt:
		return "BANKRUPT"
	if money <= -500_000 or debt >= 900_000:
		return "CRITICAL"
	if money < 0 or debt >= 500_000:
		return "TENSE"
	return "STABLE"

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
