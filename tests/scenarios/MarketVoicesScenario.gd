extends RefCounted
## Planche 8 « La voix du monde » (08/10) : après la sortie, espéré / obtenu, « Vaut-il son prix ? » et les voix.
## - la lecture du prix suit la vraie demande : trop cher → baisser fait vendre plus (prévision du jeu) ;
## - rien n'est modifié par la lecture ;
## - le bouton de Nora envoie le prix conseillé, et une fois appliqué la jauge change de zone ;
## - les quatre familles de voix parlent, et la presse cite les vrais tests du jour J.

const DESIGN := preload("res://scripts/CpuDesign.gd")
const VOICES := preload("res://scripts/MarketVoices.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Voix du monde", "CPU", "STANDARD")
	Economy.money = 2000000
	ProductManager.create_from_industrialization({"id":"CI-VOX", "name":"CI Vox", "sector":"CPU", "segment":MarketManager.default_segment(),
		"cpu_design":DESIGN.default_design(), "complexity":40.0, "design_estimate":{},
		"final_metrics":{"performance":66.0, "efficiency":64.0, "reliability":74.0, "innovation":55.0, "sustainability":58.0}}, {})
	var target: Dictionary = {}
	for product_value in ProductManager.products:
		if str((product_value as Dictionary).get("sku_tier", "")) == "SIGNATURE":
			target = product_value
	if target.is_empty():
		return "Market voices: no core model to launch"
	var reference := VOICES.reference_price(target)
	var expensive := int(round(reference * 2.0))
	if not ProductManager.launch_product(str(target.id), expensive, mini(200, int(target.production_capacity))):
		return "Market voices: launch failed"
	SimulationManager.process_month_end()
	var product := VOICES.focus_product()
	if str(product.get("id", "")) != str(target.id):
		return "Market voices: the focus should be the CPU just launched"

	# 1. Lecture pure.
	var before := ProductManager.get_state().duplicate(true)
	var money := Economy.money
	var value := VOICES.value_read(product)
	var gaps := VOICES.gaps(product)
	var voices := VOICES.voices(product)
	if ProductManager.get_state() != before or Economy.money != money:
		return "Market voices: reading the market changed the game"

	# 2. Le prix, comme la demande le voit.
	if str(value.zone) != "TOO_EXPENSIVE" or int(value.suggested) <= 0 or int(value.suggested) >= expensive:
		return "Market voices: a price at twice the market should read « trop cher » with a lower advice (%s)" % str(value)
	if int((value.then as Dictionary).units) <= int((value.now as Dictionary).units):
		return "Market voices: lowering the price should sell more in the game's own forecast"
	if not str(value.nora).contains("%d €" % int(value.suggested)):
		return "Market voices: Nora should name the advised price"

	# 2 bis. Cher mais déjà en rupture : pas de baisse conseillée (on vend tout ce qu'on fabrique).
	var sold_out := product.duplicate(true)
	sold_out["price"] = int(round(reference * 1.3))
	sold_out["production_capacity"] = 1
	var sold_out_read := VOICES.value_read(sold_out)
	if str(sold_out_read.zone) != "TOO_EXPENSIVE" or int(sold_out_read.suggested) != 0 or not str(sold_out_read.nora).contains("capacité"):
		return "Market voices: when every chip already sells, Nora should not advise a lower price (%s)" % str(sold_out_read.nora)

	# 3. Espéré / obtenu et les voix.
	if gaps.size() < 2:
		return "Market voices: expected sales and market share should be compared after a month (%d rows)" % gaps.size()
	for family in ["public", "rivals", "pros", "press"]:
		if (voices.get(family, []) as Array).is_empty():
			return "Market voices: the « %s » voices are silent" % family
	var dealer_says := false
	for card_value in voices.public:
		if str((card_value as Dictionary).effect).contains("trop haut"):
			dealer_says = true
	if not dealer_says:
		return "Market voices: the dealer should complain about the price"
	var press_card: Dictionary = (voices.press as Array)[0]
	if not str(press_card.effect).begins_with("Note "):
		return "Market voices: the press tab should quote the real reviews"

	# 4. L'écran : le conseil de Nora part avec le bouton, puis la jauge bouge.
	var board: Control = (load("res://ui/components/MarketBoard.gd") as Script).new() as Control
	host.add_child(board)
	board.call("refresh")
	var lower: Button = board.call("lower_button")
	var sent := {}
	board.connect("action_requested", func(action: String, payload: Dictionary): sent.merge({"action":action, "payload":payload}, true))
	if lower == null:
		board.queue_free()
		return "Market voices: « Baisser » button missing"
	lower.emit_signal("pressed")
	board.queue_free()
	var payload: Dictionary = sent.get("payload", {})
	if str(sent.get("action", "")) != "update_price" or int(payload.get("price", 0)) != int(value.suggested):
		return "Market voices: the advice button did not send the advised price (%s)" % str(sent)
	if not ProductManager.update_product_price(str(payload.product_id), int(payload.price)):
		return "Market voices: the advised price could not be applied"
	if str(VOICES.value_read(ProductManager.get_product(str(target.id))).zone) == "TOO_EXPENSIVE":
		return "Market voices: after following the advice, the price should no longer read « trop cher »"

	# 5. L'onglet : Nora parle du CPU en tête.
	var screen: Control = (load("res://ui/screens/MarketScreen.gd") as Script).new() as Control
	host.add_child(screen)
	screen.call("refresh")
	var line := str((screen.get("scene") as Control).call("line_text"))
	var board_visible := (screen.get("market_board") as Control).visible
	screen.queue_free()
	if not line.contains("CI Vox") or not board_visible:
		return "Market voices: the Market tab should open on the voice of the world (%s)" % line
	return ""
