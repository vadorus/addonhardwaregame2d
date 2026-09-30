extends Control
## Small native icons, kept separate from the illustrated room and its text.
var kind := "chip"
var tint := Color("17ba70")
var filled := true

## V0.10 J4 — icônes dessinées par ChatGPT. Si l'image existe, elle remplace le dessin vectoriel.
const ICON_DIR := "res://assets/art/v010/J4_icones/"
const ART := {
	"home":"dock_qg", "chip":"dock_labo", "people":"dock_equipe", "box":"dock_produits",
	"chart":"dock_marche", "news":"dock_presse", "building":"dock_entreprise", "lock":"cadenas",
	"zone_etabli_cpu":"zone_etabli_cpu", "zone_banc_test":"zone_banc_test", "zone_planification":"zone_planification",
	"zone_bureau_fondateur":"zone_bureau_fondateur", "zone_stock":"zone_stock"
}
static var _cache := {}

static func art_texture(icon_kind: String) -> Texture2D:
	if not ART.has(icon_kind):
		return null
	if not _cache.has(icon_kind):
		var path := ICON_DIR + str(ART[icon_kind]) + ".png"
		_cache[icon_kind] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _cache[icon_kind]

func uses_art() -> bool:
	return art_texture(kind) != null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var s := minf(size.x, size.y)
	var center := size * 0.5
	if filled:
		draw_circle(center + Vector2(0, 3), s * 0.46, Color(0.02, 0.08, 0.14, 0.25))
		draw_circle(center, s * 0.44, Color.WHITE)
		# Avec une icône dessinée : fond crème cerclé de la couleur du repère.
		draw_circle(center, s * 0.38, Color("fff4e2") if uses_art() else tint)
		if uses_art():
			draw_arc(center, s * 0.41, 0, TAU, 32, tint, s * 0.06, true)
	var art := art_texture(kind)
	if art != null:
		_draw_art(art, center, s)
		return
	var ink := Color.WHITE if filled else tint
	var unit := s / 52.0
	draw_set_transform(center, 0.0, Vector2.ONE * unit)
	match kind:
		"screen":
			draw_rect(Rect2(-12, -10, 24, 17), ink, false, 2.5)
			draw_line(Vector2(0, 7), Vector2(0, 13), ink, 2.5)
			draw_line(Vector2(-8, 13), Vector2(8, 13), ink, 2.5)
		"flask":
			draw_polyline(PackedVector2Array([Vector2(-5,-13), Vector2(-5,-3), Vector2(-13,12), Vector2(13,12), Vector2(5,-3), Vector2(5,-13)]), ink, 2.5, true)
			draw_line(Vector2(-8,-13), Vector2(8,-13), ink, 2.5)
			draw_line(Vector2(-8,6), Vector2(8,6), ink, 2.5)
		"people":
			draw_circle(Vector2(-6,-7), 5, ink)
			draw_circle(Vector2(7,-6), 4, ink)
			draw_style_box(_round_style(ink), Rect2(-13,1,14,13))
			draw_style_box(_round_style(ink), Rect2(3,2,11,12))
		"box":
			draw_rect(Rect2(-11,-10,22,23), ink, false, 2.5)
			draw_line(Vector2(-11,-3),Vector2(11,-3),ink,2.5)
			draw_line(Vector2(0,-10),Vector2(0,2),ink,2.5)
		"chart":
			for i in range(3):
				draw_rect(Rect2(-12 + i * 9, 7 - i * 7, 6, 7 + i * 7), ink)
		"check":
			draw_polyline(PackedVector2Array([Vector2(-10,0),Vector2(-3,7),Vector2(11,-8)]),ink,3.5,true)
		"home":
			draw_polyline(PackedVector2Array([Vector2(-14,0),Vector2(0,-12),Vector2(14,0)]), ink, 2.5, true)
			draw_rect(Rect2(-9,-1,18,14), ink, false, 2.5)
			draw_rect(Rect2(-3,5,6,8), ink)
		"news":
			draw_rect(Rect2(-12,-11,24,23), ink, false, 2.5)
			draw_rect(Rect2(-8,-7,7,7), ink)
			for y in [-6, -2]:
				draw_line(Vector2(2,y),Vector2(8,y),ink,2)
			for y in [4, 8]:
				draw_line(Vector2(-8,y),Vector2(8,y),ink,2)
		"building":
			draw_rect(Rect2(-11,-12,14,25), ink, false, 2.5)
			draw_rect(Rect2(3,-3,9,16), ink, false, 2.5)
			for y in [-7, -1, 5]:
				draw_line(Vector2(-7,y),Vector2(-1,y),ink,2)
		"lock":
			draw_arc(Vector2(0,-3), 7, PI, TAU, 12, ink, 3)
			draw_rect(Rect2(-10,-3,20,15), ink)
		_:
			draw_rect(Rect2(-9,-9,18,18), ink, false, 2.5)
			draw_rect(Rect2(-4,-4,8,8), ink)
			for i in [-6,0,6]:
				draw_line(Vector2(i,-14),Vector2(i,-9),ink,2)
				draw_line(Vector2(i,9),Vector2(i,14),ink,2)
				draw_line(Vector2(-14,i),Vector2(-9,i),ink,2)
				draw_line(Vector2(9,i),Vector2(14,i),ink,2)
	draw_set_transform(Vector2.ZERO)

func _draw_art(art: Texture2D, center: Vector2, s: float) -> void:
	var box := s * (0.62 if filled else 1.0)
	var tex_size := art.get_size()
	var fit := minf(box / tex_size.x, box / tex_size.y)
	var draw_size := tex_size * fit
	draw_texture_rect(art, Rect2(center - draw_size * 0.5, draw_size), false)

func _round_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style
