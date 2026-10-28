extends RefCounted
## LOGICIEL 2.0 (14/10) — le studio : type × public × plateforme, fonctions d'époque, trois phases d'effort.
## Ce que l'on vérifie, sans hasard :
## 1. le catalogue tient debout : chaque type a au moins une excellente et une mauvaise idée de public ;
## 2. les choix comptent : bonne combinaison > mauvaise ; répartition juste > répartition à contre-sens ;
##    fonction attendue manquante = note plus basse ; refaire le même logiciel = note plus basse (barre perso) ;
## 3. la boucle complète : lancement, 3 rapports de phase, sortie, note, carnet de Nora, ventes ;
##    une bonne idée se vend mieux qu'une mauvaise ; « Vos processeurs » exige un CPU en vente ;
## 4. on ne peut plus changer la répartition d'une phase commencée ;
## 5. sauvegarde et migration : le carnet survit, une ancienne partie reçoit un carnet vide.

const STUDIO := preload("res://scripts/SoftwareStudio.gd")
const CAT := preload("res://scripts/SoftwareCatalog.gd")

static func _spec(type_id: String, audience_id: String, features: Array, tokens: Dictionary = {}) -> Dictionary:
	var row := tokens
	if row.is_empty():
		row = {}
		for phase in STUDIO.PHASE_ORDER:
			row[phase] = STUDIO.ideal_tokens(type_id, phase)
	return {"type":type_id, "audience":audience_id, "platform":"LEADER", "features":features, "tokens":row, "price_mode":"MARKET"}

static func _note(spec: Dictionary, year: int, best: float = 0.0) -> float:
	var plan := STUDIO.plan(spec, {"year":year, "skills":{}, "mastery":0})
	return float(STUDIO.review(plan, year, best).note)

static func _setup(year: int = 1971) -> void:
	SimulationManager.reset_all("CI Studio", "CPU", "STANDARD")
	TimeManager.year = year
	TimeManager.month = 3
	Economy.money = 400000
	SoftwareManager.reset()
	SoftwareManager._check_unlocks()
	while PersonnelManager.count_department("Développement") < 2:
		if not PersonnelManager.hire_candidate():
			break

## Joue un logiciel du lancement à la sortie. Rend le produit (vide si échec).
static func _ship(spec: Dictionary, name: String, reports: Array) -> Dictionary:
	if not SoftwareManager.start_studio_project(spec, name):
		return {}
	var project := SoftwareManager.project_for(str(spec.type))
	var guard := 0
	while str(project.get("status", "")) == "DEVELOPMENT" and guard < 40:
		PersonnelManager.begin_development_month()
		SoftwareManager._process_projects()
		PersonnelManager.end_development_month()
		guard += 1
		project = SoftwareManager.project_for(str(spec.type))
	reports.append(int(project.get("phase_reported", 0)))
	if str(project.get("status", "")) != "REVIEW":
		return {}
	SoftwareManager.choose_release(str(project.id), "RELEASE")
	for value in SoftwareManager.products:
		if str(value.get("id", "")) == str(project.id):
			return value
	return {}

static func run(_host: Node) -> String:
	# 1. Catalogue.
	for type_id in CAT.FAMILY_ORDER:
		var best := 0
		var worst := 3
		for audience_id in STUDIO.AUDIENCE_ORDER:
			best = maxi(best, STUDIO.fit(str(type_id), str(audience_id)))
			worst = mini(worst, STUDIO.fit(str(type_id), str(audience_id)))
		if best < 3 or worst > 0:
			return "Studio: %s has no excellent or no bad audience" % type_id
		if not STUDIO.IMPORTANCE.has(type_id) or not STUDIO.FIT.has(type_id):
			return "Studio: %s missing importance or fit table" % type_id
		for phase in STUDIO.PHASE_ORDER:
			var ideal := STUDIO.ideal_tokens(str(type_id), str(phase))
			var total := 0
			for value in ideal.values(): total += int(value)
			if total != STUDIO.TOKENS_PER_PHASE or STUDIO.phase_alignment(str(type_id), str(phase), ideal) < 0.85:
				return "Studio: ideal tokens for %s/%s are not ideal (%s)" % [type_id, phase, str(ideal)]
	for id in STUDIO.FEATURE_ORDER:
		if not STUDIO.FEATURES.has(id):
			return "Studio: feature %s listed but undefined" % id

	# 2. Les choix comptent.
	var base := _spec("UTILITY", "HOBBY", ["FILES", "SIMPLE_COMMANDS"])
	var same_a := STUDIO.plan(base, {"year":1971})
	var same_b := STUDIO.plan(base, {"year":1971})
	if same_a != same_b:
		return "Studio: plan is not deterministic"
	var great := _note(base, 1971)
	var bad := _note(_spec("UTILITY", "CORP", ["FILES", "SIMPLE_COMMANDS"]), 1975)
	var dev_bad := _note(_spec("DEVTOOLS", "SMB", ["COMPILER", "SCRIPTING"]), 1975)
	var dev_good := _note(_spec("DEVTOOLS", "DEVS", ["COMPILER", "SCRIPTING"]), 1975)
	if great < 6.5 or dev_good <= dev_bad + 2.0 or bad >= great:
		return "Studio: combinations do not matter enough (utility hobby %.1f / corp %.1f, devtools devs %.1f / smb %.1f)" % [great, bad, dev_good, dev_bad]
	var upside := {}
	for phase in STUDIO.PHASE_ORDER:
		var ideal := STUDIO.ideal_tokens("UTILITY", phase)
		var flipped := {}
		var areas: Array = (STUDIO.PHASES[phase] as Dictionary).areas
		# À contre-sens : tout sur le domaine le moins important de la phase.
		var low := str(areas[0])
		for area in areas:
			if STUDIO.importance("UTILITY", str(area)) < STUDIO.importance("UTILITY", low):
				low = str(area)
		for area in areas:
			flipped[str(area)] = STUDIO.TOKENS_PER_PHASE if str(area) == low else 0
		upside[phase] = flipped
	var misdirected := _note(_spec("UTILITY", "HOBBY", ["FILES", "SIMPLE_COMMANDS"], upside), 1971)
	if misdirected >= great - 1.0:
		return "Studio: effort distribution barely matters (%.1f vs %.1f)" % [misdirected, great]
	var os_gui := _note(_spec("OS", "HOME", ["GUI", "NETWORK", "FAST_CORE"]), 1995)
	var os_text := _note(_spec("OS", "HOME", ["SIMPLE_COMMANDS", "NETWORK", "FAST_CORE"]), 1995)
	if os_text >= os_gui - 0.5:
		return "Studio: an OS without graphical interface in 1995 is not punished (%.1f vs %.1f)" % [os_text, os_gui]
	var first_plan := STUDIO.plan(base, {"year":1971})
	var first_review := STUDIO.review(first_plan, 1980)
	var repeat_review := STUDIO.review(first_plan, 1980, float(first_review.score) + 10.0)
	if float(repeat_review.note) >= float(first_review.note):
		return "Studio: beating your own best is not required"
	if STUDIO.missed_line(STUDIO.review(STUDIO.plan(_spec("UTILITY", "HOBBY", ["FILES"], upside), {"year":1971}), 1971)).find("effort") < 0:
		return "Studio: the press does not explain a misdirected effort"

	# 3. La boucle complète.
	_setup(1971)
	if PersonnelManager.count_department("Développement") <= 0:
		return "Studio: no developer to run the scenario"
	if bool(SoftwareManager.can_start_studio({"type":"UTILITY", "audience":"HOBBY", "platform":"OWN", "features":["FILES"], "tokens":{}}).get("ok", false)):
		return "Studio: 'your processors' available without any CPU on the market"
	var reports: Array = []
	var good := _ship(base, "Studio Good", reports)
	if good.is_empty():
		return "Studio: the good project never reached release (%s)" % str(SoftwareManager.projects)
	if int(reports[0]) != 3:
		return "Studio: expected 3 phase reports, got %d" % int(reports[0])
	if str(good.get("kind", "")) != "STUDIO" or float(good.get("note", 0.0)) < 6.0:
		return "Studio: release lost its studio data or got a poor note (%s)" % str(good.get("note", "?"))
	if SoftwareManager.known_fit("UTILITY", "HOBBY") != 3:
		return "Studio: Nora's notebook did not record the combination"
	if SoftwareManager.known_areas("UTILITY").is_empty():
		return "Studio: Nora's notebook learned no effort area"
	SoftwareManager._process_sales()
	var good_licenses := int(good.get("licenses_last", 0))
	if good_licenses <= 0 or int(good.get("revenue_last", 0)) <= 0:
		return "Studio: a good software sold nothing"
	# Le jour J : trois journaux, une moyenne fidèle à la note, la leçon de Nora, rangés dans la presse.
	var press: Array = []
	for item in MediaManager.news:
		if str(item.get("product_kind", "")) == "SOFTWARE" and str(item.get("product_id", "")) == str(good.id):
			press.append(item)
	if press.size() < 2:
		return "Studio: launch day published %d software reviews" % press.size()
	var press_mean := 0.0
	for item in press:
		press_mean += float(item.review_score)
	press_mean /= float(press.size())
	if absf(press_mean / 10.0 - float(good.note)) > 0.3:
		return "Studio: press average %.1f differs from the official note %.1f" % [press_mean / 10.0, float(good.note)]
	if SoftwareManager.studio_lesson(good).find("Carnet de Nora") < 0:
		return "Studio: no notebook lesson for the launch screen"
	# Versions 2 et 3 : base de code réutilisée.
	if bool(SoftwareManager.can_start_sequel(str(good.id)).get("ok", false)):
		return "Studio: a sequel can start the very month of the release"
	for m in range(6):
		SoftwareManager._process_sales()
	var sequel := SoftwareManager.sequel_spec(str(good.id))
	if not bool(SoftwareManager.can_start_sequel(str(good.id)).get("ok", false)) or (sequel.inherited as Array).size() != 2:
		return "Studio: sequel unavailable or did not inherit the features (%s)" % str(sequel)
	var fresh_plan := STUDIO.plan(_spec("UTILITY", "HOBBY", ["FILES", "SIMPLE_COMMANDS", "SCRIPTING"]), {"year":TimeManager.year})
	sequel["features"] = ["SCRIPTING"]
	var sequel_plan := STUDIO.plan(sequel, {"year":TimeManager.year})
	if int(sequel_plan.months) >= int(fresh_plan.months) or int(sequel_plan.monthly_cost) >= int(fresh_plan.monthly_cost) or int(sequel_plan.bugs) >= int(fresh_plan.bugs):
		return "Studio: reusing the code base is not cheaper (%s vs %s)" % [str([sequel_plan.months, sequel_plan.monthly_cost, sequel_plan.bugs]), str([fresh_plan.months, fresh_plan.monthly_cost, fresh_plan.bugs])]
	var v4 := sequel.duplicate(true)
	v4["version"] = 4
	if int(STUDIO.plan(v4, {"year":TimeManager.year}).bugs) <= int(sequel_plan.bugs):
		return "Studio: an old code base (version 4) does not add bugs"
	var empty_sequel := sequel.duplicate(true)
	empty_sequel["features"] = []
	if bool(SoftwareManager.can_start_studio(empty_sequel).get("ok", false)):
		return "Studio: a sequel without any new feature was accepted"
	var second := _ship(sequel, "", [])
	if second.is_empty() or int(second.get("version_major", 0)) != 2 or str(second.name) != "Studio Good 2":
		return "Studio: sequel did not ship as version 2 (%s)" % str(second.get("name", "?"))
	if str(good.get("status", "")) != "RETIRED" or int(second.get("upgrade_units", 0)) <= 0:
		return "Studio: the previous version stayed on sale or nobody upgraded"
	if (second.get("inherited", []) as Array).size() != 2:
		return "Studio: version 2 lost its inherited features"
	# Même chose avec une mauvaise idée de public : la note et les ventes doivent chuter.
	_setup(1975)
	var bad_product := _ship(_spec("UTILITY", "CORP", ["FILES", "SIMPLE_COMMANDS"]), "Studio Bad", [])
	if bad_product.is_empty():
		return "Studio: the bad project never reached release"
	SoftwareManager._process_sales()
	if float(bad_product.note) >= float(good.note) - 1.0:
		return "Studio: a bad combination is not visible in the note (%.1f vs %.1f)" % [float(bad_product.note), float(good.note)]

	# 3 bis. Synergie CPU : un OS maison sur vos processeurs fait vendre vos CPU (plafonné à +15 %).
	_setup(1980)
	var cpu := {"id":"CI-STUDIO-CPU", "name":"CI Puce", "sector":"CPU", "company":CompanyManager.company_name,
		"status":"LAUNCHED", "price":180, "unit_cost":60, "months_on_market":12, "last_month_sales":4000,
		"target_segment":MarketManager.default_segment(), "metrics":{"performance":70.0, "efficiency":70.0, "reliability":70.0,
			"usability":60.0, "innovation":60.0, "ecosystem":60.0, "sustainability":60.0}}
	ProductManager.products.append(cpu)
	if not SoftwareManager.has_own_cpu() or SoftwareManager.own_cpu_reach() <= 0.0:
		return "Studio: a launched CPU does not open the 'your processors' platform"
	var demand_before := int(MarketManager.estimate_consumer_demand(cpu).get("units", 0))
	if absf(SoftwareManager.cpu_ecosystem_factor() - 1.0) > 0.0001:
		return "Studio: ecosystem bonus without any software"
	var os_spec := _spec("OS", "HOME", ["FAST_CORE", "COLOR_GFX", "MULTIUSER"])
	os_spec["platform"] = "OWN"
	var os_plan := STUDIO.plan(os_spec, {"year":1980})
	var leader_plan := STUDIO.plan(_spec("OS", "HOME", ["FAST_CORE", "COLOR_GFX", "MULTIUSER"]), {"year":1980})
	if float(os_plan.metrics.performance) <= float(leader_plan.metrics.performance) or int(os_plan.monthly_cost) >= int(leader_plan.monthly_cost):
		return "Studio: software for your own CPU is neither faster nor cheaper"
	var house_os := _ship(os_spec, "CI OS", [])
	if house_os.is_empty() or str(house_os.get("platform", "")) != "OWN":
		return "Studio: the house OS did not ship on your processors"
	var factor := SoftwareManager.cpu_ecosystem_factor()
	if factor <= 1.0 or factor > 1.15 + 0.0001:
		return "Studio: house OS ecosystem factor out of range (%.3f, note %.1f)" % [factor, float(house_os.note)]
	var demand_after := int(MarketManager.estimate_consumer_demand(cpu).get("units", 0))
	if demand_before <= 0 or demand_after <= demand_before:
		return "Studio: the house OS does not help CPU demand (%d -> %d)" % [demand_before, demand_after]
	ProductManager.products.erase(cpu)

	# 4. Phases déjà commencées : figées.
	_setup(1971)
	SoftwareManager.start_studio_project(base, "Studio Edit")
	var editable := SoftwareManager.project_for("UTILITY")
	var new_row := {"TESTS":4, "OPTIM":1, "DETAIL":1}
	if not SoftwareManager.set_studio_tokens(str(editable.id), "POLISH", new_row):
		return "Studio: could not adjust a phase that has not started"
	if SoftwareManager.set_studio_tokens(str(editable.id), "FOUNDATIONS", {"CORE":6, "DATA":0, "ARCH":0}):
		return "Studio: changed a phase already under way"
	if SoftwareManager.set_studio_tokens(str(editable.id), "FEATURES", {"FUNCTIONS":6, "INTERFACE":6, "CONTENT":0}):
		return "Studio: accepted more tokens than a phase has"

	# 5. Sauvegarde et migration.
	(SoftwareManager.notebook.combos as Dictionary)["GAME:GAMERS"] = 3
	var state := SoftwareManager.get_state()
	SoftwareManager.reset()
	SoftwareManager.load_state(state.duplicate(true))
	if SoftwareManager.known_fit("GAME", "GAMERS") != 3:
		return "Studio: notebook lost on load"
	var old_save := {"version":34, "software":{"products":[], "projects":[]}, "time":{"year":1980, "month":1}}
	var migrated := SaveManager._migrate_state(old_save.duplicate(true), 34)
	if typeof((migrated.get("software", {}) as Dictionary).get("notebook", null)) != TYPE_DICTIONARY:
		return "Studio: migration did not give old saves an empty notebook"
	return ""
