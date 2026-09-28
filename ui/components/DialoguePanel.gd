extends PanelContainer
## Une conversation : le portrait de la personne, sa réplique dans une bulle,
## et vos réponses (chacune dit ce qu'elle change).

signal choice_made(key: String, choice_id: String)

const UI := preload("res://ui/UiKit.gd")
const LOOK := preload("res://ui/WorkshopStyle.gd")

var dialogue: Dictionary = {}
var _portrait: Control
var _kicker: Label
var _name: Label
var _role: Label
var _speech: Label
var _note: Label
var _choices: VBoxContainer

func _init() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffaf1")
	style.border_color = Color("d9822b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 18)
	style.shadow_color = Color(0.1, 0.05, 0.0, 0.35)
	style.shadow_size = 12
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(600, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	_kicker = LOOK.eyebrow("")
	column.add_child(_kicker)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	_portrait = (load("res://ui/Portrait.gd") as Script).new() as Control
	row.add_child(_portrait)
	var talk := VBoxContainer.new()
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talk.add_theme_constant_override("separation", 4)
	row.add_child(talk)
	_name = LOOK.label("", 19)
	talk.add_child(_name)
	_role = LOOK.muted_label("", 12)
	talk.add_child(_role)
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", UI.stylebox(Color("f6e3c6"), 14, 0, Color("f6e3c6"), 12))
	talk.add_child(bubble)
	_speech = LOOK.label("", 16)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(_speech)
	_note = LOOK.muted_label("", 12)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk.add_child(_note)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 6)
	column.add_child(_choices)

func fit_to(viewport_size: Vector2) -> void:
	custom_minimum_size.x = clampf(viewport_size.x - 48.0, 320.0, 640.0)

func show_dialogue(data: Dictionary) -> void:
	dialogue = data.duplicate(true)
	var person: Dictionary = dialogue.get("person", {})
	_portrait.call("setup", str(person.get("key", "")), str(dialogue.get("mood", "NEUTRAL")))
	_kicker.text = str(dialogue.get("kicker", ""))
	_name.text = str(person.get("name", ""))
	_role.text = str(person.get("role", ""))
	_speech.text = "« %s »" % str(dialogue.get("text", ""))
	_note.text = str(dialogue.get("note", ""))
	_note.visible = _note.text != ""
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for choice_value in dialogue.get("choices", []):
		var choice: Dictionary = choice_value
		var button := Button.new()
		button.text = str(choice.get("label", ""))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 44
		button.disabled = not bool(choice.get("enabled", true))
		LOOK.button_style(button, bool(choice.get("primary", false)) and not button.disabled)
		var choice_id := str(choice.get("id", ""))
		button.pressed.connect(func(): choice_made.emit(str(dialogue.get("key", "")), choice_id))
		_choices.add_child(button)
		var hint := str(choice.get("hint", ""))
		if hint != "":
			_choices.add_child(LOOK.muted_label(hint, 12))

func choice_ids() -> Array:
	var ids: Array = []
	for choice_value in dialogue.get("choices", []):
		ids.append(str((choice_value as Dictionary).get("id", "")))
	return ids
