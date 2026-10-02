extends ScrollContainer

signal action_requested(action: String, payload: Dictionary)

const UI := preload("res://ui/UiKit.gd")

var mode_grid: GridContainer
var mode_buttons := {}
var pages := {}
var current_mode := "BUILD"
var industrialization_panel: Control
var lifecycle_panel: Control
var after_sales_panel: Control
var components_panel: Control

func _ready() -> void:
	name = "Produits"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()
	UI.configure_touch_scroll(self)
	UI.prepare_touch_scroll_children(self)
	_select_mode(_default_mode())
	refresh()

## Premier affichage : Vendre dès qu'un CPU existe, sinon Fabriquer.
func _default_mode() -> String:
	return "SELL" if not ProductManager.products.is_empty() else "BUILD"

func show_section_for_context(context: String) -> void:
	match context:
		"SAV", "Supporter":
			focus_support()
		"PRODUCTION", "Production", "Fabriquer", "Stock & production":
			_select_mode("BUILD")
		"PRODUCT_LAUNCH", "Vendre":
			_select_mode("SELL")
		"COMPONENTS", "Gammes":
			_select_mode("RANGES")

func current_section() -> String:
	return current_mode

func _build() -> void:
	var box := UI.content_box()
	add_child(box)
	box.add_child(UI.eyebrow("COCKPIT PRODUIT"))
	box.add_child(UI.label("Fabriquer, vendre, suivre", 24))
	var intro := UI.muted_label(
		"La conception se fait au Laboratoire. Ici, vos CPU sortent de l'usine, trouvent leurs clients et sont suivis après la vente.",
		12
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)

	# Lot A (29/09) : « Concevoir » ne faisait que renvoyer au Labo, et le SAV existait aussi dans
	# Marché. Le cockpit garde trois étapes ; le SAV n'existe plus qu'ici.
	mode_grid = GridContainer.new()
	mode_grid.columns = 4
	mode_grid.add_theme_constant_override("h_separation", 8)
	mode_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(mode_grid)
	_add_mode_button("BUILD", "1  FABRIQUER")
	_add_mode_button("SELL", "2  VENDRE")
	_add_mode_button("SUPPORT", "3  SAV")
	# V0.10 / Gammes : mémoire, alimentations, boîtiers.
	_add_mode_button("RANGES", "4  GAMMES")

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

	var components_script: Script = load("res://ui/components/ComponentsPanel.gd")
	components_panel = components_script.new() as Control
	components_panel.connect("status_changed", func(message: String): action_requested.emit("status", {"text":message}))
	box.add_child(components_panel)
	pages["RANGES"] = components_panel

func _add_mode_button(mode: String, title: String) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 46
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func(): _select_mode(mode))
	mode_grid.add_child(button)
	mode_buttons[mode] = button

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
	if mode == "RANGES" and components_panel != null:
		components_panel.call("refresh")

func set_viewport_width(width: float) -> void:
	if mode_grid != null:
		mode_grid.columns = 4 if width >= 700.0 else 2
	if industrialization_panel != null and industrialization_panel.has_method("set_viewport_width"):
		industrialization_panel.call("set_viewport_width", width)
	if lifecycle_panel != null and lifecycle_panel.has_method("set_viewport_width"):
		lifecycle_panel.call("set_viewport_width", width)
	if components_panel != null:
		components_panel.call("set_viewport_width", width)

func refresh() -> void:
	if industrialization_panel != null:
		industrialization_panel.call("refresh")
	if lifecycle_panel != null:
		lifecycle_panel.call("refresh")
	if after_sales_panel != null:
		after_sales_panel.call("refresh")
	if components_panel != null and components_panel.visible:
		components_panel.call("refresh")
	_refresh_mode_badges()

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
	mode_buttons["BUILD"].text = "1  FABRIQUER%s" % ("  • %d" % active_jobs if active_jobs > 0 else "")
	mode_buttons["SELL"].text = "2  VENDRE%s" % ("  • %d" % (ready_products + launched_products) if ready_products + launched_products > 0 else "")
	mode_buttons["SUPPORT"].text = "3  SAV%s" % ("  • %d" % open_sav if open_sav > 0 else "")
	var ranges := ComponentManager.active_products().size()
	mode_buttons["RANGES"].text = "4  GAMMES%s" % ("  • %d" % ranges if ranges > 0 else ("  • nouveau" if ComponentManager.any_open() else ""))

func focus_product_launch() -> void:
	refresh()
	_select_mode("SELL")
	if lifecycle_panel != null:
		# Arrivée par « Préparer le lancement » : on pointe le premier modèle réellement prêt,
		# pas le dernier consulté (qui peut être déjà lancé).
		if lifecycle_panel.has_method("select_first_ready"):
			lifecycle_panel.call("select_first_ready")
		call_deferred("_focus_product_launch_deferred")

func _focus_product_launch_deferred() -> void:
	if lifecycle_panel == null:
		return
	# V0.10 / I4 : on arrive sur la carte « Prêt à lancer » (en haut), pas au bas de la page.
	await get_tree().process_frame
	var target: Control = lifecycle_panel.call("launch_card") if lifecycle_panel.has_method("launch_card") else lifecycle_panel
	if target == null or not target.visible:
		target = lifecycle_panel
	if get_child_count() > 0 and get_child(0) is Control:
		scroll_vertical = maxi(int(target.global_position.y - (get_child(0) as Control).global_position.y - 8.0), 0)

## V0.10 / I4 : « Choisir la fabrication » amène sur la carte du CPU qui attend, bouton vert en vue.
func focus_production() -> void:
	refresh()
	_select_mode("BUILD")
	call_deferred("_focus_production_deferred")

func _focus_production_deferred() -> void:
	if industrialization_panel == null:
		return
	await get_tree().process_frame
	var target: Control = industrialization_panel.call("first_choice_card") if industrialization_panel.has_method("first_choice_card") else null
	if target == null:
		target = industrialization_panel
	if get_child_count() > 0 and get_child(0) is Control:
		scroll_vertical = maxi(int(target.global_position.y - (get_child(0) as Control).global_position.y - 8.0), 0)

func focus_support() -> void:
	refresh()
	_select_mode("SUPPORT")
	if after_sales_panel != null:
		call_deferred("ensure_control_visible", after_sales_panel)

func _relay_action(action: String, payload: Dictionary) -> void:
	match action:
		"focus_control":
			# I5 : le portefeuille ou la carte de Nora amènent sur la fiche / « Gérer ce modèle ».
			call_deferred("_scroll_to", payload.get("control", null))
		"open_support":
			focus_support()
		_:
			action_requested.emit(action, payload)

func _scroll_to(target: Variant) -> void:
	await get_tree().process_frame
	if target == null or not (target is Control) or not is_instance_valid(target):
		return
	if get_child_count() > 0 and get_child(0) is Control:
		scroll_vertical = maxi(int((target as Control).global_position.y - (get_child(0) as Control).global_position.y - 8.0), 0)

## V0.10 / I5 : « Vendre » s'ouvre en haut, sur la carte « Ce mois-ci ».
func focus_sales() -> void:
	refresh()
	_select_mode("SELL")
	scroll_vertical = 0
