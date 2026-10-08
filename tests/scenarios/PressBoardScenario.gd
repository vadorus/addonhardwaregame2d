extends RefCounted
## Revue des onglets (07/10) — La Presse dans l'esprit du jour J : une pile de coupures par CPU
## (la meilleure critique en tête), la courbe des notes, et Nora qui compare au CPU précédent.

static func run(host: Node) -> String:
	var saved: Array = MediaManager.news.duplicate(true)
	MediaManager.news = [
		{"headline":"Le Nova 2 confirme", "body":"Plus rapide. Plus sobre. Bravo.", "source_name":"Byte Hebdo", "review_score":82.0, "product_name":"Nova 2", "month":3, "year":1976},
		{"headline":"Bien, sans plus", "body":"Correct.", "source_name":"Circuit Lab", "review_score":70.0, "product_name":"Nova 2", "month":3, "year":1976},
		{"headline":"Une brève", "body":"Économie.", "category":"Business", "month":2, "year":1976},
		{"headline":"Un début prometteur", "body":"Premier essai.", "source_name":"Byte Hebdo", "review_score":60.0, "product_name":"Nova 1", "month":5, "year":1974}]
	var error := _checks(host)
	MediaManager.news = saved
	return error

static func _checks(host: Node) -> String:
	var script: Script = load("res://ui/components/PressBoard.gd")
	var products: Array = script.call("products_with_reviews", MediaManager.news)
	if products.size() != 2 or str(products[0].name) != "Nova 2":
		return "Press: one pile per tested CPU, newest first (%s)" % str(products)
	if absf(float(products[0].average) - 76.0) > 0.01:
		return "Press: the pile shows the average score (%s)" % str(products[0].average)
	if str((products[0].reviews as Array)[0].source_name) != "Byte Hebdo":
		return "Press: the best review leads the pile"
	var board: Control = script.new() as Control
	host.add_child(board)
	var piles: VBoxContainer = board.get("_piles")
	var line := str((board.get("scene") as Control).call("line_text"))
	var ok_piles := piles.get_child_count() == 2
	var ok_line := line.begins_with("Nora") and line.contains("Nova 2") and line.contains("Mieux que Nova 1")
	var ok_curve := (board.get("_curve_card") as Control).visible
	host.remove_child(board)
	board.queue_free()
	if not ok_piles:
		return "Press: two piles expected"
	if not ok_line:
		return "Press: Nora compares the last CPU with the previous one (%s)" % line
	if not ok_curve:
		return "Press: the score curve appears from the second CPU"
	return ""
