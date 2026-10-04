extends ColorRect

signal close_requested
signal hardware_requested
signal status_changed(message: String)
signal work_started(kind: String)

const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const CAT := preload("res://scripts/SoftwareCatalog.gd")
const ACTIVITY := preload("res://scripts/SoftwareActivityCatalog.gd")

enum ViewMode { PROJECT_CHOICE, SOFTWARE_CHOICE, ACTIVITIES, PRODUCT }

var _mode := ViewMode.PROJECT_CHOICE
var _title: Label
var _subtitle: Label
var _back_button: Button
var _content: VBoxContainer
var _family_select: OptionButton
var _price_select: OptionButton
var _name_edit: LineEdit
var _settings_box: VBoxContainer
var _setting_controls: Dictionary = {}
var _project_preview: Label
var _project_start: Button

func _ready() -> void:
	color = Color(0.025, 0.055, 0.10, 0.78)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_shell()

func open() -> void:
	visible = true
	_show_project_choice()

func close() -> void:
	visible = false

func current_view_name() -> String:
	match _mode:
		ViewMode.PROJECT_CHOICE: return "PROJECT_CHOICE"
		ViewMode.SOFTWARE_CHOICE: return "SOFTWARE_CHOICE"
		ViewMode.ACTIVITIES: return "ACTIVITIES"
		ViewMode.PRODUCT: return "PRODUCT"
	return "UNKNOWN"

func _build_shell() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var panel := LOOK.card(Color("fffaf1"), 20, 20)
	panel.custom_minimum_size = Vector2(820, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(panel)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 12)
	panel.add_child(shell)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	shell.add_child(header)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	header.add_child(copy)
	copy.add_child(LOOK.eyebrow("NOUVEAU PROJET"))
	_title = LOOK.label("Choisissez votre projet", 26)
	copy.add_child(_title)
	_subtitle = LOOK.muted_label("", 13)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(_subtitle)

	_back_button = Button.new()
	_back_button.text = "Retour"
	LOOK.button_style(_back_button)
	_back_button.pressed.connect(_go_back)
	header.add_child(_back_button)

	var close_button := Button.new()
	close_button.text = "Garage"
	LOOK.button_style(close_button)
	close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.configure_touch_scroll(scroll)
	shell.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)

func _clear_content() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

func _go_back() -> void:
	match _mode:
		ViewMode.PROJECT_CHOICE:
			close_requested.emit()
		ViewMode.SOFTWARE_CHOICE:
			_show_project_choice()
		ViewMode.ACTIVITIES, ViewMode.PRODUCT:
			_show_software_choice()

func _choice_card(title: String, subtitle: String, action: String, primary := false) -> Button:
	var button := Button.new()
	button.text = "%s\n%s\n\n%s" % [title, subtitle, action]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 150)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LOOK.button_style(button, primary)
	button.add_theme_font_size_override("font_size", 17)
	return button

func _show_project_choice() -> void:
	_mode = ViewMode.PROJECT_CHOICE
	_title.text = "Quel projet voulez-vous lancer ?"
	_subtitle.text = "Choisissez d'abord la branche. Les réglages viendront ensuite."
	_back_button.text = "Garage"
	_clear_content()

	var hardware := _choice_card(
		"Processeur",
		"Concevoir une nouvelle génération de CPU.",
		"Continuer en Hardware",
		true
	)
	hardware.pressed.connect(func(): hardware_requested.emit())
	_content.add_child(hardware)

	var software := _choice_card(
		"Logiciel",
		"Travailler sur des contrats ou créer vos propres logiciels.",
		"Continuer en Software"
	)
	software.disabled = not SoftwareManager.any_open()
	software.pressed.connect(_show_software_choice)
	_content.add_child(software)

func _show_software_choice() -> void:
	_mode = ViewMode.SOFTWARE_CHOICE
	_title.text = "Logiciel"
	_subtitle.text = "Que voulez-vous faire ?"
	_back_button.text = "Projets"
	_clear_content()

	var contracts := _choice_card(
		"Petits contrats",
		"Missions courtes pour gagner un peu d'argent, de l'XP et de la maîtrise.",
		"Voir les contrats",
		true
	)
	contracts.pressed.connect(_show_activities)
	_content.add_child(contracts)

	var product := _choice_card(
		"Créer un produit",
		"Développer un logiciel qui sera vendu et maintenu dans la durée.",
		"Choisir un produit"
	)
	product.pressed.connect(_show_product)
	_content.add_child(product)

	_add_compact_status()

func _add_compact_status() -> void:
	var activity := SoftwareManager.active_activity()
	if not activity.is_empty():
		var data := ACTIVITY.data(str(activity.get("id", "")))
		_content.add_child(UI.muted_label("En cours : %s • mois %d/%d" % [
			ACTIVITY.label(str(activity.get("id", ""))),
			int(activity.get("months_done", 0)),
			int(data.get("months", 1))
		], 12))
	if not SoftwareManager.projects.is_empty():
		var project: Dictionary = SoftwareManager.projects[0]
		_content.add_child(UI.muted_label("Produit en développement : %s • mois %d/%d" % [
			str(project.get("name", "Produit Software")),
			int(project.get("months_done", 0)),
			int(project.get("months_total", 1))
		], 12))

func _show_activities() -> void:
	_mode = ViewMode.ACTIVITIES
	_title.text = "Petits contrats"
	_subtitle.text = "Choisissez une mission. Une seule peut être active à la fois."
	_back_button.text = "Logiciel"
	_clear_content()

	var current := SoftwareManager.active_activity()
	if not current.is_empty():
		var current_data := ACTIVITY.data(str(current.get("id", "")))
		var running := UI.card(UI.APP_PANEL_ALT, 12, 12)
		var running_box := VBoxContainer.new()
		running.add_child(running_box)
		running_box.add_child(UI.eyebrow("EN COURS"))
		running_box.add_child(UI.label(ACTIVITY.label(str(current.get("id", ""))), 17))
		running_box.add_child(UI.muted_label("Mois %d/%d" % [
			int(current.get("months_done", 0)),
			int(current_data.get("months", 1))
		], 12))
		_content.add_child(running)

	for activity_value in SoftwareManager.available_activities():
		var activity_id := str(activity_value)
		var data := ACTIVITY.data(activity_id)
		var card := UI.card(UI.APP_PANEL, 12, 12)
		_content.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 5)
		card.add_child(box)

		var title := UI.label(ACTIVITY.label(activity_id), 17)
		box.add_child(title)
		var family := str(data.get("family", "UTILITY"))
		box.add_child(UI.muted_label("%s • maîtrise %d/5" % [
			CAT.family_label(family), SoftwareManager.mastery(family)
		], 11))

		var pitch := UI.muted_label(str(data.get("pitch", "")), 12)
		pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(pitch)
		box.add_child(UI.muted_label("%d mois • coût %s €/mois • paiement %s € • net %s € • XP %d" % [
			int(data.get("months", 1)),
			UI.money(int(data.get("monthly_cost", 0))),
			UI.money(int(data.get("payout", 0))),
			UI.money(ACTIVITY.net_reward(activity_id)),
			int(data.get("xp", 0))
		], 11))

		var check := SoftwareManager.can_start_activity(activity_id)
		var button := Button.new()
		button.text = "Démarrer"
		LOOK.button_style(button, bool(check.get("ok", false)))
		button.disabled = not bool(check.get("ok", false))
		button.tooltip_text = str(check.get("reason", ""))
		button.pressed.connect(_start_activity.bind(activity_id))
		box.add_child(button)

	UI.prepare_touch_scroll_children(_content)

func _start_activity(activity_id: String) -> void:
	if SoftwareManager.start_activity(activity_id):
		status_changed.emit("Activité Software lancée : %s." % ACTIVITY.label(activity_id))
		work_started.emit("ACTIVITY")
	else:
		var check := SoftwareManager.can_start_activity(activity_id)
		status_changed.emit(str(check.get("reason", "Impossible de démarrer cette activité.")))
	_show_activities()

func _show_product() -> void:
	_mode = ViewMode.PRODUCT
	_title.text = "Créer un produit logiciel"
	_subtitle.text = "Choisissez d'abord le type de logiciel, puis réglez uniquement ce produit."
	_back_button.text = "Logiciel"
	_clear_content()
	_build_product_controls()
	_refresh_family_options()
	UI.prepare_touch_scroll_children(_content)

func _build_product_controls() -> void:
	var family_label := UI.eyebrow("TYPE DE LOGICIEL")
	_content.add_child(family_label)
	_family_select = OptionButton.new()
	_family_select.custom_minimum_size.y = 48
	_family_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_family_select.item_selected.connect(func(_index): _on_family_changed())
	_content.add_child(_family_select)

	var name_label := UI.eyebrow("NOM")
	_content.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nom du produit (facultatif)"
	_name_edit.custom_minimum_size.y = 46
	LOOK.input_style(_name_edit)
	_content.add_child(_name_edit)

	var price_label := UI.eyebrow("POSITIONNEMENT")
	_content.add_child(price_label)
	_price_select = OptionButton.new()
	_price_select.custom_minimum_size.y = 48
	for key_value in CAT.PRICE_MODES.keys():
		var key := str(key_value)
		_price_select.add_item(str((CAT.PRICE_MODES[key] as Dictionary).get("label", key)))
		_price_select.set_item_metadata(_price_select.item_count - 1, key)
	UI.select_meta(_price_select, "MARKET")
	_price_select.item_selected.connect(func(_index): _refresh_product_preview())
	_content.add_child(_price_select)

	_content.add_child(UI.eyebrow("RÉGLAGES"))
	_settings_box = VBoxContainer.new()
	_settings_box.add_theme_constant_override("separation", 7)
	_content.add_child(_settings_box)

	_project_preview = UI.rich_label()
	_content.add_child(_project_preview)

	_project_start = Button.new()
	_project_start.text = "Lancer le développement"
	LOOK.button_style(_project_start, true)
	_project_start.pressed.connect(_start_product)
	_content.add_child(_project_start)

func _refresh_family_options() -> void:
	if _family_select == null:
		return
	var keep := UI.option_meta(_family_select)
	_family_select.clear()
	for family_value in CAT.FAMILY_ORDER:
		var family_id := str(family_value)
		if not SoftwareManager.is_open(family_id):
			continue
		_family_select.add_item(CAT.family_label(family_id))
		_family_select.set_item_metadata(_family_select.item_count - 1, family_id)
	if _family_select.item_count == 0:
		_project_start.disabled = true
		_project_preview.text = "Aucun domaine Software disponible cette année."
		return
	if keep != "":
		UI.select_meta(_family_select, keep)
	_on_family_changed()

func _on_family_changed() -> void:
	_rebuild_settings()
	_refresh_product_preview()

func _rebuild_settings() -> void:
	for child in _settings_box.get_children():
		_settings_box.remove_child(child)
		child.queue_free()
	_setting_controls = {}
	var family_id := UI.option_meta(_family_select)
	if family_id == "":
		return
	var state := SoftwareManager.family_state(family_id)
	_settings_box.add_child(UI.muted_label("Maîtrise %d/5 • %d activité(s) terminée(s)" % [
		int(state.get("mastery", 0)), int(state.get("activities_done", 0))
	], 12))
	for setting_value in CAT.settings_of(family_id):
		var setting_id := str(setting_value)
		var data := CAT.setting(family_id, setting_id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_settings_box.add_child(row)
		var label := UI.label(str(data.get("label", setting_id)), 13)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var control := SpinBox.new()
		control.min_value = 1
		control.max_value = SoftwareManager.max_level(family_id)
		control.step = 1
		control.value = 3
		control.custom_minimum_size = Vector2(120, 42)
		control.value_changed.connect(func(_value): _refresh_product_preview())
		row.add_child(control)
		_setting_controls[setting_id] = control

func _levels() -> Dictionary:
	var levels := {}
	for key_value in _setting_controls.keys():
		var key := str(key_value)
		levels[key] = int((_setting_controls[key] as SpinBox).value)
	return levels

func _refresh_product_preview() -> void:
	if _family_select == null or _project_preview == null:
		return
	var family_id := UI.option_meta(_family_select)
	if family_id == "":
		return
	var levels := _levels()
	var price_mode := UI.option_meta(_price_select)
	var preview := SoftwareManager.preview(family_id, levels, price_mode)
	var check := SoftwareManager.can_start(family_id, levels)
	var state := SoftwareManager.family_state(family_id)
	var lines: Array[String] = []
	lines.append("%d mois • %s €/mois • coût total estimé %s €" % [
		int(preview.get("months", 0)),
		UI.money(int(preview.get("monthly_cost", 0))),
		UI.money(int(preview.get("total_cost", 0)))
	])
	lines.append("Licence %.0f € • qualité estimée %.0f/100 • XP %d/100" % [
		float(preview.get("price", 0.0)),
		float(preview.get("quality", 0.0)),
		int(state.get("activity_xp", 0))
	])
	if not bool(check.get("ok", false)):
		lines.append(str(check.get("reason", "")))
	_project_preview.text = "\n".join(lines)
	_project_start.disabled = not bool(check.get("ok", false))
	LOOK.button_style(_project_start, bool(check.get("ok", false)))

func _start_product() -> void:
	var family_id := UI.option_meta(_family_select)
	if family_id == "":
		return
	var name := _name_edit.text.strip_edges()
	var levels := _levels()
	var price_mode := UI.option_meta(_price_select)
	if SoftwareManager.start_project(family_id, levels, price_mode, name):
		status_changed.emit("Produit Software lancé.")
		work_started.emit("PROJECT")
		_show_software_choice()
	else:
		var check := SoftwareManager.can_start(family_id, levels)
		status_changed.emit(str(check.get("reason", "Impossible de lancer ce produit Software.")))
	_refresh_product_preview()
