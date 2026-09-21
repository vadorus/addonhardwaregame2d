extends Node

func _ready() -> void:
	print("[CI] Tech Empire economy test starting")
	SimulationManager.reset_all("CI Economy", "CPU", "STANDARD")

	var starting_money := Economy.money
	var lowest_money := Economy.money

	for month_index in range(1, 25):
		# Les décisions passent par les API de gameplay. Aucun argent n'est injecté
		# et aucun manager mensuel n'est appelé directement.
		if StartupManager.stage == StartupManager.STAGE_FIRST_HIRE and not StartupManager.first_engineer_hired:
			if StartupManager.can_hire_first_engineer():
				StartupManager.hire_first_engineer()

		if StartupManager.stage == StartupManager.STAGE_ELECTRONICS and StartupManager.first_engineer_hired and StartupManager.electronics_project.is_empty():
			if StartupManager.can_start_electronics_project():
				StartupManager.start_electronics_project()

		if StartupManager.active_contract.is_empty():
			var selected_contract := _best_affordable_contract()
			if selected_contract != "":
				StartupManager.start_software_contract(selected_contract)

		var report := SimulationManager.process_month_end()
		lowest_money = mini(lowest_money, Economy.money)
		print("[CI] Economy month %02d • cash=%d • contracts=%d • stage=%s" % [
			month_index,
			Economy.money,
			StartupManager.software_contracts_completed,
			StartupManager.stage
		])

		if SimulationManager.is_game_over or Economy.money <= 0:
			_fail("Economy became insolvent in month %d with %d cash." % [month_index, Economy.money])
			return
		if int(report.get("money", Economy.money)) != Economy.money:
			_fail("Monthly report cash diverged from Economy.money in month %d." % month_index)
			return

	if StartupManager.software_contracts_completed < 6:
		_fail("24-month economy line delivered only %d software contracts." % StartupManager.software_contracts_completed)
		return
	if not StartupManager.first_engineer_hired:
		_fail("24-month economy line never reached the first hire.")
		return
	if not StartupManager.cpu_program_unlocked:
		_fail("24-month economy line never unlocked the CPU program.")
		return

	print("[CI] Economy test passed • start=%d • low=%d • end=%d • contracts=%d" % [
		starting_money,
		lowest_money,
		Economy.money,
		StartupManager.software_contracts_completed
	])
	get_tree().quit(0)

func _best_affordable_contract() -> String:
	var best_id := ""
	var best_monthly_value := -1.0
	for contract_id_value in StartupManager.available_contract_ids():
		var contract_id := str(contract_id_value)
		if not StartupManager.can_start_software_contract(contract_id):
			continue
		var data := StartupManager.contract_data(contract_id)
		var duration := maxf(float(data.get("duration_months", 1)), 1.0)
		var monthly_cost := float(data.get("monthly_cost", 0))
		var reward := float(data.get("reward", 0))
		var monthly_value := reward / duration - monthly_cost
		if monthly_value > best_monthly_value:
			best_monthly_value = monthly_value
			best_id = contract_id
	return best_id

func _fail(message: String) -> void:
	push_error("[CI] " + message)
	get_tree().quit(1)
