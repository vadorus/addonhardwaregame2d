extends ScrollContainer

signal action_requested(action: String, payload: Dictionary)

const UI := preload("res://ui/UiKit.gd")

var industrialization_panel: Control
var lifecycle_panel: Control

func _ready() -> void:
	name = "Produits"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := UI.content_box()
	add_child(box)
	box.add_child(UI.eyebrow("INDUSTRIALISATION & PRODUITS"))
	box.add_child(UI.label("Transformer la R&D en une vraie gamme commerciale", 24))
	var intro := UI.muted_label("Choisissez la route de fabrication, maîtrisez le rendement puis pilotez le cycle de vie commercial de chaque CPU.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)

	var industrialization_script: Script = load("res://ui/components/IndustrializationPanel.gd")
	industrialization_panel = industrialization_script.new() as Control
	industrialization_panel.connect("action_requested", _relay_action)
	box.add_child(industrialization_panel)

	var lifecycle_script: Script = load("res://ui/components/ProductLifecyclePanel.gd")
	lifecycle_panel = lifecycle_script.new() as Control
	lifecycle_panel.connect("action_requested", _relay_action)
	box.add_child(lifecycle_panel)

func set_viewport_width(width: float) -> void:
	if industrialization_panel != null and industrialization_panel.has_method("set_viewport_width"):
		industrialization_panel.call("set_viewport_width", width)
	if lifecycle_panel != null and lifecycle_panel.has_method("set_viewport_width"):
		lifecycle_panel.call("set_viewport_width", width)

func refresh() -> void:
	if industrialization_panel != null:
		industrialization_panel.call("refresh")
	if lifecycle_panel != null:
		lifecycle_panel.call("refresh")

func _relay_action(action: String, payload: Dictionary) -> void:
	action_requested.emit(action, payload)
