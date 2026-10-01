extends Node
## Sonde 10 ans (outil, pas un test CI) : trois joueurs automatiques jouent par le vrai chemin
## (projet → décisions → fabrication → lancement → ventes), pour vérifier que mieux jouer rapporte.
##  - NOVICE  : mode Accessible, ne recrute pas, un projet à la fois, ne touche à rien d'autre.
##  - INTER   : recrute quand l'argent le permet, déménage quand c'est plein, suit la demande.
##  - EXPERT  : recrute vite, deux projets en parallèle, budgets plus hauts, vise les gros marchés.
## Cible V0.10 (H3) : INTER ≥ 2 × NOVICE et EXPERT ≥ INTER sur 10 ans.
## Lancement : godot --headless --path . res://tests/tools/profiles_probe.tscn -- [années] [profils]

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CAREER := preload("res://scripts/CareerPrestige.gd")

const PROFILES := {
	"NOVICE":{"mode":"ACCESSIBLE", "hire_every":0, "hire_cash":0, "max_projects":1, "budget_ratio":0.85, "move":false, "expand":false, "reach":1.0},
	"INTER":{"mode":"STANDARD", "hire_every":6, "hire_cash":260000, "max_projects":1, "budget_ratio":1.0, "move":true, "expand":true, "reach":1.5},
	"EXPERT":{"mode":"STANDARD", "hire_every":3, "hire_cash":220000, "max_projects":2, "budget_ratio":1.25, "move":true, "expand":true, "reach":1.25}
}
const RETIRE_AFTER_MONTHS := 60

var _log: Array[String] = []
var _mode_override := ""

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var years := int(args[0]) if args.size() > 0 else 10
	var names: Array = (args[1].split(",") as Array) if args.size() > 1 else PROFILES.keys()
	# 3e argument (H6) : forcer un mode de difficulté pour tous les profils (ACCESSIBLE, STANDARD, SIMULATION).
	_mode_override = str(args[2]) if args.size() > 2 else ""
	var results := {}
	for profile_name in names:
		results[profile_name] = _play(str(profile_name), years)
	print("[PROFILES] ===== Bilan sur %d ans =====" % years)
	for profile_name in names:
		var r: Dictionary = results[profile_name]
		print("[PROFILES] %-7s trésorerie %s | CA dernier mois %s | ventes %s puces | équipe %d (dont %d dév.) | locaux %d | %d projets lancés | rang %d | dév. moyen %.1f mois, qualité %.0f%s" % [
			profile_name, _k(int(r.money)), _k(int(r.income)), _k(int(r.units)), int(r.staff), int(r.devs), int(r.tier), int(r.launches), int(r.rank), float(r.avg_dev_months), float(r.avg_quality),
			" | FAILLITE %s" % str(r.bankrupt) if str(r.bankrupt) != "" else ""])
	if results.has("NOVICE") and results.has("INTER"):
		var ratio := float(results.INTER.money) / maxf(float(results.NOVICE.money), 1.0)
		print("[PROFILES] INTER / NOVICE = %.2f (cible ≥ 2)" % ratio)
	get_tree().quit(0)

func _play(profile_name: String, years: int) -> Dictionary:
	var p: Dictionary = PROFILES[profile_name]
	SimulationManager.reset_all("Sonde %s" % profile_name, "CPU", _mode_override if _mode_override != "" else str(p.mode))
	var end_year := TimeManager.year + years
	var month_count := 0
	var launches := 0
	var last_income := 0
	var max_decisions := 0
	var max_total_decisions := 0
	var decision_kinds := {}
	var units := 0
	var bankrupt := ""
	var gen := 0
	while TimeManager.year < end_year:
		month_count += 1
		# 1) Recrutement (développeurs d'abord, un producteur tous les 4).
		# Un joueur raisonnable garde au moins 12 mois de réserve (H5 : il voit sa trésorerie projetée).
		var runway_ok := ExecutiveManager.recent_monthly_result() >= 0 or Economy.money > -ExecutiveManager.recent_monthly_result() * 24
		if int(p.hire_every) > 0 and month_count % int(p.hire_every) == 0 and Economy.money > int(p.hire_cash) and runway_ok:
			var room := int(ExecutiveManager.workplace_data().capacity) - PersonnelManager.staff.size()
			if room > 0:
				# Surtout des développeurs ; un producteur pour trois développeurs.
				var devs := PersonnelManager.count_department("Développement")
				var dept := "Production" if PersonnelManager.count_department("Production") * 3 < devs - 2 else "Développement"
				PersonnelManager.generate_candidate(dept)
				PersonnelManager.hire_candidate()
		# 2) Déménagement quand c'est plein et qu'on peut largement payer.
		if bool(p.move):
			var next := ExecutiveManager.next_workplace_upgrade()
			if not next.is_empty() and PersonnelManager.staff.size() >= int(ExecutiveManager.workplace_data().capacity) - 1 \
					and Economy.money > int(next.get("upgrade_cost", 0)) * 3:
				ExecutiveManager.renovate_workplace()
		# 3) Nouveau projet quand l'équipe est libre.
		var can_parallel := _active_projects() == 0 or (_all_projects_past_prototype() and Economy.money > 400000 \
			and int(ExecutiveManager.launch_cash_projection(14, MarketManager.segment_recommended_budget(_pick_segment(float(p.reach)))).negative_month) < 0)
		if _active_projects() < int(p.max_projects) and can_parallel:
			gen += 1
			var segment := _pick_segment(float(p.reach))
			var budget := int(MarketManager.segment_recommended_budget(segment) * float(p.budget_ratio))
			ResearchManager.start_project("%s %d" % [profile_name, gen], "CPU", segment, "INTERNAL", "BALANCED", budget, CPU_DESIGN.preset("BALANCED"))
		# 4) Décisions de projet, route de fabrication, lancements.
		for project_value in ResearchManager.projects:
			var project: Dictionary = project_value
			var pending := ResearchManager.get_project_decision(str(project.get("id", "")))
			if not pending.is_empty():
				ResearchManager.resolve_project_decision(str(project.id), "BALANCE" if str(pending.get("type", "")) == "PROTOTYPE_REVIEW" else "APPROVE")
		for job_value in ProductionManager.get_active_jobs():
			var job: Dictionary = job_value
			if not bool(job.get("route_selected", false)):
				ProductionManager.set_manufacturing_route(str(job.get("id", "")), "EXTERNAL", "")
		for product_value in ProductManager.products:
			var product: Dictionary = product_value
			if str(product.get("status", "")) == "READY":
				var capacity := maxi(1, int(product.get("recommended_capacity", product.get("production_capacity", 1))))
				if ProductManager.launch_product(str(product.get("id", "")), maxi(1, int(product.get("price", 1))), capacity):
					launches += 1
			elif str(product.get("status", "")) == "LAUNCHED" and int(product.get("months_on_market", 0)) >= RETIRE_AFTER_MONTHS:
				ProductManager.retire_product(str(product.id), true)
		# 4b) Menaces du marché : on se défend si on en a les moyens (comme la sonde de campagne).
		for threat in MarketManager.open_market_threats():
			var threat_id := str(threat.get("id", ""))
			MarketManager.resolve_market_threat(threat_id, Economy.money > MarketManager.threat_response_cost(threat_id) * 3)
		# 5) Le mois passe.
		var rep: Dictionary = SimulationManager.process_month_end()
		last_income = int(rep.get("income", 0))
		if OS.get_environment("PROBE_DEBUG") != "" and TimeManager.year >= 1974:
			var eb: Dictionary = Economy.history.back().get("expense_breakdown", {}) if not Economy.history.is_empty() else {}
			var top := eb.keys()
			top.sort_custom(func(a, b): return int(eb[a]) > int(eb[b]))
			var parts := []
			for k in top.slice(0, 6):
				parts.append("%s=%d" % [k, int(eb[k])])
			print("[DBG] %02d/%d money %d inc %d exp %d | %s" % [TimeManager.month, TimeManager.year, Economy.money, int(rep.get("income", 0)), int(rep.get("expenses", 0)), ", ".join(parts)])
		for product_value in ProductManager.products:
			var product: Dictionary = product_value
			if str(product.get("status", "")) != "LAUNCHED":
				continue
			units += int(product.get("last_month_sales", 0))
			if bool(p.expand):
				var demand := int(product.get("last_month_demand", 0))
				var lost := int(product.get("last_month_lost_sales", 0))
				if demand > 0 and lost >= maxi(20, int(demand * 0.10)):
					var quote := ProductManager.capacity_change_quote(str(product.id), demand)
					if int(quote.get("capacity", 0)) > int(product.get("production_capacity", 0)) and Economy.money > int(quote.get("cost", 0)) * 2:
						ProductManager.set_production_capacity(str(product.id), demand)
		var pending_decisions: Array = ExecutiveManager.get_ceo_decisions()
		if ExecutiveManager.visible_ceo_decisions().size() > max_decisions:
			max_decisions = ExecutiveManager.visible_ceo_decisions().size()
		if pending_decisions.size() > max_total_decisions:
			max_total_decisions = pending_decisions.size()
		for d in pending_decisions:
			var cat := str((d as Dictionary).get("category", "?"))
			decision_kinds[cat] = int(decision_kinds.get(cat, 0)) + 1
		_advance_month()
		if SimulationManager.is_game_over:
			bankrupt = "%02d/%d" % [TimeManager.month, TimeManager.year]
			break
		if TimeManager.month == 1:
			print("[PROFILES] %-7s %d | trésorerie %s | CA mois %s | équipe %d (dév %d) | locaux %d | modèles en vente %d" % [
				profile_name, TimeManager.year - 1, _k(Economy.money), _k(last_income), PersonnelManager.staff.size(),
				PersonnelManager.count_department("Développement"), int(ExecutiveManager.workplace.get("tier", 0)), ProductManager.launched_count()])
	var dev_months := 0.0
	var done := 0
	var quality := 0.0
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if str(project.get("status", "")) != "DEVELOPMENT" and int(project.get("months_spent", 0)) > 0:
			dev_months += float(project.get("months_spent", 0))
			var fm: Dictionary = project.get("final_metrics", {})
			var total := 0.0
			for value in fm.values():
				total += float(value)
			quality += total / maxf(float(fm.size()), 1.0)
			done += 1
	var nora_settled := CompanyManager.alerts.filter(func(a): return str(a).begins_with("Nora a tranché")).size()
	print("[PROFILES] %s décisions visibles : max %d (en tout max %d) | tranchées par Nora (alertes récentes) %d | mois-décisions %s" % [profile_name, max_decisions, max_total_decisions, nora_settled, str(decision_kinds)])
	return {"avg_dev_months":dev_months / maxf(done, 1.0), "avg_quality":quality / maxf(done, 1.0), "money":Economy.money, "income":last_income, "units":units, "staff":PersonnelManager.staff.size(),
		"devs":PersonnelManager.count_department("Développement"), "tier":int(ExecutiveManager.workplace.get("tier", 0)),
		"launches":launches, "rank":int(CAREER.player_rank()), "bankrupt":bankrupt}

func _active_projects() -> int:
	var count := 0
	for project_value in ResearchManager.projects:
		if str((project_value as Dictionary).get("status", "")) == "DEVELOPMENT":
			count += 1
	return count + ProductionManager.get_active_jobs().size()

func _all_projects_past_prototype() -> bool:
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if str(project.get("status", "")) == "DEVELOPMENT" and int(project.get("phase_index", 0)) < 2:
			return false
	return true

## Le plus gros marché ouvert que l'équipe peut raisonnablement porter.
func _pick_segment(reach: float) -> String:
	var devs := float(maxi(PersonnelManager.count_department("Développement"), 1))
	var best := "EMBEDDED"
	var best_value := -1.0
	for segment in MarketManager.SEGMENT_PROJECT_SCALE.keys():
		if not MarketManager.is_segment_available(segment):
			continue
		if float(MarketManager.segment_required_team(segment)) > devs * reach:
			continue
		var value := float(MarketManager.segment_market_units(segment)) * MarketManager.segment_reference_price(segment)
		if value > best_value:
			best_value = value
			best = segment
	return best

func _advance_month() -> void:
	TimeManager.month += 1
	if TimeManager.month > 12:
		TimeManager.month = 1
		TimeManager.year += 1

func _k(value: int) -> String:
	if absi(value) >= 1_000_000:
		return "%.2f M" % (value / 1_000_000.0)
	if absi(value) >= 1000:
		return "%d k" % int(value / 1000)
	return str(value)
