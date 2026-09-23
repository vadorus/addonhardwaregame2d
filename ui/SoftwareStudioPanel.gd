extends PanelContainer

var type_select: OptionButton
var start_button: Button
var progress_label: Label
var progress_bar: ProgressBar
var action_row: HFlowContainer
var action_buttons: Array[Button] = []
var release_button: Button
var catalog_label: Label

func _ready() -> void:
	visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.095, 0.115, 0.99)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	add_child(box)
	var heading := Label.new()
	heading.text = "STUDIO LOGICIEL • VOS PROPRES PRODUITS"
	heading.add_theme_font_size_override("font_size", 19)
	box.add_child(heading)
	var description := Label.new()
	description.text = "Choisissez une application, publiez-la puis améliorez-la. Les ventes reviennent chaque mois ; l'atelier CPU reste facultatif."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	type_select = OptionButton.new()
	type_select.custom_minimum_size.y = 48
	type_select.item_selected.connect(func(_index): _refresh_buttons())
	box.add_child(type_select)
	start_button = Button.new()
	start_button.text = "Lancer le développement"
	start_button.custom_minimum_size.y = 48
	start_button.pressed.connect(_start_product)
	box.add_child(start_button)
	progress_label = Label.new()
	progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(progress_label)
	progress_bar = ProgressBar.new()
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size.y = 16
	box.add_child(progress_bar)
	action_row = HFlowContainer.new()
	action_row.add_theme_constant_override("h_separation", 8)
	box.add_child(action_row)
	for action in ["Coder", "Tester", "Faire connaître"]:
		var button := Button.new()
		button.text = action
		button.custom_minimum_size = Vector2(150, 46)
		button.pressed.connect(_session.bind(action_buttons.size()))
		action_row.add_child(button)
		action_buttons.append(button)
	release_button = Button.new()
	release_button.text = "Publier cette version"
	release_button.custom_minimum_size.y = 48
	release_button.pressed.connect(_release)
	box.add_child(release_button)
	catalog_label = Label.new()
	catalog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(catalog_label)
	var close := Button.new()
	close.text = "Fermer le studio"
	close.custom_minimum_size.y = 42
	close.pressed.connect(func(): visible = false)
	box.add_child(close)
	SoftwareStudioManager.studio_changed.connect(_refresh)
	Economy.money_changed.connect(func(_money): _refresh_buttons())
	FounderManager.founder_changed.connect(_refresh)
	_refresh()

func open() -> void:
	visible = true
	_refresh()
	var scroll := get_parent().get_parent()
	if scroll is ScrollContainer:
		(scroll as ScrollContainer).ensure_control_visible.call_deferred(self)
func _refresh() -> void:
	if type_select == null:
		return
	var previous := str(type_select.get_item_metadata(type_select.selected)) if type_select.selected >= 0 else ""
	type_select.clear()
	for type_id in SoftwareStudioManager.available_types():
		var data: Dictionary = SoftwareStudioManager.CATALOG[type_id]
		type_select.add_item("%s • création %d €" % [str(data.title), int(data.launch_cost)])
		type_select.set_item_metadata(type_select.item_count - 1, type_id)
	for index in range(type_select.item_count):
		if str(type_select.get_item_metadata(index)) == previous:
			type_select.select(index)
	if not SoftwareStudioManager.active_project.is_empty():
		var project := SoftwareStudioManager.active_project
		var type_id := str(project.get("type", ""))
		var data: Dictionary = SoftwareStudioManager.CATALOG.get(type_id, {})
		progress_label.text = "%s • %.0f / %.0f points • qualité %.0f • visibilité %.0f • programmation %.0f" % [str(data.get("title", "Logiciel")), float(project.get("work_done", 0)), float(project.get("work_required", 1)), float(project.get("quality", 0)), float(project.get("awareness", 0)), FounderManager.skill_value(FounderManager.SKILL_PROGRAMMING)]
		progress_bar.value = clampf(float(project.get("work_done", 0)) / maxf(float(project.get("work_required", 1)), 1.0) * 100.0, 0.0, 100.0)
	else:
		progress_label.text = "Créez un logiciel à vendre ou améliorez une version déjà publiée."
		progress_bar.value = 0.0
	var lines: Array[String] = []
	for product in SoftwareStudioManager.products:
		lines.append("%s v%d • dernière vente : %d € / mois • total : %d €" % [str(product.get("title", "Logiciel")), int(product.get("version", 1)), int(product.get("last_sales", 0)), int(product.get("lifetime_sales", 0))])
	catalog_label.text = "CATALOGUE\n" + ("\n".join(lines) if not lines.is_empty() else "Aucun produit publié.")
	_refresh_buttons()

func _refresh_buttons() -> void:
	if start_button == null or type_select == null:
		return
	var type_id := str(type_select.get_item_metadata(type_select.selected)) if type_select.selected >= 0 else ""
	start_button.disabled = type_id.is_empty() or not SoftwareStudioManager.can_start_product(type_id)
	start_button.text = "Préparer une nouvelle version" if SoftwareStudioManager._product_index(type_id) >= 0 else "Lancer le développement"
	progress_bar.visible = not SoftwareStudioManager.active_project.is_empty()
	action_row.visible = not SoftwareStudioManager.active_project.is_empty()
	for button in action_buttons:
		button.disabled = not SoftwareStudioManager.session_available()
	release_button.visible = not SoftwareStudioManager.active_project.is_empty()
	release_button.disabled = not SoftwareStudioManager.project_ready()
func _start_product() -> void:
	if type_select.selected < 0:
		return
	SoftwareStudioManager.start_product(str(type_select.get_item_metadata(type_select.selected)))

func _session(index: int) -> void:
	SoftwareStudioManager.perform_session(["CODE", "TEST", "PROMOTE"][index])

func _release() -> void:
	SoftwareStudioManager.release_product()
