extends ScrollContainer

signal action_requested(action: String, payload: Dictionary)

const UI := preload("res://ui/UiKit.gd")

var overview_panel: Control
var tender_panel: Control
var after_sales_panel: Control

func _ready() -> void:
	name = "Marché"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := UI.content_box()
	add_child(box)
	box.add_child(UI.eyebrow("MARCHÉ & CLIENTS"))
	box.add_child(UI.label("Lire le marché, affronter les concurrents et soutenir les produits", 24))

	var overview_script: Script = load("res://ui/components/MarketOverviewPanel.gd")
	overview_panel = overview_script.new() as Control
	box.add_child(overview_panel)

	var tender_script: Script = load("res://ui/components/TenderPanel.gd")
	tender_panel = tender_script.new() as Control
	tender_panel.connect("action_requested", _relay_action)
	box.add_child(tender_panel)

	var after_sales_script: Script = load("res://ui/components/AfterSalesPanel.gd")
	after_sales_panel = after_sales_script.new() as Control
	after_sales_panel.connect("action_requested", _relay_action)
	box.add_child(after_sales_panel)

func set_viewport_width(width: float) -> void:
	if overview_panel != null and overview_panel.has_method("set_viewport_width"):
		overview_panel.call("set_viewport_width", width)
	if after_sales_panel != null and after_sales_panel.has_method("set_viewport_width"):
		after_sales_panel.call("set_viewport_width", width)

func refresh() -> void:
	if overview_panel != null:
		overview_panel.call("refresh")
	if tender_panel != null:
		tender_panel.call("refresh")
	if after_sales_panel != null:
		after_sales_panel.call("refresh")

func _relay_action(action: String, payload: Dictionary) -> void:
	action_requested.emit(action, payload)
