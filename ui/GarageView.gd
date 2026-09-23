extends Control

signal station_pressed(index: int)

var station_buttons: Array[Button] = []
var station_labels: Array[Label] = []
var staff_count := 1
var can_recruit := false
var founder_name := "Alex"
var portrait_style := 0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 260)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in range(3):
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", _station_style(Color(0.05, 0.09, 0.10, 0.08)))
		button.add_theme_stylebox_override("hover", _station_style(Color(0.20, 0.30, 0.27, 0.28)))
		button.add_theme_stylebox_override("pressed", _station_style(Color(0.35, 0.38, 0.25, 0.36)))
		button.pressed.connect(_station_clicked.bind(index))
		add_child(button)
		station_buttons.append(button)
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.94, 0.91, 0.80))
		button.add_child(label)
		station_labels.append(label)
	resized.connect(_layout_stations)
	_layout_stations()
	set_occupancy(1, false)

func _station_style(tint: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.border_color = Color(0.85, 0.64, 0.30, 0.46)
	style.set_border_width_all(1)
	style.set_corner_radius_all(11)
	return style

func _station_clicked(index: int) -> void:
	station_pressed.emit(index)

func set_founder(name: String, style: int) -> void:
	founder_name = name
	portrait_style = clampi(style, 0, 2)
	if not station_labels.is_empty():
		station_labels[0].text = "%s • TOUCHER POUR AGIR" % founder_name.to_upper()
	queue_redraw()

func set_occupancy(count: int, recruit_unlocked: bool) -> void:
	staff_count = clampi(count, 1, 3)
	can_recruit = recruit_unlocked
	if station_labels.is_empty():
		return
	station_labels[0].text = "%s • TOUCHER POUR AGIR" % founder_name.to_upper()
	station_labels[1].text = "ÉLISE • ÉLECTRONIQUE" if staff_count >= 2 else ("POSTE LIBRE • recruter" if can_recruit else "POSTE LIBRE • à débloquer")
	station_labels[2].text = "ÉQUIPE • poste occupé" if staff_count >= 3 else "POSTE LIBRE • prochain agrandissement"
	queue_redraw()

func _layout_stations() -> void:
	if station_buttons.is_empty():
		return
	var gap := clampf(size.x * 0.025, 8.0, 32.0)
	var station_width := maxf((size.x - 28.0 - gap * 2.0) / 3.0, 90.0)
	for index in range(3):
		var button := station_buttons[index]
		button.position = Vector2(14.0 + float(index) * (station_width + gap), 38.0)
		button.size = Vector2(station_width, maxf(size.y - 46.0, 120.0))
		station_labels[index].position = Vector2(3.0, button.size.y - 42.0)
		station_labels[index].size = Vector2(button.size.x - 6.0, 36.0)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.13, 0.11, 0.09))
	draw_rect(Rect2(0.0, h * 0.55, w, h * 0.45), Color(0.24, 0.18, 0.12))
	draw_line(Vector2(0.0, h * 0.55), Vector2(w, h * 0.55), Color(0.72, 0.54, 0.28), 2.0)
	for beam in range(1, 6):
		var yy := h * (0.55 + float(beam) * 0.075)
		draw_line(Vector2(0.0, yy), Vector2(w, yy), Color(0.37, 0.27, 0.17, 0.6), 1.0)
	for pane in range(3):
		var x := w * (0.10 + float(pane) * 0.11)
		draw_rect(Rect2(x, 15.0, w * 0.085, h * 0.27), Color(0.47, 0.58, 0.51, 0.55))
		draw_line(Vector2(x + w * 0.0425, 15.0), Vector2(x + w * 0.0425, 15.0 + h * 0.27), Color(0.22, 0.16, 0.11), 4.0)
		draw_rect(Rect2(x, 15.0, w * 0.085, h * 0.27), Color(0.61, 0.42, 0.21, 0.8), false, 5.0)
	draw_rect(Rect2(14.0, 8.0, minf(w * 0.43, 370.0), 26.0), Color(0.25, 0.19, 0.12))
	for index in range(3):
		var area := station_buttons[index].get_rect()
		var center := area.get_center().x
		var desk_y := minf(h * 0.69, area.end.y - 54.0)
		var desk_width := minf(area.size.x * 0.68, 210.0)
		draw_rect(Rect2(center - desk_width * 0.5, desk_y, desk_width, 15.0), Color(0.51, 0.32, 0.18))
		draw_rect(Rect2(center - desk_width * 0.43, desk_y + 15.0, 9.0, 27.0), Color(0.31, 0.21, 0.13))
		draw_rect(Rect2(center + desk_width * 0.40, desk_y + 15.0, 9.0, 27.0), Color(0.31, 0.21, 0.13))
		draw_rect(Rect2(center - 20.0, desk_y - 32.0, 40.0, 30.0), Color(0.08, 0.15, 0.18))
		draw_rect(Rect2(center - 16.0, desk_y - 28.0, 32.0, 22.0), Color(0.25, 0.77, 0.76) if index < staff_count else Color(0.09, 0.12, 0.12))
		draw_rect(Rect2(center - 2.0, desk_y - 2.0, 4.0, 8.0), Color(0.12, 0.14, 0.14))
		if index < staff_count:
			draw_circle(Vector2(center, desk_y - 51.0), 14.0, Color(0.89, 0.67, 0.48))
			var coats := [Color(0.22, 0.57, 0.61), Color(0.67, 0.38, 0.20), Color(0.38, 0.40, 0.66)]
			var coat: Color = coats[portrait_style] if index == 0 else Color(0.62, 0.40, 0.25)
			draw_rect(Rect2(center - 17.0, desk_y - 39.0, 34.0, 29.0), coat)
			draw_circle(Vector2(center - 12.0, desk_y - 19.0), 5.0, Color(0.87, 0.63, 0.46))
			draw_circle(Vector2(center + 12.0, desk_y - 19.0), 5.0, Color(0.87, 0.63, 0.46))
			draw_arc(Vector2(center, desk_y - 54.0), 14.0, PI, TAU, 14, Color(0.17, 0.12, 0.10), 5.0)
		else:
			draw_rect(Rect2(center - 13.0, desk_y + 25.0, 26.0, 6.0), Color(0.36, 0.29, 0.22))
