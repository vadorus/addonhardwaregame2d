extends Node
## Atelier logiciel — Logiciel 2.0 (14/10) : le studio remplace l'ancien formulaire à listes déroulantes.
## On vérifie ce que voit le joueur :
## - « Nouveau logiciel » ouvre le studio (4 étapes), sans aucune liste déroulante ni case à cocher ;
## - la barre en direct suit exactement la prévision du gestionnaire, et regarder ne change rien à la partie ;
## - les jetons d'effort restent à 6 par phase, les fonctions ne dépassent pas la limite de l'équipe ;
## - sans développeur : jamais « ~-1 mois », et le lancement est refusé avec une raison ;
## - avant 1978, pas de public « Familles » ; « Vos processeurs » est grisé sans CPU en vente ;
## - lancer depuis le studio crée bien le projet du studio ;
## - sur les formats de téléphone en paysage, le bouton de lancement reste visible et assez grand.

const UI := preload("res://ui/UiKit.gd")
const LIVE := preload("res://scripts/LiveTheme.gd")
const STUDIO := preload("res://scripts/SoftwareStudio.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func settle() -> void:
	for frame in range(8): await get_tree().process_frame

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	LIVE.override = "NONE"
	for mode in ["ACCESSIBLE", "STANDARD", "SIMULATION"]:
		await test_choices(mode)
	# Le jeu est en paysage, étiré en « expand » depuis 1280×720 : la largeur logique ne descend jamais sous 1280.
	for dimensions in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1280, 960)]:
		await test_layout(dimensions)
	if failures.is_empty():
		print("[CI] Software choice preview test passed")
		get_tree().quit(0)
		return
	for failure in failures: push_error("Software choice preview: " + failure)
	get_tree().quit(1)

func workshop(parent: Node) -> Control:
	var node: Control = (load("res://ui/SoftwareWorkshop.gd") as Script).new()
	parent.add_child(node)
	node.call("open")
	node.call("_show_software_choice")
	node.call("_show_product")
	return node

func _all_nodes(root: Node) -> Array:
	var result: Array = [root]
	for child in root.get_children():
		result.append_array(_all_nodes(child))
	return result

func test_choices(mode: String) -> void:
	SimulationManager.reset_all("Preview test", "CPU", mode)
	TimeManager.time_scale = 0.0
	Economy.money = 1000000
	var node := workshop(self)
	await settle()
	var studio: Control = node.call("studio")
	check(bool(node.call("studio_visible")), "Nouveau logiciel does not open the studio")
	check(str(node.call("current_view_name")) == "PRODUCT", "studio view is not reported as PRODUCT")
	for any in _all_nodes(node):
		check(not (any is OptionButton) and not (any is CheckBox) and not (any is SpinBox), "the software screens still use a dropdown, checkbox or spinbox (%s)" % any.get_class())
	var software_before := SoftwareManager.get_state().duplicate(true)
	var economy_before := Economy.get_state().duplicate(true)
	var time_before := TimeManager.get_state().duplicate(true)
	var plan: Dictionary = SoftwareManager.studio_preview(studio.call("current_spec"))
	var live: Label = studio.get("_cost_label")
	check(live.text.contains(UI.money(int(plan.monthly_cash_cost))), "live bar cost differs from the manager forecast (%s)" % mode)
	var time_label: Label = studio.get("_time_label")
	check(time_label.text.contains("~%d mois" % int(plan.calendar_months)), "live bar duration differs from the forecast (%s)" % mode)
	for step in range(4):
		studio.call("go_to_step", step)
		await settle()
	# Fonctions : la limite de l'équipe est respectée.
	var slots := STUDIO.feature_slots(SoftwareManager.mastery(str(studio.get("type_id"))))
	for id in STUDIO.open_features(TimeManager.year):
		if not (studio.get("features") as Array).has(id):
			studio.call("toggle_feature", str(id))
	check((studio.get("features") as Array).size() <= slots, "more features than the team can handle")
	# Jetons : toujours 6 par phase, même en tapant beaucoup sur +.
	for i in range(10):
		studio.call("add_token", "POLISH", "TESTS", 1)
	var polish: Dictionary = (studio.get("tokens") as Dictionary).POLISH
	check(int(polish.TESTS) == STUDIO.TOKENS_PER_PHASE and int(studio.call("free_tokens", "POLISH")) == 0, "tokens are not conserved in a phase (%s)" % str(polish))
	check(SoftwareManager.get_state() == software_before and Economy.get_state() == economy_before and TimeManager.get_state() == time_before, "browsing the studio spends, progresses time or changes the simulation")
	# Avant 1978 : pas de familles. Sans CPU : pas de « Vos processeurs ».
	var audiences := STUDIO.open_audiences(TimeManager.year)
	check(not audiences.has("HOME"), "families are offered before home computers exist")
	check(not bool(SoftwareManager.can_start_studio({"type":"UTILITY", "audience":"HOBBY", "platform":"OWN", "features":["FILES"]}).get("ok", false)), "own CPUs offered without a CPU on sale")
	# Lancer pour de vrai.
	studio.set("features", ["FILES", "SIMPLE_COMMANDS"])
	studio.set("tokens", studio.call("camille_tokens"))
	studio.call("go_to_step", 3)
	(studio.get("_next_button") as Button).pressed.emit()
	await settle()
	check(str(SoftwareManager.project_for("UTILITY").get("kind", "")) == "STUDIO", "launching from the studio did not create a studio project (%s)" % mode)
	node.queue_free()
	await settle()
	# Sans développeur : jamais de durée négative, lancement refusé avec une raison.
	SimulationManager.reset_all("Preview no dev", "CPU", mode)
	Economy.money = 1000000
	for employee in PersonnelManager.staff:
		if str(employee.department) == "Développement": employee.department = "R&D"
	node = workshop(self)
	await settle()
	studio = node.call("studio")
	check(not (studio.get("_time_label") as Label).text.contains("-1"), "a missing team shows a negative duration")
	studio.call("go_to_step", 3)
	(studio.get("_next_button") as Button).pressed.emit()
	await settle()
	check((studio.get("_error_label") as Label).visible and SoftwareManager.projects.is_empty(), "a project can start without developers")
	node.queue_free()
	await settle()

func test_layout(dimensions: Vector2i) -> void:
	SimulationManager.reset_all("Preview layout", "CPU", "STANDARD")
	Economy.money = 1000000
	TimeManager.time_scale = 0.0
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child(viewport)
	var node := workshop(viewport)
	await settle()
	var studio: Control = node.call("studio")
	for step in range(4):
		studio.call("go_to_step", step)
		await settle()
		var content: Control = studio.get("_content")
		check(content.size.x <= dimensions.x, "studio step %d exceeds viewport width at %s" % [step, str(dimensions)])
		var next: Button = studio.get("_next_button")
		check(next.size.y >= 44.0, "next/launch button is too small to touch at " + str(dimensions))
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(next.get_global_rect()), "next/launch button outside the screen at %s step %d" % [str(dimensions), step])
	viewport.queue_free()
	await settle()
