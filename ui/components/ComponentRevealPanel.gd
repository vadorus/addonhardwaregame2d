extends PanelContainer
## V0.10 / Gammes — moment « votre composant sort » : illustration, note de la presse qui monte, raisons
## (vert / rouge), et ce qu'il faut retenir pour le prochain modèle.

signal continue_requested
signal open_ranges_requested(family_id: String)

const LOOK := preload("res://ui/WorkshopStyle.gd")
const CAT := preload("res://scripts/ComponentCatalog.gd")
const CHIPS := preload("res://ui/components/ImpactChips.gd")
const ART := preload("res://ui/components/ComponentArt.gd")

var _art: Control
var _kicker: Label
var _title: Label
var _subtitle: Label
var _score: Label
var _verdict: Label
var _reasons: VBoxContainer
var _advice: Label
var _family := "MEMORY"
var _target_score := 0.0
var _shown_score := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(560, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffaf1")
	style.border_color = Color("d9822b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 20)
	style.shadow_color = Color(0.1, 0.05, 0.0, 0.35)
	style.shadow_size = 12
	add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(left)
	_art = ART.new()
	_art.custom_minimum_size = Vector2(170, 150)
	left.add_child(_art)
	_score = LOOK.label("", 44)
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_score)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(340, 0)
	row.add_child(box)
	_kicker = LOOK.eyebrow("NOUVEAU MODÈLE EN VENTE")
	box.add_child(_kicker)
	_title = LOOK.label("", 22)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_subtitle = LOOK.muted_label("", 12)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_subtitle)
	_verdict = LOOK.label("", 15)
	_verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_verdict)
	_reasons = VBoxContainer.new()
	_reasons.add_theme_constant_override("separation", 2)
	box.add_child(_reasons)
	_advice = LOOK.muted_label("", 12)
	_advice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_advice)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)
	var open := Button.new()
	open.text = "Voir la gamme"
	LOOK.button_style(open, false)
	open.pressed.connect(func(): open_ranges_requested.emit(_family))
	buttons.add_child(open)
	var go := Button.new()
	go.text = "Continuer"
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LOOK.button_style(go, true)
	go.pressed.connect(func(): continue_requested.emit())
	buttons.add_child(go)

func show_product(product: Dictionary) -> void:
	_family = str(product.get("family", "MEMORY"))
	_art.call("setup", _family, int(product.get("year", TimeManager.year)), false)
	_title.text = str(product.get("name", ""))
	_subtitle.text = "%s pour « %s » • %s € • %s" % [CAT.family_label(_family), CAT.segment_label(_family, str(product.get("target", "OEM"))),
		_num(float(product.get("price", 0.0))), CAT.price_label(str(product.get("price_mode", "MARKET"))).to_lower()]
	_target_score = float(product.get("review", 0.0))
	_shown_score = 0.0
	_score.text = "0/10"
	var score := _target_score
	_verdict.text = "Un triomphe : la presse en fait sa référence." if score >= 8.5 else ("Bon accueil : un modèle solide." if score >= 7.0 else ("Accueil tiède : il trouvera ses clients, sans plus." if score >= 5.5 else "Accueil sévère : il aura du mal face aux rivaux."))
	_verdict.add_theme_color_override("font_color", Color("2f7a3a") if score >= 7.0 else (Color("a8631f") if score >= 5.5 else Color("b3261e")))
	for child in _reasons.get_children():
		_reasons.remove_child(child)
		child.queue_free()
	var bad: Array[String] = []
	for reason_value in product.get("reasons", []):
		var reason: Dictionary = reason_value
		var line := LOOK.label(("✓ " if bool(reason.good) else "✗ ") + str(reason.text), 13)
		line.add_theme_color_override("font_color", Color("2f7a3a") if bool(reason.good) else Color("b3261e"))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_reasons.add_child(line)
		if not bool(reason.good):
			bad.append(str(reason.text).get_slice(" :", 0).to_lower())
	if not bad.is_empty():
		_advice.text = "Pour le prochain modèle : travaillez %s." % ", ".join(bad)
	elif int(ComponentManager.mastery(_family)) < CAT.LAUNCH_MASTERY_CAP:
		_advice.text = "Ce lancement vous apprend le métier : le prochain modèle pourra aller un cran plus haut."
	else:
		_advice.text = "Les rivaux vont riposter : gardez une longueur d'avance avec le prochain modèle."
	SoundManager.play("launch")
	var tween := create_tween()
	tween.tween_method(_set_score, 0.0, _target_score, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_score(value: float) -> void:
	_shown_score = value
	_score.text = "%s/10" % _num(snappedf(value, 0.1))
	_score.add_theme_color_override("font_color", Color("2f7a3a") if value >= 7.0 else (Color("a8631f") if value >= 5.5 else Color("b3261e")))

static func _num(value: float) -> String:
	if absf(value - round(value)) < 0.05:
		return str(int(round(value)))
	return ("%.1f" % value).replace(".", ",")
