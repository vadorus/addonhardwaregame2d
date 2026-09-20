extends Node

signal patents_changed
signal patent_candidate_created(candidate)

var candidates: Array = []
var patents: Array = []
var _next_id := 1

func reset():
	candidates = []
	patents = []
	_next_id = 1
	patents_changed.emit()

func create_candidate(project: Dictionary):
	var metrics: Dictionary = project.get("final_metrics", {})
	if float(metrics.get("innovation", 0.0)) < 68.0:
		return
	var candidate := {
		"id":"PATC-%03d" % _next_id,
		"project_id":str(project.id),
		"title":"Procédé %s — %s" % [GameData.SECTORS.get(str(project.sector), {}).get("label", str(project.sector)), str(project.focus_label)],
		"strength":int(clampf(float(metrics.innovation), 1.0, 100.0)),
		"sector":str(project.sector)
	}
	_next_id += 1
	candidates.append(candidate)
	patent_candidate_created.emit(candidate)
	patents_changed.emit()

func file_first_candidate() -> bool:
	if candidates.is_empty() or not Economy.can_afford(8000, "Dépôt de brevet"):
		return false
	var c: Dictionary = candidates.pop_front()
	Economy.add_expense(8000, "Dépôt de brevet")
	c["licensed"] = false
	c["royalty_rate"] = 0.0
	patents.append(c)
	CompanyManager.change_reputation({"innovation":2.0,"prestige":0.6})
	CompanyManager.add_alert("Brevet déposé : %s" % str(c.title))
	patents_changed.emit()
	return true

func toggle_license_first():
	if patents.is_empty():
		return
	patents[0].licensed = not bool(patents[0].licensed)
	patents[0].royalty_rate = 0.025 if bool(patents[0].licensed) else 0.0
	patents_changed.emit()

func process_month():
	var royalties := 0
	for patent in patents:
		if bool(patent.get("licensed", false)):
			royalties += 600 + int(patent.get("strength", 50)) * 18
	if royalties > 0:
		Economy.add_income(royalties, "Licences de brevets")

func get_state() -> Dictionary:
	return {"candidates":candidates,"patents":patents,"next_id":_next_id}

func load_state(state: Dictionary):
	candidates = state.get("candidates", []).duplicate(true)
	patents = state.get("patents", []).duplicate(true)
	_next_id = int(state.get("next_id", 1))
	patents_changed.emit()
