extends PanelContainer
## Planche 4 « La fabrication » (revue des onglets, 08/10) : le prototype est validé, place à l'usine.
## À gauche, le nouveau CPU face au marché (l'ancien modèle de la maison, le meilleur rival) ;
## à droite, qui grave nos puces, combien de puces bonnes par plaquette, la répartition de la gamme,
## puis « Lancer la fabrication ». Tout est un aperçu sans hasard : rien n'est engagé avant le bouton.
## Utilisé dans le parcours CPU (étape Fabriquer) et dans Produits > Fabriquer.

signal launch_requested(payload: Dictionary)

const PREVIEW := preload("res://scripts/ProductionPreview.gd")
const CHIP := preload("res://ui/ChipPreview.gd")
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")

const INK := Color("3b2b1e")
const MUTED := Color("6b5640")
const PAPER := Color("fff8ec")
const LINE := Color("e6d6bd")
const ORANGE := Color("f2a541")
const ORANGE_SOFT := Color("fff3dd")
const GREEN := Color("138a4a")
const OLD := Color("8a7357")
const RIVAL := Color("3b2b1e")
const TONES := {
	"good":[Color("dff0e3"), Color("2f7f46")],
	"bad":[Color("f8dcd9"), Color("b5352d")],
	"warn":[Color("fbe9d2"), Color("9a5a12")],
	"neutral":[Color("efe2cc"), Color("6b5640")],
}
const TIER_COLORS := {"ESSENTIAL":Color("c9a37a"), "SIGNATURE":Color("f2a541"), "APEX":Color("b5352d")}

var job_id := ""
var _provider := ""
var _binning := "BALANCED"
var _data: Dictionary = {}
var _options: Array = []
var _layout: BoxContainer
var _left: VBoxContainer
var _right: VBoxContainer
var _launch: Button
var _narrow := false
var _signature := ""

func _init() -> void:
	add_theme_stylebox_override("panel", _box(PAPER, 18, 14))
	_layout = HBoxContainer.new()
	_layout.add_theme_constant_override("separation", 16)
	add_child(_layout)
	_left = _column()
	_right = _column()
	_layout.add_child(_left)
	_layout.add_child(_right)

func _column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	return column

## Le CPU à fabriquer. Le fondeur conseillé est présélectionné.
func set_job(id: String) -> void:
	if id != job_id:
		job_id = id
		_provider = ""
		_binning = "BALANCED"
	refresh()

func set_viewport_width(width: float) -> void:
	var narrow := width < 820.0
	if narrow == _narrow:
		return
	_narrow = narrow
	var vertical := narrow
	var replacement: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	replacement.add_theme_constant_override("separation", 16)
	for child in [_left, _right]:
		_layout.remove_child(child)
		replacement.add_child(child)
	remove_child(_layout)
	_layout.queue_free()
	_layout = replacement
	add_child(_layout)
	_signature = ""

func select_provider(provider: String) -> void:
	_provider = provider
	refresh(true)

func select_binning(binning: String) -> void:
	_binning = binning
	refresh(true)

func selected_provider() -> String:
	return _provider

func data() -> Dictionary:
	return _data

func launch_button() -> Button:
	return _launch if _launch != null and is_instance_valid(_launch) else null

func refresh(force: bool = false) -> void:
	var job := ProductionManager.get_job(job_id)
	visible = not job.is_empty()
	if job.is_empty():
		return
	# Le jeu rafraîchit souvent : on ne reconstruit que si quelque chose de visible a pu changer.
	var signature := "%s|%s|%s|%d|%d|%s|%d|%d|%s" % [job_id, _provider, _binning, TimeManager.month, TimeManager.year,
		str(job.get("route_selected", false)), ProductManager.products.size(), MarketManager.competitors.get("CPU", []).size(), str(_narrow)]
	if signature == _signature and not force:
		return
	_signature = signature
	_options = PREVIEW.foundry_options(job, _binning)
	if _provider == "" or not _options.any(func(o): return str(o.id) == _provider):
		_provider = ""
		for option_value in _options:
			if bool((option_value as Dictionary).recommended):
				_provider = str((option_value as Dictionary).id)
		if _provider == "" and not _options.is_empty():
			_provider = str((_options[0] as Dictionary).id)
	_data = PREVIEW.build(job, _provider, _binning) if _provider != "" else {"ok":false, "name":str(job.get("name", "CPU"))}
	_clear(_left)
	_clear(_right)
	_build_market(job)
	_build_factory()

# --- À gauche : le nouveau CPU face au marché ---------------------------------------------------

func _build_market(job: Dictionary) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_left.add_child(head)
	var chip := TextureRect.new()
	chip.texture = CHIP.era_texture(int(job.get("node_nm", 10000)))
	chip.custom_minimum_size = Vector2(54, 54)
	chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(chip)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	head.add_child(titles)
	titles.add_child(_text("%s face au marché" % str(_data.get("name", "CPU")), 20, INK))
	var others := maxi(int(_data.get("market_size", 1)) - 1, 0)
	titles.add_child(_text("%s · %d processeur%s en vente" % [str(_data.get("segment", "")), others, "s" if others > 1 else ""], 12, MUTED))
	if bool(_data.get("ok", false)):
		var rank := int(_data.rank)
		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", _box(TONES.good[0] if rank == 1 else (TONES.warn[0] if rank <= 3 else TONES.bad[0]), 14, 8))
		var badge_box := VBoxContainer.new()
		badge_box.add_theme_constant_override("separation", -2)
		badge.add_child(badge_box)
		var rank_label := _text("1er" if rank == 1 else "%de" % rank, 22, INK)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_box.add_child(rank_label)
		var market_label := _text("du marché", 11, INK)
		market_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_box.add_child(market_label)
		head.add_child(badge)
	if not bool(_data.get("ok", false)):
		var none := _text("Aucune usine ne sait encore graver cette finesse. Les fondeurs progressent chaque année : revenez plus tard, ou repensez la gravure au labo.", 13, MUTED)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_left.add_child(none)
		return
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 14)
	_left.add_child(legend)
	legend.add_child(_legend_item(ORANGE, str(_data.name), true))
	var previous: Dictionary = _data.previous
	if not previous.is_empty():
		legend.add_child(_legend_item(OLD, "%s (ton ancien)" % str(previous.get("name", "")), false))
	else:
		legend.add_child(_text("premier CPU de la maison", 11, MUTED))
	var rival: Dictionary = _data.rival
	if not rival.is_empty():
		legend.add_child(_legend_item(RIVAL, "%s (le rival)" % str(rival.get("name", "")), false))
	for row_value in _data.rows:
		_left.add_child(_metric_row(row_value))
	var say := HBoxContainer.new()
	say.add_theme_constant_override("separation", 8)
	_left.add_child(say)
	say.add_child(WORKPLACE.face_avatar(WORKPLACE.cast_look("Noah Leroy"), 38.0, ORANGE))
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", _box(Color("f6ead6"), 12, 8))
	say.add_child(bubble)
	var verdict := _text("Noah : « %s »" % str(_data.verdict), 12, INK)
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(verdict)

func _legend_item(color: Color, text: String, dot: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var mark := ColorRect.new()
	mark.color = color
	mark.custom_minimum_size = Vector2(10, 10) if dot else Vector2(3, 12)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	row.add_child(_text(text, 11, MUTED))
	return row

func _metric_row(row: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	box.add_child(line)
	var label := _text(str(row.label), 13, INK)
	label.custom_minimum_size.x = 104
	line.add_child(label)
	var value := _text(str(row.value), 13, INK)
	value.custom_minimum_size.x = 64
	line.add_child(value)
	var track := MarkerTrack.new()
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.custom_minimum_size = Vector2(90, 16)
	track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var top := maxf(float(row.get("max", 100.0)), 1.0)
	var lower_better := bool(row.get("lower_better", false))
	track.new_pos = _pos(float(row.new), top, lower_better)
	track.old_pos = _pos(float(row.old), top, lower_better) if row.has("old") else -1.0
	track.rival_pos = _pos(float(row.rival), top, lower_better) if row.has("rival") else -1.0
	line.add_child(track)
	if str(row.get("delta", "")) != "":
		var tone: Array = TONES.get(str(row.get("tone", "neutral")), TONES.neutral)
		line.add_child(_chip(str(row.get("delta", "")), tone[0], tone[1]))
	box.add_child(_text(str(row.get("note", "")), 10, MUTED))
	return box

## Position sur la jauge (0 à 1), toujours « mieux à droite ».
func _pos(value: float, top: float, lower_better: bool) -> float:
	var ratio := clampf(value / top, 0.0, 1.0)
	return clampf(1.0 - ratio if lower_better else ratio, 0.03, 0.97)

# --- À droite : qui grave nos puces, rendement, gamme, lancement -------------------------------

func _build_factory() -> void:
	_right.add_child(_text("Qui grave nos puces ?", 15, INK))
	var tiles := HFlowContainer.new()
	tiles.add_theme_constant_override("h_separation", 6)
	tiles.add_theme_constant_override("v_separation", 6)
	_right.add_child(tiles)
	for option_value in _options:
		var option: Dictionary = option_value
		tiles.add_child(_foundry_tile(option))
	if not bool(_data.get("ok", false)):
		_add_launch(false)
		return
	var wafer_row := HBoxContainer.new()
	wafer_row.add_theme_constant_override("separation", 10)
	_right.add_child(wafer_row)
	var wafer := Wafer.new()
	wafer.custom_minimum_size = Vector2(76, 76)
	wafer.yield_pct = int(_data.yield_pct)
	wafer_row.add_child(wafer)
	var yield_box := VBoxContainer.new()
	yield_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yield_box.add_theme_constant_override("separation", 2)
	wafer_row.add_child(yield_box)
	yield_box.add_child(_text("Puces bonnes par plaquette", 12, MUTED))
	var yield_line := HBoxContainer.new()
	yield_line.add_theme_constant_override("separation", 8)
	yield_box.add_child(yield_line)
	yield_line.add_child(_text("%d %%" % int(_data.yield_pct), 24, INK))
	if not (_data.previous as Dictionary).is_empty():
		var delta := int(_data.yield_delta)
		var tone: Array = TONES.good if delta >= 0 else TONES.bad
		yield_line.add_child(_chip("%+d pts vs %s" % [delta, str((_data.previous as Dictionary).get("name", ""))], tone[0], tone[1]))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	yield_box.add_child(chips)
	for chip_value in _data.chips:
		var chip: Dictionary = chip_value
		var tone: Array = TONES.get(str(chip.tone), TONES.neutral)
		chips.add_child(_chip(str(chip.text), tone[0], tone[1]))
	_build_split()
	_add_launch(true)

func _foundry_tile(option: Dictionary) -> Button:
	var picked := str(option.id) == _provider
	var tile := Button.new()
	tile.toggle_mode = false
	tile.text = "%s%s\n%s" % [str(option.name), "  ★" if bool(option.recommended) else "", str(option.tag)]
	tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tile.custom_minimum_size = Vector2(150, 46)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_font_size_override("font_size", 12)
	for state in ["normal", "hover", "pressed", "focus"]:
		var bg := ORANGE_SOFT if picked else (Color("faf0e0") if state == "hover" else PAPER)
		var style := _box(bg, 12, 7)
		style.set_border_width_all(2 if picked else 1)
		style.border_color = ORANGE if picked else LINE
		tile.add_theme_stylebox_override(state, style)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		tile.add_theme_color_override(color_name, INK)
	var id := str(option.id)
	tile.pressed.connect(func(): call_deferred("select_provider", id))
	return tile

func _build_split() -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	_right.add_child(head)
	var title := _text("La gamme qui sortira", 13, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	for key_value in PREVIEW.BINNING_ORDER:
		var key := str(key_value)
		var button := Button.new()
		button.text = str(PREVIEW.BINNING_LABELS[key])
		button.tooltip_text = str(PREVIEW.BINNING_HINTS[key])
		button.add_theme_font_size_override("font_size", 11)
		button.custom_minimum_size.y = 28
		var picked := key == _binning
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := _box(ORANGE if picked else PAPER, 10, 5)
			style.set_border_width_all(1)
			style.border_color = ORANGE if picked else LINE
			button.add_theme_stylebox_override(state, style)
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, Color.WHITE if picked else INK)
		button.pressed.connect(func(): call_deferred("select_binning", key))
		head.add_child(button)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 2)
	bar.custom_minimum_size.y = 14
	_right.add_child(bar)
	var legend := HFlowContainer.new()
	legend.add_theme_constant_override("h_separation", 12)
	_right.add_child(legend)
	for model_value in _data.models:
		var model: Dictionary = model_value
		var color: Color = TIER_COLORS.get(str(model.tier), ORANGE)
		var part := ColorRect.new()
		part.color = color
		part.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		part.size_flags_stretch_ratio = maxf(float(model.share), 0.02)
		bar.add_child(part)
		legend.add_child(_legend_item(color, "%s  %d %% · %d €" % [str(model.name), roundi(float(model.share) * 100.0), int(model.price)], true))

func _add_launch(enabled: bool) -> void:
	_launch = Button.new()
	_launch.name = "LaunchFabrication"
	_launch.text = "Lancer la fabrication"
	_launch.custom_minimum_size.y = 46
	_launch.add_theme_font_size_override("font_size", 16)
	_launch.disabled = not enabled
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var bg := GREEN if enabled else Color("b9ab97")
		_launch.add_theme_stylebox_override(state, _box(bg.darkened(0.08) if state == "hover" else bg, 12, 8))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		_launch.add_theme_color_override(color_name, Color.WHITE)
	_launch.pressed.connect(_on_launch)
	_right.add_child(_launch)
	if enabled:
		var when := _text("En rayon en %s · %s € engagés (mise en route + %d mois)" % [
			str(_data.when), PREVIEW._money(int(_data.total_cost)), int(_data.months)], 11, MUTED)
		when.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		when.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_right.add_child(when)

func _on_launch() -> void:
	if not bool(_data.get("ok", false)):
		return
	launch_requested.emit({
		"job_id":job_id,
		"strategy":"BALANCED",
		"binning":_binning,
		"mode":"INTERNAL" if _provider == "INTERNAL" else "EXTERNAL",
		"provider":_provider,
	})

# --- Petits éléments ----------------------------------------------------------------------------

func _chip(text: String, bg: Color, fg: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _box(bg, 999, 4))
	var label := _text(text, 11, fg)
	panel.add_child(label)
	return panel

func _box(bg: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding + 2
	style.content_margin_right = padding + 2
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _text(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

## Une jauge « mieux à droite » : le nouveau CPU (pastille orange), l'ancien (trait brun), le rival (trait foncé).
class MarkerTrack extends Control:
	var new_pos := 0.5
	var old_pos := -1.0
	var rival_pos := -1.0

	func _draw() -> void:
		var mid := size.y * 0.5
		draw_rect(Rect2(0, mid - 3, size.x, 6), Color("efe2cc"))
		draw_rect(Rect2(0, mid - 3, size.x * new_pos, 6), Color("f6d29a"))
		if old_pos >= 0.0:
			draw_rect(Rect2(size.x * old_pos - 1.5, mid - 7, 3, 14), Color("8a7357"))
		if rival_pos >= 0.0:
			draw_rect(Rect2(size.x * rival_pos - 1.5, mid - 8, 3, 16), Color("3b2b1e"))
		draw_circle(Vector2(size.x * new_pos, mid), 6.5, Color("3b2b1e"))
		draw_circle(Vector2(size.x * new_pos, mid), 5.0, Color("f2a541"))

## Une plaquette de silicium : chaque case est une puce, dorée si elle est bonne.
class Wafer extends Control:
	var yield_pct := 60

	func _draw() -> void:
		var radius := minf(size.x, size.y) * 0.5
		var center := size * 0.5
		draw_circle(center, radius, Color("4b5a64"))
		var cells := 9
		var cell := radius * 2.0 / float(cells)
		var index := 0
		for y in range(cells):
			for x in range(cells):
				var rect := Rect2(center.x - radius + x * cell + 1, center.y - radius + y * cell + 1, cell - 2, cell - 2)
				if rect.get_center().distance_to(center) > radius - cell * 0.45:
					continue
				var good := (index * 37) % 100 < yield_pct
				draw_rect(rect, Color("e3b04b") if good else Color("2f3b43"))
				index += 1
