extends Control

var sector_id := "LAB"
var stage := 0
var company_name := "Tech Empire"

const WALLS := [
	Color("#6b5140"), Color("#7b6757"), Color("#566779"), Color("#45576a"), Color("#394d63")
]
const FLOORS := [
	Color("#3b3028"), Color("#51463c"), Color("#39434c"), Color("#303b46"), Color("#273440")
]
const WARM := Color("#ffbc64")
const CYAN := Color("#52d7e8")
const GREEN := Color("#66dda4")
const STEEL := Color("#aebdca")

func _ready() -> void:
	custom_minimum_size = Vector2(320, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_state(new_sector_id: String, new_stage: int, new_company_name: String = "Tech Empire") -> void:
	sector_id = new_sector_id
	stage = clampi(new_stage, 0, 4)
	company_name = new_company_name
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, WALLS[stage])
	var floor_y := size.y * 0.67
	draw_rect(Rect2(0, floor_y, size.x, size.y - floor_y), FLOORS[stage])
	_draw_window()
	_draw_light()
	_draw_room_label()
	match sector_id:
		"LAB": _draw_lab(floor_y)
		"PRODUCTION": _draw_production(floor_y)
		"MARKET": _draw_market(floor_y)
		"TEAM": _draw_team(floor_y)
func _draw_window() -> void:
	if stage < 2:
		return
	var w := Rect2(size.x * 0.70, 18, size.x * 0.23, size.y * 0.42)
	draw_rect(w, Color("#a8d7f0"))
	draw_line(Vector2(w.position.x + w.size.x * 0.5, w.position.y), Vector2(w.position.x + w.size.x * 0.5, w.end.y), Color("#dcecf4"), 2.0)
	draw_line(Vector2(w.position.x, w.position.y + w.size.y * 0.5), Vector2(w.end.x, w.position.y + w.size.y * 0.5), Color("#dcecf4"), 2.0)

func _draw_light() -> void:
	var length := size.x * (0.28 + stage * 0.05)
	var x := size.x * 0.12
	draw_line(Vector2(x, 16), Vector2(x + length, 16), WARM, 5.0)
	if stage >= 3:
		draw_line(Vector2(size.x * 0.48, 16), Vector2(size.x * 0.70, 16), Color("#e9f5ff"), 4.0)

func _draw_room_label() -> void:
	var font := ThemeDB.fallback_font
	var text := company_name.to_upper()
	draw_string(font, Vector2(16, 38), text, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.42, 14, Color(1,1,1,0.90))

func _draw_desk(pos: Vector2, width: float = 76.0) -> void:
	draw_rect(Rect2(pos, Vector2(width, 9)), Color("#9a724e"))
	draw_rect(Rect2(pos + Vector2(7, 9), Vector2(6, 31)), Color("#41362e"))
	draw_rect(Rect2(pos + Vector2(width - 13, 9), Vector2(6, 31)), Color("#41362e"))
	draw_rect(Rect2(pos + Vector2(width * 0.30, -34), Vector2(width * 0.42, 29)), Color("#19232f"))
	draw_rect(Rect2(pos + Vector2(width * 0.34, -30), Vector2(width * 0.34, 20)), Color("#2f92b8"))

func _draw_plant(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(18, 18)), Color("#9c6b43"))
	for offset in [-8.0, 0.0, 8.0]:
		draw_circle(pos + Vector2(9 + offset * 0.2, -4 - abs(offset) * 0.25), 8, GREEN)

func _draw_person(pos: Vector2) -> void:
	draw_circle(pos, 7, Color("#f2c49a"))
	draw_rect(Rect2(pos + Vector2(-7, 7), Vector2(14, 24)), Color("#294b68"))
func _draw_lab(floor_y: float) -> void:
	var desks := mini(1 + stage, 4)
	for i in range(desks):
		_draw_desk(Vector2(22 + i * 82, floor_y - 12), 70)
	if stage >= 1:
		draw_rect(Rect2(size.x * 0.52, floor_y - 58, 42, 42), Color("#dce7ed"))
		draw_circle(Vector2(size.x * 0.52 + 21, floor_y - 37), 10, CYAN)
	if stage >= 2:
		_draw_person(Vector2(size.x * 0.34, floor_y - 38))
	if stage >= 3:
		_draw_plant(Vector2(size.x * 0.61, floor_y - 18))

func _draw_production(floor_y: float) -> void:
	var line_y := floor_y - 22
	draw_rect(Rect2(20, line_y, size.x - 40, 16), Color("#59636a"))
	for i in range(2 + stage):
		var x := 32.0 + i * ((size.x - 72.0) / float(2 + stage))
		draw_rect(Rect2(x, line_y - 18, 24, 18), Color("#c88c3c"))
	if stage >= 2:
		for i in range(stage - 1):
			var rx := size.x * 0.58 + i * 38
			draw_line(Vector2(rx, line_y - 52), Vector2(rx, line_y - 6), WARM, 5.0)
			draw_line(Vector2(rx, line_y - 52), Vector2(rx + 24, line_y - 34), WARM, 4.0)

func _draw_market(floor_y: float) -> void:
	_draw_desk(Vector2(28, floor_y - 12), 86)
	if stage >= 1:
		_draw_desk(Vector2(124, floor_y - 12), 76)
	if stage >= 2:
		_draw_person(Vector2(80, floor_y - 39))
		_draw_person(Vector2(170, floor_y - 39))
	if stage >= 3:
		draw_rect(Rect2(size.x * 0.58, 48, size.x * 0.30, 54), Color("#15283b"))
		draw_line(Vector2(size.x * 0.61, 88), Vector2(size.x * 0.67, 76), GREEN, 4.0)
		draw_line(Vector2(size.x * 0.67, 76), Vector2(size.x * 0.73, 80), GREEN, 4.0)
		draw_line(Vector2(size.x * 0.73, 80), Vector2(size.x * 0.84, 57), GREEN, 4.0)

func _draw_team(floor_y: float) -> void:
	var people := mini(1 + stage * 2, 8)
	for i in range(people):
		var col := i % 4
		var row := i / 4
		_draw_person(Vector2(54 + col * 54, floor_y - 42 - row * 42))
	if stage >= 2:
		_draw_desk(Vector2(size.x * 0.60, floor_y - 12), 88)
	if stage >= 3:
		_draw_plant(Vector2(size.x * 0.84, floor_y - 18))