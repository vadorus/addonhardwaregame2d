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
	_draw_people(w, h, desk_x, desk_w)
	_draw_cpu_trophies(w, h)

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
func _draw_person(pos: Vector2, shirt: Color):
	draw_circle(pos, 6.5, Color("#efc49f"))
	draw_rect(Rect2(pos + Vector2(-7, 7), Vector2(14, 22)), shirt)
	draw_line(pos + Vector2(-4, 29), pos + Vector2(-7, 42), Color("#20262b"), 3)
	draw_line(pos + Vector2(4, 29), pos + Vector2(7, 42), Color("#20262b"), 3)

func _draw_people(w: float, h: float, desk_x: float, desk_w: float):
	var count: int = int([2, 3, 4, 6, 8][stage])
	var shirts := [Color("#315f78"), Color("#6b557c"), Color("#3c785e"), Color("#8a6045")]
	for i in range(count):
		var row := i / 4
		var col := i % 4
		var px := desk_x - 46.0 + float(col) * ((desk_w + 92.0) / 3.0)
		var py := h * 0.70 + float(row) * 30.0
		if row == 0 and (col == 1 or col == 2):
			py = h * 0.55
		_draw_person(Vector2(clampf(px, 24.0, w - 24.0), py), shirts[i % shirts.size()])

func _launched_generation_indices() -> Array[int]:
	var result: Array[int] = []
	var seen := {}
	for product in ProductManager.products:
		if str(product.get("sector", "")) != "CPU" or str(product.get("status", "")) != "LAUNCHED":
			continue
		var generation := maxi(int(product.get("generation_index", 1)), 1)
		if seen.has(generation):
			continue
		seen[generation] = true
		result.append(generation)
	result.sort()
	return result

func _draw_cpu_trophies(w: float, h: float):
	var generations := _launched_generation_indices()
	if generations.is_empty():
		return
	var shown := mini(generations.size(), 5)
	var shelf_w := minf(w * 0.34, 300.0)
	var shelf_x := w * 0.58 - shelf_w * 0.5
	if stage >= 4:
		shelf_x = w * 0.43 - shelf_w * 0.5
	shelf_x = clampf(shelf_x, 190.0, maxf(190.0, w - shelf_w - 24.0))
	var shelf_y := h * 0.30
	draw_rect(Rect2(shelf_x, shelf_y + 34, shelf_w, 6), Color("#725943"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(shelf_x, shelf_y - 8), "GÉNÉRATIONS CPU", HORIZONTAL_ALIGNMENT_LEFT, shelf_w, 11, Color("#e3b766"))
	var spacing := shelf_w / float(maxi(shown, 1))
	for i in range(shown):
		var generation := generations[generations.size() - shown + i]
		var cx := shelf_x + spacing * (float(i) + 0.5)
		var chip_rect := Rect2(cx - 13, shelf_y + 4, 26, 26)
		draw_rect(chip_rect, Color("#15212a"))
		draw_rect(Rect2(chip_rect.position + Vector2(4, 4), chip_rect.size - Vector2(8, 8)), Color("#39a9b8"))
		for pin in range(3):
			var py := chip_rect.position.y + 6 + pin * 7
			draw_line(Vector2(chip_rect.position.x - 4, py), Vector2(chip_rect.position.x, py), Color("#d4b36d"), 2)
			draw_line(Vector2(chip_rect.end.x, py), Vector2(chip_rect.end.x + 4, py), Color("#d4b36d"), 2)
		draw_string(font, Vector2(cx - 12, shelf_y + 55), "G%d" % generation, HORIZONTAL_ALIGNMENT_CENTER, 24, 10, Color("#f3e7d0"))

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
