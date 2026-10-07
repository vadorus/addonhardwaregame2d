extends Node
func _ready() -> void:
	SaveManager.writes_enabled = false
	SaveManager.save_root = "res://build/pixel-saves-before/"
	if not SaveManager.load_game():
		get_tree().quit(1)
		return
	var outlet: Dictionary = MediaManager.available_outlets()[0]
	for product in ProductManager.products:
		if str(product.get("sector", "")) != "CPU": continue
		var comp := MarketManager.press_comparison(product)
		var rank := MarketManager.benchmark_rank(product)
		var breakdown := MediaManager.review_breakdown(outlet, product, rank, MarketManager.benchmark_for(product).size(), comp)
		print(JSON.stringify({"name":product.name,"metrics":product.metrics,"comparison":comp,"breakdown":breakdown}))
	get_tree().quit()
