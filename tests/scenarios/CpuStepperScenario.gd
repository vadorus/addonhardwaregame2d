extends RefCounted
## V0.9 — Parcours de création : gamme → architecture → objectif → modèles → budget.
## Vérifie : architecture de départ, limites de l'architecture respectées, proposition de l'équipe,
## lancement réel relié à une gamme, et gamme construite avec le nombre de modèles choisi.

const STEPPER := preload("res://ui/components/CpuDesignStepper.gd")
const CPU_PRODUCT_LINE := preload("res://scripts/CpuProductLine.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("Stepper Test", "CPU", "STANDARD")
	if ArchitectureManager.owned != ["A4"] or ArchitectureManager.latest_id() != "A4":
		return "V0.9 architectures: a 1971 company must start with the 4-bit architecture only (got %s)" % str(ArchitectureManager.owned)
	if not ResearchManager.start_project("Nova 1", "CPU", MarketManager.default_segment(), "INTERNAL", "BALANCED", 45000, CpuDesignModel.default_design()):
		return "V0.9 stepper: could not create the first project for the test"
	var stepper := STEPPER.new() as Control
	host.add_child(stepper)
	stepper.call("open")
	if not stepper.visible or int(stepper.call("step_count")) != 5 or int(stepper.get("step")) != 0:
		stepper.queue_free()
		return "V0.9 stepper: must open on step 1 of 5"
	# Objectif « Performant » : l'équipe propose, mais sans dépasser l'architecture 4 bits (1 cœur, pas de cache).
	stepper.set("profile", "PERF")
	stepper.call("_apply_proposal")
	var design: Dictionary = stepper.call("current_design")
	if int(design.get("cores", 0)) != 1 or float(design.get("cache_mb", 1.0)) > 0.0:
		stepper.queue_free()
		return "V0.9 stepper: the proposal exceeds the 4-bit architecture limits (%s)" % str(design)
	stepper.set("adjust", true)
	stepper.call("go_to_step", 2)
	if int(stepper.call("row_count")) < 5:
		stepper.queue_free()
		return "V0.9 stepper: 'adjust' must show the five setting rows"
	stepper.call("_shift_core", 1)
	stepper.call("_shift_cache", 1)
	design = stepper.call("current_design")
	if int(design.get("cores", 0)) != 1 or float(design.get("cache_mb", 1.0)) > 0.0:
		stepper.queue_free()
		return "V0.9 stepper: manual settings can go past the architecture limits"
	# Deux modèles seulement.
	stepper.set("tiers", ["SIGNATURE", "APEX"])
	var spec: Dictionary = stepper.call("current_spec")
	stepper.queue_free()
	if str(spec.architecture_id) != "A4" or (spec.model_tiers as Array).size() != 2 or str(spec.name) != "Nova 1":
		return "V0.9 stepper: unexpected spec %s" % str(spec)
	var count := ResearchManager.projects.size()
	if not ResearchManager.start_project("Nova Gaming 1", "CPU", str(spec.segment), "INTERNAL", str(spec.focus), int(spec.budget), CpuDesignModel.normalize(spec.design), {}, {}, "GENERAL"):
		return "V0.9 stepper: the proposed spec cannot start a real project"
	var line_id := ArchitectureManager.create_line("Nova Gaming", str(spec.segment), "A4")
	ArchitectureManager.register_project("Nova Gaming 1", line_id, "A4", spec.model_tiers)
	var project: Dictionary = ResearchManager.projects[ResearchManager.projects.size() - 1]
	if ResearchManager.projects.size() != count + 1 or str(project.get("architecture_id", "")) != "A4" or str(project.get("line_id", "")) != line_id:
		return "V0.9 stepper: the project is not linked to its range and architecture"
	if ArchitectureManager.next_model_name(ArchitectureManager.get_line(line_id)) != "Nova Gaming 2":
		return "V0.9 lines: the next generation name should be 'Nova Gaming 2'"
	# La gamme ne contient que les modèles choisis, avec des parts de tri renormalisées.
	project["cpu_design"] = CpuDesignModel.normalize(spec.design)
	var built := CPU_PRODUCT_LINE.build_range(project, "CPU-GEN-T", 1, 40, 120, 1000, 0.0, {})
	var products: Array = built.get("products", [])
	if products.size() != 2 or str((products[0] as Dictionary).get("sku_tier", "")) != "SIGNATURE":
		return "V0.9 lines: a two-model range must contain Signature and Apex only (got %d)" % products.size()
	# Retour d'expérience : un lancement fait mûrir l'architecture, et le rendement suit.
	var before := ArchitectureManager.yield_bonus("A4")
	ArchitectureManager.on_product_launched({"architecture_id":"A4"})
	if ArchitectureManager.maturity_of("A4") <= 0.0 or ArchitectureManager.yield_bonus("A4") <= before:
		return "V0.9 feedback: launching a model must mature its architecture"
	# 1975 : l'architecture 8 bits (1974) doit être disponible.
	TimeManager.year = 1975
	ArchitectureManager.sync_unlocks(false)
	if not ArchitectureManager.owned.has("A8") or ArchitectureManager.latest_id() != "A8":
		return "V0.9 architectures: 8-bit architecture must be available in 1975"
	# Carte de projet (Labo > Projets) : se construit et place un projet neuf en « Conception ».
	var card := (load("res://ui/components/ProjectCard.gd") as Script).new() as PanelContainer
	host.add_child(card)
	card.call("show_project", project, ["détail de test"])
	var stage := int(card.call("_stage_of", project))
	card.queue_free()
	if stage != 1:
		return "V0.9 project card: a project in development must show the 'Conception' stage (got %d)" % stage
	# Sauvegarde / chargement.
	var state := ArchitectureManager.get_state()
	ArchitectureManager.reset()
	ArchitectureManager.load_state(state)
	if not ArchitectureManager.owned.has("A8") or ArchitectureManager.get_line(line_id).is_empty() or ArchitectureManager.maturity_of("A4") <= 0.0:
		return "V0.9 architectures: state does not survive save/load"
	return ""
