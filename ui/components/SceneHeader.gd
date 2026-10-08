extends PanelContainer
## Revue des onglets (07/10) — la règle commune : chaque onglet s'ouvre sur une scène.
## Un décor dessiné (voilé à gauche pour lire), un personnage qui parle en une phrase,
## et à droite le chiffre du moment avec, au besoin, un bouton d'action.

signal hero_pressed

const INK := Color("3b2b1e")
const PAPER := Color("fff8ec")
const ORANGE := Color("f2a541")

var _art: TextureRect
var _face: TextureRect
var _kicker: Label
var _line: Label
var _hero: PanelContainer
var _hero_value: Label
var _hero_caption: Label
var _button: Button
var _progress: ProgressBar

## Réglages visuels des scènes existantes ; les valeurs par défaut restent inchangées.
func _init(layout: Dictionary = {}) -> void:
	custom_minimum_size.y = float(layout.get("height", 160))
	clip_contents = true
	add_theme_stylebox_override("panel", _box(Color("2b1f15"), 18, 0))
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	var veil := TextureRect.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.13, 0.09, 0.06, 0.92))
	gradient.set_color(1, Color(0.13, 0.09, 0.06, float(layout.get("veil_alpha", 0.2))))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	veil.texture = texture
	add_child(veil)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var face_margin := MarginContainer.new()
	face_margin.add_theme_constant_override("margin_left", 14)
	face_margin.add_theme_constant_override("margin_top", int(layout.get("face_top", 8)))
	row.add_child(face_margin)
	_face = TextureRect.new()
	_face.custom_minimum_size = layout.get("face_size", Vector2(108, 152))
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.size_flags_vertical = Control.SIZE_SHRINK_END
	face_margin.add_child(_face)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 6)
	row.add_child(words)
	_kicker = _text("", 12, ORANGE)
	words.add_child(_kicker)
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _box(PAPER, 14, 10))
	words.add_child(bubble)
	_line = _text("", 15, INK)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(_line)
	var hero_margin := MarginContainer.new()
	for side in ["margin_right", "margin_top", "margin_bottom"]:
		hero_margin.add_theme_constant_override(side, 14)
	row.add_child(hero_margin)
	_hero = PanelContainer.new()
	_hero.custom_minimum_size = Vector2(float(layout.get("hero_width", 210)), 0)
	_hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hero.add_theme_stylebox_override("panel", _box(Color(0.17, 0.12, 0.08, 0.86), 14, 12))
	hero_margin.add_child(_hero)
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", int(layout.get("hero_separation", 4)))
	hero_box.alignment = int(layout.get("hero_alignment", BoxContainer.ALIGNMENT_BEGIN))
	_hero.add_child(hero_box)
	_hero_value = _text("", int(layout.get("value_size", 28)), Color("f6e7cf"))
	_hero_value.horizontal_alignment = int(layout.get("text_alignment", HORIZONTAL_ALIGNMENT_CENTER))
	if bool(layout.get("wrap_value", false)):
		_hero_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_box.add_child(_hero_value)
	_hero_caption = _text("", 12, Color("e3cfb0"))
	_hero_caption.horizontal_alignment = int(layout.get("text_alignment", HORIZONTAL_ALIGNMENT_CENTER))
	_hero_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_box.add_child(_hero_caption)
	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.custom_minimum_size.y = 8
	_progress.add_theme_stylebox_override("background", _box(Color(1, 1, 1, 0.18), 99, 0))
	_progress.add_theme_stylebox_override("fill", _box(ORANGE, 99, 0))
	_progress.visible = false
	hero_box.add_child(_progress)
	_button = Button.new()
	_button.custom_minimum_size.y = float(layout.get("button_height", 40))
	if layout.has("button_size"):
		_button.add_theme_font_size_override("font_size", int(layout.button_size))
	_button.add_theme_color_override("font_color", Color.WHITE)
	_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_button.add_theme_stylebox_override("normal", _box(Color("138a4a"), 12, 8))
	_button.add_theme_stylebox_override("hover", _box(Color("0f7a40"), 12, 8))
	_button.add_theme_stylebox_override("pressed", _box(Color("0b6634"), 12, 8))
	_button.pressed.connect(func(): hero_pressed.emit())
	_button.visible = false
	hero_box.add_child(_button)

func set_scene(art_path: String, kicker: String) -> void:
	_art.texture = load(art_path) if ResourceLoader.exists(art_path) else null
	_kicker.text = kicker

func set_speaker(portrait_path: String) -> void:
	_face.texture = load(portrait_path) if ResourceLoader.exists(portrait_path) else null

func set_line(text: String) -> void:
	_line.text = text

func line_text() -> String:
	return _line.text

func set_hero(value: String, caption: String, button_text: String = "", value_color: Color = Color("f6e7cf")) -> void:
	_hero_value.text = value
	_hero_value.add_theme_color_override("font_color", value_color)
	_hero_caption.text = caption
	_button.text = button_text
	_button.visible = button_text != ""

func hero_button_text() -> String:
	return _button.text if _button.visible else ""

func set_progress(value: float, shown: bool = true) -> void:
	_progress.value = clampf(value, 0.0, 100.0)
	_progress.visible = shown

func hero_value_text() -> String:
	return _hero_value.text

func hero_caption_text() -> String:
	return _hero_caption.text

func _box(bg: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _text(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
