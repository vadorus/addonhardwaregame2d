extends Control
## Portrait en buste (de face) d'un personnage, mêmes couleurs que dans le garage.
## Provisoire en attendant les portraits dessinés par Astra.

const MEMBER := preload("res://ui/CrewMember.gd")

var key := ""
var mood := "NEUTRAL"   # NEUTRAL, HAPPY, WORRIED
var _t := 0.0

func setup(person_key: String, person_mood: String = "NEUTRAL") -> void:
	key = person_key
	mood = person_mood
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(120, 132)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var colors: Dictionary = MEMBER.palette_for(key)
	var hair: Color = colors.hair
	var shirt: Color = colors.shirt
	var skin: Color = colors.skin
	var w := size.x
	var h := size.y
	# Fond : médaillon chaleureux.
	draw_circle(Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.48, Color("f6e3c6"))
	var s := minf(w, h)
	var breathe := sin(_t * 1.6) * s * 0.01
	var neck := Vector2(w * 0.5, h * 0.66 + breathe)
	# Épaules / buste.
	var shoulders := PackedVector2Array([
		Vector2(w * 0.5 - s * 0.36, h), Vector2(w * 0.5 - s * 0.33, neck.y + s * 0.10),
		Vector2(w * 0.5 - s * 0.12, neck.y), Vector2(w * 0.5 + s * 0.12, neck.y),
		Vector2(w * 0.5 + s * 0.33, neck.y + s * 0.10), Vector2(w * 0.5 + s * 0.36, h)
	])
	draw_colored_polygon(shoulders, shirt)
	if key.begins_with("CLIENT"):
		# Chemise et cravate pour les visiteurs.
		draw_colored_polygon(PackedVector2Array([neck + Vector2(-s * 0.08, 0), neck + Vector2(s * 0.08, 0), neck + Vector2(0, s * 0.16)]), Color("f4efe6"))
		draw_colored_polygon(PackedVector2Array([neck + Vector2(-s * 0.025, s * 0.03), neck + Vector2(s * 0.025, s * 0.03), neck + Vector2(0, s * 0.22)]), Color("a8342a"))
	draw_rect(Rect2(neck + Vector2(-s * 0.06, -s * 0.06), Vector2(s * 0.12, s * 0.08)), skin.darkened(0.08))
	# Tête.
	var head := Vector2(w * 0.5, h * 0.42 + breathe)
	var r := s * 0.21
	draw_circle(head, r, skin)
	draw_arc(head, r, PI * 1.02, PI * 1.98, 32, hair, r * 0.62, true)
	draw_circle(head + Vector2(-r * 0.92, r * 0.05), r * 0.30, hair)
	draw_circle(head + Vector2(r * 0.92, r * 0.05), r * 0.30, hair)
	# Yeux (clignement), sourcils selon l'humeur, bouche.
	var blink := fmod(_t + float(absi(hash(key)) % 7), 4.0) > 3.85
	var ink := Color("2e2418")
	for side in [-1.0, 1.0]:
		var eye := head + Vector2(side * r * 0.38, r * 0.02)
		if blink:
			draw_line(eye + Vector2(-r * 0.10, 0), eye + Vector2(r * 0.10, 0), ink, 2.0)
		else:
			draw_circle(eye, r * 0.09, ink)
		var brow_tilt: float = r * 0.08 * float(side) if mood == "WORRIED" else 0.0
		draw_line(eye + Vector2(-r * 0.14, -r * 0.24 - brow_tilt), eye + Vector2(r * 0.14, -r * 0.24 + brow_tilt), hair.darkened(0.2), 2.0)
	var mouth := head + Vector2(0, r * 0.45)
	match mood:
		"HAPPY":
			draw_arc(mouth + Vector2(0, -r * 0.08), r * 0.24, PI * 0.15, PI * 0.85, 16, Color("8a3a2a"), 2.5, true)
		"WORRIED":
			draw_arc(mouth + Vector2(0, r * 0.12), r * 0.20, PI * 1.2, PI * 1.8, 16, Color("8a3a2a"), 2.5, true)
		_:
			draw_line(mouth + Vector2(-r * 0.16, 0), mouth + Vector2(r * 0.16, 0), Color("8a3a2a"), 2.5)
