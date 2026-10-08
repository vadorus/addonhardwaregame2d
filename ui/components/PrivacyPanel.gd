extends ColorRect
## La politique de confidentialité, lisible depuis le menu (Google Play exige un accès dans l'appli).

const POLICY := preload("res://scripts/PrivacyPolicy.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")

var _online: Button

func _init() -> void:
	color = Color(0.02, 0.04, 0.07, 0.62)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	z_index = 120
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := LOOK.card(Color("fffaf1"), 18, 20)
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(LOOK.label(POLICY.TITLE, 22))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var text := LOOK.muted_label(POLICY.text(), 14)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	_online = Button.new()
	_online.text = "Version en ligne"
	_online.visible = POLICY.has_online_version()
	_online.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_online.custom_minimum_size.y = 44
	LOOK.button_style(_online, false)
	_online.pressed.connect(func(): OS.shell_open(POLICY.ONLINE_URL))
	row.add_child(_online)
	var close := Button.new()
	close.text = "Fermer"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.custom_minimum_size.y = 44
	LOOK.button_style(close, true)
	close.pressed.connect(func(): visible = false)
	row.add_child(close)

func open() -> void:
	visible = true
