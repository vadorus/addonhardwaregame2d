extends Node

signal update_available(info: Dictionary)
signal update_check_finished(has_update: bool)

const BUILD_VERSION := "0.2.12-preview.5"
const REQUEST_TIMEOUT_SECONDS := 8.0

var _http: HTTPRequest
var _latest_info: Dictionary = {}
var _checking := false
var _overlay: ColorRect
var _title_label: Label
var _changelog_label: Label
var _update_button: Button
var _status_label: Label

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SECONDS
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	if DisplayServer.get_name() != "headless":
		_build_ui()
	call_deferred("check_for_updates")

func manifest_url() -> String:
	return str(ProjectSettings.get_setting("updates/manifest_url", "")).strip_edges()
func check_for_updates() -> void:
	if _checking:
		return
	var url := manifest_url()
	if url.is_empty():
		update_check_finished.emit(false)
		return
	if not url.begins_with("https://"):
		_set_status("Mise à jour désactivée : URL non sécurisée")
		update_check_finished.emit(false)
		return
	_checking = true
	var error := _http.request(url)
	if error != OK:
		_checking = false
		_set_status("Vérification impossible")
		update_check_finished.emit(false)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_checking = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		update_check_finished.emit(false)
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		update_check_finished.emit(false)
		return
	_latest_info = parsed.duplicate(true)
	var latest := str(_latest_info.get("latest_version", "")).strip_edges()
	var has_update := not latest.is_empty() and _is_newer(latest, BUILD_VERSION)
	if has_update:
		update_available.emit(_latest_info)
		_show_update(_latest_info)
	update_check_finished.emit(has_update)

func _is_newer(candidate: String, current: String) -> bool:
	var a := _version_numbers(candidate)
	var b := _version_numbers(current)
	for i in range(maxi(a.size(), b.size())):
		var av := int(a[i]) if i < a.size() else 0
		var bv := int(b[i]) if i < b.size() else 0
		if av > bv:
			return true
		if av < bv:
			return false
	return candidate.find("preview") == -1 and current.find("preview") != -1

func _version_numbers(value: String) -> Array[int]:
	var result: Array[int] = []
	var numeric := value.split("-")[0]
	for part in numeric.split("."):
		result.append(int(part) if part.is_valid_int() else 0)
	return result
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 110
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.78)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	layer.add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 330)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	_title_label = Label.new()
	_title_label.text = "Nouvelle version disponible"
	_title_label.add_theme_font_size_override("font_size", 24)
	box.add_child(_title_label)
	_changelog_label = Label.new()
	_changelog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_changelog_label.custom_minimum_size.y = 150
	box.add_child(_changelog_label)
	_status_label = Label.new()
	_status_label.visible = false
	box.add_child(_status_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(actions)
	var later := Button.new()
	later.text = "Plus tard"
	later.pressed.connect(func(): _overlay.visible = false)
	actions.add_child(later)
	_update_button = Button.new()
	_update_button.text = "Mettre à jour"
	_update_button.pressed.connect(_open_download)
	actions.add_child(_update_button)
func _show_update(info: Dictionary) -> void:
	if _overlay == null:
		return
	var latest := str(info.get("latest_version", "Nouvelle version"))
	_title_label.text = "Mise à jour disponible • %s" % latest
	var changelog := str(info.get("changelog", "Corrections et améliorations disponibles."))
	_changelog_label.text = "%s\n\nVersion installée : %s" % [changelog, BUILD_VERSION]
	_update_button.disabled = _download_url(info).is_empty()
	_overlay.visible = true

func _download_url(info: Dictionary) -> String:
	var key := "android_url" if OS.get_name() == "Android" else "windows_url"
	var url := str(info.get(key, "")).strip_edges()
	return url if url.begins_with("https://") else ""

func _open_download() -> void:
	var url := _download_url(_latest_info)
	if url.is_empty():
		_set_status("Lien de téléchargement indisponible")
		return
	OS.shell_open(url)

func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
		_status_label.visible = not text.is_empty()
