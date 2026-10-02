extends VBoxContainer
## V0.10 / Gammes — Produits > Gammes : mémoire, alimentations, boîtiers.
## Une famille à la fois : ce qui est en vente, la concurrence, le modèle en développement, et l'atelier
## de conception. Chaque réglage montre ce qu'il change avant de toucher (pastilles vertes / rouges),
## en unités de l'époque. Le récapitulatif compare au meilleur rival, chiffre le coût et le délai, et
## annonce la note probable de la presse.

signal status_changed(message: String)

const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")
const CAT := preload("res://scripts/ComponentCatalog.gd")
const CHIPS := preload("res://ui/components/ImpactChips.gd")
const ART := preload("res://ui/components/ComponentArt.gd")
const GOOD := Color("2f7a3a")
const BAD := Color("b3261e")
const WARN := Color("a8631f")

var selected := "MEMORY"
var drafts := {}
var _cards_row: HBoxContainer
var _content: VBoxContainer
var _wide := true
var _name_edit: LineEdit
var last_preview: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var intro := UI.muted_label("Tout ce qui entoure le processeur. Chaque famille a ses clients, ses rivaux et son rythme : la mémoire vieillit vite, un boîtier lentement.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(intro)
	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 8)
	add_child(_cards_row)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	add_child(_content)
	ComponentManager.components_changed.connect(_on_changed)
	refresh()

func _on_changed() -> void:
	if is_visible_in_tree():
		refresh()

func set_viewport_width(width: float) -> void:
	var wide := width >= 900.0
	if wide != _wide:
		_wide = wide
		refresh()

func select_family(family_id: String) -> void:
	if CAT.FAMILIES.has(family_id):
		selected = family_id
		refresh()

func draft(family_id: String) -> Dictionary:
	if not drafts.has(family_id):
		var target := "OEM"
		drafts[family_id] = {"levels":CAT.default_levels(family_id), "price":"MARKET", "target":target, "name":""}
	var d: Dictionary = drafts[family_id]
	# Le niveau maximal a pu baisser (nouvelle partie) : on borne.
	for key in (d.levels as Dictionary).keys():
		d.levels[key] = clampi(int(d.levels[key]), 1, ComponentManager.max_level(family_id))
	if not CAT.open_segments(family_id, TimeManager.year).has(str(d.target)):
		d["target"] = "OEM"
	return d

func refresh() -> void:
	if _content == null:
		return
	if _name_edit != null and is_instance_valid(_name_edit) and _name_edit.has_focus():
		return
	_build_family_cards()
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_name_edit = null
	if not ComponentManager.is_open(selected):
		_content.add_child(_locked_card())
	else:
		_build_open_family()
	UI.prepare_touch_scroll_children(self)

# --- En-tête : une carte par famille ------------------------------------------------------

func _build_family_cards() -> void:
	for child in _cards_row.get_children():
		_cards_row.remove_child(child)
		child.queue_free()
	for family_value in CAT.FAMILY_ORDER:
		var family_id := str(family_value)
		var open := ComponentManager.is_open(family_id)
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_toggle_style(button, family_id == selected)
		button.custom_minimum_size = Vector2(0, 86)
		button.pressed.connect(select_family.bind(family_id))
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 8
		row.offset_right = -8
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		var art: Control = ART.new()
		art.custom_minimum_size = Vector2(70, 70)
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		art.call("setup", family_id, TimeManager.year, not open)
		row.add_child(art)
		var text := VBoxContainer.new()
		text.alignment = BoxContainer.ALIGNMENT_CENTER
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text)
		var title := UI.label(CAT.family_label(family_id), 15)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_child(title)
		var status := UI.muted_label(_family_status(family_id), 11)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_child(status)
		_cards_row.add_child(button)

func _family_status(family_id: String) -> String:
	if not ComponentManager.is_open(family_id):
		return "Ouvre en %d" % maxi(int(CAT.family(family_id).get("unlock_year", 1980)), TimeManager.year + 1) if family_id != "MEMORY" else "Bientôt"
	var actives := ComponentManager.active_products(family_id).size()
	var share := float((ComponentManager.market_view.get(family_id, {}) as Dictionary).get("player_share", 0.0))
	var project := ComponentManager.project_for(family_id)
	var parts: Array[String] = []
	if actives > 0:
		parts.append("%d en vente • %s" % [actives, _pct(share)])
	if not project.is_empty():
		parts.append("1 en cours")
	if parts.is_empty():
		parts.append("À conquérir")
	return " • ".join(parts)

func _locked_card() -> Control:
	var card := UI.card(UI.APP_PANEL, 14, 16)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	box.add_child(UI.label(CAT.family_label(selected), 18))
	var pitch := UI.muted_label(str(CAT.family(selected).get("pitch", "")), 13)
	pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(pitch)
	var when := UI.label(ComponentManager.unlock_text(selected), 13)
	when.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	when.add_theme_color_override("font_color", WARN)
	box.add_child(when)
	return card

# --- Famille ouverte ----------------------------------------------------------------

func _build_open_family() -> void:
	_content.add_child(_range_section())
	var project := ComponentManager.project_for(selected)
	if not project.is_empty():
		_content.add_child(_project_card(project))
	else:
		_content.add_child(_designer())
	_content.add_child(_mastery_card())

func _range_section() -> Control:
	var card := UI.card(UI.APP_PANEL, 14, 14)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var view: Dictionary = ComponentManager.market_view.get(selected, {})
	box.add_child(UI.eyebrow("VOTRE GAMME • MARCHÉ %s" % CAT.family_label(selected).to_upper()))
	var actives := ComponentManager.active_products(selected)
	if actives.is_empty():
		var none := UI.muted_label("Aucun modèle en vente. Le marché fait %s unités par mois : à vous de jouer." % UI.money(int(view.get("units", int(CAT.family_market_units(selected, ComponentManager.now_f(), BalanceManager.market_demand_factor()))))), 13)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(none)
	for product_value in actives:
		box.add_child(_product_row(product_value as Dictionary))
	var rows: Array = view.get("rows", [])
	if not rows.is_empty():
		box.add_child(UI.muted_label("Parts de marché le mois dernier (%s unités) :" % UI.money(int(view.get("units", 0))), 12))
		var shown := 0
		for row_value in rows:
			var row: Dictionary = row_value
			if shown >= 5 and not bool(row.get("player", false)):
				continue
			box.add_child(_share_row(row))
			shown += 1
	return card

func _product_row(product: Dictionary) -> Control:
	var panel := UI.card(UI.APP_PANEL_ALT, 10, 10)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	var title := UI.label("%s  •  %s/10" % [str(product.name), _num(float(product.get("review", 0.0)))], 15)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var retire := Button.new()
	retire.text = "Retirer"
	retire.custom_minimum_size = Vector2(0, 36)
	LOOK.button_style(retire, false)
	retire.pressed.connect(_retire.bind(str(product.id)))
	head.add_child(retire)
	var launched := "Sorti en %s %d pour « %s » • %s à %s €" % [_month_name(int(product.get("month", 1))), int(product.get("year", 0)),
		CAT.segment_label(selected, str(product.get("target", "OEM"))), CAT.price_label(str(product.get("price_mode", "MARKET"))).to_lower(), _num(float(product.price))]
	var line := UI.muted_label(launched, 12)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(line)
	var sales := UI.label("Le mois dernier : %s ventes • marge %s € • part %s" % [UI.money(int(product.get("units_last", 0))),
		UI.money(int(product.get("margin_last", 0))), _pct(float(product.get("share_last", 0.0)))], 13)
	sales.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sales)
	# Face aux rivaux aujourd'hui (le marché attend mieux chaque année).
	var standing := ComponentManager.standing(product)
	var standing_label := UI.label("Face aux rivaux : %s" % str(standing.text), 12)
	standing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	standing_label.add_theme_color_override("font_color", GOOD if str(standing.level) == "good" else (WARN if str(standing.level) == "warn" else BAD))
	box.add_child(standing_label)
	return panel

func _share_row(row: Dictionary) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	var name := UI.label("%s — %s" % [str(row.company), str(row.name)], 12)
	name.custom_minimum_size = Vector2(250, 0)
	name.clip_text = true
	if bool(row.get("player", false)):
		name.add_theme_color_override("font_color", Color("a85a22"))
	line.add_child(name)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = float(row.share)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(120, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("d9822b") if bool(row.get("player", false)) else Color("9b8a74")
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("efe3cf")
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	line.add_child(bar)
	line.add_child(UI.muted_label(_pct(float(row.share)), 12))
	return line

func _project_card(project: Dictionary) -> Control:
	var card := UI.card(UI.APP_PANEL, 14, 14)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	box.add_child(UI.eyebrow("EN DÉVELOPPEMENT"))
	box.add_child(UI.label("%s — pour « %s »" % [str(project.name), CAT.segment_label(selected, str(project.target))], 16))
	var done := int(project.get("months_done", 0))
	var total := int(project.get("months_total", 1))
	var bar := ProgressBar.new()
	bar.max_value = float(total)
	bar.value = float(done)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	box.add_child(bar)
	box.add_child(UI.muted_label("Mois %d sur %d • %s € par mois • sortie automatique, la presse le testera aussitôt." % [done, total, UI.money(int(project.monthly_cost))], 12))
	var levels: Dictionary = project.levels
	var bits: Array[String] = []
	for axis in CAT.settings_of(selected):
		bits.append("%s %d" % [CAT.setting_label(selected, str(axis)), int(levels.get(axis, 3))])
	box.add_child(UI.muted_label(" • ".join(bits) + " • " + CAT.price_label(str(project.price_mode)), 12))
	var cancel := Button.new()
	cancel.text = "Abandonner ce projet"
	cancel.custom_minimum_size = Vector2(0, 38)
	LOOK.button_style(cancel, false)
	cancel.pressed.connect(func():
		if ComponentManager.cancel_project(selected):
			status_changed.emit("Projet abandonné.")
		refresh())
	box.add_child(cancel)
	return card

func _mastery_card() -> Control:
	var card := UI.card(UI.APP_PANEL, 14, 12)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var m := ComponentManager.mastery(selected)
	box.add_child(UI.label("Maîtrise : %d / %d  •  réglages jusqu'au niveau %d" % [m, CAT.MAX_MASTERY, ComponentManager.max_level(selected)], 14))
	var hint := UI.muted_label("Vos deux premiers modèles vous apprennent le métier (niveaux 4 puis 5). Ensuite, un programme de maîtrise affine toute la gamme (+1 point sur chaque qualité par niveau).", 12)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var program: Dictionary = ComponentManager.family_state(selected).get("program", {})
	if not program.is_empty():
		box.add_child(UI.label("Programme en cours : encore %d mois." % int(program.get("months_left", 0)), 13))
	elif m < CAT.MAX_MASTERY:
		var cost := CAT.program_cost(selected, TimeManager.year, m)
		var button := Button.new()
		button.text = "Lancer un programme de maîtrise (%d mois, %s €)" % [CAT.PROGRAM_MONTHS, UI.money(cost)]
		button.custom_minimum_size = Vector2(0, 40)
		button.disabled = not Economy.can_afford(cost / CAT.PROGRAM_MONTHS * 2, "Recherche")
		LOOK.button_style(button, false)
		button.pressed.connect(func():
			if ComponentManager.start_program(selected):
				status_changed.emit("Programme de maîtrise lancé.")
			refresh())
		box.add_child(button)
	return card

# --- Atelier de conception ----------------------------------------------------------

func _designer() -> Control:
	var d := draft(selected)
	var levels: Dictionary = d.levels
	var price_mode := str(d.price)
	var target := str(d.target)
	var preview := ComponentManager.preview(selected, levels, price_mode, target)
	last_preview = preview
	var launch_year := int(floor(float(preview.launch_f)))
	var card := UI.card(UI.APP_PANEL, 14, 14)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	card.add_child(outer)
	outer.add_child(UI.eyebrow("CONCEVOIR UN NOUVEAU MODÈLE"))
	# 1. Pour qui ?
	outer.add_child(UI.label("1. Pour quels clients ?", 14))
	var segments := HFlowContainer.new()
	segments.add_theme_constant_override("h_separation", 6)
	segments.add_theme_constant_override("v_separation", 6)
	outer.add_child(segments)
	for segment_value in CAT.open_segments(selected, TimeManager.year):
		var segment_id := str(segment_value)
		var button := Button.new()
		var prio: Array[String] = []
		for axis in CAT.priorities(selected, segment_id):
			prio.append(CAT.quality_label(selected, str(axis)))
		button.text = "%s\nveulent : %s" % [CAT.segment_label(selected, segment_id), ", ".join(prio)]
		_toggle_style(button, segment_id == target)
		button.custom_minimum_size = Vector2(200, 52)
		button.pressed.connect(_set_target.bind(segment_id))
		segments.add_child(button)
	var columns := BoxContainer.new()
	columns.vertical = not _wide
	columns.add_theme_constant_override("separation", 14)
	outer.add_child(columns)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	# 2. Réglages
	left.add_child(UI.label("2. Les réglages (3 = le standard de %d)" % launch_year, 14))
	for setting_value in CAT.settings_of(selected):
		left.add_child(_setting_row(str(setting_value), levels, price_mode, target, launch_year))
	# 3. Prix
	left.add_child(UI.label("3. Le prix", 14))
	var prices := HFlowContainer.new()
	prices.add_theme_constant_override("h_separation", 6)
	prices.add_theme_constant_override("v_separation", 6)
	left.add_child(prices)
	for mode_value in CAT.PRICE_ORDER:
		var mode := str(mode_value)
		var price_button := Button.new()
		price_button.text = "%s\n%s € • %s" % [CAT.price_label(mode), _num(CAT.sale_price(selected, levels, mode, ComponentManager.own_fab())), str((CAT.PRICE_MODES[mode] as Dictionary).hint)]
		_toggle_style(price_button, mode == price_mode)
		price_button.custom_minimum_size = Vector2(150, 52)
		price_button.pressed.connect(_set_price.bind(mode))
		prices.add_child(price_button)
	# Récapitulatif
	right.add_child(_summary(preview, target))
	# Lancer
	var launch_row := HBoxContainer.new()
	launch_row.add_theme_constant_override("separation", 8)
	outer.add_child(launch_row)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = ComponentManager.next_name(selected)
	_name_edit.text = str(d.get("name", ""))
	_name_edit.custom_minimum_size = Vector2(200, 44)
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LOOK.input_style(_name_edit)
	_name_edit.text_changed.connect(func(text: String): d["name"] = text)
	launch_row.add_child(_name_edit)
	var check := ComponentManager.can_start(selected, levels)
	var start := Button.new()
	start.text = "Lancer le développement (%d mois)" % int(preview.months)
	start.custom_minimum_size = Vector2(0, 44)
	start.disabled = not bool(check.get("ok", false))
	LOOK.button_style(start, true)
	start.pressed.connect(_start)
	launch_row.add_child(start)
	if not bool(check.get("ok", false)):
		var why := UI.label(str(check.get("reason", "")), 12)
		why.add_theme_color_override("font_color", BAD)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outer.add_child(why)
	return card

func _setting_row(setting_id: String, levels: Dictionary, price_mode: String, target: String, launch_year: int) -> Control:
	var level := int(levels.get(setting_id, 3))
	var data := CAT.setting(selected, setting_id)
	var panel := UI.card(UI.APP_PANEL_ALT, 10, 8)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	box.add_child(head)
	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(44, 40)
	LOOK.button_style(minus, false)
	minus.disabled = level <= 1
	minus.pressed.connect(_step.bind(setting_id, -1))
	head.add_child(minus)
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_constant_override("separation", 0)
	head.add_child(title)
	var dots := "●".repeat(level) + "○".repeat(5 - level)
	title.add_child(UI.label("%s  %s" % [str(data.get("label", setting_id)), dots], 14))
	var weights: Dictionary = CAT.segment(selected, target).get("weights", {})
	var weight := float(weights.get(setting_id, 0.0))
	var importance := "compte beaucoup pour ces clients" if weight >= 0.25 else ("compte un peu" if weight >= 0.10 else "compte peu pour ces clients")
	title.add_child(UI.muted_label("%s — %s" % [CAT.level_text(selected, setting_id, float(level), launch_year), importance], 12))
	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(44, 40)
	LOOK.button_style(plus, false)
	var up := ComponentManager.step_preview(selected, levels, price_mode, target, setting_id, 1)
	plus.disabled = not bool(up.get("possible", false))
	plus.tooltip_text = str(up.get("reason", ""))
	plus.pressed.connect(_step.bind(setting_id, 1))
	head.add_child(plus)
	var hint := UI.muted_label(str(data.get("hint", "")), 11)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	if bool(up.get("possible", false)):
		box.add_child(CHIPS.flow(up.get("chips", []), "+ :", 11))
	elif level < 5:
		var locked := UI.muted_label("+ : %s" % str(up.get("reason", "")), 11)
		locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(locked)
	# Au-dessus du standard, on montre aussi ce que rapporte un cran de moins (économie, délai).
	var down := ComponentManager.step_preview(selected, levels, price_mode, target, setting_id, -1)
	if level > 3 and bool(down.get("possible", false)):
		box.add_child(CHIPS.flow(down.get("chips", []), "− :", 11))
	return panel

func _summary(preview: Dictionary, target: String) -> Control:
	var panel := UI.card(Color("fff4e2"), 12, 12)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	box.add_child(UI.label("Votre modèle à sa sortie, face au meilleur rival", 14))
	box.add_child(UI.muted_label("Barre = votre modèle • trait noir = le meilleur rival sur ce point", 11))
	var scores: Dictionary = preview.get("scores", {})
	var rivals: Dictionary = preview.get("rival_best", {})
	var weights: Dictionary = CAT.segment(selected, target).get("weights", {})
	for axis_value in CAT.settings_of(selected):
		var axis := str(axis_value)
		var rival: Dictionary = rivals.get(axis, {})
		box.add_child(_score_bar(CAT.setting_label(selected, axis), float(scores.get(axis, 50.0)), float(rival.get("score", -1.0)), str(rival.get("name", "")), float(weights.get(axis, 0.0)) >= 0.2))
	var review: Dictionary = preview.get("review", {})
	var score := float(review.get("score", 0.0))
	var note := UI.label("Note probable de la presse : %s/10" % _num(score), 17)
	note.add_theme_color_override("font_color", GOOD if score >= 7.5 else (WARN if score >= 5.5 else BAD))
	box.add_child(note)
	var reasons: Array = review.get("reasons", [])
	if not reasons.is_empty():
		var chip_list: Array = []
		for reason_value in reasons:
			var reason: Dictionary = reason_value
			chip_list.append({"text":("✓ " if bool(reason.good) else "✗ ") + str(reason.text), "good":bool(reason.good)})
		box.add_child(CHIPS.flow(chip_list, "", 11))
	var cost := float(preview.get("unit_cost", 0.0))
	var price := float(preview.get("price", 0.0))
	box.add_child(UI.label("Coût %s € • prix %s € • marge %s € par unité" % [_num(cost), _num(price), _num(price - cost)], 13))
	box.add_child(UI.label("Ventes estimées : %s par mois (%s du marché) • marge ≈ %s €/mois" % [
		UI.money(int(preview.get("est_units", 0))), _pct(float(preview.get("est_share", 0.0))), UI.money(int(preview.get("est_margin", 0)))], 13))
	var dev := UI.muted_label("Développement : %d mois × %s € = %s € • estimation face aux modèles rivaux actuels, hors nouveautés." % [
		int(preview.get("months", 0)), UI.money(int(preview.get("monthly_cost", 0))), UI.money(int(preview.get("total_cost", 0)))], 12)
	dev.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(dev)
	var payback := float(preview.get("total_cost", 0)) / maxf(float(preview.get("est_margin", 0)), 1.0)
	var payback_label := UI.muted_label("Rentabilisé en ≈ %d mois de ventes." % int(ceil(payback)) if payback < 60.0 else "Peu rentable tel quel : les ventes estimées couvrent mal le développement.", 12)
	payback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if payback >= 60.0:
		payback_label.add_theme_color_override("font_color", BAD)
	box.add_child(payback_label)
	return panel

func _score_bar(label: String, value: float, rival: float, rival_name: String, important: bool) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	var text := "%s%s" % [label, "  (clé)" if important else ""]
	if rival >= 0.0:
		var gap := value - rival
		text += " — %s" % ("devant %s" % rival_name if gap >= 4.0 else ("au niveau" if gap >= -4.0 else "derrière %s" % rival_name))
	var title := UI.label(text, 12)
	row.add_child(title)
	var bar := ScoreBar.new()
	bar.value = value
	bar.rival = rival
	bar.custom_minimum_size = Vector2(0, 12)
	row.add_child(bar)
	return row

class ScoreBar extends Control:
	var value := 50.0
	var rival := -1.0
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("efe3cf"))
		var color := Color("2f7a3a") if rival < 0.0 or value >= rival - 4.0 else (Color("d9822b") if value >= rival - 10.0 else Color("b3261e"))
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(value / 100.0, 0.0, 1.0), r.size.y)), color)
		if rival >= 0.0:
			var x := r.size.x * clampf(rival / 100.0, 0.0, 1.0)
			draw_rect(Rect2(Vector2(x - 1.5, -2.0), Vector2(3.0, r.size.y + 4.0)), Color("3b2b1e"))

## Bouton à choisir (famille, clients, prix) : sélectionné = fond crème et bord ambre épais.
static func _toggle_style(button: Button, on: bool) -> void:
	LOOK.button_style(button, false)
	if not on:
		return
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, UI.stylebox(Color("ffe9c4"), 12, 3, Color("d9822b"), 10))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("3b2b1e"))

# --- Actions ------------------------------------------------------------------------

func _set_target(segment_id: String) -> void:
	draft(selected)["target"] = segment_id
	refresh()

func _set_price(mode: String) -> void:
	draft(selected)["price"] = mode
	refresh()

func _step(setting_id: String, delta: int) -> void:
	var d := draft(selected)
	var level := clampi(int(d.levels.get(setting_id, 3)) + delta, 1, ComponentManager.max_level(selected))
	d.levels[setting_id] = level
	SoundManager.play("click")
	refresh()

func _start() -> void:
	var d := draft(selected)
	if ComponentManager.start_project(selected, d.levels, str(d.price), str(d.target), str(d.get("name", ""))):
		status_changed.emit("Développement lancé.")
		d["name"] = ""
	refresh()

func _retire(product_id: String) -> void:
	if ComponentManager.retire_product(product_id):
		status_changed.emit("Modèle retiré du catalogue.")
	refresh()

# --- Format -------------------------------------------------------------------------

static func _num(value: float) -> String:
	if absf(value - round(value)) < 0.05:
		return str(int(round(value)))
	return ("%.1f" % value).replace(".", ",")

static func _pct(share: float) -> String:
	if share > 0.0 and share < 0.01:
		return "<1 %"
	return "%d %%" % int(round(share * 100.0))

static func _month_name(month: int) -> String:
	var names := ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
	return names[clampi(month - 1, 0, 11)]
