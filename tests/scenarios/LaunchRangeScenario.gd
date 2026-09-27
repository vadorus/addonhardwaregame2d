extends RefCounted
## Bug trouvé sur le Pixel (partie d'Alexandre, 28/09) : après avoir lancé un modèle de la gamme,
## « Préparer le lancement » repointait le modèle déjà lancé → « Lancement impossible ».

const JOURNEY := preload("res://tests/scenarios/FullCpuPlayerJourneyScenario.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Launch Range", "CPU", "STANDARD")
	if not ResearchManager.start_project("tv1", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CPU_DESIGN.default_design()):
		return "Launch range: could not start the CPU project"
	var project_id := str(ResearchManager.projects.back().get("id", ""))
	var dev := str(JOURNEY._advance_project_to_industrialization(project_id, 30))
	if dev != "":
		return "Launch range: development failed: " + dev
	var indus := str(JOURNEY._configure_and_finish_industrialization(ProductionManager.get_active_jobs()[0], 18))
	if indus != "":
		return "Launch range: industrialization failed: " + indus
	var ready: Array = ProductManager.products.filter(func(p): return str(p.get("status", "")) == "READY")
	if ready.size() < 2:
		return "Launch range: expected a range of several READY models (got %d)" % ready.size()

	# Le joueur lance un seul modèle, comme sur le téléphone.
	var first: Dictionary = ready[0]
	if not ProductManager.launch_product(str(first.id), int(first.price), int(first.get("recommended_capacity", 100))):
		return "Launch range: first model could not be launched"

	# L'écran Produits, arrivé par « Préparer le lancement », doit pointer un modèle PRÊT.
	var screen: Control = (load("res://ui/screens/ProductsScreen.gd") as Script).new() as Control
	host.add_child(screen)
	var panel: Control = screen.get("lifecycle_panel")
	panel.call("refresh")
	# Simule la sélection restée sur le modèle déjà lancé.
	var option: OptionButton = panel.get("product_select")
	for i in range(option.item_count):
		if str(option.get_item_metadata(i)) == str(first.id):
			option.select(i)
	panel.call("_refresh_product_details")
	var launch_button: Button = panel.get("launch_button")
	if not launch_button.disabled:
		screen.queue_free()
		return "Launch button stays enabled on a model that is already launched"
	screen.call("focus_product_launch")
	var selected := ProductManager.get_product(str(panel.call("selected_product_id")))
	if str(selected.get("status", "")) != "READY":
		screen.queue_free()
		return "« Préparer le lancement » still points to a model that is not READY (%s)" % str(selected.get("status", ""))
	if launch_button.disabled:
		screen.queue_free()
		return "Launch button is disabled on a READY model"
	screen.queue_free()

	# « Lancer toute la gamme » lance les modèles restants.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	host.add_child(viewport)
	var game := (load("res://main.gd") as Script).new() as Control
	viewport.add_child(game)
	game.call("_launch_range", str(first.get("generation_id", "")))
	var still_ready: Array = ProductManager.products.filter(func(p): return str(p.get("status", "")) == "READY" and str(p.get("generation_id", "")) == str(first.get("generation_id", "")))
	viewport.queue_free()
	if not still_ready.is_empty():
		return "« Lancer toute la gamme » left %d model(s) unlaunched" % still_ready.size()
	return ""
