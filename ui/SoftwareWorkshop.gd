extends ColorRect
## Atelier Logiciel. Logiciel 2.0 (14/10) : plus de listes déroulantes ni de cases à cocher.
## - Le choix du projet et le hub Logiciel sont des cartes illustrées ;
## - « Nouveau logiciel » ouvre le studio (type × public × plateforme, fonctions d'époque, effort en 3 phases) ;
## - les projets en cours montrent leurs trois phases, et l'effort des phases à venir reste réglable ;
## - le catalogue montre la note de la presse, et le prix se règle avec trois boutons.

signal close_requested
signal hardware_requested
signal status_changed(message: String)
signal work_started(kind: String)

const UI:= preload("res://ui/UiKit.gd")
const LOOK:= preload("res://ui/WorkshopStyle.gd")
const CAT:= preload("res://scripts/SoftwareCatalog.gd")
const ACTIVITY:= preload("res://scripts/SoftwareActivityCatalog.gd")
const PRESENTATION:= preload("res://scripts/ProjectPresentation.gd")
const PLAY:= preload("res://scripts/SoftwarePlayCatalog.gd")
const STUDIO:= preload("res://scripts/SoftwareStudio.gd")
const STUDIO_PANEL:= preload("res://ui/components/SoftwareStudioPanel.gd")
const ART_CPU:= "res://assets/art/v010/J3_moments/moment_premier_cpu.webp"
const ART_SOFTWARE:= "res://assets/art/v010/J3_moments/moment_architecture.webp"
const ART_CONTRACT:= "res://assets/art/v010/J3_moments/moment_contrat.webp"
const AMBER:= Color("d9822b")
const WOOD:= Color("3b2b1e")

enum ViewMode{PROJECT_CHOICE, SOFTWARE_CHOICE, ACTIVITIES, PRODUCT}

var _mode:= ViewMode.PROJECT_CHOICE
var _title: Label
var _subtitle: Label
var _back_button: Button
var _content: VBoxContainer
var _studio: Control

func _ready() -> void :
	color = Color(0.025, 0.055, 0.1, 0.78)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_shell()
	_studio = STUDIO_PANEL.new()
	add_child(_studio)
	_studio.connect("cancel_requested", _on_studio_cancel)
	_studio.connect("launch_requested", _on_studio_launch)

func open() -> void :
	visible = true
	if _studio != null:
		_studio.call("close")
	_show_project_choice()

func close() -> void :
	visible = false
	if _studio != null:
		_studio.call("close")

func current_view_name() -> String:
	match _mode:
		ViewMode.PROJECT_CHOICE: return "PROJECT_CHOICE"
		ViewMode.SOFTWARE_CHOICE: return "SOFTWARE_CHOICE"
		ViewMode.ACTIVITIES: return "ACTIVITIES"
		ViewMode.PRODUCT: return "PRODUCT"
	return "UNKNOWN"

func studio_visible() -> bool:
	return _studio != null and _studio.visible

func studio() -> Control:
	return _studio

func _build_shell() -> void :
	var margin:= MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)

	var panel:= LOOK.card(Color("fffaf1"), 20, 16)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(panel)

	var shell:= VBoxContainer.new()
	shell.add_theme_constant_override("separation", 10)
	panel.add_child(shell)

	var header:= HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	shell.add_child(header)

	var copy:= VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	header.add_child(copy)
	copy.add_child(LOOK.eyebrow("NOUVEAU PROJET"))
	_title = LOOK.label("Choisissez votre projet", 24)
	copy.add_child(_title)
	_subtitle = LOOK.muted_label("", 13)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(_subtitle)

	_back_button = Button.new()
	_back_button.text = "Retour"
	LOOK.button_style(_back_button)
	_back_button.pressed.connect(_go_back)
	header.add_child(_back_button)

	var close_button:= Button.new()
	close_button.text = "Garage"
	LOOK.button_style(close_button)
	close_button.pressed.connect( func(): close_requested.emit())
	header.add_child(close_button)

	var scroll:= ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.configure_touch_scroll(scroll)
	shell.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)

func _clear_content() -> void :
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

func _go_back() -> void :
	match _mode:
		ViewMode.PROJECT_CHOICE:
			close_requested.emit()
		ViewMode.SOFTWARE_CHOICE:
			_show_project_choice()
		ViewMode.ACTIVITIES, ViewMode.PRODUCT:
			_show_software_choice()

## Grande carte illustrée : une image, un titre, une phrase. Toute la carte se touche.
func _image_card(title: String, subtitle: String, art: String, height: int = 190) -> Button:
	var button:= Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_contents = true
	for state in ["normal", "hover", "pressed", "disabled"]:
		var edge:= AMBER if state in ["hover", "pressed"] else Color("d8c3a3")
		button.add_theme_stylebox_override(state, UI.stylebox(Color("2b1f15"), 16, 2, edge, 0))
	if ResourceLoader.exists(art):
		var picture:= TextureRect.new()
		picture.texture = load(art)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		picture.offset_left = 2; picture.offset_top = 2; picture.offset_right = -2; picture.offset_bottom = -2
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(picture)
	var band:= PanelContainer.new()
	band.anchor_left = 0.0; band.anchor_right = 1.0; band.anchor_top = 1.0; band.anchor_bottom = 1.0
	band.offset_top = -64; band.offset_left = 2; band.offset_right = -2; band.offset_bottom = -2
	band.add_theme_stylebox_override("panel", UI.stylebox(Color(0.12, 0.08, 0.05, 0.82), 0, 0, WOOD, 10))
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(band)
	var copy:= VBoxContainer.new()
	copy.add_theme_constant_override("separation", 0)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(copy)
	var title_label:= UI.label(title, 19)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title_label)
	var sub:= UI.label(subtitle, 13)
	sub.add_theme_color_override("font_color", Color("f6e3c6"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(sub)
	button.set_meta("title", title)
	return button

func _show_project_choice() -> void :
	_mode = ViewMode.PROJECT_CHOICE
	_title.text = "Quel projet voulez-vous lancer ?"
	_subtitle.text = "Un processeur à l'établi, ou un logiciel au studio."
	_back_button.visible = false
	_clear_content()

	var choices:= HBoxContainer.new()
	choices.add_theme_constant_override("separation", 14)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(choices)

	var processor:= _image_card("Processeur", "Concevoir une nouvelle génération de CPU.", ART_CPU, 260)
	processor.pressed.connect( func(): hardware_requested.emit())
	choices.add_child(processor)

	var software:= _image_card("Logiciel", "Des contrats pour se faire la main, ou vos propres logiciels.", ART_SOFTWARE, 260)
	software.disabled = not SoftwareManager.any_open()
	software.pressed.connect(_show_software_choice)
	choices.add_child(software)

func _show_software_choice() -> void :
	_mode = ViewMode.SOFTWARE_CHOICE
	_title.text = "Logiciel"
	_subtitle.text = "Contrats rapides, ou un logiciel à vous, de l'idée jusqu'à la presse."
	_back_button.visible = true
	_back_button.text = "Projets"
	_clear_content()

	var choices:= HBoxContainer.new()
	choices.add_theme_constant_override("separation", 14)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(choices)

	var contracts:= _image_card("Petits contrats", "Missions courtes : un peu d'argent, de l'expérience et de la maîtrise.", ART_CONTRACT)
	contracts.pressed.connect(_show_activities)
	choices.add_child(contracts)

	var free_types: Array = SoftwareManager.open_types().filter(func(id): return SoftwareManager.project_for(str(id)).is_empty())
	var product:= _image_card("Nouveau logiciel", "Un type, un public, une machine… et la presse jugera." if not free_types.is_empty() else "Chaque type a déjà un projet en cours.", ART_SOFTWARE)
	product.disabled = free_types.is_empty()
	product.pressed.connect(_show_product)
	choices.add_child(product)

	_add_compact_status()
	_add_notebook_summary()
	UI.prepare_touch_scroll_children(_content)

func _section(text: String) -> Label:
	var label:= LOOK.label(text, 17, Color("7a3f12"))
	return label

func _note(text: String, size: int = 12) -> Label:
	var label:= UI.muted_label(text, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _action(text: String, primary: bool = false) -> Button:
	var button:= Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LOOK.button_style(button, primary)
	return button

func _add_compact_status() -> void :
	var activity:= SoftwareManager.active_activity()
	if not SoftwareManager.projects.is_empty() or not activity.is_empty():
		_content.add_child(_section("En cours"))
	if not activity.is_empty():
		var activity_id:= str(activity.get("id", ""))
		var approach_id:= str(activity.get("approach", "BALANCED"))
		var terms:= SoftwareManager.activity_terms(activity_id, approach_id)
		_content.add_child(_note("Contrat : %s • %s • mois %d/%d" % [
			ACTIVITY.label(activity_id),
			PLAY.approach_label(approach_id),
			int(activity.get("months_done", 0)),
			int(terms.get("months", 1))
		], 13))

	for project_value in SoftwareManager.projects:
		var project: Dictionary = project_value
		var status:= str(project.get("status", "DEVELOPMENT"))
		if status == "DECISION":
			_content.add_child(_decision_card(project))
		elif status == "REVIEW":
			_content.add_child(_review_card(project))
		else:
			_content.add_child(_project_card(project))

	if not SoftwareManager.products.is_empty():
		_content.add_child(_section("Votre catalogue"))
	for product_value in SoftwareManager.products:
		_content.add_child(_product_card(product_value))

## Un projet en cours : ses trois phases, et l'effort des phases à venir encore réglable.
func _project_card(project: Dictionary) -> Control:
	var card:= UI.card(UI.APP_PANEL, 12, 12)
	var box:= VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var row:= PRESENTATION.software(project)
	var kind:= str(project.get("kind", ""))
	box.add_child(UI.label(str(project.get("name", "Logiciel")), 17))
	if kind == "STUDIO":
		var spec: Dictionary = project.get("spec", {})
		box.add_child(_note("%s pour %s, sur %s • %s" % [CAT.family_label(str(project.family)), STUDIO.audience_label(str(spec.get("audience", ""))).to_lower(),
			STUDIO.platform_phrase(str(spec.get("platform", ""))), str(row.detail)], 12))
		box.add_child(_phase_strip(project))
		var next_phase:= ""
		for phase in STUDIO.PHASE_ORDER:
			if next_phase == "" and SoftwareManager.can_edit_studio_phase(project, str(phase)):
				next_phase = str(phase)
		if next_phase != "":
			box.add_child(_token_editor(project, next_phase))
		var notes: Array = project.get("phase_notes", [])
		if not notes.is_empty():
			box.add_child(_note(str((notes.back() as Dictionary).get("text", "")), 12))
	elif str(project.get("status", "")) == "BETA":
		box.add_child(_note("Bêta en cours : tests utilisateurs ce mois-ci.", 12))
	else:
		box.add_child(_note("%s • %s" % [str(row.phase), str(row.detail)], 12))
	return card

func _phase_strip(project: Dictionary) -> Control:
	var strip:= HBoxContainer.new()
	strip.add_theme_constant_override("separation", 6)
	var current:= SoftwareManager.studio_phase_index(project)
	var total:= maxf(float(project.get("months_total", 1)), 1.0)
	var done:= float(project.get("work_done", 0.0))
	for i in range(STUDIO.PHASE_ORDER.size()):
		var cell:= VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 2)
		var label:= UI.label(("✓ " if i < current else "") + STUDIO.phase_label(str(STUDIO.PHASE_ORDER[i])), 12)
		label.add_theme_color_override("font_color", AMBER if i == current else (UI.APP_GREEN if i < current else UI.APP_MUTED))
		cell.add_child(label)
		var bar:= ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		bar.max_value = 1.0
		bar.value = clampf(done / total * 3.0 - float(i), 0.0, 1.0)
		bar.add_theme_stylebox_override("fill", UI.stylebox(AMBER, 4, 0, AMBER, 0))
		bar.add_theme_stylebox_override("background", UI.stylebox(Color("e9dcc7"), 4, 0, UI.APP_LINE, 0))
		cell.add_child(bar)
		strip.add_child(cell)
	return strip

## Les jetons de la prochaine phase : on peut encore les déplacer tant qu'elle n'a pas commencé.
func _token_editor(project: Dictionary, phase_id: String) -> Control:
	var box:= VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(_note("Prochaine phase, %s : vous pouvez encore déplacer l'effort." % STUDIO.phase_label(phase_id).to_lower(), 12))
	var row:= HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var tokens: Dictionary = ((project.get("spec", {}) as Dictionary).get("tokens", {}) as Dictionary).get(phase_id, {})
	var known:= SoftwareManager.known_areas(str(project.get("family", "")))
	for area in (STUDIO.PHASES[phase_id] as Dictionary).areas:
		var cell:= HBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 4)
		var minus:= Button.new()
		minus.text = "−"
		minus.custom_minimum_size = Vector2(44, 44)
		LOOK.button_style(minus)
		minus.custom_minimum_size = Vector2(48, 44)
		minus.pressed.connect(_shift_token.bind(str(project.id), phase_id, str(area), -1))
		cell.add_child(minus)
		var count:= int(tokens.get(area, 0))
		var tag:= "" if not known.has(str(area)) else " (%s)" % STUDIO.importance_label(float(known[area]))
		var label:= UI.label("%s%s\n%s" % [STUDIO.area_label(str(area)), tag, "●".repeat(count) + "○".repeat(maxi(0, STUDIO.TOKENS_PER_PHASE - count))], 12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(label)
		var plus:= Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(44, 44)
		LOOK.button_style(plus)
		plus.custom_minimum_size = Vector2(48, 44)
		plus.pressed.connect(_shift_token.bind(str(project.id), phase_id, str(area), 1))
		cell.add_child(plus)
		row.add_child(cell)
	return box

## + prend un jeton au domaine le plus chargé ; − le rend au domaine le moins chargé (6 jetons au total).
func _shift_token(project_id: String, phase_id: String, area_id: String, delta: int) -> void :
	var project:= SoftwareManager.project_by_id(project_id)
	if project.is_empty():
		return
	var row: Dictionary = (((project.get("spec", {}) as Dictionary).get("tokens", {}) as Dictionary).get(phase_id, {}) as Dictionary).duplicate()
	var other:= ""
	for area in row.keys():
		if str(area) == area_id:
			continue
		if other == "":
			other = str(area)
		elif delta > 0 and int(row[area]) > int(row[other]):
			other = str(area)
		elif delta < 0 and int(row[area]) < int(row[other]):
			other = str(area)
	if other == "" or (delta > 0 and int(row[other]) <= 0) or (delta < 0 and int(row.get(area_id, 0)) <= 0):
		return
	row[area_id] = int(row.get(area_id, 0)) + delta
	row[other] = int(row[other]) - delta
	if SoftwareManager.set_studio_tokens(project_id, phase_id, row):
		SoundManager.play("click", 1.1)
		_show_software_choice()

func _decision_card(project: Dictionary) -> Control:
	var decision: Dictionary = project.get("pending_decision", {})
	var card:= UI.card(UI.APP_PANEL_ALT, 12, 12)
	var box:= VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	box.add_child(UI.eyebrow("DÉCISION REQUISE"))
	box.add_child(UI.label(str(decision.get("title", "Problème de développement")), 17))
	box.add_child(_note(str(decision.get("text", "")), 12))
	var actions:= HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var rewrite:= _action("Réécrire\n+1 mois, moins de bugs", true)
	rewrite.pressed.connect(_resolve_project_decision.bind(str(project.get("id", "")), "REWRITE"))
	actions.add_child(rewrite)
	var cut:= _action("Retirer la fonction\nmoins ambitieux")
	cut.disabled = (project.get("features", []) as Array).size() <= 2
	cut.pressed.connect(_resolve_project_decision.bind(str(project.get("id", "")), "CUT"))
	actions.add_child(cut)
	var quick:= _action("Corriger vite\nplus de risque")
	quick.pressed.connect(_resolve_project_decision.bind(str(project.get("id", "")), "QUICK_FIX"))
	actions.add_child(quick)
	return card

func _review_card(project: Dictionary) -> Control:
	var card:= UI.card(UI.APP_PANEL_ALT, 12, 12)
	var box:= VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	box.add_child(UI.eyebrow("PRÊT À SORTIR"))
	box.add_child(UI.label(str(project.get("name", "Logiciel")), 17))
	var metrics: Dictionary = project.get("metrics", {})
	box.add_child(_note("Fonctions %.0f • Ergonomie %.0f • Stabilité %.0f • Performances %.0f • bugs %d" % [
		float(metrics.get("features", 0.0)), float(metrics.get("usability", 0.0)),
		float(metrics.get("stability", 0.0)), float(metrics.get("performance", 0.0)), int(project.get("bugs", 0))], 12))
	var actions:= HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	for release_choice in ["RELEASE", "BETA", "DELAY"]:
		var text: String = {"RELEASE":"Sortir maintenant\nla presse jugera", "BETA":"Faire une bêta\n+1 mois de tests", "DELAY":"Repousser\n+1 mois de finition"}[release_choice]
		var button:= _action(text, release_choice == "RELEASE")
		button.pressed.connect(_choose_release.bind(str(project.get("id", "")), release_choice))
		actions.add_child(button)
	return card

func _product_card(product: Dictionary) -> Control:
	var version:= "%d.%d.%d" % [int(product.get("version_major", 1)), int(product.get("version_minor", 0)), int(product.get("version_patch", 0))]
	var card:= UI.card(UI.APP_PANEL, 12, 12)
	var outer:= HBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	card.add_child(outer)
	if str(product.get("kind", "")) == "STUDIO":
		outer.add_child(_note_badge(float(product.get("note_live", product.get("note", 5.0))), float(product.get("note", 5.0))))
	var box:= VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	outer.add_child(box)
	var fresh:= int(product.get("market_months", 0)) == 0 and str(product.get("status", "")) == "ACTIVE"
	box.add_child(UI.eyebrow("VIENT DE SORTIR" if fresh else ("EN VENTE" if str(product.get("status", "")) == "ACTIVE" else "CATALOGUE SUSPENDU")))
	box.add_child(UI.label("%s • v%s" % [str(product.get("name", "Logiciel")), version], 17))
	if str(product.get("kind", "")) == "STUDIO":
		box.add_child(_note("%s pour %s, sur %s" % [CAT.family_label(str(product.family)), STUDIO.audience_label(str(product.get("audience", ""))).to_lower(), STUDIO.platform_phrase(str(product.get("platform", "")))], 12))
		if str(product.get("missed", "")) != "":
			box.add_child(_note("Presse : " + str(product.missed), 12))
	box.add_child(_note("%s licences ce mois • recettes %s € • support %s € • marge %s €/mois\nMarge cumulée %s € • développement %s € • bugs connus %d" % [
		UI.money(int(product.get("licenses_last", 0))), UI.money(int(product.get("revenue_last", 0))), UI.money(int(product.get("support_last", 0))),
		UI.money(int(product.get("margin_last", 0))), UI.money(int(product.get("margin_total", 0))), UI.money(int(product.get("development_spent", 0))),
		int(product.get("bugs_known", 0))], 12))
	box.add_child(_note(SoftwareManager.product_feedback(product), 12))
	var prices:= HBoxContainer.new()
	prices.add_theme_constant_override("separation", 6)
	box.add_child(prices)
	for mode in ["LOW", "MARKET", "PREMIUM"]:
		var selected: bool = str(product.get("price_mode", "MARKET")) == mode
		var price:= SoftwareManager.studio_price(str(product.family), str(product.get("audience", "HOBBY")), mode) if str(product.get("kind", "")) == "STUDIO" else CAT.license_price(str(product.family), mode)
		var button:= _action("%s%s\n%s €" % ["✓ " if selected else "", str(CAT.PRICE_MODES[mode].label), UI.money(int(price))], selected)
		button.pressed.connect(_set_price.bind(str(product.id), mode))
		prices.add_child(button)
	var actions:= HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	box.add_child(actions)
	var is_active:= str(product.get("status", "")) == "ACTIVE"
	if str(product.get("kind", "")) in ["UTILITY_SLICE", "STUDIO"] and SoftwareManager.project_for(str(product.get("family", ""))).is_empty():
		var patch_check:= SoftwareManager.can_start_patch(str(product.get("id", "")))
		var patch:= _action("Correctif\n1 mois de travail", bool(patch_check.get("ok", false)))
		patch.disabled = not bool(patch_check.get("ok", false))
		patch.tooltip_text = str(patch_check.get("reason", ""))
		patch.pressed.connect(_start_patch.bind(str(product.get("id", ""))))
		actions.add_child(patch)
	var retire:= _action("Suspendre la vente" if is_active else "Remettre en vente")
	retire.pressed.connect(_toggle_product.bind(str(product.id), not is_active))
	actions.add_child(retire)
	if str(product.get("kind", "")) == "UTILITY_SLICE" and SoftwareManager.project_for("UTILITY").is_empty():
		var update_features:= SoftwareManager.available_update_features(str(product.get("id", "")))
		if not update_features.is_empty():
			box.add_child(_note("Mise à jour : ajouter une fonction", 12))
			var flow:= HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", 6)
			flow.add_theme_constant_override("v_separation", 6)
			box.add_child(flow)
			for feature_value in update_features:
				var feature_id:= str(feature_value)
				var chip:= Button.new()
				chip.text = "+ " + str(PLAY.utility_feature(feature_id).get("label", feature_id))
				LOOK.button_style(chip)
				chip.pressed.connect(_start_update.bind(str(product.get("id", "")), feature_id))
				flow.add_child(chip)
	return card

## La pastille de note : grande, colorée, avec la note de sortie si elle a changé depuis.
func _note_badge(live: float, launch: float) -> Control:
	var panel:= PanelContainer.new()
	var tint:= Color("2f7a3a") if live >= 7.5 else (Color("d9822b") if live >= 5.5 else Color("b3261e"))
	panel.add_theme_stylebox_override("panel", UI.stylebox(tint, 40, 0, tint, 8))
	panel.custom_minimum_size = Vector2(78, 78)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var box:= VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", -2)
	panel.add_child(box)
	var big:= UI.label(("%.1f" % live).replace(".", ","), 24)
	big.add_theme_color_override("font_color", Color.WHITE)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(big)
	var small:= UI.label("/10" if absf(live - launch) < 0.15 else ("sortie %s" % ("%.1f" % launch).replace(".", ",")), 11)
	small.add_theme_color_override("font_color", Color("fff2dc"))
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(small)
	return panel

## Le carnet de Nora en une carte : combinaisons connues et meilleures notes.
func _add_notebook_summary() -> void :
	var book: Dictionary = SoftwareManager.notebook
	var combos: Dictionary = book.get("combos", {})
	if combos.is_empty():
		return
	_content.add_child(_section("Le carnet de Nora"))
	var card:= UI.card(Color("fbf1df"), 12, 12)
	_content.add_child(card)
	var box:= VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var keys:= combos.keys()
	keys.sort()
	for key in keys:
		var parts:= str(key).split(":")
		if parts.size() != 2:
			continue
		var value:= int(combos[key])
		var line:= UI.label("%s  %s pour %s — %s" % [STUDIO.FIT_STARS[clampi(value, 0, 3)], CAT.family_label(parts[0]), STUDIO.audience_label(parts[1]).to_lower(), STUDIO.FIT_LABELS[clampi(value, 0, 3)].to_lower()], 13)
		line.add_theme_color_override("font_color", Color("2f7a3a") if value >= 2 else Color("b3261e") if value == 0 else UI.APP_TEXT)
		box.add_child(line)
	var areas: Dictionary = book.get("areas", {})
	for type_key in areas.keys():
		var learned: Dictionary = areas[type_key]
		if learned.is_empty():
			continue
		var essentials: Array[String] = []
		for area in learned.keys():
			if float(learned[area]) >= 1.25:
				essentials.append(STUDIO.area_label(str(area)).to_lower())
		box.add_child(_note("%s : %d domaine(s) d'effort compris sur 9%s." % [CAT.family_label(str(type_key)), learned.size(),
			(" — essentiel : " + ", ".join(essentials)) if not essentials.is_empty() else ""], 12))

func _set_price(product_id: String, mode: String) -> void :
	if SoftwareManager.set_product_price(product_id, mode):
		status_changed.emit("Prix ajusté. Les ventes du prochain mois mesureront ce choix.")
		_show_software_choice()

func _start_patch(product_id: String) -> void :
	if SoftwareManager.start_patch(product_id):
		status_changed.emit("Correctif Software lancé.")
		work_started.emit("PROJECT")
	else:
		var check:= SoftwareManager.can_start_patch(product_id)
		status_changed.emit(str(check.get("reason", "Correctif impossible.")))
	_show_software_choice()

func _start_update(product_id: String, feature_id: String) -> void :
	if SoftwareManager.start_update(product_id, feature_id):
		status_changed.emit("Mise à jour Software lancée : %s." % str(PLAY.utility_feature(feature_id).get("label", feature_id)))
		work_started.emit("PROJECT")
	else:
		var check:= SoftwareManager.can_start_update(product_id, feature_id)
		status_changed.emit(str(check.get("reason", "Mise à jour impossible.")))
	_show_software_choice()

func _resolve_project_decision(project_id: String, choice: String) -> void :
	if SoftwareManager.resolve_project_decision(project_id, choice):
		status_changed.emit("Décision Software appliquée.")
	else:
		status_changed.emit("Cette décision n'est plus disponible.")
	_show_software_choice()

func _choose_release(project_id: String, choice: String) -> void :
	if SoftwareManager.choose_release(project_id, choice):
		match choice:
			"RELEASE": status_changed.emit("Logiciel sorti : la presse a rendu son verdict.")
			"BETA": status_changed.emit("Bêta lancée : un mois de travail de tests, réparti selon l’équipe disponible.")
			"DELAY": status_changed.emit("Un mois de travail de finition ajouté au planning.")
	else:
		status_changed.emit("Cette décision de sortie n'est plus disponible.")
	_show_software_choice()

func _show_activities() -> void :
	_mode = ViewMode.ACTIVITIES
	_title.text = "Petits contrats"
	_subtitle.text = "Choisissez une mission. Une seule peut être active à la fois."
	_back_button.visible = true
	_back_button.text = "Logiciel"
	_clear_content()

	var current:= SoftwareManager.active_activity()
	if not current.is_empty():
		var current_id:= str(current.get("id", ""))
		var approach_id:= str(current.get("approach", "BALANCED"))
		var terms:= SoftwareManager.activity_terms(current_id, approach_id)
		var running:= UI.card(UI.APP_PANEL_ALT, 12, 12)
		var running_box:= VBoxContainer.new()
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
		var skill_id:= str(skill_value)
		skill_parts.append("%s %d XP" % [PLAY.skill_label(skill_id), SoftwareManager.skill_xp(skill_id)])
	_content.add_child(UI.muted_label("Savoir-faire : " + " • ".join(skill_parts), 11))

	for activity_value in SoftwareManager.available_activities():
		var activity_id:= str(activity_value)
		var data:= ACTIVITY.data(activity_id)
		var card:= UI.card(UI.APP_PANEL, 12, 12)
		_content.add_child(card)
		var box:= VBoxContainer.new()
		box.add_theme_constant_override("separation", 5)
		card.add_child(box)

		var title:= UI.label(ACTIVITY.label(activity_id), 17)
		box.add_child(title)
		var family:= str(data.get("family", "UTILITY"))
		box.add_child(UI.muted_label("%s • maîtrise %d/5" % [
			CAT.family_label(family), SoftwareManager.mastery(family)
		], 11))

		var pitch:= UI.muted_label(str(data.get("pitch", "")), 12)
		pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(pitch)

		var approaches:= HBoxContainer.new()
		approaches.add_theme_constant_override("separation", 8)
		box.add_child(approaches)
		for approach_value in PLAY.APPROACH_ORDER:
			var approach_id:= str(approach_value)
			var terms:= SoftwareManager.activity_terms(activity_id, approach_id)
			var check:= SoftwareManager.can_start_activity(activity_id, approach_id)
			var button:= Button.new()
			button.text = "%s\n%s • net estimé %s €\nXP %d • %s" % [
				PLAY.approach_label(approach_id),
				_months_text(int(terms.get("calendar_months", 1))),
				UI.money(int(terms.get("net_estimate", 0))),
				int(terms.get("xp", 0)),
				str(PLAY.approach(approach_id).get("risk_label", ""))
			]
			button.custom_minimum_size = Vector2(185, 78)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			LOOK.button_style(button, approach_id == "BALANCED" and bool(check.get("ok", false)))
			button.disabled = not bool(check.get("ok", false))
			button.tooltip_text = "Coût %s €/mois • paiement %s € • XP %d%s" % [
				UI.money(int(terms.get("monthly_cash_cost", terms.get("monthly_cost", 0)))),
				UI.money(int(terms.get("payout", 0))),
				int(terms.get("xp", 0)),
				(" • " + str(check.get("reason", ""))) if button.disabled else ""
			]
			button.pressed.connect(_start_activity.bind(activity_id, approach_id))
			approaches.add_child(button)

	UI.prepare_touch_scroll_children(_content)

func _start_activity(activity_id: String, approach_id: String = "BALANCED") -> void :
	if SoftwareManager.start_activity(activity_id, approach_id):
		status_changed.emit("Contrat Software lancé : %s (%s)." % [
			ACTIVITY.label(activity_id), PLAY.approach_label(approach_id)
		])
		work_started.emit("ACTIVITY")
	else:
		var check:= SoftwareManager.can_start_activity(activity_id, approach_id)
		status_changed.emit(str(check.get("reason", "Impossible de démarrer ce contrat.")))
	_show_activities()


## « Nouveau logiciel » : le studio s'ouvre par-dessus le hub.
func _show_product() -> void :
	_mode = ViewMode.PRODUCT
	if _studio == null:
		return
	_studio.call("open")

func _on_studio_cancel() -> void :
	_studio.call("close")
	_show_software_choice()

func _on_studio_launch(spec: Dictionary, product_name: String) -> void :
	if SoftwareManager.start_studio_project(spec, product_name):
		var project:= SoftwareManager.project_for(str(spec.get("type", "")))
		status_changed.emit("%s entre en développement." % str(project.get("name", "Le logiciel")))
		work_started.emit("PROJECT")
		_studio.call("play_launch", str(project.get("name", product_name)))
		_show_software_choice()
	else:
		var check:= SoftwareManager.can_start_studio(spec)
		_studio.call("show_error", str(check.get("reason", "Impossible de lancer ce logiciel.")))

func _toggle_product(product_id: String, active: bool) -> void :
	if SoftwareManager.set_product_active(product_id, active):
		status_changed.emit("Produit remis en vente." if active else "Catalogue suspendu. Vous pouvez reprendre sa commercialisation.")
	else:
		status_changed.emit("Terminez la maintenance en cours avant de suspendre ce produit.")
	_show_software_choice()

## Lot 0 (08/10) : sans développeur affecté, la durée valait -1 et s'affichait « ~-1 mois ».
static func _months_text(months: int) -> String:
	if months < 0:
		return "aucun développeur affecté"
	return "~%d mois" % months
