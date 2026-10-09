extends Node
## T2 : les vrais écrans, simulés en paysage, avec le mode tactile forcé en headless.
const UI := preload("res://ui/UiKit.gd")
const LIVE := preload("res://scripts/LiveTheme.gd")
var failures: Array[String] = []

func fail(message: String) -> void:
	failures.append(message)

func visit(node: Node, found: Array[Control]) -> void:
	for child in node.get_children():
		if child is BaseButton or child is HSlider or child is VSlider or child is SpinBox or child is LineEdit:
			found.append(child as Control)
		visit(child, found)

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	LIVE.override = "NONE"
	var desktop := Button.new()
	desktop.custom_minimum_size = Vector2(25, 25)
	UI.touch_target(desktop)
	if not OS.has_feature("mobile") and desktop.custom_minimum_size != Vector2(25, 25):
		fail("T2 must not enlarge controls on desktop")
	UI.touch_target(desktop, "secondary", true)
	if desktop.custom_minimum_size.x < 58 or desktop.custom_minimum_size.y < 58:
		fail("Secondary minimum must be 58 in both directions")
	var primary := Button.new()
	primary.text = "Confirmer"
	UI.touch_target(primary, UI.touch_kind(primary), true)
	if primary.custom_minimum_size.y < 77:
		fail("Primary minimum must be 77")
	for dimensions in [Vector2i(1280, 720), Vector2i(1600, 720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		add_child(viewport)
		CompanyManager.created = false
		var game := (load("res://main.tscn") as PackedScene).instantiate() as Control
		game.set_meta("_t2_test_mobile", true)
		viewport.add_child(game)
		game.call("_start_new_game")
		game.call("_update_responsive_layout")
		(game.get("setup_layer") as Control).hide()
		for frame in range(9):
			await get_tree().process_frame
		# Un changement d'état ne doit pas pouvoir rétrécir les commandes.
		var speed: Button = (game.get("speed_buttons") as Array)[0] as Button
		speed.custom_minimum_size = Vector2(20, 20)
		for frame in range(3):
			await get_tree().process_frame
		if speed.custom_minimum_size.x < 58 or speed.custom_minimum_size.y < 58:
			fail("Mobile speed button shrunk after its initial setup")
		var controls: Array[Control] = []
		var scanned: Dictionary = {}
		var too_small: Array[String] = []
		var tabs: TabContainer = game.get("tabs")
		for tab_index in range(7):
			tabs.current_tab = tab_index
			for frame in range(3):
				await get_tree().process_frame
			controls.clear()
			visit(game, controls)
			for control in controls:
				if not is_instance_valid(control) or not control.is_visible_in_tree():
					continue
				UI.touch_target(control, UI.touch_kind(control), true)
			for frame in range(3):
				await get_tree().process_frame
			for control in controls:
				if not is_instance_valid(control) or not control.is_visible_in_tree():
					continue
				scanned[control.get_instance_id()] = true
				var minimum: float = 77.0 if UI.touch_kind(control) == "primary" else 58.0
				if control.size.x + 1.0 < 58.0 or control.size.y + 1.0 < minimum:
					too_small.append("%s %s" % [control.get_path(), str(control.size)])
		var interactive_count := scanned.size()
		if interactive_count < 40:
			fail("Too few interactive controls scanned at %s: %d" % [str(dimensions), interactive_count])
		if not too_small.is_empty():
			fail("%s interactive zones undersized: %s" % [str(dimensions), str(too_small.slice(0, 8))])
		var dock: Control = game.get("bottom_dock") as Control
		if dock == null or dock.get_global_rect().end.x > dimensions.x + 1.0 or dock.get_global_rect().end.y > dimensions.y + 1.0:
			fail("Dock overflows at %s" % str(dimensions))
		var header: Control = game.get("header_panel") as Control
		if header == null or header.get_global_rect().end.x > dimensions.x + 1.0:
			fail("Header overflows at %s" % str(dimensions))
		print("[T2] %s controls=%d undersized=%d" % [str(dimensions), interactive_count, too_small.size()])
		viewport.queue_free()
		await get_tree().process_frame
	if failures.is_empty():
		print("[CI] TouchTargetScenario PASS")
		get_tree().quit(0)
	else:
		for problem in failures:
			push_error("[CI] TouchTargetScenario: " + problem)
		get_tree().quit(1)
