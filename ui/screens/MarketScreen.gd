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

	# Sous-pages : marché, appels d'offres et SAV ne s'empilent plus (retour d'Alexandre, 28/09).
	pager = (load("res://ui/SectionPager.gd") as Script).new() as Control
	box.add_child(pager)
	for part in [["OVERVIEW", "Mes ventes", "product_nodes"], ["NEEDS", "Besoins du marché", "needs_nodes"], ["COMPETITORS", "Concurrents", "competitor_nodes"]]:
		var page: VBoxContainer = pager.call("add_page", str(part[0]), str(part[1]))
		for node_value in overview_panel.get(str(part[2])):
			var node: Node = node_value
			node.get_parent().remove_child(node)
			page.add_child(node)
	overview_panel.visible = false
	for part in [["TENDERS", "Appels d'offres", tender_panel], ["SAV", "SAV", after_sales_panel]]:
		var page: VBoxContainer = pager.call("add_page", str(part[0]), str(part[1]))
		var panel: Control = part[2]
		box.remove_child(panel)
		page.add_child(panel)
	pager.call("show_page", "OVERVIEW")

var pager: Control

func show_section(key: String) -> void:
	if pager != null:
		pager.call("show_page", key)

func current_section() -> String:
	return str(pager.get("current")) if pager != null else ""

func show_section_for_context(context: String) -> void:
	match context:
		"SAV":
			show_section("SAV")
		"CONTRAT", "Appels d'offres":
			show_section("TENDERS")
		"MARCHÉ", "Marché":
			show_section("OVERVIEW")
		"Besoins":
			show_section("NEEDS")
		"Concurrents":
			show_section("COMPETITORS")

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
