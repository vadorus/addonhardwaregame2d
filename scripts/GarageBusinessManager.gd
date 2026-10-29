extends Node
## Lot B (29/09) — les petites affaires du garage, pour remplir le début de partie.
##
## 1. Contrats d'études (sous-traitance, comme les contrats de Game Dev Tycoon) : un client vient au
##    garage avec une petite puce à concevoir. Accepter = une avance tout de suite, le solde à la
##    livraison, mais une partie de l'équipe Développement est occupée (le CPU maison avance moins vite).
## 2. Prêt bancaire proposé par Nora quand la trésorerie tient moins de 6 mois.
## 3. Grands moments du premier CPU : « premier silicium » et « tri des puces » (drapeaux « déjà vu »).

signal business_changed

const STUDY_TEMPLATES := [
	{"customer":"Delta Office", "task":"une puce de calculatrice de bureau", "months":2, "pay":15000, "load":0.30},
	{"customer":"Pioneer Toys", "task":"le contrôleur d'un jouet électronique", "months":2, "pay":12000, "load":0.25},
	{"customer":"Vector Controls", "task":"un contrôleur de machine-outil", "months":3, "pay":22000, "load":0.35},
	{"customer":"Nova Laboratories", "task":"un circuit de mesure pour laboratoire", "months":3, "pay":26000, "load":0.40},
	{"customer":"Atlas Automobile", "task":"un module d'allumage électronique", "months":3, "pay":24000, "load":0.35},
	{"customer":"Northstar Office", "task":"le contrôleur d'un terminal de saisie", "months":2, "pay":18000, "load":0.30},
]
const OFFER_INTERVAL_MONTHS := 3
const OFFER_EXPIRY_MONTHS := 2
const ADVANCE_SHARE := 0.25
const LOAN_MONTHS := 36
const LOAN_COST := 0.20 # 20 % d'intérêts sur la durée

var studies: Array = []
var loans: Array = []
var flags: Dictionary = {}
var _next_study_id := 1
var _next_loan_id := 1
var _months_since_study := 0
var _template_turn := 0
var _cash_warning_shown := false # Transient : une partie rechargée réaffiche le risque actuel.
var _negative_cash_warning_shown := false # Transient : réarmé dès le retour à un solde positif.

func _ready() -> void:
	TimeManager.day_changed.connect(func(_day, _month, _year): check_cash_safety())

## Nora interrompt le temps avant la prochaine clôture, même au premier mois.
func check_cash_safety() -> void:
	if not CompanyManager.created or SimulationManager.is_game_over:
		return
	if Economy.money > 0:
		_negative_cash_warning_shown = false
	var reserve := cash_runway_months()
	if reserve > 3.0:
		_cash_warning_shown = false
		return
	if reserve >= 2.0:
		return
	if Economy.money < 0:
		if _negative_cash_warning_shown:
			return
		_negative_cash_warning_shown = true
	else:
		if _cash_warning_shown:
			return
	_cash_warning_shown = true
	CompanyManager.add_alert(("Nora : trésorerie négative, faillite à la clôture si rien ne change. Jeu en pause : utilisez ▶ pour reprendre." if Economy.money < 0 else "Nora : attention, la trésorerie couvre moins de deux mois de dépenses. Jeu en pause : après la décision, utilisez ▶ pour reprendre."))
	TimeManager.time_scale = 0.0
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("open_dialogue"):
		_open_cash_warning.call_deferred(scene, "FINANCE:LOAN" if loan_offer_pending() else "FINANCE:WARNING")

## La clôture peut déclarer la faillite après le contrôle de trésorerie,
## avant que la file des appels différés ouvre le dialogue.
func _open_cash_warning(scene: Node, key: String) -> void:
	if SimulationManager.is_game_over or not is_instance_valid(scene):
		return
	scene.call("open_dialogue", key)

## Devis sans effet : mêmes catégories de paiement que l'usine, difficulté comprise.
func fabrication_cash_quote(job_id: String, provider: String, strategy: String, binning: String) -> Dictionary:
	var preview := ProductionManager.preview_industrialization(job_id, provider, strategy, binning)
	if preview.is_empty():
		return {}
	var job := ProductionManager.get_job(job_id)
	var route := FoundryManager.route_quote("INTERNAL" if provider == "INTERNAL" else "EXTERNAL", provider, int(job.get("node_nm", 10000)))
	var setup := 0 if bool(job.get("route_committed", false)) else Economy.quoted_expense(int(preview.get("setup_fee", 0)), "Mise en production — %s" % str(route.get("provider_name", "fabrication")))
	var monthly := Economy.quoted_expense(int(preview.get("monthly_cost", 0)), "Industrialisation — %s (%s)" % [str(job.get("name", "CPU")), str(route.get("provider_name", "fabrication"))])
	var months := int(preview.get("preparation_months", 1))
	var projection := ExecutiveManager.launch_cash_projection(months, monthly, setup)
	return {"cash":Economy.money, "setup":setup, "monthly":monthly, "months":months,
		"job_id":job_id, "total":setup + monthly * months, "lowest":int(projection.lowest), "cash_end":int(projection.cash_end)}

## Recherche sans mutation ni tirage aléatoire : coût total industriel minimal,
## avec toutes les clôtures projetées non négatives (charges comprises).
func cheapest_affordable_fabrication(job_id: String) -> Dictionary:
	var job := ProductionManager.get_job(job_id)
	if job.is_empty() or bool(job.get("route_committed", false)):
		return {}
	var providers := FoundryManager.available_external_foundries(int(job.node_nm))
	if FoundryManager.internal_supports_node(int(job.node_nm)):
		providers.append("INTERNAL")
	var best := {}
	for provider in providers:
		for strategy in ProductionManager.get_strategy_keys():
			for binning in ProductionManager.get_binning_strategy_keys():
				var option := fabrication_cash_quote(job_id, str(provider), str(strategy), str(binning))
				if option.is_empty() or int(option.lowest) < 0:
					continue
				if best.is_empty() or int(option.total) < int(best.total):
					best = option
					best["label"] = "%s / %s / %s" % ["Interne" if provider == "INTERNAL" else FoundryManager.external_foundry_label(str(provider)), ProductionManager.strategy_label(str(strategy)), ProductionManager.binning_strategy_label(str(binning))]
	return best

func fabrication_cash_text(quote: Dictionary) -> String:
	var option := cheapest_affordable_fabrication(str(quote.get("job_id", "")))
	var alternative := "Aucune option ne garde un solde projeté positif ou nul avec la trésorerie actuelle."
	if not option.is_empty():
		alternative = "Option finançable la moins chère (estimation) : %s — %d €, réserve minimale %d €. Revenez au choix de fabrication pour la sélectionner." % [str(option.label), int(option.total), int(option.lowest)]
	return "Trésorerie disponible : %d €.\nFabrication estimée : %d € (%d € de mise en route + %d €/mois pendant %d mois).\nAvec les autres dépenses et revenus récents, le solde pourrait descendre à %d € avant les premières ventes.\n\n%s\n\nContinuer malgré le risque de faillite ?" % [int(quote.cash), int(quote.total), int(quote.setup), int(quote.monthly), int(quote.months), int(quote.lowest), alternative]

func reset() -> void:
	_cash_warning_shown = false
	_negative_cash_warning_shown = false
	studies = []
	loans = []
	flags = {}
	_next_study_id = 1
	_next_loan_id = 1
	_months_since_study = 0
	_template_turn = 0
	business_changed.emit()

# --- Contrats d'études ---------------------------------------------------------

func open_offers() -> Array:
	return studies.filter(func(s): return str(s.get("status", "")) == "OFFER")

func active_studies() -> Array:
	return studies.filter(func(s): return str(s.get("status", "")) == "ACTIVE")

func get_study(study_id: String) -> Dictionary:
	for study_value in studies:
		if str((study_value as Dictionary).get("id", "")) == study_id:
			return study_value
	return {}

## Part de l'équipe Développement qui reste sur les projets maison (1,0 = tout le monde).
func development_speed_factor() -> float:
	var busy_share := 0.0
	for study_value in active_studies():
		busy_share += float((study_value as Dictionary).get("load", 0.0))
	return clampf(1.0 - busy_share, 0.45, 1.0)

func study_window_open() -> bool:
	if not CompanyManager.created or ExecutiveManager.months_operated < 2:
		return false
	# Une activité de garage : elle s'efface quand l'entreprise vit de ses propres CPU.
	# Les études financent aussi le premier CPU ; une seule offre client à la fois.
	if MarketManager.b2b_offer_waiting():
		return false
	var generations := ProductManager.cpu_generations.size()
	return PersonnelManager.staff.size() < 12 and (generations < 3 or Economy.money < 300000)

func _era_pay(base: int) -> int:
	var factor := clampf(1.0 + 0.06 * float(maxi(TimeManager.year - 1971, 0)), 1.0, 2.5)
	return int(round(float(base) * factor / 500.0)) * 500

func _spawn_offer() -> Dictionary:
	var template: Dictionary = STUDY_TEMPLATES[_template_turn % STUDY_TEMPLATES.size()]
	_template_turn += 1
	var study := {
		"id":"STUDY-%03d" % _next_study_id,
		"customer":str(template.customer), "task":str(template.task),
		"months":int(template.months), "pay":_era_pay(int(template.pay)), "load":float(template.load),
		"status":"OFFER", "age":0, "progress_months":0,
		"month":TimeManager.month, "year":TimeManager.year
	}
	_next_study_id += 1
	_months_since_study = 0
	studies.push_front(study)
	if studies.size() > 24:
		studies.pop_back()
	CompanyManager.add_alert("%s passe au garage : il cherche quelqu'un pour concevoir %s." % [str(study.customer), str(study.task)])
	business_changed.emit()
	return study

func study_advance(study: Dictionary) -> int:
	return int(round(float(study.get("pay", 0)) * ADVANCE_SHARE))

func accept_study(study_id: String) -> bool:
	var study := get_study(study_id)
	if study.is_empty() or str(study.get("status", "")) != "OFFER":
		return false
	study["status"] = "ACTIVE"
	var advance := study_advance(study)
	if advance > 0:
		Economy.add_income(advance, "Avance contrat d'études — %s" % str(study.customer))
	CompanyManager.add_alert("Contrat signé avec %s : %s, livraison dans %d mois." % [str(study.customer), str(study.task), int(study.months)])
	business_changed.emit()
	return true

func decline_study(study_id: String) -> bool:
	var study := get_study(study_id)
	if study.is_empty() or str(study.get("status", "")) != "OFFER":
		return false
	study["status"] = "DECLINED"
	business_changed.emit()
	return true

func _complete_study(study: Dictionary) -> void:
	study["status"] = "DONE"
	var balance := int(study.get("pay", 0)) - study_advance(study)
	Economy.add_income(balance, "Contrat d'études — %s" % str(study.customer))
	CompanyManager.change_reputation({"professional":1.0})
	# Concevoir pour les autres, c'est aussi apprendre (un peu).
	ResearchManager.raise_technology("cpu", 0.35)
	CompanyManager.add_alert("Livré à %s : %s. Solde encaissé (%d €)." % [str(study.customer), str(study.task), balance])

func _process_studies() -> void:
	for study_value in studies:
		var study: Dictionary = study_value
		match str(study.get("status", "")):
			"OFFER":
				study["age"] = int(study.get("age", 0)) + 1
				if int(study.age) >= OFFER_EXPIRY_MONTHS:
					study["status"] = "EXPIRED"
					CompanyManager.add_alert("%s a trouvé un autre prestataire." % str(study.customer))
			"ACTIVE":
				study["progress_months"] = int(study.get("progress_months", 0)) + 1
				if int(study.progress_months) >= int(study.get("months", 2)):
					_complete_study(study)
	_months_since_study += 1
	if not open_offers().is_empty() or not active_studies().is_empty() or not study_window_open():
		return
	# Trésorerie tendue : les clients reviennent plus vite.
	var interval := 1 if cash_runway_months() < 6.0 else OFFER_INTERVAL_MONTHS
	if _months_since_study >= interval:
		_spawn_offer()

# --- Prêt bancaire ----------------------------------------------------------------

func cash_runway_months() -> float:
	return float(ExecutiveManager.financial_advice().get("runway_months", 99.0))

func active_loan() -> Dictionary:
	for loan_value in loans:
		if str((loan_value as Dictionary).get("status", "")) == "ACTIVE":
			return loan_value
	return {}

func loan_offer_pending() -> bool:
	if not CompanyManager.created or not active_loan().is_empty():
		return false
	if ExecutiveManager.months_operated < 3 and cash_runway_months() >= 2.0:
		return false
	if ExecutiveManager.months_operated < int(flags.get("loan_next_offer_at", 0)):
		return false
	return cash_runway_months() < 6.0 and Economy.money < 150000

func loan_terms() -> Dictionary:
	var expenses := 0.0
	var count := 0
	for i in range(maxi(Economy.history.size() - 3, 0), Economy.history.size()):
		expenses += float((Economy.history[i] as Dictionary).get("expenses", 0))
		count += 1
	var monthly := expenses / float(maxi(count, 1))
	var amount := clampi(int(round(maxf(60000.0, monthly * 6.0) / 5000.0)) * 5000, 60000, 400000)
	var total := int(round(float(amount) * (1.0 + LOAN_COST)))
	return {"amount":amount, "months":LOAN_MONTHS, "monthly":int(ceil(float(total) / float(LOAN_MONTHS))), "total":total}

func accept_loan() -> bool:
	if not active_loan().is_empty():
		return false
	var terms := loan_terms()
	var loan := {"id":"LOAN-%02d" % _next_loan_id, "amount":int(terms.amount), "monthly":int(terms.monthly),
		"remaining_months":int(terms.months), "status":"ACTIVE", "month":TimeManager.month, "year":TimeManager.year}
	_next_loan_id += 1
	loans.push_front(loan)
	Economy.add_income(int(terms.amount), "Prêt bancaire")
	CompanyManager.add_alert("Prêt accordé : %d € versés, %d €/mois pendant %d mois." % [int(terms.amount), int(terms.monthly), int(terms.months)])
	business_changed.emit()
	return true

func decline_loan() -> void:
	flags["loan_next_offer_at"] = ExecutiveManager.months_operated + 12
	business_changed.emit()

func _process_loans() -> void:
	for loan_value in loans:
		var loan: Dictionary = loan_value
		if str(loan.get("status", "")) != "ACTIVE":
			continue
		Economy.add_expense(int(loan.get("monthly", 0)), "Remboursement prêt bancaire")
		loan["remaining_months"] = int(loan.get("remaining_months", 0)) - 1
		if int(loan.remaining_months) <= 0:
			loan["status"] = "REPAID"
			CompanyManager.add_alert("Prêt bancaire entièrement remboursé.")

# --- Grands moments du premier CPU ---------------------------------------------------

## Premier prototype sous tension : la revue prototype du tout premier CPU vient de s'ouvrir.
func first_silicon_project() -> Dictionary:
	if bool(flags.get("first_silicon_shown", false)) or not ProductManager.cpu_generations.is_empty():
		return {}
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		var pending = project.get("pending_decision", {})
		if typeof(pending) == TYPE_DICTIONARY and str((pending as Dictionary).get("type", "")) == "PROTOTYPE_REVIEW":
			return project
	return {}

## Premières puces sorties d'usine : la toute première génération vient d'être triée.
func first_binning_generation() -> Dictionary:
	if bool(flags.get("first_binning_shown", false)) or ProductManager.cpu_generations.is_empty():
		return {}
	return ProductManager.cpu_generations[0]

func mark_shown(flag: String) -> void:
	flags[flag] = true
	business_changed.emit()

# --- Mois --------------------------------------------------------------------------

func process_month() -> void:
	if not CompanyManager.created:
		return
	_process_studies()
	_process_loans()

func get_state() -> Dictionary:
	return {"studies":studies, "loans":loans, "flags":flags, "next_study_id":_next_study_id, "next_loan_id":_next_loan_id,
		"months_since_study":_months_since_study, "template_turn":_template_turn}

func load_state(state: Dictionary) -> void:
	_cash_warning_shown = false
	_negative_cash_warning_shown = false
	studies = state.get("studies", []).duplicate(true)
	loans = state.get("loans", []).duplicate(true)
	flags = state.get("flags", {}).duplicate(true)
	_next_study_id = int(state.get("next_study_id", studies.size() + 1))
	_next_loan_id = int(state.get("next_loan_id", loans.size() + 1))
	_months_since_study = int(state.get("months_since_study", 0))
	_template_turn = int(state.get("template_turn", 0))
	# Partie d'avant le lot B déjà lancée : pas de « premier silicium » rétroactif.
	if not state.has("flags") and not ProductManager.cpu_generations.is_empty():
		flags["first_silicon_shown"] = true
		flags["first_binning_shown"] = true
	business_changed.emit()
