extends Control

const MENU_BACKGROUND: Texture2D = preload("res://assets/ui/runtime/menu/menu_background_1971.webp")
const GAME_LOGO: Texture2D = preload("res://assets/ui/runtime/branding/tech_empire_logo.webp")
const GAME_SCENE := "res://main.tscn"

const NAVY := Color("#081624")
const NAVY_SOFT := Color("#0d2234")
const CYAN := Color("#46c8ff")
const CYAN_SOFT := Color("#1a83b8")
const AMBER := Color("#f2bd5b")
const TEXT := Color("#f4f0e7")
const MUTED := Color("#9eb2c2")

var _left_panel: PanelContainer
var _logo: TextureRect
var _continue_button: Button
var _status_label: Label
var _modal_layer: CanvasLayer
var _modal_panel: PanelContainer
var _modal_title: Label
var _modal_body: VBoxContainer

func _ready() -> void:
	_build_background()
	_build_menu()
	_build_modal()
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()

func _build_background() -> void:
	var background := TextureRect.new()
	background.name = "WorkshopBackground"
	background.texture = MENU_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.name = "AtmosphereShade"
	shade.color = Color(0.01, 0.02, 0.035, 0.20)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

func _build_menu() -> void:
	var safe := MarginContainer.new()
	safe.name = "SafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 28)
	safe.add_theme_constant_override("margin_top", 24)
	safe.add_theme_constant_override("margin_right", 28)
	safe.add_theme_constant_override("margin_bottom", 24)
	add_child(safe)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	safe.add_child(row)

	_left_panel = PanelContainer.new()
	_left_panel.name = "MainMenuPanel"
	_left_panel.custom_minimum_size = Vector2(420, 0)
	_left_panel.add_theme_stylebox_override("panel", _panel_style())
	row.add_child(_left_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	_left_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	margin.add_child(column)

	_logo = TextureRect.new()
	_logo.name = "TechEmpireLogo"
	_logo.texture = GAME_LOGO
	_logo.custom_minimum_size = Vector2(360, 205)
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_logo)

	var era := Label.new()
	era.text = "1971  •  TOUT COMMENCE ICI"
	era.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	era.add_theme_color_override("font_color", AMBER)
	era.add_theme_font_size_override("font_size", 15)
	column.add_child(era)

	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	column.add_child(separator)

	_continue_button = _menu_button("Continuer", true)
	_continue_button.pressed.connect(_continue_game)
	column.add_child(_continue_button)

	var new_game := _menu_button("Nouvelle partie")
	new_game.pressed.connect(_new_game)
	column.add_child(new_game)

	var load_game := _menu_button("Charger")
	load_game.pressed.connect(_load_game)
	column.add_child(load_game)

	var settings := _menu_button("Paramètres")
	settings.pressed.connect(_show_settings)
	column.add_child(settings)

	var credits := _menu_button("Crédits")
	credits.pressed.connect(_show_credits)
	column.add_child(credits)

	if not OS.has_feature("mobile"):
		var quit := _menu_button("Quitter")
		quit.pressed.connect(func(): get_tree().quit())
		column.add_child(quit)

	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	column.add_child(gap)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", MUTED)
	_status_label.add_theme_font_size_override("font_size", 14)
	column.add_child(_status_label)

	var motto := Label.new()
	motto.text = "« Les grandes innovations commencent dans un garage. »"
	motto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	motto.add_theme_color_override("font_color", Color(0.94, 0.78, 0.48, 0.82))
	motto.add_theme_font_size_override("font_size", 14)
	column.add_child(motto)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var version := Label.new()
	version.text = "Tech Empire  •  V0.3.1 UI Preview"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	version.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	version.size_flags_vertical = Control.SIZE_EXPAND_FILL
	version.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95, 0.72))
	version.add_theme_font_size_override("font_size", 13)
	row.add_child(version)

	_refresh_save_status()

func _menu_button(label_text: String, primary := false) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(360, 52)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(primary, false))
	button.add_theme_stylebox_override("hover", _button_style(primary, true))
	button.add_theme_stylebox_override("pressed", _button_style(true, true))
	button.add_theme_stylebox_override("disabled", _disabled_button_style())
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.065, 0.105, 0.91)
	style.border_color = Color(0.18, 0.52, 0.70, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 12
	return style

func _button_style(primary: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if primary:
		style.bg_color = Color("#126fa3") if not hover else Color("#168ac7")
		style.border_color = CYAN
	else:
		style.bg_color = Color(0.035, 0.11, 0.17, 0.94) if not hover else Color(0.055, 0.18, 0.26, 0.98)
		style.border_color = Color(0.20, 0.48, 0.64, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 18
	return style

func _disabled_button_style() -> StyleBoxFlat:
	var style := _button_style(false, false)
	style.bg_color = Color(0.03, 0.055, 0.075, 0.78)
	style.border_color = Color(0.18, 0.25, 0.30, 0.55)
	return style

func _refresh_save_status() -> void:
	var has_save := SaveManager.has_any_save()
	_continue_button.disabled = not has_save
	if has_save:
		var latest := SaveManager.get_latest_slot_id()
		_status_label.text = "Sauvegardes disponibles • Continuer reprendra la partie la plus récente (%s)." % latest
	else:
		_status_label.text = "Aucune sauvegarde pour le moment. Commencez votre aventure en 1971."

func _new_game() -> void:
	var empty_slot := SaveManager.first_empty_slot()
	if SaveManager.slot_exists(empty_slot):
		_show_message("Nouvelle partie", "Les 5 emplacements sont utilisés. Chargez une partie existante ou libérez un emplacement avant de recommencer.")
		return
	SaveManager.set_current_slot(empty_slot)
	get_tree().change_scene_to_file(GAME_SCENE)

func _continue_game() -> void:
	if SaveManager.load_latest_game():
		get_tree().change_scene_to_file(GAME_SCENE)
	else:
		_refresh_save_status()

func _load_game() -> void:
	_show_save_slots()

func _show_save_slots() -> void:
	_clear_modal_content()
	_modal_title.text = "Charger une partie"
	var found := false
	for slot_value in SaveManager.list_slots():
		var slot: Dictionary = slot_value
		if not bool(slot.get("exists", false)):
			continue
		found = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_modal_body.add_child(row)

		var label := str(slot.get("company_name", slot.get("slot_name", "Entreprise")))
		var slot_id := str(slot.get("slot_id", "slot_1"))
		var load := _menu_button("%s  •  %d/%d/%d  •  %s €" % [
			label,
			int(slot.get("day", 1)),
			int(slot.get("month", 1)),
			int(slot.get("year", 1971)),
			_format_money(int(slot.get("money", 0)))
		])
		load.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		load.pressed.connect(func(): _load_slot(slot_id))
		row.add_child(load)

		if slot_id != "legacy":
			var delete := Button.new()
			delete.text = "Supprimer"
			delete.custom_minimum_size = Vector2(100, 48)
			delete.pressed.connect(func(): _confirm_delete_slot(slot_id, label))
			row.add_child(delete)

	if not found:
		var empty := Label.new()
		empty.text = "Aucune sauvegarde disponible."
		empty.add_theme_color_override("font_color", MUTED)
		_modal_body.add_child(empty)

	var close := _menu_button("Fermer")
	close.pressed.connect(_close_modal)
	_modal_body.add_child(close)
	_modal_layer.visible = true

func _load_slot(slot_id: String) -> void:
	if SaveManager.load_game(slot_id):
		get_tree().change_scene_to_file(GAME_SCENE)
	else:
		_show_message("Chargement", "Impossible de charger cet emplacement.")

func _confirm_delete_slot(slot_id: String, label: String) -> void:
	_clear_modal_content()
	_modal_title.text = "Supprimer la sauvegarde ?"
	var warning := Label.new()
	warning.text = "%s sera définitivement supprimée." % label
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_color_override("font_color", TEXT)
	_modal_body.add_child(warning)
	var confirm := _menu_button("Supprimer définitivement")
	confirm.pressed.connect(func():
		SaveManager.delete_slot(slot_id)
		_refresh_save_status()
		_show_save_slots()
	)
	_modal_body.add_child(confirm)
	var cancel := _menu_button("Annuler", true)
	cancel.pressed.connect(_show_save_slots)
	_modal_body.add_child(cancel)
	_modal_layer.visible = true

func _format_money(value: int) -> String:
	var raw := str(abs(value))
	var result := ""
	var count := 0
	for i in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = " " + result
		result = raw.substr(i, 1) + result
		count += 1
	return ("-" if value < 0 else "") + result

func _build_modal() -> void:
	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 20
	add_child(_modal_layer)

	var dim := ColorRect.new()
	dim.name = "ModalDim"
	dim.color = Color(0, 0, 0, 0.64)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(dim)

	_modal_panel = PanelContainer.new()
	_modal_panel.custom_minimum_size = Vector2(480, 260)
	_modal_panel.add_theme_stylebox_override("panel", _panel_style())
	_modal_panel.set_anchors_preset(Control.PRESET_CENTER)
	_modal_panel.position = Vector2(-240, -130)
	_modal_layer.add_child(_modal_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	_modal_panel.add_child(margin)

	_modal_body = VBoxContainer.new()
	_modal_body.add_theme_constant_override("separation", 14)
	margin.add_child(_modal_body)

	_modal_title = Label.new()
	_modal_title.add_theme_color_override("font_color", AMBER)
	_modal_title.add_theme_font_size_override("font_size", 25)
	_modal_body.add_child(_modal_title)

	_modal_layer.visible = false

func _clear_modal_content() -> void:
	for child in _modal_body.get_children():
		if child != _modal_title:
			child.queue_free()

func _show_message(title: String, message: String) -> void:
	_clear_modal_content()
	_modal_title.text = title
	var body := Label.new()
	body.text = message
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", TEXT)
	body.add_theme_font_size_override("font_size", 17)
	_modal_body.add_child(body)
	var close := _menu_button("Fermer", true)
	close.pressed.connect(_close_modal)
	_modal_body.add_child(close)
	_modal_layer.visible = true

func _show_settings() -> void:
	_clear_modal_content()
	_modal_title.text = "Paramètres"

	var info := Label.new()
	info.text = "Affichage"
	info.add_theme_color_override("font_color", TEXT)
	info.add_theme_font_size_override("font_size", 17)
	_modal_body.add_child(info)

	if not OS.has_feature("mobile"):
		var fullscreen := CheckButton.new()
		fullscreen.text = "Plein écran"
		fullscreen.button_pressed = bool(SettingsManager.get_setting("display", "fullscreen"))
		fullscreen.toggled.connect(_toggle_fullscreen)
		_modal_body.add_child(fullscreen)

	var scale_label := Label.new()
	scale_label.text = "Échelle de l'interface"
	scale_label.add_theme_color_override("font_color", TEXT)
	_modal_body.add_child(scale_label)

	var ui_scale := OptionButton.new()
	var scale_values := [0.90, 1.00, 1.10, 1.25]
	for value in scale_values:
		ui_scale.add_item("%d %%" % int(round(float(value) * 100.0)))
		ui_scale.set_item_metadata(ui_scale.item_count - 1, float(value))
	var current_scale := float(SettingsManager.get_setting("display", "ui_scale"))
	var best_index := 0
	var best_delta := 999.0
	for i in range(ui_scale.item_count):
		var delta := absf(float(ui_scale.get_item_metadata(i)) - current_scale)
		if delta < best_delta:
			best_delta = delta
			best_index = i
	ui_scale.select(best_index)
	ui_scale.item_selected.connect(func(index: int):
		SettingsManager.set_ui_scale(float(ui_scale.get_item_metadata(index)))
	)
	_modal_body.add_child(ui_scale)

	var reduce_motion := CheckButton.new()
	reduce_motion.text = "Réduire les animations"
	reduce_motion.button_pressed = bool(SettingsManager.get_setting("display", "reduce_motion"))
	reduce_motion.toggled.connect(func(enabled: bool):
		SettingsManager.set_setting("display", "reduce_motion", enabled)
	)
	_modal_body.add_child(reduce_motion)

	var tutorial := CheckButton.new()
	tutorial.text = "Guidage de Nora / tutoriel progressif"
	tutorial.button_pressed = bool(SettingsManager.get_setting("gameplay", "tutorial_enabled"))
	tutorial.toggled.connect(func(enabled: bool):
		SettingsManager.set_setting("gameplay", "tutorial_enabled", enabled)
	)
	_modal_body.add_child(tutorial)

	var responsive := Label.new()
	responsive.text = "Ces réglages sont enregistrés séparément des parties et restent identiques quel que soit le profil chargé."
	responsive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	responsive.add_theme_color_override("font_color", MUTED)
	_modal_body.add_child(responsive)

	var reset := _menu_button("Réinitialiser les paramètres")
	reset.pressed.connect(func():
		SettingsManager.reset_to_defaults()
		_show_settings()
	)
	_modal_body.add_child(reset)

	var close := _menu_button("Fermer", true)
	close.pressed.connect(_close_modal)
	_modal_body.add_child(close)
	_modal_layer.visible = true

func _show_credits() -> void:
	_show_message(
		"Crédits",
		"Tech Empire\nConception et direction : Alexandre Basso\nDéveloppement : projet indépendant\n\nMerci de participer aux premières versions du jeu."
	)

func _toggle_fullscreen(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)

func _close_modal() -> void:
	_modal_layer.visible = false

func _apply_layout() -> void:
	if _left_panel == null:
		return
	var viewport_size := get_viewport_rect().size
	var ratio: float = viewport_size.x / maxf(viewport_size.y, 1.0)
	var compact: bool = viewport_size.y < 620.0 or ratio > 2.05
	if compact:
		_left_panel.custom_minimum_size.x = 340
		_logo.custom_minimum_size = Vector2(290, 150)
		for child in _left_panel.find_children("*", "Button", true, false):
			if child is Button:
				child.custom_minimum_size.y = 44
				child.add_theme_font_size_override("font_size", 16)
	else:
		_left_panel.custom_minimum_size.x = 420
		_logo.custom_minimum_size = Vector2(360, 205)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _modal_layer.visible:
		_close_modal()
		get_viewport().set_input_as_handled()
