extends Control
class_name CpuGuidanceBar

var min_value := 0.0
var max_value := 1.0
var ambitious_min := 0.0
var recommended_min := 0.0
var recommended_max := 1.0
var ambitious_max := 1.0
var current_value := 0.5

func _ready() -> void:
	custom_minimum_size = Vector2(0, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(minimum: float, maximum: float, ambitious_low: float, recommended_low: float, recommended_high: float, ambitious_high: float, current: float) -> void:
	min_value = minimum
	max_value = maxf(maximum, minimum + 0.001)
	ambitious_min = clampf(ambitious_low, min_value, max_value)
	recommended_min = clampf(recommended_low, min_value, max_value)
	recommended_max = clampf(recommended_high, min_value, max_value)
	ambitious_max = clampf(ambitious_high, min_value, max_value)
	current_value = clampf(current, min_value, max_value)
	queue_redraw()

func _draw() -> void:
	var track_height := maxf(size.y - 4.0, 8.0)
	var y := (size.y - track_height) * 0.5
	var full_rect := Rect2(0.0, y, size.x, track_height)
	draw_rect(full_rect, Color(0.58, 0.18, 0.20, 0.45), true)

	var ambitious_x0 := _value_to_x(ambitious_min)
	var ambitious_x1 := _value_to_x(ambitious_max)
	draw_rect(Rect2(ambitious_x0, y, maxf(ambitious_x1 - ambitious_x0, 1.0), track_height), Color(0.85, 0.55, 0.16, 0.62), true)

	var recommended_x0 := _value_to_x(recommended_min)
	var recommended_x1 := _value_to_x(recommended_max)
	draw_rect(Rect2(recommended_x0, y, maxf(recommended_x1 - recommended_x0, 1.0), track_height), Color(0.22, 0.67, 0.43, 0.78), true)

	var marker_x := _value_to_x(current_value)
	draw_line(Vector2(marker_x, 0.0), Vector2(marker_x, size.y), Color(0.94, 0.97, 1.0, 1.0), 2.0)

func _value_to_x(value: float) -> float:
	var ratio := inverse_lerp(min_value, max_value, clampf(value, min_value, max_value))
	return ratio * size.x
