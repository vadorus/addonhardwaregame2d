extends RefCounted
## Planche 4 « La fabrication » (08/10) : le prototype validé face au marché, le choix du fondeur,
## la gamme qui sortira et « Lancer la fabrication ».
## - l'aperçu ne touche ni à l'état du jeu, ni à l'argent, ni au hasard ;
## - un fondeur plus précis donne plus de puces bonnes ; un tri strict donne moins de X qu'un tri « plus de X » ;
## - les écarts avec l'ancien modèle sont bien orientés (prix : moins = mieux) ;
## - le bouton envoie le fondeur choisi, et Produits > Fabriquer ne montre plus l'ancienne carte en double.

const DESIGN := preload("res://scripts/CpuDesign.gd")
const PREVIEW := preload("res://scripts/ProductionPreview.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Planche 4", "CPU", "STANDARD")
	ProductionManager._on_project_completed({"id":"CI-PB", "name":"CI Board", "sector":"CPU", "segment":MarketManager.default_segment(),
		"cpu_design":DESIGN.default_design(), "complexity":40.0, "design_estimate":{},
		"final_metrics":{"performance":66.0, "efficiency":64.0, "reliability":72.0, "innovation":55.0, "sustainability":58.0}})
	var active := ProductionManager.get_active_jobs()
	if active.is_empty():
		return "Production board: no job waiting for its factory"
	var job: Dictionary = active[0]
	var job_id := str(job.get("id", ""))

	# 1. Aperçu pur.
	var production_before := ProductionManager.get_state().duplicate(true)
	var products_before := ProductManager.products.size()
	var money_before := Economy.money
	var rng_before := ProductionManager.rng.state
	var foundry_rng_before := FoundryManager.rng.state
	var options := PREVIEW.foundry_options(job)
	var data := PREVIEW.build(job, str((options[0] as Dictionary).id) if not options.is_empty() else "")
	if ProductionManager.get_state() != production_before or ProductManager.products.size() != products_before \
			or Economy.money != money_before or ProductionManager.rng.state != rng_before or FoundryManager.rng.state != foundry_rng_before:
		return "Production board: the preview changed the game state"
	if options.size() < 2:
		return "Production board: at least two foundries should be offered at the start (%d)" % options.size()
	if options.filter(func(o): return bool(o.recommended)).size() != 1:
		return "Production board: exactly one foundry should be recommended"
	for option_value in options:
		if str((option_value as Dictionary).get("tag", "")) == "":
			return "Production board: every foundry needs a two-word summary"

	# 2. Le contenu de la planche.
	if not bool(data.get("ok", false)) or (data.rows as Array).size() != 5 or (data.models as Array).size() != 3:
		return "Production board: five comparison rows and three models expected (%s)" % str(data.keys())
	var share := 0.0
	for model_value in data.models:
		share += float((model_value as Dictionary).share)
	if absf(share - 1.0) > 0.01 or int(data.rank) < 1 or str(data.verdict) == "" or str(data.when) == "":
		return "Production board: split, rank, verdict or release month missing"

	# 3. Le fondeur et le tri changent vraiment le résultat.
	var sharpest := ""
	var bluntest := ""
	var best_precision := -1.0
	var worst_precision := 999.0
	for option_value in options:
		var option: Dictionary = option_value
		var precision := float((option.preview as Dictionary).get("route_precision", 0.0))
		if precision > best_precision:
			best_precision = precision
			sharpest = str(option.id)
		if precision < worst_precision:
			worst_precision = precision
			bluntest = str(option.id)
	if int(PREVIEW.build(job, sharpest).yield_pct) <= int(PREVIEW.build(job, bluntest).yield_pct):
		return "Production board: a more precise foundry should give more good chips"
	var volume := _apex_share(PREVIEW.build(job, sharpest, "VOLUME"))
	var strict := _apex_share(PREVIEW.build(job, sharpest, "STRICT"))
	if strict >= volume:
		return "Production board: strict sorting should leave fewer X chips than « plus de X » (%.2f vs %.2f)" % [strict, volume]

	# 4. Les écarts avec l'ancien modèle : plus rapide = bien, plus cher = mal.
	var rows := PREVIEW._rows({"metrics":{"performance":70.0, "efficiency":60.0, "reliability":70.0}, "price":40, "unit_cost":20},
		{"name":"Ancien", "metrics":{"performance":60.0, "efficiency":60.0, "reliability":75.0}, "price":30, "unit_cost":20}, {})
	var tones := {}
	for row_value in rows:
		tones[str((row_value as Dictionary).key)] = str((row_value as Dictionary).tone)
	if tones.get("performance") != "good" or tones.get("efficiency") != "neutral" or tones.get("reliability") != "bad" \
			or tones.get("price") != "bad" or tones.get("margin") != "good":
		return "Production board: comparison deltas point the wrong way (%s)" % str(tones)

	# 5. L'écran : le bouton envoie le fondeur choisi.
	var board: Control = (load("res://ui/components/ProductionBoard.gd") as Script).new() as Control
	host.add_child(board)
	board.call("set_job", job_id)
	var launch: Button = board.call("launch_button")
	if launch == null or launch.disabled:
		board.queue_free()
		return "Production board: « Lancer la fabrication » missing"
	var other := ""
	for option_value in options:
		if not bool((option_value as Dictionary).recommended):
			other = str((option_value as Dictionary).id)
	board.call("select_provider", other)
	board.call("select_binning", "STRICT")
	var received := {}
	board.connect("launch_requested", func(payload: Dictionary): received.merge(payload, true))
	(board.call("launch_button") as Button).emit_signal("pressed")
	board.queue_free()
	if str(received.get("job_id", "")) != job_id or str(received.get("provider", "")) != other or str(received.get("binning", "")) != "STRICT":
		return "Production board: the launch did not carry the chosen foundry and sorting (%s)" % str(received)

	# 6. Produits : la scène parle du CPU qui attend, l'ancienne carte n'est plus en double.
	var screen: Control = (load("res://ui/screens/ProductsScreen.gd") as Script).new() as Control
	host.add_child(screen)
	screen.call("_select_mode", "BUILD")
	var board_in_screen: Control = screen.get("production_board")
	var diagnosis: Dictionary = screen.call("products_diagnosis")
	var duplicate := _find_button(screen.get("industrialization_panel"), "Lancer la production")
	if board_in_screen == null or not board_in_screen.visible or not str(diagnosis.line).contains("CI Board") or duplicate != null:
		screen.queue_free()
		return "Production board: Products should open on the board, without the old card twice (%s)" % str(diagnosis.line)
	if not (ProductionManager.set_manufacturing_route(job_id, str(received.mode), str(received.provider)) and ProductionManager.set_binning_strategy(job_id, "STRICT")):
		screen.queue_free()
		return "Production board: the chosen route could not be applied"
	screen.call("refresh")
	diagnosis = screen.call("products_diagnosis")
	var still_visible := board_in_screen.visible
	screen.queue_free()
	if still_visible or not str(diagnosis.line).contains("prépare"):
		return "Production board: once launched, the board should give way to the factory progress (%s)" % str(diagnosis.line)
	return ""

static func _apex_share(data: Dictionary) -> float:
	for model_value in data.get("models", []):
		var model: Dictionary = model_value
		if str(model.tier) == "APEX":
			return float(model.share)
	return 0.0

static func _find_button(node: Node, text: String) -> Button:
	if node == null:
		return null
	if node is Button and (node as Button).text.begins_with(text) and (node as Button).is_visible_in_tree():
		return node
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null
