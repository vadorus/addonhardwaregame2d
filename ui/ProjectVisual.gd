extends Control
## The artifact changes only with the real project phase/progress.
const JUICE := preload("res://ui/Juice.gd")
var data: Dictionary = {}
var _clock := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 94)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(row: Dictionary) -> void:
	data = row.duplicate(true)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or JUICE.reduced_motion or bool(data.get("blocked", false)) or TimeManager.time_scale <= 0.0:
		return
	_clock += delta
	queue_redraw()

func _draw() -> void:
	var ink := Color("304453")
	var accent := Color("b9712e") if str(data.get("kind", "")) == "CPU" else Color("317c88")
	var phase := int(data.get("phase_index", 0))
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("f1eadc")
	bg.set_corner_radius_all(10)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	var origin := Vector2(58, size.y * 0.5)
	if str(data.get("kind", "")) == "CPU":
		for i in range(6):
			var p := Vector2(25 + i * 12, 13)
			draw_line(p, p + Vector2(0, 12), accent, 3)
			draw_line(p + Vector2(0, 56), p + Vector2(0, 68), accent, 3)
		var chip := Rect2(origin - Vector2(40, 24), Vector2(80, 48))
		draw_rect(chip, ink)
		for i in range(6):
			var core := Rect2(chip.position + Vector2(9 + (i % 3) * 22, 8 + (i / 3) * 19), Vector2(16, 12))
			draw_rect(core, accent if i <= phase else Color("6b777a"))
	else:
		var window := Rect2(origin - Vector2(46, 31), Vector2(92, 62))
		draw_rect(window, Color("fffaf1"))
		draw_rect(Rect2(window.position, Vector2(92, 12)), ink)
		for i in range(3):
			draw_circle(window.position + Vector2(7 + i * 7, 6), 2, accent)
		for i in range(3):
			var line_y := window.position.y + 23 + i * 12
			draw_rect(Rect2(Vector2(window.position.x + 10, line_y), Vector2(6, 6)), accent if phase >= 2 else Color("c5d0cc"))
			draw_line(Vector2(window.position.x + 23, line_y + 3), Vector2(window.end.x - 10 - i * 6, line_y + 3), accent, 2)
	var font := ThemeDB.fallback_font
	var text_x := 124.0
	draw_string(font, Vector2(text_x, 31), str(data.get("phase", "Projet")), HORIZONTAL_ALIGNMENT_LEFT, maxf(0, size.x - text_x - 10), 16, ink)
	var state := "Votre choix est attendu" if bool(data.get("blocked", false)) else "L'équipe prépare le prochain jalon"
	draw_string(font, Vector2(text_x, 53), state, HORIZONTAL_ALIGNMENT_LEFT, maxf(0, size.x - text_x - 10), 12, Color("66746d"))
	var track := Rect2(Vector2(text_x, 67), Vector2(maxf(0, size.x - text_x - 18), 6))
	draw_rect(track, Color("d8d7c9"))
	draw_rect(Rect2(track.position, Vector2(track.size.x * float(data.get("progress", 0.0)) / 100.0, 6)), accent)
	if not JUICE.reduced_motion and not bool(data.get("blocked", false)) and TimeManager.time_scale > 0.0:
		var scan_x := track.position.x + fmod(_clock * 36.0, maxf(track.size.x, 1.0))
		draw_line(Vector2(scan_x, 63), Vector2(scan_x, 77), Color("b0c7a6"), 2)
