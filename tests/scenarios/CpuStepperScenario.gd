extends RefCounted
## V0.9 — conception en étapes : 5 étapes, réglages ◀ ▶ qui changent le design, lancement réel.

const STEPPER := preload("res://ui/components/CpuDesignStepper.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("Stepper Test", "CPU", "STANDARD")
	if not ResearchManager.start_project("Nova 1", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CPU_DESIGN_DEFAULT()):
		return "V0.9 stepper: could not create the first project for the test"
	var stepper := STEPPER.new() as Control
	host.add_child(stepper)
	stepper.call("open")
	if not stepper.visible or int(stepper.call("step_count")) != 5 or int(stepper.get("step")) != 0:
		stepper.queue_free()
		return "V0.9 stepper: must open on step 1 of 5"
	stepper.call("go_to_step", 1)
	if int(stepper.call("row_count")) != 3:
		stepper.queue_free()
		return "V0.9 stepper: architecture step must show cores, frequency and cache rows"
	var before: Dictionary = stepper.call("current_design")
	stepper.call("_shift_core", 1)
	stepper.call("_shift_freq", 1)
	var after: Dictionary = stepper.call("current_design")
	if int(after.get("cores", 0)) <= int(before.get("cores", 0)) or float(after.get("frequency_ghz", 0.0)) <= float(before.get("frequency_ghz", 0.0)):
		stepper.queue_free()
		return "V0.9 stepper: ◀ ▶ controls do not change the design"
	stepper.call("go_to_step", 2)
	if int(stepper.call("row_count")) != 2:
		stepper.queue_free()
		return "V0.9 stepper: process step must show node and power rows"
	stepper.call("go_to_step", 4)
	var spec: Dictionary = stepper.call("current_spec")
	var count := ResearchManager.projects.size()
	var design := CpuDesignModel.normalize(spec.get("design", {}))
	if not ResearchManager.start_project(str(spec.name), "CPU", str(spec.segment), "INTERNAL", str(spec.focus), int(spec.budget), design, {}, {}, str(spec.application)):
		stepper.queue_free()
		return "V0.9 stepper: the default spec from the stepper cannot start a real project"
	if ResearchManager.projects.size() != count + 1:
		stepper.queue_free()
		return "V0.9 stepper: launching did not add a project"
	stepper.queue_free()
	return ""

static func CPU_DESIGN_DEFAULT() -> Dictionary:
	return CpuDesignModel.default_design()
