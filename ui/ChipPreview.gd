extends Control

var _progress := 0.0
var _launched := false
var _cores := 1
var _node_nm := 10000
var _tdp_w := 2

const CHIP_CASE := Color(0.157, 0.220, 0.282, 1.0)
const CHIP_SUBSTRATE_COOL := Color(0.055, 0.204, 0.176, 1.0)
const CHIP_SUBSTRATE_HOT := Color(0.420, 0.160, 0.090, 1.0)
const CHIP_CORE := Color(0.325, 0.725, 0.612, 1.0)
const CHIP_CORE_ALT := Color(0.255, 0.616, 0.533, 1.0)
const CHIP_ADVANCED := Color(0.306, 0.843, 0.910, 1.0)
const CHIP_GOLD := Color(1.000, 0.741, 0.353, 1.0)
const CHIP_CYAN := Color(0.306, 0.843, 0.910, 1.0)
const CHIP_TRACK := Color(0.149, 0.212, 0.290, 1.0)

## V0.10 / J3 : puces peintes par Astra, une par époque (déduite de la finesse de gravure).
const ART_DIR := "res://assets/art/v010/puces/"
## Finesse de gravure minimale de chaque époque : 10–6 µm (1971), 3–1,5 µm (1978), 1 µm–800 nm (1985),
## 600–350 nm (1993), 250–180 nm (1999), 130 nm et moins (2004).
const ERAS := [[6000, "puce_1971"], [1500, "puce_1978"], [800, "puce_1985"], [350, "puce_1993"], [180, "puce_1999"], [0, "puce_2004"]]
static var _art_cache := {}

static func era_art_name(node_nm: int) -> String:
	for era in ERAS:
		if node_nm >= int(era[0]):
			return str(era[1])
	return "puce_2004"

static func era_texture(node_nm: int) -> Texture2D:
	var art_name := era_art_name(node_nm)
	if not _art_cache.has(art_name):
		var path := ART_DIR + art_name + ".png"
		_art_cache[art_name] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _art_cache[art_name]

func _ready() -> void:
	custom_minimum_size = Vector2(175, 175)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_progress(value: float, launched: bool = false) -> void:
	_progress = clampf(value, 0.0, 100.0)
	_launched = launched
	queue_redraw()

func set_design(design: Dictionary, progress: float = 0.0, launched: bool = false) -> void:
	_cores = clampi(int(design.get("cores", 1)), 1, 64)
	_node_nm = clampi(int(design.get("node_nm", 10000)), 3, 10000)
	_tdp_w = clampi(int(design.get("tdp_w", 2)), 1, 400)
	set_progress(progress, launched)

func _draw() -> void:
	var art := era_texture(_node_nm)
	if art != null:
		_draw_art(art)
		return
	var side: float = minf(size.x, size.y) * 0.58
	var origin := (size - Vector2(side, side)) * 0.5
	var chip_rect := Rect2(origin, Vector2(side, side))
	var shadow_rect := Rect2(origin + Vector2(6.0, 8.0), Vector2(side, side))
	draw_rect(shadow_rect, Color(0.0, 0.0, 0.0, 0.30), true)

	var pin_count := clampi(6 + int(ceil(float(_cores) / 4.0)), 8, 14)
	for i in range(pin_count):
		var offset: float = side * (float(i) + 0.5) / float(pin_count)
		var horizontal_y: float = origin.y + offset
		var vertical_x: float = origin.x + offset
		draw_line(Vector2(origin.x - 10.0, horizontal_y), Vector2(origin.x, horizontal_y), CHIP_GOLD, 3.0)
		draw_line(Vector2(origin.x + side, horizontal_y), Vector2(origin.x + side + 10.0, horizontal_y), CHIP_GOLD, 3.0)
		draw_line(Vector2(vertical_x, origin.y - 10.0), Vector2(vertical_x, origin.y), CHIP_GOLD, 3.0)
		draw_line(Vector2(vertical_x, origin.y + side), Vector2(vertical_x, origin.y + side + 10.0), CHIP_GOLD, 3.0)

	draw_rect(chip_rect, CHIP_CASE, true)
	var border_color := CHIP_CYAN if _node_nm <= 180 else CHIP_GOLD
	draw_rect(chip_rect, border_color, false, 4.0)
	var substrate := chip_rect.grow(-12.0)
	var heat := clampf(remap(float(_tdp_w), 1.0, 220.0, 0.0, 1.0), 0.0, 1.0)
	draw_rect(substrate, CHIP_SUBSTRATE_COOL.lerp(CHIP_SUBSTRATE_HOT, heat * 0.72), true)

	var gap := 4.0
	var columns := int(ceil(sqrt(float(_cores))))
	var rows := int(ceil(float(_cores) / float(columns)))
	var core_width: float = (substrate.size.x - gap * float(columns + 1)) / float(columns)
	var core_height: float = (substrate.size.y - gap * float(rows + 1)) / float(rows)
	for index in range(_cores):
		var row := int(index / columns)
		var column := index % columns
		var core_origin := substrate.position + Vector2(
			gap + float(column) * (core_width + gap),
			gap + float(row) * (core_height + gap)
		)
		var core_color := CHIP_ADVANCED if _node_nm <= 180 else (CHIP_CORE if (row + column) % 2 == 0 else CHIP_CORE_ALT)
		draw_rect(Rect2(core_origin, Vector2(core_width, core_height)), core_color, true)

	var center := chip_rect.get_center()
	var ring_radius: float = side * 0.68
	draw_arc(center, ring_radius, -PI * 0.5, PI * 1.5, 64, CHIP_TRACK, 4.0, true)
	var end_angle: float = -PI * 0.5 + TAU * _progress / 100.0
	draw_arc(center, ring_radius, -PI * 0.5, end_angle, 64, CHIP_GOLD if _launched else CHIP_CYAN, 4.0, true)

func _draw_art(art: Texture2D) -> void:
	var box := minf(size.x, size.y)
	var center := size * 0.5
	var fit := minf(box * 0.86 / art.get_width(), box * 0.86 / art.get_height())
	var draw_size := art.get_size() * fit
	# Pendant le développement, la puce « se révèle » ; lancée, elle est pleinement dorée.
	var alpha := 1.0 if _launched or _progress <= 0.0 else lerpf(0.55, 1.0, _progress / 100.0)
	draw_texture_rect(art, Rect2(center - draw_size * 0.5, draw_size), false, Color(1, 1, 1, alpha))
	if _cores > 1:
		var badge := Vector2(size.x - 30.0, 22.0)
		draw_circle(badge, 17.0, Color("d9822b"))
		draw_string(ThemeDB.fallback_font, badge + Vector2(-13.0, 5.0), "×%d" % _cores, HORIZONTAL_ALIGNMENT_CENTER, 26.0, 13, Color.WHITE)
	if _progress > 0.0 and not _launched:
		var ring_radius := box * 0.47
		draw_arc(center, ring_radius, -PI * 0.5, PI * 1.5, 64, Color(0.149, 0.212, 0.290, 0.35), 4.0, true)
		draw_arc(center, ring_radius, -PI * 0.5, -PI * 0.5 + TAU * _progress / 100.0, 64, CHIP_CYAN, 4.0, true)
