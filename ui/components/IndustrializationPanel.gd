extends VBoxContainer
## V0.9 — Page « Fabriquer » (Produits) : des cartes au lieu du mur de texte (demande d'Alexandre, 29/09).
## • une carte par CPU en préparation d'usine : avancement, et quand un choix est attendu, trois
##   questions simples en boutons (où fabriquer ? priorité ? tri des puces ?) + « Lancer la production » ;
## • votre usine : état, capacité, location de la capacité libre, maintenance, agrandissement ;
## • les dernières productions terminées : 3 jauges + détails repliés ;
## • les fonderies partenaires : une jauge par fonderie.
## Les actions émises sont inchangées (apply_industrialization, build_fab, maintain_fab, toggle_capacity_sales).

signal action_requested(action: String, payload: Dictionary)

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")
const AMBER := Color("d9822b")
const IDLE_BG := Color("efe3d0")
const IDLE_TEXT := Color("6b5b48")

const STRATEGY_ORDER := ["ECONOMY", "BALANCED", "QUALITY", "SPEED"]
const STRATEGY_SHORT := {"ECONOMY":"Économie", "BALANCED":"Équilibré", "QUALITY":"Qualité", "SPEED":"Vitesse"}
const STRATEGY_HINTS := {
	"ECONOMY":"Coûte moins cher, prépare plus lentement, un peu plus de défauts.",
	"BALANCED":"Le bon compromis coût / délai / qualité.",
	"QUALITY":"Plus cher, mais moins de défauts et de meilleures puces.",
	"SPEED":"En boutique plus vite et plus de capacité, mais coûte cher.",
}
const BINNING_ORDER := ["VOLUME", "BALANCED", "STRICT"]
const BINNING_SHORT := {"VOLUME":"Volume", "BALANCED":"Équilibré", "STRICT":"Strict"}
const BINNING_HINTS := {
	"VOLUME":"Plus de puces classées haut de gamme, avec moins de marge.",
	"BALANCED":"Répartition normale entre les modèles de la gamme.",
	"STRICT":"Moins de puces haut de gamme, mais excellentes (overclocking).",
}

var _team_label: Label
var _jobs_box: VBoxContainer
var _fab_box: VBoxContainer
var _done_box: VBoxContainer
var _foundries_box: VBoxContainer
var _choices: Dictionary = {}
var _adjust_open: Dictionary = {}
var _go_buttons: Dictionary = {}
var _team_details: VBoxContainer
var _team_toggle: Button
var _signature := ""
var _narrow := false
## Produits > Fabriquer (08/10) : la planche 4 (ProductionBoard) montre déjà le CPU qui attend son usine.
var hide_waiting := false

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build()
	refresh()

func _build() -> void:
	add_child(UI.section("Fabrication"))
	# I4 : les CPU qui attendent un choix d'abord ; le savoir-faire de l'équipe ensuite, replié.
	_jobs_box = _vbox(10)
	add_child(_jobs_box)
	_team_toggle = Button.new()
	_team_toggle.flat = true
	_team_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_team_toggle.pressed.connect(func():
		_team_details.visible = not _team_details.visible
		_team_toggle.text = _team_toggle_text())
	add_child(_team_toggle)
	_team_details = _vbox(2)
	_team_details.visible = false
	add_child(_team_details)
	_team_label = UI.muted_label("", 12)
	_team_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_team_details.add_child(_team_label)
	add_child(UI.section("Votre usine"))
	_fab_box = _vbox(8)
	add_child(_fab_box)
	add_child(UI.section("Dernières productions"))
	_done_box = _vbox(8)
	add_child(_done_box)
	add_child(UI.section("Fonderies partenaires"))
	_foundries_box = _vbox(4)
	add_child(_foundries_box)

func set_viewport_width(width: float) -> void:
	var narrow := width < 760.0
	if narrow != _narrow:
		_narrow = narrow
		_signature = ""
		refresh()

func refresh() -> void:
	if _jobs_box == null:
		return
	var signature := _state_signature()
	if signature == _signature:
		return
	_signature = signature
	_team_label.text = _team_text()
	_team_toggle.text = _team_toggle_text()
	_go_buttons.clear()
	_rebuild_jobs()
	_rebuild_fab()
	_rebuild_done()
	_rebuild_foundries()
	UI.prepare_touch_scroll_children(self)

func _force_refresh() -> void:
	_signature = ""
	refresh()

## Ne reconstruit la page que si quelque chose de visible a changé (pas de saut de défilement).
func _state_signature() -> String:
	var parts: Array[String] = [str(_narrow), str(hide_waiting), str(ProductionManager.jobs.size())]
	for job_value in ProductionManager.jobs:
		var job: Dictionary = job_value
		parts.append("%s|%s|%d|%s|%s|%s" % [str(job.get("id", "")), str(job.get("status", "")), int(float(job.get("progress", 0.0))),
			str(job.get("route_selected", false)), str(job.get("route_committed", false)), str(job.get("route_error", ""))])
	var fab := FoundryManager.internal_fab_data()
	var construction := FoundryManager.active_construction()
	var upgrade := FoundryManager.next_internal_fab_upgrade()
	parts.append("%d|%d|%s|%d|%d|%s" % [int(fab.get("tier", 0)), int(float(fab.get("condition", 0.0))), str(fab.get("sell_spare_capacity", false)),
		int(fab.get("used_capacity", 0)), int(construction.get("months_remaining", -1)),
		str(Economy.can_afford(int(round(float(upgrade.get("build_cost", 0)) * 0.25)), "Acompte construction fab"))])
	for foundry_id in FoundryManager.external_foundry_keys():
		parts.append(str(int(float(FoundryManager.get_external_foundry(str(foundry_id)).get("technology_score", 0.0)))))
	return ";".join(parts)

func _team_toggle_text() -> String:
	var people := PersonnelManager.count_department("Production")
	var head := "Équipe production : %d personne%s" % [people, "s" if people > 1 else ""]
	return head + ("  ▴" if _team_details != null and _team_details.visible else "  •  savoir-faire  ▾")

func _team_text() -> String:
	var nodes := CPU_DESIGN.available_nodes_for_capabilities(
		float(ResearchManager.technologies.get("manufacturing", 0.0)), ResearchManager.get_cpu_capability("MINIATURIZATION"))
	var mastery: Array[String] = []
	for i in range(maxi(nodes.size() - 3, 0), nodes.size()):
		var node_nm := int(nodes[i])
		mastery.append("%s %.0f" % [CPU_DESIGN.node_label(node_nm), ProductionManager.get_process_mastery(node_nm)])
	return "Savoir-faire qualité %.0f (moins de défauts) • maintenance %.0f (usine en meilleur état)\nMaîtrise de la gravure (plus on produit, mieux c'est) : %s" % [
		ProductionManager.quality_knowledge,
		ProductionManager.maintenance_knowledge, " • ".join(mastery) if not mastery.is_empty() else "—"]

# --- CPU en préparation d'usine -------------------------------------------------------------

func _rebuild_jobs() -> void:
	_clear(_jobs_box)
	var active := ProductionManager.get_active_jobs()
	if hide_waiting:
		active = active.filter(func(job): return bool(job.get("route_selected", false)) or bool(job.get("route_committed", false)))
		if active.is_empty() and not ProductionManager.get_active_jobs().is_empty():
			return
	if active.is_empty():
		var empty := UI.muted_label("Aucun CPU en préparation d'usine. Quand un projet du Labo termine son prototype, il arrive ici pour être fabriqué.", 13)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_jobs_box.add_child(empty)
		return
	for job_value in active:
		_jobs_box.add_child(_job_card(job_value))

func _job_card(job: Dictionary) -> Control:
	var committed := bool(job.get("route_committed", false))
	var selected := bool(job.get("route_selected", false))
	var needs_choice := not selected and not committed
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL, 14, 2 if needs_choice else 1, AMBER if needs_choice else UI.APP_LINE, 12))
	var box := _vbox(8)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	head.add_child(UI.label(str(job.get("name", "CPU")), 18))
	var sub := UI.muted_label("gravure %s" % CPU_DESIGN.node_label(int(job.get("node_nm", 10000))), 13)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sub)
	var chip_text := "Choix à faire"
	var chip_color := AMBER
	if committed:
		chip_text = "En préparation"
		chip_color = UI.APP_GREEN
	elif selected:
		chip_text = "Démarre le mois prochain"
		chip_color = IDLE_TEXT
	head.add_child(_chip(chip_text, chip_color))
	var progress := float(job.get("progress", 0.0))
	if not needs_choice:
		box.add_child(UI.label("Préparation de l'usine : %.0f %%  •  %d mois" % [progress, int(job.get("months_spent", 0))], 14))
		box.add_child(_bar(progress, UI.APP_GREEN if committed else AMBER))
	var route_error := str(job.get("route_error", ""))
	if route_error != "":
		var warn := UI.label("⚠ " + route_error, 13)
		warn.add_theme_color_override("font_color", UI.APP_RED)
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(warn)
	if needs_choice:
		_add_choices(box, job)
	else:
		var summary := UI.muted_label(_route_summary(job), 13)
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(summary)
	return card

func _route_summary(job: Dictionary) -> String:
	var quote := ProductionManager.manufacturing_route_quote(str(job.get("id", "")))
	var strategy := str(job.get("strategy", "BALANCED"))
	var cost_factor := float(ProductionManager.STRATEGIES.get(strategy, {}).get("cost", 1.0)) * float(quote.get("cost_factor", 1.0))
	return "Fabriqué chez %s  •  priorité %s  •  tri %s  •  ~%s €/mois pendant la préparation" % [
		str(quote.get("provider_name", "—")), str(STRATEGY_SHORT.get(strategy, strategy)).to_lower(),
		str(BINNING_SHORT.get(str(job.get("binning_strategy", "BALANCED")), "")).to_lower(),
		UI.money(int(round(float(job.get("monthly_cost", 0)) * cost_factor)))]

func _choice_for(job: Dictionary) -> Dictionary:
	var job_id := str(job.get("id", ""))
	if not _choices.has(job_id):
		var node_nm := int(job.get("node_nm", 10000))
		var provider := str(job.get("foundry_id", ""))
		if str(job.get("manufacturing_mode", "EXTERNAL")) == "INTERNAL" or FoundryManager.internal_supports_node(node_nm):
			provider = "INTERNAL"
		if provider == "" or (provider != "INTERNAL" and not FoundryManager.provider_supports_node(provider, node_nm)):
			provider = FoundryManager.recommended_external_foundry(node_nm)
		_choices[job_id] = {"provider":provider, "strategy":str(job.get("strategy", "BALANCED")), "binning":str(job.get("binning_strategy", "BALANCED"))}
	return _choices[job_id]

func _route_options(node_nm: int) -> Array:
	var result: Array = []
	if FoundryManager.internal_supports_node(node_nm):
		var internal := FoundryManager.route_quote("INTERNAL", "INTERNAL", node_nm)
		if not internal.is_empty():
			result.append({"id":"INTERNAL", "quote":internal})
	for foundry_id in FoundryManager.available_external_foundries(node_nm):
		var quote := FoundryManager.route_quote("EXTERNAL", str(foundry_id), node_nm)
		if not quote.is_empty():
			result.append({"id":str(foundry_id), "quote":quote})
	return result

## V0.10 / I4 : d'abord la recommandation de Nora et le bouton vert (visible sans défiler sur téléphone),
## puis « Ajuster moi-même » replié avec les trois questions, chaque option expliquée en une phrase.
func _add_choices(box: VBoxContainer, job: Dictionary) -> void:
	var job_id := str(job.get("id", ""))
	var choice := _choice_for(job)
	var node_nm := int(job.get("node_nm", 10000))
	var options := _route_options(node_nm)
	var provider := str(choice.provider)
	var mode := "INTERNAL" if provider == "INTERNAL" else "EXTERNAL"
	var quote := FoundryManager.route_quote(mode, provider, node_nm)
	if options.is_empty() or quote.is_empty():
		var none := UI.label("Aucune usine ne sait encore graver en %s : il faut attendre que les fonderies progressent ou changer de gravure." % CPU_DESIGN.node_label(node_nm), 13)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(none)
	else:
		var plan := UI.label(choice_summary(job_id), 14)
		plan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(plan)
		var cost := UI.muted_label(choice_cost_text(job), 13)
		cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(cost)
	var go := Button.new()
	go.name = "GoProduction"
	go.custom_minimum_size = Vector2(0, 50)
	go.add_theme_font_size_override("font_size", 16)
	if quote.is_empty():
		go.text = "Choisissez où fabriquer"
		go.disabled = true
	else:
		go.text = "Lancer la production chez %s" % str(quote.get("provider_name", provider))
		go.add_theme_color_override("font_color", Color.WHITE)
		go.add_theme_color_override("font_hover_color", Color.WHITE)
		go.add_theme_color_override("font_pressed_color", Color.WHITE)
		go.add_theme_stylebox_override("normal", UI.stylebox(UI.APP_GREEN, 12, 0, UI.APP_GREEN, 10))
		go.add_theme_stylebox_override("hover", UI.stylebox(UI.APP_GREEN.darkened(0.1), 12, 0, UI.APP_GREEN, 10))
		go.add_theme_stylebox_override("pressed", UI.stylebox(UI.APP_GREEN.darkened(0.2), 12, 0, UI.APP_GREEN, 10))
		go.pressed.connect(func(): _apply(job_id))
	box.add_child(go)
	_go_buttons[job_id] = go
	if options.is_empty():
		return
	# Réglages fins, repliés : l'état ouvert/fermé survit aux reconstructions de la page.
	var open := bool(_adjust_open.get(job_id, false))
	var toggle := Button.new()
	toggle.flat = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.text = ("Masquer les réglages  ▴" if open else "Ajuster moi-même (usine, priorité, tri des puces)  ▾")
	toggle.pressed.connect(func():
		_adjust_open[job_id] = not bool(_adjust_open.get(job_id, false))
		call_deferred("_force_refresh"))
	box.add_child(toggle)
	if not open:
		return
	var recommended := FoundryManager.recommended_external_foundry(node_nm)
	# 1. Où fabriquer ?
	box.add_child(_question("1. Où fabriquer ?"))
	box.add_child(_hint("Précision : des puces plus réussies. Fiabilité : moins de retards. Coût : multiplie les frais mensuels."))
	var routes := HFlowContainer.new()
	routes.add_theme_constant_override("h_separation", 8)
	routes.add_theme_constant_override("v_separation", 8)
	box.add_child(routes)
	for option_value in options:
		var option: Dictionary = option_value
		var option_id := str(option.id)
		var option_quote: Dictionary = option.quote
		var tag := ""
		if option_id == "INTERNAL":
			tag = "  ★ votre usine"
		elif option_id == recommended:
			tag = "  ★ conseillé"
		var text := "%s%s\nPrécision %.0f • fiabilité %.0f • coût x%.2f\nMise en route %s €" % [
			str(option_quote.get("provider_name", option_id)), tag, float(option_quote.get("precision", 0.0)),
			float(option_quote.get("reliability", 0.0)), float(option_quote.get("cost_factor", 1.0)), UI.money(int(option_quote.get("setup_fee", 0)))]
		var tile := _toggle_button(text, provider == option_id, 250 if not _narrow else 0, 78)
		tile.pressed.connect(func(): _pick(job_id, "provider", option_id))
		routes.add_child(tile)
	# 2. Priorité de l'usine.
	box.add_child(_question("2. Priorité de l'usine"))
	box.add_child(_segmented(job_id, "strategy", STRATEGY_ORDER, STRATEGY_SHORT, str(choice.strategy)))
	box.add_child(_hint(str(STRATEGY_HINTS.get(str(choice.strategy), ""))))
	# 3. Tri des puces (binning).
	box.add_child(_question("3. Tri des puces"))
	box.add_child(_segmented(job_id, "binning", BINNING_ORDER, BINNING_SHORT, str(choice.binning)))
	box.add_child(_hint(str(BINNING_HINTS.get(str(choice.binning), ""))))

## Une phrase : où, comment, et si c'est le conseil de Nora.
func choice_summary(job_id: String) -> String:
	var job := _job_by_id(job_id)
	if job.is_empty():
		return ""
	var choice := _choice_for(job)
	var node_nm := int(job.get("node_nm", 10000))
	var provider := str(choice.provider)
	var quote := FoundryManager.route_quote("INTERNAL" if provider == "INTERNAL" else "EXTERNAL", provider, node_nm)
	var where := str(quote.get("provider_name", provider))
	var advised := provider == "INTERNAL" or provider == FoundryManager.recommended_external_foundry(node_nm)
	var settings := "priorité %s, tri %s" % [str(STRATEGY_SHORT.get(str(choice.strategy), "")).to_lower(), str(BINNING_SHORT.get(str(choice.binning), "")).to_lower()]
	if advised and str(choice.strategy) == "BALANCED" and str(choice.binning) == "BALANCED":
		return "Nora conseille : fabriquer chez %s, réglages équilibrés." % where
	return "Votre choix : fabriquer chez %s, %s." % [where, settings]

func choice_cost_text(job: Dictionary) -> String:
	var choice := _choice_for(job)
	var provider := str(choice.provider)
	var quote := FoundryManager.route_quote("INTERNAL" if provider == "INTERNAL" else "EXTERNAL", provider, int(job.get("node_nm", 10000)))
	if quote.is_empty():
		return ""
	var monthly := int(round(float(job.get("monthly_cost", 0)) * float(ProductionManager.STRATEGIES.get(str(choice.strategy), {}).get("cost", 1.0)) * float(quote.get("cost_factor", 1.0))))
	return "Coût : %s € de mise en route, puis ~%s €/mois pendant la préparation de l'usine." % [UI.money(int(quote.get("setup_fee", 0))), UI.money(monthly)]

## Le bouton vert de la carte (pour la navigation et les tests).
func go_button(job_id: String = "") -> Button:
	if job_id == "":
		for key in _go_buttons.keys():
			var b: Button = _go_buttons[key]
			if is_instance_valid(b):
				return b
		return null
	var button: Button = _go_buttons.get(job_id, null)
	return button if is_instance_valid(button) else null

## La première carte qui attend un choix (pour y amener le joueur).
func first_choice_card() -> Control:
	var button := go_button()
	if button == null:
		return null
	var node: Node = button
	while node != null and node.get_parent() != _jobs_box:
		node = node.get_parent()
	return node as Control

func _job_by_id(job_id: String) -> Dictionary:
	for job_value in ProductionManager.jobs:
		if str((job_value as Dictionary).get("id", "")) == job_id:
			return job_value
	return {}

func _pick(job_id: String, field: String, value: String) -> void:
	if _choices.has(job_id):
		(_choices[job_id] as Dictionary)[field] = value
	# Différé : le bouton touché est reconstruit, on ne le libère pas pendant son propre signal.
	call_deferred("_force_refresh")

func _apply(job_id: String) -> void:
	var choice: Dictionary = _choices.get(job_id, {})
	var provider := str(choice.get("provider", ""))
	action_requested.emit("apply_industrialization", {
		"job_id":job_id,
		"strategy":str(choice.get("strategy", "BALANCED")),
		"binning":str(choice.get("binning", "BALANCED")),
		"mode":"INTERNAL" if provider == "INTERNAL" else "EXTERNAL",
		"provider":provider
	})
	_choices.erase(job_id)
	call_deferred("_force_refresh")

# --- Votre usine ----------------------------------------------------------------------------

func _rebuild_fab() -> void:
	_clear(_fab_box)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL, 14, 1, UI.APP_LINE, 12))
	var box := _vbox(8)
	card.add_child(box)
	_fab_box.add_child(card)
	var fab := FoundryManager.internal_fab_data()
	var construction := FoundryManager.active_construction()
	var upgrade := FoundryManager.next_internal_fab_upgrade()
	if bool(fab.get("built", false)):
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		var name_label := UI.label(str(fab.get("name", "Fab interne")), 18)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(name_label)
		head.add_child(_chip("Opérationnelle", UI.APP_GREEN))
		box.add_child(head)
		var condition := float(fab.get("condition", 0.0))
		var state_row := UI.meter_row("État de l'usine", "Sous 60, pensez à la maintenance")
		UI.set_meter(state_row, condition, "%.0f/100" % condition)
		box.add_child(state_row)
		var capacity := maxi(int(fab.get("capacity", 0)), 1)
		var used := int(fab.get("used_capacity", 0))
		var use_row := UI.meter_row("Capacité utilisée", "Par vos propres CPU")
		UI.set_meter(use_row, float(used) / float(capacity) * 100.0, "%s / %s par mois" % [UI.money(used), UI.money(capacity)])
		box.add_child(use_row)
		box.add_child(UI.muted_label("Frais fixes : %s €/mois  •  précision %.0f/100" % [UI.money(FoundryManager.current_monthly_overhead()), float(fab.get("precision", 0.0))], 13))
		var rent := CheckButton.new()
		rent.text = "Louer la capacité libre à d'autres fabricants"
		rent.button_pressed = bool(fab.get("sell_spare_capacity", false))
		rent.toggled.connect(func(_on): action_requested.emit("toggle_capacity_sales", {}))
		box.add_child(rent)
		var actions := HFlowContainer.new()
		actions.add_theme_constant_override("h_separation", 8)
		actions.add_theme_constant_override("v_separation", 8)
		box.add_child(actions)
		var maintain := Button.new()
		maintain.text = "Maintenance lourde (%s €)" % UI.money(FoundryManager.current_monthly_overhead() * 2)
		maintain.custom_minimum_size.y = 44
		maintain.pressed.connect(func(): action_requested.emit("maintain_fab", {}))
		actions.add_child(maintain)
		if construction.is_empty() and not upgrade.is_empty():
			actions.add_child(_build_button(upgrade, "Agrandir"))
		elif not construction.is_empty():
			_add_construction(box, construction)
		return
	if not construction.is_empty():
		box.add_child(UI.label("Votre première usine est en chantier", 16))
		_add_construction(box, construction)
		return
	box.add_child(UI.label("Pas encore d'usine à vous", 16))
	var intro := UI.muted_label("Vos CPU sont fabriqués par des fonderies partenaires. Une usine à vous coûte moins cher par puce, apprend plus vite et loue sa capacité libre.", 13)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)
	if not upgrade.is_empty():
		box.add_child(UI.muted_label("%s : capacité %s puces/mois • frais fixes %s €/mois" % [
			str(upgrade.get("name", "")), UI.money(int(upgrade.get("capacity", 0))), UI.money(int(upgrade.get("monthly_overhead", 0)))], 13))
		box.add_child(_build_button(upgrade, "Construire"))

func _build_button(upgrade: Dictionary, verb: String) -> Control:
	var wrap := _vbox(4)
	var cost := int(upgrade.get("build_cost", 0))
	var deposit := int(round(float(cost) * 0.25))
	var button := Button.new()
	button.custom_minimum_size.y = 44
	button.text = "%s : %s — %s €, %d mois" % [verb, str(upgrade.get("name", "")), UI.money(cost), int(upgrade.get("build_months", 0))]
	var needed := float(upgrade.get("required_manufacturing", 0.0))
	var have := float(ResearchManager.technologies.get("manufacturing", 0.0))
	var reason := ""
	if have + 0.001 < needed:
		reason = "Il faut une maîtrise de fabrication de %.0f (vous : %.0f). Elle progresse en produisant et avec la recherche « miniaturisation »." % [needed, have]
	elif not Economy.can_afford(deposit, "Acompte construction fab"):
		reason = "Acompte de %s € à payer au lancement du chantier (25 %%), le reste pendant la construction." % UI.money(deposit)
	button.disabled = reason != ""
	button.pressed.connect(func(): action_requested.emit("build_fab", {}))
	wrap.add_child(button)
	if reason != "":
		wrap.add_child(_hint(reason))
	else:
		wrap.add_child(_hint("Acompte %s € maintenant, le reste étalé sur le chantier." % UI.money(deposit)))
	return wrap

func _add_construction(box: VBoxContainer, construction: Dictionary) -> void:
	var total := maxi(int(construction.get("months_total", 1)), 1)
	var remaining := int(construction.get("months_remaining", 0))
	box.add_child(UI.label("Chantier : %s — encore %d mois" % [str(construction.get("name", "")), remaining], 14))
	box.add_child(_bar(float(total - remaining) / float(total) * 100.0, AMBER))
	box.add_child(UI.muted_label("Reste à payer : %s €" % UI.money(int(construction.get("remaining_cost", 0))), 13))

# --- Dernières productions ------------------------------------------------------------------

func _rebuild_done() -> void:
	_clear(_done_box)
	var shown := 0
	for i in range(ProductionManager.jobs.size() - 1, -1, -1):
		var job: Dictionary = ProductionManager.jobs[i]
		if str(job.get("status", "")) == "INDUSTRIALIZATION":
			continue
		var result: Dictionary = job.get("result", {})
		if result.is_empty():
			continue
		_done_box.add_child(_done_card(job, result))
		shown += 1
		if shown >= 3:
			break
	if shown == 0:
		_done_box.add_child(UI.muted_label("Aucune production terminée pour l'instant.", 13))

func _done_card(job: Dictionary, result: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL, 14, 1, UI.APP_LINE, 12))
	var box := _vbox(6)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var title := UI.label(str(job.get("name", "CPU")), 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(_chip("Terminée", UI.APP_GREEN))
	box.add_child(head)
	var quality := float(result.get("quality_score", 0.0))
	var dies := float(result.get("die_quality_mean", result.get("silicon_quality_mean", 0.0)))
	var defects := float(result.get("defect_rate", 0.0)) * 100.0
	for row_data in [["Qualité de l'usine", quality, "%.0f/100" % quality],
			["Qualité des puces", dies, "%.0f/100" % dies],
			["Puces sans défaut", clampf(100.0 - defects * 6.0, 0.0, 100.0), "%.1f %% de défauts" % defects]]:
		var row := UI.meter_row(str(row_data[0]))
		UI.set_meter(row, float(row_data[1]), str(row_data[2]))
		box.add_child(row)
	box.add_child(UI.muted_label("Fabriqué chez %s  •  overclocking typique +%.1f %%  •  %s" % [
		str(result.get("foundry_name", "—")), float(result.get("oc_headroom_pct", 0.0)),
		ProductionManager.binning_strategy_label(str(result.get("binning_strategy", "BALANCED")))], 13))
	var details: Array[String] = [
		"Priorité : %s • %d mois de préparation" % [ProductionManager.strategy_label(str(result.get("strategy", "BALANCED"))), int(result.get("months", 0))],
		"Maîtrise du procédé %.0f/100 • gravure / équipement %.0f/100 • marges de conception %.0f/100" % [
			float(result.get("process_mastery", 0.0)), float(result.get("lithography_precision", 0.0)), float(result.get("design_margin_score", 0.0))],
		"Dispersion des puces ± %.1f • prévisibilité %.0f/100 • undervolt %.1f %%" % [
			float(result.get("die_variation", result.get("silicon_variation", 0.0))),
			float(result.get("process_predictability", result.get("silicon_predictability", 0.0))), float(result.get("undervolt_headroom_pct", 0.0))],
		"Dépendance au fournisseur %.0f/100 • confidentialité %.0f/100 • capacité ~%s/mois" % [
			float(result.get("foundry_dependency", 0.0)), float(result.get("foundry_confidentiality", 0.0)), UI.money(int(result.get("foundry_capacity", 0)))],
	]
	_add_details(box, details)
	return card

# --- Fonderies partenaires ------------------------------------------------------------------

func _rebuild_foundries() -> void:
	_clear(_foundries_box)
	for foundry_id_value in FoundryManager.external_foundry_keys():
		var provider := FoundryManager.get_external_foundry(str(foundry_id_value))
		var row := UI.meter_row(str(provider.get("name", foundry_id_value)),
			"précision %.0f • fiabilité %.0f • coût x%.2f • dépendance %.0f" % [float(provider.get("precision", 0.0)),
			float(provider.get("reliability", 0.0)), float(provider.get("cost_factor", 1.0)), float(provider.get("dependency", 0.0))])
		var tech := float(provider.get("technology_score", 0.0))
		UI.set_meter(row, tech, "techno %.0f" % tech)
		_foundries_box.add_child(row)

# --- Petits éléments ------------------------------------------------------------------------

func _vbox(separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box

func _clear(box: Control) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

func _question(text: String) -> Label:
	var label := UI.label(text, 15)
	label.add_theme_color_override("font_color", UI.APP_TEXT)
	return label

func _hint(text: String) -> Label:
	var label := UI.muted_label(text, 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _chip(text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.stylebox(color, 12, 0, color, 6))
	var label := UI.label(text, 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	return panel

func _bar(value: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10
	bar.max_value = 100
	bar.value = clampf(value, 0.0, 100.0)
	bar.add_theme_stylebox_override("fill", UI.stylebox(color, 5, 0, color, 0))
	bar.add_theme_stylebox_override("background", UI.stylebox(Color("ead9c0"), 5, 0, UI.APP_LINE, 0))
	return bar

func _toggle_button(text: String, active: bool, min_width: int, min_height: int) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(min_width, min_height)
	if min_width <= 0:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := AMBER if active else IDLE_BG
	var fg := Color.WHITE if active else IDLE_TEXT
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, UI.stylebox(bg.darkened(0.06) if state == "hover" else bg, 10, 2 if active else 1, AMBER if active else UI.APP_LINE, 10))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, fg)
	return button

func _segmented(job_id: String, field: String, order: Array, labels: Dictionary, current: String) -> Control:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	for key_value in order:
		var key := str(key_value)
		var button := _toggle_button(str(labels.get(key, key)), key == current, 118, 42)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(func(): _pick(job_id, field, key))
		row.add_child(button)
	return row

func _add_details(box: VBoxContainer, lines: Array[String]) -> void:
	var toggle := Button.new()
	toggle.text = "Détails  ▾"
	toggle.flat = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(toggle)
	var details := _vbox(2)
	details.visible = false
	for line_text in lines:
		var label := UI.muted_label(line_text, 12)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(label)
	box.add_child(details)
	toggle.pressed.connect(_toggle_details.bind(toggle, details))

func _toggle_details(toggle: Button, details: Control) -> void:
	details.visible = not details.visible
	toggle.text = "Masquer les détails  ▴" if details.visible else "Détails  ▾"
