extends Node

var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)

func _ready() -> void:
	var map: Control = (load("res://ui/components/BranchMap.gd") as Script).new()
	add_child(map)
	await get_tree().process_frame
	map.call("refresh")
	var first_cta: Button = map.call("cta_button")
	var first_id := first_cta.get_instance_id()
	var cpu_button: Button = (map.get("_node_buttons") as Dictionary)["cpu"]
	var first_style := cpu_button.get_theme_stylebox("normal")
	var first_signature: String = map.get("_last_content_signature")
	check(first_signature != "", "initial signature is empty")
	for i in range(8):
		map.call("refresh")
	check((map.call("cta_button") as Button).get_instance_id() == first_id, "unchanged refresh rebuilt detail card")
	check(cpu_button.get_theme_stylebox("normal") == first_style, "unchanged refresh rebuilt button styles")
	check(str(map.get("_last_content_signature")) == first_signature, "stable signature changed")
	map.call("select", "soft")
	check((map.call("cta_button") as Button).get_instance_id() != first_id, "selection was not rebuilt")
	check(not (map.call("cta_button") as Button).disabled, "software selection no longer navigable")
	map.call("select", "def")
	check((map.call("cta_button") as Button).disabled, "locked branch became navigable")
	var original_year: int = TimeManager.year
	TimeManager.year = 1979
	map.call("refresh")
	var before: String = ((map.get("_card_box") as VBoxContainer).get_child(1) as Label).text
	var cta_before: Button = map.call("cta_button")
	TimeManager.year = 1980
	map.call("refresh")
	var after: String = ((map.get("_card_box") as VBoxContainer).get_child(1) as Label).text
	check(after != before, "change of branch status in 1980 not reflected")
	check(cta_before != (map.call("cta_button") as Button), "new year status did not cause rerender")
	TimeManager.year = original_year
	map.queue_free()
	if failures.is_empty():
		print("[CI] BranchMap signature: stable controls, selection, locked CTA, status date PASS")
		get_tree().quit(0)
	else:
		for description in failures:
			push_error("[CI] BranchMap: " + description)
		get_tree().quit(1)
