extends RefCounted
## V0.10 / J3 — moments clés illustrés : déduits de l'état du jeu, montrés une seule fois,
## sauvegardés, jamais rejoués sur une ancienne partie ; la carte met le jeu en pause.

const MOMENTS := preload("res://scripts/Moments.gd")

static func run(host: Node) -> String:
	var saved_products: Array = ProductManager.products.duplicate(true)
	var saved_seen: Dictionary = ExecutiveManager.moments_seen.duplicate(true)
	var saved_pending := ExecutiveManager.moments_migration_pending
	var saved_owned: Array = ArchitectureManager.owned.duplicate()
	var saved_scale := TimeManager.time_scale
	var error := _check(host)
	ProductManager.products = saved_products
	ExecutiveManager.moments_seen = saved_seen
	ExecutiveManager.moments_migration_pending = saved_pending
	ArchitectureManager.owned = saved_owned
	TimeManager.time_scale = saved_scale
	return error

static func _check(host: Node) -> String:
	for moment_id in MOMENTS.MOMENTS.keys():
		if not ResourceLoader.exists(MOMENTS.image_path(moment_id)):
			return "J3: missing illustration for moment %s" % moment_id
	var chip: Script = load("res://ui/ChipPreview.gd")
	var expected := {10000:"puce_1971", 3000:"puce_1978", 1000:"puce_1985", 600:"puce_1993", 180:"puce_1999", 90:"puce_2004", 3:"puce_2004"}
	for node in expected.keys():
		if str(chip.call("era_art_name", node)) != str(expected[node]) or chip.call("era_texture", node) == null:
			return "J3: chip art for %d nm should be %s" % [node, expected[node]]
	if not ResourceLoader.exists("res://assets/art/v010/titre/ecran_titre.webp"):
		return "J3: missing title screen art"
	ExecutiveManager.moments_seen = {}
	ExecutiveManager.moments_migration_pending = false
	ProductManager.products = []
	ArchitectureManager.owned = ["A4"]
	if MOMENTS.next_unseen() != "":
		return "J3: no moment should fire before anything happens"
	ProductManager.products = [{"id":"M1", "name":"Moment CPU", "status":"LAUNCHED", "last_month_demand":400, "last_month_lost_sales":200}]
	if MOMENTS.next_unseen() != "FIRST_LAUNCH":
		return "J3: the first launch must be the first moment"
	ExecutiveManager.mark_moment_seen("FIRST_LAUNCH")
	if MOMENTS.next_unseen() != "FIRST_STOCKOUT":
		return "J3: losing half the demand must trigger the stock-out moment"
	ExecutiveManager.mark_moment_seen("FIRST_STOCKOUT")
	if MOMENTS.next_unseen({"GOOD_PRESS":true}) != "GOOD_PRESS":
		return "J3: good reviews must trigger the press moment"
	if not MOMENTS.is_good_press([{"score":82.0}, {"score":80.0}]) or MOMENTS.is_good_press([{"score":60.0}]):
		return "J3: good press threshold is wrong"
	ExecutiveManager.mark_moment_seen("GOOD_PRESS")
	if MOMENTS.next_unseen({"GOOD_PRESS":true}) != "":
		return "J3: a seen moment must never come back"
	# Sauvegarde : les moments vus sont gardés ; une ancienne sauvegarde ne rejoue rien.
	var state := ExecutiveManager.get_state()
	ExecutiveManager.load_state(state)
	if not ExecutiveManager.moment_seen("FIRST_LAUNCH") or ExecutiveManager.moments_migration_pending:
		return "J3: seen moments were lost by save/load"
	state.erase("moments_seen")
	ExecutiveManager.load_state(state)
	ArchitectureManager.owned = ["A4", "A8"]
	if not ExecutiveManager.moments_migration_pending or MOMENTS.next_unseen() != "" or not ExecutiveManager.moment_seen("NEW_ARCHITECTURE"):
		return "J3: loading an old save must silently mark past moments as seen"
	# La carte : pause pendant le moment, même vitesse ensuite.
	var card: ColorRect = (load("res://ui/components/MomentCard.gd") as Script).new() as ColorRect
	host.add_child(card)
	card.size = Vector2(1616, 720)
	TimeManager.time_scale = 2.0
	if not bool(card.call("show_moment", "FIRST_CONTRACT")) or not card.visible or TimeManager.time_scale != 0.0:
		card.queue_free()
		return "J3: the moment card must show and pause the game"
	card.call("close")
	var ok := not card.visible and TimeManager.time_scale == 2.0
	card.queue_free()
	if not ok:
		return "J3: closing the moment card must resume at the same speed"
	return ""
