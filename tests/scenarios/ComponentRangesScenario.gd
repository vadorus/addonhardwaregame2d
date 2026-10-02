extends RefCounted
## V0.10 / Gammes (2/10) — mémoire, alimentations, boîtiers. Vérifie :
## - l'ouverture des marchés à leur date (mémoire après le premier CPU ou en 1974, alimentations 1977, boîtiers 1981) ;
## - les unités de l'époque (64 Ko en 1982, 4 Go en 2010) ;
## - la fiche d'impact : chaque flèche annonce exactement ce que l'aperçu complet calcule ;
## - la fidélité : la note annoncée est la note obtenue, les ventes estimées sont les ventes du premier mois ;
## - le vieillissement, le retrait, les rivaux qui sortent de nouveaux modèles, la sauvegarde.

const CAT := preload("res://scripts/ComponentCatalog.gd")

static func _next_month() -> void:
	TimeManager.month += 1
	if TimeManager.month > 12:
		TimeManager.month = 1
		TimeManager.year += 1

static func _freeze_rivals() -> void:
	for rival_id in ComponentManager.rival_state.keys():
		(ComponentManager.rival_state[rival_id] as Dictionary)["next_f"] = 9999.0

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Gammes", "CPU", "STANDARD")
	CompanyManager.created = true
	Economy.money = 5_000_000
	# 1. Ouverture des marchés.
	ComponentManager._check_unlocks()
	if ComponentManager.is_open("MEMORY"):
		return "Ranges: memory must not open in 1971 without a CPU on sale"
	TimeManager.year = 1974
	ComponentManager._check_unlocks()
	if not ComponentManager.is_open("MEMORY") or ComponentManager.is_open("PSU") or ComponentManager.is_open("CASE"):
		return "Ranges: in 1974 only memory should be open"
	if ComponentManager.active_rivals("MEMORY").size() != 3:
		return "Ranges: 1974 memory market should have 3 rivals (got %d)" % ComponentManager.active_rivals("MEMORY").size()
	# 2. Unités d'époque.
	if CAT.level_text("MEMORY", "capacity", 3.0, 1982) != "barrette de 64 Ko" or CAT.level_text("MEMORY", "capacity", 3.0, 2010) != "barrette de 4 Go":
		return "Ranges: era units wrong (%s / %s)" % [CAT.level_text("MEMORY", "capacity", 3.0, 1982), CAT.level_text("MEMORY", "capacity", 3.0, 2010)]
	if CAT.level_text("MEMORY", "capacity", 3.0, 1975) != "puces de 4 Kbit":
		return "Ranges: 1975 chip capacity should read 4 Kbit (got %s)" % CAT.level_text("MEMORY", "capacity", 3.0, 1975)
	# 3. Fiche d'impact : sans expérience, pas au-dessus du standard.
	var levels := CAT.default_levels("MEMORY")
	var blocked := ComponentManager.step_preview("MEMORY", levels, "MARKET", "OEM", "capacity", 1)
	if bool(blocked.get("possible", true)):
		return "Ranges: level 4 must require experience"
	ComponentManager.family_state("MEMORY")["mastery"] = 2
	_freeze_rivals()
	var step := ComponentManager.step_preview("MEMORY", levels, "MARKET", "OEM", "capacity", 1)
	var texts: Array[String] = []
	for chip_value in step.get("chips", []):
		texts.append("%s|%s" % [str((chip_value as Dictionary).text), str((chip_value as Dictionary).good)])
	var joined := " ".join(texts)
	if not joined.contains("Capacité ▲▲▲|true") or not joined.contains("Fiabilité ▼") or not joined.contains("€/unité +3,1 €|false") or not joined.contains("+1 mois|false"):
		return "Ranges: capacity +1 chips wrong (%s)" % joined
	var before := ComponentManager.preview("MEMORY", levels, "MARKET", "OEM")
	var after_levels := levels.duplicate()
	after_levels["capacity"] = 4
	var after := ComponentManager.preview("MEMORY", after_levels, "MARKET", "OEM")
	if absf(float(after.scores.capacity) - float(before.scores.capacity) - 15.0) > 0.01 or absf(float(after.scores.reliability) - float(before.scores.reliability) + 5.0) > 0.01:
		return "Ranges: one capacity step should be +15 capacity / -5 reliability"
	if int(after.months) != int(before.months) + 1:
		return "Ranges: one capacity step should add one month"
	# 4. Développement puis sortie : la note annoncée est la note obtenue.
	var target_levels := {"capacity":5, "speed":3, "reliability":4, "efficiency":3}
	var promise := ComponentManager.preview("MEMORY", target_levels, "LOW", "SERVER")
	Economy.expense_breakdown = {}
	if not ComponentManager.start_project("MEMORY", target_levels, "LOW", "SERVER", "Mémo CI"):
		return "Ranges: project should start (%s)" % str(ComponentManager.can_start("MEMORY", target_levels))
	if ComponentManager.start_project("MEMORY", target_levels, "LOW", "SERVER"):
		return "Ranges: only one project per family at a time"
	var months := int(promise.months)
	var launched := {}
	for i in range(months):
		ComponentManager.process_month()
		if not ComponentManager.active_products("MEMORY").is_empty():
			launched = ComponentManager.active_products("MEMORY")[0]
			break
		_next_month()
	if launched.is_empty():
		return "Ranges: product should launch after %d months" % months
	var charged := int(Economy.expense_breakdown.get("Développement — Mémoire", 0))
	if charged != Economy.quoted_expense(int(promise.monthly_cost), "Développement — Mémoire") * months:
		return "Ranges: development cost charged %d, announced %d x %d" % [charged, int(promise.monthly_cost), months]
	if absf(float(launched.review) - float((promise.review as Dictionary).score)) > 0.001:
		return "Ranges: announced review %.1f != real review %.1f" % [float((promise.review as Dictionary).score), float(launched.review)]
	var sold := int(launched.get("units_last", 0))
	if sold <= 0 or absi(sold - int(promise.est_units)) > maxi(int(float(promise.est_units) * 0.02), 2):
		return "Ranges: first month sales %d should match the estimate %d" % [sold, int(promise.est_units)]
	if ComponentManager.mastery("MEMORY") != 2:
		return "Ranges: launches only teach up to mastery 2"
	if ComponentManager.pop_reveal().is_empty():
		return "Ranges: the launch must queue a reveal"
	if not Economy.income_breakdown.has("Ventes — Mémoire"):
		return "Ranges: memory sales must appear in the income breakdown"
	# 5. Vieillissement : trois ans plus tard, le modèle est dépassé et se vend moins.
	var fresh := ComponentManager.freshness(launched)
	var share_now := float(launched.share_last)
	TimeManager.year += 3
	_freeze_rivals()
	if ComponentManager.freshness(launched) >= fresh - 20.0:
		return "Ranges: a 3-year-old memory should be much less fresh"
	# 6. Les rivaux sortent de nouveaux modèles à leur rythme : le vieux modèle perd sa place.
	for rival_id in ComponentManager.rival_state.keys():
		(ComponentManager.rival_state[rival_id] as Dictionary)["next_f"] = 0.0
	var before_count := ComponentManager.rival_products.size()
	ComponentManager._process_rivals()
	if ComponentManager.rival_products.size() <= before_count or ComponentManager.active_rivals("MEMORY").size() != 3:
		return "Ranges: rivals should replace their models (one active each)"
	ComponentManager._process_sales()
	if float(launched.share_last) >= share_now * 0.5:
		return "Ranges: an old model facing new rivals should lose most of its share (%.3f -> %.3f)" % [share_now, float(launched.share_last)]
	# 7. Marchés suivants.
	TimeManager.year = 1977
	ComponentManager._check_unlocks()
	if not ComponentManager.is_open("PSU") or ComponentManager.is_open("CASE"):
		return "Ranges: power supplies open in 1977, cases later"
	TimeManager.year = 1981
	ComponentManager._check_unlocks()
	if not ComponentManager.is_open("CASE"):
		return "Ranges: cases open in 1981"
	# 8. Sauvegarde : aller-retour JSON.
	var state: Dictionary = JSON.parse_string(JSON.stringify(ComponentManager.get_state()))
	var product_count := ComponentManager.products.size()
	ComponentManager.load_state(state)
	if ComponentManager.products.size() != product_count or not ComponentManager.is_open("CASE") or ComponentManager.mastery("MEMORY") != 2:
		return "Ranges: save/load round trip lost data"
	var reloaded: Dictionary = ComponentManager.products[0]
	if int(reloaded.levels.capacity) != 5 or ComponentManager.preview("MEMORY", reloaded.levels, "LOW", "SERVER").is_empty():
		return "Ranges: levels must survive a save"
	# Ancienne partie sans gammes.
	ComponentManager.load_state({})
	if ComponentManager.any_open() or not ComponentManager.products.is_empty():
		return "Ranges: an old save must start with closed markets"
	ComponentManager.load_state(state)
	# 9. Retrait.
	if not ComponentManager.retire_product(str(reloaded.id)) or not ComponentManager.active_products("MEMORY").is_empty():
		return "Ranges: retiring a product failed"
	# 10. L'écran se construit (atelier, récapitulatif, pastilles).
	ComponentManager.family_state("PSU")["mastery"] = 1
	var panel: Control = (load("res://ui/components/ComponentsPanel.gd") as Script).new() as Control
	host.add_child(panel)
	panel.call("select_family", "PSU")
	if (panel.get("last_preview") as Dictionary).is_empty():
		host.remove_child(panel)
		panel.queue_free()
		return "Ranges: the designer should compute a preview"
	panel.call("_step", "power", 1)
	var levels_after: Dictionary = (panel.call("draft", "PSU") as Dictionary).levels
	host.remove_child(panel)
	panel.queue_free()
	if int(levels_after.power) != 4:
		return "Ranges: + on power should raise it to 4 with mastery (got %d)" % int(levels_after.power)
	SimulationManager.reset_all("CI Fin gammes", "CPU", "STANDARD")
	if ComponentManager.any_open() or not ComponentManager.products.is_empty():
		return "Ranges: a new game must reset ranges"
	return ""
