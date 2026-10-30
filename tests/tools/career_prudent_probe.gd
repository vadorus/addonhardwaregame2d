extends "res://tests/tools/career_probe.gd"
## CAREER-02 : expérience autonome, pas une modification de la difficulté du jeu.
## Mêmes stratégies officielles C3, avec prudence budgétaire au moment d'embaucher.
const HIRING_SIGNING_ESTIMATE := 12000
const HIRING_SALARY_ESTIMATE := 5607
const MIN_RUNWAY_MONTHS := 6.0

func _ready() -> void:
	print("[CAREER_PRUDENT] EXPERIMENTAL hiring_signing=%d monthly_salary=%d min_runway=%.1f months" % [
		HIRING_SIGNING_ESTIMATE, HIRING_SALARY_ESTIMATE, MIN_RUNWAY_MONTHS
	])
	super._ready()

func _can_hire() -> bool:
	if not super._can_hire():
		return false
	var advice: Dictionary = ExecutiveManager.financial_advice(HIRING_SIGNING_ESTIMATE, HIRING_SALARY_ESTIMATE)
	return bool(advice.get("can_afford", false)) and float(advice.get("runway_months", 0.0)) >= MIN_RUNWAY_MONTHS
