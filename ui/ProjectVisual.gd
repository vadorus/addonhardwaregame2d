extends Control

const JUICE:= preload("res://ui/Juice.gd")
var data: Dictionary = {}
var _clock:= 0.0

func _ready() -> void :
	custom_minimum_size = Vector2(0, 154)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(row: Dictionary) -> void :
	data = row.duplicate(true)
	queue_redraw()

func _process(delta: float) -> void :
	if not is_visible_in_tree() or JUICE.reduced_motion or bool(data.get("blocked", false)) or TimeManager.time_scale <= 0.0:
		return
	_clock += delta
	queue_redraw()

func _draw() -> void :
	var ink:= Color("304453")
	var muted:= Color("66746d")
	var accent:= Color("b9712e") if str(data.get("kind", "")) == "CPU" else Color("317c88")
	var phase:= int(data.get("phase_index", 0))
	var bg:= StyleBoxFlat.new()
	bg.bg_color = Color("f1eadc")
	bg.set_corner_radius_all(12)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	if str(data.get("kind", "")) == "CPU":
		_draw_cpu(ink, muted, accent, phase)
	else:
		_draw_software(ink, muted, accent, phase)

func _draw_cpu(ink: Color, muted: Color, accent: Color, phase: int) -> void :
	var chip_center:= Vector2(66, 64)
	for i in range(7):
		var px:= 28.0 + float(i) * 12.0
		draw_line(Vector2(px, 26), Vector2(px, 39), accent, 3)
		draw_line(Vector2(px, 89), Vector2(px, 102), accent, 3)
	for i in range(5):
		var py:= 44.0 + float(i) * 11.0
		draw_line(Vector2(18, py), Vector2(31, py), accent, 3)
		draw_line(Vector2(101, py), Vector2(114, py), accent, 3)
	var chip:= Rect2(chip_center - Vector2(36, 27), Vector2(72, 54))
	draw_rect(chip, ink)
	var cores:= maxi(int(data.get("cores", 1)), 1)
	var visible_cores:= mini(cores, 8)
	for i in range(visible_cores):
		var col:= i % 4
		var row:= i / 4
		var core:= Rect2(chip.position + Vector2(8 + col * 15, 8 + row * 19), Vector2(11, 13))
		draw_rect(core, accent if i <= phase + 1 else Color("6b777a"))

	var font:= ThemeDB.fallback_font
	var tx:= 134.0
	draw_string(font, Vector2(tx, 28), str(data.get("name", "CPU")), HORIZONTAL_ALIGNMENT_LEFT, maxf(0, size.x - tx - 14), 18, ink)
	var target:= str(data.get("target", "")).strip_edges()
	var specs:= "%d cœur%s • %.1f MHz" % [cores, "s" if cores > 1 else "", float(data.get("frequency_mhz", 0.0))]
	if int(data.get("node_nm", 0)) > 0:
		specs += " • %d nm" % int(data.get("node_nm", 0))
	if int(data.get("tdp_w", 0)) > 0:
		specs += " • %d W" % int(data.get("tdp_w", 0))
	if target != "":
		specs += " • " + target
	draw_string(font, Vector2(tx, 49), specs, HORIZONTAL_ALIGNMENT_LEFT, maxf(0, size.x - tx - 14), 12, muted)

	var state:= "VOTRE DÉCISION EST ATTENDUE • ESTIMATIONS" if bool(data.get("blocked", false)) else str(data.get("phase", "Projet")).to_upper() + " • ESTIMATIONS"
	draw_string(font, Vector2(tx, 69), state, HORIZONTAL_ALIGNMENT_LEFT, maxf(0, size.x - tx - 14), 11, accent)

	var metrics: Dictionary = data.get("metrics", {})
	var labels:= {"performance": "PERF.", "efficiency": "EFFIC.", "reliability": "FIAB.", "innovation": "INNOV."}
	var metric_width:= maxf((size.x - tx - 32.0) / 4.0, 80.0)
	for i in range(4):
		var axis: String = str(["performance", "efficiency", "reliability", "innovation"][i])
		var x:= tx + float(i) * metric_width
		var score:= clampf(float(metrics.get(axis, 50.0)), 0.0, 100.0)
		draw_string(font, Vector2(x, 92), "%s %.0f" % [str(labels[axis]), score], HORIZONTAL_ALIGNMENT_LEFT, metric_width - 8, 10, ink)
		var track:= Rect2(Vector2(x, 99), Vector2(metric_width - 10, 5))
		draw_rect(track, Color("d8d7c9"))
		draw_rect(Rect2(track.position, Vector2(track.size.x * score / 100.0, track.size.y)), accent)

	_draw_progress(tx, 121.0, accent, muted)

func _draw_software(ink: Color, muted: Color, accent: Color, phase: int) -> void :
	var origin:= Vector2(66, 60)
	var window:= Rect2(origin - Vector2(46, 31), Vector2(92, 62))
	draw_rect(window, Color("fffaf1"))
	draw_rect(Rect2(window.position, Vector2(92, 12)), ink)
	for i in range(3):
		draw_circle(window.position + Vector2(7 + i * 7, 6), 2, accent)
	for i in range(3):
		var line_y:= window.position.y + 23 + i * 12
		draw_rect(Rect2(Vector2(window.position.x + 10, line_y), Vector2(6, 6)), accent if phase >= 2 else Color("c5d0cc"))
		draw_line(Vector2(window.position.x + 23, line_y + 3), Vector2(window.end.x - 10 - i * 6, line_y + 3), accent, 2)
	var font:= ThemeDB.fallback_font
	var tx:= 134.0
	draw_string(font, Vector2(tx, 34), str(data.get("name", "Logiciel")), HORIZONTAL_ALIGNMENT_LEFT, maxf(0, size.x - tx - 14), 18, ink)
	draw_string(font, Vector2(tx, 58), str(data.get("phase", "Projet")), HORIZONTAL_ALIGNMENT_LEFT, maxf(0, size.x - tx - 14), 12, muted)
	_draw_progress(tx, 91.0, accent, muted)

func _draw_progress(tx: float, y: float, accent: Color, muted: Color) -> void :
	var font:= ThemeDB.fallback_font
	var progress:= clampf(float(data.get("progress", 0.0)), 0.0, 100.0)
	var state:= "En pause — décision requise" if bool(data.get("blocked", false)) else "Développement %.0f%%" % progress
	draw_string(font, Vector2(tx, y), state, HORIZONTAL_ALIGNMENT_LEFT, maxf(0, size.x - tx - 14), 11, muted)
	var track:= Rect2(Vector2(tx, y + 9), Vector2(maxf(0, size.x - tx - 18), 7))
	draw_rect(track, Color("d8d7c9"))
	draw_rect(Rect2(track.position, Vector2(track.size.x * progress / 100.0, 7)), accent)
	if not JUICE.reduced_motion and not bool(data.get("blocked", false)) and TimeManager.time_scale > 0.0:
		var scan_x:= track.position.x + fmod(_clock * 44.0, maxf(track.size.x, 1.0))
		draw_line(Vector2(scan_x, track.position.y - 3), Vector2(scan_x, track.end.y + 3), Color("b0c7a6"), 2)
