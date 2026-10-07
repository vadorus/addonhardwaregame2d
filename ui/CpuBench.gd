extends Control
## A persistent bench illustration; motion reflects running simulation only.
var state: Dictionary = {}
var _clock := 0.0
const COPPER := Color("d9a45c")
const GREEN := Color("54d6ae")

func _ready() -> void:
	custom_minimum_size = Vector2(280, 230)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(value: Dictionary) -> void:
	state = value
	queue_redraw()

func _process(delta: float) -> void:
	if is_visible_in_tree() and TimeManager.time_scale > 0.0:
		_clock += delta
		queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_style_box(_box(Color("142c31"), 18), bounds)
	var center := Vector2(size.x * 0.5, size.y * 0.47)
	var side := minf(size.x * 0.44, size.y * 0.55)
	var chip := Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	# Board traces remain attached to the same CPU throughout its lifecycle.
	for i in range(8):
		var y := chip.position.y + side * float(i + 1) / 9.0
		draw_line(Vector2(18, y), Vector2(chip.position.x - 8, y), Color("30535a"), 2)
		draw_line(Vector2(chip.end.x + 8, y), Vector2(size.x - 18, y), Color("30535a"), 2)
		for x in [chip.position.x - 10, chip.end.x]:
			draw_rect(Rect2(Vector2(x, y - 3), Vector2(10, 6)), COPPER)
		var x := chip.position.x + side * float(i + 1) / 9.0
		for pin_y in [chip.position.y - 10, chip.end.y]:
			draw_rect(Rect2(Vector2(x - 3, pin_y), Vector2(6, 10)), COPPER)
	draw_style_box(_box(Color("253d43"), 7), chip)
	var design: Dictionary = state.get("design", {})
	var cores := clampi(int(design.get("cores", 1)), 1, 16)
	var columns := ceili(sqrt(float(cores)))
	var cell := (side - 30) / float(columns)
	for i in range(cores):
		var at := chip.position + Vector2(15 + (i % columns) * cell, 15 + (i / columns) * cell)
		draw_style_box(_box(COPPER.darkened(0.2), 3), Rect2(at, Vector2.ONE * (cell - 5)))
	var stage := str(state.get("stage", "DEVELOPMENT"))
	if stage == "PRODUCTION":
		var wafer := Vector2(size.x - 44, 42)
		draw_circle(wafer, 26, Color("38596d"))
		for i in range(3):
			for j in range(3):
				draw_rect(Rect2(wafer + Vector2(i * 12 - 16, j * 12 - 16), Vector2(9, 9)), COPPER)
	var running := TimeManager.time_scale > 0.0 and stage in ["DEVELOPMENT", "PRODUCTION"]
	var light := GREEN if running else COPPER
	draw_circle(Vector2(24, 24), 4.0 + (sin(_clock * 4.0) * 1.0 if running else 0.0), light)
	var font := ThemeDB.fallback_font
	var label := "ÉQUIPE AU TRAVAIL" if running else "EN VENTE" if stage == "MARKET" else "ATELIER EN PAUSE"
	draw_string(font, Vector2(38, 29), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 50, 12, light)
	var spec := "%d cœur%s   ·   %.1f MHz   ·   %d W" % [int(design.get("cores", 1)), "s" if int(design.get("cores", 1)) > 1 else "", float(design.get("frequency_ghz", 0.0)) * 1000.0, int(design.get("tdp_w", 0))]
	draw_string(font, Vector2(18, size.y - 20), spec, HORIZONTAL_ALIGNMENT_CENTER, size.x - 36, 14, Color("e4eee8"))
	if running:
		var x := fmod(_clock * 50.0, maxf(chip.position.x - 32.0, 1.0)) + 18
		draw_circle(Vector2(x, center.y), 3, GREEN)

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box
