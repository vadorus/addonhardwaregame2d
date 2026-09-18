extends Node

signal stage_changed(sector_id, previous_stage, new_stage, state)

var achieved_stages: Dictionary = {}

const SECTOR_ORDER := ["LAB", "PRODUCTION", "MARKET", "TEAM"]

const DEFINITIONS := {
	"LAB": {
		"title": "Laboratoire CPU",
		"icon": "⚗",
		"subtitle": "Recherche, prototypage et innovation.",
		"stages": [
			{"name":"Coin prototype", "desc":"Vos premières idées testées sur un établi."},
			{"name":"Petit labo", "desc":"Des tests plus sérieux et de meilleurs prototypes."},
			{"name":"Labo structuré", "desc":"Une vraie équipe et des outils avancés."},
			{"name":"Pôle R&D", "desc":"Recherche de pointe et nouveaux designs."},
			{"name":"Campus innovation", "desc":"Un centre d'excellence reconnu mondialement."}
		]
	},
	"PRODUCTION": {
		"title": "Production",
		"icon": "▦",
		"subtitle": "Transformez vos innovations en produits.",
		"stages": [
			{"name":"Atelier de montage", "desc":"Assemblage artisanal à petite échelle."},
			{"name":"Petite unité", "desc":"Une première ligne d'assemblage simplifiée."},
			{"name":"Usine en croissance", "desc":"Plus de capacité et d'automatisation."},
			{"name":"Production avancée", "desc":"Lignes optimisées et contrôle qualité renforcé."},
			{"name":"Usine intelligente", "desc":"Robotique et production à grande échelle."}
		]
	},	"MARKET": {
		"title": "Marché & Vente",
		"icon": "↗",
		"subtitle": "Faites connaître vos produits au monde.",
		"stages": [
			{"name":"Coin commercial", "desc":"Vos premiers contacts et premiers clients."},
			{"name":"Petit bureau", "desc":"Une base commerciale prend forme."},
			{"name":"Équipe vente", "desc":"Une équipe dédiée et des campagnes ciblées."},
			{"name":"Développement", "desc":"Une présence nationale et des partenaires."},
			{"name":"Expansion mondiale", "desc":"Une marque reconnue dans le monde entier."}
		]
	},
	"TEAM": {
		"title": "Équipe / RH",
		"icon": "●",
		"subtitle": "Construisez une équipe qui grandit avec l'entreprise.",
		"stages": [
			{"name":"Noyau fondateur", "desc":"Une petite équipe porte tout le projet."},
			{"name":"Petite équipe", "desc":"Les premiers renforts structurent le quotidien."},
			{"name":"Équipe structurée", "desc":"Des rôles clairs et un vrai management."},
			{"name":"Pôle RH", "desc":"Recrutement, formation et organisation dédiés."},
			{"name":"Culture d'entreprise", "desc":"Une grande équipe unie par une vision commune."}
		]
	}
}

func reset_progression():
	achieved_stages = {}
	for sector_id in SECTOR_ORDER:
		var score := _score_for(str(sector_id))
		var raw_stage := _stage_from_score(score, _thresholds_for(str(sector_id)))
		achieved_stages[str(sector_id)] = raw_stage

func evaluate_progression():
	if achieved_stages.is_empty():
		reset_progression()
		return
	for sector_id_value in SECTOR_ORDER:
		var sector_id := str(sector_id_value)
		var score := _score_for(sector_id)
		var raw_stage := _stage_from_score(score, _thresholds_for(sector_id))
		var previous_stage := int(achieved_stages.get(sector_id, raw_stage))
		var new_stage := maxi(previous_stage, raw_stage)
		achieved_stages[sector_id] = new_stage
		if new_stage > previous_stage:
			stage_changed.emit(sector_id, previous_stage, new_stage, get_sector_state(sector_id))

func get_state() -> Dictionary:
	return {"achieved_stages": achieved_stages.duplicate(true)}

func load_state(state: Dictionary):
	achieved_stages = {}
	var stored: Dictionary = state.get("achieved_stages", {})
	for sector_id_value in SECTOR_ORDER:
		var sector_id := str(sector_id_value)
		var raw_stage := _stage_from_score(_score_for(sector_id), _thresholds_for(sector_id))
		achieved_stages[sector_id] = clampi(int(stored.get(sector_id, raw_stage)), raw_stage, 4)

# Terminologie canonique : un pôle représente une grande zone de l'entreprise
# (Laboratoire, Production, Marché, Équipe). Les noms "sector_*" restent en
# compatibilité avec les anciennes sauvegardes et les anciens appels.
func get_pole_ids() -> Array:
	return SECTOR_ORDER.duplicate()

func get_all_pole_states() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pole_id in get_pole_ids():
		result.append(get_pole_state(str(pole_id)))
	return result

func get_pole_state(pole_id: String) -> Dictionary:
	return get_sector_state(pole_id)

func get_all_states() -> Array[Dictionary]:
	return get_all_pole_states()

func get_sector_state(sector_id: String) -> Dictionary:
	var definition: Dictionary = DEFINITIONS.get(sector_id, {})
	if definition.is_empty():
		return {}
	var score := _score_for(sector_id)
	var thresholds := _thresholds_for(sector_id)
	var raw_stage := _stage_from_score(score, thresholds)
	var stage := maxi(raw_stage, int(achieved_stages.get(sector_id, raw_stage)))
	var stages: Array = definition.get("stages", [])
	var progress := _progress_to_next(score, thresholds, stage)
	return {
		"id": sector_id,
		"title": str(definition.get("title", sector_id)),
		"icon": str(definition.get("icon", "•")),
		"subtitle": str(definition.get("subtitle", "")),
		"stage": stage,
		"stage_name": str(stages[stage].get("name", "")),
		"stage_desc": str(stages[stage].get("desc", "")),
		"progress": progress,
		"score": score,
		"next_hint": _next_hint(sector_id, stage),
		"stages": stages
	}

func _score_for(sector_id: String) -> float:
	match sector_id:
		"LAB": return _research_score()
		"PRODUCTION": return _production_score()
		"MARKET": return _market_score()
		"TEAM": return _team_score()
	return 0.0

func _thresholds_for(sector_id: String) -> Array[float]:
	match sector_id:
		"LAB": return [0.0, 22.0, 45.0, 68.0, 88.0]
		"PRODUCTION": return [0.0, 18.0, 42.0, 67.0, 88.0]
		"MARKET": return [0.0, 18.0, 40.0, 65.0, 86.0]
		"TEAM": return [0.0, 18.0, 42.0, 67.0, 88.0]
	return [0.0, 25.0, 50.0, 75.0, 90.0]
func _research_score() -> float:
	var completed := 0
	var active := 0
	for project in ResearchManager.projects:
		var status := str(project.get("status", ""))
		if status == "COMPLETED": completed += 1
		elif status == "DEVELOPMENT": active += 1
	var cpu_tech := float(ResearchManager.technologies.get("cpu", 0.0))
	return clampf(float(completed) * 17.0 + float(active) * 6.0 + cpu_tech * 0.65, 0.0, 100.0)

func _production_score() -> float:
	var launched := 0
	var total_units := 0
	var max_capacity := 0
	for product in ProductManager.products:
		if str(product.get("status", "")) == "LAUNCHED": launched += 1
		total_units += int(product.get("units_sold_total", 0))
		max_capacity = maxi(max_capacity, int(product.get("production_capacity", 0)))
	var volume_score := minf(float(total_units) / 450.0, 44.0)
	var capacity_score := minf(float(max_capacity) / 90.0, 20.0)
	return clampf(float(launched) * 14.0 + volume_score + capacity_score, 0.0, 100.0)

func _market_score() -> float:
	var launched := 0
	var best_share := 0.0
	for product in ProductManager.products:
		if str(product.get("status", "")) == "LAUNCHED":
			launched += 1
			best_share = maxf(best_share, float(product.get("last_month_share", 0.0)))
	var brand_bonus := maxf(CompanyManager.get_brand_score() - 45.0, 0.0) * 0.55
	return clampf(float(launched) * 9.0 + best_share * 100.0 * 1.15 + brand_bonus, 0.0, 100.0)

func _team_score() -> float:
	var growth := maxi(PersonnelManager.staff.size() - 2, 0)
	var leadership_bonus := 0.0
	for employee in PersonnelManager.staff:
		leadership_bonus += maxf(float(employee.get("leadership", 0)) - 60.0, 0.0) * 0.04
	return clampf(float(growth) * 9.0 + minf(leadership_bonus, 18.0), 0.0, 100.0)
func _stage_from_score(score: float, thresholds: Array[float]) -> int:
	var stage := 0
	for i in range(thresholds.size()):
		if score >= thresholds[i]: stage = i
	return clampi(stage, 0, 4)

func _progress_to_next(score: float, thresholds: Array[float], stage: int) -> float:
	if stage >= 4:
		return 100.0
	var current := thresholds[stage]
	var next := thresholds[stage + 1]
	return clampf((score - current) / maxf(next - current, 1.0) * 100.0, 0.0, 100.0)

func _next_hint(sector_id: String, stage: int) -> String:
	if stage >= 4:
		return "Palier maximum atteint pour cette version."
	match sector_id:
		"LAB":
			return ["Lancez puis terminez vos premiers projets CPU.", "Accumulez du savoir-faire et terminez plusieurs générations.", "Renforcez la R&D et poursuivez les générations CPU.", "Atteignez un niveau technologique de référence."][stage]
		"PRODUCTION":
			return ["Lancez votre premier produit.", "Augmentez les ventes et la capacité mensuelle.", "Industrialisez plusieurs produits avec un volume régulier.", "Atteignez une production de grande échelle."][stage]
		"MARKET":
			return ["Commercialisez votre premier CPU.", "Développez vos ventes et votre part de marché.", "Renforcez la marque et gagnez des parts de marché.", "Imposez Tech Empire comme une marque mondiale."][stage]
		"TEAM":
			return ["Recrutez vos premiers renforts.", "Agrandissez l'équipe et spécialisez les rôles.", "Construisez plusieurs équipes solides.", "Développez une organisation à grande échelle."][stage]
	return "Continuez à développer ce secteur."