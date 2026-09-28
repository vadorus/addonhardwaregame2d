extends Node
## V0.9 — Architectures possédées, gammes du joueur, maturité (retour d'expérience).
## Tranche 1 du modèle d'Alexandre : l'architecture est la base, l'équipe de développement en tire
## des modèles, et chaque modèle lancé ou vendu fait mûrir son architecture jusqu'à un plafond.

const CATALOG := preload("res://scripts/ArchitectureCatalog.gd")
const MATURITY_PER_LAUNCH := 10.0
const MATURITY_PER_MONTH := 0.4
const PLATEAU := 85.0
const MAX_YIELD_BONUS := 0.06

signal architectures_changed

var owned: Array = ["A4"]
var maturity: Dictionary = {}
var models_launched: Dictionary = {}
var plateau_warned: Dictionary = {}
var lines: Array = []
var _next_line_id := 1

func reset() -> void:
	owned = ["A4"]
	maturity = {}
	models_launched = {}
	plateau_warned = {}
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
	return "%s %d" % [str(line.get("name", "Nova")), int(line.get("generations", 0)) + 1]

## Relie un projet qui vient de démarrer à sa gamme et à son architecture.
func register_project(project_name: String, line_id: String, arch_id: String, tiers: Array) -> void:
	for i in range(ResearchManager.projects.size() - 1, -1, -1):
		var project: Dictionary = ResearchManager.projects[i]
		if str(project.get("name", "")) == project_name:
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
		"plateau_warned":plateau_warned.duplicate(), "lines":lines.duplicate(true), "next_line_id":_next_line_id}

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
