extends PanelContainer
## Planche 6 « La finition » (08/10) : à quoi ressemblera le CPU ? Le boîtier en grand, la puce au microscope,
## les trois pistes de Camille, quelques retouches (couleur, logo, dessin caché), ce que ça change, puis
## « Valider la finition ». Les effets sont ceux de CpuFinish ; rien n'est posé avant le bouton.
## Utilisé dans le parcours CPU, juste avant le lancement (le jour J).

signal finish_requested(generation_id: String, finish: Dictionary)

const FINISH := preload("res://scripts/CpuFinish.gd")
const CHIP := preload("res://ui/ChipPreview.gd")
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")

const INK := Color("3b2b1e")
const MUTED := Color("6b5640")
const PAPER := Color("fff8ec")
const LINE := Color("e6d6bd")
const ORANGE := Color("f2a541")
const ORANGE_SOFT := Color("fff3dd")
const GREEN := Color("138a4a")
const TONES := {
	"good":[Color("dff0e3"), Color("2f7f46")],
	"bad":[Color("f8dcd9"), Color("b5352d")],
	"warn":[Color("fbe9d2"), Color("9a5a12")],
	"neutral":[Color("efe2cc"), Color("6b5640")],
}

var generation_id := ""
var _product: Dictionary = {}
var _finish: Dictionary = FINISH.default_finish()
var _microscope := false
var _layout: BoxContainer
var _left: VBoxContainer
var _right: VBoxContainer
var _validate: Button
var _narrow := false

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

## La génération à habiller ; `product` est son modèle « cœur de gamme » (nom, coût, gravure).
func set_generation(id: String, product: Dictionary) -> void:
	if id != generation_id:
		generation_id = id
		_finish = FINISH.default_finish()
		_microscope = false
	_product = product
	refresh()

func set_viewport_width(width: float) -> void:
	var narrow := width < 820.0
	if narrow == _narrow:
		return
	_narrow = narrow
	var replacement: BoxContainer = VBoxContainer.new() if narrow else HBoxContainer.new()
	replacement.add_theme_constant_override("separation", 16)
	for child in [_left, _right]:
		_layout.remove_child(child)
		replacement.add_child(child)
	remove_child(_layout)
	_layout.queue_free()
	_layout = replacement
	add_child(_layout)

func finish() -> Dictionary:
	return _finish.duplicate()

func validate_button() -> Button:
	return _validate if _validate != null and is_instance_valid(_validate) else null

func select_piste(piste: String) -> void:
	_finish.piste = piste
	_finish.color = str((FINISH.PISTES[piste] as Dictionary).color)
	refresh()

func select_color(color: String) -> void:
	_finish.color = color
	refresh()

func select_logo(logo: String) -> void:
	_finish.logo = logo
	refresh()

func toggle_doodle() -> void:
	_finish.doodle = not bool(_finish.doodle)
	refresh()

func toggle_microscope() -> void:
	_microscope = not _microscope
	refresh()

func refresh() -> void:
	_clear(_left)
	_clear(_right)
	if _product.is_empty():
		return
	_build_stage()
	_build_choices()

# --- À gauche : le CPU en grand -----------------------------------------------------------------

func _build_stage() -> void:
	var cpu_name := str(_product.get("generation_name", _product.get("name", "CPU")))
	var head := _text("À quoi ressemblera %s ?" % cpu_name, 20, INK)
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_left.add_child(head)
	_left.add_child(_text("%s · dernière étape avant le jour J" % cpu_name, 12, MUTED))
	var stage := PanelContainer.new()
	stage.add_theme_stylebox_override("panel", _box(Color("2b1f15"), 16, 12))
	stage.custom_minimum_size.y = 210
	_left.add_child(stage)
	if _microscope:
		var die := VBoxContainer.new()
		die.add_theme_constant_override("separation", 6)
		stage.add_child(die)
		var art := TextureRect.new()
		art.texture = CHIP.era_texture(int((_product.get("cpu_design", {}) as Dictionary).get("node_nm", 10000)))
		art.custom_minimum_size = Vector2(0, 130)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		die.add_child(art)
		var text := _text(_die_text(), 12, Color("f6e7cf"))
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		die.add_child(text)
	else:
		var package := PackageView.new()
		package.custom_minimum_size = Vector2(0, 186)
		package.setup(cpu_name, FINISH.print_code(cpu_name, int(_product.get("generation_index", 1)), TimeManager.year, TimeManager.month),
			"%s · %s" % [CompanyManager.company_name.to_upper(), str((FINISH.PISTES[_finish.piste] as Dictionary).material)],
			FINISH.COLORS[_finish.color], str(_finish.logo), bool((FINISH.PISTES[_finish.piste] as Dictionary).lid))
		stage.add_child(package)
	var microscope := Button.new()
	microscope.text = "Revenir au boîtier" if _microscope else "Voir la puce au microscope"
	microscope.flat = true
	microscope.add_theme_color_override("font_color", Color("9a5a12"))
	microscope.pressed.connect(func(): call_deferred("toggle_microscope"))
	_left.add_child(microscope)

func _die_text() -> String:
	if bool(_finish.doodle):
		return "Le petit garage de Camille, gravé dans un coin du silicium. Un jour, un journaliste le trouvera… et les collectionneurs adoreront."
	return "Rien de caché pour l'instant. Les ingénieurs de l'époque signaient parfois leurs puces d'un petit dessin."

# --- À droite : les pistes de Camille, les retouches, l'effet, la validation ---------------------

func _build_choices() -> void:
	_right.add_child(_text("Les trois pistes de Camille", 15, INK))
	var pistes := HBoxContainer.new()
	pistes.add_theme_constant_override("separation", 6)
	_right.add_child(pistes)
	for key_value in FINISH.PISTE_ORDER:
		pistes.add_child(_piste_tile(str(key_value)))
	_right.add_child(_text("Retoucher", 13, INK))
	var colors := HBoxContainer.new()
	colors.add_theme_constant_override("separation", 6)
	_right.add_child(colors)
	colors.add_child(_row_label("Couleur"))
	for key_value in FINISH.COLOR_ORDER:
		colors.add_child(_swatch(str(key_value)))
	var logos := HBoxContainer.new()
	logos.add_theme_constant_override("separation", 6)
	_right.add_child(logos)
	logos.add_child(_row_label("Logo gravé"))
	for key_value in FINISH.LOGO_ORDER:
		var key := str(key_value)
		logos.add_child(_pill(str(FINISH.LOGOS[key]), key == str(_finish.logo), func(): call_deferred("select_logo", key)))
	var doodle := HBoxContainer.new()
	doodle.add_theme_constant_override("separation", 6)
	_right.add_child(doodle)
	doodle.add_child(_row_label("Dessin caché"))
	doodle.add_child(_pill("Oui — le garage, gravé dans le silicium" if bool(_finish.doodle) else "Non", bool(_finish.doodle), func(): call_deferred("toggle_doodle")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 2)
	_right.add_child(grid)
	for impact_value in impacts():
		var impact: Dictionary = impact_value
		grid.add_child(_text(str(impact.label), 12, MUTED))
		var tone: Array = TONES.get(str(impact.tone), TONES.neutral)
		grid.add_child(_text(str(impact.value), 12, tone[1] if str(impact.tone) != "neutral" else INK))
	var say := HBoxContainer.new()
	say.add_theme_constant_override("separation", 8)
	_right.add_child(say)
	say.add_child(WORKPLACE.face_avatar(WORKPLACE.cast_look("Camille Durand"), 38.0, ORANGE))
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var warn := str(_finish.piste) == "VITRINE" and str(_product.get("target_segment", "")) in ["EMBEDDED", "CALCULATOR"]
	bubble.add_theme_stylebox_override("panel", _box(TONES.warn[0] if warn else Color("e3f3e6"), 12, 8))
	say.add_child(bubble)
	var line := _text("Camille : « %s »" % FINISH.camille_line(str(_finish.piste), str(_product.get("target_segment", "")), bool(_finish.doodle)), 12, INK)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(line)
	_validate = Button.new()
	_validate.name = "ValidateFinish"
	_validate.text = "Valider la finition"
	_validate.custom_minimum_size.y = 46
	_validate.add_theme_font_size_override("font_size", 16)
	for state in ["normal", "hover", "pressed", "focus"]:
		_validate.add_theme_stylebox_override(state, _box(GREEN.darkened(0.08) if state == "hover" else GREEN, 12, 8))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_validate.add_theme_color_override(color_name, Color.WHITE)
	_validate.pressed.connect(func(): finish_requested.emit(generation_id, _finish.duplicate()))
	_right.add_child(_validate)

## Ce que change la finition, en clair : coût par puce, chaleur, fiabilité, image.
func impacts() -> Array:
	var effect := FINISH.effects(_product, _finish)
	var cost := int(_product.get("unit_cost", 0)) + int(effect.cost)
	var press := float(effect.press)
	return [
		{"label":"Coût par puce", "value":"%d €%s" % [cost, " (%+d)" % int(effect.cost) if int(effect.cost) != 0 else ""],
			"tone":"warn" if int(effect.cost) > 0 else ("good" if int(effect.cost) < 0 else "neutral")},
		{"label":"Chaleur", "value":"Un peu plus" if float(effect.efficiency) < 0.0 else "Normale", "tone":"bad" if float(effect.efficiency) < 0.0 else "neutral"},
		{"label":"Fiabilité", "value":"%+.0f point" % float(effect.reliability) if float(effect.reliability) != 0.0 else "Inchangée", "tone":"bad" if float(effect.reliability) < 0.0 else "neutral"},
		{"label":"Image", "value":"+%s (presse, salons)" % ("%.0f" % press) if press > 0.0 else "Neutre", "tone":"good" if press > 0.0 else "neutral"},
	]

func _piste_tile(key: String) -> Button:
	var piste: Dictionary = FINISH.PISTES[key]
	var picked := key == str(_finish.piste)
	var tile := Button.new()
	tile.text = "%s\n%s\n%s" % [str(piste.label), str(piste.note), str(piste.effect)]
	tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size = Vector2(96, 74)
	tile.add_theme_font_size_override("font_size", 11)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := _box(ORANGE_SOFT if picked else (Color("faf0e0") if state == "hover" else Color.WHITE), 12, 6)
		style.set_border_width_all(2 if picked else 1)
		style.border_color = ORANGE if picked else LINE
		tile.add_theme_stylebox_override(state, style)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		tile.add_theme_color_override(color_name, INK)
	tile.pressed.connect(func(): call_deferred("select_piste", key))
	return tile

func _swatch(key: String) -> Button:
	var color: Dictionary = FINISH.COLORS[key]
	var picked := key == str(_finish.color)
	var swatch := Button.new()
	swatch.tooltip_text = str(color.label)
	swatch.custom_minimum_size = Vector2(32, 26)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := _box(color.top.lerp(color.bottom, 0.5), 8, 0)
		style.set_border_width_all(3 if picked else 1)
		style.border_color = ORANGE if picked else LINE
		swatch.add_theme_stylebox_override(state, style)
	swatch.pressed.connect(func(): call_deferred("select_color", key))
	return swatch

func _pill(text: String, picked: bool, callback: Callable) -> Button:
	var pill := Button.new()
	pill.text = text
	pill.custom_minimum_size.y = 26
	pill.add_theme_font_size_override("font_size", 11)
	for state in ["normal", "hover", "pressed", "focus"]:
		pill.add_theme_stylebox_override(state, _box(ORANGE if picked else Color("efe2cc"), 999, 4))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		pill.add_theme_color_override(color_name, INK if picked else Color("8a7357"))
	pill.pressed.connect(callback)
	return pill

func _row_label(text: String) -> Label:
	var label := _text(text, 12, MUTED)
	label.custom_minimum_size.x = 84
	return label

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

## Le boîtier DIP, vu de dessus : pattes, encoche, capot doré éventuel, logo et inscriptions.
class PackageView extends Control:
	var title := "CPU"
	var code := ""
	var maker := ""
	var colors: Dictionary = {}
	var logo := "ROND"
	var lid := false

	func setup(new_title: String, new_code: String, new_maker: String, new_colors: Dictionary, new_logo: String, new_lid: bool) -> void:
		title = new_title
		code = new_code
		maker = new_maker
		colors = new_colors
		logo = new_logo
		lid = new_lid
		queue_redraw()

	func _draw() -> void:
		var width := minf(size.x * 0.86, 360.0)
		var height := minf(size.y * 0.62, 118.0)
		var body := Rect2((size.x - width) * 0.5, (size.y - height) * 0.5, width, height)
		var pins := 10
		var step := body.size.x / float(pins)
		for i in range(pins):
			var x := body.position.x + step * (i + 0.5) - 5.0
			draw_rect(Rect2(x, body.position.y - 16.0, 10.0, 18.0), Color("cfd4d8"))
			draw_rect(Rect2(x, body.end.y - 2.0, 10.0, 18.0), Color("cfd4d8"))
		var top: Color = colors.get("top", Color("fbf7ee"))
		var bottom: Color = colors.get("bottom", Color("ddd5c4"))
		var ink: Color = colors.get("ink", Color("5b5246"))
		draw_polygon(PackedVector2Array([body.position, Vector2(body.end.x, body.position.y), body.end, Vector2(body.position.x, body.end.y)]),
			PackedColorArray([top, top.lerp(bottom, 0.4), bottom, top.lerp(bottom, 0.7)]))
		draw_circle(Vector2(body.position.x, body.get_center().y), 12.0, Color("2b1f15"))
		if lid:
			var plate := Rect2(body.position.x + body.size.x * 0.66, body.position.y + 14.0, body.size.x * 0.26, body.size.y - 28.0)
			draw_rect(plate, Color("d9a441"))
			draw_rect(plate.grow(-4.0), Color("f1c766"))
		var font := get_theme_default_font()
		var left := body.position.x + 30.0
		var logo_center := Vector2(left + 12.0, body.position.y + 34.0)
		match logo:
			"LOSANGE":
				draw_colored_polygon(PackedVector2Array([logo_center + Vector2(0, -12), logo_center + Vector2(12, 0), logo_center + Vector2(0, 12), logo_center + Vector2(-12, 0)]), ink)
			"CARRE":
				draw_rect(Rect2(logo_center - Vector2(10, 10), Vector2(20, 20)), ink)
			_:
				draw_circle(logo_center, 11.0, ink)
		draw_string(font, logo_center + Vector2(-5, 5), title.substr(0, 1).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, top)
		var text_width := body.size.x * (0.58 if lid else 0.86) - 30.0
		draw_string(font, Vector2(left + 32.0, body.position.y + 44.0), title, HORIZONTAL_ALIGNMENT_LEFT, text_width - 32.0, 26, ink)
		draw_string(font, Vector2(left, body.position.y + 72.0), code, HORIZONTAL_ALIGNMENT_LEFT, text_width, 13, ink)
		draw_string(font, Vector2(left, body.position.y + 94.0), maker, HORIZONTAL_ALIGNMENT_LEFT, text_width, 10, ink)
