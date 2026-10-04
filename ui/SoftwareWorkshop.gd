extends ColorRect

signal close_requested
signal hardware_requested
signal status_changed(message: String)
signal work_started(kind: String)

const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const CAT := preload("res://scripts/SoftwareCatalog.gd")
const ACTIVITY := preload("res://scripts/SoftwareActivityCatalog.gd")
const PLAY := preload("res://scripts/SoftwarePlayCatalog.gd")

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
var _target_select: OptionButton
var _feature_checks: Dictionary = {}
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

func _choice_card(title: String, subtitle: String) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [title, subtitle]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 170)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LOOK.button_style(button)
	button.add_theme_font_size_override("font_size", 18)
	return button

func _show_project_choice() -> void:
	_mode = ViewMode.PROJECT_CHOICE
	_title.text = "Quel projet voulez-vous lancer ?"
	_subtitle.text = "Choisissez d'abord la branche. Les réglages viendront ensuite."
	_back_button.visible = false
	_clear_content()

	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 14)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(choices)

	var processor := _choice_card(
		"Processeur",
		"Concevoir une nouvelle génération de CPU."
	)
	processor.pressed.connect(func(): hardware_requested.emit())
	choices.add_child(processor)

	var software := _choice_card(
		"Logiciel",
		"Réaliser des contrats ou créer vos propres logiciels."
	)
	software.disabled = not SoftwareManager.any_open()
	software.pressed.connect(_show_software_choice)
	choices.add_child(software)

func _show_software_choice() -> void:
	_mode = ViewMode.SOFTWARE_CHOICE
	_title.text = "Logiciel"
	_subtitle.text = "Que voulez-vous faire ?"
	_back_button.visible = true
	_back_button.text = "Projets"
	_clear_content()

	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 14)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(choices)

	var contracts := _choice_card(
		"Petits contrats",
		"Missions courtes pour gagner un peu d'argent, de l'XP et de la maîtrise."
	)
	contracts.pressed.connect(_show_activities)
	choices.add_child(contracts)

	var product := _choice_card(
		"Créer un produit",
		"Développer un logiciel vendu et maintenu dans la durée."
	)
	product.pressed.connect(_show_product)
	choices.add_child(product)

	_add_compact_status()

func _add_compact_status() -> void:
	var activity := SoftwareManager.active_activity()
	if not activity.is_empty():
		var activity_id := str(activity.get("id", ""))
		var approach_id := str(activity.get("approach", "BALANCED"))
		var terms := SoftwareManager.activity_terms(activity_id, approach_id)
		_content.add_child(UI.muted_label("Contrat en cours : %s • %s • mois %d/%d" % [
			ACTIVITY.label(activity_id),
			PLAY.approach_label(approach_id),
			int(activity.get("months_done", 0)),
			int(terms.get("months", 1))
		], 12))

	if not SoftwareManager.projects.is_empty():
		var project: Dictionary = SoftwareManager.projects[0]
		var status := str(project.get("status", "DEVELOPMENT"))
		if status == "DECISION":
			var decision: Dictionary = project.get("pending_decision", {})
			var card := UI.card(UI.APP_PANEL_ALT, 12, 12)
			_content.add_child(card)
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 6)
			card.add_child(box)
			box.add_child(UI.eyebrow("DÉCISION REQUISE"))
			box.add_child(UI.label(str(decision.get("title", "Problème de développement")), 17))
			var text_label := UI.muted_label(str(decision.get("text", "")), 12)
			text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(text_label)
			var actions := HBoxContainer.new()
			actions.add_theme_constant_override("separation", 8)
			box.add_child(actions)
			var rewrite := Button.new()
			rewrite.text = "Réécrire\n+1 mois, moins de bugs"
			rewrite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			LOOK.button_style(rewrite, true)
			rewrite.pressed.connect(_resolve_project_decision.bind(str(project.get("id", "")), "REWRITE"))
			actions.add_child(rewrite)
			var cut := Button.new()
			cut.text = "Retirer la fonction\nmoins ambitieux"
			cut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cut.disabled = (project.get("features", []) as Array).size() <= 2
			LOOK.button_style(cut)
			cut.pressed.connect(_resolve_project_decision.bind(str(project.get("id", "")), "CUT"))
			actions.add_child(cut)
			var quick := Button.new()
			quick.text = "Corriger vite\nplus de risque"
			quick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			LOOK.button_style(quick)
			quick.pressed.connect(_resolve_project_decision.bind(str(project.get("id", "")), "QUICK_FIX"))
			actions.add_child(quick)
		elif status == "REVIEW":
			var card := UI.card(UI.APP_PANEL_ALT, 12, 12)
			_content.add_child(card)
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 6)
			card.add_child(box)
			box.add_child(UI.eyebrow("PRÊT À SORTIR"))
			box.add_child(UI.label(str(project.get("name", "Produit Software")), 17))
			var metrics: Dictionary = project.get("metrics", {})
			box.add_child(UI.muted_label("Fonctions %.0f • Ergonomie %.0f • Stabilité %.0f • Compat./perf. %.0f • bugs %d" % [
				float(metrics.get("features", 0.0)),
				float(metrics.get("usability", 0.0)),
				float(metrics.get("stability", 0.0)),
				float(metrics.get("performance", 0.0)),
				int(project.get("bugs", 0))
			], 11))
			var actions := HBoxContainer.new()
			actions.add_theme_constant_override("separation", 8)
			box.add_child(actions)
			for release_choice in ["RELEASE", "BETA", "DELAY"]:
				var button := Button.new()
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				match release_choice:
					"RELEASE": button.text = "Sortir maintenant"
					"BETA": button.text = "Faire une bêta\n+1 mois de tests"
					"DELAY": button.text = "Repousser\n+1 mois de finition"
				LOOK.button_style(button, release_choice == "BETA")
				button.pressed.connect(_choose_release.bind(str(project.get("id", "")), release_choice))
				actions.add_child(button)
		elif status == "BETA":
			_content.add_child(UI.muted_label("Bêta en cours : %s • tests utilisateurs ce mois-ci." % str(project.get("name", "Produit Software")), 12))
		else:
			_content.add_child(UI.muted_label("Produit en développement : %s • mois %d/%d" % [
				str(project.get("name", "Produit Software")),
				int(project.get("months_done", 0)),
				int(project.get("months_total", 1))
			], 12))

	var active := SoftwareManager.active_products()
	if not active.is_empty():
		var product: Dictionary = active[0]
		var version := "%d.%d.%d" % [
			int(product.get("version_major", 1)),
			int(product.get("version_minor", 0)),
			int(product.get("version_patch", 0))
		]
		_content.add_child(UI.muted_label("En vente : %s v%s • %s licences ce mois • bugs connus %d" % [
			str(product.get("name", "Produit Software")),
			version,
			UI.money(int(product.get("licenses_last", 0))),
			int(product.get("bugs_known", 0))
		], 12))
		if str(product.get("kind", "")) == "UTILITY_SLICE" and SoftwareManager.project_for("UTILITY").is_empty():
			var maintenance := UI.card(UI.APP_PANEL, 10, 10)
			_content.add_child(maintenance)
			var maintenance_box := VBoxContainer.new()
			maintenance_box.add_theme_constant_override("separation", 6)
			maintenance.add_child(maintenance_box)
			maintenance_box.add_child(UI.eyebrow("FAIRE VIVRE LE PRODUIT"))
			var actions := HBoxContainer.new()
			actions.add_theme_constant_override("separation", 8)
			maintenance_box.add_child(actions)

			var patch_check := SoftwareManager.can_start_patch(str(product.get("id", "")))
			var patch := Button.new()
			patch.text = "Correctif\n1 mois"
			patch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			patch.disabled = not bool(patch_check.get("ok", false))
			patch.tooltip_text = str(patch_check.get("reason", ""))
			LOOK.button_style(patch, bool(patch_check.get("ok", false)))
			patch.pressed.connect(_start_patch.bind(str(product.get("id", ""))))
			actions.add_child(patch)

			var update_features := SoftwareManager.available_update_features(str(product.get("id", "")))
			if not update_features.is_empty():
				var update_select := OptionButton.new()
				update_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				update_select.custom_minimum_size.y = 48
				for feature_value in update_features:
					var feature_id := str(feature_value)
					update_select.add_item(str(PLAY.utility_feature(feature_id).get("label", feature_id)))
					update_select.set_item_metadata(update_select.item_count - 1, feature_id)
				actions.add_child(update_select)
				var update := Button.new()
				update.text = "Mise à jour\nnouvelle fonction"
				update.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				LOOK.button_style(update)
				update.pressed.connect(_start_selected_update.bind(str(product.get("id", "")), update_select))
				actions.add_child(update)

func _start_patch(product_id: String) -> void:
	if SoftwareManager.start_patch(product_id):
		status_changed.emit("Correctif Software lancé.")
		work_started.emit("PROJECT")
	else:
		var check := SoftwareManager.can_start_patch(product_id)
		status_changed.emit(str(check.get("reason", "Correctif impossible.")))
	_show_software_choice()

func _start_selected_update(product_id: String, select: OptionButton) -> void:
	var feature_id := UI.option_meta(select)
	if SoftwareManager.start_update(product_id, feature_id):
		status_changed.emit("Mise à jour Software lancée : %s." % str(PLAY.utility_feature(feature_id).get("label", feature_id)))
		work_started.emit("PROJECT")
	else:
		var check := SoftwareManager.can_start_update(product_id, feature_id)
		status_changed.emit(str(check.get("reason", "Mise à jour impossible.")))
	_show_software_choice()

func _resolve_project_decision(project_id: String, choice: String) -> void:
	if SoftwareManager.resolve_project_decision(project_id, choice):
		status_changed.emit("Décision Software appliquée.")
	else:
		status_changed.emit("Cette décision n'est plus disponible.")
	_show_software_choice()

func _choose_release(project_id: String, choice: String) -> void:
	if SoftwareManager.choose_release(project_id, choice):
		match choice:
			"RELEASE": status_changed.emit("Produit Software commercialisé.")
			"BETA": status_changed.emit("Bêta lancée pour un mois.")
			"DELAY": status_changed.emit("Sortie repoussée d'un mois pour finition.")
	else:
		status_changed.emit("Cette décision de sortie n'est plus disponible.")
	_show_software_choice()

func _show_activities() -> void:
	_mode = ViewMode.ACTIVITIES
	_title.text = "Petits contrats"
	_subtitle.text = "Choisissez une mission. Une seule peut être active à la fois."
	_back_button.visible = true
	_back_button.text = "Logiciel"
	_clear_content()

	var current := SoftwareManager.active_activity()
	if not current.is_empty():
		var current_id := str(current.get("id", ""))
		var approach_id := str(current.get("approach", "BALANCED"))
		var terms := SoftwareManager.activity_terms(current_id, approach_id)
		var running := UI.card(UI.APP_PANEL_ALT, 12, 12)
		var running_box := VBoxContainer.new()
		running.add_child(running_box)
		running_box.add_child(UI.eyebrow("EN COURS"))
		running_box.add_child(UI.label(ACTIVITY.label(current_id), 17))
		running_box.add_child(UI.muted_label("%s • mois %d/%d" % [
			PLAY.approach_label(approach_id),
			int(current.get("months_done", 0)),
			int(terms.get("months", 1))
		], 12))
		_content.add_child(running)

	var skill_parts: Array[String] = []
	for skill_value in PLAY.SKILL_ORDER:
		var skill_id := str(skill_value)
		skill_parts.append("%s %d XP" % [PLAY.skill_label(skill_id), SoftwareManager.skill_xp(skill_id)])
	_content.add_child(UI.muted_label("Savoir-faire : " + " • ".join(skill_parts), 11))

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

		var approaches := HBoxContainer.new()
		approaches.add_theme_constant_override("separation", 8)
		box.add_child(approaches)
		for approach_value in PLAY.APPROACH_ORDER:
			var approach_id := str(approach_value)
			var terms := SoftwareManager.activity_terms(activity_id, approach_id)
			var check := SoftwareManager.can_start_activity(activity_id, approach_id)
			var button := Button.new()
			button.text = "%s\n%d mois • net %s €\nXP %d • %s" % [
				PLAY.approach_label(approach_id),
				int(terms.get("months", 1)),
				UI.money(int(terms.get("net", 0))),
				int(terms.get("xp", 0)),
				str(PLAY.approach(approach_id).get("risk_label", ""))
			]
			button.custom_minimum_size = Vector2(185, 78)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			LOOK.button_style(button, approach_id == "BALANCED" and bool(check.get("ok", false)))
			button.disabled = not bool(check.get("ok", false))
			button.tooltip_text = "Coût %s €/mois • paiement %s € • XP %d%s" % [
				UI.money(int(terms.get("monthly_cost", 0))),
				UI.money(int(terms.get("payout", 0))),
				int(terms.get("xp", 0)),
				(" • " + str(check.get("reason", ""))) if button.disabled else ""
			]
			button.pressed.connect(_start_activity.bind(activity_id, approach_id))
			approaches.add_child(button)

	UI.prepare_touch_scroll_children(_content)

func _start_activity(activity_id: String, approach_id: String = "BALANCED") -> void:
	if SoftwareManager.start_activity(activity_id, approach_id):
		status_changed.emit("Contrat Software lancé : %s (%s)." % [
			ACTIVITY.label(activity_id), PLAY.approach_label(approach_id)
		])
		work_started.emit("ACTIVITY")
	else:
		var check := SoftwareManager.can_start_activity(activity_id, approach_id)
		status_changed.emit(str(check.get("reason", "Impossible de démarrer ce contrat.")))
	_show_activities()

func _show_product() -> void:
	_mode = ViewMode.PRODUCT
	_title.text = "Créer un produit logiciel"
	_subtitle.text = "Choisissez d'abord le type de logiciel, puis réglez uniquement ce produit."
	_back_button.visible = true
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
	_feature_checks = {}
	_target_select = null
	var family_id := UI.option_meta(_family_select)
	if family_id == "":
		return
	var state := SoftwareManager.family_state(family_id)
	_settings_box.add_child(UI.muted_label("Maîtrise %d/5 • %d contrat(s) terminé(s)" % [
		int(state.get("mastery", 0)), int(state.get("activities_done", 0))
	], 12))

	if family_id == "UTILITY":
		_settings_box.add_child(UI.eyebrow("PUBLIC CIBLE"))
		_target_select = OptionButton.new()
		_target_select.custom_minimum_size.y = 46
		for target_value in PLAY.UTILITY_TARGET_ORDER:
			var target_id := str(target_value)
			_target_select.add_item(PLAY.utility_target_label(target_id))
			_target_select.set_item_metadata(_target_select.item_count - 1, target_id)
		UI.select_meta(_target_select, "HOME")
		_target_select.item_selected.connect(func(_index): _refresh_product_preview())
		_settings_box.add_child(_target_select)

		_settings_box.add_child(UI.eyebrow("FONCTIONNALITÉS • 2 À 4"))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 6)
		_settings_box.add_child(grid)
		var default_count := 0
		for feature_value in PLAY.UTILITY_FEATURE_ORDER:
			var feature_id := str(feature_value)
			var feature := PLAY.utility_feature(feature_id)
			var check := CheckBox.new()
			check.text = str(feature.get("label", feature_id))
			check.custom_minimum_size = Vector2(300, 44)
			check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			check.tooltip_text = "%d mois de complexité • risque bugs %d" % [
				int(feature.get("months", 1)), int(feature.get("bugs", 0))
			]
			if default_count < 2:
				check.button_pressed = true
				default_count += 1
			check.toggled.connect(func(_pressed): _refresh_product_preview())
			grid.add_child(check)
			_feature_checks[feature_id] = check
		return

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

func _utility_features() -> Array:
	var result: Array = []
	for feature_value in PLAY.UTILITY_FEATURE_ORDER:
		var feature_id := str(feature_value)
		if _feature_checks.has(feature_id) and (_feature_checks[feature_id] as CheckBox).button_pressed:
			result.append(feature_id)
	return result

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
	var price_mode := UI.option_meta(_price_select)
	var lines: Array[String] = []

	if family_id == "UTILITY":
		var features := _utility_features()
		var target_id := UI.option_meta(_target_select) if _target_select != null else "HOME"
		var preview := SoftwareManager.utility_preview(features, target_id, price_mode)
		var check := SoftwareManager.can_start_utility(features, target_id)
		var metrics: Dictionary = preview.get("metrics", {})
		lines.append("%s • %d fonctionnalité(s)" % [PLAY.utility_target_label(target_id), features.size()])
		lines.append("%d mois • %s €/mois • coût total estimé %s €" % [
			int(preview.get("months", 0)),
			UI.money(int(preview.get("monthly_cost", 0))),
			UI.money(int(preview.get("total_cost", 0)))
		])
		lines.append("Fonctions %.0f • Ergonomie %.0f • Stabilité %.0f • Performances %.0f" % [
			float(metrics.get("features", 0.0)),
			float(metrics.get("usability", 0.0)),
			float(metrics.get("stability", 0.0)),
			float(metrics.get("performance", 0.0))
		])
		lines.append("Bugs estimés %d • licence %.0f € • qualité %.0f/100" % [
			int(preview.get("bugs", 0)),
			float(preview.get("price", 0.0)),
			float(preview.get("quality", 0.0))
		])
		if not bool(check.get("ok", false)):
			lines.append(str(check.get("reason", "")))
		_project_preview.text = "\n".join(lines)
		_project_start.disabled = not bool(check.get("ok", false))
		LOOK.button_style(_project_start, bool(check.get("ok", false)))
		return

	var levels := _levels()
	var preview := SoftwareManager.preview(family_id, levels, price_mode)
	var check := SoftwareManager.can_start(family_id, levels)
	var state := SoftwareManager.family_state(family_id)
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
	var price_mode := UI.option_meta(_price_select)
	if family_id == "UTILITY":
		var features := _utility_features()
		var target_id := UI.option_meta(_target_select) if _target_select != null else "HOME"
		if SoftwareManager.start_utility_project(features, target_id, price_mode, name):
			status_changed.emit("Utilitaire lancé en développement.")
			work_started.emit("PROJECT")
			_show_software_choice()
		else:
			var utility_check := SoftwareManager.can_start_utility(features, target_id)
			status_changed.emit(str(utility_check.get("reason", "Impossible de lancer cet utilitaire.")))
		_refresh_product_preview()
		return

	var levels := _levels()
	if SoftwareManager.start_project(family_id, levels, price_mode, name):
		status_changed.emit("Produit Software lancé.")
		work_started.emit("PROJECT")
		_show_software_choice()
	else:
		var check := SoftwareManager.can_start(family_id, levels)
		status_changed.emit(str(check.get("reason", "Impossible de lancer ce produit Software.")))
	_refresh_product_preview()
