extends RefCounted
## Lot C (29/09) : objectifs de Nora — trois à la fois, récompenses, parties déjà avancées.

static func run() -> String:
	SimulationManager.reset_all("CI Objectifs", "CPU", "STANDARD")
	var active := Objectives.active_objectives()
	if active.size() != 3:
		return "Objectives: three objectives (one per track) should be active at start (got %d)" % active.size()
	var ids: Array[String] = []
	for objective in active:
		ids.append(str((objective as Dictionary).get("id", "")))
	if ids != ["P1", "G1", "M1"]:
		return "Objectives: the first objectives should be P1, G1, M1 (got %s)" % str(ids)
	for objective in active:
		if Objectives.reward_label(objective) == "" or Objectives.progress_text(objective) == "":
			return "Objectives: each objective must show its progress and its reward"

	# Passer à 5 personnes : récompense en argent, l'objectif suivant de la piste apparaît.
	Economy.money = 500000
	while PersonnelManager.staff.size() < 5:
		PersonnelManager.generate_candidate("Développement")
		if not PersonnelManager.hire_candidate():
			return "Objectives: could not hire for the staff objective"
	var money_before := Economy.money
	var newly := Objectives.evaluate()
	if newly.size() != 1 or str((newly[0] as Dictionary).get("id", "")) != "G1":
		return "Objectives: reaching 5 people should complete G1 only (got %s)" % str(newly)
	if Economy.money != money_before + 15000:
		return "Objectives: G1 should pay its 15 000 € reward"
	var growth := ""
	for objective in Objectives.active_objectives():
		if str((objective as Dictionary).get("track", "")) == "CROISSANCE":
			growth = str((objective as Dictionary).get("id", ""))
	if growth != "G2":
		return "Objectives: the growth track should move on to G2 (got %s)" % growth
	if not Objectives.evaluate().is_empty():
		return "Objectives: an objective must not be rewarded twice"

	# Sauvegarde.
	var state := Objectives.get_state().duplicate(true)
	Objectives.reset()
	Objectives.load_state(state)
	if not Objectives.is_completed("G1") or Objectives.is_completed("G2"):
		return "Objectives: completed objectives were not restored"

	# Partie d'avant le lot C (pas de clé « objectives ») : ce qui est déjà fait est coché sans récompense.
	Economy.money = 2000000
	var money_old_save := Economy.money
	Objectives.load_state({})
	if not Objectives.is_completed("G1") or not Objectives.is_completed("G2"):
		return "Objectives: an older save should silently tick what is already achieved (5 people, 1 M€)"
	if Economy.money != money_old_save:
		return "Objectives: silently ticked objectives must not pay rewards"
	var growth_after_load := ""
	for objective in Objectives.active_objectives():
		if str((objective as Dictionary).get("track", "")) == "CROISSANCE":
			growth_after_load = str((objective as Dictionary).get("id", ""))
	if growth_after_load != "G3":
		return "Objectives: a track is a path — the older save should now aim for G3 (got %s)" % growth_after_load
	Objectives.reset()
	return ""
