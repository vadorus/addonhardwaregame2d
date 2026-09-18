extends Node

const BUILD_VERSION := "0.2.12-preview.3"
const QUEUE_PATH := "user://bug_reports_queue.json"
const MAX_DESCRIPTION_LENGTH := 1200
const MAX_QUEUE_SIZE := 50
const REQUEST_TIMEOUT_SECONDS := 10.0

var _queue: Array[Dictionary] = []
var _http: HTTPRequest
var _request_in_flight := false

var _ui_root: Control
var _overlay: ColorRect
var _description: TextEdit
var _consent: CheckBox
var _submit_button: Button
var _status_label: Label
var _status_timer: Timer

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SECONDS
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_load_queue()

	if DisplayServer.get_name() != "headless":
		_build_ui()

	call_deferred("_try_send_next")

func sanitize_description(value: String) -> String:
	var clean := value.strip_edges()
	if clean.length() > MAX_DESCRIPTION_LENGTH:
		clean = clean.substr(0, MAX_DESCRIPTION_LENGTH)
	return clean

func build_report(description: String) -> Dictionary:
	var viewport_width := 0
	var viewport_height := 0
	if is_inside_tree() and get_viewport() != null:
		var viewport_size := get_viewport().get_visible_rect().size
		viewport_width = int(viewport_size.x)
		viewport_height = int(viewport_size.y)

	var version_info: Dictionary = Engine.get_version_info()
	return {
		"id": "%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()],
		"created_unix": int(Time.get_unix_time_from_system()),
		"description": sanitize_description(description),
		"build_version": BUILD_VERSION,
		"app_name": str(ProjectSettings.get_setting("application/config/name", "Tech Empire")),
		"godot_version": str(version_info.get("string", "unknown")),
		"platform": OS.get_name(),
		"viewport": {
			"width": viewport_width,
			"height": viewport_height,
		},
	}

func queue_report(description: String) -> bool:
	var clean := sanitize_description(description)
	if clean.length() < 3:
		return false

	_queue.append(build_report(clean))
	while _queue.size() > MAX_QUEUE_SIZE:
		_queue.pop_front()
	_save_queue()
	_try_send_next()
	return true

func pending_count() -> int:
	return _queue.size()

func _endpoint() -> String:
	return str(ProjectSettings.get_setting("bug_reporting/endpoint", "")).strip_edges()

func _try_send_next() -> void:
	if _request_in_flight or _queue.is_empty():
		return

	var endpoint := _endpoint()
	if endpoint.is_empty():
		return

	var headers := PackedStringArray(["Content-Type: application/json"])
	var error := _http.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(_queue[0]))
	if error == OK:
		_request_in_flight = true
	else:
		_set_status("Rapport gardé hors-ligne")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_request_in_flight = false
	var delivered := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
	if delivered and not _queue.is_empty():
		_queue.pop_front()
		_save_queue()
		_set_status("Rapport envoyé • merci")
		call_deferred("_try_send_next")
	else:
		_set_status("Rapport gardé hors-ligne")

func _load_queue() -> void:
	_queue.clear()
	if not FileAccess.file_exists(QUEUE_PATH):
		return

	var file := FileAccess.open(QUEUE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				_queue.append(item)
	while _queue.size() > MAX_QUEUE_SIZE:
		_queue.pop_front()

func _save_queue() -> void:
	var file := FileAccess.open(QUEUE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_queue))

func _build_ui() -> void:
	_ui_root = Control.new()
	_ui_root.name = "BugReporterUI"
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_sync_ui_size)

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	layer.add_child(_ui_root)

	var report_button := Button.new()
	report_button.text = "Signaler un bug"
	report_button.custom_minimum_size = Vector2(156, 42)
	report_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	report_button.offset_left = -168.0
	report_button.offset_top = -54.0
	report_button.offset_right = -12.0
	report_button.offset_bottom = -12.0
	report_button.mouse_filter = Control.MOUSE_FILTER_STOP
	report_button.pressed.connect(_open_reporter)
	_ui_root.add_child(report_button)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_status_label.offset_left = -340.0
	_status_label.offset_top = -82.0
	_status_label.offset_right = -12.0
	_status_label.offset_bottom = -58.0
	_status_label.visible = false
	_ui_root.add_child(_status_label)

	_status_timer = Timer.new()
	_status_timer.one_shot = true
	_status_timer.wait_time = 4.0
	_status_timer.timeout.connect(func(): _status_label.visible = false)
	add_child(_status_timer)

	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	_ui_root.add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 420)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Signaler un bug"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	var privacy := Label.new()
	privacy.text = "Décris ce qui s’est passé. Seuls ton texte et des diagnostics techniques minimaux sont enregistrés. Aucune sauvegarde, aucun nom de société et aucune adresse IP ne sont collectés par le jeu."
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(privacy)

	_description = TextEdit.new()
	_description.placeholder_text = "Exemple : après avoir lancé le modèle Apex, le bouton…"
	_description.custom_minimum_size.y = 180
	_description.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_description.text_changed.connect(_update_submit_state)
	box.add_child(_description)

	_consent = CheckBox.new()
	_consent.text = "J’accepte d’enregistrer ce rapport et ces diagnostics techniques."
	_consent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_consent.toggled.connect(func(_enabled): _update_submit_state())
	box.add_child(_consent)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(actions)

	var cancel := Button.new()
	cancel.text = "Annuler"
	cancel.pressed.connect(_close_reporter)
	actions.add_child(cancel)

	_submit_button = Button.new()
	_submit_button.text = "Enregistrer le rapport"
	_submit_button.disabled = true
	_submit_button.pressed.connect(_submit_report)
	actions.add_child(_submit_button)

func _sync_ui_size() -> void:
	if _ui_root != null:
		_ui_root.size = get_viewport().get_visible_rect().size

func _open_reporter() -> void:
	_description.text = ""
	_consent.button_pressed = false
	_update_submit_state()
	_overlay.visible = true
	_description.grab_focus()

func _close_reporter() -> void:
	_overlay.visible = false

func _update_submit_state() -> void:
	if _submit_button == null:
		return
	_submit_button.disabled = not _consent.button_pressed or sanitize_description(_description.text).length() < 3

func _submit_report() -> void:
	if not _consent.button_pressed:
		return
	if queue_report(_description.text):
		_close_reporter()
		if _endpoint().is_empty():
			_set_status("Rapport enregistré localement")
		else:
			_set_status("Rapport mis en file d’envoi")

func _set_status(message: String) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.visible = true
	if _status_timer != null:
		_status_timer.start()
