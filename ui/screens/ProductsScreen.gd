extends ScrollContainer

signal action_requested(action: String, payload: Dictionary)

const UI := preload("res://ui/UiKit.gd")

var mode_grid: GridContainer
var mode_buttons := {}
var pages := {}
var current_mode := "DESIGN"
var design_status_label: Label
var industrialization_panel: Control
var lifecycle_panel: Control
var after_sales_panel: Control

func _ready() -> void:
	name = "Produits"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()
	_select_mode("DESIGN")
	refresh()

func _build() -> void:
	var box := UI.content_box()
	add_child(box)
	box.add_child(UI.eyebrow("COCKPIT PRODUIT"))
	box.add_child(UI.label("Un produit, quatre responsabilités", 24))
	var intro := UI.muted_label(
		"Concevez, industrialisez, vendez puis supportez la même génération sans perdre son histoire.",
		12
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)

	mode_grid = GridContainer.new()
	mode_grid.columns = 4
	mode_grid.add_theme_constant_override("h_separation", 8)
	mode_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(mode_grid)
	_add_mode_button("DESIGN", "1  CONCEVOIR")
	_add_mode_button("BUILD", "2  FABRIQUER")
	_add_mode_button("SELL", "3  VENDRE")
	_add_mode_button("SUPPORT", "4  SUPPORTER")

	var design_page := VBoxContainer.new()
	design_page.add_theme_constant_override("separation", 10)
	box.add_child(design_page)
	pages["DESIGN"] = design_page
	_build_design_page(design_page)

	var industrialization_script: Script = load("res://ui/components/IndustrializationPanel.gd")
	industrialization_panel = industrialization_script.new() as Control
	industrialization_panel.connect("action_requested", _relay_action)
	box.add_child(industrialization_panel)
	pages["BUILD"] = industrialization_panel

	var lifecycle_script: Script = load("res://ui/components/ProductLifecyclePanel.gd")
	lifecycle_panel = lifecycle_script.new() as Control
	lifecycle_panel.connect("action_requested", _relay_action)
	box.add_child(lifecycle_panel)
	pages["SELL"] = lifecycle_panel

	var after_sales_script: Script = load("res://ui/components/AfterSalesPanel.gd")
	after_sales_panel = after_sales_script.new() as Control
	after_sales_panel.connect("action_requested", _relay_action)
	box.add_child(after_sales_panel)
	pages["SUPPORT"] = after_sales_panel

func _add_mode_button(mode: String, title: String) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 46
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func(): _select_mode(mode))
	mode_grid.add_child(button)
	mode_buttons[mode] = button

func _build_design_page(page: VBoxContainer) -> void:
	page.add_child(UI.section("Concevoir la prochaine génération"))
	var card := UI.card(UI.APP_PANEL_ALT, 12, 14)
	page.add_child(card)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 8)
	card.add_child(card_box)
	card_box.add_child(UI.eyebrow("DU BESOIN AU PROTOTYPE"))
	var copy := UI.muted_label(
		"Le cockpit garde l'histoire du produit. Les réglages techniques détaillés restent dans le laboratoire, tandis qu'ici vous suivez la génération de bout en bout.",
		12
	)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_box.add_child(copy)
	design_status_label = UI.rich_label()
	design_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_box.add_child(design_status_label)
	var open_lab := Button.new()
	open_lab.text = "Ouvrir le laboratoire CPU"
	open_lab.custom_minimum_size.y = 44
	open_lab.pressed.connect(func(): action_requested.emit("open_lab", {}))
	card_box.add_child(open_lab)

func _select_mode(mode: String) -> void:
	current_mode = mode
	for key_value in pages.keys():
		var key := str(key_value)
		var page: Control = pages[key_value]
		page.visible = key == current_mode
	for key_value in mode_buttons.keys():
		var key := str(key_value)
		var button: Button = mode_buttons[key_value]
		button.disabled = key == current_mode

func set_viewport_width(width: float) -> void:
	if mode_grid != null:
		mode_grid.columns = 2 if width < 760.0 else 4
	if industrialization_panel != null and industrialization_panel.has_method("set_viewport_width"):
		industrialization_panel.call("set_viewport_width", width)
	if lifecycle_panel != null and lifecycle_panel.has_method("set_viewport_width"):
		lifecycle_panel.call("set_viewport_width", width)

func refresh() -> void:
	_refresh_design_summary()
	if industrialization_panel != null:
		industrialization_panel.call("refresh")
	if lifecycle_panel != null:
		lifecycle_panel.call("refresh")
	if after_sales_panel != null:
		after_sales_panel.call("refresh")
	_refresh_mode_badges()

func _refresh_design_summary() -> void:
	if design_status_label == null:
		return
	var active_projects := ResearchManager.projects.size()
	var ready_products := 0
	var launched_products := 0
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		match str(product.get("status", "")):
			"READY": ready_products += 1
			"LAUNCHED": launched_products += 1
	var open_sav := AfterSalesManager.get_open_cases().size()
	design_status_label.text = "Projet(s) R&D actif(s) : %d\nPrêts à lancer : %d\nProduits sur le marché : %d\nDossiers SAV ouverts : %d" % [
		active_projects, ready_products, launched_products, open_sav
	]

func _refresh_mode_badges() -> void:
	if mode_buttons.is_empty():
		return
	var ready_products := 0
	var launched_products := 0
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "READY":
			ready_products += 1
		elif str(product.get("status", "")) == "LAUNCHED":
			launched_products += 1
	var active_jobs := ProductionManager.get_active_jobs().size()
	var open_sav := AfterSalesManager.get_open_cases().size()
	mode_buttons["DESIGN"].text = "1  CONCEVOIR"
	mode_buttons["BUILD"].text = "2  FABRIQUER%s" % ("  • %d" % active_jobs if active_jobs > 0 else "")
	mode_buttons["SELL"].text = "3  VENDRE%s" % ("  • %d" % (ready_products + launched_products) if ready_products + launched_products > 0 else "")
	mode_buttons["SUPPORT"].text = "4  SUPPORTER%s" % ("  • %d" % open_sav if open_sav > 0 else "")

func focus_product_launch() -> void:
	refresh()
	_select_mode("SELL")
	if lifecycle_panel != null:
		call_deferred("_focus_product_launch_deferred")

func _focus_product_launch_deferred() -> void:
	if lifecycle_panel != null:
		ensure_control_visible(lifecycle_panel)

func focus_support() -> void:
	refresh()
	_select_mode("SUPPORT")
	if after_sales_panel != null:
		call_deferred("ensure_control_visible", after_sales_panel)

func _relay_action(action: String, payload: Dictionary) -> void:
	action_requested.emit(action, payload)
