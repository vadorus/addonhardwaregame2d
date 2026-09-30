extends ColorRect
## V0.10 / J3 — grande carte illustrée pour un moment clé (image d'Astra + une phrase).
## Le jeu se met en pause pendant la carte et reprend à la même vitesse ensuite.

signal closed(moment_id: String)

const MOMENTS := preload("res://scripts/Moments.gd")
const UI := preload("res://ui/UiKit.gd")
const JUICE := preload("res://ui/Juice.gd")

var moment_id := ""
var _panel: PanelContainer
var _image: TextureRect
var _kicker: Label
var _title: Label
var _text: Label
var _button: Button
var _resume_scale := 0.0

func _ready() -> void:
	color = Color(0.08, 0.05, 0.02, 0.82)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	z_index = 110
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UI.stylebox(Color("fffaf1"), 18, 3, Color("d9822b"), 14))
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	_image = TextureRect.new()
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.clip_contents = true
	box.add_child(_image)
	_kicker = UI.label("", 13)
	_kicker.add_theme_color_override("font_color", Color("d9822b"))
	box.add_child(_kicker)
	_title = UI.label("", 24)
	box.add_child(_title)
	_text = UI.label("", 15)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)
	_button = Button.new()
	_button.text = "Continuer"
	_button.focus_mode = Control.FOCUS_NONE
	_button.custom_minimum_size.y = 48
	_button.pressed.connect(close)
	box.add_child(_button)
	resized.connect(_fit)

func show_moment(id: String, extra_text: String = "") -> bool:
	var data := MOMENTS.data(id)
	if data.is_empty():
		return false
	moment_id = id
	var path := MOMENTS.image_path(id)
	_image.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_image.visible = _image.texture != null
	_kicker.text = str(data.kicker)
	_title.text = str(data.title)
	_text.text = str(data.text) + ("\n" + extra_text if extra_text != "" else "")
	_resume_scale = TimeManager.time_scale
	TimeManager.time_scale = 0.0
	visible = true
	_fit()
	JUICE.fade_in(self, 0.25)
	JUICE.pop_in(_panel, 0.25)
	SoundManager.play("unlock")
	return true

func close() -> void:
	if not visible:
		return
	visible = false
	TimeManager.time_scale = _resume_scale
	closed.emit(moment_id)

## Carte large sur PC, presque plein écran sur téléphone ; l'image garde le format 2:1.
func _fit() -> void:
	if _panel == null or size.x <= 0.0:
		return
	var width := clampf(size.x * 0.62, 320.0, 860.0)
	var image_h := minf(width * 0.5, size.y * 0.52)
	_image.custom_minimum_size = Vector2(width, image_h)
	_text.custom_minimum_size.x = width
	_title.custom_minimum_size.x = width
