extends RefCounted
## Planche 6 « La finition » (08/10) : trois pistes de boîtier aux effets modestes et lisibles,
## posées une seule fois par génération, gardées dans la sauvegarde, et comptées par la presse.

const DESIGN := preload("res://scripts/CpuDesign.gd")
const FINISH := preload("res://scripts/CpuFinish.gd")

static func run(host: Node) -> String:
	# 1. Les effets.
	var sample := {"unit_cost":40, "metrics":{"reliability":70.0, "efficiency":60.0}}
	var sober := FINISH.effects(sample, {"piste":"SOBRE"})
	var showcase := FINISH.effects(sample, {"piste":"VITRINE"})
	var cheap := FINISH.effects(sample, {"piste":"ECO", "doodle":true})
	if int(sober.cost) != 0 or float(sober.press) != 0.0 or float(sober.reliability) != 0.0:
		return "Finishing: the sober finish should change nothing"
	if int(showcase.cost) <= 0 or float(showcase.press) <= 0.0:
		return "Finishing: the showcase finish should cost a bit and please the press"
	if int(cheap.cost) >= 0 or float(cheap.reliability) >= 0.0 or float(cheap.efficiency) >= 0.0 or float(cheap.press) != FINISH.DOODLE_PRESS:
		return "Finishing: plastic should be cheaper but hotter; the hidden drawing should count for the press (%s)" % str(cheap)

	# 2. Une génération prête, habillée une seule fois.
	SimulationManager.reset_all("CI Finition", "CPU", "STANDARD")
	ProductManager.create_from_industrialization({"id":"CI-FIN", "name":"CI Finish", "sector":"CPU", "segment":MarketManager.default_segment(),
		"cpu_design":DESIGN.default_design(), "complexity":40.0, "design_estimate":{},
		"final_metrics":{"performance":66.0, "efficiency":64.0, "reliability":72.0, "innovation":55.0, "sustainability":58.0}}, {})
	var generation_id := ""
	var costs := {}
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		generation_id = str(product.get("generation_id", ""))
		costs[str(product.id)] = int(product.unit_cost)
	if generation_id == "" or not ProductManager.generation_needs_finish(generation_id):
		return "Finishing: a fresh CPU range should wait for its finish"

	# 3. L'écran : la piste choisie part avec le bouton.
	var board: Control = (load("res://ui/components/FinishingBoard.gd") as Script).new() as Control
	host.add_child(board)
	board.call("set_generation", generation_id, ProductManager.products[0])
	board.call("select_piste", "VITRINE")
	board.call("toggle_doodle")
	var impacts: Array = board.call("impacts")
	var validate: Button = board.call("validate_button")
	var sent := {}
	board.connect("finish_requested", func(id: String, finish: Dictionary): sent.merge({"id":id, "finish":finish}, true))
	if validate == null:
		board.queue_free()
		return "Finishing: « Valider la finition » missing"
	validate.emit_signal("pressed")
	board.queue_free()
	if str(sent.get("id", "")) != generation_id or str((sent.get("finish", {}) as Dictionary).get("piste", "")) != "VITRINE" or not bool((sent.finish as Dictionary).get("doodle", false)):
		return "Finishing: the chosen finish was not sent (%s)" % str(sent)
	if not str((impacts[0] as Dictionary).value).contains("(+") or not str((impacts[3] as Dictionary).value).begins_with("+3"):
		return "Finishing: the impacts should show the extra cost and the press bonus (%s)" % str(impacts)

	# 4. Posée sur toute la gamme, une seule fois.
	if not ProductManager.apply_cpu_finish(generation_id, sent.finish) or ProductManager.apply_cpu_finish(generation_id, {"piste":"ECO"}):
		return "Finishing: the finish should apply once per generation"
	if ProductManager.generation_needs_finish(generation_id):
		return "Finishing: the generation still asks for a finish"
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if int(product.unit_cost) <= int(costs[str(product.id)]) or float(product.get("finish_press", 0.0)) != 3.0 or str((product.finish as Dictionary).piste) != "VITRINE":
			return "Finishing: %s did not receive the showcase finish" % str(product.name)

	# 5. Gardée dans la sauvegarde.
	var saved := ProductManager.get_state().duplicate(true)
	ProductManager.reset()
	ProductManager.load_state(saved)
	if str(((ProductManager.products[0] as Dictionary).get("finish", {}) as Dictionary).get("piste", "")) != "VITRINE":
		return "Finishing: the finish was lost by a save/load"

	# 6. La presse la compte, comme un facteur nommé.
	var product: Dictionary = ProductManager.products[0]
	var outlet: Dictionary = MediaManager.available_outlets()[0]
	var with_finish := MediaManager.review_breakdown(outlet, product, 2, 4, {})
	var plain := product.duplicate(true)
	plain.erase("finish_press")
	var without := MediaManager.review_breakdown(outlet, plain, 2, 4, {})
	var listed := (with_finish.parts as Array).any(func(part): return str(part.key) == "finish")
	if not listed or float(with_finish.final) <= float(without.final):
		return "Finishing: the press should count the finish (%.1f vs %.1f)" % [float(with_finish.final), float(without.final)]
	return ""
