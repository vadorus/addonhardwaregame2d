extends CanvasLayer
## T3 — Infobulles au toucher : 450 ms, sans altérer les clics courts.
## Les infobulles restent lisibles brièvement après le relâchement.
signal tooltip_opened(message: String)

const HOLD_SECONDS := 0.45
const MOVE_CANCEL := 16.0
const READ_SECONDS := 3.0

var force_mobile := false
var _active: Control
var _press_position := Vector2.ZERO
var _generation := 0
var _was_shown := false
var _temporarily_disabled: BaseButton
var _bubble: PanelContainer
var _description: Label

func _ready() -> void:
	layer = 190
	_bubble = PanelContainer.new()
	_bubble.visible = false
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("2e2418")
	background.border_color = Color("e5d4ba")
	background.set_border_width_all(2)
	background.set_corner_radius_all(12)
	background.set_content_margin_all(16)
	_bubble.add_theme_stylebox_override("panel", background)
	add_child(_bubble)
	_description = Label.new()
	_description.add_theme_color_override("font_color", Color("fffaf1"))
	_description.add_theme_font_size_override("font_size", 19)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_description)

func register(control: Control) -> void:
	if control == null or control.has_meta("_t3_touch_tooltip_registered"):
		return
	control.set_meta("_t3_touch_tooltip_registered", true)
	control.gui_input.connect(_on_control_input.bind(control))

func _on_control_input(event: InputEvent, control: Control) -> void:
	if not force_mobile and not OS.has_feature("mobile"):
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_arm(control, control.get_global_transform_with_canvas() * touch.position)
		elif _active == control:
			_release()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_arm(control, control.get_global_transform_with_canvas() * mouse.position)
		elif _active == control:
			_release()
	elif event is InputEventScreenDrag and _active == control:
		var drag := event as InputEventScreenDrag
		_check_movement(control.get_global_transform_with_canvas() * drag.position)
	elif event is InputEventMouseMotion and _active == control:
		var motion := event as InputEventMouseMotion
		_check_movement(control.get_global_transform_with_canvas() * motion.position)

func _arm(control: Control, at: Vector2) -> void:
	if not is_instance_valid(control) or control.tooltip_text.strip_edges().is_empty():
		return
	if _active == control:
		return # Les événements tactiles et souris peuvent être émis ensemble.
	_cancel()
	_hide_bubble()
	_active = control
	_press_position = at
	_was_shown = false
	_generation += 1
	var ticket := _generation
	get_tree().create_timer(HOLD_SECONDS, true, false, true).timeout.connect(_open_if_still_pressed.bind(ticket), CONNECT_ONE_SHOT)

func _check_movement(at: Vector2) -> void:
	if at.distance_to(_press_position) > MOVE_CANCEL:
		_cancel()
		_hide_bubble()

func _open_if_still_pressed(ticket: int) -> void:
	if ticket != _generation or not is_instance_valid(_active):
		return
	if not _active.is_visible_in_tree() or _active.tooltip_text.strip_edges().is_empty():
		_cancel()
		return
	var control := _active
	_was_shown = true
	_show_bubble(control.tooltip_text, _press_position)
	# Empêcher qu'un appui long sur une décision déclenche sa confirmation au relâchement.
	if control is BaseButton and not (control as BaseButton).disabled:
		_temporarily_disabled = control as BaseButton
		_temporarily_disabled.disabled = true

func _show_bubble(message: String, at: Vector2) -> void:
	var canvas_size := get_viewport().get_visible_rect().size
	_description.text = message
	_bubble.custom_minimum_size.x = minf(420.0, maxf(180.0, canvas_size.x - 32.0))
	_description.custom_minimum_size.x = _bubble.custom_minimum_size.x - 36.0
	_bubble.visible = true
	_bubble.reset_size()
	var size_hint := _bubble.get_combined_minimum_size()
	_bubble.size = size_hint
	var desired := at + Vector2(18.0, 22.0)
	if desired.y + size_hint.y > canvas_size.y - 12.0:
		desired.y = at.y - size_hint.y - 18.0
	_bubble.position = Vector2(
		clampf(desired.x, 12.0, maxf(12.0, canvas_size.x - size_hint.x - 12.0)),
		clampf(desired.y, 12.0, maxf(12.0, canvas_size.y - size_hint.y - 12.0)))
	tooltip_opened.emit(message)

func _release() -> void:
	var held := _was_shown
	_cancel()
	if held:
		var ticket := _generation
		get_tree().create_timer(READ_SECONDS, true, false, true).timeout.connect(_hide_after_reading.bind(ticket), CONNECT_ONE_SHOT)
	else:
		_hide_bubble()

func _cancel() -> void:
	_generation += 1
	_active = null
	_was_shown = false
	if is_instance_valid(_temporarily_disabled):
		_temporarily_disabled.set_deferred("disabled", false)
	_temporarily_disabled = null

func _hide_after_reading(ticket: int) -> void:
	if ticket == _generation:
		_hide_bubble()

func _hide_bubble() -> void:
	if _bubble != null:
		_bubble.visible = false

func _input(event: InputEvent) -> void:
	if _active == null:
		return
	if event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		_release()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
			_release()
	elif event is InputEventScreenDrag:
		_check_movement((event as InputEventScreenDrag).position)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_check_movement((event as InputEventMouseMotion).position)

func is_bubble_visible() -> bool:
	return _bubble != null and _bubble.visible

func bubble_text() -> String:
	return _description.text if _description != null else ""
