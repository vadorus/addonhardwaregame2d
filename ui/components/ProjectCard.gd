extends PanelContainer
## V0.9 — Carte de projet (onglet Labo > Projets) : remplace le mur de texte.
## Nom, gamme, architecture, frise des 5 étapes (Idée → Conception → Prototype → Production → Lancement),
## étape en cours avec sa jauge, une ligne de caractéristiques, résultat commercial, détails repliés.

signal decision_requested(project_id: String)

const UI := preload("res://ui/UiKit.gd")
const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const CATALOG := preload("res://scripts/ArchitectureCatalog.gd")
const STAGES := ["Idée", "Conception", "Prototype", "Production", "Lancement"]
const AMBER := Color("d9822b")

var _details_box: VBoxContainer
var _details_button: Button

func show_project(project: Dictionary, detail_lines: Array) -> void:
	var stage := _stage_of(project)
	var decision := _pending_decision(project)
	var finished := stage >= 5
	add_theme_stylebox_override("panel", UI.stylebox(UI.APP_PANEL, 14, 2 if not decision.is_empty() else 1, AMBER if not decision.is_empty() else UI.APP_LINE, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	# En-tête : nom, gamme, architecture, statut.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	var title := UI.label(str(project.get("name", "Projet CPU")), 18)
	head.add_child(title)
	var line := ArchitectureManager.get_line(str(project.get("line_id", "")))
	var tags: Array = []
	if not line.is_empty():
		tags.append("Gamme %s" % str(line.name))
	var arch_id := str(project.get("architecture_id", ""))
	if arch_id != "":
		tags.append(str(CATALOG.get_by_id(arch_id).name))
	var tag_label := UI.muted_label("  •  ".join(tags), 13)
	tag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tag_label)
	head.add_child(_chip(_status_text(project, stage, decision), not decision.is_empty(), finished))
	# Frise des 5 étapes.
	box.add_child(_timeline(stage))
	# Étape en cours.
	var now := _now_text(project, stage, decision)
	if now != "":
		var now_row := HBoxContainer.new()
		now_row.add_theme_constant_override("separation", 10)
		var now_label := UI.label(now, 14)
		now_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		now_row.add_child(now_label)
		if not decision.is_empty():
			var go := Button.new()
			go.text = "Décider maintenant"
			go.custom_minimum_size = Vector2(190, 40)
			go.add_theme_color_override("font_color", Color.WHITE)
			go.add_theme_stylebox_override("normal", UI.stylebox(AMBER, 10, 0, AMBER, 8))
			go.add_theme_stylebox_override("hover", UI.stylebox(AMBER.darkened(0.1), 10, 0, AMBER, 8))
			var project_id := str(project.get("id", ""))
			go.pressed.connect(func(): decision_requested.emit(project_id))
			now_row.add_child(go)
		box.add_child(now_row)
		var progress := _stage_progress(project, stage)
		if progress >= 0.0:
			var bar := ProgressBar.new()
			bar.show_percentage = false
			bar.custom_minimum_size.y = 10
			bar.max_value = 100
			bar.value = progress
			bar.add_theme_stylebox_override("fill", UI.stylebox(AMBER, 5, 0, AMBER, 0))
			bar.add_theme_stylebox_override("background", UI.stylebox(Color("ead9c0"), 5, 0, UI.APP_LINE, 0))
			box.add_child(bar)
	# Une ligne : ce qu'est la puce.
	var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
	var segment := str(project.get("segment", ""))
	box.add_child(UI.muted_label("%d cœur(s) • %s • %s • %s • %d W  —  %s • priorité %s" % [
		int(design.cores), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design),
		CPU_DESIGN.node_label(int(design.node_nm)), int(design.tdp_w),
		str(GameData.SEGMENTS.get(segment, {}).get("label", segment)), str(project.get("focus_label", "Équilibré"))], 13))
	# Résultat commercial.
	var sales := _sales_text(project)
	if sales != "":
		var sales_label := UI.label(sales, 14)
		sales_label.add_theme_color_override("font_color", UI.APP_GREEN)
		box.add_child(sales_label)
	# Détails repliés.
	if not detail_lines.is_empty():
		_details_button = Button.new()
		_details_button.text = "Détails  ▾"
		_details_button.flat = true
		_details_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_details_button.pressed.connect(_toggle_details)
		box.add_child(_details_button)
		_details_box = VBoxContainer.new()
		_details_box.visible = false
		for line_text in detail_lines:
			var detail := UI.muted_label(str(line_text).strip_edges(), 12)
			detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_details_box.add_child(detail)
		box.add_child(_details_box)

func _toggle_details() -> void:
	_details_box.visible = not _details_box.visible
	_details_button.text = "Masquer les détails  ▴" if _details_box.visible else "Détails  ▾"

# --- Où en est le projet ------------------------------------------------------------------

func _products_of(project: Dictionary) -> Array:
	var result: Array = []
	var project_id := str(project.get("id", ""))
	for product in ProductManager.products:
		if str(product.get("project_id", "")) == project_id:
			result.append(product)
	return result

func _job_of(project: Dictionary) -> Dictionary:
	var project_id := str(project.get("id", ""))
	for job in ProductionManager.jobs:
		if str(job.get("project_id", "")) == project_id and not ["COMPLETED", "DONE", "FINISHED"].has(str(job.get("status", ""))):
			return job
	return {}

## 0 Idée, 1 Conception, 2 Prototype, 3 Production, 4 Lancement, 5 = en vente (tout est fait).
func _stage_of(project: Dictionary) -> int:
	if str(project.get("status", "")) == "DEVELOPMENT":
		return 1 if int(project.get("phase_index", 0)) < 2 else 2
	var products := _products_of(project)
	for product in products:
		if str(product.get("status", "")) == "LAUNCHED":
			return 5
	for product in products:
		if str(product.get("status", "")) == "READY":
			return 4
	return 3

func _pending_decision(project: Dictionary) -> Dictionary:
	var value = project.get("pending_decision", {})
	return value if typeof(value) == TYPE_DICTIONARY else {}

func _status_text(_project: Dictionary, stage: int, decision: Dictionary) -> String:
	if not decision.is_empty():
		return "Décision en attente"
	if stage >= 5:
		return "En vente"
	return "En cours"

func _now_text(project: Dictionary, stage: int, decision: Dictionary) -> String:
	if not decision.is_empty():
		return "À décider : %s" % str(decision.get("title", decision.get("kicker", "une décision de l'équipe"))).capitalize()
	match stage:
		1, 2:
			var delay := int(project.get("decision_delay_months_remaining", 0)) + int(project.get("remediation_months_remaining", 0))
			if delay > 0:
				return "Correction en cours — encore %d mois" % delay
			var phase_index := clampi(int(project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
			return "%s : phase « %s »" % [STAGES[stage], str(GameData.PHASES[phase_index])]
		3:
			return "Production : l'usine se prépare (industrialisation)"
		4:
			return "Prêt à lancer : choisissez le prix et la capacité dans Produits"
	return ""

func _stage_progress(project: Dictionary, stage: int) -> float:
	if stage == 1 or stage == 2:
		return float(project.get("phase_progress", 0.0))
	if stage == 3:
		var job := _job_of(project)
		return float(job.get("progress", 0.0)) if not job.is_empty() else -1.0
	return -1.0

func _sales_text(project: Dictionary) -> String:
	var launched := 0
	var units := 0
	for product in _products_of(project):
		if str(product.get("status", "")) == "LAUNCHED":
			launched += 1
		units += int(product.get("units_sold_total", 0))
	if launched == 0:
		return ""
	return "%d modèle(s) en vente  •  %s unités vendues" % [launched, UI.money(units)]

# --- Visuels -----------------------------------------------------------------------------

func _chip(text: String, alert: bool, done: bool) -> Control:
	var panel := PanelContainer.new()
	var color := AMBER if alert else (UI.APP_GREEN if done else Color("7a6a58"))
	panel.add_theme_stylebox_override("panel", UI.stylebox(color, 12, 0, color, 6))
	var label := UI.label(text, 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	return panel

## Frise : pastilles reliées. Vert = fait, ambre = en cours, gris = à venir.
func _timeline(stage: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	for i in range(STAGES.size()):
		if i > 0:
			var link := ColorRect.new()
			link.custom_minimum_size = Vector2(0, 4)
			link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			link.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			link.color = UI.APP_GREEN if i <= stage else Color("e2d2b8")
			row.add_child(link)
		var done := i < stage
		var current := i == stage
		var pill := PanelContainer.new()
		var bg := UI.APP_GREEN if done else (AMBER if current else Color("efe3d0"))
		pill.add_theme_stylebox_override("panel", UI.stylebox(bg, 14, 0, bg, 6))
		var label := UI.label(("✓ " if done else "") + str(STAGES[i]), 13)
		label.add_theme_color_override("font_color", Color.WHITE if (done or current) else Color("8a7a66"))
		pill.add_child(label)
		row.add_child(pill)
	return row
