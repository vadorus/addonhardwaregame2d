extends RefCounted

static func run(host: Node) -> String:
	var lab_script: Script = load("res://ui/screens/LabScreen.gd")
	var lab: Control = lab_script.new() as Control
	host.add_child(lab)
	if str(lab.call("get_depth_mode")) != "ESSENTIAL":
		lab.queue_free()
		return "CPU lab does not start in Essential depth"
	var controls_value = lab.call("get_control_map")
	if typeof(controls_value) != TYPE_DICTIONARY:
		lab.queue_free()
		return "CPU lab did not expose its control map"
	var controls: Dictionary = controls_value
	var cores: Control = controls.get("rd_cores") as Control
	var cache: Control = controls.get("rd_cache") as Control
	var contract: Control = controls.get("rd_contract_term") as Control
	if cores == null or cache == null or contract == null:
		lab.queue_free()
		return "CPU lab depth test is missing expected controls"
	if not cores.get_parent().visible or cache.get_parent().visible or contract.get_parent().visible:
		lab.queue_free()
		return "Essential depth exposes too much CPU complexity"
	lab.call("set_depth_mode", "DETAILED")
	if not cache.get_parent().visible or contract.get_parent().visible:
		lab.queue_free()
		return "Detailed depth did not reveal the intermediate CPU controls correctly"
	lab.call("set_depth_mode", "EXPERT")
	if not contract.get_parent().visible:
		lab.queue_free()
		return "Expert depth did not reveal advanced supplier controls"
	lab.call("set_depth_mode", "ESSENTIAL")
	if cache.get_parent().visible or contract.get_parent().visible:
		lab.queue_free()
		return "Returning to Essential depth did not collapse advanced controls"
	lab.queue_free()
	return ""
