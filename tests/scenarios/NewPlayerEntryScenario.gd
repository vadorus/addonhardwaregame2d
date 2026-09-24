extends RefCounted

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(host: Node) -> String:
	var snapshot := _snapshot()
	CompanyManager.created = false

	var main_script: Script = load("res://main.gd")
	if main_script == null:
		_restore(snapshot)
		return "V0.5 entry: main script could not be loaded"
	var game: Control = main_script.new() as Control
	host.add_child(game)

	var setup_layer: Control = game.get("setup_layer")
	var title_box: VBoxContainer = game.get("setup_title_box")
	var creation_box: VBoxContainer = game.get("setup_creation_box")
	if setup_layer == null or not setup_layer.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: title screen is not visible before company creation"
	if title_box == null or not title_box.visible or creation_box == null or creation_box.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: title screen did not start in the simple title state"

	game.call("_show_creation_screen")
	if title_box.visible or not creation_box.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: New Company did not open the short creation form"

	var setup_name: LineEdit = game.get("setup_name")
	if setup_name == null:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: company name field is missing"
	setup_name.text = "CI Garage Start"
	game.call("_start_new_game")

	if not CompanyManager.created or setup_layer.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: entering the garage did not create and reveal the game"
	var nav_panel: PanelContainer = game.get("nav_panel")
	if nav_panel == null or nav_panel.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: management navigation is visible before the first CPU project"
	var tabs: TabContainer = game.get("tabs")
	if tabs == null or tabs.current_tab != 0:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: new company did not land directly in the garage"

	var dashboard: Control = game.get("dashboard_screen")
	if dashboard == null:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: garage screen is missing"
	var heading: Control = dashboard.get("dashboard_heading")
	var management_grid: GridContainer = dashboard.get("dashboard_grid")
	var garage: Control = dashboard.get("dashboard_garage")
	if heading == null or heading.visible or management_grid == null or management_grid.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: management dashboard still surrounds the opening garage"
	if garage == null or int(garage.call("visible_zone_count")) != 1:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: opening garage should expose only the CPU workbench"
	if str(garage.get("_onboarding_stage")) != "FIRST_IDEA":
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: opening garage did not enter the first-idea onboarding stage"

	if TimeManager.time_scale != 0.0:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: time is running before the player has chosen the first CPU"

	game.call("_on_dashboard_navigation", 3, "Établi CPU")
	var workshop: Control = game.get("first_cpu_workshop")
	if workshop == null or not workshop.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: touching the CPU workbench did not open the guided workshop"
	if int(workshop.call("get_brief_count")) != 4:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: first CPU workshop does not offer the four opening intents"
	workshop.call("select_brief", "EMBEDDED")
	var spec_value = workshop.call("current_spec")
	if typeof(spec_value) != TYPE_DICTIONARY:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: first CPU workshop did not create a launch specification"
	var spec: Dictionary = spec_value
	spec["name"] = "CI First Idea"
	if str(spec.get("segment", "")) != "EMBEDDED" or int(spec.get("budget", 0)) != 45000:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: embedded brief did not configure the expected target and budget"

	game.call("_launch_first_cpu_from_workshop", spec)
	if ResearchManager.projects.size() != 1:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: guided workshop could not launch the first CPU project"
	if workshop.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: guided workshop stayed open after project launch"
	if TimeManager.time_scale <= 0.0:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: simulation did not start when the first CPU entered development"

	if not nav_panel.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: management navigation did not appear after the first project started"
	if not heading.visible or not management_grid.visible:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: full HQ did not appear after the first project started"
	if int(garage.call("visible_zone_count")) < 3:
		game.queue_free()
		_restore(snapshot)
		return "V0.5 entry: garage did not expand its available zones after onboarding"

	game.queue_free()
	_restore(snapshot)
	return ""

static func _snapshot() -> Dictionary:
	return {
		"time":TimeManager.get_state().duplicate(true),
		"balance":BalanceManager.get_state().duplicate(true),
		"economy":Economy.get_state().duplicate(true),
		"company":CompanyManager.get_state().duplicate(true),
		"divisions":DivisionManager.get_state().duplicate(true),
		"personnel":PersonnelManager.get_state().duplicate(true),
		"executive":ExecutiveManager.get_state().duplicate(true),
		"suppliers":SupplierManager.get_state().duplicate(true),
		"research":ResearchManager.get_state().duplicate(true),
		"foundry":FoundryManager.get_state().duplicate(true),
		"production":ProductionManager.get_state().duplicate(true),
		"patents":PatentManager.get_state().duplicate(true),
		"products":ProductManager.get_state().duplicate(true),
		"after_sales":AfterSalesManager.get_state().duplicate(true),
		"market":MarketManager.get_state().duplicate(true),
		"media":MediaManager.get_state().duplicate(true),
		"game_over":SimulationManager.is_game_over
	}

static func _restore(snapshot: Dictionary) -> void:
	CompanyManager.load_state(snapshot.company)
	TimeManager.load_state(snapshot.time)
	BalanceManager.load_state(snapshot.balance)
	DivisionManager.load_state(snapshot.divisions)
	Economy.load_state(snapshot.economy)
	PersonnelManager.load_state(snapshot.personnel)
	ExecutiveManager.load_state(snapshot.executive)
	SupplierManager.load_state(snapshot.suppliers)
	ResearchManager.load_state(snapshot.research)
	FoundryManager.load_state(snapshot.foundry)
	ProductionManager.load_state(snapshot.production)
	PatentManager.load_state(snapshot.patents)
	ProductManager.load_state(snapshot.products)
	AfterSalesManager.load_state(snapshot.after_sales)
	MarketManager.load_state(snapshot.market)
	MediaManager.load_state(snapshot.media)
	SimulationManager.is_game_over = bool(snapshot.game_over)
