extends Control

signal close_requested

var settings_grid: GridContainer
var platform_grid: GridContainer
var desktop_section: VBoxContainer
var android_section: VBoxContainer
var volume_value: Label
var scale_value: Label
var update_status: Label
var fps_select: OptionButton
var resolution_select: OptionButton
var fullscreen_check: CheckBox
var vsync_check: CheckBox
var _compact := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_sync_from_settings()
	if not UpdateManager.update_check_finished.is_connected(_on_update_check_finished):
		UpdateManager.update_check_finished.connect(_on_update_check_finished)

func set_compact(value: bool) -> void:
	_compact = value
	if settings_grid != null:
		settings_grid.columns = 1 if value else 2
	if platform_grid != null:
		platform_grid.columns = 1 if value else 2

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.035, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var kicker := Label.new()
	kicker.text = "PARAMÈTRES"
	title_box.add_child(kicker)
	var title := Label.new()
	title.text = "Tech Empire • %s" % ("Android" if SettingsManager.is_android() else "PC")
	title.add_theme_font_size_override("font_size", 24)
	title_box.add_child(title)
	var close := Button.new()
	close.text = "Fermer"
	close.custom_minimum_size = Vector2(100, 44)
	close.pressed.connect(func(): close_requested.emit())
	header.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	_build_common_section(body)
	_build_platform_section(body)
	_build_support_section(body)

func _build_common_section(parent: VBoxContainer) -> void:
	var card := _section(parent, "Audio & interface", "Réglages communs à toutes les versions.")
	settings_grid = GridContainer.new()
	settings_grid.columns = 1 if _compact else 2
	settings_grid.add_theme_constant_override("h_separation", 14)
	settings_grid.add_theme_constant_override("v_separation", 10)
	card.add_child(settings_grid)
	settings_grid.add_child(_row_label("Volume général"))
	var volume_box := HBoxContainer.new()
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 1
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.value = SettingsManager.master_volume * 100.0
	volume_value = Label.new()
	volume_value.custom_minimum_size.x = 46
	volume.value_changed.connect(func(v): SettingsManager.set_master_volume(v / 100.0); volume_value.text = "%d%%" % int(v))
	volume_box.add_child(volume)
	volume_box.add_child(volume_value)
	settings_grid.add_child(volume_box)
	settings_grid.add_child(_row_label("Échelle interface"))
	var scale_box := HBoxContainer.new()
	var scale := HSlider.new()
	scale.min_value = 85
	scale.max_value = 130
	scale.step = 5
	scale.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale.value = SettingsManager.ui_scale * 100.0
	scale_value = Label.new()
	scale_value.custom_minimum_size.x = 46
	scale.value_changed.connect(func(v): SettingsManager.set_ui_scale(v / 100.0); scale_value.text = "%d%%" % int(v))
	scale_box.add_child(scale)
	scale_box.add_child(scale_value)
	settings_grid.add_child(scale_box)

func _build_platform_section(parent: VBoxContainer) -> void:
	if SettingsManager.is_android():
		android_section = _section(parent, "Android", "Optimisez fluidité et autonomie selon votre téléphone.")
		platform_grid = GridContainer.new()
		platform_grid.columns = 1 if _compact else 2
		platform_grid.add_theme_constant_override("h_separation", 14)
		platform_grid.add_theme_constant_override("v_separation", 10)
		android_section.add_child(platform_grid)
		platform_grid.add_child(_row_label("Limite d'images/seconde"))
		fps_select = _fps_option()
		platform_grid.add_child(fps_select)
		var note := Label.new()
		note.text = "30 FPS économise la batterie • 60 FPS recommandé • 90 FPS plus fluide mais plus énergivore."
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.modulate = Color(0.72, 0.78, 0.86)
		android_section.add_child(note)
	else:
		desktop_section = _section(parent, "Affichage PC", "Fenêtre, résolution et synchronisation verticale.")
		platform_grid = GridContainer.new()
		platform_grid.columns = 1 if _compact else 2
		platform_grid.add_theme_constant_override("h_separation", 14)
		platform_grid.add_theme_constant_override("v_separation", 10)
		desktop_section.add_child(platform_grid)
		platform_grid.add_child(_row_label("Mode d'affichage"))
		fullscreen_check = CheckBox.new()
		fullscreen_check.text = "Plein écran"
		fullscreen_check.toggled.connect(SettingsManager.set_fullscreen)
		platform_grid.add_child(fullscreen_check)
		platform_grid.add_child(_row_label("Résolution fenêtrée"))
		resolution_select = _resolution_option()
		platform_grid.add_child(resolution_select)
		platform_grid.add_child(_row_label("V-Sync"))
		vsync_check = CheckBox.new()
		vsync_check.text = "Activée"
		vsync_check.toggled.connect(SettingsManager.set_vsync)
		platform_grid.add_child(vsync_check)
		platform_grid.add_child(_row_label("Limite d'images/seconde"))
		fps_select = _fps_option()
		platform_grid.add_child(fps_select)

func _build_support_section(parent: VBoxContainer) -> void:
	var support := _section(parent, "Version & assistance", "Informations de build et outils de diagnostic.")
	var version := Label.new()
	version.text = "Version installée : %s • Canal : %s" % [UpdateManager.BUILD_VERSION, str(ProjectSettings.get_setting("updates/channel", "preview"))]
	support.add_child(version)
	update_status = Label.new()
	update_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	update_status.modulate = Color(0.72, 0.78, 0.86)
	support.add_child(update_status)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	support.add_child(actions)
	var update_btn := Button.new()
	update_btn.text = "Vérifier les mises à jour"
	update_btn.custom_minimum_size.y = 44
	update_btn.pressed.connect(_check_updates)
	actions.add_child(update_btn)
	var bug_btn := Button.new()
	bug_btn.text = "Signaler un bug"
	bug_btn.custom_minimum_size.y = 44
	bug_btn.pressed.connect(func(): BugReporter.call("_open_reporter"))
	actions.add_child(bug_btn)
	var reset_btn := Button.new()
	reset_btn.text = "Réinitialiser les paramètres"
	reset_btn.custom_minimum_size.y = 44
	reset_btn.pressed.connect(_reset_settings)
	actions.add_child(reset_btn)

func _section(parent: VBoxContainer, title: String, subtitle: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 18)
	box.add_child(heading)
	var desc := Label.new()
	desc.text = subtitle
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(0.72, 0.78, 0.86)
	box.add_child(desc)
	return box

func _row_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _fps_option() -> OptionButton:
	var option := OptionButton.new()
	for fps in [30, 60, 90, 120]:
		option.add_item("%d FPS" % fps)
		option.set_item_metadata(option.item_count - 1, fps)
	option.item_selected.connect(func(index): SettingsManager.set_max_fps(int(option.get_item_metadata(index))))
	return option

func _resolution_option() -> OptionButton:
	var option := OptionButton.new()
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080), Vector2i(2560,1440)]:
		option.add_item("%d × %d" % [size.x, size.y])
		option.set_item_metadata(option.item_count - 1, size)
	option.item_selected.connect(func(index): SettingsManager.set_window_size(option.get_item_metadata(index)))
	return option

func _sync_from_settings() -> void:
	volume_value.text = "%d%%" % int(SettingsManager.master_volume * 100.0)
	scale_value.text = "%d%%" % int(SettingsManager.ui_scale * 100.0)
	if fps_select != null:
		_select_metadata(fps_select, SettingsManager.max_fps)
	if fullscreen_check != null:
		fullscreen_check.set_pressed_no_signal(SettingsManager.fullscreen)
	if vsync_check != null:
		vsync_check.set_pressed_no_signal(SettingsManager.vsync)
	if resolution_select != null:
		_select_metadata(resolution_select, SettingsManager.window_size)
	update_status.text = "Les paramètres sont enregistrés automatiquement."

func _select_metadata(option: OptionButton, value: Variant) -> void:
	for i in range(option.item_count):
		if option.get_item_metadata(i) == value:
			option.select(i)
			return

func _check_updates() -> void:
	if UpdateManager.manifest_url().is_empty():
		update_status.text = "Le serveur de mise à jour n'est pas encore activé pour cette preview."
		return
	update_status.text = "Vérification en cours…"
	UpdateManager.check_for_updates()

func _on_update_check_finished(has_update: bool) -> void:
	if has_update:
		update_status.text = "Une mise à jour est disponible."
	else:
		update_status.text = "Aucune mise à jour plus récente détectée."

func _reset_settings() -> void:
	SettingsManager.reset_defaults()
	_sync_from_settings()
	update_status.text = "Paramètres réinitialisés."
