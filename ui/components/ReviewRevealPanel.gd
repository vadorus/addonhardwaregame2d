extends PanelContainer
## Moment « la presse a testé votre produit » : les notes arrivent une par une, façon Game Dev Tycoon.

signal continue_requested

const LOOK := preload("res://ui/WorkshopStyle.gd")
const JUICE := preload("res://ui/Juice.gd")
const REVEAL_STEP := 0.7

var _title: Label
var _subtitle: Label
var _cards: VBoxContainer
var _verdict: Label
var _continue: Button
var _reviews: Array = []
var _revealed := 0

func _ready() -> void:
	custom_minimum_size = Vector2(520, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffaf1")
	style.border_color = Color("d9822b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 22)
	style.shadow_color = Color(0.1, 0.05, 0.0, 0.35)
	style.shadow_size = 12
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var kicker := LOOK.eyebrow("LA PRESSE A TESTÉ")
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	_title = LOOK.label("", 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_subtitle = LOOK.muted_label("", 13)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_subtitle)
	_cards = VBoxContainer.new()
	_cards.add_theme_constant_override("separation", 8)
	box.add_child(_cards)
	_verdict = LOOK.label("", 16)
	_verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_verdict)
	_continue = Button.new()
	_continue.text = "Continuer"
	LOOK.button_style(_continue, true)
	_continue.pressed.connect(func(): continue_requested.emit())
	box.add_child(_continue)

## reviews : [{source_name, channel_label, score (0-100), headline}] ; other_models : autres modèles de la gamme testés.
func show_reviews(product_name: String, reviews: Array, other_models: int = 0) -> void:
	_reviews = reviews.duplicate(true)
	_revealed = 0
	_title.text = product_name
	_subtitle.text = "%d média(s) ont publié leur test." % _reviews.size()
	if other_models > 0:
		_subtitle.text += " %d autre(s) modèle(s) de la gamme ont aussi été testés : détails dans Presse & médias." % other_models
	_verdict.text = ""
	_continue.disabled = true
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for review_value in _reviews:
		var review: Dictionary = review_value
		var card := _review_card(review)
		card.modulate.a = 0.0
		_cards.add_child(card)
	if is_inside_tree():
		_reveal_next()
	else:
		reveal_all()

func reveal_all() -> void:
	for card in _cards.get_children():
		(card as CanvasItem).modulate.a = 1.0
	_revealed = _reviews.size()
	_show_verdict()

func revealed_count() -> int:
	return _revealed

func verdict_text() -> String:
	return _verdict.text

static func score_out_of_ten(score: float) -> int:
	return clampi(roundi(score / 10.0), 1, 10)

func _reveal_next() -> void:
	if _revealed >= _reviews.size():
		_show_verdict()
		return
	var card := _cards.get_child(_revealed) as Control
	JUICE.pop_in(card, 0.22)
	var score := score_out_of_ten(float((_reviews[_revealed] as Dictionary).get("score", 50.0)))
	if get_node_or_null("/root/SoundManager") != null:
		SoundManager.play("review", 0.9 + 0.03 * score)
	_revealed += 1
	get_tree().create_timer(REVEAL_STEP).timeout.connect(_reveal_next)

func _show_verdict() -> void:
	if _reviews.is_empty():
		_verdict.text = "Aucun test publié pour l'instant."
		_continue.disabled = false
		return
	var total := 0.0
	for review_value in _reviews:
		total += float((review_value as Dictionary).get("score", 50.0))
	var average := total / float(_reviews.size())
	var mean_ten := average / 10.0
	var words := "Accueil difficile : les tests pointent des faiblesses."
	var sound := "review_bad"
	if mean_ten >= 8.0:
		words = "Triomphe ! La presse est conquise."
		sound = "review_good"
	elif mean_ten >= 6.5:
		words = "Bon accueil : le produit convainc."
		sound = "review_good"
	elif mean_ten >= 5.0:
		words = "Accueil correct, sans enthousiasme."
		sound = "review"
	_verdict.text = "Moyenne %.1f/10 — %s" % [mean_ten, words]
	_continue.disabled = false
	if is_inside_tree():
		JUICE.pop_in(_verdict, 0.25)
		if get_node_or_null("/root/SoundManager") != null:
			SoundManager.play(sound)

func _review_card(review: Dictionary) -> Control:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f8efe2")
	style.border_color = Color("e5d4ba")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 10)
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var score := score_out_of_ten(float(review.get("score", 50.0)))
	var badge := Label.new()
	badge.text = str(score)
	badge.custom_minimum_size = Vector2(52, 52)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 24)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("10a34c") if score >= 7 else (Color("d9822b") if score >= 5 else Color("c0392b"))
	badge_style.set_corner_radius_all(26)
	badge.add_theme_stylebox_override("normal", badge_style)
	row.add_child(badge)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)
	text_box.add_child(LOOK.label("%s • %s" % [str(review.get("source_name", "Presse")), str(review.get("channel_label", ""))], 14))
	var headline := LOOK.muted_label("« %s »" % str(review.get("headline", "")), 13)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(headline)
	var comparison_summary := str(review.get("comparison_summary", ""))
	if comparison_summary != "":
		var comparison_label := LOOK.muted_label(comparison_summary, 12)
		comparison_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_box.add_child(comparison_label)
	return card
