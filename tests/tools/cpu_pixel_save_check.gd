extends Node
const COCKPIT := preload("res://ui/ProjectCockpit.gd")

func _ready() -> void:
	SaveManager.writes_enabled = false
	SaveManager.save_root = "res://build/pixel-saves-before/"
	if not SaveManager.load_game():
		push_error("Pixel save could not be loaded")
		get_tree().quit(1)
		return
	var cpu := ResearchManager.active_cpu_project()
	var before := cpu.duplicate(true)
	var state := ResearchManager.rng.state
	var pending := ResearchManager.cpu_pending_directive(cpu)
	var preview := ResearchManager.cpu_prototype_preview(cpu)
	var cockpit := COCKPIT.new()
	add_child(cockpit)
	cockpit.open(str(cpu.id))
	if Economy.money != 16017713 or cpu != before or state != ResearchManager.rng.state or pending.is_empty() or preview.is_empty():
		push_error("Pixel save/preview invariant failed")
		get_tree().quit(1)
		return
	print("[CI] Real Pixel save loaded: 16017713 EUR, 1987-10, bsm 3; preview and cockpit preserve state")
	cockpit.queue_free()
	get_tree().quit(0)
