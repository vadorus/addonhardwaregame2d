extends Node

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CPU_SUPPORT := preload("res://scripts/CpuSupportModel.gd")
const INDUSTRIALIZATION := preload("res://scripts/IndustrializationModel.gd")

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
	var forbidden: bool = ResearchManager.start_project("Forbidden GPU", "GPU", "MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000)
	if forbidden:
		_fail("Inactive GPU branch accepted a research project")
		return
	if not CompanyManager.created:
		_fail("Company was not created")
		return
	if CompanyManager.SUBSIDIARIES_ENABLED:
		_fail("Subsidiaries must remain locked during the CPU vertical slice")
		return
	if CompanyManager.create_subsidiary("Fake Subsidiary", "CPU", 50_000):
		_fail("Locked subsidiary creation unexpectedly succeeded")
		return
	if PersonnelManager.staff.size() != 2:
		_fail("New companies must start with the two-person garage team")
		return
	if str(PersonnelManager.staff[0].get("name", "")) != "Camille Durand":
		_fail("Camille must remain the founding CTO")
		return
	var founder_personnel_state := PersonnelManager.get_state().duplicate(true)
	var direct_management := CompanyManager.estimate_department_management_modifier("R&D", "DIRECT", "")
	var autonomous_without_leader := CompanyManager.estimate_department_management_modifier("R&D", "AUTONOMOUS", "")
	var autonomous_with_camille := CompanyManager.estimate_department_management_modifier("R&D", "AUTONOMOUS", str(PersonnelManager.staff[0].get("id", "")))
	if not is_equal_approx(direct_management, 1.0):
		_fail("Direct department management must remain neutral")
		return
	if autonomous_with_camille <= autonomous_without_leader:
		_fail("A strong department leader did not improve autonomous management")
		return
	if PersonnelManager.dismiss_employee(str(PersonnelManager.staff[0].get("id", ""))):
		_fail("Founding employee could be dismissed")
		return
	var founder_rd_score := PersonnelManager.team_score("R&D", "cpu")
	PersonnelManager._add_employee("Junior Test", "Stagiaire R&D", "R&D", 35, 0.0, "cpu", 15, 2400)
	var junior_id := str(PersonnelManager.staff[-1].get("id", ""))
	var junior_salary := int(PersonnelManager.staff[-1].get("salary", 0))
	CompanyManager.set_department_leader("R&D", junior_id)
	var money_before_dismissal := Economy.money
	if not PersonnelManager.dismiss_employee(junior_id):
		_fail("Non-founder employee could not be dismissed")
		return
	if Economy.money != money_before_dismissal - junior_salary:
		_fail("Employee dismissal did not charge one month of severance")
		return
	if str(CompanyManager.departments["R&D"].get("leader_id", "")) != "":
		_fail("Dismissed department leader was not cleared")
		return
	PersonnelManager._add_employee("Junior Test", "Stagiaire R&D", "R&D", 35, 0.0, "cpu", 15, 2400)
	var expanded_rd_score := PersonnelManager.team_score("R&D", "cpu")
	if expanded_rd_score + 0.001 < founder_rd_score:
		_fail("Adding a junior employee reduced the R&D team score")
		return
	PersonnelManager.load_state(founder_personnel_state)
	var search_economy_state := Economy.get_state().duplicate(true)
	var money_before_search := Economy.money
	if not PersonnelManager.search_candidate("Production"):
		_fail("Candidate search unexpectedly failed with sufficient cash")
		return
	if Economy.money != money_before_search - PersonnelManager.CANDIDATE_SEARCH_COST:
		_fail("Candidate search fee was not charged")
		return
	if str(PersonnelManager.candidate.get("department", "")) != "Production":
		_fail("Paid candidate search returned the wrong department")
		return
	Economy.money = PersonnelManager.CANDIDATE_SEARCH_COST - 1
	if PersonnelManager.search_candidate("Marketing"):
		_fail("Candidate search succeeded without enough cash")
		return
	Economy.load_state(search_economy_state)
	PersonnelManager.load_state(founder_personnel_state)
	for _candidate_roll in range(12):
		var candidate := PersonnelManager.generate_candidate("R&D")
		var specialization := str(candidate.get("specialization", ""))
		if specialization != "cpu" and specialization != "product":
			_fail("R&D candidate specialization escaped the active CPU vertical slice: %s" % specialization)
			return
	PersonnelManager.load_state(founder_personnel_state)
	var marketing_before_staff := CompanyManager.get_awareness_bonus()
	var support_before_staff := CompanyManager.get_support_modifier()
	var production_before_staff := CompanyManager.get_production_execution_modifier()
	var production_cost_before_staff := CompanyManager.get_production_cost_modifier()
	var finance_interest_before_staff := CompanyManager.get_finance_interest_modifier()
	PersonnelManager._add_employee("Prod Test", "Responsable production", "Production", 72, 7.0, "manufacturing", 68, 5000)
	PersonnelManager._add_employee("Marketing Test", "Responsable marketing", "Marketing", 70, 6.0, "marketing", 68, 4800)
	PersonnelManager._add_employee("Support Test", "Responsable support", "Support", 70, 6.0, "support", 68, 4500)
	PersonnelManager._add_employee("Finance Test", "Responsable finance", "Finance", 72, 7.0, "finance", 70, 5200)
	if CompanyManager.get_production_execution_modifier() <= production_before_staff:
		_fail("Hiring Production staff did not improve production execution")
		return
	if CompanyManager.get_production_cost_modifier() >= production_cost_before_staff:
		_fail("Hiring Production staff did not reduce production cost overhead")
		return
	if CompanyManager.get_awareness_bonus() <= marketing_before_staff:
		_fail("Hiring Marketing staff did not improve campaign awareness")
		return
	if CompanyManager.get_support_modifier() <= support_before_staff:
		_fail("Hiring Support staff did not improve support effectiveness")
		return
	if CompanyManager.get_finance_interest_modifier() >= finance_interest_before_staff:
		_fail("Hiring Finance staff did not reduce the debt interest modifier")
		return
	Economy.reset(500_000)
	Economy.debt = 500_000
	var expected_interest := Economy.projected_monthly_interest()
	if expected_interest <= 0:
		_fail("Finance interest projection returned an invalid amount")
		return
	Economy.process_financing_month()
	if Economy.monthly_expenses != expected_interest:
		_fail("Monthly financing cost did not use the effective Finance-adjusted rate")
		return
	Economy.reset(500_000)
	PersonnelManager.load_state(founder_personnel_state)
	if Economy.money != 500_000:
		_fail("Unexpected starting money: %s" % Economy.money)
		return

	var discovery_economy_state := Economy.get_state().duplicate(true)
	var discovery_research_state := ResearchManager.get_state().duplicate(true)
	var discovery_manager_state := DiscoveryManager.get_state().duplicate(true)
	var reusable_technology_state := TechnologyManager.get_state().duplicate(true)
	TechnologyManager.reset()
	DiscoveryManager.reset()
	var fake_discovery_project := {"id":"PRJ-DISCOVERY-TEST", "sector":"CPU"}
	var fake_discovery_report := {"phase":"Prototype", "weakness":"efficiency"}
	DiscoveryManager._on_phase_report(fake_discovery_project, fake_discovery_report)
	DiscoveryManager._on_phase_report(fake_discovery_project, fake_discovery_report)
	if DiscoveryManager.pending.size() != 1:
		_fail("Prototype discovery trigger was not one-shot")
		return
	var first_discovery := DiscoveryManager.get_pending_discovery()
	if str(first_discovery.get("template_id", "")) != "POWER_MANAGEMENT":
		_fail("Efficiency weakness did not create the expected power-management discovery")
		return
	var cpu_tech_before_exploit := float(ResearchManager.technologies.get("cpu", 0.0))
	var money_before_discovery := Economy.money
	if not DiscoveryManager.resolve_discovery(str(first_discovery.get("id", "")), "EXPLOIT_NOW"):
		_fail("Immediate discovery exploitation failed")
		return
	if Economy.money != money_before_discovery - 4_000:
		_fail("Immediate discovery exploitation cost was not charged")
		return
	if float(ResearchManager.technologies.get("cpu", 0.0)) <= cpu_tech_before_exploit:
		_fail("Immediate discovery exploitation did not improve company know-how")
		return
	if not DiscoveryManager.get_pending_discovery().is_empty():
		_fail("Resolved immediate discovery remained pending")
		return
	if TechnologyManager.has_technology("ADAPTIVE_POWER"):
		_fail("Immediate discovery exploitation incorrectly unlocked a reusable technology")
		return

	var derived_discovery := DiscoveryManager.create_test_discovery("CACHE_POLICY", "DERIVED-TEST")
	if derived_discovery.is_empty():
		_fail("Could not create derived-research discovery")
		return
	var cpu_tech_before_research := float(ResearchManager.technologies.get("cpu", 0.0))
	if not DiscoveryManager.resolve_discovery(str(derived_discovery.get("id", "")), "DERIVED_RESEARCH"):
		_fail("Could not launch derived research")
		return
	if DiscoveryManager.get_active_research().size() != 1:
		_fail("Derived research did not enter the active queue")
		return
	var discovery_round_trip := DiscoveryManager.get_state().duplicate(true)
	DiscoveryManager.load_state(discovery_round_trip)
	if DiscoveryManager.get_active_research().size() != 1:
		_fail("Derived research did not survive state round-trip")
		return
	DiscoveryManager.process_month()
	if DiscoveryManager.get_active_research().is_empty():
		_fail("Two-month derived research completed too early")
		return
	DiscoveryManager.process_month()
	if not DiscoveryManager.get_active_research().is_empty():
		_fail("Derived research did not complete after its expected duration")
		return
	if float(ResearchManager.technologies.get("cpu", 0.0)) <= cpu_tech_before_research:
		_fail("Completed derived research did not improve durable CPU know-how")
		return
	if not TechnologyManager.has_technology("SMART_CACHE"):
		_fail("Completed cache research did not unlock its reusable technology")
		return
	if TechnologyManager.metric_bonus("performance") <= 0.0:
		_fail("Reusable cache technology did not expose a performance bonus")
		return
	var reusable_round_trip := TechnologyManager.get_state().duplicate(true)
	TechnologyManager.reset()
	TechnologyManager.load_state(reusable_round_trip)
	if not TechnologyManager.has_technology("SMART_CACHE"):
		_fail("Reusable technology did not survive state round-trip")
		return
	if TechnologyManager.unlock("SMART_CACHE", "duplicate test"):
		_fail("Reusable technology could be unlocked twice")
		return
	if not TechnologyManager.unlock("FOUNDRY_DRC", "industrial test"):
		_fail("Could not unlock foundry reusable technology")
		return
	if TechnologyManager.industrial_modifier("unit_cost") >= 1.0 or TechnologyManager.industrial_modifier("capacity") <= 1.0:
		_fail("Foundry reusable technology did not improve industrial economics")
		return
	TechnologyManager.load_state(reusable_technology_state)
	DiscoveryManager.load_state(discovery_manager_state)
	ResearchManager.load_state(discovery_research_state)
	Economy.load_state(discovery_economy_state)

	var initial_company_state := CompanyManager.get_state().duplicate(true)
	var previous_awareness := -1.0
	var previous_budget := -1
	for campaign_key in ["NONE", "LOCAL", "NATIONAL", "GLOBAL"]:
		if not CompanyManager.set_marketing_campaign(campaign_key):
			_fail("Could not select marketing campaign %s" % campaign_key)
			return
		var campaign := CompanyManager.get_marketing_campaign()
		var awareness := CompanyManager.get_awareness_bonus()
		var budget := int(campaign.get("budget", -1))
		if awareness <= previous_awareness:
			_fail("Marketing awareness is not increasing between campaign tiers")
			return
		if budget <= previous_budget:
			_fail("Marketing budget is not increasing between campaign tiers")
			return
		previous_awareness = awareness
		previous_budget = budget
	var legacy_company_state := initial_company_state.duplicate(true)
	var legacy_policies: Dictionary = legacy_company_state.get("policies", {}).duplicate(true)
	legacy_policies.erase("marketing_campaign")
	legacy_policies["marketing_budget"] = 34_000
	legacy_company_state["policies"] = legacy_policies
	CompanyManager.load_state(legacy_company_state)
	if str(CompanyManager.policies.get("marketing_campaign", "")) != "NATIONAL":
		_fail("Legacy marketing budget did not migrate to the nearest campaign tier")
		return
	if int(CompanyManager.policies.get("marketing_budget", 0)) != 35_000:
		_fail("Migrated marketing budget was not normalized to the campaign cost")
		return
	CompanyManager.load_state(initial_company_state)

	var previous_support_modifier := -1.0
	var previous_support_budget := -1
	for support_key in ["MINIMAL", "STANDARD", "PREMIUM"]:
		if not CompanyManager.set_support_plan(support_key):
			_fail("Could not select support plan %s" % support_key)
			return
		var support_plan := CompanyManager.get_support_plan()
		var support_modifier := CompanyManager.get_support_modifier()
		var support_budget := int(support_plan.get("budget", -1))
		if support_modifier <= previous_support_modifier:
			_fail("Support effectiveness is not increasing between plan tiers")
			return
		if support_budget <= previous_support_budget:
			_fail("Support budget is not increasing between plan tiers")
			return
		previous_support_modifier = support_modifier
		previous_support_budget = support_budget
	var legacy_support_state := initial_company_state.duplicate(true)
	var legacy_support_policies: Dictionary = legacy_support_state.get("policies", {}).duplicate(true)
	legacy_support_policies.erase("support_level")
	legacy_support_policies["support_budget"] = 17_000
	legacy_support_state["policies"] = legacy_support_policies
	CompanyManager.load_state(legacy_support_state)
	if str(CompanyManager.policies.get("support_level", "")) != "PREMIUM":
		_fail("Legacy support budget did not migrate to the nearest support plan")
		return
	if int(CompanyManager.policies.get("support_budget", 0)) != 18_000:
		_fail("Migrated support budget was not normalized to the support plan cost")
		return
	CompanyManager.load_state(initial_company_state)

	var low_environment_gain := CompanyManager.get_environment_reputation_gain(2_500)
	var max_environment_gain := CompanyManager.get_environment_reputation_gain(CompanyManager.MAX_ENVIRONMENT_BUDGET)
	if max_environment_gain <= low_environment_gain:
		_fail("Environment reputation gain did not increase with spending")
		return
	var legacy_environment_state := initial_company_state.duplicate(true)
	var legacy_environment_policies: Dictionary = legacy_environment_state.get("policies", {}).duplicate(true)
	legacy_environment_policies["environment_budget"] = 200_000
	legacy_environment_state["policies"] = legacy_environment_policies
	CompanyManager.load_state(legacy_environment_state)
	if int(CompanyManager.policies.get("environment_budget", 0)) != CompanyManager.MAX_ENVIRONMENT_BUDGET:
		_fail("Legacy environment budget was not clamped to the useful maximum")
		return
	CompanyManager.load_state(initial_company_state)

	if not SaveManager.autosave_game():
		_fail("Autosave could not write the current game")
		return
	if not FileAccess.file_exists(SaveManager.SAVE_PATH):
		_fail("Autosave file was not created")
		return
	var initial_economy_state := Economy.get_state().duplicate(true)
	if not Economy.request_financing(250_000):
		_fail("Could not obtain initial financing")
		return
	if Economy.debt != 250_000 or Economy.money != 750_000:
		_fail("Financing did not update debt and cash correctly")
		return
	var expected_initial_interest := Economy.projected_monthly_interest()
	Economy.process_financing_month()
	if int(Economy.expense_breakdown.get("Intérêts financement", 0)) != expected_initial_interest:
		_fail("Monthly financing interest did not match the effective Finance-adjusted rate")
		return
	Economy.load_state(initial_economy_state)
	if Economy.debt != 0 or Economy.money != 500_000:
		_fail("Economy financing state did not restore correctly")
		return

	Economy.money = -1_100_000
	Economy.negative_months = 2
	var bankruptcy_report := Economy.close_month()
	if not Economy.bankrupt or str(bankruptcy_report.get("solvency_status", "")) != "BANKRUPT":
		_fail("Durable insolvency did not trigger bankruptcy")
		return
	Economy.load_state(initial_economy_state)
	if Economy.bankrupt:
		_fail("Bankruptcy state did not reset after loading a healthy economy")
		return

	Economy.history = [
		{"result":-80_000, "expense_breakdown":{"R&D":60_000, "Salaires":30_000}, "income_breakdown":{}},
		{"result":-60_000, "expense_breakdown":{"R&D":55_000, "Salaires":30_000}, "income_breakdown":{"Ventes":20_000}},
		{"result":-40_000, "expense_breakdown":{"R&D":50_000, "Salaires":30_000}, "income_breakdown":{"Ventes":35_000}}
	]
	Economy.money = 240_000
	var finance_snapshot := Economy.financial_snapshot()
	if str(finance_snapshot.get("trend", "")) != "IMPROVING":
		_fail("Financial snapshot did not detect improving results")
		return
	if str(finance_snapshot.get("top_expense", {}).get("category", "")) != "R&D":
		_fail("Financial snapshot did not identify the largest expense")
		return
	if float(finance_snapshot.get("runway_months", 0.0)) <= 0.0:
		_fail("Financial snapshot did not expose a positive runway")
		return
	Economy.load_state(initial_economy_state)

	var efficient := CPU_DESIGN.evaluate(CPU_DESIGN.preset("EFFICIENT"))
	var performance := CPU_DESIGN.evaluate(CPU_DESIGN.preset("PERFORMANCE"))
	if float(performance.get("performance", 0.0)) <= float(efficient.get("performance", 0.0)):
		_fail("Performance preset is not faster than efficient preset")
		return
	if int(performance.get("unit_cost", 0)) <= int(efficient.get("unit_cost", 0)):
		_fail("Performance preset must cost more to manufacture")
		return
	if float(efficient.get("efficiency", 0.0)) <= float(performance.get("efficiency", 0.0)):
		_fail("Efficient preset is not more efficient")
		return

	var ipc_base_design := CPU_DESIGN.preset("BALANCED")
	ipc_base_design["ipc_factor"] = 1.0
	ipc_base_design["compatibility_mode"] = "BALANCED"
	var ipc_high_design := ipc_base_design.duplicate(true)
	ipc_high_design["ipc_factor"] = 1.25
	var ipc_base_eval := CPU_DESIGN.evaluate(ipc_base_design)
	var ipc_high_eval := CPU_DESIGN.evaluate(ipc_high_design)
	if float(ipc_high_eval.get("performance", 0.0)) <= float(ipc_base_eval.get("performance", 0.0)):
		_fail("Higher IPC did not improve CPU performance")
		return
	if float(ipc_high_eval.get("complexity", 0.0)) <= float(ipc_base_eval.get("complexity", 0.0)):
		_fail("Higher IPC did not increase CPU complexity")
		return
	if int(ipc_high_eval.get("unit_cost", 0)) <= int(ipc_base_eval.get("unit_cost", 0)):
		_fail("Higher IPC did not increase CPU manufacturing cost")
		return

	var preserve_design := ipc_base_design.duplicate(true)
	preserve_design["compatibility_mode"] = "PRESERVE"
	var break_design := ipc_base_design.duplicate(true)
	break_design["compatibility_mode"] = "BREAK"
	var preserve_eval := CPU_DESIGN.evaluate(preserve_design)
	var break_eval := CPU_DESIGN.evaluate(break_design)
	var design_support_metrics := {
		"performance":70.0,
		"efficiency":70.0,
		"reliability":70.0,
		"innovation":70.0,
		"sustainability":70.0
	}
	var preserve_support := CPU_SUPPORT.initial_state(design_support_metrics, preserve_design)
	var break_support := CPU_SUPPORT.initial_state(design_support_metrics, break_design)
	if float(preserve_support.get("compatibility", 0.0)) <= float(break_support.get("compatibility", 0.0)):
		_fail("Preserving the platform did not improve initial compatibility")
		return
	if float(break_eval.get("innovation", 0.0)) <= float(preserve_eval.get("innovation", 0.0)):
		_fail("Breaking platform compatibility did not create an innovation upside")
		return

	var proposals := ResearchManager.prepare_cpu_generation_proposals("MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000, CPU_DESIGN.preset("BALANCED"))
	if proposals.size() != 3:
		_fail("CPU generation council did not return three plans")
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

	var cpu_design: Dictionary = selected_plan.get("design", {})
	var started: bool = ResearchManager.start_project("CI CPU", "CPU", "MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000, cpu_design, selected_plan)
	if not started:
		_fail("Could not start R&D project")
		return
	var project: Dictionary = ResearchManager.projects[0]
	if int(project.get("cpu_design", {}).get("cores", 0)) != int(cpu_design.get("cores", -1)):
		_fail("Selected generation design was not stored on the R&D project")
		return
	if str(project.get("generation_plan", {}).get("id", "")) != str(selected_plan.get("id", "")):
		_fail("Generation plan was not attached to the R&D project")
		return
	if not ResearchManager.get_cpu_generation_proposals().is_empty():
		_fail("Generation proposals were not cleared after project launch")
		return
	if float(project.get("complexity", 0.0)) <= float(efficient.get("complexity", 0.0)):
		_fail("Complex CPU design did not increase development complexity")
		return

	var report: Dictionary = SimulationManager.process_month_end()
	if report.is_empty():
		_fail("Monthly report is empty")
		return
	if int(report.get("money", -1)) != Economy.money:
		_fail("Monthly report balance does not match economy")
		return

	var decision_guard := 0
	while ResearchManager.get_pending_phase_decision().is_empty() and decision_guard < 5:
		SimulationManager.process_month_end()
		decision_guard += 1
	var pending_decision := ResearchManager.get_pending_phase_decision()
	if pending_decision.is_empty():
		_fail("R&D phase did not create a player decision")
		return
	var blocked_phase := int(project.get("phase_index", -1))
	var blocked_progress := float(project.get("phase_progress", -1.0))
	SimulationManager.process_month_end()
	if int(project.get("phase_index", -1)) != blocked_phase or not is_equal_approx(float(project.get("phase_progress", -1.0)), blocked_progress):
		_fail("R&D project advanced while a phase decision was pending")
		return
	var choices: Array = pending_decision.get("choices", [])
	if choices.size() != 3:
		_fail("R&D decision must expose exactly three choices")
		return
	if not ResearchManager.resolve_phase_decision(str(pending_decision.get("project_id", "")), str(choices[1].get("id", ""))):
		_fail("Could not resolve R&D phase decision")
		return
	if not ResearchManager.get_pending_phase_decision().is_empty():
		_fail("Resolved R&D decision remained pending")
		return
	if int(project.get("phase_index", -1)) != blocked_phase + 1:
		_fail("Resolving an R&D decision did not advance to the next phase")
		return

	var range_project := project.duplicate(true)
	var completed_metrics := {}
	var completed_evaluation := CPU_DESIGN.evaluate(cpu_design)
	for metric in GameData.METRICS:
		completed_metrics[metric] = float(completed_evaluation.get(metric, 62.0))
	range_project["final_metrics"] = completed_metrics
	range_project["status"] = "COMPLETED"
	ProductManager._on_project_completed(range_project)
	if ProductManager.cpu_generations.size() != 1 or ProductManager.products.size() != 3:
		_fail("A completed CPU architecture did not create one generation with three launch models")
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
	if float(apex_model.get("metrics", {}).get("performance", 0.0)) <= float(essential_model.get("metrics", {}).get("performance", 0.0)):
		_fail("Apex model must outperform the Essential model")
		return
	if int(apex_model.get("unit_cost", 0)) <= int(essential_model.get("unit_cost", 0)):
		_fail("Apex bin must cost more than the Essential bin")
		return
	if int(apex_model.get("cpu_design", {}).get("cores", 0)) <= int(essential_model.get("cpu_design", {}).get("cores", 0)):
		_fail("Product binning did not create distinct CPU configurations")
		return
	var bin_total := 0.0
	for bin_product in ProductManager.products:
		bin_total += float(bin_product.get("bin_share", 0.0))
	if absf(bin_total - 1.0) > 0.001:
		_fail("CPU bin allocation does not total 100 percent")
		return
	if float(cpu_generation.get("yield_rate", 0.0)) < 0.46 or float(cpu_generation.get("yield_rate", 0.0)) > 0.92:
		_fail("CPU generation yield escaped its supported range")
		return

	var portfolio_demand := MarketManager.estimate_portfolio_demand(ProductManager.products)
	var portfolio_units := 0
	for demand_product in ProductManager.products:
		portfolio_units += int(portfolio_demand.get(str(demand_product.id), {}).get("units", 0))
	if portfolio_demand.size() != 3 or portfolio_units > int(GameData.SECTORS.CPU.market_units):
		_fail("Portfolio demand did not cap the CPU family to the available market")
		return

	var apex_recommended_capacity := int(apex_model.get("recommended_capacity", 1))
	var apex_max_capacity := int(apex_model.get("max_monthly_capacity", 1))
	var recommended_financials := ProductManager.launch_financials(str(apex_model.id), apex_recommended_capacity)
	var max_financials := ProductManager.launch_financials(str(apex_model.id), apex_max_capacity)

	var flexible_choices := {"contract":"FLEXIBLE","packaging":"STANDARD","testing":"ECONOMY"}
	var partner_choices := {"contract":"PARTNER","packaging":"STANDARD","testing":"BALANCED"}
	var quality_choices := {"contract":"PARTNER","packaging":"PREMIUM","testing":"INTENSIVE"}
	var flexible_financials := ProductManager.launch_financials(str(apex_model.id), apex_recommended_capacity, flexible_choices)
	var quality_financials := ProductManager.launch_financials(str(apex_model.id), apex_recommended_capacity, quality_choices)
	if int(flexible_financials.get("investment", 0)) >= int(recommended_financials.get("investment", 0)):
		_fail("Flexible industrial contract did not reduce launch investment")
		return
	if int(quality_financials.get("investment", 0)) <= int(recommended_financials.get("investment", 0)):
		_fail("Premium industrial strategy did not increase launch investment")
		return
	var default_industrial_forecast := ProductManager.launch_forecast(str(apex_model.id), int(apex_model.price), apex_recommended_capacity)
	var flexible_industrial_forecast := ProductManager.launch_forecast(str(apex_model.id), int(apex_model.price), apex_recommended_capacity, flexible_choices)
	var quality_industrial_forecast := ProductManager.launch_forecast(str(apex_model.id), int(apex_model.price), apex_recommended_capacity, quality_choices)
	var partner_industrial_forecast := ProductManager.launch_forecast(str(apex_model.id), int(apex_model.price), apex_recommended_capacity, partner_choices)
	if float(flexible_industrial_forecast.get("return_rate", 0.0)) <= float(default_industrial_forecast.get("return_rate", 0.0)):
		_fail("Economy industrial testing did not increase return risk")
		return
	if float(quality_industrial_forecast.get("return_rate", 1.0)) >= float(default_industrial_forecast.get("return_rate", 0.0)):
		_fail("Premium packaging and intensive testing did not reduce return risk")
		return
	if int(partner_industrial_forecast.get("effective_unit_cost", 0)) >= int(default_industrial_forecast.get("effective_unit_cost", 0)):
		_fail("Foundry partnership did not reduce effective unit production cost")
		return

	apex_model["stock_policy"] = "LEAN"
	var lean_stock_forecast := ProductManager.launch_forecast(str(apex_model.id), int(apex_model.price), apex_recommended_capacity)
	apex_model["stock_policy"] = "SECURE"
	var secure_stock_forecast := ProductManager.launch_forecast(str(apex_model.id), int(apex_model.price), apex_recommended_capacity)
	if int(secure_stock_forecast.get("inventory_target", 0)) <= int(lean_stock_forecast.get("inventory_target", 0)):
		_fail("Secure stock policy did not target more inventory than lean policy")
		return
	apex_model["stock_policy"] = "BALANCED"

	var stock_economy_state := Economy.get_state().duplicate(true)
	var stock_company_state := CompanyManager.get_state().duplicate(true)
	var stock_metrics: Dictionary = apex_model.get("metrics", {}).duplicate(true)
	stock_metrics["reliability"] = 98.0
	var inventory_product := {
		"id":"STOCK-TEST-INVENTORY",
		"name":"Stock Test Inventory",
		"sector":"CPU",
		"company":CompanyManager.company_name,
		"status":"LAUNCHED",
		"target_segment":"MAINSTREAM",
		"price":300,
		"unit_cost":100,
		"production_capacity":100,
		"monthly_capacity_overhead":0,
		"industrialization":INDUSTRIALIZATION.default_choices(),
		"stock_policy":"SECURE",
		"inventory_units":0,
		"last_month_produced":0,
		"last_month_lost_sales":0,
		"last_month_sales":0,
		"units_sold_total":0,
		"months_on_market":0,
		"last_month_score":0.0,
		"last_month_share":0.0,
		"last_month_returns":0,
		"customer_satisfaction":60.0,
		"pending_quality_incident":{},
		"quality_incident_cooldown":0,
		"renewal_alerted":false,
		"metrics":stock_metrics,
		"cpu_design":apex_model.get("cpu_design", {}).duplicate(true)
	}
	ProductManager._reviewed_products["STOCK-TEST-INVENTORY"] = true
	ProductManager._sell_product_month(inventory_product, {"units":20,"score":70.0,"share":0.05,"expectation_gap":0.0})
	if int(inventory_product.get("last_month_produced", 0)) <= int(inventory_product.get("last_month_sales", 0)):
		_fail("Secure stock policy did not build inventory above current sales")
		return
	if int(inventory_product.get("inventory_units", 0)) <= 0:
		_fail("Unsold production was not retained as inventory")
		return
	if int(Economy.expense_breakdown.get("Stockage — Stock Test Inventory", 0)) <= 0:
		_fail("Stored inventory did not generate holding cost")
		return

	var rupture_product: Dictionary = inventory_product.duplicate(true)
	rupture_product["id"] = "STOCK-TEST-RUPTURE"
	rupture_product["name"] = "Stock Test Rupture"
	rupture_product["stock_policy"] = "LEAN"
	rupture_product["production_capacity"] = 10
	rupture_product["inventory_units"] = 0
	rupture_product["last_month_lost_sales"] = 0
	rupture_product["months_on_market"] = 0
	ProductManager._reviewed_products["STOCK-TEST-RUPTURE"] = true
	ProductManager._sell_product_month(rupture_product, {"units":100,"score":70.0,"share":0.05,"expectation_gap":0.0})
	if int(rupture_product.get("last_month_lost_sales", 0)) <= 0:
		_fail("Insufficient production capacity did not create lost sales")
		return
	if int(rupture_product.get("inventory_units", 0)) != 0:
		_fail("Stockout test unexpectedly ended with inventory")
		return
	ProductManager._reviewed_products.erase("STOCK-TEST-INVENTORY")
	ProductManager._reviewed_products.erase("STOCK-TEST-RUPTURE")
	Economy.load_state(stock_economy_state)
	CompanyManager.load_state(stock_company_state)

	var low_price := maxi(int(apex_model.get("unit_cost", 1)) + 5, int(float(apex_model.price) * 0.75))
	var high_price := maxi(low_price + 10, int(float(apex_model.price) * 1.45))
	var low_price_forecast := ProductManager.launch_forecast(str(apex_model.id), low_price, apex_recommended_capacity)
	var high_price_forecast := ProductManager.launch_forecast(str(apex_model.id), high_price, apex_recommended_capacity)
	if low_price_forecast.is_empty() or high_price_forecast.is_empty():
		_fail("Launch forecast was not generated")
		return
	var low_requested := int(low_price_forecast.get("requested_units", 0))
	var high_requested := int(high_price_forecast.get("requested_units", 0))
	if low_requested <= high_requested:
		_fail("Higher launch price did not reduce requested consumer demand")
		return
	if high_requested > int(round(float(low_requested) * 0.90)):
		_fail("Price elasticity is too weak to create a meaningful volume tradeoff")
		return
	if float(low_price_forecast.get("utilization", -1.0)) < 0.0 or float(low_price_forecast.get("utilization", 2.0)) > 1.0:
		_fail("Launch forecast utilization escaped the supported range")
		return
	if not low_price_forecast.has("monthly_result") or not low_price_forecast.has("investment"):
		_fail("Launch forecast omitted economic outputs")
		return
	if int(max_financials.get("investment", 0)) <= int(recommended_financials.get("investment", 0)):
		_fail("Higher production capacity did not increase industrialization investment")
		return
	if int(max_financials.get("monthly_overhead", 0)) <= int(recommended_financials.get("monthly_overhead", 0)):
		_fail("Higher production capacity did not increase monthly fixed overhead")
		return
	var cash_before_launch := Economy.money
	Economy.money = int(max_financials.get("investment", 0)) - 1
	if ProductManager.launch_product(str(apex_model.id), int(apex_model.price), apex_max_capacity):
		_fail("CPU launch succeeded without enough cash for industrialization")
		return
	Economy.money = cash_before_launch
	if not ProductManager.launch_product(str(apex_model.id), int(apex_model.price), apex_max_capacity + 9999):
		_fail("Could not launch an available CPU family model")
		return
	if int(apex_model.production_capacity) != apex_max_capacity:
		_fail("CPU launch ignored the binning capacity limit")
		return
	if int(apex_model.get("launch_investment", 0)) != int(max_financials.get("investment", 0)):
		_fail("CPU launch did not store the industrialization investment")
		return
	if int(apex_model.get("monthly_capacity_overhead", 0)) != int(max_financials.get("monthly_overhead", 0)):
		_fail("CPU launch did not store the monthly capacity overhead")
		return
	if Economy.money != cash_before_launch - int(max_financials.get("investment", 0)):
		_fail("CPU launch did not charge the industrialization investment")
		return
	var stored_industrialization: Dictionary = apex_model.get("industrialization", {})
	if str(stored_industrialization.get("contract", "")) != "RESERVED" or str(stored_industrialization.get("testing", "")) != "BALANCED":
		_fail("Default industrialization strategy was not stored on launch")
		return

	var economy_before_offer_update := Economy.get_state().duplicate(true)
	var original_price := int(apex_model.get("price", 1))
	var original_overhead := int(apex_model.get("monthly_capacity_overhead", 0))
	var money_before_reduction := Economy.money
	if not ProductManager.update_product_offer(str(apex_model.id), original_price + 10, apex_recommended_capacity):
		_fail("Could not reduce production capacity after launch")
		return
	if int(apex_model.get("production_capacity", 0)) != apex_recommended_capacity:
		_fail("Post-launch capacity reduction was not applied")
		return
	if int(apex_model.get("price", 0)) != original_price + 10:
		_fail("Post-launch price change was not applied")
		return
	if Economy.money != money_before_reduction:
		_fail("Reducing production capacity incorrectly refunded or charged cash")
		return
	if int(apex_model.get("monthly_capacity_overhead", 0)) >= original_overhead:
		_fail("Reducing production capacity did not lower fixed overhead")
		return

	var reexpansion := ProductManager.offer_update_financials(str(apex_model.id), apex_max_capacity)
	var reexpansion_cost := int(reexpansion.get("expansion_cost", 0))
	if reexpansion_cost <= 0:
		_fail("Re-expanding production capacity did not require investment")
		return
	Economy.money = reexpansion_cost + 1000
	if not ProductManager.update_product_offer(str(apex_model.id), original_price, apex_max_capacity):
		_fail("Could not re-expand production capacity after launch")
		return
	if Economy.money != 1000:
		_fail("Production capacity extension cost was not charged")
		return
	if int(apex_model.get("production_capacity", 0)) != apex_max_capacity:
		_fail("Post-launch capacity expansion was not applied")
		return
	Economy.load_state(economy_before_offer_update)

	var reliability_before_incident := float(apex_model.get("metrics", {}).get("reliability", 50.0))
	var satisfaction_before_incident := float(apex_model.get("customer_satisfaction", 50.0))
	var support_before_incident := float(CompanyManager.reputation.get("support", 50.0))
	ProductManager._maybe_create_quality_incident(apex_model, 200, 30, 0.15, 5_000)
	var quality_incident := ProductManager.get_pending_quality_incident()
	if quality_incident.is_empty() or str(quality_incident.get("product_id", "")) != str(apex_model.id):
		_fail("High return rate did not create a quality incident")
		return
	if ProductManager.quality_incident_options(str(apex_model.id)).size() != 3:
		_fail("Quality incident did not expose three player responses")
		return
	if not ProductManager.resolve_quality_incident(str(apex_model.id), "MINIMAL_SUPPORT"):
		_fail("Minimal support response could not resolve a quality incident")
		return
	if not ProductManager.get_pending_quality_incident().is_empty():
		_fail("Resolved quality incident remained pending")
		return
	if int(apex_model.get("quality_incident_cooldown", 0)) != 6:
		_fail("Quality incident cooldown was not applied")
		return
	if float(apex_model.get("customer_satisfaction", 50.0)) >= satisfaction_before_incident:
		_fail("Minimal support response did not reduce customer satisfaction")
		return
	if float(CompanyManager.reputation.get("support", 50.0)) >= support_before_incident:
		_fail("Minimal support response did not hurt support reputation")
		return
	apex_model.get("metrics", {})["reliability"] = reliability_before_incident
	apex_model["customer_satisfaction"] = satisfaction_before_incident
	CompanyManager.reputation["support"] = support_before_incident

	var support_economy_state := Economy.get_state().duplicate(true)
	var support_company_state := CompanyManager.get_state().duplicate(true)
	var support_metrics: Dictionary = apex_model.get("metrics", {}).duplicate(true)
	var support_state: Dictionary = apex_model.get("cpu_support", {}).duplicate(true)
	var healthy_market_score := MarketManager.evaluate_product(apex_model, str(apex_model.get("target_segment", "MAINSTREAM")))
	apex_model["cpu_support"] = {
		"microcode_quality":48.0,
		"compatibility":50.0,
		"support_debt":8.0,
		"patch_level":0,
		"pending_issue":{},
		"active_fix":{}
	}
	ProductManager._process_cpu_support_month(apex_model)
	var software_issue := ProductManager.get_pending_software_issue()
	if software_issue.is_empty() or str(software_issue.get("product_id", "")) != str(apex_model.id):
		_fail("Software support debt did not create a CPU software incident")
		return
	var degraded_market_score := MarketManager.evaluate_product(apex_model, str(apex_model.get("target_segment", "MAINSTREAM")))
	if degraded_market_score >= healthy_market_score:
		_fail("CPU software incident did not reduce market appeal")
		return
	if ProductManager.software_fix_options(str(apex_model.id)).size() != 3:
		_fail("CPU software incident did not expose three fix strategies")
		return
	var performance_before_hotfix := float(apex_model.get("metrics", {}).get("performance", 0.0))
	var money_before_hotfix := Economy.money
	if not ProductManager.start_software_fix(str(apex_model.id), "HOTFIX"):
		_fail("CPU hotfix could not be started")
		return
	if Economy.money != money_before_hotfix - 8_000:
		_fail("CPU hotfix cost was not charged")
		return
	ProductManager._process_cpu_support_month(apex_model)
	if not ProductManager.get_pending_software_issue().is_empty():
		_fail("Completed hotfix did not clear the software incident")
		return
	var patched_support: Dictionary = apex_model.get("cpu_support", {})
	if int(patched_support.get("patch_level", 0)) != 1:
		_fail("Completed hotfix did not increment patch level")
		return
	if float(apex_model.get("metrics", {}).get("performance", 0.0)) >= performance_before_hotfix:
		_fail("Rapid hotfix did not apply its advertised performance tradeoff")
		return
	if float(patched_support.get("microcode_quality", 0.0)) <= 48.0:
		_fail("Completed hotfix did not improve microcode quality")
		return
	apex_model["cpu_support"] = support_state
	apex_model["metrics"] = support_metrics
	Economy.load_state(support_economy_state)
	CompanyManager.load_state(support_company_state)

	var fresh_demand := MarketManager.estimate_consumer_demand(apex_model)
	if MarketManager.should_renew_product(apex_model):
		_fail("Freshly launched CPU was marked for renewal too early")
		return
	apex_model["months_on_market"] = 24
	var aged_demand := MarketManager.estimate_consumer_demand(apex_model)
	if not MarketManager.should_renew_product(apex_model):
		_fail("A clearly aged CPU was not marked for renewal")
		return
	apex_model["renewal_alerted"] = false
	if not ProductManager._maybe_announce_renewal(apex_model):
		_fail("Aged CPU did not emit its renewal announcement")
		return
	if ProductManager._maybe_announce_renewal(apex_model):
		_fail("CPU renewal announcement was emitted more than once")
		return
	if not bool(apex_model.get("renewal_alerted", false)):
		_fail("CPU renewal announcement was not persisted on the product")
		return
	if float(aged_demand.get("relevance", 1.0)) >= float(fresh_demand.get("relevance", 1.0)):
		_fail("Product relevance did not decay with age")
		return
	if int(aged_demand.get("units", 0)) >= int(fresh_demand.get("units", 0)):
		_fail("Aged product demand did not decline")
		return
	apex_model["months_on_market"] = 0
	apex_model["renewal_alerted"] = false
	var initial_competitor_generation := 1
	for competitor in MarketManager.competitors.get("CPU", []):
		initial_competitor_generation = maxi(initial_competitor_generation, int(competitor.get("generation", 1)))
	for _month in range(20):
		MarketManager.process_month(ProductManager.products)
	var evolved_generation := 1
	for competitor in MarketManager.competitors.get("CPU", []):
		evolved_generation = maxi(evolved_generation, int(competitor.get("generation", 1)))
	if evolved_generation <= initial_competitor_generation:
		_fail("Competitors did not release a new generation")
		return

	var market_state_before_contract_test := MarketManager.get_state().duplicate(true)
	MarketManager.contracts = [
		{"id":"B2B-TEST-A","product_id":str(apex_model.id),"product_name":str(apex_model.name),"customer":"Alpha Systems","units_per_month":120,"unit_price":300,"remaining_months":12,"status":"PENDING"},
		{"id":"B2B-TEST-B","product_id":str(apex_model.id),"product_name":str(apex_model.name),"customer":"Beta Cloud","units_per_month":200,"unit_price":320,"remaining_months":9,"status":"PENDING"}
	]
	if not MarketManager.accept_contract("B2B-TEST-B"):
		_fail("Could not accept the selected B2B contract")
		return
	if str(MarketManager.contracts[0].get("status", "")) != "PENDING":
		_fail("Accepting one B2B contract changed another pending proposal")
		return
	if str(MarketManager.contracts[1].get("status", "")) != "ACTIVE":
		_fail("Selected B2B contract did not become active")
		return
	MarketManager.load_state(market_state_before_contract_test)

	var before_discontinue_products := ProductManager.get_state().duplicate(true)
	var before_discontinue_market := MarketManager.get_state().duplicate(true)
	MarketManager.contracts = [
		{"id":"B2B-BLOCK","product_id":str(apex_model.id),"product_name":str(apex_model.name),"customer":"Locked Client","units_per_month":80,"unit_price":310,"remaining_months":4,"status":"ACTIVE"}
	]
	if ProductManager.discontinuation_blocker(str(apex_model.id)).is_empty():
		_fail("Active B2B contract did not block product discontinuation")
		return
	if ProductManager.discontinue_product(str(apex_model.id)):
		_fail("Product was discontinued despite an active B2B contract")
		return
	MarketManager.contracts[0]["status"] = "COMPLETED"
	if not ProductManager.discontinue_product(str(apex_model.id)):
		_fail("Product could not be discontinued after B2B completion")
		return
	if str(apex_model.get("status", "")) != "DISCONTINUED":
		_fail("Discontinued product did not enter the expected status")
		return
	if int(apex_model.get("monthly_capacity_overhead", -1)) != 0:
		_fail("Discontinued product kept fixed production overhead")
		return
	if ProductManager.update_product_offer(str(apex_model.id), int(apex_model.price), int(apex_model.production_capacity)):
		_fail("Discontinued product still accepted live offer changes")
		return
	ProductManager.load_state(before_discontinue_products)
	MarketManager.load_state(before_discontinue_market)

	var product_round_trip := ProductManager.get_state().duplicate(true)
	ProductManager.reset()
	ProductManager.load_state(product_round_trip)
	if ProductManager.cpu_generations.size() != 1 or ProductManager.products.size() != 3:
		_fail("CPU product family did not survive a save round-trip")
		return
	var legacy_product_state := product_round_trip.duplicate(true)
	legacy_product_state.erase("cpu_generations")
	legacy_product_state.erase("next_generation_id")
	for legacy_product in legacy_product_state.get("products", []):
		legacy_product.erase("generation_id")
		legacy_product.erase("generation_index")
		legacy_product.erase("generation_name")
		legacy_product.erase("industrialization")
		legacy_product.erase("cpu_support")
	ProductManager.load_state(legacy_product_state)
	if ProductManager.cpu_generations.is_empty() or str(ProductManager.products[0].get("generation_id", "")).is_empty():
		_fail("Legacy V5 products were not migrated into a CPU generation")
		return
	var migrated_industrialization: Dictionary = ProductManager.products[0].get("industrialization", {})
	if str(migrated_industrialization.get("contract", "")) != "RESERVED" or str(migrated_industrialization.get("packaging", "")) != "STANDARD" or str(migrated_industrialization.get("testing", "")) != "BALANCED":
		_fail("Legacy product did not migrate to the default industrialization strategy")
		return
	var migrated_design: Dictionary = ProductManager.products[0].get("cpu_design", {})
	if not is_equal_approx(float(migrated_design.get("ipc_factor", 0.0)), 1.0) or str(migrated_design.get("compatibility_mode", "")) != "BALANCED":
		_fail("Legacy CPU design did not migrate to default IPC and compatibility settings")
		return
	var migrated_support: Dictionary = ProductManager.products[0].get("cpu_support", {})
	if migrated_support.is_empty() or not migrated_support.has("microcode_quality") or not migrated_support.has("compatibility"):
		_fail("Legacy CPU did not migrate to a software support state")
		return

	var legacy_state := ResearchManager.get_state().duplicate(true)
	var legacy_projects: Array = legacy_state.get("projects", [])
	var legacy_project: Dictionary = legacy_projects[0]
	legacy_project.erase("cpu_design")
	legacy_project.erase("design_estimate")
	legacy_project.erase("complexity")
	legacy_project.erase("generation_plan")
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

	ResearchManager.prepare_cpu_generation_proposals("PRO", "HYBRID", "RELIABILITY", 50_000, CPU_DESIGN.preset("BALANCED"))
	var research_round_trip := ResearchManager.get_state().duplicate(true)
	ResearchManager.load_state(research_round_trip)
	if ResearchManager.get_cpu_generation_proposals().size() != 3:
		_fail("Generation proposals did not survive a save round-trip")
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

	if not _validate_first_generation_financing():
		return

	print("[CI] Smoke test passed")
	get_tree().quit(0)

func _validate_first_generation_financing() -> bool:
	SimulationManager.reset_all("First Generation Balance", "CPU")
	var proposals := ResearchManager.prepare_cpu_generation_proposals(
		"MAINSTREAM", "INTERNAL", "BALANCED", 42_000, CPU_DESIGN.preset("BALANCED")
	)
	if proposals.size() != 3:
		_fail("Balance test could not prepare CPU generation plans")
		return false
	var selected: Dictionary = proposals[0]
	for proposal_value in proposals:
		var proposal: Dictionary = proposal_value
		if bool(proposal.get("recommended", false)):
			selected = proposal
			break
	var design: Dictionary = selected.get("design", CPU_DESIGN.preset("BALANCED"))
	if not ResearchManager.start_project("First Gen", "CPU", "MAINSTREAM", "INTERNAL", "BALANCED", 42_000, design, selected):
		_fail("Balance test could not start the first CPU generation")
		return false
	var project: Dictionary = ResearchManager.projects[0]
	var elapsed_months := 0
	while str(project.get("status", "")) == "DEVELOPMENT" and elapsed_months < 24:
		var pending := ResearchManager.get_pending_phase_decision()
		if not pending.is_empty():
			if not ResearchManager.resolve_phase_decision(str(pending.get("project_id", "")), "FIX_WEAKNESS"):
				_fail("Balance test could not resolve a phase decision")
				return false
			continue
		SimulationManager.process_month_end()
		elapsed_months += 1
		if Economy.bankrupt:
			_fail("First CPU generation becomes bankrupt before R&D can finish")
			return false
	if str(project.get("status", "")) != "COMPLETED":
		_fail("First CPU generation did not complete within 24 months")
		return false
	if ProductManager.products.size() < 3:
		_fail("First CPU generation did not produce the launch family")
		return false

	var launch_model: Dictionary = ProductManager.products[1]
	var launch_financials := ProductManager.launch_financials(
		str(launch_model.get("id", "")),
		int(launch_model.get("recommended_capacity", launch_model.get("production_capacity", 1)))
	)
	var investment := int(launch_financials.get("investment", 0))
	var financing_steps := 0
	while Economy.money < investment and Economy.debt < Economy.MAX_DEBT and financing_steps < 4:
		if not Economy.request_financing(250_000):
			break
		financing_steps += 1
	if Economy.money < investment:
		_fail("First CPU cannot be industrialized even after available financing")
		return false
	if not ProductManager.launch_product(
		str(launch_model.get("id", "")),
		int(launch_model.get("price", 1)),
		int(launch_model.get("recommended_capacity", 1))
	):
		_fail("First CPU could not be launched after financing")
		return false
	if Economy.bankrupt:
		_fail("First CPU launch path ended in unavoidable bankruptcy")
		return false
	return true

func _fail(message: String) -> void:
	push_error("[CI] " + message)
	get_tree().quit(1)
