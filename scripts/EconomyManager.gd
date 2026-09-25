extends Node

signal money_changed(amount)
signal month_closed(report)
signal transaction_recorded(kind, category, amount)

var money: int = 500_000
var monthly_income: int = 0
var monthly_expenses: int = 0
var income_breakdown: Dictionary = {}
var expense_breakdown: Dictionary = {}
var history: Array = []

func reset(starting_capital: int = 100_000):
	money = starting_capital
	monthly_income = 0
	monthly_expenses = 0
	income_breakdown = {}
	expense_breakdown = {}
	history = []
	money_changed.emit(money)

func add_income(amount: int, category: String = "Autres revenus"):
	if amount <= 0:
		return
	monthly_income += amount
	money += amount
	income_breakdown[category] = int(income_breakdown.get(category, 0)) + amount
	money_changed.emit(money)
	transaction_recorded.emit("income", category, amount)

func quoted_expense(amount: int, category: String = "Autres dépenses") -> int:
	return BalanceManager.expense_amount(amount, category)

func can_afford(amount: int, category: String = "Autres dépenses") -> bool:
	return money >= quoted_expense(amount, category)

func add_expense(amount: int, category: String = "Autres dépenses"):
	if amount <= 0:
		return
	var charged := quoted_expense(amount, category)
	monthly_expenses += charged
	money -= charged
	expense_breakdown[category] = int(expense_breakdown.get(category, 0)) + charged
	money_changed.emit(money)
	transaction_recorded.emit("expense", category, charged)

func close_month() -> Dictionary:
	var report := {
		"income": monthly_income,
		"expenses": monthly_expenses,
		"result": monthly_income - monthly_expenses,
		"money": money,
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
	return report

func get_state() -> Dictionary:
	return {
		"money":money, "monthly_income":monthly_income, "monthly_expenses":monthly_expenses,
		"income_breakdown":income_breakdown, "expense_breakdown":expense_breakdown,
		"history":history
	}

func load_state(state: Dictionary):
	money = int(state.get("money", 500000))
	monthly_income = int(state.get("monthly_income", 0))
	monthly_expenses = int(state.get("monthly_expenses", 0))
	income_breakdown = state.get("income_breakdown", {}).duplicate(true)
	expense_breakdown = state.get("expense_breakdown", {}).duplicate(true)
	history = state.get("history", []).duplicate(true)
	money_changed.emit(money)
