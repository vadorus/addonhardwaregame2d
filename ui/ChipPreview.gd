extends Control

var _progress := 0.0
var _launched := false

const CHIP_CASE := Color(0.157, 0.220, 0.282, 1.0)
const CHIP_SUBSTRATE := Color(0.055, 0.204, 0.176, 1.0)
const CHIP_CORE := Color(0.325, 0.725, 0.612, 1.0)
const CHIP_CORE_ALT := Color(0.255, 0.616, 0.533, 1.0)
const CHIP_GOLD := Color(1.000, 0.741, 0.353, 1.0)
const CHIP_CYAN := Color(0.306, 0.843, 0.910, 1.0)
const CHIP_TRACK := Color(0.149, 0.212, 0.290, 1.0)

func _ready() -> void:
	custom_minimum_size = Vector2(175, 175)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_progress(value: float, launched: bool = false) -> void:
	_progress = clampf(value, 0.0, 100.0)
	_launched = launched
	queue_redraw()

func _draw() -> void:
	var side: float = minf(size.x, size.y) * 0.58
	var origin := (size - Vector2(side, side)) * 0.5
	var chip_rect := Rect2(origin, Vector2(side, side))
	var shadow_rect := Rect2(origin + Vector2(6.0, 8.0), Vector2(side, side))
	draw_rect(shadow_rect, Color(0.0, 0.0, 0.0, 0.30), true)

	var pin_count := 8
	for i in range(pin_count):
		var offset: float = side * (float(i) + 0.5) / float(pin_count)
		var horizontal_y: float = origin.y + offset
		var vertical_x: float = origin.x + offset
		draw_line(Vector2(origin.x - 10.0, horizontal_y), Vector2(origin.x, horizontal_y), CHIP_GOLD, 3.0)
		draw_line(Vector2(origin.x + side, horizontal_y), Vector2(origin.x + side + 10.0, horizontal_y), CHIP_GOLD, 3.0)
		draw_line(Vector2(vertical_x, origin.y - 10.0), Vector2(vertical_x, origin.y), CHIP_GOLD, 3.0)
		draw_line(Vector2(vertical_x, origin.y + side), Vector2(vertical_x, origin.y + side + 10.0), CHIP_GOLD, 3.0)

	draw_rect(chip_rect, CHIP_CASE, true)
	draw_rect(chip_rect, CHIP_GOLD, false, 4.0)
	var substrate := chip_rect.grow(-12.0)
	draw_rect(substrate, CHIP_SUBSTRATE, true)

	var gap := 5.0
	var columns := 4
	var rows := 2
	var core_width: float = (substrate.size.x - gap * float(columns + 1)) / float(columns)
	var core_height: float = (substrate.size.y - gap * float(rows + 1)) / float(rows)
	for row in range(rows):
		for column in range(columns):
			var core_origin := substrate.position + Vector2(
				gap + float(column) * (core_width + gap),
				gap + float(row) * (core_height + gap)
			)
			var core_color := CHIP_CORE if (row + column) % 2 == 0 else CHIP_CORE_ALT
			draw_rect(Rect2(core_origin, Vector2(core_width, core_height)), core_color, true)

	var center := chip_rect.get_center()
	var ring_radius: float = side * 0.68
	draw_arc(center, ring_radius, -PI * 0.5, PI * 1.5, 64, CHIP_TRACK, 4.0, true)
	var end_angle: float = -PI * 0.5 + TAU * _progress / 100.0
	draw_arc(center, ring_radius, -PI * 0.5, end_angle, 64, CHIP_CYAN if not _launched else CHIP_GOLD, 4.0, true)
