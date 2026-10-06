extends RefCounted
## Petites animations réutilisables (« juice ») : apparitions, pulsations, compteurs.
## Toutes sont sans effet si le nœud n'est pas dans l'arbre (tests, écrans cachés).

static var reduced_motion := false

static func pop_in(node: Control, duration: float = 0.18) -> void:
	if node == null or not node.is_inside_tree() or reduced_motion:
		return
	node.pivot_offset = node.size * 0.5
	node.modulate.a = 0.0
	node.scale = Vector2(0.94, 0.94)
	var tween := node.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	tween.tween_property(node, "scale", Vector2.ONE, duration)

static func fade_in(node: CanvasItem, duration: float = 0.2) -> void:
	if node == null or not node.is_inside_tree() or reduced_motion:
		return
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, duration)

static func slide_in(node: Control, offset: Vector2, duration: float = 0.25) -> void:
	if node == null or not node.is_inside_tree() or reduced_motion:
		return
	var target := node.position
	node.position = target + offset
	node.modulate.a = 0.0
	var tween := node.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", target, duration)
	tween.tween_property(node, "modulate:a", 1.0, duration)

## Pulsation en boucle (repère qui réclame l'attention). Renvoie le Tween pour pouvoir l'arrêter.
static func pulse_forever(node: Control, amount: float = 0.12, period: float = 0.9) -> Tween:
	if node == null or not node.is_inside_tree() or reduced_motion:
		return null
	node.pivot_offset = node.size * 0.5
	var tween := node.create_tween().set_loops()
	tween.tween_property(node, "scale", Vector2.ONE * (1.0 + amount), period * 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2.ONE, period * 0.5).set_trans(Tween.TRANS_SINE)
	return tween

static func stop_pulse(node: Control, tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
	if node != null:
		node.scale = Vector2.ONE

## Compteur qui défile d'une valeur à l'autre ; formatter(value: float) -> String.
static func count_label(label: Label, from_value: float, to_value: float, formatter: Callable, duration: float = 0.6) -> Tween:
	if label == null:
		return null
	if reduced_motion or not label.is_inside_tree() or is_equal_approx(from_value, to_value):
		label.text = formatter.call(to_value)
		return null
	var tween := label.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: float): label.text = formatter.call(value), from_value, to_value, duration)
	return tween
