extends Node
## Atelier logiciel (réécrit le 08/10, lot 0) : l'ancien test visait un comparateur retiré de l'interface.
## On vérifie ce que voit le joueur aujourd'hui :
## - l'aperçu affiché suit exactement la prévision du gestionnaire et ne change pas la simulation ;
## - sans développeur, la durée n'est jamais « ~-1 mois » et le lancement est bloqué ;
## - avant 1977, le public grand public s'appelle « Passionnés et universités » ;
## - pour les familles de base, changer un réglage suit `SoftwareManager.preview` ;
## - le bouton de lancement reste visible sur les formats de téléphone.

const UI := preload("res://ui/UiKit.gd")
const LIVE := preload("res://scripts/LiveTheme.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func settle() -> void:
	for frame in range(8): await get_tree().process_frame

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	LIVE.override = "NONE"
	for mode in ["ACCESSIBLE", "STANDARD", "SIMULATION"]:
		await test_choices(mode)
	# Le jeu est en paysage, étiré en « expand » depuis 1280×720 : la largeur logique ne descend jamais sous 1280.
	for dimensions in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1280, 960)]:
		await test_layout(dimensions)
	if failures.is_empty():
		print("[CI] Software choice preview test passed")
		get_tree().quit(0)
		return
	for failure in failures: push_error("Software choice preview: " + failure)
	get_tree().quit(1)

func workshop(parent: Node) -> Control:
	var node: Control = (load("res://ui/SoftwareWorkshop.gd") as Script).new()
	parent.add_child(node)
	node.call("open")
	node.call("_show_product")
	return node

func preview_text(node: Control) -> String:
	return (node.get("_project_preview") as Label).text

func test_choices(mode: String) -> void:
	SimulationManager.reset_all("Preview test", "CPU", mode)
	TimeManager.time_scale = 0.0
	Economy.money = 1000000
	var node := workshop(self)
	await settle()
	var software_before := SoftwareManager.get_state().duplicate(true)
	var economy_before := Economy.get_state().duplicate(true)
	var time_before := TimeManager.get_state().duplicate(true)
	var checks: Dictionary = node.get("_feature_checks")
	check(not checks.is_empty(), "utility features are missing")
	var features: Array = node.call("_utility_features")
	check(features.size() == 2, "the form should start with two features")
	var plan := SoftwareManager.utility_preview(features, "HOME", "MARKET")
	check(preview_text(node).contains("~%d mois" % int(plan.calendar_months)), "displayed duration differs from the forecast (%s)" % mode)
	check(preview_text(node).contains(UI.money(int(plan.total_cost))), "displayed budget differs from the forecast (%s)" % mode)
	check(preview_text(node).contains("Passionnés et universités"), "1971 should not offer « Particuliers »")
	(checks.AUTOMATION as CheckBox).button_pressed = true
	var plan_more := SoftwareManager.utility_preview(node.call("_utility_features"), "HOME", "MARKET")
	check(preview_text(node).contains(UI.money(int(plan_more.total_cost))), "adding a feature does not refresh the estimate")
	check(int(plan_more.total_cost) >= int(plan.total_cost), "adding a feature makes the project cheaper")
	UI.select_meta(node.get("_price_select"), "PREMIUM")
	node.call("_refresh_product_preview")
	check(SoftwareManager.get_state() == software_before and Economy.get_state() == economy_before and TimeManager.get_state() == time_before, "browsing choices spends, progresses time or changes the simulation")
	# Sans développeur : jamais de durée négative, lancement bloqué.
	for employee in PersonnelManager.staff:
		if str(employee.department) == "Développement": employee.department = "R&D"
	node.call("_refresh_product_preview")
	check(not preview_text(node).contains("-1"), "a missing team shows a negative duration")
	check((node.get("_project_start") as Button).disabled, "a project can start without developers")
	# Familles de base.
	SimulationManager.reset_all("Family preview", "CPU", mode)
	Economy.money = 1000000
	TimeManager.year = 1977
	SoftwareManager._check_unlocks()
	SoftwareManager.family_state("DEVTOOLS")["mastery"] = 1
	node.call("_refresh_family_options")
	UI.select_meta(node.get("_family_select"), "DEVTOOLS")
	node.call("_on_family_changed")
	var controls: Dictionary = node.get("_setting_controls")
	(controls.productivity as SpinBox).value = 4
	var basic := SoftwareManager.preview("DEVTOOLS", {"productivity":4,"compatibility":3,"stability":3,"extensibility":3}, "MARKET")
	check(preview_text(node).contains(UI.money(int(basic.total_cost))), "basic family estimate differs from the manager preview")
	node.queue_free()
	await settle()

func test_layout(dimensions: Vector2i) -> void:
	SimulationManager.reset_all("Preview layout", "CPU", "STANDARD")
	Economy.money = 1000000
	TimeManager.time_scale = 0.0
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child(viewport)
	var node := workshop(viewport)
	await settle()
	var content: Control = node.get("_content")
	check(content.size.x <= dimensions.x, "product form exceeds viewport width at " + str(dimensions))
	var start: Button = node.get("_project_start")
	check(start.size.y >= 44.0, "launch button is too small to touch at " + str(dimensions))
	var scroll := content.get_parent() as ScrollContainer
	if scroll != null:
		scroll.ensure_control_visible(start)
		await settle()
		check(scroll.get_global_rect().encloses(start.get_global_rect()), "launch button cannot scroll into view at " + str(dimensions))
	viewport.queue_free()
	await settle()
