extends Control
## L'équipe vit dans le garage (retour d'Alexandre, 28/09 : « on dirait des lignes d'écriture »).
## - chaque salarié est assis à un poste du décor, Nora est debout près du tableau ;
## - pendant un projet, ils travaillent et des bulles de points montent vers la carte projet
##   (comme Game Dev Tycoon), au rythme réel de l'avancement ;
## - de temps en temps quelqu'un dit quelque chose d'utile, tiré de l'état du jeu ;
## - toucher un personnage : sa bulle + une petite fiche (rôle, compétence, moral).

signal member_opened(member_id: String)

const MEMBER := preload("res://ui/CrewMember.gd")
const TREE := preload("res://scripts/ResearchTree.gd")
const UI := preload("res://ui/UiKit.gd")

## Postes du décor : un jeu de postes par palier de locaux (V0.10 K1, ui/WorkplaceArt.gd).
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")
const INTERACTIONS := preload("res://scripts/Interactions.gd")

var art_rect := Rect2()
var project_target := Vector2.ZERO   # où volent les bulles de points (carte projet)
var _members: Array = []
var _bubble: PanelContainer
var _bubble_label: Label
var _bubble_owner: Control
var _bubble_time := 0.0
var _chat_timer := 8.0
var _point_timer := 0.0
var _card: PanelContainer
var _card_box: VBoxContainer
var _last_staff_key := ""
var _tier := 0
var _celebrate_time := 0.0
var _last_launch_count := -1
var _work_events: Array = []
const JUICE := preload("res://ui/Juice.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ResearchManager.work_event.connect(_queue_work_event)
	SoftwareManager.work_event.connect(_queue_work_event)
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override("panel", UI.stylebox(Color("fffaf1"), 12, 2, Color("d9822b"), 8))
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.visible = false
	_bubble.z_index = 5
	_bubble_label = UI.label("", 14)
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.custom_minimum_size.x = 220
	_bubble.add_child(_bubble_label)
	add_child(_bubble)
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UI.stylebox(Color("fffaf1"), 12, 1, Color("e5d4ba"), 10))
	_card.visible = false
	_card.z_index = 6
	_card_box = VBoxContainer.new()
	_card_box.add_theme_constant_override("separation", 4)
	_card.add_child(_card_box)
	add_child(_card)

## Changement de locaux : chacun rejoint son poste dans le nouveau décor.
func set_workplace_tier(tier: int) -> void:
	var t := WORKPLACE.tier_of(tier)
	if t == _tier:
		return
	_tier = t
	_last_staff_key = ""
	for member in _members.duplicate():
		var id := str(member.get("member_id"))
		if id.begins_with("CLIENT:") or id.begins_with("PRESS:"):
			member.set_meta("at", WORKPLACE.crew_layout(_tier).visitor)
	if CompanyManager.created:
		refresh()
	_place_members()

func workplace_tier() -> int:
	return _tier

func seat_count() -> int:
	return (WORKPLACE.crew_layout(_tier).seats as Array).size()

## Tout le monde saute de joie quelques secondes (lancement d'un CPU…).
func celebrate(duration: float = 5.0) -> void:
	_celebrate_time = duration
	_apply_moods()

func _apply_moods() -> void:
	var mood := "normal"
	if _celebrate_time > 0.0:
		mood = "joie"
	elif CompanyManager.created and Economy.money < 0:
		mood = "inquiet"
	for member in _members:
		member.set("mood", mood)

func set_art_rect(rect: Rect2) -> void:
	art_rect = rect
	_place_members()

## Recrée les personnages quand l'équipe change (embauche, départ).
func refresh() -> void:
	if not CompanyManager.created:
		_clear_members()
		return
	var ids: Array[String] = []
	for employee_value in PersonnelManager.staff:
		ids.append(str((employee_value as Dictionary).get("id", "")))
	var key := ",".join(ids)
	if key != _last_staff_key:
		_last_staff_key = key
		_rebuild_members()
	var active := _has_active_work() and TimeManager.time_scale > 0.0
	# Qui veut vous parler ? (« ! » au-dessus de la tête) ; un client en visite attend à la porte.
	var talkers := {}
	var visitor_key := ""
	for item_value in INTERACTIONS.pending():
		var speaker := str((item_value as Dictionary).get("speaker", ""))
		talkers[speaker] = true
		if (speaker.begins_with("CLIENT:") or speaker.begins_with("PRESS:")) and visitor_key == "":
			visitor_key = speaker
	_sync_visitor(visitor_key)
	for member in _members:
		(member as Control).set("working", active and str(member.get("pose")) == "SIT")
		(member as Control).set("alert", talkers.has(str(member.get("member_id"))))
	# Un nouveau CPU lancé : toute l'équipe fait la fête.
	var launches := ProductManager.products.filter(func(p): return str((p as Dictionary).get("status", "")) == "LAUNCHED").size()
	launches += SoftwareManager.products.size()
	if _last_launch_count >= 0 and launches > _last_launch_count:
		_celebrate_time = 5.0
	_last_launch_count = launches
	_apply_moods()

func _sync_visitor(visitor_key: String) -> void:
	var current: Control = null
	for member in _members:
		var member_key := str(member.get("member_id"))
		if member_key.begins_with("CLIENT:") or member_key.begins_with("PRESS:"):
			current = member
	if current != null and str(current.get("member_id")) != visitor_key:
		_members.erase(current)
		current.queue_free()
		current = null
	if current == null and visitor_key != "":
		var is_press := visitor_key.begins_with("PRESS:")
		_add_member({"id":visitor_key, "name":visitor_key.substr(6 if is_press else 7), "role":"Journaliste" if is_press else "Client en visite", "department":"Visiteur",
			"pose":"STAND", "facing":-1.0, "at":WORKPLACE.crew_layout(_tier).visitor, "look":WORKPLACE.PRESS_LOOK if is_press else WORKPLACE.CLIENT_LOOK})
		_place_members()
		if is_visible_in_tree():
			SoundManager.play("notify")

func member_count() -> int:
	return _members.size()

func _clear_members() -> void:
	for member in _members:
		(member as Node).queue_free()
	_members.clear()
	_last_staff_key = ""

func _rebuild_members() -> void:
	_clear_members()
	# R&D et Développement aux postes techniques d'abord.
	var order := {"R&D":0, "Développement":1, "Production":2, "Support":3, "Marketing":4, "Finance":5}
	var staff: Array = PersonnelManager.staff.duplicate()
	staff.sort_custom(func(a, b): return int(order.get(str(a.get("department", "")), 9)) < int(order.get(str(b.get("department", "")), 9)))
	var layout := WORKPLACE.crew_layout(_tier)
	var seats: Array = layout.seats
	var looks := WORKPLACE.staff_looks()
	var used := {}
	for i in range(mini(staff.size(), seats.size())):
		var employee: Dictionary = staff[i]
		var seat: Vector3 = seats[i]
		var id := str(employee.get("id", ""))
		# Chaque salarié garde le même visage ; deux personnes à l'écran ne se ressemblent pas.
		# D'abord parmi les visages bien distincts, puis les variantes.
		var distinct := WORKPLACE.DISTINCT_STAFF_LOOKS.size()
		var pick := absi(hash(id)) % distinct
		for _probe in range(looks.size()):
			if not used.has(looks[pick]):
				break
			pick = (pick + 1) % looks.size()
		used[looks[pick]] = true
		_add_member({"id":id, "name":str(employee.get("name", "")), "role":str(employee.get("role", "")),
			"department":str(employee.get("department", "")), "pose":"SIT", "facing":seat.z, "at":Vector2(seat.x, seat.y), "look":looks[pick]})
	var nora := ExecutiveManager.get_right_hand()
	_add_member({"id":"NORA", "name":str(nora.get("name", "Nora Bernard")), "role":"Bras droit", "department":"Direction",
		"pose":"STAND", "facing":-1.0, "at":layout.nora, "hair":Color("5a3a2a"), "shirt":Color("3f7f8c"), "look":WORKPLACE.NORA_LOOK})
	_place_members()

func _add_member(data: Dictionary) -> void:
	var member := MEMBER.new() as Control
	member.call("setup", data)
	member.set_meta("at", data.at)
	member.connect("tapped", _on_member_tapped)
	add_child(member)
	move_child(member, 0)
	_members.append(member)

func _place_members() -> void:
	if art_rect.size.x <= 0.0:
		return
	var px := art_rect.size.y * float(WORKPLACE.crew_layout(_tier).scale)
	for member_value in _members:
		var member: Control = member_value
		member.call("set_scale_px", px * (1.05 if str(member.get("pose")) == "STAND" else 1.0))
		var at: Vector2 = member.get_meta("at")
		var foot := art_rect.position + Vector2(at.x * art_rect.size.x, at.y * art_rect.size.y)
		member.position = foot - Vector2(member.size.x * 0.5, member.size.y)
		member.z_index = 0
	# Profondeur : celui qui est devant (plus bas à l'écran) est dessiné par-dessus.
	var ordered := _members.duplicate()
	ordered.sort_custom(func(a, b): return float((a.get_meta("at") as Vector2).y) < float((b.get_meta("at") as Vector2).y))
	for i in range(ordered.size()):
		move_child(ordered[i], i)

func _has_active_work() -> bool:
	return not _work_cues().is_empty()

func _work_cues() -> Array:
	var cues: Array = []
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if PersonnelManager.count_department("Développement") > 0 and str(project.get("status", "")) == "DEVELOPMENT" and ResearchManager.cpu_pending_directive(project).is_empty() and (project.get("pending_decision", {}) as Dictionary).is_empty():
			var phase := clampi(int(project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)
			cues.append([str(GameData.PHASES[phase]), Color("d9822b")])
	for value in SoftwareManager.projects:
		var project: Dictionary = value
		if PersonnelManager.count_department("Développement") > 0 and str(project.get("status", "DEVELOPMENT")) in ["DEVELOPMENT", "BETA"] and SoftwareManager.software_pending_directive(project).is_empty():
			var phase := SoftwareManager.software_cockpit_phase(project)
			var label := "Conception" if phase == "PLANNING" else "Code" if phase == "BUILD" else "Tests"
			if str(project.get("kind", "")) in ["PATCH", "UPDATE"] or str(project.get("status", "")) == "BETA":
				label = "Correctif" if str(project.get("kind", "")) == "PATCH" else "Tests" if str(project.get("status", "")) == "BETA" else "Mise à jour"
			cues.append([label, Color("3f7f8c")])
	if PersonnelManager.count_department("Développement") > 0 and not SoftwareManager.activities.is_empty():
		cues.append(["Contrat", Color("3f7f8c")])
	for value in ProductionManager.get_active_jobs():
		if bool((value as Dictionary).get("route_selected", false)):
			cues.append(["Fabrication", Color("2f9e6a")])
	return cues

func _process(delta: float) -> void:
	if _celebrate_time > 0.0:
		_celebrate_time -= delta
		if _celebrate_time <= 0.0:
			_apply_moods()
	if _bubble.visible:
		_bubble_time -= delta
		if _bubble_owner != null and is_instance_valid(_bubble_owner):
			_place_bubble()
		if _bubble_time <= 0.0:
			_bubble.visible = false
			_card.visible = false
	var speed := TimeManager.time_scale
	var active := speed > 0.0 and _has_active_work()
	for member in _members:
		member.set("working", active and str(member.get("pose")) == "SIT")
	if not is_visible_in_tree() or _members.is_empty():
		return
	_chat_timer -= delta
	if speed > 0.0 and _chat_timer <= 0.0:
		_chat_timer = randf_range(14.0, 22.0)
		var talker: Control = _members[randi() % _members.size()]
		say(talker, line_for(talker))
	if (not _work_events.is_empty() or (speed > 0.0 and _has_active_work())) and not JUICE.reduced_motion:
		_point_timer -= delta * maxf(speed, 1.0)
		if _point_timer <= 0.0:
			_point_timer = randf_range(0.9, 1.6)
			var workers: Array = _members.filter(func(m): return str(m.get("pose")) == "SIT")
			if not workers.is_empty():
				_spawn_point(workers[randi() % workers.size()])

## Activity animation, never invented metric gains.
func _spawn_point(member: Control) -> void:
	var cues := _work_cues()
	if cues.is_empty() and _work_events.is_empty():
		return
	var kind: Array = ["", Color("317c88")] if cues.is_empty() else cues[randi() % cues.size()]
	if not _work_events.is_empty():
		var event: Dictionary = _work_events.pop_front()
		kind = [str(event.get("text", "")), Color("b9712e") if str(event.get("kind", "")) == "CPU" else Color("317c88")]
	var pill := Label.new()
	pill.text = str(kind[0])
	pill.add_theme_font_size_override("font_size", 12)
	pill.add_theme_color_override("font_color", Color.WHITE)
	pill.add_theme_stylebox_override("normal", UI.stylebox(kind[1], 10, 0, kind[1], 4))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.z_index = 4
	add_child(pill)
	var start: Vector2 = member.call("head_position") + Vector2(-20, -10)
	pill.position = start
	var target := project_target if project_target != Vector2.ZERO else start + Vector2(0, -80)
	var tween := pill.create_tween()
	tween.tween_property(pill, "position", start + Vector2(randf_range(-12, 12), -26), 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(pill, "position", target, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(pill, "modulate:a", 0.0, 0.9).set_delay(0.5)
	tween.tween_callback(pill.queue_free)

func say(member: Control, text: String, duration: float = 5.0) -> void:
	if text == "" or member == null:
		return
	_bubble_label.text = "%s : %s" % [str(member.get("display_name")).split(" ")[0], text]
	_bubble_owner = member
	_bubble_time = duration
	_bubble.visible = true
	_bubble.reset_size()
	_place_bubble()

func _place_bubble() -> void:
	var head: Vector2 = _bubble_owner.call("head_position")
	var bubble_size := _bubble.get_combined_minimum_size()
	var pos := head + Vector2(-bubble_size.x * 0.5, -bubble_size.y - 18.0)
	pos.x = clampf(pos.x, 8.0, maxf(8.0, size.x - bubble_size.x - 8.0))
	pos.y = maxf(pos.y, 8.0)
	_bubble.position = pos

func _on_member_tapped(member: Control) -> void:
	if bool(member.get("alert")):
		# Cette personne a quelque chose à vous dire : la conversation s'ouvre.
		_bubble.visible = false
		_card.visible = false
		member_opened.emit(str(member.get("member_id")))
		return
	say(member, line_for(member), 7.0)
	_show_card(member)
	member_opened.emit(str(member.get("member_id")))

func _show_card(member: Control) -> void:
	for child in _card_box.get_children():
		_card_box.remove_child(child)
		child.queue_free()
	_card_box.add_child(UI.label(str(member.get("display_name")), 15))
	_card_box.add_child(UI.muted_label(str(member.get("role")), 12))
	var employee := PersonnelManager.get_employee(str(member.get("member_id")))
	if not employee.is_empty():
		for data in [["Compétence", float(employee.get("skill", 0))], ["Moral", float(employee.get("morale", 70.0))]]:
			var meter := UI.meter_row(str(data[0]), "")
			meter.get_child(0).custom_minimum_size.x = 90
			UI.set_meter(meter, float(data[1]))
			meter.custom_minimum_size.x = 250
			_card_box.add_child(meter)
	_card.visible = true
	_card.reset_size()
	var head: Vector2 = member.call("head_position")
	var card_size := _card.get_combined_minimum_size()
	# Du côté où il y a de la place (les cartes projet/actu occupent la droite).
	var card_x := head.x + 40.0 if head.x < size.x * 0.5 else head.x - card_size.x - 40.0
	_card.position = Vector2(clampf(card_x, 8.0, maxf(8.0, size.x - card_size.x - 8.0)), clampf(head.y + 10.0, 8.0, maxf(8.0, size.y - card_size.y - 8.0)))

## Ce que dit un personnage : toujours tiré de l'état réel de la partie.
func line_for(member: Control) -> String:
	var id := str(member.get("member_id"))
	if id.begins_with("CLIENT:"):
		return "Bonjour ! J'aurais une commande à vous proposer, vous avez une minute ?"
	if id.begins_with("PRESS:"):
		return "Bonjour ! Une petite interview sur votre nouveau CPU ?"
	if bool(member.get("alert")):
		return "Vous auriez une minute ? J'ai besoin de vous parler."
	if id == "NORA":
		var focus: Dictionary = get_parent().call("focus_decision") if get_parent() != null and get_parent().has_method("focus_decision") else {}
		if not focus.is_empty():
			return "%s. Le bouton vert vous y emmène." % str(focus.get("title", "Une décision nous attend"))
		return "Tout est sous contrôle. Pensez à la prochaine génération de CPU."
	var employee := PersonnelManager.get_employee(id)
	if not employee.is_empty() and float(employee.get("morale", 70.0)) < 52.0:
		return "Je suis à bout en ce moment… un geste ou une discussion m'aiderait."
	var department := str(member.get("department"))
	if department == "R&D":
		var best: Dictionary = {}
		var best_lane := ""
		var best_gap := 1000.0
		for lane_value in TREE.lanes(3):
			var next: Dictionary = (lane_value as Dictionary).get("next", {})
			if next.is_empty():
				continue
			var gap := float(next.target) - float(next.value)
			if gap > 0.0 and gap < best_gap:
				best_gap = gap
				best = next
				best_lane = str((lane_value as Dictionary).get("title", ""))
		if not best.is_empty():
			return "Encore %.0f points en %s et on débloque « %s ». Regardez l'arbre de recherche !" % [ceilf(best_gap), best_lane, str(best.title)]
		return "La recherche avance bien."
	for value in SoftwareManager.projects:
		var project: Dictionary = value
		if not SoftwareManager.software_pending_directive(project).is_empty():
			return "%s attend votre orientation. Ouvrez Piloter les projets." % str(project.get("name", "Le logiciel"))
		if str(project.get("status", "")) in ["DECISION", "REVIEW"]:
			return "%s attend votre choix dans l'atelier Logiciel." % str(project.get("name", "Le logiciel"))
		return "On travaille sur %s : mois %d/%d." % [str(project.get("name", "le logiciel")), int(project.get("months_done", 0)), int(project.get("months_total", 1))]
	for project_value in ResearchManager.projects:
		var project: Dictionary = project_value
		if str(project.get("status", "")) == "DEVELOPMENT":
			return "%s avance : on en est à « %s »." % [str(project.get("name", "Le CPU")), str(GameData.PHASES[clampi(int(project.get("phase_index", 0)), 0, GameData.PHASES.size() - 1)]).to_lower()]
	for job_value in ProductionManager.get_active_jobs():
		return "La fabrication de %s tourne : %.0f %%." % [str((job_value as Dictionary).get("name", "notre CPU")), float((job_value as Dictionary).get("progress", 0.0))]
	if ProductManager.has_ready_product_to_launch():
		return "Le CPU est prêt. On le lance quand ?"
	return "On attaque le prochain CPU ? J'ai quelques idées."


func _queue_work_event(event: Dictionary) -> void:
	if not is_visible_in_tree() or JUICE.reduced_motion:
		return
	_work_events.append(event.duplicate(true))
	while _work_events.size() > 6:
		_work_events.pop_front()
