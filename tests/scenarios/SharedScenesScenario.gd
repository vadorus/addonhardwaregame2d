extends RefCounted

const HEADER := preload("res://ui/components/SceneHeader.gd")
const LAB := preload("res://ui/components/LabBoard.gd")
const PRESS := preload("res://ui/components/PressBoard.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Scènes communes", "CPU", "STANDARD")
	var lab := LAB.new()
	var press := PRESS.new()
	host.add_child(lab)
	host.add_child(press)
	var error := _check(lab, press)
	lab.queue_free()
	press.queue_free()
	return error

static func _check(lab: Control, press: Control) -> String:
	var lab_scene: Control = lab.get("scene")
	var press_scene: Control = press.get("scene")
	if lab_scene.get_script() != HEADER or press_scene.get_script() != HEADER:
		return "Shared scenes: Lab and Press must use SceneHeader"
	var sent := {}
	lab.connect("board_action", func(action: Dictionary): sent.merge(action, true))
	(lab_scene.get("_button") as Button).emit_signal("pressed")
	if str(sent.get("type", "")) != "OPEN_STEPPER" or not str(lab_scene.call("hero_button_text")).contains("Concevoir"):
		return "Shared scenes: the empty lab lost its design action"
	var project := {"id":"HEADER-CPU", "name":"Nova témoin", "sector":"CPU", "status":"DEVELOPMENT", "phase_index":2, "phase_progress":37.0}
	ResearchManager.projects = [project]
	for state in ["RUNNING", "DECISION", "DIRECTIVE"]:
		project["pending_decision"] = {"type":"PROTOTYPE_REVIEW"} if state == "DECISION" else {}
		project["cockpit_directive_pending"] = {"context_version":1, "title":"Le compromis thermique"} if state == "DIRECTIVE" else {}
		lab.call("refresh")
		sent.clear()
		(lab_scene.get("_button") as Button).emit_signal("pressed")
		var expected: String = {"RUNNING":"SHOW_PROJECTS", "DECISION":"PROJECT_DECISION", "DIRECTIVE":"OPEN_COCKPIT"}[state]
		if str(sent.get("type", "")) != expected or not str(lab_scene.call("hero_value_text")).contains("Nova témoin"):
			return "Shared scenes: the %s lab action or project name changed" % state
		var progress: ProgressBar = lab_scene.get("_progress")
		if not progress.visible or not is_equal_approx(progress.value, 37.0):
			return "Shared scenes: project progress disappeared"
	ResearchManager.projects = []
	lab.call("refresh")
	if (lab_scene.get("_progress") as Control).visible:
		return "Shared scenes: progress remains on the empty workbench"
	# Presse : note, portrait, couleur et retour à l'état vide, sans bouton parasite.
	for score in [82.0, 55.0, 30.0]:
		MediaManager.news = [{"headline":"Test témoin", "product_name":"Nova témoin", "source_name":"Byte", "review_score":score, "month":3, "year":1976}]
		press.call("refresh", true)
		var expected_score: String = {82.0:"8,2/10", 55.0:"5,5/10", 30.0:"3/10"}[score]
		if str(press_scene.call("hero_value_text")) != expected_score or not str(press_scene.call("line_text")).contains("Nova témoin") or str(press_scene.call("hero_button_text")) != "":
			return "Shared scenes: Press score, text or button changed"
		var face: TextureRect = press_scene.get("_face")
		if face.texture.resource_path != (PRESS.NORA_OK if score >= 65.0 else PRESS.NORA_HMM):
			return "Shared scenes: Nora's expression no longer follows the score"
	MediaManager.news = []
	press.call("refresh", true)
	if str(press_scene.call("hero_value_text")) != "—" or str(press_scene.call("hero_caption_text")) != "pas encore de test":
		return "Shared scenes: empty Press state is incorrect"
	return ""
