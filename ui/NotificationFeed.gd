extends VBoxContainer
## Fil de notifications : petites cartes qui s'empilent en haut de l'écran puis s'effacent.
## Une carte cliquable (tab >= 0) ouvre l'écran concerné.

signal navigate_requested(tab_index: int)

const JUICE := preload("res://ui/Juice.gd")
const MAX_VISIBLE := 3
const LIFETIME := 4.5
const KIND_COLORS := {
	"info":Color("d9822b"), "good":Color("10a34c"), "alert":Color("e5372c"), "press":Color("7a4a2a"), "unlock":Color("3a8fd6")
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 6)
	z_index = 50

func push(text: String, kind: String = "info", tab: int = -1) -> Control:
	if text.strip_edges() == "":
		return null
	while get_child_count() >= MAX_VISIBLE:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.98, 0.945, 0.97)
	style.border_color = KIND_COLORS.get(kind, KIND_COLORS["info"])
	style.set_border_width_all(1)
	style.border_width_left = 6
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0.22, 0.12, 0.04, 0.25)
	style.shadow_size = 5
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP if tab >= 0 else Control.MOUSE_FILTER_IGNORE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if tab >= 0 else Control.CURSOR_ARROW
	card.set_meta("kind", kind)
	card.set_meta("tab", tab)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 3
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("2e2418"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(label)
	card.gui_input.connect(_on_card_input.bind(card))
	add_child(card)
	JUICE.fade_in(card, 0.22) # fondu seulement : le conteneur gère la position des cartes
	if is_inside_tree():
		var timer := get_tree().create_timer(LIFETIME)
		timer.timeout.connect(_dismiss.bind(card))
	return card

func toast_count() -> int:
	return get_child_count()

func toast_texts() -> Array[String]:
	var texts: Array[String] = []
	for child in get_children():
		var label := child.get_child(0) as Label
		if label != null:
			texts.append(label.text)
	return texts

func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _on_card_input(event: InputEvent, card: Control) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if not tapped:
		return
	var tab := int(card.get_meta("tab", -1))
	if tab >= 0:
		navigate_requested.emit(tab)
	_dismiss(card)

func _dismiss(card) -> void:
	# Non typé : la carte a pu être retirée (plus ancienne) avant la fin de son minuteur.
	if card == null or not is_instance_valid(card) or card.get_parent() != self:
		return
	var tween: Tween = card.create_tween()
	tween.tween_property(card, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		if is_instance_valid(card) and card.get_parent() == self:
			remove_child(card)
			card.queue_free()
	)
