extends Node
## C3 — sonde de carrière longue. Outil de mesure uniquement, hors CI.
## Lance trois stratégies par le vrai chemin projet -> décisions -> fabrication -> lancement -> ventes.
## Usage : godot --headless --path . res://tests/tools/career_probe.tscn -- [graines] [mode]

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const ARCH_CATALOG := preload("res://scripts/ArchitectureCatalog.gd")
const CAREER := preload("res://scripts/CareerPrestige.gd")
const SALES_ADVISOR := preload("res://scripts/SalesAdvisor.gd")
const PROFILES_PROBE := preload("res://tests/tools/profiles_probe.gd")

const STRATEGIES := ["FIGEE", "ADAPTEE", "EN_RETARD"]
const DEFAULT_SEEDS := [104729, 208877, 313133, 417401, 521657, 625919]
const MARKETS := ["CALCULATOR", "EMBEDDED", "INDUSTRIAL", "SCIENTIFIC", "HOBBYIST", "BUSINESS_PC", "HOME_PC", "WORKSTATION", "SERVER", "GAMING", "MOBILE_COMPUTING", "DATACENTER"]
const END_YEAR := 2030
const REFRESH_AFTER_MONTHS := 36
const RETIRE_AFTER_MONTHS := 60

var _profiles

func _ready() -> void:
	_profiles = PROFILES_PROBE.new()
	var args := OS.get_cmdline_user_args()
	var seeds := _parse_seeds(str(args[0])) if args.size() > 0 else DEFAULT_SEEDS.duplicate()
	var mode := str(args[1]).to_upper() if args.size() > 1 else "STANDARD"
	if mode not in ["STANDARD", "ACCESSIBLE"]:
		push_error("[C3] mode attendu : STANDARD ou ACCESSIBLE")
		get_tree().quit(2)
		return
	var root := DirAccess.open("res://")
	if root != null:
		root.make_dir_recursive("build")
	print("[C3] commit=eff0871 mode=%s seeds=%s" % [mode, str(seeds)])
	for seed_value in seeds:
		var seed := int(seed_value)
		for strategy in STRATEGIES:
			_run_strategy(str(strategy), seed, mode)
	_profiles.free()
	get_tree().quit(0)

func _parse_seeds(raw: String) -> Array:
	var out: Array = []
	for bit in raw.split(",", false):
		var text := str(bit).strip_edges()
		if text.is_valid_int():
			out.append(int(text))
	return out if not out.is_empty() else DEFAULT_SEEDS.duplicate()

func _seed_world(seed: int) -> void:
	# Semer avant reset rend aussi reproductible ce que les reset consomment ;
	# semer après reset donne ensuite le même flux aux trois stratégies.
	PersonnelManager.rng.seed = seed + 101
	ResearchManager.rng.seed = seed + 211
	ProductionManager.rng.seed = seed + 307
	AfterSalesManager.rng.seed = seed + 401
	FoundryManager.rng.seed = seed + 503
	MarketManager.rng.seed = seed + 601
	SupplierManager.rng.seed = seed + 701

func _run_strategy(strategy: String, seed: int, mode: String) -> void:
	_seed_world(seed)
	SimulationManager.reset_all("C3 %s %d" % [strategy, seed], "CPU", mode)
	_seed_world(seed)
	var first_arch := "A4"
	var fixed_segment := MarketManager.default_segment()
	var state := {
		"strategy":strategy, "seed":seed, "mode":mode,
		"segment":fixed_segment, "fixed_segment":fixed_segment,
		"first_arch":first_arch, "line_by_segment":{},
		"base_design":CPU_DESIGN.preset("BALANCED"),
		"generation":0, "force_project":false,
		"annual_decisions":[], "all_decisions":[],
		"year_revenue":0, "year_margin":0, "year_lost":0,
		"cumulative_margin":0, "first_rank1":-1,
		"lost_rank1":false, "rank1_idle_years":[], "blocker":"",
		"baseline_staff":_department_counts()
	}
	var path := "res://build/career_%s_%s_seed%d.csv" % [mode.to_lower(), strategy.to_lower(), seed]
	var csv := FileAccess.open(path, FileAccess.WRITE)
	if csv == null:
		push_error("[C3] impossible d'ouvrir %s" % path)
		return
	_write_header(csv)
	while TimeManager.year <= _end_year() and not SimulationManager.is_game_over:
		if strategy == "FIGEE":
			_replace_departures(state)
		else:
			_adapt_staff_and_rnd(state)
		_resolve_project_decisions(state)
		_route_production(state)
		_launch_ready_products(state)
		_retire_if_needed(state)
		_maybe_start_project(state)
		_handle_market_threats(state)
		_extra_month(state)
		var report: Dictionary = SimulationManager.process_month_end()
		state.year_revenue = int(state.year_revenue) + int(report.get("income", 0))
		state.year_margin = int(state.year_margin) + int(report.get("result", 0))
		state.cumulative_margin = int(state.cumulative_margin) + int(report.get("result", 0))
		state.year_lost = int(state.year_lost) + _monthly_lost_demand()
		if strategy != "FIGEE":
			_follow_sales_advice(state)
			_react_to_rival(state)
		var rank := int(CAREER.player_rank())
		if rank == 1 and int(state.first_rank1) < 0:
			state.first_rank1 = TimeManager.year
		elif int(state.first_rank1) >= 0 and rank != 1:
			state.lost_rank1 = true
		var completed_year := TimeManager.year
		_profiles._advance_month()
		if TimeManager.month == 1:
			_write_annual_row(csv, state, completed_year, rank)
			state.year_revenue = 0
			state.year_margin = 0
			state.year_lost = 0
			state.annual_decisions = []
	if SimulationManager.is_game_over:
		state.blocker = "FAILLITE %02d/%d" % [TimeManager.month, TimeManager.year]
		print("[C3][BLOCKER] mode=%s seed=%d strategy=%s %s" % [mode, seed, strategy, str(state.blocker)])
	csv.close()
	print("[C3][RESULT] mode=%s seed=%d strategy=%s margin=%d cash=%d rank=%d first_rank1=%d lost_rank1=%s blocker=%s" % [
		mode, seed, strategy, int(state.cumulative_margin), Economy.money, int(CAREER.player_rank()),
		int(state.first_rank1), str(state.lost_rank1), str(state.blocker)])

## Points d'extension pour les sondes dérivées (ex. components_probe).
func _end_year() -> int:
	return END_YEAR

func _extra_month(_state: Dictionary) -> void:
	pass

func _department_counts() -> Dictionary:
	return {
		"Développement":PersonnelManager.count_department("Développement"),
		"Production":PersonnelManager.count_department("Production"),
		"R&D":PersonnelManager.count_department("R&D")
	}
func _replace_departures(state: Dictionary) -> void:
	var baseline: Dictionary = state.baseline_staff
	for dept in ["Développement", "Production", "R&D"]:
		if PersonnelManager.count_department(dept) >= int(baseline.get(dept, 0)):
			continue
		if _room_left() <= 0:
			return
		PersonnelManager.generate_candidate(dept)
		if PersonnelManager.hire_candidate():
			_note(state, "Remplacement %s : effectif revenu au niveau de départ" % dept)
		return

func _adapt_staff_and_rnd(state: Dictionary) -> void:
	var current_segment := str(state.segment)
	var growth_target := str(_profiles._pick_segment(2.5))
	if MarketManager.MARKET_NEED_ORDER.find(growth_target) <= MarketManager.MARKET_NEED_ORDER.find(current_segment):
		growth_target = _newest_reachable_segment(current_segment, 2.5)
	if growth_target != current_segment and Economy.money > maxi(600000, MarketManager.segment_recommended_budget(growth_target) * 8) and _can_hire():
		var old_segment := str(state.segment)
		state.segment = growth_target
		state.force_project = true
		_note(state, "Marché : opportunité %s ouverte et finançable, bascule depuis %s" % [MarketManager.segment_label(growth_target), MarketManager.segment_label(old_segment)])
	var target := str(state.segment)
	var required_devs := MarketManager.segment_required_team(target)
	var devs := PersonnelManager.count_department("Développement")
	if devs < required_devs and _can_hire() and _room_left() > 0:
		PersonnelManager.generate_candidate("Développement")
		if PersonnelManager.hire_candidate():
			_note(state, "Embauche Développement : %s demande %d développeur(s)" % [MarketManager.segment_label(target), required_devs])
			return
	var rnd := PersonnelManager.count_department("R&D")
	if rnd == 0 and Economy.money >= 350000 and _can_hire() and _room_left() > 0:
		PersonnelManager.generate_candidate("R&D")
		if PersonnelManager.hire_candidate():
			_note(state, "Embauche R&D : Nora peut enfin affecter une piste de recherche")
			return
	_maybe_move_workplace(state)
	_orient_research(state)
	_maybe_start_concept(state)
func _can_hire() -> bool:
	var recent := ExecutiveManager.recent_monthly_result()
	return recent >= 0 or Economy.money > -recent * 18

func _room_left() -> int:
	return int(ExecutiveManager.workplace_data().capacity) - PersonnelManager.staff.size()

func _maybe_move_workplace(state: Dictionary) -> void:
	var rec: Dictionary = ExecutiveManager.workplace_upgrade_recommendation()
	if not bool(rec.get("recommended", false)):
		return
	var upgrade: Dictionary = rec.get("upgrade", {})
	if upgrade.is_empty():
		return
	var cost := int(upgrade.get("upgrade_cost", 0))
	if Economy.money <= cost * 2:
		return
	var before := str(ExecutiveManager.workplace_data().get("name", "local actuel"))
	if ExecutiveManager.renovate_workplace():
		_note(state, "Nora : déménagement depuis %s, capacité/état des locaux le justifient" % before)

func _orient_research(state: Dictionary) -> void:
	var capacity := ResearchManager.get_cpu_research_capacity()
	if capacity <= 0:
		return
	var domain := "ARCHITECTURE"
	if _average_launched_reliability() < 66.0:
		domain = "RELIABILITY"
	elif str(state.segment) in ["MOBILE_COMPUTING", "EMBEDDED", "CALCULATOR"]:
		domain = "EFFICIENCY"
	var allocations := {"ARCHITECTURE":0, "EFFICIENCY":0, "RELIABILITY":0}
	allocations[domain] = capacity
	var same := true
	for key in allocations.keys():
		if int(ResearchManager.get_cpu_research_domain(str(key)).get("allocated", 0)) != int(allocations[key]):
			same = false
	if not same and ResearchManager.set_cpu_research_allocations(allocations):
		_note(state, "R&D orientée %s : besoin courant du portefeuille/marché" % ResearchManager.get_cpu_research_label(domain))

func _maybe_start_concept(state: Dictionary) -> void:
	if Economy.money < 600000 or ExecutiveManager.recent_monthly_result() <= 0:
		return
	if ResearchManager.get_cpu_research_capacity() <= 0:
		return
	for value in ResearchManager.get_active_cpu_concept_programs():
		if str((value as Dictionary).get("axis", "")) == "MINIATURIZATION":
			return
	var available := CPU_DESIGN.available_nodes_for_capabilities(float(ResearchManager.technologies.get("manufacturing", 0.0)), ResearchManager.get_cpu_capability("MINIATURIZATION"))
	var latest := int(available[available.size() - 1])
	var index := CPU_DESIGN.NODE_ORDER.find(latest)
	if index < 0 or index >= CPU_DESIGN.NODE_ORDER.size() - 1:
		return
	var next_node := int(CPU_DESIGN.NODE_ORDER[index + 1])
	if ResearchManager.start_cpu_concept_program("MINIATURIZATION", 15000, 2):
		_note(state, "R&D Concept miniaturisation : préparer %s par le vrai programme Concept" % CPU_DESIGN.node_label(next_node))

func _average_launched_reliability() -> float:
	var total := 0.0
	var count := 0
	for value in ProductManager.products:
		var product: Dictionary = value
		if str(product.get("status", "")) != "LAUNCHED":
			continue
		total += float((product.get("metrics", {}) as Dictionary).get("reliability", 50.0))
		count += 1
	return total / float(count) if count > 0 else 100.0

func _resolve_project_decisions(state: Dictionary) -> void:
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		var pending := ResearchManager.get_project_decision(str(project.get("id", "")))
		if pending.is_empty():
			continue
		var answer := "BALANCE" if str(pending.get("type", "")) == "PROTOTYPE_REVIEW" else "APPROVE"
		if ResearchManager.resolve_project_decision(str(project.id), answer):
			_note(state, "Décision projet %s : %s (%s)" % [str(project.name), answer, str(pending.get("recommendation", "validation requise"))])
func _route_production(state: Dictionary) -> void:
	for job_value in ProductionManager.get_active_jobs():
		var job: Dictionary = job_value
		if bool(job.get("route_selected", false)):
			continue
		if ProductionManager.set_manufacturing_route(str(job.get("id", "")), "EXTERNAL", ""):
			_note(state, "Fabrication externe : route recommandée disponible pour %s" % str(job.get("project_name", job.get("id", "job"))))

func _launch_ready_products(state: Dictionary) -> void:
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) != "READY":
			continue
		var capacity := maxi(1, int(product.get("recommended_capacity", product.get("production_capacity", 1))))
		var price := maxi(1, int(product.get("price", 1)))
		if ProductManager.launch_product(str(product.get("id", "")), price, capacity):
			_note(state, "Lancement %s : prix conseillé %d, capacité %d" % [str(product.get("name", "CPU")), price, capacity])

func _retire_if_needed(state: Dictionary) -> void:
	if str(state.strategy) != "FIGEE":
		return
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "LAUNCHED" and int(product.get("months_on_market", 0)) >= RETIRE_AFTER_MONTHS:
			if ProductManager.retire_product(str(product.id), true):
				_note(state, "Retrait automatique %s : %d mois, règle figée" % [str(product.name), RETIRE_AFTER_MONTHS])

func _handle_market_threats(state: Dictionary) -> void:
	for threat_value in MarketManager.open_market_threats():
		var threat: Dictionary = threat_value
		var id := str(threat.get("id", ""))
		var mitigate := str(state.strategy) != "FIGEE" and Economy.money > MarketManager.threat_response_cost(id) * 3
		if MarketManager.resolve_market_threat(id, mitigate):
			_note(state, "%s menace %s : %s" % ["Nora traite" if mitigate else "FIGÉE ignore", str(threat.get("title", id)), "réponse financée" if mitigate else "aucune réaction"])

func _maybe_start_project(state: Dictionary) -> void:
	if _profiles._active_projects() > 0 or _has_ready_products():
		return
	if not _project_due(state):
		return
	var strategy := str(state.strategy)
	var segment := str(state.fixed_segment) if strategy == "FIGEE" else str(state.segment)
	var focus := "BALANCED" if strategy == "FIGEE" else _focus_for_segment(segment)
	var budget := MarketManager.segment_recommended_budget(segment)
	var base: Dictionary = state.base_design
	var proposals := ResearchManager.prepare_cpu_generation_proposals(segment, "INTERNAL", focus, budget, base)
	var proposal := _pick_generation_proposal(proposals, strategy)
	var design: Dictionary = CPU_DESIGN.normalize(proposal.get("design", base))
	var arch_id := str(state.first_arch) if strategy == "EN_RETARD" else ArchitectureManager.latest_id()
	if strategy == "EN_RETARD":
		design.node_nm = 10000
		design = CPU_DESIGN.normalize(design)
	_apply_architecture_limits(design, arch_id)
	proposal["design"] = design.duplicate(true)
	state.generation = int(state.generation) + 1
	var project_name := "C3 %s %02d" % [strategy, int(state.generation)]
	var line_id := _line_for_segment(state, segment, arch_id)
	if ResearchManager.start_project(project_name, "CPU", segment, "INTERNAL", focus, budget, design, proposal):
		ArchitectureManager.register_project(project_name, line_id, arch_id, [])
		state.base_design = design.duplicate(true)
		state.force_project = false
		_note(state, "Nouveau projet %s : %s, %s, %s, %s" % [project_name, MarketManager.segment_label(segment), focus, CPU_DESIGN.node_label(int(design.node_nm)), ARCH_CATALOG.get_by_id(arch_id).short])
	else:
		state.blocker = "start_project refusé %02d/%d segment=%s node=%d arch=%s" % [TimeManager.month, TimeManager.year, segment, int(design.node_nm), arch_id]
		_note(state, "BLOCAGE : %s" % str(state.blocker))

func _project_due(state: Dictionary) -> bool:
	if bool(state.force_project):
		return true
	var launched := 0
	var newest_age := 9999
	for value in ProductManager.products:
		var product: Dictionary = value
		if str(product.get("status", "")) != "LAUNCHED":
			continue
		launched += 1
		newest_age = mini(newest_age, int(product.get("months_on_market", 0)))
	return launched == 0 or newest_age >= REFRESH_AFTER_MONTHS

func _has_ready_products() -> bool:
	for value in ProductManager.products:
		if str((value as Dictionary).get("status", "")) == "READY":
			return true
	return false

func _pick_generation_proposal(proposals: Array, strategy: String) -> Dictionary:
	for value in proposals:
		var proposal: Dictionary = value
		if strategy == "FIGEE" and str(proposal.get("archetype", "")) == "BALANCED":
			return proposal.duplicate(true)
	for value in proposals:
		var proposal: Dictionary = value
		if bool(proposal.get("recommended", false)):
			return proposal.duplicate(true)
	if not proposals.is_empty():
		return (proposals[0] as Dictionary).duplicate(true)
	return {"design":CPU_DESIGN.preset("BALANCED"), "archetype":"BALANCED"}

func _line_for_segment(state: Dictionary, segment: String, arch_id: String) -> String:
	var lines: Dictionary = state.line_by_segment
	if lines.has(segment):
		return str(lines[segment])
	var line_id := ArchitectureManager.create_line("C3 %s" % MarketManager.segment_label(segment), segment, arch_id)
	lines[segment] = line_id
	state.line_by_segment = lines
	return line_id

func _apply_architecture_limits(design: Dictionary, arch_id: String) -> void:
	var arch: Dictionary = ARCH_CATALOG.get_by_id(arch_id)
	design.cores = mini(int(design.cores), int(arch.get("max_cores", 1)))
	var max_cache_mb := float(arch.get("max_cache_kb", 0)) / 1024.0
	design.cache_mb = minf(float(design.cache_mb), max_cache_mb)
	var reference_ghz := float(CPU_DESIGN.node_profile(int(design.node_nm)).get("reference_mhz", 1.0)) / 1000.0
	var max_ghz := reference_ghz * float(arch.get("max_freq_factor", 1.0))
	design.frequency_ghz = minf(float(design.frequency_ghz), max_ghz)

func _focus_for_segment(segment: String) -> String:
	if segment in ["INDUSTRIAL", "SERVER", "DATACENTER"]:
		return "RELIABILITY"
	if segment in ["WORKSTATION", "GAMING", "SCIENTIFIC"]:
		return "PERFORMANCE"
	if segment in ["MOBILE_COMPUTING", "EMBEDDED", "CALCULATOR"]:
		return "EFFICIENCY"
	return "BALANCED"

func _follow_sales_advice(state: Dictionary) -> void:
	var summary: Dictionary = SALES_ADVISOR.month_summary()
	var advice: Dictionary = summary.get("top", {})
	if advice.is_empty():
		return
	var kind := str(advice.get("kind", ""))
	var product_id := str(advice.get("product_id", ""))
	var product := ProductManager.get_product(product_id)
	match kind:
		"LOSING":
			if not product.is_empty():
				var floor := int(ceil(float(product.get("unit_cost", 1)) / maxf(1.0 - MarketManager.distributor_share(), 0.05))) + 3
				var target := maxi(floor, int(round(float(product.get("price", 1)) * 1.10)))
				if ProductManager.update_product_price(product_id, target):
					_note(state, "SalesAdvisor LOSING : prix %s -> %d pour retrouver une marge" % [str(product.get("name", "CPU")), target])
		"STOCKOUT", "OVERCAPACITY":
			var target_capacity := int(advice.get("capacity_target", 0))
			if target_capacity > 0 and ProductManager.set_production_capacity(product_id, target_capacity):
				_note(state, "SalesAdvisor %s : capacité %s -> %d" % [kind, str(product.get("name", "CPU")), target_capacity])
		"PROMOTION":
			var promotion := str(advice.get("promotion", "AWARENESS"))
			if ProductManager.start_promotion(product_id, promotion):
				_note(state, "SalesAdvisor PROMOTION : %s sur %s" % [promotion, str(product.get("name", "CPU"))])
		"CLEARANCE":
			var ids: Array = advice.get("product_ids", [product_id])
			var changed := ProductManager.start_clearance_many(ids)
			if changed > 0:
				_note(state, "SalesAdvisor CLEARANCE : %d modèle(s) passent en fin de série" % changed)
		"SOFTWARE":
			if ProductManager.release_control_software(product_id):
				_note(state, "SalesAdvisor SOFTWARE : logiciel de contrôle lancé pour %s" % str(product.get("name", "CPU")))
		"RIVAL":
			state.force_project = true
			_note(state, "SalesAdvisor RIVAL : préparer une nouvelle réponse produit/marché")
		"SAV":
			# Le conseil demande d'ouvrir le dossier, mais aucun choix de correction n'est recommandé automatiquement.
			_note_once(state, "SAV observé : diagnostic demandé, pas d'action automatique sans recommandation")

func _react_to_rival(state: Dictionary) -> void:
	var current := str(state.segment)
	var player_units := _segment_player_units(current)
	var rival_units := 0
	var rival_name := ""
	for value in MarketManager.competitors.get("CPU", []):
		var rival: Dictionary = value
		if str(rival.get("target_segment", "")) != current:
			continue
		if int(rival.get("last_month_units", 0)) > rival_units:
			rival_units = int(rival.get("last_month_units", 0))
			rival_name = str(rival.get("company", "Rival"))
	if rival_units <= maxi(player_units, 1):
		return
	var candidate := str(_profiles._pick_segment(1.5))
	if MarketManager.MARKET_NEED_ORDER.find(candidate) <= MarketManager.MARKET_NEED_ORDER.find(current):
		candidate = _newest_reachable_segment(current, 1.5)
	if candidate != current:
		state.segment = candidate
		state.force_project = true
		_note(state, "Marché : %s dépasse %d vs %d, bascule prochaine gamme vers %s" % [rival_name, rival_units, player_units, MarketManager.segment_label(candidate)])
func _newest_reachable_segment(current: String, reach: float) -> String:
	var devs := float(maxi(PersonnelManager.count_department("Développement"), 1))
	var current_index := MarketManager.MARKET_NEED_ORDER.find(current)
	var best := current
	for segment_value in MarketManager.available_segment_keys():
		var segment := str(segment_value)
		if MarketManager.MARKET_NEED_ORDER.find(segment) <= current_index:
			continue
		if float(MarketManager.segment_required_team(segment)) <= devs * reach:
			best = segment
	return best
func _best_alternate_segment(current: String) -> String:
	var devs := float(maxi(PersonnelManager.count_department("Développement"), 1))
	var best := current
	var best_value := -1.0
	for value in MarketManager.market_landscape():
		var row: Dictionary = value
		var segment := str(row.get("segment", ""))
		if segment == current or float(MarketManager.segment_required_team(segment)) > devs * 1.5:
			continue
		var opportunity := float(row.get("units", 0)) * float(row.get("reference_price", 0))
		if opportunity > best_value:
			best_value = opportunity
			best = segment
	return best
func _segment_player_units(segment: String) -> int:
	var total := 0
	for value in ProductManager.products:
		var product: Dictionary = value
		if str(product.get("status", "")) == "LAUNCHED" and str(product.get("target_segment", "")) == segment:
			total += int(product.get("last_month_sales", 0))
	return total

func _monthly_lost_demand() -> int:
	var total := 0
	for value in ProductManager.products:
		var product: Dictionary = value
		if str(product.get("status", "")) == "LAUNCHED":
			total += int(product.get("last_month_lost_sales", 0))
	return total

func _note(state: Dictionary, text: String) -> void:
	var dated := "%02d/%d %s" % [TimeManager.month, TimeManager.year, text]
	(state.annual_decisions as Array).append(dated)
	(state.all_decisions as Array).append(dated)

func _note_once(state: Dictionary, text: String) -> void:
	for value in state.all_decisions:
		if str(value).ends_with(text):
			return
	_note(state, text)

func _write_header(csv: FileAccess) -> void:
	var cols := ["commit", "seed", "mode", "strategy", "year", "treasury", "revenue", "margin", "cumulative_margin", "global_rank", "lost_demand", "decisions_count", "decisions", "rivals_ahead", "process_nm", "architecture"]
	for market in MARKETS:
		cols.append("share_%s" % market)
	csv.store_line(",".join(cols))
func _write_annual_row(csv: FileAccess, state: Dictionary, year: int, rank: int) -> void:
	var decisions: Array = state.annual_decisions
	var tech := _latest_player_tech()
	var row := [
		"eff0871", str(state.seed), str(state.mode), str(state.strategy), str(year),
		str(Economy.money), str(state.year_revenue), str(state.year_margin), str(state.cumulative_margin),
		str(rank), str(state.year_lost), str(decisions.size()), _csv_cell(" | ".join(decisions)),
		_csv_cell(_rivals_ahead()), str(tech.node_nm), _csv_cell(str(tech.architecture))
	]
	for market in MARKETS:
		row.append("%.6f" % _segment_share(str(market)))
	csv.store_line(",".join(row))
	if decisions.is_empty() and rank == 1 and int(state.year_margin) > 0:
		(state.rank1_idle_years as Array).append(year)
	print("[C3] %s seed=%d %s %d cash=%d margin=%d rank=%d decisions=%d node=%s arch=%s" % [
		str(state.mode), int(state.seed), str(state.strategy), year, Economy.money,
		int(state.year_margin), rank, decisions.size(), str(tech.node_nm), str(tech.architecture)])

func _segment_share(segment: String) -> float:
	var share := 0.0
	for value in ProductManager.products:
		var product: Dictionary = value
		if str(product.get("status", "")) == "LAUNCHED" and str(product.get("target_segment", "")) == segment:
			share += float(product.get("last_month_share", 0.0))
	return share

func _rivals_ahead() -> String:
	var names: Array[String] = []
	for value in CAREER.global_ranking():
		var row: Dictionary = value
		if bool(row.get("player", false)):
			break
		names.append(str(row.get("company", "Rival")))
	return ";".join(names)
func _latest_player_tech() -> Dictionary:
	var best := {}
	var best_generation := -1
	for value in ProductManager.products:
		var product: Dictionary = value
		if str(product.get("status", "")) not in ["LAUNCHED", "READY"]:
			continue
		var generation := int(product.get("generation_index", 0))
		if generation < best_generation:
			continue
		best_generation = generation
		best = product
	if best.is_empty():
		return {"node_nm":10000, "architecture":str(ArchitectureManager.latest_id())}
	var design: Dictionary = best.get("cpu_design", {})
	var arch_id := str(best.get("architecture_id", "A4"))
	return {
		"node_nm":int(design.get("node_nm", 10000)),
		"architecture":str(ARCH_CATALOG.get_by_id(arch_id).get("short", arch_id))
	}

func _csv_cell(value: String) -> String:
	return "\"%s\"" % value.replace("\"", "\"\"")
