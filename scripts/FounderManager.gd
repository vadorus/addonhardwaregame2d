extends Node

signal founder_changed
signal level_up(new_level)
signal branch_level_up(branch, new_level)

const SKILL_PROGRAMMING := "PROGRAMMING"
const SKILL_ELECTRONICS := "ELECTRONICS"
const SKILL_MANAGEMENT := "MANAGEMENT"
const SKILL_COMMERCIAL := "COMMERCIAL"

const BRANCH_BUSINESS := "BUSINESS"
const BRANCH_INDUSTRIAL := "INDUSTRIAL"
const BRANCH_SCIENTIFIC := "SCIENTIFIC"
const BRANCH_EMBEDDED := "EMBEDDED"
const BRANCH_WEB := "WEB"

const SKILL_LABELS := {
	SKILL_PROGRAMMING:"Programmation",
	SKILL_ELECTRONICS:"Électronique",
	SKILL_MANAGEMENT:"Gestion",
	SKILL_COMMERCIAL:"Commercial"
}

const BRANCH_DEFS := {
	BRANCH_BUSINESS:{
		"label":"Logiciels de gestion",
		"min_year":1971,
		"tree":[
			{"level":2,"title":"Code structuré","effect":"Développement +8%","speed":0.08},
			{"level":4,"title":"Bibliothèque métier","effect":"Développement +12% • coûts -5%","speed":0.12,"cost":0.05},
			{"level":6,"title":"Méthodes fiables","effect":"Qualité +10 • paiement +5%","quality":10.0,"reward":0.05}
		]
	},
	BRANCH_INDUSTRIAL:{
		"label":"Logiciels industriels",
		"min_year":1971,
		"tree":[
			{"level":2,"title":"Diagnostic terrain","effect":"Qualité +8","quality":8.0},
			{"level":4,"title":"Temps réel","effect":"Développement +12%","speed":0.12},
			{"level":6,"title":"Systèmes robustes","effect":"Qualité +12 • paiement +5%","quality":12.0,"reward":0.05}
		]
	},
	BRANCH_SCIENTIFIC:{
		"label":"Calcul scientifique",
		"min_year":1971,
		"tree":[
			{"level":2,"title":"Calcul numérique","effect":"Développement +8% • qualité +4","speed":0.08,"quality":4.0},
			{"level":4,"title":"Optimisation mémoire","effect":"Développement +12%","speed":0.12},
			{"level":6,"title":"Bibliothèques de calcul","effect":"Qualité +10 • coûts -5%","quality":10.0,"cost":0.05}
		]
	},
	BRANCH_EMBEDDED:{
		"label":"Commande & embarqué",
		"min_year":1971,
		"tree":[
			{"level":2,"title":"Programmation bas niveau","effect":"Développement +8%","speed":0.08},
			{"level":4,"title":"ROM & entrées/sorties","effect":"Qualité +10","quality":10.0},
			{"level":6,"title":"Systèmes compacts","effect":"Développement +10% • coûts -5%","speed":0.10,"cost":0.05}
		]
	},
	BRANCH_WEB:{
		"label":"Web",
		"min_year":1991,
		"tree":[
			{"level":2,"title":"Hypertexte","effect":"Développement +8%","speed":0.08},
			{"level":4,"title":"Applications web","effect":"Qualité +8 • paiement +5%","quality":8.0,"reward":0.05},
			{"level":6,"title":"Services en ligne","effect":"Développement +12%","speed":0.12}
		]
	}
}

const PROGRAMMING_TREE := [
	{"level":2,"title":"Code structuré","effect":"Tous les logiciels +5% vitesse","software_speed":0.05},
	{"level":3,"title":"Tests & débogage","effect":"Qualité logiciel +6 • validation CPU +2%","software_quality":6.0,"cpu_confidence":0.02},
	{"level":4,"title":"Bas niveau & assembleur","effect":"Embarqué/électronique +8% • CPU +3% vitesse","hardware_speed":0.08,"cpu_speed":0.03},
	{"level":5,"title":"Outillage de développement","effect":"Tous les projets +5% vitesse • coûts logiciel -3%","global_speed":0.05,"software_cost":0.03},
	{"level":6,"title":"Simulation numérique","effect":"CPU +5% vitesse • validation CPU +3%","cpu_speed":0.05,"cpu_confidence":0.03},
	{"level":7,"title":"Microcode & compilation","effect":"CPU +6% vitesse • qualité CPU +5","cpu_speed":0.06,"cpu_quality":5.0}
]

var programming_level := 1
var programming_xp := 0
var developer_tools_level := 0

var level := 1
var level_xp := 0
var total_xp := 0
var skills := {}
var branch_levels := {}
var branch_xp := {}

func _default_skills() -> Dictionary:
	return {
		SKILL_PROGRAMMING:18.0,
		SKILL_ELECTRONICS:5.0,
		SKILL_MANAGEMENT:8.0,
		SKILL_COMMERCIAL:6.0
	}

func _reset_branches() -> void:
	branch_levels = {}
	branch_xp = {}
	for branch in BRANCH_DEFS.keys():
		branch_levels[str(branch)] = 1
		branch_xp[str(branch)] = 0

func reset() -> void:
	level = 1
	level_xp = 0
	total_xp = 0
	programming_level = 1
	programming_xp = 0
	developer_tools_level = 0
	skills = _default_skills()
	_reset_branches()
	founder_changed.emit()

func programming_xp_to_next() -> int:
	return 80 + (programming_level - 1) * 65

func programming_xp_ratio() -> float:
	return clampf(float(programming_xp) / maxf(float(programming_xp_to_next()), 1.0), 0.0, 1.0)

func add_programming_mastery(xp_amount: int) -> void:
	if xp_amount <= 0:
		return
	programming_xp += xp_amount
	while programming_xp >= programming_xp_to_next():
		programming_xp -= programming_xp_to_next()
		programming_level += 1
		founder_changed.emit()
	founder_changed.emit()

func programming_tree() -> Array:
	var rows: Array = []
	for node_value in PROGRAMMING_TREE:
		var node: Dictionary = node_value.duplicate(true)
		node["unlocked"] = programming_level >= int(node.get("level", 99))
		rows.append(node)
	return rows

func next_programming_perk() -> Dictionary:
	for node_value in programming_tree():
		var node: Dictionary = node_value
		if not bool(node.get("unlocked", false)):
			return node
	return {}

func _programming_bonus(key: String) -> float:
	var total := 0.0
	for node_value in programming_tree():
		var node: Dictionary = node_value
		if bool(node.get("unlocked", false)):
			total += float(node.get(key, 0.0))
	return total

func improve_developer_tools() -> bool:
	if developer_tools_level >= 10:
		return false
	developer_tools_level += 1
	add_programming_mastery(12 + developer_tools_level * 2)
	add_multi_experience(8, {SKILL_PROGRAMMING:0.8, SKILL_MANAGEMENT:0.2})
	return true

func developer_tools_multiplier() -> float:
	return 1.0 + float(developer_tools_level) * 0.015

func software_programming_speed_multiplier() -> float:
	var skill_bonus := lerpf(1.0, 1.18, skill_value(SKILL_PROGRAMMING) / 100.0)
	return clampf((skill_bonus + _programming_bonus("software_speed") + _programming_bonus("global_speed")) * developer_tools_multiplier(), 1.0, 1.75)

func software_programming_quality_bonus() -> float:
	return skill_value(SKILL_PROGRAMMING) * 0.05 + _programming_bonus("software_quality")

func software_programming_cost_discount() -> float:
	return clampf(_programming_bonus("software_cost"), 0.0, 0.20)

func hardware_programming_multiplier() -> float:
	return clampf((1.0 + _programming_bonus("hardware_speed") + _programming_bonus("global_speed") + skill_value(SKILL_PROGRAMMING) / 800.0) * developer_tools_multiplier(), 1.0, 1.55)

func cpu_development_multiplier() -> float:
	return clampf((1.0 + _programming_bonus("cpu_speed") + _programming_bonus("global_speed") + skill_value(SKILL_PROGRAMMING) / 1000.0) * developer_tools_multiplier(), 1.0, 1.45)

func cpu_programming_confidence_bonus() -> float:
	return clampf(_programming_bonus("cpu_confidence") * 100.0 + skill_value(SKILL_PROGRAMMING) * 0.04, 0.0, 10.0)

func cpu_programming_quality_bonus() -> float:
	return clampf(_programming_bonus("cpu_quality") + skill_value(SKILL_PROGRAMMING) * 0.03, 0.0, 9.0)

func xp_to_next_level() -> int:
	return 100 + (level - 1) * 60

func xp_progress_ratio() -> float:
	return clampf(float(level_xp) / maxf(float(xp_to_next_level()), 1.0), 0.0, 1.0)

func skill_value(skill: String) -> float:
	return clampf(float(skills.get(skill, 0.0)), 0.0, 100.0)

func skill_label(skill: String) -> String:
	return str(SKILL_LABELS.get(skill, skill.capitalize()))

func branch_label(branch: String) -> String:
	return str(BRANCH_DEFS.get(branch, {}).get("label", branch.capitalize()))

func branch_min_year(branch: String) -> int:
	return int(BRANCH_DEFS.get(branch, {}).get("min_year", 9999))

func branch_available(branch: String, year: int = -1) -> bool:
	var check_year := TimeManager.year if year < 0 else year
	return BRANCH_DEFS.has(branch) and check_year >= branch_min_year(branch)

func branch_level(branch: String) -> int:
	return maxi(int(branch_levels.get(branch, 1)), 1)

func branch_xp_value(branch: String) -> int:
	return maxi(int(branch_xp.get(branch, 0)), 0)

func branch_xp_to_next(branch: String) -> int:
	return 90 + (branch_level(branch) - 1) * 70

func branch_xp_ratio(branch: String) -> float:
	return clampf(float(branch_xp_value(branch)) / maxf(float(branch_xp_to_next(branch)), 1.0), 0.0, 1.0)

func available_branches(year: int = -1) -> Array:
	var result: Array = []
	for branch_value in BRANCH_DEFS.keys():
		var branch := str(branch_value)
		if branch_available(branch, year):
			result.append(branch)
	result.sort()
	return result

func add_experience(skill: String, xp_amount: int, skill_gain: float) -> void:
	add_multi_experience(xp_amount, {skill:skill_gain})

func add_multi_experience(xp_amount: int, gains: Dictionary) -> void:
	if xp_amount > 0:
		total_xp += xp_amount
		level_xp += xp_amount
	for skill_value_key in gains.keys():
		var skill := str(skill_value_key)
		if SKILL_LABELS.has(skill):
			skills[skill] = clampf(skill_value(skill) + float(gains[skill_value_key]), 0.0, 100.0)

	while level_xp >= xp_to_next_level():
		level_xp -= xp_to_next_level()
		level += 1
		level_up.emit(level)

	founder_changed.emit()

func add_branch_experience(branch: String, xp_amount: int) -> void:
	if not BRANCH_DEFS.has(branch) or xp_amount <= 0:
		return
	branch_xp[branch] = branch_xp_value(branch) + xp_amount
	while branch_xp_value(branch) >= branch_xp_to_next(branch):
		branch_xp[branch] = branch_xp_value(branch) - branch_xp_to_next(branch)
		branch_levels[branch] = branch_level(branch) + 1
		branch_level_up.emit(branch, branch_level(branch))
	founder_changed.emit()

func branch_tree(branch: String) -> Array:
	var rows: Array = []
	var tree_value = BRANCH_DEFS.get(branch, {}).get("tree", [])
	if typeof(tree_value) != TYPE_ARRAY:
		return rows
	for node_value in tree_value:
		var node: Dictionary = node_value.duplicate(true)
		node["unlocked"] = branch_level(branch) >= int(node.get("level", 99))
		rows.append(node)
	return rows

func _branch_bonus(branch: String, key: String) -> float:
	var total := 0.0
	for node_value in branch_tree(branch):
		var node: Dictionary = node_value
		if bool(node.get("unlocked", false)):
			total += float(node.get(key, 0.0))
	return total

func branch_speed_multiplier(branch: String) -> float:
	var mastery := float(maxi(branch_level(branch) - 1, 0)) * 0.025
	return clampf(1.0 + mastery + _branch_bonus(branch, "speed"), 1.0, 1.80)

func branch_quality_bonus(branch: String) -> float:
	return float(maxi(branch_level(branch) - 1, 0)) * 1.2 + _branch_bonus(branch, "quality")

func branch_cost_discount(branch: String) -> float:
	return clampf(_branch_bonus(branch, "cost"), 0.0, 0.35)

func branch_reward_bonus(branch: String) -> float:
	return clampf(_branch_bonus(branch, "reward"), 0.0, 0.30)

func programming_multiplier() -> float:
	return software_programming_speed_multiplier()

func electronics_multiplier() -> float:
	return lerpf(0.85, 1.32, skill_value(SKILL_ELECTRONICS) / 100.0)

func commercial_multiplier() -> float:
	return lerpf(0.90, 1.25, skill_value(SKILL_COMMERCIAL) / 100.0)

func management_multiplier() -> float:
	return lerpf(0.92, 1.22, skill_value(SKILL_MANAGEMENT) / 100.0)

func get_state() -> Dictionary:
	return {
		"level":level,
		"level_xp":level_xp,
		"total_xp":total_xp,
		"programming_level":programming_level,
		"programming_xp":programming_xp,
		"developer_tools_level":developer_tools_level,
		"skills":skills.duplicate(true),
		"branch_levels":branch_levels.duplicate(true),
		"branch_xp":branch_xp.duplicate(true)
	}

func load_state(state: Dictionary) -> void:
	if state.is_empty():
		reset()
		return
	level = maxi(int(state.get("level", 1)), 1)
	level_xp = maxi(int(state.get("level_xp", 0)), 0)
	total_xp = maxi(int(state.get("total_xp", level_xp)), 0)
	programming_level = maxi(int(state.get("programming_level", 1)), 1)
	programming_xp = maxi(int(state.get("programming_xp", 0)), 0)
	developer_tools_level = clampi(int(state.get("developer_tools_level", 0)), 0, 10)
	skills = _default_skills()
	var loaded_skills: Dictionary = state.get("skills", {})
	for skill in SKILL_LABELS.keys():
		skills[skill] = clampf(float(loaded_skills.get(skill, skills.get(skill, 0.0))), 0.0, 100.0)
	_reset_branches()
	var loaded_levels: Dictionary = state.get("branch_levels", {})
	var loaded_xp: Dictionary = state.get("branch_xp", {})
	for branch in BRANCH_DEFS.keys():
		var key := str(branch)
		branch_levels[key] = maxi(int(loaded_levels.get(key, 1)), 1)
		branch_xp[key] = maxi(int(loaded_xp.get(key, 0)), 0)
	founder_changed.emit()
