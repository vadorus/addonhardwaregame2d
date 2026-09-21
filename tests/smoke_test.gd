extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

func _ready() -> void:
	print("[CI] Tech Empire smoke test starting")
	SimulationManager.reset_all("CI Test", "GPU")
	if CompanyManager.starting_sector != "CPU":
		_fail("Inactive starting sector was not normalized to CPU")
		return
	if GameData.get_active_sector_keys() != ["CPU"]:
		_fail("CPU must be the only active sector")
		return
	if DivisionManager.get_active_division_keys() != ["CPU"]:
		_fail("CPU must be the only operational company division")
		return
	if DivisionManager.is_operational("GPU"):
		_fail("Future divisions must remain locked")
		return
	if DivisionManager.delegation_available("CPU"):
		_fail("Division delegation should stay hidden during the initial garage phase")
		return
	if not PersonnelManager.staff.is_empty():
		_fail("A new garage game must start with the founder alone")
		return
	ExecutiveManager.sync_interface_unlocks()
	if not ExecutiveManager.is_interface_feature_unlocked("QG") or ExecutiveManager.is_interface_feature_unlocked("LAB"):
		_fail("The garage must expose only the QG before electronics milestones")
		return
	if Economy.money != BalanceManager.starting_capital():
		_fail("Garage starting cash does not match the selected difficulty")
		return

	if not StartupManager.start_software_contract("STOCK"):
		_fail("Could not start the first garage software contract")
		return
	SimulationManager.process_month_end()
	SimulationManager.process_month_end()
	if StartupManager.software_contracts_completed != 1:
		_fail("First garage software contract did not complete")
		return
	if not StartupManager.start_software_contract("INVOICING"):
		_fail("Could not start the second garage software contract")
		return
	SimulationManager.process_month_end()
	SimulationManager.process_month_end()
	if StartupManager.stage != StartupManager.STAGE_FIRST_HIRE:
		_fail("Two delivered software contracts did not unlock the first hire")
		return
	if FounderManager.branch_level(FounderManager.BRANCH_BUSINESS) < 2:
		_fail("Repeated business-software work did not level the founder specialization")
		return
	if not StartupManager.available_contract_ids().has("PAYROLL"):
		_fail("Business software level 2 did not unlock the advanced payroll contract")
		return
	if not StartupManager.hire_first_engineer() or PersonnelManager.staff.size() != 1:
		_fail("First startup engineer could not be hired")
		return
	if not StartupManager.start_electronics_project():
		_fail("Electronics prototype could not start")
		return
	for _month in range(3):
		SimulationManager.process_month_end()
	if not StartupManager.cpu_program_unlocked:
		_fail("Electronics prototype did not unlock the CPU program")
		return
	ExecutiveManager.sync_interface_unlocks()
	if not ExecutiveManager.is_interface_feature_unlocked("LAB"):
		_fail("CPU Lab did not unlock after the electronics prototype")
		return

	# À partir d'ici, le smoke test prépare une équipe mûre afin de conserver
	# la couverture des anciens systèmes de management, production et marché.
	PersonnelManager._add_employee("CI R&D 2", "Ingénieur R&D", "R&D", 65, 4.0, "cpu", 48, 3200)
	PersonnelManager._add_employee("CI Dev 1", "Ingénieur développement", "Développement", 62, 3.0, "product", 46, 3000)
	PersonnelManager._add_employee("CI Dev 2", "Ingénieur validation", "Développement", 60, 2.5, "validation", 42, 2900)
	PersonnelManager._add_employee("CI Production", "Responsable production", "Production", 63, 5.0, "manufacturing", 60, 3300)
	PersonnelManager._add_employee("CI Marketing", "Responsable marketing", "Marketing", 58, 4.0, "marketing", 55, 3000)
	PersonnelManager._add_employee("CI Support", "Responsable support", "Support", 57, 4.0, "support", 52, 2900)
	CompanyManager.set_department_leader("R&D", str(PersonnelManager.staff[0].id))
	CompanyManager.set_department_leader("Développement", str(PersonnelManager.staff[2].id))
	CompanyManager.set_department_leader("Production", str(PersonnelManager.staff[4].id))
	CompanyManager.set_department_leader("Marketing", str(PersonnelManager.staff[5].id))
	CompanyManager.set_department_leader("Support", str(PersonnelManager.staff[6].id))
	Economy.reset(500000)

	var division_initial_state := DivisionManager.get_state().duplicate(true)
	var delegation_company_state := CompanyManager.get_state().duplicate(true)
	var delegation_research_state := ResearchManager.get_state().duplicate(true)
	DivisionManager.record_completed_generation("CPU")
	if not DivisionManager.delegation_available("CPU"):
		_fail("Division delegation did not unlock after the first completed CPU generation")
		return
	var director_id := str(PersonnelManager.staff[0].get("id", ""))
	var director_profile := PersonnelManager.management_profile(director_id, "CPU")
	if director_profile.is_empty() or float(director_profile.get("technical", 0.0)) <= 0.0 or float(director_profile.get("financial", 0.0)) <= 0.0:
		_fail("Division director profile was not derived from the employee")
		return
	if not DivisionManager.set_leader("CPU", director_id):
		_fail("Could not appoint a CPU division director")
		return
	if not DivisionManager.set_mandate("CPU", {
		"priority":"PERFORMANCE",
		"target_segment":"EMBEDDED",
		"risk_tolerance":"CAUTIOUS",
		"monthly_budget_ceiling":10000,
		"quality_bias":65.0,
		"growth_bias":55.0
	}):
		_fail("Could not apply a CPU division mandate")
		return
	if not DivisionManager.set_control_mode("CPU", "SUPERVISED"):
		_fail("Could not switch the CPU division to supervised delegation")
		return
	if str(CompanyManager.departments["R&D"].get("autonomy", "")) != "SUPERVISED" or str(CompanyManager.departments["Production"].get("autonomy", "")) != "SUPERVISED":
		_fail("Division delegation did not propagate to operational departments")
		return
	var supervised_modifier := DivisionManager.management_modifier("CPU")
	if supervised_modifier < 0.90 or supervised_modifier > 1.05:
		_fail("Supervised director execution modifier escaped its supported range")
		return
	if not ResearchManager.set_cpu_research_allocations({"ARCHITECTURE":1, "EFFICIENCY":0, "RELIABILITY":0}):
		_fail("Could not create a small delegated research commitment")
		return
	ResearchManager.set_continuous_research_budget(18000)
	DivisionManager.process_month()
	var escalations := DivisionManager.get_pending_escalations("CPU")
	var budget_escalation: Dictionary = {}
	var new_generation_escalation: Dictionary = {}
	for escalation_value in escalations:
		var escalation: Dictionary = escalation_value
		if str(escalation.get("category", "")) == "BUDGET":
			budget_escalation = escalation
		elif str(escalation.get("category", "")) == "NEW_GENERATION":
			new_generation_escalation = escalation
	if budget_escalation.is_empty():
		_fail("Delegated director did not escalate a budget overrun")
		return
	if new_generation_escalation.is_empty():
		_fail("Delegated director launched no CEO escalation for a structural new-generation decision")
		return
	if str(DivisionManager.get_division("CPU").get("strategy", "")) != "PERFORMANCE":
		_fail("Director did not execute the routine strategy inside the mandate")
		return
	var ceiling_before := int(DivisionManager.get_division("CPU").get("mandate", {}).get("monthly_budget_ceiling", 0))
	if not DivisionManager.resolve_escalation(str(budget_escalation.get("id", "")), true):
		_fail("CEO could not apply the director budget recommendation")
		return
	var ceiling_after := int(DivisionManager.get_division("CPU").get("mandate", {}).get("monthly_budget_ceiling", 0))
	if ceiling_after <= ceiling_before or ceiling_after < DivisionManager.current_commitments("CPU"):
		_fail("Applied budget arbitration did not update the division mandate")
		return
	if not DivisionManager.set_control_mode("CPU", "AUTONOMOUS"):
		_fail("Could not switch the division to autonomous delegation")
		return
	var autonomous_modifier := DivisionManager.management_modifier("CPU")
	if autonomous_modifier < 0.76 or autonomous_modifier > 1.10:
		_fail("Autonomous director execution modifier escaped its supported range")
		return
	var delegation_round_trip := DivisionManager.get_state().duplicate(true)
	DivisionManager.reset("CPU")
	DivisionManager.load_state(delegation_round_trip)
	var restored_division := DivisionManager.get_division("CPU")
	if str(restored_division.get("control_mode", "")) != "AUTONOMOUS" or str(restored_division.get("leader_id", "")) != director_id:
		_fail("Division director/control mode did not survive a save round-trip")
		return
	if DivisionManager.get_pending_escalations("CPU").is_empty() or DivisionManager.get_recent_decisions("CPU", 3).is_empty():
		_fail("Division escalations or decision history did not survive a save round-trip")
		return
	CompanyManager.load_state(delegation_company_state)
	ResearchManager.load_state(delegation_research_state)
	DivisionManager.load_state(division_initial_state)

	var forbidden: bool = ResearchManager.start_project("Forbidden GPU", "GPU", "MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000)
	if forbidden:
		_fail("Inactive GPU branch accepted a research project")
		return
	if not CompanyManager.created:
		_fail("Company was not created")
		return
	if Economy.money != 500_000:
		_fail("Unexpected starting money: %s" % Economy.money)
		return
	if BalanceManager.active_profile != "STANDARD":
		_fail("Default CI game did not start on Standard economic balance")
		return
	var balance_state := BalanceManager.get_state().duplicate(true)
	var standard_salary_cost := BalanceManager.expense_amount(10000, "Salaires")
	var standard_market_units := MarketManager.segment_market_units("EMBEDDED")
	var standard_capital := BalanceManager.starting_capital()
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
		_fail("Difficulty profiles do not change real payroll costs in the expected direction")
		return
	if not (accessible_market_units > standard_market_units and standard_market_units > realistic_market_units):
		_fail("Difficulty profiles do not change available market demand")
		return
	if not (accessible_capital > standard_capital and standard_capital > realistic_capital):
		_fail("Difficulty profiles do not change garage starting liquidity")
		return
	if accessible_runway <= standard_runway or realistic_runway >= standard_runway:
		_fail("Difficulty profiles do not create distinct starting runway pressure")
		return
	if BalanceManager.competitor_pressure_factor() <= 1.0:
		_fail("Realistic difficulty did not increase competitor pressure")
		return
	if BalanceManager.expense_amount(10000, "Production — test CPU") != 10000:
		_fail("Difficulty changed literal per-unit production economics")
		return
	if BalanceManager.expense_amount(10000, "SAV garanties — test CPU") != 10000:
		_fail("Difficulty changed literal warranty unit economics")
		return
	BalanceManager.load_state(balance_state)
	if BalanceManager.active_profile != "STANDARD":
		_fail("Economic difficulty did not survive a state round-trip")
		return
	if TimeManager.year != 1971:
		_fail("New companies must start in the early microprocessor era")
		return
	if CompanyManager.founded_year != 1971:
		_fail("Company founding year did not follow the early CPU era")
		return
	var starting_markets := MarketManager.available_segment_keys()
	for required_market in ["CALCULATOR", "EMBEDDED", "INDUSTRIAL"]:
		if not starting_markets.has(required_market):
			_fail("1971 market is missing the early CPU need: %s" % required_market)
			return
	for anachronistic_market in ["HOME_PC", "GAMING", "SERVER", "DATACENTER"]:
		if starting_markets.has(anachronistic_market):
			_fail("1971 market exposed an anachronistic segment: %s" % anachronistic_market)
			return
	var market_research_probe := ResearchManager.get_state().duplicate(true)
	ResearchManager.technologies["cpu"] = 60.0
	ResearchManager.cpu_capabilities["ARCHITECTURE"] = 60.0
	ResearchManager.cpu_capabilities["LAYOUT"] = 60.0
	ResearchManager.cpu_capabilities["MINIATURIZATION"] = 60.0
	var accelerated_markets := MarketManager.available_segment_keys()
	if not accelerated_markets.has("HOBBYIST") or not accelerated_markets.has("BUSINESS_PC"):
		_fail("Technological lead could not make later CPU markets emerge ahead of the historical date")
		return
	if accelerated_markets.has("GAMING"):
		_fail("Moderate technological lead unlocked gaming too early")
		return
	ResearchManager.load_state(market_research_probe)
	ExecutiveManager.sync_interface_unlocks()
	if not ExecutiveManager.is_interface_feature_unlocked("QG") or not ExecutiveManager.is_interface_feature_unlocked("LAB"):
		_fail("Progressed startup did not expose QG and CPU Lab")
		return
	if not ExecutiveManager.is_interface_feature_unlocked("COMPANY") or not ExecutiveManager.is_interface_feature_unlocked("TEAM"):
		_fail("First recruitment did not expose Company and Team management")
		return
	for locked_feature in ["PRODUCTS","MARKET","PRESS"]:
		if ExecutiveManager.is_interface_feature_unlocked(locked_feature):
			_fail("Post-CPU feature unlocked too early: %s" % locked_feature)
			return

	var executive_initial_state := ExecutiveManager.get_state().duplicate(true)
	var personnel_initial_state := PersonnelManager.get_state().duplicate(true)
	var company_initial_state := CompanyManager.get_state().duplicate(true)
	var economy_initial_state := Economy.get_state().duplicate(true)
	var right_hand_brief := ExecutiveManager.get_executive_brief()
	if str(right_hand_brief.get("advisor", {}).get("name", "")).is_empty() or str(right_hand_brief.get("headline", "")).is_empty():
		_fail("Right-hand guide was not available from the garage stage")
		return
	var starting_workplace := ExecutiveManager.workplace_data()
	if int(starting_workplace.get("tier", -1)) != 0 or int(starting_workplace.get("capacity", 0)) != 8:
		_fail("Company did not start in the expected garage workplace")
		return
	var small_advice := ExecutiveManager.financial_advice(10_000, 0)
	var dangerous_advice := ExecutiveManager.financial_advice(480_000, 25_000)
	if float(dangerous_advice.get("runway_months", 999.0)) >= float(small_advice.get("runway_months", 0.0)):
		_fail("Financial advisor did not detect the additional liquidity risk")
		return
	var benefits_before := ExecutiveManager.monthly_benefit_cost()
	if not ExecutiveManager.set_benefit_policy("HEALTH", "STRONG"):
		_fail("Could not improve employee health benefits")
		return
	if ExecutiveManager.monthly_benefit_cost() <= benefits_before:
		_fail("Improved employee benefits did not increase the real monthly cost")
		return
	var upgrade := ExecutiveManager.next_workplace_upgrade()
	if upgrade.is_empty() or str(upgrade.get("name", "")).is_empty():
		_fail("Garage did not expose a real next workplace upgrade")
		return
	if not ExecutiveManager.renovate_workplace():
		_fail("Could not renovate the starting workplace with sufficient cash")
		return
	if int(ExecutiveManager.workplace_data().get("tier", -1)) != 1 or int(ExecutiveManager.workplace_data().get("capacity", 0)) <= int(starting_workplace.get("capacity", 0)):
		_fail("Workplace renovation did not improve company capacity")
		return
	PersonnelManager.staff[0]["morale"] = 40.0
	ExecutiveManager._detect_hr_issues()
	var hr_issues := ExecutiveManager.get_open_hr_issues()
	if hr_issues.is_empty():
		_fail("Low employee morale did not create an HR alert")
		return
	var morale_before_hr := float(PersonnelManager.staff[0].get("morale", 0.0))
	if not ExecutiveManager.resolve_hr_issue(str(hr_issues[0].get("id", "")), "DISCUSS"):
		_fail("HR issue could not be handled through an employee discussion")
		return
	if float(PersonnelManager.staff[0].get("morale", 0.0)) <= morale_before_hr:
		_fail("HR intervention did not improve the affected employee morale")
		return
	var executive_round_trip := ExecutiveManager.get_state().duplicate(true)
	ExecutiveManager.reset()
	ExecutiveManager.load_state(executive_round_trip)
	if int(ExecutiveManager.workplace_data().get("tier", -1)) != 1 or str(ExecutiveManager.benefit_policy.get("HEALTH", "")) != "STRONG":
		_fail("Executive workplace and benefits did not survive a save round-trip")
		return
	CompanyManager.load_state(company_initial_state)
	ExecutiveManager.load_state(executive_initial_state)
	PersonnelManager.load_state(personnel_initial_state)
	Economy.load_state(economy_initial_state)

	var foundry_initial_state := FoundryManager.get_state().duplicate(true)
	var foundry_company_state := CompanyManager.get_state().duplicate(true)
	var foundry_economy_state := Economy.get_state().duplicate(true)
	var recommended_foundry := FoundryManager.recommended_external_foundry(10000)
	if recommended_foundry == "":
		_fail("No external foundry can manufacture the starting 10 µm CPU")
		return
	var external_quote := FoundryManager.route_quote("EXTERNAL", recommended_foundry, 10000)
	if external_quote.is_empty() or float(external_quote.get("precision", 0.0)) <= 0.0 or int(external_quote.get("setup_fee", 0)) <= 0:
		_fail("External foundry quote is missing real cost/precision data")
		return
	if not FoundryManager.route_quote("INTERNAL", "INTERNAL", 10000).is_empty():
		_fail("Company started with a fictitious internal fab")
		return
	if not FoundryManager.start_internal_fab_project():
		_fail("Could not start the first internal fab construction with sufficient cash and manufacturing knowledge")
		return
	for _i in range(4):
		FoundryManager.process_month()
	var built_fab := FoundryManager.internal_fab_data()
	if not bool(built_fab.get("built", false)) or int(built_fab.get("tier", 0)) != 1:
		_fail("Internal fab construction did not complete")
		return
	var internal_quote := FoundryManager.route_quote("INTERNAL", "INTERNAL", 10000)
	if internal_quote.is_empty() or int(internal_quote.get("max_capacity", 0)) <= 0:
		_fail("Completed internal fab cannot quote a supported CPU process")
		return
	FoundryManager.set_sell_spare_capacity(true)
	var foundry_income_before := Economy.monthly_income
	FoundryManager.process_month()
	if Economy.monthly_income <= foundry_income_before or int(Economy.income_breakdown.get("Services de fonderie", 0)) <= 0:
		_fail("Selling unused internal fab capacity did not generate foundry-service revenue")
		return
	FoundryManager.load_state(foundry_initial_state)
	CompanyManager.load_state(foundry_company_state)
	Economy.load_state(foundry_economy_state)

	var era_design := CPU_DESIGN.default_design()
	if int(era_design.get("node_nm", 0)) != 10000 or int(era_design.get("cores", 0)) != 1:
		_fail("Default CPU design is not an early-era single-core 10 µm design")
		return
	if not CPU_DESIGN.format_frequency(era_design).contains("MHz"):
		_fail("Early CPU frequency is not presented in MHz")
		return
	if not CPU_DESIGN.format_cache(era_design).contains("sans cache"):
		_fail("Early CPU design should start without integrated cache")
		return
	var starting_nodes := CPU_DESIGN.available_nodes_for_capabilities(
		float(ResearchManager.technologies.get("manufacturing", 0.0)),
		ResearchManager.get_cpu_capability("MINIATURIZATION")
	)
	if starting_nodes != [10000]:
		_fail("Starting company should initially master only the 10 µm process")
		return
	if ResearchManager.get_cpu_capability("ARCHITECTURE") <= 0.0 or ResearchManager.get_cpu_capability("LAYOUT") <= 0.0:
		_fail("CPU technical capabilities were not initialized")
		return
	if CPU_DESIGN.available_nodes_for_capabilities(30.0, 30.0).size() <= starting_nodes.size():
		_fail("Manufacturing plus miniaturization mastery does not unlock finer historical processes")
		return
	var forbidden_8um := CPU_DESIGN.default_design()
	forbidden_8um["node_nm"] = 8000
	if ResearchManager.start_project("Too Early 8um", "CPU", "MAINSTREAM", "INTERNAL", "INNOVATION", 20_000, forbidden_8um):
		_fail("CPU development accepted a process that miniaturization cannot yet support")
		return

	if ResearchManager.get_cpu_research_domain_keys().size() != 3:
		_fail("CPU research must start with three clear domains")
		return
	var research_capacity := ResearchManager.get_cpu_research_capacity()
	if research_capacity != PersonnelManager.count_department("R&D") or research_capacity < 2:
		_fail("CPU research capacity does not match the R&D staff")
		return
	var development_size := ResearchManager.get_development_team_size()
	if development_size != PersonnelManager.count_department("Développement") or development_size < 2:
		_fail("CPU Development team was not created separately from R&D")
		return
	if not CompanyManager.departments.has("Développement"):
		_fail("Company organization is missing the Development department")
		return
	if PersonnelManager.count_department("Production") < 1:
		_fail("Starting company has no Production team")
		return
	if PersonnelManager.team_attribute("Production", "process_quality") <= 0.0:
		_fail("Production employee profiles were not initialized")
		return
	if ResearchManager.set_cpu_research_allocations({"ARCHITECTURE":research_capacity + 1, "EFFICIENCY":0, "RELIABILITY":0}):
		_fail("CPU research accepted more researchers than available")
		return
	if not ResearchManager.set_cpu_research_allocations({"ARCHITECTURE":1, "EFFICIENCY":1, "RELIABILITY":0}):
		_fail("CPU research rejected a valid team split")
		return
	if ResearchManager.get_development_team_size() != development_size:
		_fail("Research allocation incorrectly changed the Development team size")
		return
	var idle_development_factor := ResearchManager.development_capacity_factor()
	if idle_development_factor < 0.65 or idle_development_factor > 1.05:
		_fail("Idle Development capacity factor escaped its expected range")
		return
	if ResearchManager.development_team_score() <= 20.0 or ResearchManager.development_confidence() <= 20.0:
		_fail("Development team quality was not initialized")
		return
	ResearchManager.set_continuous_research_budget(18000)
	var architecture_before := float(ResearchManager.get_cpu_research_domain("ARCHITECTURE").get("knowledge", 0.0))
	ResearchManager.process_month()
	var architecture_after := float(ResearchManager.get_cpu_research_domain("ARCHITECTURE").get("knowledge", 0.0))
	if architecture_after <= architecture_before:
		_fail("Allocated CPU research did not increase knowledge")
		return
	var confidence := ResearchManager.research_confidence("ARCHITECTURE")
	if confidence < 20.0 or confidence > 96.0:
		_fail("Research confidence escaped its supported range")
		return
	ResearchManager.cpu_research_domains["ARCHITECTURE"]["knowledge"] = 24.9
	ResearchManager.cpu_research_domains["ARCHITECTURE"]["milestones"] = 0
	ResearchManager.process_month()
	var pending_research_events := ResearchManager.get_pending_research_events()
	if pending_research_events.is_empty():
		_fail("Research milestone did not create a discovery event")
		return
	var research_event: Dictionary = pending_research_events[0]
	if not ResearchManager.resolve_research_event(str(research_event.get("id", "")), true):
		_fail("Research discovery could not be pursued")
		return
	if int(ResearchManager.get_cpu_research_domain("ARCHITECTURE").get("momentum_months", 0)) < 3:
		_fail("Pursued research discovery did not create momentum")
		return

	var concept_money_before := Economy.money
	var mini_before := ResearchManager.get_cpu_capability("MINIATURIZATION")
	var manufacturing_before := float(ResearchManager.technologies.get("manufacturing", 0.0))
	if not ResearchManager.start_cpu_concept_program("MINIATURIZATION", 10000, 2):
		_fail("Could not launch a CPU miniaturization concept program")
		return
	var concept_loops := 0
	while not ResearchManager.get_active_cpu_concept_programs().is_empty() and concept_loops < 12:
		ResearchManager.process_month()
		concept_loops += 1
	if not ResearchManager.get_active_cpu_concept_programs().is_empty():
		_fail("CPU concept program did not reach transferable technology")
		return
	if ResearchManager.get_cpu_capability("MINIATURIZATION") <= mini_before:
		_fail("Completed concept program did not increase miniaturization capability")
		return
	if float(ResearchManager.technologies.get("manufacturing", 0.0)) <= manufacturing_before:
		_fail("Miniaturization concept did not teach manufacturing")
		return
	var nodes_after_concept := CPU_DESIGN.available_nodes_for_capabilities(
		float(ResearchManager.technologies.get("manufacturing", 0.0)),
		ResearchManager.get_cpu_capability("MINIATURIZATION")
	)
	if not nodes_after_concept.has(8000):
		_fail("Transferred miniaturization technology did not unlock the 8 µm process")
		return
	var completed_concepts := ResearchManager.get_cpu_concept_programs()
	if completed_concepts.is_empty() or str(completed_concepts[0].get("stage", "")) != "TRANSFÉRABLE":
		_fail("Concept program did not preserve its transferable result")
		return
	Economy.money = concept_money_before

	var baseline_capabilities := ResearchManager.get_cpu_capabilities()
	var improved_capabilities := baseline_capabilities.duplicate(true)
	improved_capabilities["LAYOUT"] = 70.0
	improved_capabilities["ARCHITECTURE"] = 70.0
	var demanding_design := CPU_DESIGN.preset("PERFORMANCE")
	var baseline_estimate := CPU_DESIGN.evaluate(demanding_design, baseline_capabilities)
	var improved_estimate := CPU_DESIGN.evaluate(demanding_design, improved_capabilities)
	if float(improved_estimate.get("complexity", 100.0)) >= float(baseline_estimate.get("complexity", 0.0)):
		_fail("Better architecture/layout capability did not reduce CPU design complexity")
		return

	var efficient := CPU_DESIGN.evaluate(CPU_DESIGN.preset("EFFICIENT"), ResearchManager.get_cpu_capabilities())
	var performance := CPU_DESIGN.evaluate(CPU_DESIGN.preset("PERFORMANCE"), ResearchManager.get_cpu_capabilities())
	if float(performance.get("performance", 0.0)) <= float(efficient.get("performance", 0.0)):
		_fail("Performance preset is not faster than efficient preset")
		return
	if int(performance.get("unit_cost", 0)) <= int(efficient.get("unit_cost", 0)):
		_fail("Performance preset must cost more to manufacture")
		return
	if float(efficient.get("efficiency", 0.0)) <= float(performance.get("efficiency", 0.0)):
		_fail("Efficient preset is not more efficient")
		return

	var efficient_axes := CPU_DESIGN.decision_axes(efficient)
	var performance_axes := CPU_DESIGN.decision_axes(performance)
	if efficient_axes.size() != 5 or performance_axes.size() != 5:
		_fail("CPU decision layer must expose exactly five tradeoff axes")
		return
	for axis_key in ["performance", "efficiency", "cost_control", "reliability", "delivery"]:
		var axis_score := float(efficient_axes.get(axis_key, -1.0))
		if axis_score < 0.0 or axis_score > 100.0:
			_fail("CPU decision axis escaped the 0-100 range: %s" % axis_key)
			return
	if float(performance_axes.performance) <= float(efficient_axes.performance):
		_fail("Performance preset did not improve the visible performance tradeoff")
		return
	if float(efficient_axes.cost_control) <= float(performance_axes.cost_control):
		_fail("Efficient preset should control manufacturing cost better")
		return
	if CPU_DESIGN.decision_summary(efficient_axes).is_empty():
		_fail("CPU decision summary is empty")
		return

	var preset_delta := CPU_DESIGN.decision_axis_delta(performance_axes, efficient_axes)
	if float(preset_delta.get("performance", 0.0)) <= 0.0:
		_fail("Live CPU delta must expose the performance gain")
		return
	if float(preset_delta.get("cost_control", 0.0)) >= 0.0:
		_fail("Live CPU delta must expose the manufacturing cost tradeoff")
		return
	var delta_text := CPU_DESIGN.decision_delta_summary(preset_delta)
	if not delta_text.contains("Performance +") or not delta_text.contains("Maîtrise du coût -"):
		_fail("Live CPU delta summary does not describe gains and losses")
		return
	var zero_delta := CPU_DESIGN.decision_axis_delta(efficient_axes, efficient_axes)
	if CPU_DESIGN.decision_delta_summary(zero_delta) != "Aucun écart par rapport à la référence.":
		_fail("Unchanged CPU design should report no reference delta")
		return

	var balanced_design := CPU_DESIGN.preset("BALANCED")
	var balanced_guidance := CPU_DESIGN.guidance_report(balanced_design, balanced_design, 82.0)
	if str(balanced_guidance.get("overall", "")) != "RECOMMENDED":
		_fail("Reference CPU design should remain inside the team's recommended zone")
		return
	if balanced_guidance.get("ranges", {}).size() != 4:
		_fail("CPU guidance must expose four readable parameter ranges")
		return
	var aggressive_guidance := CPU_DESIGN.guidance_report(CPU_DESIGN.preset("PERFORMANCE"), balanced_design, 82.0)
	if str(aggressive_guidance.get("overall", "")) == "RECOMMENDED":
		_fail("Aggressive CPU design was incorrectly presented as fully recommended")
		return
	if not str(aggressive_guidance.get("summary", "")).contains("équipe"):
		_fail("CPU guidance does not provide a team explanation")
		return

	var remediation_probe := CPU_DESIGN.preset("PERFORMANCE")
	var remediation_baseline := CPU_DESIGN.evaluate(remediation_probe, ResearchManager.get_cpu_capabilities())
	var remediation_options := ResearchManager.cpu_remediation_options(remediation_probe, 42_000, "PERFORMANCE")
	if remediation_options.size() != 3:
		_fail("Technical team did not return quick, recommended and ambitious remediation options")
		return
	var recommended_remediation: Dictionary = {}
	var remediation_recommended_count := 0
	for remediation_value in remediation_options:
		var remediation_option: Dictionary = remediation_value
		if int(remediation_option.get("extra_months", 0)) <= 0 or int(remediation_option.get("upfront_cost", 0)) <= 0:
			_fail("Technical remediation does not expose real time and cost consequences")
			return
		if bool(remediation_option.get("recommended", false)):
			remediation_recommended_count += 1
			recommended_remediation = remediation_option
	if remediation_recommended_count != 1:
		_fail("Technical team must recommend exactly one remediation option")
		return
	var remediation_preview := ResearchManager.cpu_remediation_preview(remediation_probe, recommended_remediation)
	if float(remediation_preview.get("risk", 100.0)) >= float(remediation_baseline.get("risk", 0.0)):
		_fail("Recommended technical remediation did not reduce estimated CPU risk")
		return
	if int(recommended_remediation.get("extra_months", 0)) != 3:
		_fail("Recommended remediation should currently represent the three-month balanced solution")
		return

	var proposals := ResearchManager.prepare_cpu_generation_proposals("MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000, CPU_DESIGN.preset("BALANCED"))
	if proposals.size() != 3:
		_fail("CPU generation council did not return three plans")
		return
	for research_proposal_value in proposals:
		var research_proposal: Dictionary = research_proposal_value
		if not research_proposal.has("research_confidence"):
			_fail("CPU proposal does not expose research confidence")
			return
		if not research_proposal.has("development_confidence") or int(research_proposal.get("development_team_size", 0)) != development_size:
			_fail("CPU proposal does not expose the dedicated Development team")
			return
	var safe_plan: Dictionary = proposals[0]
	var bold_plan: Dictionary = proposals[2]
	if float(bold_plan.get("evaluation", {}).get("performance", 0.0)) <= float(safe_plan.get("evaluation", {}).get("performance", 0.0)):
		_fail("Bold generation plan must outperform safe plan")
		return
	if float(bold_plan.get("risk", 0.0)) <= float(safe_plan.get("risk", 0.0)):
		_fail("Bold generation plan must carry more risk")
		return
	if float(safe_plan.get("confidence", 0.0)) <= float(bold_plan.get("confidence", 0.0)):
		_fail("Safe generation estimates must be more trustworthy")
		return
	var recommended_count := 0
	var selected_plan: Dictionary = proposals[1]
	for proposal_value in proposals:
		var proposal: Dictionary = proposal_value
		if int(proposal.get("potential_models", 0)) < 3:
			_fail("Every CPU generation must support the three-model launch family")
			return
		if bool(proposal.get("recommended", false)):
			recommended_count += 1
			selected_plan = proposal
	if recommended_count != 1:
		_fail("Exactly one CPU generation plan must be recommended")
		return

	var project_plan: Dictionary = bold_plan
	var cpu_design: Dictionary = project_plan.get("design", {})
	var project_remediation_options := ResearchManager.cpu_remediation_options(cpu_design, 42_000, "PERFORMANCE")
	if project_remediation_options.is_empty():
		_fail("Bold CPU plan should expose a technical remediation path")
		return
	var project_remediation: Dictionary = {}
	for remediation_value in project_remediation_options:
		var remediation_option: Dictionary = remediation_value
		if bool(remediation_option.get("recommended", false)):
			project_remediation = remediation_option
			break
	if project_remediation.is_empty():
		_fail("Bold CPU remediation has no recommended option")
		return
	var capability_before_remediation := ResearchManager.get_cpu_capability(str(project_remediation.get("capability", "ARCHITECTURE")))
	var cash_before_remediation := Economy.money
	var started: bool = ResearchManager.start_project("CI CPU", "CPU", "MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000, cpu_design, project_plan, project_remediation)
	if not started:
		_fail("Could not start R&D project with the team's technical solution")
		return
	if Economy.money != cash_before_remediation - int(project_remediation.get("upfront_cost", 0)):
		_fail("Technical remediation upfront cost was not charged when the project started")
		return
	var project: Dictionary = ResearchManager.projects[0]
	if str(project.get("segment", "")) != "EMBEDDED":
		_fail("Legacy MAINSTREAM project target was not normalized to the real 1971 embedded market")
		return
	ExecutiveManager.sync_interface_unlocks()
	if not ExecutiveManager.is_interface_feature_unlocked("TEAM"):
		_fail("Starting the first CPU project did not reveal the Team screen")
		return
	if ExecutiveManager.is_interface_feature_unlocked("PRODUCTS") or ExecutiveManager.is_interface_feature_unlocked("MARKET"):
		_fail("Product/Market screens unlocked before the CPU reached production")
		return
	if int(project.get("cpu_design", {}).get("cores", 0)) != int(cpu_design.get("cores", -1)):
		_fail("Selected generation design was not stored on the R&D project")
		return
	if str(project.get("generation_plan", {}).get("id", "")) != str(project_plan.get("id", "")):
		_fail("Generation plan was not attached to the R&D project")
		return
	if project.get("technical_remediation", {}).is_empty() or int(project.get("remediation_months_remaining", 0)) != int(project_remediation.get("extra_months", 0)):
		_fail("Technical remediation was not attached as a real pre-development phase")
		return
	if not ResearchManager.get_cpu_generation_proposals().is_empty():
		_fail("Generation proposals were not cleared after project launch")
		return
	if float(project.get("complexity", 0.0)) <= float(efficient.get("complexity", 0.0)):
		_fail("Complex CPU design did not increase development complexity")
		return
	if not project.has("research_snapshot") or float(project.get("estimate_confidence", 0.0)) <= 0.0:
		_fail("CPU project did not store its research context")
		return
	var development_snapshot: Dictionary = project.get("development_snapshot", {})
	if int(development_snapshot.get("team_size", 0)) != development_size or float(development_snapshot.get("team_score", 0.0)) <= 20.0:
		_fail("CPU project did not store its Development team context")
		return
	var loaded_development_factor := ResearchManager.development_capacity_factor()
	if loaded_development_factor >= idle_development_factor:
		_fail("Starting a CPU project did not increase Development workload")
		return
	var active_departments := ResearchManager.active_departments()
	if not active_departments.has("R&D") or not active_departments.has("Développement"):
		_fail("Research and Development are not active independently")
		return

	var initial_remediation_months := int(project.get("remediation_months_remaining", 0))
	var report: Dictionary = SimulationManager.process_month_end()
	if report.is_empty():
		_fail("Monthly report is empty")
		return
	if int(report.get("money", -1)) != Economy.money:
		_fail("Monthly report balance does not match economy")
		return
	ExecutiveManager.sync_interface_unlocks()
	if not ExecutiveManager.is_interface_feature_unlocked("COMPANY"):
		_fail("Company screen did not unlock after the first operating month")
		return
	if initial_remediation_months > 0:
		if int(project.get("phase_index", -1)) != 0 or float(project.get("phase_progress", -1.0)) != 0.0:
			_fail("CPU product development advanced before the accepted technical solution was validated")
			return
		if int(project.get("remediation_months_remaining", initial_remediation_months)) != initial_remediation_months - 1:
			_fail("Technical remediation did not consume exactly one extra month")
			return
	var remediation_guard := 0
	while int(project.get("remediation_months_remaining", 0)) > 0 and remediation_guard < 8:
		ResearchManager.process_month()
		remediation_guard += 1
	if int(project.get("remediation_months_remaining", 0)) != 0 or not bool(project.get("remediation_transfer_applied", false)):
		_fail("Technical solution did not complete and transfer its learning")
		return
	if ResearchManager.get_cpu_capability(str(project_remediation.get("capability", "ARCHITECTURE"))) <= capability_before_remediation:
		_fail("Validated project-specific technology did not improve reusable company know-how")
		return

	var range_project := project.duplicate(true)
	var completed_metrics := {}
	var completed_evaluation := CPU_DESIGN.evaluate(cpu_design)
	for metric in GameData.METRICS:
		completed_metrics[metric] = float(completed_evaluation.get(metric, 62.0))
	range_project["final_metrics"] = completed_metrics
	range_project["status"] = "COMPLETED"
	ProductionManager._on_project_completed(range_project)
	ExecutiveManager.sync_interface_unlocks()
	if not ExecutiveManager.is_interface_feature_unlocked("PRODUCTS"):
		_fail("Products screen did not unlock when CPU industrialization began")
		return
	if ExecutiveManager.is_interface_feature_unlocked("MARKET"):
		_fail("Market screen unlocked before a CPU was commercialized")
		return
	if ProductionManager.get_active_jobs().size() != 1:
		_fail("Completed CPU development did not enter industrialization")
		return
	if not ProductManager.products.is_empty():
		_fail("CPU became sellable before industrialization completed")
		return
	var industrial_job: Dictionary = ProductionManager.get_active_jobs()[0]
	if str(industrial_job.get("manufacturing_mode", "")) != "EXTERNAL" or str(industrial_job.get("foundry_id", "")) == "":
		_fail("CPU industrialization did not receive a default external foundry route")
		return
	var route_quote := ProductionManager.manufacturing_route_quote(str(industrial_job.get("id", "")))
	if route_quote.is_empty() or float(route_quote.get("dependency", -1.0)) < 0.0 or float(route_quote.get("confidentiality", -1.0)) < 0.0:
		_fail("Industrialization route did not expose supplier dependency/confidentiality")
		return
	var compatible_foundries := FoundryManager.available_external_foundries(int(industrial_job.get("node_nm", 10000)))
	if compatible_foundries.is_empty():
		_fail("No foundry remained compatible with the developed CPU process")
		return
	var chosen_foundry := str(compatible_foundries[compatible_foundries.size() - 1])
	if not ProductionManager.set_manufacturing_route(str(industrial_job.get("id", "")), "EXTERNAL", chosen_foundry):
		_fail("Could not choose an external foundry before industrialization started")
		return
	if not ProductionManager.set_strategy(str(industrial_job.get("id", "")), "QUALITY"):
		_fail("Could not apply an industrialization strategy")
		return
	if not ProductionManager.set_binning_strategy(str(industrial_job.get("id", "")), "STRICT"):
		_fail("Could not apply a silicon binning strategy")
		return
	if str(industrial_job.get("binning_strategy", "")) != "STRICT":
		_fail("Industrialization did not store the selected silicon binning policy")
		return
	var production_mastery_before := ProductionManager.get_process_mastery(int(industrial_job.get("node_nm", 7)))
	var production_iterations := 0
	while not ProductionManager.get_active_jobs().is_empty() and production_iterations < 12:
		ProductionManager.process_month()
		production_iterations += 1
	if not ProductionManager.get_active_jobs().is_empty():
		_fail("CPU industrialization did not finish in a reasonable number of months")
		return
	if ProductManager.cpu_generations.size() != 1 or ProductManager.products.size() != 3:
		_fail("Completed industrialization did not create one generation with three launch models")
		return
	if ProductionManager.get_process_mastery(int(industrial_job.get("node_nm", 7))) <= production_mastery_before:
		_fail("Production team did not learn from industrialization")
		return
	var completed_industrial_job: Dictionary = ProductionManager.jobs[0]
	var industrial_result: Dictionary = completed_industrial_job.get("result", {})
	if float(industrial_result.get("quality_score", 0.0)) <= 0.0 or float(industrial_result.get("defect_rate", -1.0)) < 0.0:
		_fail("Industrialization did not produce quality and defect results")
		return
	if str(industrial_result.get("strategy", "")) != "QUALITY":
		_fail("Industrialization did not preserve the chosen strategy")
		return
	if str(industrial_result.get("binning_strategy", "")) != "STRICT":
		_fail("Industrialization did not preserve the chosen binning strategy")
		return
	if str(industrial_result.get("manufacturing_mode", "")) != "EXTERNAL" or str(industrial_result.get("foundry_id", "")) != chosen_foundry:
		_fail("Industrialization did not preserve the selected external foundry")
		return
	if str(industrial_result.get("foundry_name", "")) == "" or int(industrial_result.get("foundry_capacity", 0)) <= 0:
		_fail("Industrialization result lost foundry identity/capacity")
		return
	if float(industrial_result.get("die_quality_mean", 0.0)) <= 0.0 or float(industrial_result.get("die_variation", 0.0)) <= 0.0:
		_fail("Industrialization did not produce manufactured die quality and variation")
		return
	if float(industrial_result.get("lithography_precision", 0.0)) <= 0.0 or float(industrial_result.get("design_margin_score", 0.0)) <= 0.0:
		_fail("Die quality is not causally tied to lithography/equipment and design margin")
		return
	if float(industrial_result.get("process_predictability", 0.0)) < 20.0 or float(industrial_result.get("oc_headroom_pct", -1.0)) < 0.0:
		_fail("Industrialization silicon predictability/headroom escaped supported ranges")
		return
	var cpu_generation: Dictionary = ProductManager.cpu_generations[0]
	var essential_model: Dictionary = ProductManager.products[0]
	var signature_model: Dictionary = ProductManager.products[1]
	var apex_model: Dictionary = ProductManager.products[2]
	if str(essential_model.get("sku_tier", "")) != "ESSENTIAL" or str(signature_model.get("sku_tier", "")) != "SIGNATURE" or str(apex_model.get("sku_tier", "")) != "APEX":
		_fail("CPU product family tiers are missing or out of order")
		return
	if str(essential_model.get("generation_id", "")) != str(apex_model.get("generation_id", "")):
		_fail("CPU models were not linked to the same generation")
		return
	var family_recommended_capacity := 0
	for family_model in ProductManager.products:
		family_recommended_capacity += int(family_model.get("recommended_capacity", 0))
		var suggested_price := int(family_model.get("price", 0))
		var unit_cost := int(family_model.get("unit_cost", 0))
		var gross_margin := 1.0 - float(unit_cost) / maxf(float(suggested_price), 1.0)
		if gross_margin + 0.015 < BalanceManager.gross_margin_target(str(family_model.get("target_segment", "EMBEDDED"))):
			_fail("Suggested CPU price fell below the market-specific gross margin guard")
			return
	var target_family_capacity := maxi(300, int(float(MarketManager.segment_market_units("EMBEDDED")) * 0.22))
	if family_recommended_capacity > target_family_capacity + 6:
		_fail("CPU launch family capacity exceeded the actual target market sizing")
		return
	for family_market_model in [essential_model, signature_model, apex_model]:
		if str(family_market_model.get("target_segment", "")) != "EMBEDDED":
			_fail("CPU binning invented a modern market instead of preserving the selected 1971 use case")
			return
	if float(apex_model.get("metrics", {}).get("performance", 0.0)) <= float(essential_model.get("metrics", {}).get("performance", 0.0)):
		_fail("Apex model must outperform the Essential model")
		return
	if int(apex_model.get("unit_cost", 0)) <= int(essential_model.get("unit_cost", 0)):
		_fail("Apex bin must cost more than the Essential bin")
		return
	var apex_design: Dictionary = apex_model.get("cpu_design", {})
	var essential_design: Dictionary = essential_model.get("cpu_design", {})
	var apex_is_faster := float(apex_design.get("frequency_ghz", 0.0)) > float(essential_design.get("frequency_ghz", 0.0))
	var apex_has_more_cores := int(apex_design.get("cores", 0)) > int(essential_design.get("cores", 0))
	if not apex_is_faster and not apex_has_more_cores:
		_fail("Product binning did not create distinct CPU configurations")
		return
	var bin_total := 0.0
	for bin_product in ProductManager.products:
		bin_total += float(bin_product.get("bin_share", 0.0))
	if absf(bin_total - 1.0) > 0.001:
		_fail("CPU bin allocation does not total 100 percent")
		return
	if float(cpu_generation.get("yield_rate", 0.0)) < 0.40 or float(cpu_generation.get("yield_rate", 0.0)) > 0.94:
		_fail("CPU generation yield escaped its supported range")
		return
	if float(cpu_generation.get("manufacturing_quality", 0.0)) <= 0.0 or float(cpu_generation.get("defect_rate", -1.0)) < 0.0:
		_fail("CPU generation did not keep its industrialization quality")
		return
	if float(apex_model.get("manufacturing_quality", 0.0)) <= 0.0 or str(apex_model.get("industrialization_strategy", "")) != "QUALITY":
		_fail("CPU products did not inherit industrialization data")
		return
	if str(apex_model.get("binning_strategy", "")) != "STRICT":
		_fail("CPU products did not inherit the silicon binning strategy")
		return
	if str(apex_model.get("foundry_id", "")) != chosen_foundry or str(apex_model.get("manufacturing_mode", "")) != "EXTERNAL":
		_fail("CPU products did not inherit their actual manufacturing source")
		return
	if int(apex_model.get("max_monthly_capacity", 0)) > int(industrial_result.get("foundry_capacity", 0)):
		_fail("CPU product capacity exceeded the selected foundry capacity")
		return
	if float(apex_model.get("die_quality", 0.0)) <= float(signature_model.get("die_quality", 0.0)) or float(signature_model.get("die_quality", 0.0)) <= float(essential_model.get("die_quality", 0.0)):
		_fail("Electrical die quality does not increase across Essential, Signature and Apex bins")
		return
	if float(apex_model.get("die_variation", 99.0)) >= float(cpu_generation.get("die_variation", 99.0)):
		_fail("Strict binning did not narrow the variation inside the selected Apex bin")
		return
	if float(apex_model.get("oc_headroom_pct", 0.0)) <= float(essential_model.get("oc_headroom_pct", 0.0)):
		_fail("Apex silicon should expose more typical overclocking headroom than Essential")
		return
	if float(apex_model.get("typical_oc_frequency_ghz", 0.0)) <= float(apex_model.get("cpu_design", {}).get("frequency_ghz", 0.0)):
		_fail("Typical overclocking frequency does not exceed the guaranteed Apex frequency")
		return
	var enthusiast_baseline := apex_model.duplicate(true)
	enthusiast_baseline["oc_headroom_pct"] = 0.0
	enthusiast_baseline["die_consistency"] = 50.0
	if MarketManager.evaluate_product(apex_model, "HOBBYIST") <= MarketManager.evaluate_product(enthusiast_baseline, "HOBBYIST"):
		_fail("Hobbyist market does not value die headroom and consistency")
		return

	var portfolio_demand := MarketManager.estimate_portfolio_demand(ProductManager.products)
	var portfolio_units := 0
	for demand_product in ProductManager.products:
		portfolio_units += int(portfolio_demand.get(str(demand_product.id), {}).get("units", 0))
	var family_market := MarketManager.normalize_segment(str(apex_model.get("target_segment", MarketManager.default_segment())))
	var family_market_units := MarketManager.segment_market_units(family_market)
	if portfolio_demand.size() != 3 or portfolio_units > family_market_units:
		_fail("Portfolio demand did not cap the CPU family to its actual era market")
		return

	var apex_max_capacity := int(apex_model.get("max_monthly_capacity", 1))
	if not ProductManager.launch_product(str(apex_model.id), int(apex_model.price), apex_max_capacity + 9999):
		_fail("Could not launch an available CPU family model")
		return
	if int(apex_model.production_capacity) != apex_max_capacity:
		_fail("CPU launch ignored the binning capacity limit")
		return
	ExecutiveManager.sync_interface_unlocks()
	if not ExecutiveManager.is_interface_feature_unlocked("MARKET"):
		_fail("Market screen did not unlock after the first CPU launch")
		return
	if ExecutiveManager.is_interface_feature_unlocked("PRESS"):
		_fail("Press screen unlocked before any real product feedback")
		return
	var review_scores := MarketManager.segment_scores(apex_model)
	var review_rows := MarketManager.benchmark_for(apex_model)
	MediaManager.publish_product_review(apex_model, review_scores, MarketManager.benchmark_rank(apex_model), review_rows.size())
	ExecutiveManager.sync_interface_unlocks()
	if not ExecutiveManager.is_interface_feature_unlocked("PRESS"):
		_fail("Press screen did not unlock after the first public CPU review")
		return
	var progressed_executive_state := ExecutiveManager.get_state().duplicate(true)
	ExecutiveManager.reset()
	ExecutiveManager.load_state(progressed_executive_state)
	if not ExecutiveManager.is_interface_feature_unlocked("PRESS") or ExecutiveManager.get_unlock_history().is_empty():
		_fail("Progressive UI unlocks did not survive an executive-state round-trip")
		return

	var lifecycle_initial := ProductManager.get_post_launch_summary(str(apex_model.id))
	if str(lifecycle_initial.get("revision", "")) != "A0" or int(lifecycle_initial.get("firmware_version", 0)) != 1:
		_fail("Newly launched CPU did not receive baseline revision and firmware state")
		return
	if bool(lifecycle_initial.get("firmware_available", true)) or bool(lifecycle_initial.get("control_software_available", true)):
		_fail("Advanced CPU software lifecycle should not be available to the early-era company immediately")
		return

	var price_before := int(apex_model.price)
	if not ProductManager.update_product_price(str(apex_model.id), maxi(price_before - 5, 1)):
		_fail("Could not change price of a launched CPU")
		return
	if int(apex_model.price) >= price_before or apex_model.get("commercial_history", []).is_empty():
		_fail("Post-launch price change did not persist commercially")
		return

	var demand_before_promotion := MarketManager.estimate_consumer_demand(apex_model)
	if not ProductManager.start_promotion(str(apex_model.id), "VALUE"):
		_fail("Could not start a post-launch CPU promotion")
		return
	var demand_during_promotion := MarketManager.estimate_consumer_demand(apex_model)
	if float(demand_during_promotion.get("score", 0.0)) <= float(demand_before_promotion.get("score", 0.0)):
		_fail("Product promotion did not improve market attractiveness")
		return
	if int(apex_model.get("promotion_months_remaining", 0)) != 2:
		_fail("Promotion duration was not stored on the product")
		return

	var sold_before_revision := int(apex_model.get("units_sold_total", 0))
	var defect_before_revision := float(apex_model.get("defect_rate", 0.025))
	var consistency_before_revision := float(apex_model.get("die_consistency", 0.0))
	var lithography_before_revision := float(apex_model.get("lithography_precision", 0.0))
	var oc_before_revision := float(apex_model.get("oc_headroom_pct", 0.0))
	if not ProductManager.apply_hardware_revision(str(apex_model.id), "QUALITY"):
		_fail("Could not create a post-launch CPU hardware stepping")
		return
	if str(apex_model.get("revision_label", "")) != "A1":
		_fail("Hardware revision did not increment the CPU stepping")
		return
	if float(apex_model.get("defect_rate", 1.0)) >= defect_before_revision:
		_fail("Reliability-focused stepping did not improve future manufacturing defects")
		return
	if int(apex_model.get("units_sold_total", -1)) != sold_before_revision:
		_fail("Hardware stepping incorrectly modified the already-sold installed base")
		return
	if float(apex_model.get("die_consistency", 0.0)) <= consistency_before_revision or float(apex_model.get("oc_headroom_pct", 0.0)) <= oc_before_revision:
		_fail("Reliability stepping did not improve future die consistency/headroom")
		return
	if float(apex_model.get("lithography_precision", 0.0)) <= lithography_before_revision:
		_fail("Reliability stepping did not improve future process/calibration precision")
		return

	ResearchManager.technologies["software"] = 20.0
	ResearchManager.technologies["integration"] = 28.0
	ResearchManager.cpu_capabilities["ARCHITECTURE"] = maxf(ResearchManager.get_cpu_capability("ARCHITECTURE"), 30.0)
	if not ProductManager.firmware_available(apex_model) or not ProductManager.control_software_available(apex_model):
		_fail("CPU software lifecycle did not unlock after sufficient software, integration and architecture knowledge")
		return
	var firmware_field_before := AfterSalesManager.cpu_field_experience("FIRMWARE")
	var reliability_before_firmware := float(apex_model.get("metrics", {}).get("reliability", 0.0))
	if not ProductManager.release_firmware(str(apex_model.id), "STABILITY"):
		_fail("Could not publish a CPU stability firmware")
		return
	if int(apex_model.get("firmware_version", 0)) != 2:
		_fail("Firmware version did not advance")
		return
	if float(apex_model.get("metrics", {}).get("reliability", 0.0)) <= reliability_before_firmware:
		_fail("Stability firmware did not improve reliability")
		return
	if AfterSalesManager.cpu_field_experience("FIRMWARE") <= firmware_field_before:
		_fail("Firmware publication did not teach the support/research loop")
		return

	var usability_before_software := float(apex_model.get("metrics", {}).get("usability", 0.0))
	if not ProductManager.release_control_software(str(apex_model.id)):
		_fail("Could not release linked CPU control software")
		return
	var apex_software: Dictionary = apex_model.get("control_software", {})
	if not bool(apex_software.get("released", false)) or int(apex_software.get("version", 0)) != 1:
		_fail("CPU control software did not attach to the launched product")
		return
	if apex_software.get("supported_product_ids", []).size() != 3:
		_fail("CPU control software does not expose the explicit compatible model list")
		return
	if float(apex_model.get("metrics", {}).get("usability", 0.0)) <= usability_before_software:
		_fail("CPU control software did not improve the supported product experience")
		return
	for family_model in ProductManager.products:
		if not bool(family_model.get("control_software", {}).get("released", false)):
			_fail("Generation control software was not shared with every compatible CPU model")
			return

	ProductManager._tick_post_launch_state(apex_model)
	ProductManager._tick_post_launch_state(apex_model)
	if str(apex_model.get("promotion_type", "")) != "NONE" or float(apex_model.get("promotion_bonus", -1.0)) != 0.0:
		_fail("Expired promotion did not clear its temporary demand bonus")
		return

	var field_before := AfterSalesManager.cpu_field_experience()
	apex_model["defect_rate"] = 0.085
	apex_model["manufacturing_quality"] = 42.0
	var apex_metrics: Dictionary = apex_model.get("metrics", {})
	apex_metrics["reliability"] = 46.0
	apex_model["metrics"] = apex_metrics
	apex_model["last_month_returns"] = 18
	AfterSalesManager._on_sales_report({"product_id":str(apex_model.id), "units":240})
	if AfterSalesManager.get_open_cases().size() != 1:
		_fail("Field returns did not create an after-sales case")
		return
	if AfterSalesManager.cpu_field_experience() <= field_before:
		_fail("Real-world sales and returns did not increase field experience")
		return
	var sav_case: Dictionary = AfterSalesManager.get_open_cases()[0]
	var sav_case_id := str(sav_case.get("id", ""))
	if not AfterSalesManager.start_investigation(sav_case_id):
		_fail("Could not start an after-sales investigation")
		return
	var investigation_loops := 0
	while str(AfterSalesManager.get_case(sav_case_id).get("status", "")) == "INVESTIGATING" and investigation_loops < 12:
		AfterSalesManager.process_month()
		investigation_loops += 1
	if str(AfterSalesManager.get_case(sav_case_id).get("status", "")) != "DIAGNOSED":
		_fail("After-sales investigation did not reach a diagnosis")
		return
	var fix_count_before := int(apex_model.get("field_fix_count", 0))
	var field_after_diagnosis := AfterSalesManager.cpu_field_experience()
	if not AfterSalesManager.apply_corrective_action(sav_case_id):
		_fail("Diagnosed after-sales case could not be corrected")
		return
	if str(AfterSalesManager.get_case(sav_case_id).get("status", "")) != "RESOLVED":
		_fail("Corrective action did not resolve the after-sales case")
		return
	if int(apex_model.get("field_fix_count", 0)) <= fix_count_before:
		_fail("Corrective action did not modify the affected product")
		return
	if AfterSalesManager.cpu_field_experience() <= field_after_diagnosis:
		_fail("Resolved field case did not teach the company")
		return
	var learned_proposals := ResearchManager.prepare_cpu_generation_proposals("PRO", "INTERNAL", "RELIABILITY", 50_000, CPU_DESIGN.preset("BALANCED"))
	if learned_proposals.is_empty() or float(learned_proposals[0].get("field_experience", 0.0)) <= 0.0:
		_fail("Future CPU proposals ignored accumulated field experience")
		return

	var fresh_probe := apex_model.duplicate(true)
	fresh_probe["months_on_market"] = 6
	var aged_probe := apex_model.duplicate(true)
	aged_probe["months_on_market"] = 30
	var fresh_demand := MarketManager.estimate_consumer_demand(fresh_probe)
	var aged_demand := MarketManager.estimate_consumer_demand(aged_probe)
	if float(fresh_demand.get("age_penalty", -1.0)) != 0.0:
		_fail("Fresh CPU received an aging penalty")
		return
	if float(aged_demand.get("age_penalty", 0.0)) <= 0.0:
		_fail("Old CPU did not receive a commercial aging penalty")
		return
	if float(aged_demand.get("score", 100.0)) >= float(fresh_demand.get("score", 0.0)):
		_fail("CPU aging did not reduce commercial attractiveness")
		return

	var competitor_before: Dictionary = MarketManager.competitors.get("CPU", [])[0].duplicate(true)
	var competitor_generation_before := int(competitor_before.get("generation_index", 1))
	var competitor_arch_before := float(competitor_before.get("architecture_skill", 0.0))
	var competitor_progress_before := float(competitor_before.get("development_progress", 0.0))
	var competitor_cash_before := int(competitor_before.get("cash", 0))
	var competitor_loops := 0
	while int(MarketManager.competitors.get("CPU", [])[0].get("generation_index", 1)) == competitor_generation_before and competitor_loops < 30:
		MarketManager.process_month([])
		competitor_loops += 1
	var competitor_after: Dictionary = MarketManager.competitors.get("CPU", [])[0].duplicate(true)
	if float(competitor_after.get("architecture_skill", 0.0)) <= competitor_arch_before:
		_fail("CPU competitor R&D did not improve its technical capability")
		return
	if int(competitor_after.get("cash", 0)) == competitor_cash_before:
		_fail("CPU competitor finances did not react to sales, R&D and fixed costs")
		return
	if int(competitor_after.get("generation_index", 1)) <= competitor_generation_before:
		_fail("CPU competitor did not complete a real next-generation development cycle")
		return
	if float(competitor_after.get("development_progress", 100.0)) >= competitor_progress_before and competitor_loops >= 30:
		_fail("CPU competitor development did not reset after its generation launch")
		return
	if int(competitor_after.get("node_nm", 0)) <= 0 or int(competitor_after.get("capacity", 0)) <= 0 or float(competitor_after.get("yield_rate", 0.0)) <= 0.0:
		_fail("CPU competitor generation has no process, capacity or yield constraints")
		return
	var market_round_trip := MarketManager.get_state().duplicate(true)
	var saved_market_age := MarketManager.market_age_months
	var saved_competitor_generation := int(competitor_after.get("generation_index", 1))
	var saved_known_markets := MarketManager.known_segments.size()
	MarketManager.reset()
	MarketManager.load_state(market_round_trip)
	if MarketManager.market_age_months != saved_market_age:
		_fail("Market age did not survive a save round-trip")
		return
	if int(MarketManager.competitors.get("CPU", [])[0].get("generation_index", 0)) != saved_competitor_generation:
		_fail("Competitor generation state did not survive a save round-trip")
		return
	if MarketManager.known_segments.size() != saved_known_markets:
		_fail("Evolving market unlock state did not survive a save round-trip")
		return
	var after_sales_round_trip := AfterSalesManager.get_state().duplicate(true)
	var saved_field_experience := AfterSalesManager.cpu_field_experience()
	AfterSalesManager.reset()
	AfterSalesManager.load_state(after_sales_round_trip)
	if absf(AfterSalesManager.cpu_field_experience() - saved_field_experience) > 0.001:
		_fail("Field experience did not survive a save round-trip")
		return
	if AfterSalesManager.cases.is_empty() or str(AfterSalesManager.cases[0].get("status", "")) != "RESOLVED":
		_fail("After-sales cases did not survive a save round-trip")
		return

	var production_round_trip := ProductionManager.get_state().duplicate(true)
	var saved_process_mastery := ProductionManager.get_process_mastery(int(completed_industrial_job.get("node_nm", 7)))
	ProductionManager.reset()
	ProductionManager.load_state(production_round_trip)
	if absf(ProductionManager.get_process_mastery(int(completed_industrial_job.get("node_nm", 7))) - saved_process_mastery) > 0.001:
		_fail("Production mastery did not survive a save round-trip")
		return
	if ProductionManager.jobs.size() != 1 or str(ProductionManager.jobs[0].get("status", "")) != "COMPLETED":
		_fail("Industrialization job did not survive a save round-trip")
		return
	var product_round_trip := ProductManager.get_state().duplicate(true)
	ProductManager.reset()
	ProductManager.load_state(product_round_trip)
	if ProductManager.cpu_generations.size() != 1 or ProductManager.products.size() != 3:
		_fail("CPU product family did not survive a save round-trip")
		return
	var restored_apex := ProductManager.get_product(str(apex_model.id))
	var restored_lifecycle := ProductManager.get_post_launch_summary(str(apex_model.id))
	if restored_apex.is_empty() or str(restored_lifecycle.get("revision", "")) != "A1" or int(restored_lifecycle.get("firmware_version", 0)) != 2:
		_fail("CPU post-launch revision or firmware state did not survive a save round-trip")
		return
	if float(restored_apex.get("die_quality", 0.0)) <= 0.0 or float(restored_apex.get("oc_headroom_pct", -1.0)) < 0.0 or str(restored_apex.get("binning_strategy", "")) != "STRICT":
		_fail("CPU die/process distribution data did not survive a save round-trip")
		return
	if str(restored_apex.get("foundry_id", "")) != chosen_foundry:
		_fail("CPU manufacturing source did not survive a save round-trip")
		return
	if not bool(restored_lifecycle.get("software_released", false)) or int(restored_lifecycle.get("software_version", 0)) != 1:
		_fail("Linked CPU control software did not survive a save round-trip")
		return
	if restored_apex.get("commercial_history", []).is_empty() or restored_apex.get("revision_history", []).is_empty() or restored_apex.get("firmware_history", []).is_empty():
		_fail("CPU lifecycle histories did not survive a save round-trip")
		return
	var legacy_product_state := product_round_trip.duplicate(true)
	legacy_product_state.erase("cpu_generations")
	legacy_product_state.erase("next_generation_id")
	for legacy_product in legacy_product_state.get("products", []):
		legacy_product.erase("generation_id")
		legacy_product.erase("generation_index")
		legacy_product.erase("generation_name")
	ProductManager.load_state(legacy_product_state)
	if ProductManager.cpu_generations.is_empty() or str(ProductManager.products[0].get("generation_id", "")).is_empty():
		_fail("Legacy V5 products were not migrated into a CPU generation")
		return

	ProductionManager.load_state({})
	if not ProductionManager.jobs.is_empty() or ProductionManager.get_process_mastery(7) <= 0.0:
		_fail("Legacy save without Production state did not receive production defaults")
		return
	AfterSalesManager.load_state({})
	if not AfterSalesManager.cases.is_empty() or AfterSalesManager.cpu_field_experience() != 0.0:
		_fail("Legacy save without after-sales state did not receive clean defaults")
		return

	var legacy_state := ResearchManager.get_state().duplicate(true)
	var legacy_projects: Array = legacy_state.get("projects", [])
	var legacy_project: Dictionary = legacy_projects[0]
	legacy_project.erase("cpu_design")
	legacy_project.erase("design_estimate")
	legacy_project.erase("complexity")
	legacy_project.erase("generation_plan")
	legacy_project.erase("technical_remediation")
	legacy_project.erase("remediation_months_remaining")
	legacy_project.erase("remediation_total_months")
	legacy_project.erase("remediation_transfer_applied")
	legacy_state.erase("cpu_generation_proposals")
	legacy_state.erase("cpu_generation_context")
	ResearchManager.load_state(legacy_state)
	var migrated_project: Dictionary = ResearchManager.projects[0]
	if not migrated_project.has("cpu_design") or migrated_project.get("design_estimate", {}).is_empty():
		_fail("Legacy R&D save was not migrated to a CPU design")
		return
	if not migrated_project.get("generation_plan", {}).is_empty():
		_fail("Legacy project received an invalid generation plan")
		return
	if not migrated_project.get("technical_remediation", {}).is_empty() or int(migrated_project.get("remediation_months_remaining", 0)) != 0:
		_fail("Legacy project received an invalid technical remediation phase")
		return

	ResearchManager.prepare_cpu_generation_proposals("PRO", "HYBRID", "RELIABILITY", 50_000, CPU_DESIGN.preset("BALANCED"))
	var research_round_trip := ResearchManager.get_state().duplicate(true)
	var saved_architecture_knowledge := float(ResearchManager.get_cpu_research_domain("ARCHITECTURE").get("knowledge", 0.0))
	var saved_research_budget := ResearchManager.continuous_research_budget
	var saved_miniaturization := ResearchManager.get_cpu_capability("MINIATURIZATION")
	var saved_concept_count := ResearchManager.get_cpu_concept_programs().size()
	ResearchManager.load_state(research_round_trip)
	if ResearchManager.get_cpu_generation_proposals().size() != 3:
		_fail("Generation proposals did not survive a save round-trip")
		return
	if absf(float(ResearchManager.get_cpu_research_domain("ARCHITECTURE").get("knowledge", 0.0)) - saved_architecture_knowledge) > 0.001:
		_fail("CPU research knowledge did not survive a save round-trip")
		return
	if ResearchManager.continuous_research_budget != saved_research_budget:
		_fail("CPU research budget did not survive a save round-trip")
		return
	if absf(ResearchManager.get_cpu_capability("MINIATURIZATION") - saved_miniaturization) > 0.001:
		_fail("CPU technical capabilities did not survive a save round-trip")
		return
	if ResearchManager.get_cpu_concept_programs().size() != saved_concept_count:
		_fail("CPU concept programs did not survive a save round-trip")
		return
	var legacy_research_state := research_round_trip.duplicate(true)
	legacy_research_state.erase("cpu_research_domains")
	legacy_research_state.erase("continuous_research_budget")
	legacy_research_state.erase("research_events")
	legacy_research_state.erase("cpu_capabilities")
	legacy_research_state.erase("concept_programs")
	legacy_research_state.erase("next_concept_id")
	legacy_research_state.erase("next_research_event_id")
	ResearchManager.load_state(legacy_research_state)
	if ResearchManager.get_cpu_research_domain_keys().size() != 3:
		_fail("Legacy research save did not receive default CPU research domains")
		return
	if ResearchManager.get_cpu_capability("MINIATURIZATION") <= 0.0 or not ResearchManager.get_cpu_concept_programs().is_empty():
		_fail("Legacy research save did not receive clean CPU capability / concept defaults")
		return

	var legacy_company_state := CompanyManager.get_state().duplicate(true)
	legacy_company_state["departments"].erase("Développement")
	CompanyManager.load_state(legacy_company_state)
	if not CompanyManager.departments.has("Développement"):
		_fail("Legacy company save did not receive the Development department")
		return
	var legacy_personnel_state := PersonnelManager.get_state().duplicate(true)
	var legacy_staff: Array = legacy_personnel_state.get("staff", [])
	var has_legacy_samira := false
	for existing_emp in legacy_staff:
		if str(existing_emp.get("name", "")) == "Samira Lefèvre":
			has_legacy_samira = true
			break
	if not has_legacy_samira:
		legacy_staff.append({
			"id":"EMP-LEGACY-SAMIRA",
			"name":"Samira Lefèvre",
			"role":"Ingénieure produit",
			"department":"R&D",
			"skill":64,
			"aptitude":66,
			"experience_years":4.0,
			"specialization":"product",
			"domain_experience":{"product":4.0},
			"leadership":58,
			"salary":4400,
			"morale":75.0
		})
		legacy_personnel_state["staff"] = legacy_staff
	for legacy_emp in legacy_personnel_state.get("staff", []):
		if str(legacy_emp.get("name", "")) == "Samira Lefèvre":
			legacy_emp["department"] = "R&D"
			legacy_emp["specialization"] = "product"
	CompanyManager.departments["Développement"]["leader_id"] = ""
	PersonnelManager.load_state(legacy_personnel_state)
	var migrated_samira_department := ""
	for migrated_emp in PersonnelManager.staff:
		if str(migrated_emp.get("name", "")) == "Samira Lefèvre":
			migrated_samira_department = str(migrated_emp.get("department", ""))
	if migrated_samira_department != "Développement":
		_fail("Legacy product engineer was not migrated to Development")
		return
	if str(CompanyManager.departments["Développement"].get("leader_id", "")) == "":
		_fail("Legacy Development department did not recover a leader")
		return

	var division_state := DivisionManager.get_state()
	DivisionManager.reset("CPU")
	DivisionManager.load_state(division_state)
	var restored_cpu := DivisionManager.get_division("CPU")
	if int(restored_cpu.get("generation_count", 0)) != 1 or float(restored_cpu.get("maturity", 0.0)) <= 12.0:
		_fail("Division progress did not survive a save round-trip")
		return
	DivisionManager.load_state({})
	if DivisionManager.get_active_division_keys() != ["CPU"]:
		_fail("Legacy V3 save was not migrated to the CPU division")
		return

	ProductManager.reset()
	Economy.money = 1
	SimulationManager.is_game_over = false
	var bankruptcy_report := SimulationManager.process_month_end()
	if not SimulationManager.is_game_over:
		_fail("Empty treasury did not trigger bankruptcy")
		return
	if int(bankruptcy_report.get("money", 1)) > 0:
		_fail("Bankruptcy test did not exhaust treasury")
		return
	if TimeManager.time_scale != 0.0:
		_fail("Bankruptcy did not pause the simulation")
		return

	print("[CI] Smoke test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("[CI] " + message)
	get_tree().quit(1)
