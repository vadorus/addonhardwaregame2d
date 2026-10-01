extends RefCounted
## V0.10 / I6 — petits défauts vus au doigt : champs numériques exacts (143 devenait 141),
## retour d'expérience dégressif à chaque CPU terminé. Le bouton de capacité après lancement est
## vérifié sur le vrai parcours dans workshop_layout_test.

const UI := preload("res://ui/UiKit.gd")

static func run(host: Node) -> String:
	var spin := UI.spin(1, 1000000, 10, 100)
	host.add_child(spin)
	spin.value = 143
	var exact := int(spin.value) == 143
	var arrows := is_equal_approx(spin.custom_arrow_step, 10.0)
	spin.queue_free()
	if not exact:
		return "I6: a stepped number field must keep an exact value (143 became %d)" % int(spin.value)
	if not arrows:
		return "I6: the arrows of a stepped number field must keep their step"
	var first := ResearchManager.completion_lesson_gain(1)
	var third := ResearchManager.completion_lesson_gain(3)
	if not (first > third and third > 0.0):
		return "I6: the lesson of a finished CPU must shrink but stay positive (%.2f then %.2f)" % [first, third]
	return ""
