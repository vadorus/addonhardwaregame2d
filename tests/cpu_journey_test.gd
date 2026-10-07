extends Node
const MODEL := preload("res://scripts/CpuJourneyModel.gd")
const JOURNEY := preload("res://ui/CpuJourney.gd")
const MATRIX := preload("res://tests/scenarios/GarageEconomyMatrixScenario.gd")
const DESIGN := preload("res://scripts/CpuDesign.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	SimulationManager.reset_all("Journey test", "CPU", "STANDARD")
	check(ResearchManager.start_project("Journey CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "EFFICIENCY", 35000, DESIGN.preset("EFFICIENT"), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true), "start failed")
	var id := MODEL.default_project_id()
	var saved := ResearchManager.get_state().duplicate(true)
	var random := ResearchManager.rng.state
	var state := MODEL.snapshot(id)
	check(str(state.get("stage", "")) == "DEVELOPMENT", "development stage missing")
	check(not state.get("directive", {}).is_empty(), "phase decision missing")
	check(ResearchManager.get_state() == saved and ResearchManager.rng.state == random, "view changed simulation")
	var screen := JOURNEY.new()
	add_child(screen)
	screen.open(id)
	await get_tree().process_frame
	screen._preview_option(state.directive.options[0], false)
	check(ResearchManager.get_state() == saved, "choice preview changed simulation")
	var case: Dictionary = MATRIX.CASES[1].duplicate(true)
	case["interactive"] = true
	check(MATRIX._run_case(case) == "", "full development/production scenario failed")
	id = MODEL.default_project_id()
	state = MODEL.snapshot(id)
	check(str(state.get("stage", "")) == "LAUNCH", "completed CPU did not transition to launch")
	screen.open(id)
	await get_tree().process_frame
	var product: Dictionary = state.product
	check(ProductManager.launch_product(str(product.id), int(product.price), mini(100, int(product.production_capacity))), "launch failed")
	state = MODEL.snapshot(id, str(product.id))
	check(str(state.stage) == "MARKET", "launched model did not transition to market")
	screen.refresh()
	await get_tree().process_frame
	SimulationManager.process_month_end()
	screen.refresh()
	check(int(ProductManager.get_product(str(product.id)).get("months_on_market", 0)) > 0, "no commercial month")
	screen._benchmarks = true
	screen.refresh()
	await get_tree().process_frame
	screen.queue_free()
	if failures.is_empty(): print("[CI] CPU journey passed: development, pure previews, real production, launch, commercial month, benchmark UI")
	else:
		for failure in failures: push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
