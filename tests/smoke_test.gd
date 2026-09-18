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
	Economy.process_financing_month()
	if int(Economy.expense_breakdown.get("Intérêts financement", 0)) != 3000:
		_fail("Monthly financing interest was not charged")
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
	var fresh_demand := MarketManager.estimate_consumer_demand(apex_model)
	apex_model["months_on_market"] = 24
	var aged_demand := MarketManager.estimate_consumer_demand(apex_model)
	if float(aged_demand.get("relevance", 1.0)) >= float(fresh_demand.get("relevance", 1.0)):
		_fail("Product relevance did not decay with age")
		return
	if int(aged_demand.get("units", 0)) >= int(fresh_demand.get("units", 0)):
		_fail("Aged product demand did not decline")
		return
	apex_model["months_on_market"] = 0
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
	ProductManager.load_state(legacy_product_state)
	if ProductManager.cpu_generations.is_empty() or str(ProductManager.products[0].get("generation_id", "")).is_empty():
		_fail("Legacy V5 products were not migrated into a CPU generation")
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
