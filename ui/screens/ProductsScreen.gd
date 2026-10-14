extends ScrollContainer

signal action_requested(action: String, payload: Dictionary)

const UI := preload("res://ui/UiKit.gd")
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")

var mode_grid: GridContainer
var mode_buttons := {}
var pages := {}
var current_mode := "BUILD"
var industrialization_panel: Control
var lifecycle_panel: Control
var after_sales_panel: Control
var components_panel: Control
var software_panel: VBoxContainer
## Revue des onglets (08/10) : une scène avec Noah en tête, et la planche 4 quand un prototype attend l'usine.
var scene: Control
var production_board: Control
var _scene_action := ""

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
		"SOFTWARE_PRODUCTS", "Logiciels":
			_select_mode("SOFTWARE")

func current_section() -> String:
	return current_mode

func _build() -> void:
	var box := UI.content_box()
	add_child(box)
	scene = (load("res://ui/components/SceneHeader.gd") as Script).new() as Control
	scene.connect("hero_pressed", _on_scene_hero)
	box.add_child(scene)

	# Lot A (29/09) : « Concevoir » ne faisait que renvoyer au Labo, et le SAV existait aussi dans
	# Marché. Le cockpit garde trois étapes ; le SAV n'existe plus qu'ici.
	mode_grid = GridContainer.new()
	mode_grid.columns = 5
	mode_grid.add_theme_constant_override("h_separation", 8)
	mode_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(mode_grid)
	_add_mode_button("BUILD", "1  FABRIQUER")
	_add_mode_button("SELL", "2  VENDRE")
	_add_mode_button("SUPPORT", "3  SAV")
	# V0.10 / Gammes : mémoire, alimentations, boîtiers.
	_add_mode_button("RANGES", "4  GAMMES")
	# Revue des onglets (14/10) : vos logiciels avaient leur catalogue caché dans l'atelier.
	_add_mode_button("SOFTWARE", "5  LOGICIELS")

	production_board = (load("res://ui/components/ProductionBoard.gd") as Script).new() as Control
	production_board.connect("launch_requested", func(payload: Dictionary): action_requested.emit("apply_industrialization", payload))
	box.add_child(production_board)

	var industrialization_script: Script = load("res://ui/components/IndustrializationPanel.gd")
	industrialization_panel = industrialization_script.new() as Control
	industrialization_panel.connect("action_requested", _relay_action)
	# La planche 4 remplace la carte « choix à faire » : le panneau garde l'usine et les productions.
	industrialization_panel.set("hide_waiting", true)
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

	software_panel = VBoxContainer.new()
	software_panel.add_theme_constant_override("separation", 8)
	box.add_child(software_panel)
	pages["SOFTWARE"] = software_panel

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
	if mode == "SOFTWARE":
		_refresh_software()
	_refresh_board()

## Le premier CPU qui attend qu'on choisisse son usine (vide sinon).
func waiting_job() -> Dictionary:
	for job_value in ProductionManager.get_active_jobs():
		var job: Dictionary = job_value
		if not bool(job.get("route_selected", false)) and not bool(job.get("route_committed", false)):
			return job
	return {}

func _refresh_board() -> void:
	if production_board == null:
		return
	var job := waiting_job()
	production_board.visible = current_mode == "BUILD" and not job.is_empty()
	if production_board.visible:
		production_board.call("set_job", str(job.get("id", "")))

## Ce que Noah dit en tête de l'onglet : le moment de la fabrication et des ventes, en une phrase.
func products_diagnosis() -> Dictionary:
	var job := waiting_job()
	if not job.is_empty():
		return {"line":"Noah : « Le prototype de %s est validé. Choisis qui grave nos puces, et on lance l'usine. »" % str(job.get("name", "CPU")),
			"value":str(job.get("name", "CPU")), "caption":"attend son usine", "button":"Choisir l'usine", "action":"BUILD"}
	for job_value in ProductionManager.get_active_jobs():
		var running: Dictionary = job_value
		return {"line":"Noah : « L'usine prépare %s. Encore un peu de patience avant les premières séries. »" % str(running.get("name", "CPU")),
			"value":"%.0f %%" % float(running.get("progress", 0.0)), "caption":"préparation de %s" % str(running.get("name", "CPU")), "button":"", "action":""}
	var ready: Array = []
	var launched := 0
	var sold := 0
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("company", CompanyManager.company_name)) != CompanyManager.company_name:
			continue
		match str(product.get("status", "")):
			"READY":
				ready.append(product)
			"LAUNCHED":
				launched += 1
				sold += int(product.get("last_month_sales", 0))
	if not ready.is_empty():
		return {"line":"Noah : « %s sort de l'usine. Il ne lui manque qu'un prix pour partir en rayon. »" % str((ready[0] as Dictionary).get("generation_name", (ready[0] as Dictionary).get("name", "Le CPU"))),
			"value":"%d" % ready.size(), "caption":"modèle%s prêt%s à lancer" % ["s" if ready.size() > 1 else "", "s" if ready.size() > 1 else ""], "button":"Fixer le prix", "action":"LAUNCH"}
	if launched > 0:
		return {"line":"Noah : « %d CPU en rayon. Le mois dernier, %s puces sont parties chez les clients. »" % [launched, UI.money(sold)],
			"value":UI.money(sold), "caption":"puces vendues le mois dernier", "button":"Voir les ventes", "action":"SELL"}
	return {"line":"Noah : « Rien à fabriquer pour l'instant. Un nouveau CPU se conçoit au labo, puis il passe par ici. »",
		"value":"0", "caption":"CPU en vente", "button":"", "action":""}

func _refresh_scene() -> void:
	if scene == null:
		return
	var diagnosis := products_diagnosis()
	scene.call("set_scene", "res://assets/art/v010/J3_moments/moment_premier_cpu.webp", "LES PRODUITS")
	scene.call("set_speaker", WORKPLACE.character_path(WORKPLACE.cast_look("Noah Leroy"), "joie" if str(diagnosis.action) in ["BUILD", "LAUNCH"] else "bureau"))
	scene.call("set_line", str(diagnosis.line))
	scene.call("set_hero", str(diagnosis.value), str(diagnosis.caption), str(diagnosis.button))
	_scene_action = str(diagnosis.action)

func _on_scene_hero() -> void:
	match _scene_action:
		"BUILD":
			focus_production()
		"LAUNCH":
			focus_product_launch()
		"SELL":
			focus_sales()

func set_viewport_width(width: float) -> void:
	if mode_grid != null:
		# Toutes les étapes sur une ligne dès 700 px (téléphone en paysage) : 4, ou 5 avec les logiciels.
		var shown := 0
		for button in mode_buttons.values():
			if (button as Button).visible:
				shown += 1
		mode_grid.columns = maxi(shown, 1) if width >= 700.0 else 2
	if industrialization_panel != null and industrialization_panel.has_method("set_viewport_width"):
		industrialization_panel.call("set_viewport_width", width)
	if lifecycle_panel != null and lifecycle_panel.has_method("set_viewport_width"):
		lifecycle_panel.call("set_viewport_width", width)
	if components_panel != null:
		components_panel.call("set_viewport_width", width)
	if production_board != null:
		production_board.call("set_viewport_width", width)

func refresh() -> void:
	if industrialization_panel != null:
		industrialization_panel.call("refresh")
	if lifecycle_panel != null:
		lifecycle_panel.call("refresh")
	if after_sales_panel != null:
		after_sales_panel.call("refresh")
	if components_panel != null and components_panel.visible:
		components_panel.call("refresh")
	if software_panel != null and software_panel.visible:
		_refresh_software()
	if mode_buttons.has("SOFTWARE"):
		(mode_buttons["SOFTWARE"] as Button).visible = SoftwareManager.any_open()
	_refresh_board()
	_refresh_scene()
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
	if mode_buttons.has("SOFTWARE"):
		var software := SoftwareManager.active_products().size()
		mode_buttons["SOFTWARE"].text = "5  LOGICIELS%s" % ("  • %d" % software if software > 0 else "")

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
	var target: Control = production_board if production_board != null and production_board.visible else null
	if target == null and industrialization_panel.has_method("first_choice_card"):
		target = industrialization_panel.call("first_choice_card")
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


const STUDIO := preload("res://scripts/SoftwareStudio.gd")
const SOFTWARE_CAT := preload("res://scripts/SoftwareCatalog.gd")

## Les logiciels en vente, d'un coup d'œil : note du moment, licences, marge. Le détail reste dans l'atelier.
func _refresh_software() -> void:
	if software_panel == null:
		return
	for child in software_panel.get_children():
		software_panel.remove_child(child)
		child.queue_free()
	var open := Button.new()
	open.text = "Ouvrir l'atelier Logiciel"
	open.custom_minimum_size.y = 46
	open.pressed.connect(func(): action_requested.emit("open_software", {}))
	software_panel.add_child(open)
	var active := SoftwareManager.active_products()
	if active.is_empty():
		software_panel.add_child(UI.muted_label("Aucun logiciel en vente. Le studio se trouve dans « Nouveau projet », puis Logiciel.", 13))
		return
	var total := 0
	for value in active:
		total += int((value as Dictionary).get("margin_last", 0))
	software_panel.add_child(UI.label("%d logiciel(s) en vente • marge %s €/mois" % [active.size(), UI.money(total)], 15))
	for value in active:
		var product: Dictionary = value
		var card := UI.card(UI.APP_PANEL, 12, 10)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		if str(product.get("kind", "")) == "STUDIO":
			var note := float(product.get("note_live", product.get("note", 5.0)))
			var badge := UI.label(UI.fr(note), 18)
			badge.custom_minimum_size = Vector2(58, 44)
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			badge.add_theme_color_override("font_color", Color.WHITE)
			var tint := Color("2f7a3a") if note >= 7.5 else (Color("d9822b") if note >= 5.5 else Color("b3261e"))
			badge.add_theme_stylebox_override("normal", UI.stylebox(tint, 22, 0, tint, 0))
			row.add_child(badge)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(words)
		words.add_child(UI.label("%s • v%d.%d" % [str(product.get("name", "Logiciel")), int(product.get("version_major", 1)), int(product.get("version_minor", 0))], 15))
		var who := ""
		if str(product.get("kind", "")) == "STUDIO":
			who = "%s pour %s • " % [SOFTWARE_CAT.family_label(str(product.family)), STUDIO.audience_label(str(product.get("audience", ""))).to_lower()]
		words.add_child(UI.muted_label("%s%s licences ce mois • marge %s €/mois" % [who, UI.money(int(product.get("licenses_last", 0))), UI.money(int(product.get("margin_last", 0)))], 12))
		software_panel.add_child(card)
