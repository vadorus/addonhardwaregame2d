extends Control
## The existing workstation touch target becomes a view of its real project.
const CHIP := preload("res://ui/ChipPreview.gd")
var _row: Dictionary = {}
var _design: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_project(row: Dictionary, design: Dictionary = {}) -> void:
	_row = row.duplicate(true)
	_design = design.duplicate(true)
	visible = not row.is_empty()
	queue_redraw()

func presentation_state() -> Dictionary:
	var phase := int(_row.get("phase_index", 0))
	var cpu := str(_row.get("kind", "")) == "CPU"
	var visual := "PLAN"
	if cpu:
		if phase >= 2: visual = "VALIDATION" if phase >= 5 else "PROTOTYPE"
	elif str(_row.get("phase", "")) == "Tests utilisateurs" or str(_row.get("state", "")) == "Prêt à sortir" or phase >= 2:
		visual = "TEST"
	elif phase == 1:
		visual = "BUILD"
	return {"id":str(_row.get("id", "")), "kind":str(_row.get("kind", "")),
		"progress":float(_row.get("progress", 0.0)), "blocked":bool(_row.get("blocked", false)),
		"visual":visual, "art_name":CHIP.era_art_name(int(_design.get("node_nm", 10000))) if cpu else ""}

func _draw() -> void:
	if _row.is_empty(): return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.43
	var cpu := str(_row.get("kind", "")) == "CPU"
	var ink := Color("a85a22") if cpu else Color("317c88")
	var state := presentation_state()
	var ring := Color("d9822b") if bool(state.blocked) else ink
	draw_circle(center + Vector2(1, 3), radius + 3, Color(0, 0, 0, 0.2))
	draw_circle(center, radius, Color("fffaf1"))
	draw_arc(center, radius, 0, TAU, 48, Color("e5d4ba"), 3, true)
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(state.progress) / 100.0, 0, 1), 48, ring, 3, true)
	var box := Rect2(center - Vector2.ONE * radius * 0.62, Vector2.ONE * radius * 1.24)
	if cpu and str(state.visual) != "PLAN":
		var art := CHIP.era_texture(int(_design.get("node_nm", 10000)))
		if art != null:
			var fit := minf(box.size.x / art.get_width(), box.size.y / art.get_height())
			var dimensions := art.get_size() * fit
			draw_texture_rect(art, Rect2(center - dimensions * 0.5, dimensions), false)
		else:
			draw_rect(box.grow(-3), ink)
		if str(state.visual) == "VALIDATION":
			var lens := center + Vector2(radius * 0.46, radius * 0.25)
			draw_circle(lens, 6, Color("fffaf1"))
			draw_arc(lens, 4, 0, TAU, 16, ink, 1.5, true)
			draw_line(lens + Vector2(3, 3), lens + Vector2(7, 7), ink, 2)
	elif str(state.visual) == "PLAN":
		draw_rect(box, Color("e0ece8"))
		draw_rect(box, ink, false, 1.5)
		for index in range(1, 4):
			var offset := float(index) / 4.0
			draw_line(box.position + Vector2(box.size.x * offset, 0), box.position + Vector2(box.size.x * offset, box.size.y), Color("bdd0c8"), 1)
			draw_line(box.position + Vector2(0, box.size.y * offset), box.position + Vector2(box.size.x, box.size.y * offset), Color("bdd0c8"), 1)
		draw_rect(box.grow(-box.size.x * 0.25), ink, false, 2)
	else:
		draw_rect(box, ink)
		var screen := box.grow(-3)
		draw_rect(screen, Color("edf4ed"))
		draw_rect(Rect2(screen.position, Vector2(screen.size.x, 5)), ink)
		for index in range(3):
			var y := screen.position.y + 10 + float(index) * 5
			if str(state.visual) == "TEST":
				draw_line(Vector2(screen.position.x + 3, y), Vector2(screen.position.x + 5, y + 2), ink, 1.5)
				draw_line(Vector2(screen.position.x + 5, y + 2), Vector2(screen.position.x + 8, y - 2), ink, 1.5)
			else:
				draw_circle(Vector2(screen.position.x + 4, y), 1.5, ink)
			draw_line(Vector2(screen.position.x + 11, y), Vector2(screen.end.x - 3, y), ink, 1.5)
	var count := int(_row.get("phase_count", 3))
	for index in range(count):
		var offset := (float(index) - float(count - 1) * 0.5) * 5
		draw_circle(center + Vector2(offset, radius * 0.77), 1.5, ink if index <= int(_row.get("phase_index", 0)) else Color("d7c7b2"))
