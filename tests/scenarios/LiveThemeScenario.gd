extends RefCounted
## Thème du moment (02/10) : le jeu s'habille selon la VRAIE date (Halloween en octobre, fêtes de fin d'année
## du 1er novembre au 6 janvier), sans mise à jour, et le joueur peut couper les décorations dans le menu.

const LIVE := preload("res://scripts/LiveTheme.gd")

static func run(host: Node) -> String:
	var saved_override: String = LIVE.override
	var saved_enabled: bool = LIVE.enabled
	var error := _checks(host)
	LIVE.override = saved_override
	LIVE.enabled = saved_enabled
	return error

static func _checks(host: Node) -> String:
	LIVE.override = ""
	LIVE.enabled = true
	# 1. Les dates.
	var expected := [
		[{"year":2026, "month":10, "day":2}, "HALLOWEEN"], [{"year":2026, "month":10, "day":31}, "HALLOWEEN"],
		[{"year":2026, "month":11, "day":1}, "FIN_ANNEE"], [{"year":2026, "month":12, "day":24}, "FIN_ANNEE"],
		[{"year":2027, "month":1, "day":6}, "FIN_ANNEE"], [{"year":2027, "month":1, "day":7}, ""],
		[{"year":2027, "month":6, "day":15}, ""], [{"year":2027, "month":9, "day":30}, ""]]
	for row_value in expected:
		var row: Array = row_value
		var got := LIVE.current(row[0])
		if got != str(row[1]):
			return "Live theme: %s should be '%s', got '%s'" % [str(row[0]), str(row[1]), got]
	# 2. Le réglage « Décorations du moment : non » coupe tout.
	LIVE.enabled = false
	if LIVE.current({"year":2026, "month":10, "day":2}) != "":
		return "Live theme: decorations switched off in the menu must show no theme"
	LIVE.enabled = true
	# 3. Chaque thème a son message, son petit air (qui existe), ses ampoules et ses objets au QG.
	for theme in ["HALLOWEEN", "FIN_ANNEE"]:
		if LIVE.greeting(theme) == "" or LIVE.bulb_colors(theme).size() < 3 or LIVE.hq_fetes(theme).is_empty():
			return "Live theme %s is incomplete" % theme
		if not SoundManager.has_method("play") or not str(LIVE.jingle(theme)).begins_with("fete_"):
			return "Live theme %s has no jingle" % theme
	# 4. La couche décorative : guirlande en haut et sur les côtés, invisible hors saison, jamais sous le doigt.
	var overlay := (load("res://ui/LiveThemeOverlay.gd") as Script).new() as Control
	host.add_child(overlay)
	overlay.size = Vector2(1212, 540)
	LIVE.override = "HALLOWEEN"
	overlay.call("refresh")
	var state: Dictionary = overlay.call("state")
	if not bool(state.visible) or int(state.bulbs) < 30:
		overlay.queue_free()
		return "Live theme overlay should show a garland in October (%s)" % str(state)
	if overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		overlay.queue_free()
		return "Live theme overlay must never catch the player's finger"
	LIVE.override = "FIN_ANNEE"
	overlay.call("refresh")
	if int((overlay.call("state") as Dictionary).flakes) <= 0:
		overlay.queue_free()
		return "Year-end theme should bring snow to the title screen"
	LIVE.override = "NONE"
	overlay.call("refresh")
	if overlay.visible:
		overlay.queue_free()
		return "Live theme overlay must hide outside the seasons"
	overlay.queue_free()
	# 5. Le QG : la vraie date ajoute ses objets, même quand la partie est en mai.
	SimulationManager.reset_all("CI Thème", "CPU", "STANDARD")
	TimeManager.month = 5
	var life := (load("res://ui/GarageLife.gd") as Script).new() as Control
	host.add_child(life)
	LIVE.override = "HALLOWEEN"
	life.call("refresh")
	var fetes: Array = (life.call("scene_state") as Dictionary).fetes
	if not fetes.has("HALLOWEEN"):
		life.queue_free()
		return "In October, the HQ should wear Halloween even if the game is in May (%s)" % str(fetes)
	LIVE.override = "NONE"
	life.call("refresh")
	if not ((life.call("scene_state") as Dictionary).fetes as Array).is_empty():
		life.queue_free()
		return "Outside the real seasons, a game in May has no party at the HQ"
	life.queue_free()
	return ""
