extends PanelContainer

signal action_requested(tab_index: int, context: String)
signal team_requested

const UI := preload("res://ui/UiKit.gd")

var _message_label: Label
var _objective_label: Label
var _team_label: Label
var _action_button: Button
var _team_button: Button
var _target_tab := 0
var _target_context := ""

func _ready() -> void:
	add_theme_stylebox_override("panel", UI.stylebox(UI.APP_CYAN_DARK, 14, 1, UI.APP_CYAN, 14))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build()

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	root.add_child(head)

	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(52, 52)
	avatar.add_theme_stylebox_override("panel", UI.stylebox(UI.APP_CYAN, 99, 0, UI.APP_CYAN, 0))
	var avatar_label := UI.label("N", 22)
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_color_override("font_color", UI.APP_BG)
	avatar.add_child(avatar_label)
	head.add_child(avatar)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(identity)
	var right_hand := ExecutiveManager.get_right_hand()
	identity.add_child(UI.label(str(right_hand.get("name", "Nora Bernard")), 18))
	var role := UI.muted_label(str(right_hand.get("role", "Bras droit / vice-présidente")), 12)
	role.add_theme_color_override("font_color", UI.APP_CYAN)
	identity.add_child(role)

	var badge := UI.label("GUIDE", 11)
	badge.add_theme_color_override("font_color", UI.APP_AMBER)
	head.add_child(badge)

	_message_label = UI.rich_label()
	_message_label.add_theme_font_size_override("font_size", 13)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_message_label)

	var objective_card := UI.card(UI.APP_PANEL_ALT, 10, 10)
	var objective_box := VBoxContainer.new()
	objective_box.add_theme_constant_override("separation", 4)
	objective_card.add_child(objective_box)
	objective_box.add_child(UI.eyebrow("OBJECTIF ACTUEL"))
	_objective_label = UI.label("", 14)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_box.add_child(_objective_label)
	root.add_child(objective_card)

	var team_card := UI.card(UI.APP_PANEL, 10, 10)
	var team_box := VBoxContainer.new()
	team_box.add_theme_constant_override("separation", 4)
	team_card.add_child(team_box)
	team_box.add_child(UI.eyebrow("QUI TRAVAILLE SUR LE CPU ?"))
	_team_label = UI.muted_label("", 12)
	_team_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	team_box.add_child(_team_label)
	root.add_child(team_card)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 6)
	root.add_child(actions)

	_action_button = Button.new()
	_action_button.custom_minimum_size.y = 42
	_action_button.pressed.connect(func(): action_requested.emit(_target_tab, _target_context))
	actions.add_child(_action_button)

	_team_button = Button.new()
	_team_button.text = "Voir l'équipe"
	_team_button.custom_minimum_size.y = 42
	_team_button.pressed.connect(func(): team_requested.emit())
	actions.add_child(_team_button)

	refresh()

func refresh() -> void:
	if _message_label == null:
		return
	var research_names := _department_names("R&D")
	var development_names := _department_names("Développement")
	var team_score := ResearchManager.development_team_score()
	var confidence := ResearchManager.development_confidence()

	_team_label.text = "R&D = recherche et nouvelles connaissances : %s.\nDéveloppement = transforme le design en produit : %s.\nÉquipe développement : %.0f/100 • confiance %.0f%%." % [
		_names_or_none(research_names),
		_names_or_none(development_names),
		team_score,
		confidence
	]
	_team_button.visible = ExecutiveManager.is_interface_feature_unlocked("TEAM")

	var active_project := _active_project()
	var active_job := _active_production_job()
	var ready_product := _first_product_with_status("READY")
	var launched_product := _first_product_with_status("LAUNCHED")

	if ResearchManager.projects.is_empty():
		_message_label.text = "Je suis Nora Bernard, votre bras droit. Mon rôle est de vous dire ce qui mérite votre attention sans vous noyer dans tous les systèmes du jeu."
		_objective_label.text = "Décider quel premier processeur construire et lancer son développement."
		_action_button.text = "Aller à l'établi CPU"
		_target_tab = 3
		_target_context = "Établi CPU"
	elif not active_project.is_empty():
		var pending_value = active_project.get("pending_decision", {})
		var pending: Dictionary = pending_value if typeof(pending_value) == TYPE_DICTIONARY else {}
		if not pending.is_empty():
			_message_label.text = "L'équipe attend votre arbitrage. Tant que cette décision n'est pas prise, le projet reste volontairement en pause."
			_objective_label.text = str(pending.get("text", "Prendre la décision de développement en attente."))
		else:
			var phase_index := clampi(int(active_project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
			_message_label.text = "Samira et Noah portent le développement du produit. Camille et Alex font progresser le savoir-faire qui améliorera ce CPU et les générations suivantes."
			_objective_label.text = "Suivre %s — phase %s à %.0f%%." % [
				str(active_project.get("name", "votre CPU")),
				str(GameData.PHASES[phase_index]),
				float(active_project.get("phase_progress", 0.0))
			]
		_action_button.text = "Ouvrir le laboratoire CPU"
		_target_tab = 3
		_target_context = ""
	elif not active_job.is_empty():
		_message_label.text = "Le développement est terminé. La prochaine décision est industrielle : qui fabrique, avec quelle stratégie et quel niveau de qualité."
		_objective_label.text = "Valider la route de fabrication du premier CPU."
		_action_button.text = "Piloter l'industrialisation"
		_target_tab = 4
		_target_context = ""
	elif not ready_product.is_empty():
		_message_label.text = "Le CPU est prêt. Il faut maintenant décider comment le vendre, à quel prix et avec quelle capacité."
		_objective_label.text = "Préparer le lancement commercial de %s." % str(ready_product.get("name", "votre CPU"))
		_action_button.text = "Préparer le lancement"
		_target_tab = 4
		_target_context = ""
	elif not launched_product.is_empty():
		_message_label.text = "Votre produit est sur le marché. Les ventes et retours clients deviennent maintenant notre meilleure source d'apprentissage."
		_objective_label.text = "Lire les résultats du marché et préparer la génération suivante."
		_action_button.text = "Analyser le marché"
		_target_tab = 5
		_target_context = ""
	else:
		_message_label.text = "Je reste votre point de repère. Quand une décision importante apparaît, je la remonterai ici."
		_objective_label.text = "Préparer la prochaine génération CPU."
		_action_button.text = "Ouvrir le laboratoire CPU"
		_target_tab = 3
		_target_context = ""

func _department_names(department: String) -> Array[String]:
	var result: Array[String] = []
	for employee_value in PersonnelManager.staff:
		var employee: Dictionary = employee_value
		if str(employee.get("department", "")) == department:
			result.append(str(employee.get("name", "")))
	return result

func _names_or_none(names: Array[String]) -> String:
	return ", ".join(names) if not names.is_empty() else "personne"

func _active_project() -> Dictionary:
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if str(project.get("status", "")) == "DEVELOPMENT":
			return project
	return {}

func _active_production_job() -> Dictionary:
	for job_value in ProductionManager.get_active_jobs():
		var job: Dictionary = job_value
		return job
	return {}

func _first_product_with_status(status: String) -> Dictionary:
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == status:
			return product
	return {}
