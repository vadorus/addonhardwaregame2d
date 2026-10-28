extends Control
## Thème du moment (02/10) : la couche qui habille tout le jeu selon la vraie date (voir scripts/LiveTheme.gd).
## - Guirlande lumineuse le long du haut de l'écran, avec deux retombées sur les côtés, qui scintille ;
##   orange et violet pour Halloween, multicolore pour les fêtes de fin d'année.
## - Halloween : toiles d'araignée dans les coins du haut, chauves-souris qui passent de temps en temps,
##   citrouilles sur l'écran d'accueil.
## - Fin d'année : neige et sapin sur l'écran d'accueil.
## Ne capte jamais le doigt (MOUSE_FILTER_IGNORE) et reste sous les grandes fenêtres (notes, moments clés).

const LIVE := preload("res://scripts/LiveTheme.gd")
const FETE_DIR := "res://assets/art/v010/J6_fetes/"
const BULB_SPACING := 34.0
const SAG := 14.0
const SPAN := 190.0

## Vrai quand l'écran d'accueil est affiché (neige, citrouilles, sapin) ; fourni par main.gd.
var title_visible: Callable = func() -> bool: return false
var theme_name := ""
var _time := 0.0
var _bats: Array = []
var _next_bat := 3.0
var _flakes: Array = []
var _textures := {}

func _ready() -> void:
	AnimationClock.watch_animation(self, _on_animation_tick)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 60
	refresh()

func refresh() -> void:
	theme_name = LIVE.current()
	visible = theme_name != ""
	_bats.clear()
	_flakes.clear()
	if theme_name == "FIN_ANNEE":
		var rng := RandomNumberGenerator.new()
		rng.seed = 1225
		for i in range(70):
			_flakes.append({"x":rng.randf(), "y":rng.randf(), "speed":rng.randf_range(0.03, 0.08), "size":rng.randf_range(1.4, 3.0), "phase":rng.randf() * TAU})
	queue_redraw()

## Ce que la couche montre (tests).
func state() -> Dictionary:
	return {"theme":theme_name, "visible":visible, "bulbs":garland_points().size(), "bats":_bats.size(), "flakes":_flakes.size()}

func _texture(file_name: String) -> Texture2D:
	if not _textures.has(file_name):
		var path := FETE_DIR + file_name
		_textures[file_name] = load(path) if ResourceLoader.exists(path) else null
	return _textures[file_name]

func _on_animation_tick(delta: float) -> void:
	if not is_visible_in_tree():
		return
	# Sur l'écran d'accueil (dessiné au niveau 100), les décorations passent devant ; en jeu, elles restent
	# sous les grandes fenêtres (notes, moments clés, menu).
	var wanted_z := 101 if bool(title_visible.call()) else 60
	if z_index != wanted_z:
		z_index = wanted_z
	_time += delta
	if theme_name == "HALLOWEEN":
		_next_bat -= delta
		if _next_bat <= 0.0 and _bats.size() < 3:
			var from_left := randf() < 0.5
			_bats.append({"x":-0.05 if from_left else 1.05, "dir":1.0 if from_left else -1.0, "y":randf_range(0.10, 0.45),
				"speed":randf_range(0.10, 0.18), "size":randf_range(12.0, 20.0), "phase":randf() * TAU})
			_next_bat = randf_range(7.0, 14.0)
		for i in range(_bats.size() - 1, -1, -1):
			var bat: Dictionary = _bats[i]
			bat.x = float(bat.x) + float(bat.dir) * float(bat.speed) * delta
			if float(bat.x) < -0.1 or float(bat.x) > 1.1:
				_bats.remove_at(i)
	elif theme_name == "FIN_ANNEE" and bool(title_visible.call()):
		for flake_value in _flakes:
			var flake: Dictionary = flake_value
			flake.y = float(flake.y) + float(flake.speed) * delta
			if float(flake.y) > 1.02:
				flake.y = -0.02
	queue_redraw()

## Les ampoules de la guirlande : le long du haut (arcs), puis deux retombées sur les côtés.
## Sur l'accueil, grande guirlande festonnée ; en jeu, fine et collée au bord pour ne cacher aucun texte
## du bandeau (02/10, capture : elle passait sur le nom du jeu et la trésorerie).
func garland_points() -> Array:
	var points: Array = []
	if size.x <= 0.0:
		return points
	var on_title := bool(title_visible.call())
	var sag := SAG if on_title else 5.0
	var top := 6.0 if on_title else 0.0
	var count := maxi(int(size.x / BULB_SPACING), 2)
	for i in range(count + 1):
		var x := size.x * float(i) / float(count)
		var t := fposmod(x, SPAN) / SPAN
		points.append(Vector2(x, top + sin(t * PI) * sag))
	var drop := size.y * (0.30 if on_title else 0.18)
	for k in range(1, int(drop / BULB_SPACING) + 1):
		var y := top + float(k) * BULB_SPACING
		var sway := sin(float(k) * 1.3) * (3.0 if on_title else 1.0)
		var inset := 7.0 if on_title else 3.0
		points.append(Vector2(inset + sway, y))
		points.append(Vector2(size.x - inset - sway, y))
	return points

func _draw() -> void:
	if not visible or size.x <= 0.0:
		return
	var on_title := bool(title_visible.call())
	if theme_name == "HALLOWEEN":
		if on_title:
			_draw_cobwebs()
			_draw_prop("fete_halloween_citrouilles.png", Vector2(size.x * 0.10, size.y - 6.0), size.y * 0.22)
		for bat_value in _bats:
			_draw_bat(bat_value)
	elif theme_name == "FIN_ANNEE" and on_title:
		_draw_prop("fete_noel_sapin.png", Vector2(size.x * 0.90, size.y - 4.0), size.y * 0.46)
		for flake_value in _flakes:
			var flake: Dictionary = flake_value
			var sway := sin(_time * 0.8 + float(flake.phase)) * 0.01
			draw_circle(Vector2((float(flake.x) + sway) * size.x, float(flake.y) * size.y), float(flake.size), Color(1, 1, 1, 0.85))
	_draw_garland()

func _draw_garland() -> void:
	var colors := LIVE.bulb_colors(theme_name)
	if colors.is_empty():
		return
	var wire := Color("2f3b2a") if theme_name == "FIN_ANNEE" else Color("2a1a2e")
	var points := garland_points()
	var big := bool(title_visible.call())
	var bulb := 4.6 if big else 3.4
	var halo := 10.0 if big else 6.5
	var hang := 7.0 if big else 4.0
	var top_count := maxi(int(size.x / BULB_SPACING), 2) + 1
	var line := PackedVector2Array()
	for i in range(top_count):
		line.append(points[i])
	draw_polyline(line, wire, 2.0, true)
	for i in range(points.size()):
		var p: Vector2 = points[i]
		var color: Color = colors[i % colors.size()]
		# Chaque ampoule scintille à son rythme ; un léger halo autour.
		var glow := 0.55 + 0.45 * sin(_time * 2.2 + float(i) * 1.7)
		draw_circle(p + Vector2(0, hang), halo, Color(color.r, color.g, color.b, 0.16 * glow))
		draw_rect(Rect2(p + Vector2(-1.5, 0), Vector2(3, hang - bulb + 1.0)), wire)
		draw_circle(p + Vector2(0, hang), bulb, color.lerp(Color.WHITE, 0.25 * glow) * Color(1, 1, 1, 0.55 + 0.45 * glow))

func _draw_cobwebs() -> void:
	var web := _texture("fete_halloween_toile.png")
	if web == null:
		return
	var s := clampf(size.y * 0.20, 70.0, 140.0)
	# La toile d'Astra est accrochée en haut à droite : retournée pour le coin gauche.
	draw_texture_rect(web, Rect2(Vector2(size.x - s, 0), Vector2(s, s)), false, Color(1, 1, 1, 0.80))
	draw_set_transform(Vector2(s, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect(web, Rect2(Vector2.ZERO, Vector2(s, s)), false, Color(1, 1, 1, 0.80))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_prop(file_name: String, foot: Vector2, height: float) -> void:
	var texture := _texture(file_name)
	if texture == null:
		return
	var w := height * float(texture.get_width()) / maxf(float(texture.get_height()), 1.0)
	draw_texture_rect(texture, Rect2(foot - Vector2(w * 0.5, height), Vector2(w, height)), false)

func _draw_bat(bat: Dictionary) -> void:
	var s := float(bat.size)
	var center := Vector2(float(bat.x) * size.x, float(bat.y) * size.y + sin(_time * 3.0 + float(bat.phase)) * 10.0)
	var flap := sin(_time * 14.0 + float(bat.phase))
	var color := Color("1c1220", 0.88)
	draw_circle(center, s * 0.22, color)
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			center + Vector2(side * s * 0.15, -s * 0.05),
			center + Vector2(side * s * 0.75, -s * (0.30 + 0.35 * flap)),
			center + Vector2(side * s * 1.10, s * (0.05 - 0.20 * flap)),
			center + Vector2(side * s * 0.70, s * 0.10),
			center + Vector2(side * s * 0.40, s * 0.02)])
		draw_colored_polygon(wing, color)
	# Deux petites oreilles.
	draw_colored_polygon(PackedVector2Array([center + Vector2(-s * 0.12, -s * 0.16), center + Vector2(-s * 0.06, -s * 0.34), center + Vector2(0, -s * 0.16)]), color)
	draw_colored_polygon(PackedVector2Array([center + Vector2(s * 0.12, -s * 0.16), center + Vector2(s * 0.06, -s * 0.34), center + Vector2(0, -s * 0.16)]), color)
