extends ColorRect

signal close_requested
signal hardware_requested
signal status_changed(message: String)
signal work_started(kind: String)

const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const CAT := preload("res://scripts/SoftwareCatalog.gd")
const ACTIVITY := preload("res://scripts/SoftwareActivityCatalog.gd")

var _activity_status: Label
var _activity_box: VBoxContainer
var _family_select: OptionButton
var _price_select: OptionButton
var _name_edit: LineEdit
var _settings_box: VBoxContainer
var _setting_controls: Dictionary = {}
var _project_preview: Label
var _project_start: Button
var _projects_box: VBoxContainer
var _products_box: VBoxContainer

func _ready() -> void:
	color = Color(0.025, 0.055, 0.10, 0.78)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()
	UI.prepare_touch_scroll_children(self)

func open() -> void:
	visible = true
	refresh()

func close() -> void:
	visible = false

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.configure_touch_scroll(scroll)
	margin.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var panel := LOOK.card(Color("fffaf1"), 20, 20)
	panel.custom_minimum_size = Vector2(800, 0)
	center.add_child(panel)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 14)
	panel.add_child(shell)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	shell.add_child(header)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(copy)
	copy.add_child(LOOK.eyebrow("GARAGE • DEUX FAÇONS DE CONSTRUIRE L'ENTREPRISE"))
	copy.add_child(LOOK.label("Hardware ou Software", 25))
	var intro := LOOK.muted_label("Le Hardware construit vos processeurs. Le Software peut avancer en parallèle : petits contrats pour apprendre, puis vrais produits à développer et maintenir.", 13)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(intro)

	var hardware := Button.new()
	hardware.text = "Hardware • CPU"
	LOOK.button_style(hardware)
	hardware.pressed.connect(func(): hardware_requested.emit())
	header.add_child(hardware)
	var close_button := Button.new()
	close_button.text = "Retour au garage"
	LOOK.button_style(close_button)
	close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(close_button)

	shell.add_child(UI.section("Activités Software courtes"))
	var activity_help := UI.muted_label("Ces missions rapportent peu. Leur intérêt principal est l'expérience Software, la maîtrise du domaine et la réputation. Une seule activité courte peut être menée à la fois.", 12)
	activity_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shell.add_child(activity_help)
	_activity_status = UI.rich_label()
	shell.add_child(_activity_status)
	_activity_box = VBoxContainer.new()
	_activity_box.add_theme_constant_override("separation", 8)
	shell.add_child(_activity_box)

	shell.add_child(UI.section("Développer un vrai produit Software"))
	var product_help := UI.muted_label("Un produit Software demande plusieurs mois, coûte chaque mois et génère ensuite des licences avec un coût de support. Les réglages élevés demandent davantage de maîtrise.", 12)
	product_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shell.add_child(product_help)

	var family_row := HBoxContainer.new()
	family_row.add_theme_constant_override("separation", 8)
	shell.add_child(family_row)
	_family_select = OptionButton.new()
	_family_select.custom_minimum_size = Vector2(250, 44)
	_family_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_family_select.item_selected.connect(func(_index): _on_family_changed())
	family_row.add_child(_family_select)
	_price_select = OptionButton.new()
	_price_select.custom_minimum_size = Vector2(220, 44)
	for key_value in CAT.PRICE_MODES.keys():
		var key := str(key_value)
		_price_select.add_item(str((CAT.PRICE_MODES[key] as Dictionary).get("label", key)))
		_price_select.set_item_metadata(_price_select.item_count - 1, key)
	UI.select_meta(_price_select, "MARKET")
	_price_select.item_selected.connect(func(_index): _refresh_product_preview())
	family_row.add_child(_price_select)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nom du produit (facultatif)"
	_name_edit.custom_minimum_size.y = 44
	LOOK.input_style(_name_edit)
	shell.add_child(_name_edit)

	_settings_box = VBoxContainer.new()
	_settings_box.add_theme_constant_override("separation", 7)
	shell.add_child(_settings_box)
	_project_preview = UI.rich_label()
	shell.add_child(_project_preview)
	_project_start = Button.new()
	_project_start.text = "Lancer le développement"
	LOOK.button_style(_project_start, true)
	_project_start.pressed.connect(_start_product)
	shell.add_child(_project_start)

	shell.add_child(UI.section("Votre branche Software"))
	_projects_box = VBoxContainer.new()
	_projects_box.add_theme_constant_override("separation", 6)
	shell.add_child(_projects_box)
	_products_box = VBoxContainer.new()
	_products_box.add_theme_constant_override("separation", 6)
	shell.add_child(_products_box)


func refresh() -> void:
	_refresh_activities()
	_refresh_family_options()
	_refresh_branch_status()

func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _refresh_activities() -> void:
	var current := SoftwareManager.active_activity()
	if current.is_empty():
		_activity_status.text = "Aucune activité courte en cours. Elles peuvent avancer pendant qu'un CPU est en développement."
	else:
		var data := ACTIVITY.data(str(current.get("id", "")))
		_activity_status.text = "En cours : %s — mois %d/%d." % [
			ACTIVITY.label(str(current.get("id", ""))),
			int(current.get("months_done", 0)),
			int(data.get("months", 1))
		]
	_clear(_activity_box)
	for activity_value in SoftwareManager.available_activities():
		var activity_id := str(activity_value)
		var data := ACTIVITY.data(activity_id)
		var card := UI.card(UI.APP_PANEL, 12, 12)
		_activity_box.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 5)
		card.add_child(box)
		var head := HBoxContainer.new()
		box.add_child(head)
		var title := UI.label(ACTIVITY.label(activity_id), 16)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(title)
		var family := str(data.get("family", "UTILITY"))
		var mastery := SoftwareManager.mastery(family)
		head.add_child(UI.muted_label("%s • maîtrise %d/5" % [CAT.family_label(family), mastery], 11))
		var pitch := UI.muted_label(str(data.get("pitch", "")), 12)
		pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(pitch)
		var economics := UI.muted_label("%d mois • %s €/mois • paiement %s € • gain net %s € • XP %d" % [
			int(data.get("months", 1)),
			UI.money(int(data.get("monthly_cost", 0))),
			UI.money(int(data.get("payout", 0))),
			UI.money(ACTIVITY.net_reward(activity_id)),
			int(data.get("xp", 0))
		], 11)
		box.add_child(economics)
		var check := SoftwareManager.can_start_activity(activity_id)
		var button := Button.new()
		button.text = "Démarrer cette activité"
		LOOK.button_style(button, bool(check.get("ok", false)))
		button.disabled = not bool(check.get("ok", false))
		if button.disabled:
			button.tooltip_text = str(check.get("reason", ""))
		button.pressed.connect(_start_activity.bind(activity_id))
		box.add_child(button)

func _start_activity(activity_id: String) -> void:
	if SoftwareManager.start_activity(activity_id):
		status_changed.emit("Activité Software lancée : %s." % ACTIVITY.label(activity_id))
		work_started.emit("ACTIVITY")
	else:
		var check := SoftwareManager.can_start_activity(activity_id)
		status_changed.emit(str(check.get("reason", "Impossible de démarrer cette activité.")))
	refresh()

func _refresh_family_options() -> void:
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
		_project_preview.text = "Aucun domaine Software n'est disponible pour cette année."
		_clear(_settings_box)
		return
	if keep != "":
		UI.select_meta(_family_select, keep)
	_on_family_changed()

func _on_family_changed() -> void:
	_rebuild_settings()
	_refresh_product_preview()

func _rebuild_settings() -> void:
	_clear(_settings_box)
	_setting_controls = {}
	var family_id := UI.option_meta(_family_select)
	if family_id == "":
		return
	var state := SoftwareManager.family_state(family_id)
	var mastery := int(state.get("mastery", 0))
	var info := UI.muted_label("%s — maîtrise %d/5 • %d lancement(s) • %d activité(s) terminée(s)" % [
		CAT.family_label(family_id), mastery,
		int(state.get("launches", 0)), int(state.get("activities_done", 0))
	], 12)
	_settings_box.add_child(info)
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
	var family_id := UI.option_meta(_family_select)
	if family_id == "":
		return
	var levels := _levels()
	var price_mode := UI.option_meta(_price_select)
	var preview := SoftwareManager.preview(family_id, levels, price_mode)
	var check := SoftwareManager.can_start(family_id, levels)
	var project := SoftwareManager.project_for(family_id)
	var state := SoftwareManager.family_state(family_id)
	var xp := int(state.get("activity_xp", 0))
	var lines: Array[String] = []
	lines.append("%s • développement %d mois • %s €/mois • coût estimé %s €." % [
		CAT.family_label(family_id),
		int(preview.get("months", 0)),
		UI.money(int(preview.get("monthly_cost", 0))),
		UI.money(int(preview.get("total_cost", 0)))
	])
	lines.append("Licence : %.0f € • qualité estimée %.0f/100 • progression activité %d/100 XP." % [
		float(preview.get("price", 0.0)),
		float(preview.get("quality", 0.0)),
		xp
	])
	if not project.is_empty():
		lines.append("Une version de cette famille est déjà en développement.")
	elif not bool(check.get("ok", false)):
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
		status_changed.emit("Produit Software lancé : %s." % (name if name != "" else SoftwareManager.next_name(family_id)))
		work_started.emit("PROJECT")
		_name_edit.text = ""
	else:
		var check := SoftwareManager.can_start(family_id, levels)
		status_changed.emit(str(check.get("reason", "Impossible de lancer ce produit Software.")))
	refresh()

func _refresh_branch_status() -> void:
	_clear(_projects_box)
	_clear(_products_box)
	if SoftwareManager.projects.is_empty():
		_projects_box.add_child(UI.muted_label("Aucun produit Software en développement.", 12))
	else:
		_projects_box.add_child(UI.eyebrow("EN DÉVELOPPEMENT"))
		for value in SoftwareManager.projects:
			var project: Dictionary = value
			var card := UI.card(UI.APP_PANEL, 10, 10)
			_projects_box.add_child(card)
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 3)
			card.add_child(box)
			box.add_child(UI.label(str(project.get("name", "Produit Software")), 15))
			box.add_child(UI.muted_label("%s • mois %d/%d • %s €/mois" % [
				CAT.family_label(str(project.get("family", ""))),
				int(project.get("months_done", 0)),
				int(project.get("months_total", 1)),
				UI.money(int(project.get("monthly_cost", 0)))
			], 11))
	if SoftwareManager.products.is_empty():
		_products_box.add_child(UI.muted_label("Aucun produit Software commercialisé pour le moment.", 12))
	else:
		_products_box.add_child(UI.eyebrow("EN VENTE"))
		for value in SoftwareManager.products:
			var product: Dictionary = value
			if str(product.get("status", "")) != "ACTIVE":
				continue
			var card := UI.card(UI.APP_PANEL_ALT, 10, 10)
			_products_box.add_child(card)
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 3)
			card.add_child(box)
			box.add_child(UI.label(str(product.get("name", "Produit Software")), 15))
			var margin := int(product.get("margin_last", 0))
			var detail := "%s • %s licences ce mois • %s utilisateurs installés • marge mensuelle %s%s €" % [
				CAT.family_label(str(product.get("family", ""))),
				UI.money(int(product.get("licenses_last", 0))),
				UI.money(int(product.get("installed_users", 0))),
				"+" if margin >= 0 else "",
				UI.money(margin)
			]
			box.add_child(UI.muted_label(detail, 11))
