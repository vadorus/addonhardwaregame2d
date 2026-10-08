extends Node
## Le panneau P0 doit rester visible sur Android en paysage.
var failures: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)

func _ready() -> void:
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	PerfProbe.attach_game(host)
	PerfProbe.enable()
	# Attendre la fin de l'initialisation de la scene avant d'ajouter la CanvasLayer.
	await get_tree().process_frame
	PerfProbe.show_panel()
	for i in range(5):
		await get_tree().process_frame
	var panel: PanelContainer = PerfProbe._panel
	var scroll: ScrollContainer = panel.get_parent() as ScrollContainer
	var canvas_height := get_viewport().get_visible_rect().size.y
	check(panel.is_visible_in_tree(), "P0 panel is not visible in the scene tree")
	check(scroll.size.y > 260.0, "P0 scroll collapsed to %.1f px" % scroll.size.y)
	check(panel.size.y > 260.0, "P0 panel collapsed to %.1f px" % panel.size.y)
	check(scroll.size.y <= canvas_height, "P0 scroll overflows the viewport")
	check(PerfProbe._summary != null and PerfProbe._summary.is_visible_in_tree(), "P0 summary missing")
	var controls: VBoxContainer = panel.get_child(0) as VBoxContainer
	var count := 0
	for child in controls.get_children():
		if child is Button:
			count += 1
	check(count >= 10, "Missing P0 actions: %d" % count)
	PerfProbe.hide_panel()
	check(not PerfProbe._panel_layer.visible, "P0 cannot be hidden")
	if failures.is_empty():
		print("[CI] P0 panel visibility passed: scroll %.1f px, panel %.1f px, %d controls" % [
			scroll.size.y, panel.size.y, count
		])
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("P0 panel: " + failure)
		get_tree().quit(1)
