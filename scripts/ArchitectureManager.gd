extends Node
## V0.9 — Architectures possédées, gammes du joueur, maturité (retour d'expérience).
## Tranche 1 du modèle d'Alexandre : l'architecture est la base, l'équipe de développement en tire
## des modèles, et chaque modèle lancé ou vendu fait mûrir son architecture jusqu'à un plafond.

const CATALOG := preload("res://scripts/ArchitectureCatalog.gd")
const MATURITY_PER_LAUNCH := 10.0
const MATURITY_PER_MONTH := 0.4
const PLATEAU := 85.0
const MAX_YIELD_BONUS := 0.06
const RESEARCH_TEAMS := preload("res://scripts/ResearchTeams.gd")
## Lot E3/E4 : tick (même architecture, procédé plus fin) ou tock (nouvelle architecture).
const MODE_SPEED := {"NEW_LINE":1.0, "TICK":1.15, "TOCK":0.88}
const MODE_LABELS := {"NEW_LINE":"Nouvelle gamme", "TICK":"Tick", "TOCK":"Tock"}
const WEAR_YEARS := 6.0
const WEAR_PERFORMANCE_PENALTY := 8.0
const WEAR_EFFICIENCY_PENALTY := 4.0

signal architectures_changed

var owned: Array = ["A4"]
var maturity: Dictionary = {}
var models_launched: Dictionary = {}
var plateau_warned: Dictionary = {}
var wear_warned: Dictionary = {}
var lines: Array = []
var _next_line_id := 1

func reset() -> void:
	owned = ["A4"]
	maturity = {}
	models_launched = {}
	plateau_warned = {}
	wear_warned = {}
	lines = []
	_next_line_id = 1
	architectures_changed.emit()

# --- Architectures -----------------------------------------------------------------

func capability() -> float:
	return float(ResearchManager.get_cpu_capability("ARCHITECTURE"))

## Ajoute les architectures devenues disponibles ; renvoie celles qui viennent d'arriver.
func sync_unlocks(announce: bool = true) -> Array:
	var fresh: Array = []
	for arch in CATALOG.all():
		var arch_id := str(arch.id)
		if owned.has(arch_id):
			continue
		if CATALOG.is_available(arch, TimeManager.year, capability()):
			owned.append(arch_id)
			fresh.append(arch)
			if announce and CompanyManager.created:
				CompanyManager.add_alert("Nouvelle architecture disponible : %s. %s" % [str(arch.name), str(arch.pitch)])
	if not fresh.is_empty():
		architectures_changed.emit()
	return fresh

func owned_architectures() -> Array:
	var result: Array = []
	for arch in CATALOG.all():
		if owned.has(str(arch.id)):
			result.append(arch)
	return result

func locked_architectures() -> Array:
	var result: Array = []
	for arch in CATALOG.all():
		if not owned.has(str(arch.id)):
			result.append(arch)
	return result

func latest_id() -> String:
	var archs := owned_architectures()
	return str((archs[archs.size() - 1] as Dictionary).id) if not archs.is_empty() else "A4"

func maturity_of(arch_id: String) -> float:
	return float(maturity.get(arch_id, 0.0))

func yield_bonus(arch_id: String) -> float:
	return maturity_of(arch_id) / 100.0 * MAX_YIELD_BONUS

func maturity_label(arch_id: String) -> String:
	var value := maturity_of(arch_id)
	if value >= PLATEAU:
		return "Plafonne : préparez la suivante"
	if value >= 50.0:
		return "Bien maîtrisée"
	if value >= 15.0:
		return "En rodage"
	return "Toute neuve"

# --- Retour d'expérience ---------------------------------------------------------------

func on_product_launched(product: Dictionary) -> void:
	var arch_id := str(product.get("architecture_id", ""))
	if arch_id == "":
		return
	models_launched[arch_id] = int(models_launched.get(arch_id, 0)) + 1
	_add_maturity(arch_id, MATURITY_PER_LAUNCH)

func process_month() -> void:
	sync_unlocks(true)
	for product in ProductManager.products:
		if str(product.get("status", "")) == "LAUNCHED" and str(product.get("architecture_id", "")) != "":
			_add_maturity(str(product.architecture_id), MATURITY_PER_MONTH)
	_check_wear()

# --- Lot E4 : usure d'une architecture -------------------------------------------------------

## Usure 0..1 : une architecture s'use dès qu'une plus récente est disponible (6 ans pour s'essouffler),
## un peu plus vite si elle a déjà plafonné.
func wear_of(arch_id: String) -> float:
	var archs := owned_architectures()
	var index := -1
	for i in range(archs.size()):
		if str((archs[i] as Dictionary).id) == arch_id:
			index = i
	if index < 0 or index >= archs.size() - 1:
		return 0.0
	var next_year := int((archs[index + 1] as Dictionary).year)
	var years := maxf(float(TimeManager.year - next_year) + float(TimeManager.month - 1) / 12.0, 0.0)
	var wear := years / WEAR_YEARS + (0.10 if maturity_of(arch_id) >= PLATEAU else 0.0)
	return clampf(wear, 0.0, 1.0)

func wear_label(arch_id: String) -> String:
	var wear := wear_of(arch_id)
	if wear >= 0.75:
		return "À bout de souffle"
	if wear >= 0.5:
		return "Fatiguée"
	if wear >= 0.2:
		return "Commence à vieillir"
	return "Fraîche"

## Architectures encore utilisées par un produit en vente ou une gamme.
func architectures_in_use() -> Array:
	var used: Array = []
	for product in ProductManager.products:
		var arch_id := str(product.get("architecture_id", ""))
		if str(product.get("status", "")) == "LAUNCHED" and arch_id != "" and not used.has(arch_id):
			used.append(arch_id)
	for line in lines:
		var line_arch := str(line.get("architecture_id", ""))
		if line_arch != "" and not used.has(line_arch):
			used.append(line_arch)
	return used

func _check_wear() -> void:
	if not CompanyManager.created:
		return
	for arch_id_value in architectures_in_use():
		var arch_id := str(arch_id_value)
		if wear_of(arch_id) < 0.5 or bool(wear_warned.get(arch_id, false)):
			continue
		wear_warned[arch_id] = true
		CompanyManager.add_alert("Équipe de développement : l'%s s'use. Nos prochaines puces dessus seront moins rapides — passez la prochaine génération sur %s (tock)." % [
			str(CATALOG.get_by_id(arch_id).name).to_lower(), str(CATALOG.get_by_id(latest_id()).name).to_lower()])

# --- Lot E3 : l'architecture prend la forme de vos équipes -------------------------------------

## Signature des équipes de recherche : bonus / malus par critère selon le niveau de chaque équipe.
func team_signature() -> Dictionary:
	var result := {}
	for axis in RESEARCH_TEAMS.AXES:
		var metric := str(RESEARCH_TEAMS.AXIS_METRIC[axis])
		var level := RESEARCH_TEAMS.team_level(axis)
		# Une équipe d'une seule personne marque moins l'architecture qu'une vraie équipe (3 et plus).
		var size_factor := clampf(sqrt(float(RESEARCH_TEAMS.members(axis, false).size()) / 3.0), 0.4, 1.0)
		result[metric] = 0.0 if level <= 0.0 else clampf((level - 45.0) * 0.15 * size_factor, -3.0, 6.0)
	return result

func signature_text(signature: Dictionary) -> String:
	var parts: Array = []
	for axis in RESEARCH_TEAMS.AXES:
		var value := float(signature.get(str(RESEARCH_TEAMS.AXIS_METRIC[axis]), 0.0))
		parts.append("%s %s%.0f" % [str(RESEARCH_TEAMS.AXIS_LABELS[axis]), "+" if value >= 0.0 else "", value])
	return "  •  ".join(parts)

## Tick / tock pour une suite de gamme.
func project_mode(line: Dictionary, arch_id: String) -> String:
	if line.is_empty() or int(line.get("generations", 0)) <= 0:
		return "NEW_LINE"
	return "TICK" if str(line.get("architecture_id", "")) == arch_id else "TOCK"

func is_first_use(arch_id: String) -> bool:
	if int(models_launched.get(arch_id, 0)) > 0:
		return false
	for project in ResearchManager.projects:
		if str(project.get("architecture_id", "")) == arch_id:
			return false
	return true

## Ajustements appliqués aux mesures finales d'un projet (signature, tick/tock, usure, première puce).
func metric_adjustments(mode: String, arch_id: String, signature: Dictionary, first_use: bool) -> Dictionary:
	var result := {"performance":0.0, "efficiency":0.0, "reliability":0.0}
	var weight := 1.5 if mode == "TOCK" else 1.0
	for key in result.keys():
		result[key] = float(result[key]) + float(signature.get(key, 0.0)) * weight
	if mode == "TICK":
		result["reliability"] = float(result.reliability) + 3.0
	elif mode == "TOCK":
		result["performance"] = float(result.performance) + 4.0
	if first_use and float(signature.get("reliability", 0.0)) < 2.0:
		result["reliability"] = float(result.reliability) - 3.0
	var wear := wear_of(arch_id)
	result["performance"] = float(result.performance) - wear * WEAR_PERFORMANCE_PENALTY
	result["efficiency"] = float(result.efficiency) - wear * WEAR_EFFICIENCY_PENALTY
	return result

## Ce que le développement dit du choix, pour l'étape Architecture.
func mode_advice(mode: String, arch_id: String, first_use: bool) -> String:
	var text := ""
	match mode:
		"TICK":
			text = "Tick : on garde la même architecture sur un procédé plus fin. Développement ~15 % plus rapide, fiabilité +3."
		"TOCK":
			text = "Tock : nouvelle architecture pour la gamme. Développement ~12 % plus long, performance +4 et la signature des équipes compte davantage."
		_:
			text = "Nouvelle gamme : l'équipe part de zéro sur cette architecture."
	if first_use:
		text += " Première puce sur cette architecture : risque de défauts de jeunesse (fiabilité -3) sauf si l'équipe Fiabilité est solide."
	var wear := wear_of(arch_id)
	if wear >= 0.2:
		text += " Usure %.0f %% : performance -%.0f." % [wear * 100.0, wear * WEAR_PERFORMANCE_PENALTY]
	return text

func _add_maturity(arch_id: String, amount: float) -> void:
	var before := maturity_of(arch_id)
	maturity[arch_id] = minf(before + amount, 100.0)
	if before < PLATEAU and maturity_of(arch_id) >= PLATEAU and not bool(plateau_warned.get(arch_id, false)):
		plateau_warned[arch_id] = true
		if CompanyManager.created:
			CompanyManager.add_alert("Équipe de développement : on ne tirera plus grand-chose de l'%s. Il est temps de passer à une architecture plus récente." % str(CATALOG.get_by_id(arch_id).name).to_lower())
	architectures_changed.emit()

# --- Gammes ----------------------------------------------------------------------------

func create_line(line_name: String, segment: String, arch_id: String) -> String:
	var line_id := "LINE-%03d" % _next_line_id
	_next_line_id += 1
	lines.append({"id":line_id, "name":line_name.strip_edges(), "segment":segment, "architecture_id":arch_id, "generations":0})
	architectures_changed.emit()
	return line_id

func get_line(line_id: String) -> Dictionary:
	for line in lines:
		if str(line.id) == line_id:
			return line
	return {}

## Nom proposé pour la prochaine génération d'une gamme : « Nova Gaming 3 ».
func next_model_name(line: Dictionary) -> String:
	return unique_cpu_name("%s %d" % [str(line.get("name", "Nova")), int(line.get("generations", 0)) + 1])

## Revue du 07/10 : deux « Nova 1 » dans une même partie (un nouveau projet nommé comme un projet en cours,
## ou une gamme recréée sous le même nom). Un nom de CPU est maintenant unique dans la partie.
func cpu_name_taken(candidate: String) -> bool:
	var wanted := candidate.strip_edges().to_lower()
	for project_value in ResearchManager.projects:
		if str((project_value as Dictionary).get("name", "")).strip_edges().to_lower() == wanted:
			return true
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("company", CompanyManager.company_name)) != CompanyManager.company_name:
			continue
		if str(product.get("generation_name", product.get("name", ""))).strip_edges().to_lower() == wanted:
			return true
	return false

## Le nom demandé s'il est libre, sinon le même avec le premier numéro libre (« Nova 1 » → « Nova 2 »…).
func unique_cpu_name(candidate: String) -> String:
	var clean := candidate.strip_edges()
	if clean == "":
		clean = "Nova 1"
	if not cpu_name_taken(clean):
		return clean
	var base := clean
	var number := 1
	var digits := RegEx.create_from_string("^(.*?)\\s*(\\d+)$").search(clean)
	if digits != null:
		base = digits.get_string(1).strip_edges()
		number = int(digits.get_string(2))
	for next in range(number + 1, number + 200):
		var proposal := "%s %d" % [base, next]
		if not cpu_name_taken(proposal):
			return proposal
	return "%s %d" % [base, Time.get_ticks_msec() % 100000]

## Relie un projet qui vient de démarrer à sa gamme et à son architecture.
func register_project(project_name: String, line_id: String, arch_id: String, tiers: Array) -> void:
	var mode := project_mode(get_line(line_id), arch_id)
	var first_use := is_first_use(arch_id)
	for i in range(ResearchManager.projects.size() - 1, -1, -1):
		var project: Dictionary = ResearchManager.projects[i]
		if str(project.get("name", "")) == project_name:
			project["arch_mode"] = mode
			project["arch_first_use"] = first_use
			project["team_signature"] = team_signature()
			project["architecture_id"] = arch_id
			project["line_id"] = line_id
			project["model_tiers"] = tiers.duplicate()
			break
	for line in lines:
		if str(line.id) == line_id:
			line["generations"] = int(line.get("generations", 0)) + 1
			line["architecture_id"] = arch_id
	architectures_changed.emit()

# --- Sauvegarde --------------------------------------------------------------------------

func get_state() -> Dictionary:
	return {"owned":owned.duplicate(), "maturity":maturity.duplicate(), "models_launched":models_launched.duplicate(),
		"plateau_warned":plateau_warned.duplicate(), "wear_warned":wear_warned.duplicate(),
		"lines":lines.duplicate(true), "next_line_id":_next_line_id}

func load_state(state: Dictionary) -> void:
	reset()
	if state.is_empty():
		_migrate_from_existing_game()
		return
	owned = (state.get("owned", ["A4"]) as Array).duplicate()
	maturity = (state.get("maturity", {}) as Dictionary).duplicate()
	models_launched = (state.get("models_launched", {}) as Dictionary).duplicate()
	plateau_warned = (state.get("plateau_warned", {}) as Dictionary).duplicate()
	lines = (state.get("lines", []) as Array).duplicate(true)
	_next_line_id = int(state.get("next_line_id", lines.size() + 1))
	if not owned.has("A4"):
		owned.push_front("A4")
	sync_unlocks(false)
	if state.has("wear_warned"):
		wear_warned = (state.get("wear_warned", {}) as Dictionary).duplicate()
	else:
		# Sauvegarde d'avant le lot E4 : on ne déverse pas toutes les alertes d'usure au chargement.
		for arch_id_value in architectures_in_use():
			if wear_of(str(arch_id_value)) >= 0.5:
				wear_warned[str(arch_id_value)] = true

## Anciennes parties : architectures selon l'année, produits rattachés, gammes déduites des noms de projets.
func _migrate_from_existing_game() -> void:
	sync_unlocks(false)
	var default_arch := latest_id()
	for product in ProductManager.products:
		if str(product.get("architecture_id", "")) == "":
			product["architecture_id"] = default_arch
		if str(product.get("status", "")) == "LAUNCHED":
			models_launched[default_arch] = int(models_launched.get(default_arch, 0)) + 1
	maturity[default_arch] = minf(float(models_launched.get(default_arch, 0)) * MATURITY_PER_LAUNCH, PLATEAU - 1.0)
	var regex := RegEx.new()
	regex.compile("[\\s\\d]+$")
	for project in ResearchManager.projects:
		var base := regex.sub(str(project.get("name", "")), "").strip_edges()
		if base == "":
			continue
		var found: Dictionary = {}
		for line in lines:
			if str(line.name) == base:
				found = line
		if found.is_empty():
			create_line(base, str(project.get("segment", MarketManager.default_segment())), default_arch)
			found = lines[lines.size() - 1]
		found["generations"] = int(found.get("generations", 0)) + 1
		found["segment"] = str(project.get("segment", found.get("segment", "")))
