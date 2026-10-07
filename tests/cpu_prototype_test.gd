extends Node

const DESIGN := preload("res://scripts/CpuDesign.gd")
const MODEL := preload("res://scripts/CpuPrototypeModel.gd")
const CATALOG := preload("res://scripts/ProjectDirectiveCatalog.gd")
const COCKPIT := preload("res://ui/ProjectCockpit.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _ready() -> void:
	SimulationManager.reset_all("CPU prototype CI", "CPU", "STANDARD")
	Economy.money = 1000000
	var design := DESIGN.default_design()
	design["frequency_ghz"] = 0.003
	design["tdp_w"] = 1
	check(ResearchManager.start_project("Voltage test", "CPU", MarketManager.default_segment(),
		"INTERNAL", "BALANCED", 35000, design, {}, {}, "GENERAL", "", "BALANCED",
		"STANDARD", "NONE", "SHARED", "NONE", true), "project failed to start")
	var project := ResearchManager.active_cpu_project()
	var id := str(project.id)
	check(ResearchManager.resolve_cpu_directive(id, "BALANCED"), "concept choice failed")
	project["phase_index"] = 2
	# This also checks migration of a decision stored by the previous release.
	project["cockpit_directive_pending"] = CATALOG.cpu_milestone(2)
	var pending := ResearchManager.cpu_pending_directive(project)
	check(str((pending.get("situation", {}) as Dictionary).get("id", "")) == "POWER", "electric deficit was not diagnosed")
	var reduce := CATALOG.option_for(pending, "EFFICIENT")
	var redesign := CATALOG.option_for(pending, "ROBUST")
	var before_state := project.duplicate(true)
	var rng_before := ResearchManager.rng.state
	var before := ResearchManager.cpu_prototype_preview(project)
	var lowered := ResearchManager.cpu_prototype_preview(project, reduce)
	var repaired := ResearchManager.cpu_prototype_preview(project, redesign)
	check(ResearchManager.rng.state == rng_before, "preview consumed gameplay RNG")
	check(project == before_state, "preview mutated the live project")
	check(float(lowered.required_tdp) < float(before.required_tdp), "frequency reduction did not reduce electric need")
	check(float(repaired.power_deficit_ratio) == 0.0, "redesign did not fix electric deficit")
	check(float(repaired.frequency_ghz) == float(before.frequency_ghz), "redesign silently reduced frequency")
	check(int(redesign.cost_once) >= 2500 and int(redesign.delay_months) == 2, "redesign has no meaningful cost and delay")
	var cash_before := Economy.money
	check(ResearchManager.resolve_cpu_directive(id, "EFFICIENT"), "frequency choice failed")
	check(float(project.cpu_design.frequency_ghz) < float(before.frequency_ghz), "choice did not modify actual design")
	check(Economy.money == cash_before, "free fallback charged money")
	var after := ResearchManager.cpu_prototype_preview(project)
	check(after.metrics == lowered.metrics, "resolved metrics disagree with the preview")
	check(str(project.cockpit_last_outcome).contains("→"), "before/after consequence is missing")
	check(not ResearchManager.resolve_cpu_directive(id, "EFFICIENT"), "choice could be applied twice")
	var saved := ResearchManager.get_state().duplicate(true)
	ResearchManager.reset("CPU")
	ResearchManager.load_state(saved)
	project = ResearchManager.active_cpu_project()
	check(project.cpu_design == after.design, "design change was lost on save/load")
	project["phase_index"] = 4
	project["cockpit_directive_pending"] = MODEL.milestone(project, 4)
	var paid: Dictionary = project.cockpit_directive_pending.options[2]
	Economy.money = 0
	var failed_state := project.duplicate(true)
	check(not ResearchManager.resolve_cpu_directive(id, str(paid.id)), "unaffordable choice succeeded")
	check(project == failed_state, "unaffordable choice partially applied")
	Economy.money = 1000000
	var preview_paid := ResearchManager.cpu_prototype_preview(project, paid)
	check(ResearchManager.resolve_cpu_directive(id, str(paid.id)), "paid choice failed")
	check(ResearchManager.cpu_prototype_preview(project).metrics == preview_paid.metrics, "paid choice disagrees with preview")
	check(int(project.decision_delay_months_remaining) == int(paid.delay_months), "delay was not scheduled")
	var progress := float(project.phase_progress)
	ResearchManager.process_month()
	check(float(project.phase_progress) == progress, "project progressed during correction delay")
	check(int(project.decision_delay_months_remaining) == int(paid.delay_months) - 1, "delay did not tick down")
	var cockpit := COCKPIT.new()
	add_child(cockpit)
	cockpit.open(id)
	check(cockpit.visible, "cockpit failed to open")
	cockpit.queue_free()
	if failures.is_empty():
		print("[CI] CPU prototype test passed")
	else:
		for failure in failures: push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
