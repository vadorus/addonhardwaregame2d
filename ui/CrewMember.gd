extends Control
## Un membre de l'équipe dans le décor. V0.10 J2 : dessiné avec les personnages de ChatGPT
## (au poste = « bureau », debout = « réflexion », fête = « joie », coup dur = « inquiet ») ;
## le dessin vectoriel d'origine reste en secours si les images manquent.
## Assis de dos à son poste (vu en 3/4 arrière) ou debout (Nora), avec une petite
## animation : il tape, bouge la tête, respire. Toucher le personnage émet `tapped`.

signal tapped(member)

var member_id := ""
var display_name := ""
var role := ""
var department := ""
var pose := "SIT"        # SIT (de dos, au poste) ou STAND (debout, de face)
var facing := -1.0       # -1 : travaille vers la gauche, 1 : vers la droite
var working := false
var alert := false       # « ! » au-dessus de la tête : une conversation attend
var scale_px := 90.0     # hauteur du personnage en pixels
var hair := Color("3b2a1e")
var shirt := Color("c8743a")
var skin := Color("e7b48f")
var look := 0            # personnage de ChatGPT (1..12), 0 = dessin vectoriel
var mood := "normal"     # normal, joie, inquiet
var _t := 0.0
var _textures := {}
const ART := preload("res://ui/WorkplaceArt.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_t = randf() * 10.0

func setup(data: Dictionary) -> void:
	member_id = str(data.get("id", ""))
	display_name = str(data.get("name", ""))
	role = str(data.get("role", ""))
	department = str(data.get("department", ""))
	pose = str(data.get("pose", "SIT"))
	facing = float(data.get("facing", -1.0))
	var colors := palette_for(member_id if member_id != "" else display_name)
	hair = data.get("hair", colors.hair)
	shirt = data.get("shirt", colors.shirt)
	skin = colors.skin
	look = int(data.get("look", 0))
	_textures.clear()
	queue_redraw()

## Mêmes couleurs partout (garage, portrait de dialogue) pour une même personne.
static func palette_for(key: String) -> Dictionary:
	if key == "NORA":
		return {"hair":Color("5a3a2a"), "shirt":Color("3f7f8c"), "skin":Color("e7b48f")}
	var pick := absi(hash(key))
	var hairs := [Color("3b2a1e"), Color("1f1a17"), Color("7a4a26"), Color("c9a064"), Color("5a3a2a"), Color("8c8c8c")]
	var shirts := [Color("c8743a"), Color("3f7f8c"), Color("6a8f3a"), Color("8a4a7a"), Color("b8483a"), Color("4a6aa8")]
	var skins := [Color("f1c9a5"), Color("e7b48f"), Color("c68a62"), Color("8d5a3b")]
	if key.begins_with("CLIENT"):
		shirts = [Color("2f3a4a"), Color("3a3a3a"), Color("4a3a2f")]
	return {"hair":hairs[pick % hairs.size()], "shirt":shirts[(pick / 7) % shirts.size()], "skin":skins[(pick / 13) % skins.size()]}

## Pose affichée selon la situation.
func sprite_pose() -> String:
	# Client ou journaliste : il est venu vous parler, il fait le geste.
	if department == "Visiteur":
		return "parle"
	if mood == "joie":
		return "joie"
	if mood == "inquiet":
		return "inquiet"
	return "bureau" if pose == "SIT" else "reflexion"

func sprite_texture() -> Texture2D:
	if look <= 0:
		return null
	var wanted := sprite_pose()
	if not _textures.has(wanted):
		var path := ART.character_path(look, wanted)
		if not ResourceLoader.exists(path):
			path = ART.character_path(look, "reflexion")
		_textures[wanted] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[wanted]

func set_scale_px(value: float) -> void:
	scale_px = value
	var texture := sprite_texture()
	if texture != null:
		# Taille calée sur la pose « bureau » (poste complet) ; les autres poses gardent la même hauteur.
		size = Vector2(value * 1.0, value)
		pivot_offset = Vector2(size.x * 0.5, size.y)
		queue_redraw()
		return
	size = Vector2(value * 0.8, value * 1.05)
	pivot_offset = Vector2(size.x * 0.5, size.y)
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta * (2.0 if working else 1.0)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var released: bool = (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and not event.pressed)
	if released:
		tapped.emit(self)
		accept_event()

func head_position() -> Vector2:
	if sprite_texture() != null:
		var hx := 0.5
		if sprite_pose() == "bureau":
			hx = 0.62 if facing <= 0.0 else 0.38
		return position + Vector2(size.x * hx, size.y - scale_px * 0.92)
	return position + Vector2(size.x * 0.5, size.y - scale_px * (1.02 if pose == "STAND" else 0.86))

func _draw() -> void:
	var s := scale_px
	var base := Vector2(size.x * 0.5, size.y)   # sol / assise
	draw_set_transform(Vector2.ZERO)
	var texture := sprite_texture()
	if texture != null:
		_draw_sprite(texture, base, s)
	else:
		# Ombre au sol.
		_draw_ellipse(base + Vector2(0, -s * 0.02), Vector2(s * 0.30, s * 0.07), Color(0, 0, 0, 0.22))
		if pose == "STAND":
			_draw_standing(base, s)
		else:
			_draw_seated(base, s)
	if alert:
		# « ! » qui rebondit au-dessus de la tête : cette personne veut vous parler.
		var head_local := head_position() - position
		var bounce := absf(sin(_t * 3.0)) * s * 0.08
		var center := head_local + Vector2(0, -s * 0.30 - bounce)
		draw_circle(center, s * 0.13, Color("e5372c"))
		draw_arc(center, s * 0.13, 0, TAU, 24, Color.WHITE, 2.0, true)
		draw_line(center + Vector2(0, -s * 0.07), center + Vector2(0, s * 0.02), Color.WHITE, s * 0.035)
		draw_circle(center + Vector2(0, s * 0.065), s * 0.02, Color.WHITE)

func _draw_sprite(texture: Texture2D, base: Vector2, s: float) -> void:
	var tex := texture.get_size()
	var current := sprite_pose()
	# Hauteur : le poste « bureau » occupe toute la hauteur ; debout, un peu plus grand que la tête assise.
	var h := s * (1.0 if current == "bureau" else 0.95)
	var w := tex.x * h / tex.y
	var bob := 0.0
	if current == "joie":
		bob = -absf(sin(_t * 6.0)) * s * 0.06
	elif working and current == "bureau":
		bob = sin(_t * 9.0) * s * 0.004
	else:
		bob = sin(_t * 1.6) * s * 0.006
	_draw_ellipse(base + Vector2(0, -s * 0.015), Vector2(w * 0.42, s * 0.05), Color(0, 0, 0, 0.20))
	var rect := Rect2(base + Vector2(-w * 0.5, -h + bob), Vector2(w, h))
	if facing > 0.0:
		# Regarde vers la droite : image retournée.
		draw_set_transform(Vector2(base.x * 2.0, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect(texture, rect, false)
	draw_set_transform(Vector2.ZERO)

func _draw_seated(base: Vector2, s: float) -> void:
	var breathe := sin(_t * 1.6) * s * 0.008
	var type_a := sin(_t * 11.0) * s * 0.02 if working else 0.0
	var type_b := sin(_t * 11.0 + 1.7) * s * 0.02 if working else 0.0
	var waist := base + Vector2(0, -s * 0.26)
	var shoulder_y := -s * 0.66 + breathe
	# Buste (vu de dos) : trapèze arrondi.
	var torso := PackedVector2Array([
		waist + Vector2(-s * 0.17, 0), waist + Vector2(s * 0.17, 0),
		base + Vector2(s * 0.23, shoulder_y + s * 0.05), base + Vector2(s * 0.19, shoulder_y),
		base + Vector2(-s * 0.19, shoulder_y), base + Vector2(-s * 0.23, shoulder_y + s * 0.05)
	])
	draw_colored_polygon(torso, shirt)
	# Bras tendus vers le plan de travail (côté `facing`).
	var hand_dir := Vector2(facing * s * 0.30, -s * 0.30)
	var left_sh := base + Vector2(-s * 0.20, shoulder_y + s * 0.06)
	var right_sh := base + Vector2(s * 0.20, shoulder_y + s * 0.06)
	draw_line(left_sh, left_sh + hand_dir + Vector2(0, type_a), shirt.darkened(0.18), s * 0.09, true)
	draw_line(right_sh, right_sh + hand_dir + Vector2(s * 0.04 * facing, type_b), shirt.darkened(0.18), s * 0.09, true)
	draw_circle(left_sh + hand_dir + Vector2(0, type_a), s * 0.045, skin)
	draw_circle(right_sh + hand_dir + Vector2(s * 0.04 * facing, type_b), s * 0.045, skin)
	# Cou et tête (arrière de la tête : cheveux, oreilles).
	var head := base + Vector2(facing * s * 0.03, shoulder_y - s * 0.17 + (sin(_t * 0.9) * s * 0.01))
	draw_rect(Rect2(base + Vector2(-s * 0.05, shoulder_y - s * 0.07), Vector2(s * 0.10, s * 0.08)), skin.darkened(0.08))
	draw_circle(head + Vector2(-s * 0.14, s * 0.02), s * 0.035, skin)
	draw_circle(head + Vector2(s * 0.14, s * 0.02), s * 0.035, skin)
	draw_circle(head, s * 0.15, hair)
	draw_circle(head + Vector2(-s * 0.04, -s * 0.05), s * 0.05, hair.lightened(0.12))

func _draw_standing(base: Vector2, s: float) -> void:
	var breathe := sin(_t * 1.6) * s * 0.008
	# Jambes.
	draw_rect(Rect2(base + Vector2(-s * 0.11, -s * 0.42), Vector2(s * 0.09, s * 0.42)), Color("2e2a33"))
	draw_rect(Rect2(base + Vector2(s * 0.02, -s * 0.42), Vector2(s * 0.09, s * 0.42)), Color("2e2a33"))
	# Buste.
	var top := -s * 0.80 + breathe
	var torso := PackedVector2Array([
		base + Vector2(-s * 0.15, -s * 0.40), base + Vector2(s * 0.15, -s * 0.40),
		base + Vector2(s * 0.20, top + s * 0.06), base + Vector2(s * 0.15, top),
		base + Vector2(-s * 0.15, top), base + Vector2(-s * 0.20, top + s * 0.06)
	])
	draw_colored_polygon(torso, shirt)
	# Bras : l'un le long du corps, l'autre montre le tableau quand elle parle.
	var wave := sin(_t * 2.2) * s * 0.03
	draw_line(base + Vector2(-s * 0.19, top + s * 0.08), base + Vector2(-s * 0.24, -s * 0.44), shirt.darkened(0.18), s * 0.08, true)
	draw_line(base + Vector2(s * 0.19, top + s * 0.08), base + Vector2(s * 0.34, top - s * 0.02 + wave), shirt.darkened(0.18), s * 0.08, true)
	draw_circle(base + Vector2(s * 0.34, top - s * 0.02 + wave), s * 0.04, skin)
	# Tête de face : visage, cheveux, yeux.
	var head := base + Vector2(0, top - s * 0.17)
	draw_rect(Rect2(base + Vector2(-s * 0.045, top - s * 0.06), Vector2(s * 0.09, s * 0.07)), skin.darkened(0.08))
	draw_circle(head, s * 0.15, skin)
	draw_arc(head, s * 0.15, PI * 1.05, PI * 1.95, 24, hair, s * 0.10, true)
	draw_circle(head + Vector2(-s * 0.13, s * 0.02), s * 0.05, hair)
	draw_circle(head + Vector2(s * 0.13, s * 0.02), s * 0.05, hair)
	var blink := fmod(_t, 4.0) > 3.85
	for side in [-1.0, 1.0]:
		var eye := head + Vector2(side * s * 0.055, s * 0.01)
		if blink:
			draw_line(eye + Vector2(-s * 0.02, 0), eye + Vector2(s * 0.02, 0), Color("2e2418"), 1.5)
		else:
			draw_circle(eye, s * 0.018, Color("2e2418"))
	draw_arc(head + Vector2(0, s * 0.06), s * 0.045, PI * 0.15, PI * 0.85, 10, Color("8a4a3a"), 1.5, true)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, color)
