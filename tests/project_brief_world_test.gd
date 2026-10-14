extends Node
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const LIVE := preload("res://scripts/LiveTheme.gd")
const UI := preload("res://ui/UiKit.gd")
const STUDIO := preload("res://scripts/SoftwareStudio.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func settle() -> void:
	for frame in range(10): await get_tree().process_frame

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	LIVE.override = "NONE"
	await test_first_cpu()
	for dimensions in [Vector2i(1616, 720), Vector2i(1280, 720), Vector2i(1067, 600), Vector2i(800, 480), Vector2i(700, 720)]:
		await test_world(dimensions)
	if failures.is_empty():
		print("[CI] Project brief and world marker test passed")
		get_tree().quit(0)
		return
	for failure in failures: push_error("Project brief/world: " + failure)
	get_tree().quit(1)

## Revue des onglets (14/10) : la fiche « brief » de l'établi et les marqueurs de projet dans le décor ont été
## retirés lors de la refonte du QG (08/10). Le test vérifie ce qui existe aujourd'hui :
## - l'établi du premier CPU propose une conception sans rien dépenser tant qu'on ne lance pas ;
## - le QG affiche un projet CPU et un logiciel du studio sans déborder ni modifier la partie en pause.
func test_first_cpu() -> void:
	SimulationManager.reset_all("CPU brief", "CPU", "STANDARD")
	TimeManager.time_scale = 0
	var workshop: Control = (load("res://ui/FirstCpuWorkshop.gd") as Script).new()
	add_child(workshop)
	workshop.call("open")
	workshop.call("select_brief", "CALCULATOR")
	await settle()
	var spec: Dictionary = workshop.call("current_spec")
	var treasury := Economy.get_state().duplicate(true)
	check(not spec.is_empty() and int(spec.get("budget", 0)) > 0, "first CPU brief gives no specification")
	check(Economy.get_state() == treasury and ResearchManager.projects.is_empty(), "browsing the first CPU workbench spends or starts a project")
	workshop.call("show_error", "Équipe indisponible")
	await settle()
	check((workshop.get("_error_label") as Control).is_visible_in_tree(), "CPU refusal hidden")
	workshop.queue_free()
	await settle()

func test_world(dimensions: Vector2i) -> void:
	SimulationManager.reset_all("World preview", "CPU", "STANDARD")
	Economy.money = 1000000
	TimeManager.time_scale = 0
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child(viewport)
	var garage: Control = (load("res://ui/GarageHub.gd") as Script).new()
	garage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(garage)
	garage.call("set_progression", {"QG":true, "LAB":true, "COMPANY":true, "TEAM":true, "PRODUCTS":true, "MARKET":true, "PRESS":true})
	await settle()
	check(ResearchManager.start_project("World CPU", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 35000, CPU_DESIGN.default_design(), {}, {}, "GENERAL", "", "BALANCED", "STANDARD", "NONE", "SHARED", "NONE", true), "cannot create CPU fixture")
	var tokens := {}
	for phase in STUDIO.PHASE_ORDER:
		tokens[phase] = STUDIO.ideal_tokens("UTILITY", phase)
	check(SoftwareManager.start_studio_project({"type":"UTILITY", "audience":"HOBBY", "platform":"LEADER", "features":["FILES"], "tokens":tokens, "price_mode":"MARKET"}, "World Tools"), "cannot create studio software fixture")
	garage.call("_refresh_gameplay_overlays")
	await settle()
	var before := {"cpu":ResearchManager.get_state().duplicate(true), "software":SoftwareManager.get_state().duplicate(true), "money":Economy.get_state().duplicate(true), "time":TimeManager.get_state().duplicate(true)}
	garage.call("_refresh_gameplay_overlays")
	await settle()
	check(ResearchManager.get_state() == before.cpu and SoftwareManager.get_state() == before.software and Economy.get_state() == before.money and TimeManager.get_state() == before.time, "world presentation advances work, time or spending in pause")
	var bounds := Rect2(Vector2.ZERO, garage.size)
	for button in garage.get("_zone_buttons"):
		if not button.visible: continue
		check(bounds.encloses(button.get_rect()) and button.size.x >= 44 and button.size.y >= 44, "workstation is clipped or too small at " + str(dimensions))
	viewport.queue_free()
	await settle()
