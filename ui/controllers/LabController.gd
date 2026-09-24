extends Node

signal status_changed(message: String)
signal refresh_requested

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")
const APP_TEXT := UI.APP_TEXT
const APP_MUTED := UI.APP_MUTED
const APP_CYAN := UI.APP_CYAN
const APP_AMBER := UI.APP_AMBER
const APP_GREEN := UI.APP_GREEN
const APP_RED := UI.APP_RED

var lab_screen: Control
var status_label: Label

var tech_label: Label
var projects_label: Label
var patents_label: Label
var rd_name: LineEdit
var rd_segment: OptionButton
var rd_application: OptionButton
var rd_approach: OptionButton
var rd_supplier: OptionButton
var rd_negotiation: OptionButton
var rd_contract_term: OptionButton
var rd_exclusivity: OptionButton
var rd_ip_term: OptionButton
var rd_volume_term: OptionButton
var rd_supplier_label: Label
var supplier_contract_select: OptionButton
var supplier_contract_label: Label
var supplier_contract_renegotiate_button: Button
var supplier_contract_break_button: Button
var rd_focus: OptionButton
var rd_budget: SpinBox
var research_overview_label: Label
var research_budget: SpinBox
var research_alloc_controls: Dictionary = {}
var concept_axis: OptionButton
var concept_budget: SpinBox
var concept_ambition: OptionButton
var concept_status_label: Label
var cpu_generation_select: OptionButton
var cpu_generation_summary_label: Label
var active_cpu_generation_plan: Dictionary = {}
var rd_cores: HSlider
var rd_frequency: HSlider
var rd_cache: HSlider
var rd_node: OptionButton
var rd_tdp: HSlider
var lab_chip: Control
var lab_profile_label: Label
var lab_summary_label: Label
var lab_unit_cost_value: Label
var lab_dev_time_value: Label
var lab_fit_value: Label
var lab_tradeoff_summary_label: Label
var lab_delta_summary_label: Label
var lab_reference_design: Dictionary = {}
var lab_reference_name := "Design équilibré"
var lab_technical_detail_label: Label
var lab_warning_label: Label
var lab_guidance_bars: Dictionary = {}
var lab_guidance_labels: Dictionary = {}
var lab_team_guidance_label: Label
var lab_remediation_select: OptionButton
var lab_remediation_summary_label: Label
var lab_remediation_accept_button: Button
var lab_remediation_options: Array = []
var active_cpu_remediation: Dictionary = {}
var cpu_metric_bars: Dictionary = {}
var cpu_metric_labels: Dictionary = {}

func configure(screen: Control, shared_status_label: Label) -> void:
	lab_screen = screen
	status_label = shared_status_label
	if lab_screen == null:
		return
	var controls_value = lab_screen.call("get_control_map")
	if typeof(controls_value) != TYPE_DICTIONARY:
		return
	var controls: Dictionary = controls_value
	for field_value in controls.keys():
		if field_value in ["lab_layout_grid", "lab_stats_grid", "lab_reference_design", "lab_reference_name"]:
			continue
		set(str(field_value), controls[field_value])
	refresh()
	_refresh_supplier_options()
	_refresh_supplier_contracts()
	_refresh_cpu_node_options()
	_refresh_cpu_preview()

func refresh() -> void:
	_refresh_research()

func refresh_generation_plans() -> void:
	_refresh_generation_plan_options()

func refresh_supplier_context() -> void:
	_refresh_supplier_options()
	_refresh_supplier_contracts()
	_refresh_cpu_preview()

func _refresh_all() -> void:
	refresh_requested.emit()

func _money(value: int) -> String:
	return UI.money(value)

func _meta(option: OptionButton) -> String:
	return UI.option_meta(option)

func _select_meta(option: OptionButton, wanted: String) -> void:
	UI.select_meta(option, wanted)


func handle_action(action: String, payload: Variant = null):
	match action:
		"preview":
			_refresh_cpu_preview()
		"sourcing_changed":
			_on_sourcing_approach_changed()
		"supplier_contract_selected":
			_refresh_selected_supplier_contract()
		"renegotiate_supplier_contract":
			_renegotiate_selected_supplier_contract()
		"break_supplier_contract":
			_break_selected_supplier_contract()
		"apply_research_plan":
			_apply_research_plan()
		"start_concept":
			_start_cpu_concept_program()
		"request_generation_plans":
			_request_cpu_generation_plans()
		"generation_selected":
			_refresh_generation_plan_summary()
		"apply_generation_plan":
			_apply_selected_generation_plan()
		"preset":
			_apply_cpu_preset(str(payload))
		"remediation_selected":
			_refresh_cpu_remediation_summary()
		"accept_remediation":
			_accept_cpu_remediation()
		"start_project":
			_start_project()
		"file_patent":
			_file_patent()
		"toggle_patent_license":
			_toggle_patent_license()

func _current_cpu_design() -> Dictionary:
	if rd_cores == null or rd_frequency == null or rd_cache == null or rd_node == null or rd_tdp == null or rd_node.item_count == 0:
		return CPU_DESIGN.default_design()
	return CPU_DESIGN.normalize({
		"cores": int(rd_cores.value),
		"frequency_ghz": float(rd_frequency.value) / 1000.0,
		"cache_mb": float(rd_cache.value) / 1024.0,
		"node_nm": int(rd_node.get_item_metadata(rd_node.selected)),
		"tdp_w": int(rd_tdp.value)
	})

func _request_cpu_generation_plans():
	if not CompanyManager.created:
		status_label.text = "Créez d'abord votre entreprise."
		return
	active_cpu_generation_plan = {}
	var proposals := ResearchManager.prepare_cpu_generation_proposals(
		_meta(rd_segment), _meta(rd_approach), _meta(rd_focus), int(rd_budget.value), _current_cpu_design()
	)
	_refresh_generation_plan_options()
	if proposals.size() == 3:
		status_label.text = "Camille a préparé trois pistes pour la prochaine génération CPU."
	else:
		status_label.text = "L'équipe n'a pas pu préparer les plans."

func _refresh_generation_plan_options():
	if cpu_generation_select == null:
		return
	var previous_id := ""
	if cpu_generation_select.item_count > 0:
		previous_id = str(cpu_generation_select.get_item_metadata(cpu_generation_select.selected))
	cpu_generation_select.clear()
	for proposal in ResearchManager.get_cpu_generation_proposals():
		var marker := "★ " if bool(proposal.get("recommended", false)) else ""
		cpu_generation_select.add_item("%s%s — %s" % [marker, str(proposal.get("tag", "PLAN")), str(proposal.get("title", "Architecture"))])
		cpu_generation_select.set_item_metadata(cpu_generation_select.item_count - 1, str(proposal.get("id", "")))
	if previous_id != "":
		_select_meta(cpu_generation_select, previous_id)
	elif cpu_generation_select.item_count > 0:
		cpu_generation_select.select(0)
	_refresh_generation_plan_summary()

func _selected_cpu_generation_plan() -> Dictionary:
	if cpu_generation_select == null or cpu_generation_select.item_count == 0:
		return {}
	return ResearchManager.get_cpu_generation_proposal(str(cpu_generation_select.get_item_metadata(cpu_generation_select.selected)))

func _refresh_generation_plan_summary():
	if cpu_generation_summary_label == null:
		return
	var proposal := _selected_cpu_generation_plan()
	if proposal.is_empty():
		cpu_generation_summary_label.text = "Aucun plan préparé. Définissez le brief puis lancez la réunion d'architecture."
		cpu_generation_summary_label.add_theme_color_override("font_color", APP_MUTED)
		return
	var design: Dictionary = proposal.get("design", {})
	var deltas: Dictionary = proposal.get("metric_deltas", {})
	var strengths: Array = proposal.get("strengths", [])
	var risks: Array = proposal.get("risks", [])
	var recommendation_prefix := "★ RECOMMANDÉ PAR CAMILLE\n" if bool(proposal.get("recommended", false)) else ""
	cpu_generation_summary_label.text = "%sPLAN %s — %s G%d\n%s\n\n%d cœur(s) • %s • %s • %s • %d W\n~%d mois • %s € • compétitif ~%.1f ans • %d modèles\nRisque %.0f/100 • confiance plan %.0f/100 • confiance R&D %.0f/100 • confiance dev %.0f/100 • terrain %.0f/100 • cible %.0f/100\nGains estimés : performance %s • efficacité %s • fiabilité %s\nForces : %s\nRisques : %s\n\n%s" % [
		recommendation_prefix, str(proposal.get("tag", "PLAN")), str(proposal.get("title", "Architecture")), int(proposal.get("generation_index", 1)),
		str(proposal.get("promise", "")),
		int(design.get("cores", 0)), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design), CPU_DESIGN.node_label(int(design.get("node_nm", 10000))), int(design.get("tdp_w", 0)),
		int(proposal.get("estimated_months", 0)), _money(int(proposal.get("program_cost", 0))), float(proposal.get("competitive_months", 0)) / 12.0, int(proposal.get("potential_models", 0)),
		float(proposal.get("risk", 0.0)), float(proposal.get("confidence", 0.0)), float(proposal.get("research_confidence", 50.0)), float(proposal.get("development_confidence", 50.0)), float(proposal.get("field_experience", 0.0)), float(proposal.get("target_fit", 0.0)),
		_signed_score(float(deltas.get("performance", 0.0))), _signed_score(float(deltas.get("efficiency", 0.0))), _signed_score(float(deltas.get("reliability", 0.0))),
		" • ".join(strengths), " • ".join(risks), str(proposal.get("recommendation", ""))
	]
	cpu_generation_summary_label.add_theme_color_override("font_color", APP_GREEN if bool(proposal.get("recommended", false)) else APP_TEXT)

func _signed_score(value: float) -> String:
	return "+%.0f" % value if value >= 0.0 else "%.0f" % value

func _apply_selected_generation_plan():
	var proposal := _selected_cpu_generation_plan()
	if proposal.is_empty():
		status_label.text = "Préparez d'abord les plans de génération."
		return
	active_cpu_generation_plan = proposal.duplicate(true)
	active_cpu_remediation = {}
	_set_cpu_design_controls(proposal.get("design", {}), "Plan %s" % str(proposal.get("title", "sélectionné")))
	status_label.text = "Plan %s appliqué. Vous pouvez encore ajuster chaque paramètre." % str(proposal.get("title", "sélectionné"))

func _refresh_cpu_node_options():
	if rd_node == null:
		return
	var current_node := int(CPU_DESIGN.default_design().node_nm)
	if rd_node.item_count > 0 and rd_node.selected >= 0:
		current_node = int(rd_node.get_item_metadata(rd_node.selected))
	var mastery := float(ResearchManager.technologies.get("manufacturing", 0.0))
	var miniaturization := ResearchManager.get_cpu_capability("MINIATURIZATION")
	var nodes := CPU_DESIGN.available_nodes_for_capabilities(mastery, miniaturization)
	if not nodes.has(current_node):
		nodes.append(current_node)
	rd_node.clear()
	for node_value in nodes:
		var node_nm := int(node_value)
		rd_node.add_item(CPU_DESIGN.node_label(node_nm))
		rd_node.set_item_metadata(rd_node.item_count - 1, node_nm)
	_select_meta(rd_node, str(current_node))
	if rd_node.selected < 0 and rd_node.item_count > 0:
		rd_node.select(0)

func _ensure_cpu_node_option(node_nm: int):
	if rd_node == null:
		return
	for index in range(rd_node.item_count):
		if int(rd_node.get_item_metadata(index)) == node_nm:
			return
	rd_node.add_item(CPU_DESIGN.node_label(node_nm))
	rd_node.set_item_metadata(rd_node.item_count - 1, node_nm)

func _refresh_cpu_control_limits(design: Dictionary):
	if rd_cores == null or rd_frequency == null or rd_cache == null or rd_tdp == null:
		return
	var normalized := CPU_DESIGN.normalize(design)
	var node: Dictionary = CPU_DESIGN.node_profile(int(normalized.node_nm))
	var reference_mhz := maxf(float(node.get("reference_mhz", 1.0)), 0.1)
	var reference_cores := maxf(float(node.get("core_reference", 1.0)), 1.0)
	var reference_cache_kb := maxf(float(node.get("cache_reference_kb", 0.0)), 0.0)
	var base_power := maxf(float(node.get("base_power", 2.0)), 1.0)
	rd_cores.max_value = maxf(maxf(4.0, reference_cores * 2.0), float(normalized.cores))
	rd_frequency.max_value = maxf(maxf(10.0, reference_mhz * 2.8), float(normalized.frequency_ghz) * 1000.0)
	rd_cache.max_value = maxf(maxf(32.0, reference_cache_kb * 3.0), float(normalized.cache_mb) * 1024.0)
	rd_tdp.max_value = maxf(maxf(25.0, base_power * 3.5), float(normalized.tdp_w))

func _set_cpu_design_controls(input: Dictionary, reference_name: String = "Référence"):
	var design := CPU_DESIGN.normalize(input)
	_refresh_cpu_control_limits(design)
	lab_reference_design = design.duplicate(true)
	lab_reference_name = reference_name
	rd_cores.value = int(design.cores)
	rd_frequency.value = float(design.frequency_ghz) * 1000.0
	rd_cache.value = float(design.cache_mb) * 1024.0
	_ensure_cpu_node_option(int(design.node_nm))
	_select_meta(rd_node, str(design.node_nm))
	rd_tdp.value = int(design.tdp_w)
	_refresh_cpu_preview()

func _apply_cpu_preset(key: String):
	active_cpu_generation_plan = {}
	active_cpu_remediation = {}
	_set_cpu_design_controls(CPU_DESIGN.preset(key), "Préréglage %s" % key.to_lower())
	status_label.text = "Préréglage %s appliqué. Vous pouvez encore tout ajuster." % key.to_lower()

func _refresh_cpu_preview():
	if lab_profile_label == null or lab_chip == null:
		return
	var design := _current_cpu_design()
	if not active_cpu_remediation.is_empty() and CPU_DESIGN.normalize(active_cpu_remediation.get("design", {})) != design:
		active_cpu_remediation = {}
	_refresh_cpu_control_limits(design)
	var evaluation := CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities())
	if not active_cpu_remediation.is_empty():
		evaluation = ResearchManager.cpu_remediation_preview(design, active_cpu_remediation)
	var segment := _meta(rd_segment) if rd_segment != null else MarketManager.default_segment()
	var fit := CPU_DESIGN.segment_fit(evaluation, segment)
	var application_key := _meta(rd_application) if rd_application != null else "GENERAL"
	var application_assessment := CPU_DESIGN.application_assessment(evaluation, application_key)
	var approach_key := _meta(rd_approach) if rd_approach != null else "INTERNAL"
	var approach_data: Dictionary = GameData.approach_data(approach_key)
	var sourcing: Dictionary = _selected_supplier_quote()
	if sourcing.is_empty():
		sourcing = GameData.sourcing_profile(approach_key)
	var effective_speed := float(approach_data.speed) * float(sourcing.get("speed_factor", 1.0))
	var base_months := maxi(1, int(ceil(float(evaluation.estimated_months) / maxf(effective_speed, 0.10))))
	var extra_months := int(active_cpu_remediation.get("extra_months", 0))
	var months := base_months + extra_months
	var monthly_budget := int(rd_budget.value) if rd_budget != null else 45000
	var estimated_program_cost := int(float(months * monthly_budget) * float(approach_data.cost) * float(sourcing.get("monthly_cost_factor", 1.0))) + int(active_cpu_remediation.get("upfront_cost", 0)) + int(sourcing.get("setup_cost", 0))
	var risk := float(evaluation.risk)
	var risk_label := "faible"
	if risk >= 60.0:
		risk_label = "élevé"
	elif risk >= 40.0:
		risk_label = "modéré"
	var decision_axes := CPU_DESIGN.decision_axes(evaluation, months)
	var reference_design := lab_reference_design if not lab_reference_design.is_empty() else CPU_DESIGN.default_design()
	var reference_evaluation := CPU_DESIGN.evaluate(reference_design, ResearchManager.get_cpu_capabilities())
	var reference_months := maxi(1, int(ceil(float(reference_evaluation.estimated_months) / maxf(effective_speed, 0.10))))
	var reference_axes := CPU_DESIGN.decision_axes(reference_evaluation, reference_months)
	var axis_delta := CPU_DESIGN.decision_axis_delta(decision_axes, reference_axes)
	var focus_key := _meta(rd_focus) if rd_focus != null else "BALANCED"
	var guidance_confidence := clampf(
		ResearchManager.development_confidence() * 0.55
		+ ResearchManager.research_confidence_for_focus(focus_key) * 0.45,
		20.0,
		96.0
	)
	if not active_cpu_generation_plan.is_empty():
		guidance_confidence = clampf(float(active_cpu_generation_plan.get("confidence", guidance_confidence)), 20.0, 96.0)
	var guidance := CPU_DESIGN.guidance_report(design, reference_design, guidance_confidence, ResearchManager.get_cpu_capabilities())

	lab_profile_label.text = str(evaluation.profile)
	var remediation_tag := ""
	if not active_cpu_remediation.is_empty():
		remediation_tag = " • solution équipe +%d mois" % extra_months
	var application_gaps: Array = application_assessment.get("gaps", [])
	var application_gap_text := ""
	if not application_gaps.is_empty():
		application_gap_text = " • à améliorer : %s" % ", ".join(application_gaps)
	var royalty_text := "aucune royalty"
	if float(sourcing.get("royalty_rate", 0.0)) > 0.0:
		royalty_text = "%.1f%% du CA" % (float(sourcing.get("royalty_rate", 0.0)) * 100.0)
	lab_summary_label.text = "%d cœur(s) • %s • %s • %s • %d W\nProgramme estimé : %s € • risque %s (%.0f/100)%s\nSourcing : %s • dépendance %.0f/100 • IP %.0f/100 • personnalisation %.0f/100 • %s\nUsage %s : %.0f/100 — %s%s" % [
		int(design.cores), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design), CPU_DESIGN.node_label(int(design.node_nm)), int(design.tdp_w),
		_money(estimated_program_cost), risk_label, risk, remediation_tag,
		str(sourcing.get("label", "Interne")), float(sourcing.get("dependency", 0.0)), float(sourcing.get("ip_ownership", 100.0)),
		float(sourcing.get("customization", 100.0)), royalty_text,
		str(application_assessment.get("label", "Polyvalent")), float(application_assessment.get("fit", 0.0)),
		str(application_assessment.get("summary", "")), application_gap_text
	]
	var projected_unit_cost := int(round(float(evaluation.unit_cost) * float(sourcing.get("unit_cost_factor", 1.0))))
	lab_unit_cost_value.text = "%s €" % _money(projected_unit_cost)
	if rd_supplier_label != null:
		if approach_key == "INTERNAL":
			rd_supplier_label.text = "Équipe interne : aucune dépendance fournisseur, IP et personnalisation maximales."
		else:
			var acceptance_text := "OFFRE ACCEPTABLE"
			if not bool(sourcing.get("accepted", false)):
				acceptance_text = "CONTRE-PROPOSITION : %s" % str(sourcing.get("counter_text", "conditions à revoir"))
			var volume_commitment := int(sourcing.get("guaranteed_units", 0))
			var volume_text := "aucun volume garanti" if volume_commitment <= 0 else "%s unités garanties" % _money(volume_commitment)
			var supplier_public_action := str(sourcing.get("supplier_public_action", "Conditions commerciales stables."))
			var rival_load := int(sourcing.get("supplier_rival_load", 0))
			var public_rivals: Array = sourcing.get("supplier_public_rivals", [])
			var rivalry_text := "%d projet(s) concurrent(s) identifié(s)" % rival_load
			if not public_rivals.is_empty():
				rivalry_text += " — %s" % ", ".join(public_rivals)
			rd_supplier_label.text = "%s • %s\nQualité %.0f/100 • fiabilité %.0f/100 • confiance %.0f/100 • relation %.0f/100\nCapacité : %d/%d créneau(x) libre(s) • %d charge client anonyme • %s\nContrat : %s • %s • %s • %s\nAccès %s € • royalty %.1f%% • coût unitaire x%.2f • rupture %s €\nMouvement partenaire : %s\n%s — score d'acceptation %.0f/100" % [
				str(sourcing.get("supplier_name", "Partenaire")), str(sourcing.get("specialty", "Technologie")),
				float(sourcing.get("supplier_quality", 0.0)), float(sourcing.get("supplier_reliability", 0.0)),
				float(sourcing.get("supplier_trust", 0.0)), float(sourcing.get("supplier_relationship", 0.0)),
				int(sourcing.get("available_capacity_slots", 0)), int(sourcing.get("supplier_capacity_slots", 0)),
				int(sourcing.get("supplier_external_load", 0)), rivalry_text,
				str(sourcing.get("contract_term_label", "")), str(sourcing.get("exclusivity_label", "")),
				str(sourcing.get("ip_term_label", "")), volume_text,
				_money(int(sourcing.get("setup_cost", 0))), float(sourcing.get("royalty_rate", 0.0)) * 100.0,
				float(sourcing.get("unit_cost_factor", 1.0)), _money(int(sourcing.get("termination_penalty", 0))),
				supplier_public_action,
				acceptance_text, float(sourcing.get("acceptance_score", 0.0))
			]
	lab_dev_time_value.text = "~%d mois" % months
	lab_fit_value.text = "%.0f / 100" % fit
	lab_warning_label.text = str(evaluation.tradeoff)
	lab_warning_label.add_theme_color_override("font_color", APP_RED if risk >= 60.0 else (APP_AMBER if risk >= 40.0 else APP_GREEN))

	lab_tradeoff_summary_label.text = CPU_DESIGN.decision_summary(decision_axes)
	lab_delta_summary_label.text = "%s — %s" % [lab_reference_name, CPU_DESIGN.decision_delta_summary(axis_delta)]
	for metric_key in ["performance", "efficiency", "cost_control", "reliability", "delivery"]:
		var score := float(decision_axes.get(metric_key, 0.0))
		if cpu_metric_bars.has(metric_key):
			var bar: ProgressBar = cpu_metric_bars[metric_key]
			bar.value = score
		if cpu_metric_labels.has(metric_key):
			var metric_label: Label = cpu_metric_labels[metric_key]
			var delta := float(axis_delta.get(metric_key, 0.0))
			var delta_text := ""
			if absf(delta) >= 0.5:
				delta_text = "  (%s%.0f)" % ["+" if delta > 0.0 else "", delta]
			metric_label.text = "%.0f%s" % [score, delta_text]
			metric_label.add_theme_color_override("font_color", APP_GREEN if delta > 0.5 else (APP_RED if delta < -0.5 else APP_TEXT))

	var thermal_text := "enveloppe cohérente"
	if float(evaluation.power_deficit) > 0.05:
		thermal_text = "déficit électrique/thermique %.1f W" % float(evaluation.power_deficit)
	lab_technical_detail_label.text = "Innovation %.0f • durabilité %.0f • complexité %.0f/100 • risque %.0f/100\nBesoin estimé ~%.1f W • %s • coût unitaire %s €" % [
		float(evaluation.innovation), float(evaluation.sustainability), float(evaluation.complexity), risk,
		float(evaluation.required_tdp), thermal_text, _money(int(evaluation.unit_cost))
	]

	_refresh_cpu_guidance(guidance, design)
	_refresh_cpu_remediation_options(design)

	if lab_chip.has_method("set_design"):
		lab_chip.call("set_design", design, 16.0, false)

func _refresh_cpu_guidance(guidance: Dictionary, design: Dictionary):
	var ranges: Dictionary = guidance.get("ranges", {})
	var states: Dictionary = guidance.get("states", {})
	for key in ["cores", "frequency_ghz", "cache_mb", "tdp_w"]:
		if not ranges.has(key):
			continue
		var zone: Dictionary = ranges[key]
		var current := float(design.get(key, 0.0))
		if lab_guidance_bars.has(key):
			var bar: Control = lab_guidance_bars[key]
			if bar.has_method("configure"):
				bar.call(
					"configure",
					float(zone.get("min", 0.0)),
					float(zone.get("max", 1.0)),
					float(zone.get("ambitious_min", 0.0)),
					float(zone.get("recommended_min", 0.0)),
					float(zone.get("recommended_max", 1.0)),
					float(zone.get("ambitious_max", 1.0)),
					current
				)
		if lab_guidance_labels.has(key):
			var label: Label = lab_guidance_labels[key]
			var state := str(states.get(key, "RECOMMENDED"))
			var state_text := "recommandé"
			var state_color := APP_GREEN
			if state == "AMBITIOUS":
				state_text = "ambitieux"
				state_color = APP_AMBER
			elif state == "OUTSIDE":
				state_text = "hors zone maîtrisée"
				state_color = APP_RED
			label.text = "Équipe : %s à %s • votre choix : %s" % [
				_format_guidance_value(key, float(zone.get("recommended_min", 0.0))),
				_format_guidance_value(key, float(zone.get("recommended_max", 0.0))),
				state_text
			]
			label.add_theme_color_override("font_color", state_color)

	if lab_team_guidance_label != null:
		var overall := str(guidance.get("overall", "RECOMMENDED"))
		var color := APP_GREEN
		if overall == "AMBITIOUS":
			color = APP_AMBER
		elif overall == "OUTSIDE":
			color = APP_RED
		var detail := str(guidance.get("details", ""))
		var advice := ResearchManager.cpu_technical_advice(design)
		var concept_hint := ""
		if not advice.is_empty():
			concept_hint = "\nPiste R&D Concept : %s" % str(advice[0])
		lab_team_guidance_label.text = "%s\n%s : %.0f%%.%s%s" % [
			str(guidance.get("summary", "")),
			str(guidance.get("confidence_text", "Confiance")),
			float(guidance.get("confidence", 0.0)),
			(" " + detail) if detail != "" else "",
			concept_hint
		]
		if not active_cpu_remediation.is_empty():
			lab_team_guidance_label.text += "\n✓ Solution intégrée : %s (+%d mois, %s € de coût technique initial)." % [
				str(active_cpu_remediation.get("title", "solution technique")),
				int(active_cpu_remediation.get("extra_months", 0)),
				_money(int(active_cpu_remediation.get("upfront_cost", 0)))
			]
		lab_team_guidance_label.add_theme_color_override("font_color", color)

func _refresh_cpu_remediation_options(design: Dictionary):
	if lab_remediation_select == null:
		return
	var previous_id := ""
	if lab_remediation_select.item_count > 0 and lab_remediation_select.selected >= 0:
		previous_id = str(lab_remediation_select.get_item_metadata(lab_remediation_select.selected))
	lab_remediation_options = ResearchManager.cpu_remediation_options(
		design,
		int(rd_budget.value) if rd_budget != null else 45000,
		_meta(rd_focus) if rd_focus != null else "BALANCED"
	)
	if not active_cpu_remediation.is_empty():
		for refreshed_value in lab_remediation_options:
			var refreshed: Dictionary = refreshed_value
			if str(refreshed.get("id", "")) == str(active_cpu_remediation.get("id", "")):
				active_cpu_remediation = refreshed.duplicate(true)
				break
	lab_remediation_select.clear()
	if lab_remediation_options.is_empty():
		lab_remediation_select.add_item("Aucune solution spéciale nécessaire")
		lab_remediation_select.set_item_metadata(0, "")
		lab_remediation_select.select(0)
		if lab_remediation_accept_button != null:
			lab_remediation_accept_button.disabled = true
		_refresh_cpu_remediation_summary()
		return
	for option_value in lab_remediation_options:
		var option: Dictionary = option_value
		var marker := "★ " if bool(option.get("recommended", false)) else ""
		lab_remediation_select.add_item("%s%s" % [marker, str(option.get("title", "Solution technique"))])
		lab_remediation_select.set_item_metadata(lab_remediation_select.item_count - 1, str(option.get("id", "")))
	if not active_cpu_remediation.is_empty():
		previous_id = str(active_cpu_remediation.get("id", previous_id))
	if previous_id != "":
		_select_meta(lab_remediation_select, previous_id)
	if lab_remediation_select.selected < 0:
		for index in range(lab_remediation_options.size()):
			if bool((lab_remediation_options[index] as Dictionary).get("recommended", false)):
				lab_remediation_select.select(index)
				break
		if lab_remediation_select.selected < 0:
			lab_remediation_select.select(0)
	if lab_remediation_accept_button != null:
		lab_remediation_accept_button.disabled = false
	_refresh_cpu_remediation_summary()

func _selected_cpu_remediation() -> Dictionary:
	if lab_remediation_select == null or lab_remediation_select.item_count == 0:
		return {}
	var selected_id := str(lab_remediation_select.get_item_metadata(lab_remediation_select.selected))
	for option_value in lab_remediation_options:
		var option: Dictionary = option_value
		if str(option.get("id", "")) == selected_id:
			return option.duplicate(true)
	return {}

func _refresh_cpu_remediation_summary():
	if lab_remediation_summary_label == null:
		return
	var option := _selected_cpu_remediation()
	if option.is_empty():
		lab_remediation_summary_label.text = "Aucune intervention spéciale nécessaire pour cette configuration."
		lab_remediation_summary_label.add_theme_color_override("font_color", APP_GREEN)
		return
	var accepted := not active_cpu_remediation.is_empty() and str(active_cpu_remediation.get("id", "")) == str(option.get("id", ""))
	var prefix := "✓ INTÉGRÉ AU PROJET\n" if accepted else ("★ RECOMMANDÉ PAR L'ÉQUIPE\n" if bool(option.get("recommended", false)) else "")
	lab_remediation_summary_label.text = "%s%s\nProblème traité : %s\n+%d mois • coût technique %s € • surcoût total estimé %s €\nConfiance équipe %.0f%%\n%s" % [
		prefix,
		str(option.get("title", "Solution technique")),
		str(option.get("issue_label", "contrainte technique")),
		int(option.get("extra_months", 0)),
		_money(int(option.get("upfront_cost", 0))),
		_money(int(option.get("estimated_extra_cost", 0))),
		float(option.get("confidence", 0.0)),
		str(option.get("expected_effect", ""))
	]
	lab_remediation_summary_label.add_theme_color_override("font_color", APP_GREEN if accepted else (APP_CYAN if bool(option.get("recommended", false)) else APP_TEXT))

func _accept_cpu_remediation():
	var option := _selected_cpu_remediation()
	if option.is_empty():
		active_cpu_remediation = {}
		status_label.text = "Aucune solution technique supplémentaire à intégrer."
		return
	active_cpu_remediation = option.duplicate(true)
	status_label.text = "Solution intégrée : %s. Le développement prendra %d mois supplémentaires." % [
		str(option.get("title", "solution technique")),
		int(option.get("extra_months", 0))
	]
	_refresh_cpu_preview()

func _format_guidance_value(key: String, value: float) -> String:
	match key:
		"cores":
			return "%d cœur(s)" % int(round(value))
		"frequency_ghz":
			var mhz := value * 1000.0
			return "%.1f MHz" % mhz if mhz < 10.0 else "%.0f MHz" % mhz
		"cache_mb":
			var kb := value * 1024.0
			return "aucun cache" if kb < 0.5 else "%d Ko" % int(round(kb))
		"tdp_w":
			return "%d W" % int(round(value))
		_:
			return "%.1f" % value

func _refresh_supplier_options():
	if rd_supplier == null or rd_approach == null:
		return
	var approach := _meta(rd_approach)
	var previous := _meta(rd_supplier) if rd_supplier.item_count > 0 else ""
	rd_supplier.clear()
	var contract_controls := [rd_contract_term, rd_exclusivity, rd_ip_term, rd_volume_term]
	if approach == "INTERNAL":
		rd_supplier.add_item("Équipe interne — aucun fournisseur")
		rd_supplier.set_item_metadata(0, "")
		rd_supplier.disabled = true
		if rd_negotiation != null:
			rd_negotiation.disabled = true
		for control_value in contract_controls:
			var control: OptionButton = control_value
			if control != null:
				control.disabled = true
	else:
		rd_supplier.disabled = false
		if rd_negotiation != null:
			rd_negotiation.disabled = false
		for control_value in contract_controls:
			var control: OptionButton = control_value
			if control != null:
				control.disabled = false
		for supplier_id_value in SupplierManager.supplier_keys_for_mode(approach):
			var supplier_id := str(supplier_id_value)
			var supplier := SupplierManager.get_supplier(supplier_id)
			rd_supplier.add_item("%s — %s" % [str(supplier.get("name", supplier_id)), str(supplier.get("specialty", "Technologie"))])
			rd_supplier.set_item_metadata(rd_supplier.item_count - 1, supplier_id)
		if previous != "":
			_select_meta(rd_supplier, previous)
		if rd_supplier.selected < 0 and rd_supplier.item_count > 0:
			_select_meta(rd_supplier, SupplierManager.recommended_supplier(approach))
	if rd_supplier.item_count > 0 and rd_supplier.selected < 0:
		rd_supplier.select(0)

func _on_sourcing_approach_changed():
	_refresh_supplier_options()
	_refresh_cpu_preview()

func _selected_supplier_quote() -> Dictionary:
	var approach := _meta(rd_approach) if rd_approach != null else "INTERNAL"
	var supplier_id := _meta(rd_supplier) if rd_supplier != null and rd_supplier.item_count > 0 else ""
	var negotiation := _meta(rd_negotiation) if rd_negotiation != null and rd_negotiation.item_count > 0 else "BALANCED"
	if approach == "INTERNAL":
		return SupplierManager.quote(approach, supplier_id, negotiation)
	var term_key := _meta(rd_contract_term) if rd_contract_term != null and rd_contract_term.item_count > 0 else "STANDARD"
	var exclusivity := _meta(rd_exclusivity) if rd_exclusivity != null and rd_exclusivity.item_count > 0 else "NONE"
	var ip_term := _meta(rd_ip_term) if rd_ip_term != null and rd_ip_term.item_count > 0 else "SHARED"
	var volume_term := _meta(rd_volume_term) if rd_volume_term != null and rd_volume_term.item_count > 0 else "NONE"
	return SupplierManager.contract_quote(approach, supplier_id, negotiation, term_key, exclusivity, ip_term, volume_term)

func _refresh_supplier_contracts():
	if supplier_contract_select == null:
		return
	var previous := _meta(supplier_contract_select) if supplier_contract_select.item_count > 0 else ""
	supplier_contract_select.clear()
	for contract_value in SupplierManager.active_contracts():
		var contract: Dictionary = contract_value
		supplier_contract_select.add_item("%s — %s — %s" % [
			str(contract.get("id", "")),
			str(contract.get("supplier_name", "Partenaire")),
			"R&D" if str(contract.get("status", "")) == "RND" else "%d mois" % int(contract.get("remaining_months", 0))
		])
		supplier_contract_select.set_item_metadata(supplier_contract_select.item_count - 1, str(contract.get("id", "")))
	if previous != "":
		_select_meta(supplier_contract_select, previous)
	if supplier_contract_select.selected < 0 and supplier_contract_select.item_count > 0:
		supplier_contract_select.select(0)
	_refresh_selected_supplier_contract()

func _refresh_selected_supplier_contract():
	if supplier_contract_label == null:
		return
	if supplier_contract_select == null or supplier_contract_select.item_count == 0:
		supplier_contract_label.text = "Aucun contrat fournisseur actif."
		if supplier_contract_renegotiate_button != null:
			supplier_contract_renegotiate_button.disabled = true
		if supplier_contract_break_button != null:
			supplier_contract_break_button.disabled = true
		return
	var contract := SupplierManager.get_contract(_meta(supplier_contract_select))
	if contract.is_empty():
		return
	var status := str(contract.get("status", "RND"))
	var status_text := "R&D en cours" if status == "RND" else "Commercial — %d mois restants" % int(contract.get("remaining_months", 0))
	var guaranteed := int(contract.get("guaranteed_units", 0))
	var volume_text := "aucun volume garanti"
	if guaranteed > 0:
		volume_text = "%s / %s unités réalisées" % [_money(int(contract.get("units_delivered", 0))), _money(guaranteed)]
	supplier_contract_label.text = "%s • %s\n%s • %s • %s • %s\nRoyalty %.1f%% • IP entreprise %.0f%% • %s • rupture %s €" % [
		str(contract.get("supplier_name", "Partenaire")), status_text,
		str(contract.get("contract_term_label", "")), str(contract.get("exclusivity_label", "")),
		str(contract.get("ip_term_label", "")), str(contract.get("volume_term_label", "")),
		float(contract.get("royalty_rate", 0.0)) * 100.0, float(contract.get("ip_ownership", 0.0)),
		volume_text, _money(int(contract.get("termination_penalty", 0)))
	]
	if supplier_contract_renegotiate_button != null:
		supplier_contract_renegotiate_button.disabled = false
	if supplier_contract_break_button != null:
		supplier_contract_break_button.disabled = status != "COMMERCIAL"

func _renegotiate_selected_supplier_contract():
	if supplier_contract_select == null or supplier_contract_select.item_count == 0:
		return
	var contract_id := _meta(supplier_contract_select)
	var negotiation := _meta(rd_negotiation) if rd_negotiation != null else "BALANCED"
	var term_key := _meta(rd_contract_term) if rd_contract_term != null else "STANDARD"
	var exclusivity := _meta(rd_exclusivity) if rd_exclusivity != null else "NONE"
	var ip_term := _meta(rd_ip_term) if rd_ip_term != null else "SHARED"
	var volume_term := _meta(rd_volume_term) if rd_volume_term != null else "NONE"
	var result := SupplierManager.renegotiate_contract(contract_id, negotiation, term_key, exclusivity, ip_term, volume_term)
	if result.is_empty():
		status_label.text = "Renégociation impossible."
	elif bool(result.get("accepted", false)):
		status_label.text = "Contrat %s renégocié avec %s." % [contract_id, str(result.get("supplier_name", "le partenaire"))]
	else:
		status_label.text = "Contre-proposition : %s" % str(result.get("counter_text", "conditions refusées"))
	_refresh_all()

func _break_selected_supplier_contract():
	if supplier_contract_select == null or supplier_contract_select.item_count == 0:
		return
	var contract_id := _meta(supplier_contract_select)
	var contract := SupplierManager.get_contract(contract_id)
	if SupplierManager.break_contract(contract_id):
		status_label.text = "Contrat rompu. Pénalité payée : %s €." % _money(int(contract.get("termination_penalty", 0)))
	else:
		status_label.text = "Rupture impossible : contrat encore en R&D ou trésorerie insuffisante."
	_refresh_all()

func _refresh_segment_options(option: OptionButton, preferred: String = ""):
	if option == null:
		return
	var current := preferred
	if current == "" and option.item_count > 0:
		current = _meta(option)
	option.clear()
	for segment_value in MarketManager.available_segment_keys():
		var segment := str(segment_value)
		option.add_item(MarketManager.segment_label(segment))
		option.set_item_metadata(option.item_count - 1, segment)
	if current != "":
		var normalized := MarketManager.normalize_segment(current)
		_select_meta(option, normalized)
	if option.selected < 0 and option.item_count > 0:
		_select_meta(option, MarketManager.default_segment())

func _apply_research_plan():
	var allocations := {}
	for research_key in ResearchManager.get_cpu_research_domain_keys():
		var key := str(research_key)
		allocations[key] = int((research_alloc_controls[key] as SpinBox).value)
	if not ResearchManager.set_cpu_research_allocations(allocations):
		status_label.text = "Répartition impossible : vous avez affecté plus de chercheurs que l'effectif R&D disponible."
		_refresh_research()
		return
	ResearchManager.set_continuous_research_budget(int(research_budget.value))
	status_label.text = "Recherche mise à jour : %d chercheur(s) réparti(s) sur les pistes CPU. L’équipe Développement reste indépendante." % ResearchManager.get_total_cpu_research_allocation()
	_refresh_all()

func _start_cpu_concept_program():
	if concept_axis == null or concept_axis.item_count == 0:
		return
	var axis := str(concept_axis.get_item_metadata(concept_axis.selected))
	var ambition := int(concept_ambition.get_item_metadata(concept_ambition.selected)) if concept_ambition != null else 2
	if ResearchManager.start_cpu_concept_program(axis, int(concept_budget.value), ambition):
		status_label.text = "Programme Concept lancé : %s." % ResearchManager.get_cpu_concept_axis_label(axis)
	else:
		status_label.text = "Impossible de lancer ce programme Concept : vérifiez trésorerie, équipe R&D ou programmes déjà actifs."
	_refresh_all()

func _refresh_research():
	if tech_label == null:
		return
	if rd_segment != null:
		_refresh_segment_options(rd_segment)
	_refresh_cpu_node_options()
	_refresh_cpu_preview()
	_refresh_generation_plan_options()
	_refresh_supplier_contracts()
	var capacity := ResearchManager.get_cpu_research_capacity()
	var allocated := ResearchManager.get_total_cpu_research_allocation()
	var dev_size := ResearchManager.get_development_team_size()
	var active_dev_projects := ResearchManager.get_active_development_project_count()
	if research_overview_label != null:
		research_overview_label.text = "Recherche : %d personne(s) • %d affectée(s) aux pistes CPU\nDéveloppement : %d personne(s) • %d projet(s) actif(s) • charge/capacité %.0f%% • confiance %.0f%%" % [
			capacity, allocated, dev_size, active_dev_projects,
			ResearchManager.development_capacity_factor() * 100.0,
			ResearchManager.development_confidence()
		]
	if research_budget != null:
		research_budget.value = ResearchManager.continuous_research_budget
	for research_key in ResearchManager.get_cpu_research_domain_keys():
		var key := str(research_key)
		var data := ResearchManager.get_cpu_research_domain(key)
		if research_alloc_controls.has(key):
			var allocation: SpinBox = research_alloc_controls[key]
			allocation.max_value = maxf(float(capacity), 0.0)
			allocation.value = int(data.get("allocated", 0))
	var tech_lines: Array[String] = [
		"Recherche CPU :",
		"",
		"Équipe Développement — %d personne(s) • score %.0f/100 • confiance %.0f%% • capacité %.0f%%" % [
			ResearchManager.get_development_team_size(),
			ResearchManager.development_team_score(),
			ResearchManager.development_confidence(),
			ResearchManager.development_capacity_factor() * 100.0
		],
		""
	]
	for research_key in ResearchManager.get_cpu_research_domain_keys():
		var key := str(research_key)
		var data := ResearchManager.get_cpu_research_domain(key)
		tech_lines.append("• %s — connaissance %.1f/100 • expérience %.1f • confiance %.0f%% • %d chercheur(s)" % [
			ResearchManager.get_cpu_research_label(key),
			float(data.get("knowledge", 0.0)), float(data.get("experience", 0.0)),
			ResearchManager.research_confidence(key), int(data.get("allocated", 0))
		])
	tech_lines.append("\nCompétences techniques de l'entreprise :")
	for capability_value in ResearchManager.get_cpu_capability_keys():
		var capability_key := str(capability_value)
		tech_lines.append("• %s : %.1f/100" % [ResearchManager.get_cpu_capability_label(capability_key), ResearchManager.get_cpu_capability(capability_key)])
	tech_lines.append("\nExpérience terrain CPU : fabrication %.1f • thermique %.1f • stabilité %.1f • firmware %.1f" % [
		AfterSalesManager.cpu_field_experience("MANUFACTURING"),
		AfterSalesManager.cpu_field_experience("THERMAL"),
		AfterSalesManager.cpu_field_experience("STABILITY"),
		AfterSalesManager.cpu_field_experience("FIRMWARE")
	])
	tech_lines.append("\nSavoir-faire techniques hérités :")
	for key in ResearchManager.technologies.keys():
		tech_lines.append("• %s : %.1f" % [str(key).capitalize(), float(ResearchManager.technologies[key])])
	tech_label.text = "\n".join(tech_lines)

	if concept_status_label != null:
		var concept_lines: Array[String] = []
		for program in ResearchManager.get_cpu_concept_programs():
			var result: Dictionary = program.get("result", {})
			var result_text := ""
			if not result.is_empty():
				result_text = " • %s" % str(result.get("summary", "technologie transférable"))
			concept_lines.append("• %s — %s — %.0f%% • %d mois • confiance %.0f%%%s" % [
				str(program.get("name", "Concept CPU")), str(program.get("stage", "ÉTUDE")),
				float(program.get("progress", 0.0)), int(program.get("months_spent", 0)),
				float(program.get("confidence", 0.0)), result_text
			])
		concept_status_label.text = "\n".join(concept_lines) if not concept_lines.is_empty() else "Aucun programme Concept actif ou terminé."

	var lines: Array[String] = []
	for project in ResearchManager.projects:
		var phase := "Terminé"
		if str(project.status) == "DEVELOPMENT":
			if int(project.get("remediation_months_remaining", 0)) > 0:
				phase = "Mise au point technique — %d mois restant(s)" % int(project.get("remediation_months_remaining", 0))
			else:
				phase = "%s — %.0f%%" % [GameData.PHASES[int(project.phase_index)], float(project.phase_progress)]
		var design := CPU_DESIGN.normalize(project.get("cpu_design", {}))
		var capability_value = project.get("technical_capabilities_snapshot", {})
		var capability_snapshot: Dictionary = capability_value if typeof(capability_value) == TYPE_DICTIONARY else {}
		var estimate := CPU_DESIGN.evaluate(design, capability_snapshot)
		lines.append("%s — %s — %d mois" % [str(project.name), phase, int(project.months_spent)])
		var development_snapshot: Dictionary = project.get("development_snapshot", {})
		if not development_snapshot.is_empty():
			lines.append("  Équipe Développement au lancement : %d personne(s) • score %.0f/100 • confiance %.0f%%" % [
				int(development_snapshot.get("team_size", 0)),
				float(development_snapshot.get("team_score", 0.0)),
				float(development_snapshot.get("confidence", 0.0))
			])
		lines.append("  %d cœur(s) • %s • %s • %s • %d W • coût cible %s €" % [
			int(design.cores), CPU_DESIGN.format_frequency(design), CPU_DESIGN.format_cache(design), CPU_DESIGN.node_label(int(design.node_nm)), int(design.tdp_w), _money(int(estimate.unit_cost))
		])
		lines.append("  Cible %s • %s • priorité %s" % [
			str(GameData.SEGMENTS.get(str(project.segment), {}).get("label", str(project.segment))),
			str(GameData.APPROACHES[str(project.approach)].label),
			str(project.get("focus_label", "Équilibré"))
		])
		var supplier_contract_id := str(project.get("supplier_contract_id", ""))
		if supplier_contract_id != "":
			var supplier_contract := SupplierManager.get_contract(supplier_contract_id)
			lines.append("  Contrat %s • %s • %s • %s • royalty %.1f%% • IP %.0f%%" % [
				supplier_contract_id,
				str(supplier_contract.get("supplier_name", project.get("supplier_name", "Partenaire"))),
				str(supplier_contract.get("contract_term_label", "")),
				str(supplier_contract.get("exclusivity_label", "")),
				float(supplier_contract.get("royalty_rate", 0.0)) * 100.0,
				float(supplier_contract.get("ip_ownership", 0.0))
			])
		var generation_plan: Dictionary = project.get("generation_plan", {})
		if not generation_plan.is_empty():
			lines.append("  Génération G%d • plan %s — %s%s" % [int(generation_plan.get("generation_index", 1)), str(generation_plan.get("tag", "PLAN")), str(generation_plan.get("title", "Architecture")), " • personnalisé" if bool(generation_plan.get("customized", false)) else ""])
		var remediation: Dictionary = project.get("technical_remediation", {})
		if not remediation.is_empty():
			lines.append("  Solution équipe : %s • +%d mois • coût technique %s € • %s" % [
				str(remediation.get("title", "solution technique")),
				int(project.get("remediation_total_months", remediation.get("extra_months", 0))),
				_money(int(remediation.get("upfront_cost", 0))),
				"validée" if bool(project.get("remediation_transfer_applied", false)) else "en cours"
			])
		if not project.reports.is_empty():
			lines.append("  Camille : %s" % str(project.reports[0].text))
	projects_label.text = "\n\n".join(lines) if not lines.is_empty() else "Aucun projet. Réglez votre première architecture CPU ci-dessus."

	var patent_lines: Array[String] = []
	for candidate in PatentManager.candidates:
		patent_lines.append("Candidat : %s — force %d" % [str(candidate.title), int(candidate.strength)])
	for patent in PatentManager.patents:
		patent_lines.append("Brevet : %s — %s" % [str(patent.title), "licencié" if bool(patent.licensed) else "exclusif"])
	patents_label.text = "\n".join(patent_lines) if not patent_lines.is_empty() else "Aucun brevet. Les architectures les plus innovantes peuvent générer des inventions brevetables."

func _start_project():
	var name := rd_name.text.strip_edges()
	if name.is_empty():
		name = "Nova CPU %d" % (ResearchManager.projects.size() + 1)
	var design := _current_cpu_design()
	var evaluation := CPU_DESIGN.evaluate(design, ResearchManager.get_cpu_capabilities())
	if not active_cpu_remediation.is_empty():
		evaluation = ResearchManager.cpu_remediation_preview(design, active_cpu_remediation)
	var generation_plan := active_cpu_generation_plan.duplicate(true)
	var remediation := active_cpu_remediation.duplicate(true)
	var application_key := _meta(rd_application) if rd_application != null else "GENERAL"
	var supplier_id := _meta(rd_supplier) if rd_supplier != null and rd_supplier.item_count > 0 else ""
	var negotiation := _meta(rd_negotiation) if rd_negotiation != null and rd_negotiation.item_count > 0 else "BALANCED"
	var contract_term := _meta(rd_contract_term) if rd_contract_term != null and rd_contract_term.item_count > 0 else "STANDARD"
	var exclusivity := _meta(rd_exclusivity) if rd_exclusivity != null and rd_exclusivity.item_count > 0 else "NONE"
	var ip_term := _meta(rd_ip_term) if rd_ip_term != null and rd_ip_term.item_count > 0 else "SHARED"
	var volume_term := _meta(rd_volume_term) if rd_volume_term != null and rd_volume_term.item_count > 0 else "NONE"
	var proposal := _selected_supplier_quote()
	if _meta(rd_approach) != "INTERNAL" and not bool(proposal.get("accepted", false)):
		status_label.text = "Le partenaire refuse ces conditions. %s" % str(proposal.get("counter_text", "Ajustez le contrat."))
		return
	if ResearchManager.start_project(name, "CPU", _meta(rd_segment), _meta(rd_approach), _meta(rd_focus), int(rd_budget.value), design, generation_plan, remediation, application_key, supplier_id, negotiation, contract_term, exclusivity, ip_term, volume_term):
		rd_name.text = ""
		var plan_text := " • plan %s" % str(generation_plan.get("title", "")) if not generation_plan.is_empty() else ""
		var remediation_text := " • solution technique +%d mois" % int(remediation.get("extra_months", 0)) if not remediation.is_empty() else ""
		var supplier_text := ""
		if _meta(rd_approach) != "INTERNAL":
			supplier_text = " • partenaire %s" % SupplierManager.supplier_label(supplier_id)
		status_label.text = "%s entre en développement — %s • usage %s%s%s%s." % [name, str(evaluation.profile), CPU_DESIGN.application_label(application_key), plan_text, remediation_text, supplier_text]
		active_cpu_generation_plan = {}
		active_cpu_remediation = {}
	else:
		status_label.text = "Impossible de lancer le projet : vérifiez la trésorerie, la capacité R&D et la disponibilité du partenaire."
	_refresh_all()

func _file_patent(): status_label.text="Brevet déposé." if PatentManager.file_first_candidate() else "Aucun brevet candidat ou trésorerie insuffisante."; _refresh_all()

func _toggle_patent_license(): PatentManager.toggle_license_first(); _refresh_all()
