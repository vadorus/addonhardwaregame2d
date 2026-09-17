extends Control

var stage := 0
var company_name := "Tech Empire"

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 230)
	queue_redraw()

func set_stage(value: int, name: String = "Tech Empire"):
	stage = clampi(value, 0, 4)
	company_name = name
	queue_redraw()

func _draw():
	var w := size.x
	var h := size.y
	if w <= 1.0 or h <= 1.0:
		return
	var wall_colors := [Color("#3b312b"), Color("#4a3b31"), Color("#31414c"), Color("#283945"), Color("#22333d")]
	var floor_colors := [Color("#241d19"), Color("#2a221d"), Color("#20272c"), Color("#1d252a"), Color("#182127")]
	draw_rect(Rect2(0, 0, w, h * 0.72), wall_colors[stage])
	draw_rect(Rect2(0, h * 0.72, w, h * 0.28), floor_colors[stage])
	_draw_room(w, h)
func _draw_room(w: float, h: float):
	var desk_y := h * 0.63
	var desk_w := minf(w * 0.38, 360.0)
	var desk_x := (w - desk_w) * 0.5
	var wood := Color("#8d6749") if stage < 2 else Color("#7b614d")
	draw_rect(Rect2(desk_x, desk_y, desk_w, 18), wood)
	draw_rect(Rect2(desk_x + 18, desk_y + 18, 12, h * 0.18), Color("#2c2927"))
	draw_rect(Rect2(desk_x + desk_w - 30, desk_y + 18, 12, h * 0.18), Color("#2c2927"))

	var monitor_count := 1 if stage == 0 else 2 if stage < 3 else 3
	for i in range(monitor_count):
		var mw := 70.0
		var mh := 45.0
		var mx := desk_x + desk_w * 0.5 - (monitor_count * mw + (monitor_count - 1) * 10.0) * 0.5 + i * (mw + 10.0)
		var my := desk_y - mh - 8.0
		draw_rect(Rect2(mx, my, mw, mh), Color("#11181e"), true)
		draw_rect(Rect2(mx + 5, my + 5, mw - 10, mh - 10), Color("#1e5660"), true)
		draw_rect(Rect2(mx + mw * 0.45, desk_y - 8, 7, 8), Color("#262b2f"), true)

	_draw_stage_props(w, h, desk_x, desk_w)
func _draw_stage_props(w: float, h: float, desk_x: float, desk_w: float):
	if stage == 0:
		draw_rect(Rect2(24, h * 0.55, 72, 48), Color("#8b6a45"))
		draw_rect(Rect2(w - 105, h * 0.58, 78, 42), Color("#73583d"))
		draw_line(Vector2(20, 22), Vector2(w - 20, 22), Color("#5a4a3e"), 2)
	elif stage >= 1:
		_draw_plant(Vector2(w - 68, h * 0.68))
		draw_rect(Rect2(26, 25, 135, 62), Color("#24313a"))
		draw_rect(Rect2(32, 31, 123, 50), Color("#9bb2b7"))
	if stage >= 2:
		draw_rect(Rect2(w * 0.08, h * 0.18, w * 0.18, 8), Color("#6d5847"))
		draw_circle(Vector2(w * 0.12, h * 0.15), 12, Color("#d3b06b"))
		draw_circle(Vector2(w * 0.18, h * 0.15), 12, Color("#6ea58c"))
	if stage >= 3:
		for i in range(3):
			var x := w * 0.12 + i * w * 0.16
			draw_rect(Rect2(x, h * 0.76, 80, 8), Color("#5f5147"))
	if stage >= 4:
		draw_rect(Rect2(w * 0.68, 24, w * 0.24, h * 0.43), Color("#1c2d38"))
		draw_rect(Rect2(w * 0.69, 34, w * 0.22, h * 0.39), Color("#547786"))
	_draw_sign(w)
func _draw_plant(base: Vector2):
	draw_rect(Rect2(base.x - 13, base.y - 28, 26, 28), Color("#6b4d3b"))
	draw_circle(base + Vector2(-10, -39), 12, Color("#4f8a68"))
	draw_circle(base + Vector2(5, -46), 14, Color("#5b9a72"))
	draw_circle(base + Vector2(14, -34), 10, Color("#447a5c"))

func _draw_sign(w: float):
	var font := ThemeDB.fallback_font
	var title := company_name if not company_name.is_empty() else "TECH EMPIRE"
	var stage_names := ["GARAGE", "PETIT BUREAU", "STARTUP", "GROUPE TECH", "CAMPUS"]
	draw_string(font, Vector2(24, 116), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f3e7d0"))
	draw_string(font, Vector2(24, 140), stage_names[stage], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e3b766"))
