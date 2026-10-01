extends PanelContainer
## Moment « la presse a testé votre produit » : les notes arrivent une par une, façon Game Dev Tycoon.

signal continue_requested

const LOOK := preload("res://ui/WorkshopStyle.gd")
const JUICE := preload("res://ui/Juice.gd")
const EXPLAIN := preload("res://scripts/ReviewExplainer.gd")
const REVEAL_STEP := 0.7

var _title: Label
var _subtitle: Label
var _cards: VBoxContainer
var _verdict: Label
var _continue: Button
var _body: BoxContainer
var _side: VBoxContainer
var _why: VBoxContainer
var _pleased: Label
var _held_back: Label
var _next: Label
var _sales_hint: Label
var _detail: Label
var _detail_button: Button
var _reviews: Array = []
var _revealed := 0
var _silent := false
## V0.10 : un triomphe dans la presse s'affiche ici, en bandeau, au lieu d'une fenêtre « À la une » de plus.
var _banner: TextureRect
var _kicker: Label
const FRONT_PAGE_ART := "res://assets/art/v010/J3_moments/moment_presse.webp"

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
	_banner = TextureRect.new()
	_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_banner.custom_minimum_size = Vector2(0, 110)
	_banner.clip_contents = true
	_banner.visible = false
	box.add_child(_banner)
	var kicker := LOOK.eyebrow("LA PRESSE A TESTÉ")
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kicker = kicker
	box.add_child(kicker)
	_title = LOOK.label("", 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_subtitle = LOOK.muted_label("", 13)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_subtitle)
	# C2 : sur un écran large (téléphone en paysage), deux colonnes : les tests à gauche, le verdict et
	# « pourquoi » à droite. Sur un écran étroit, tout est empilé.
	_body = HBoxContainer.new()
	_body.add_theme_constant_override("separation", 18)
	box.add_child(_body)
	_cards = VBoxContainer.new()
	_cards.add_theme_constant_override("separation", 8)
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards.custom_minimum_size = Vector2(420, 0)
	_body.add_child(_cards)
	_side = VBoxContainer.new()
	_side.add_theme_constant_override("separation", 8)
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.custom_minimum_size = Vector2(360, 0)
	_body.add_child(_side)
	_verdict = LOOK.label("", 16)
	_verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(_verdict)
	_why = VBoxContainer.new()
	_why.add_theme_constant_override("separation", 4)
	_why.visible = false
	_side.add_child(_why)
	_pleased = _why_label(Color("10703a"))
	_held_back = _why_label(Color("a8431f"))
	_next = _why_label(Color("3b2b1e"))
	_sales_hint = LOOK.muted_label("", 12)
	_sales_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_why.add_child(_sales_hint)
	_detail = LOOK.muted_label("", 12)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.visible = false
	_side.add_child(_detail)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	_side.add_child(buttons)
	_detail_button = Button.new()
	_detail_button.text = "Voir le calcul"
	_detail_button.visible = false
	LOOK.button_style(_detail_button, false)
	_detail_button.pressed.connect(_toggle_detail)
	buttons.add_child(_detail_button)
	_continue = Button.new()
	_continue.text = "Continuer"
	_continue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LOOK.button_style(_continue, true)
	_continue.pressed.connect(func(): continue_requested.emit())
	buttons.add_child(_continue)

func _why_label(color: Color) -> Label:
	var label := LOOK.label("", 13)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	_why.add_child(label)
	return label

## Deux colonnes si l'écran est assez large, sinon une seule (les tests puis le verdict).
func _apply_layout() -> void:
	var wide := not is_inside_tree() or get_viewport_rect().size.x >= 980.0
	var target: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
	if (_body is HBoxContainer) != wide:
		target.add_theme_constant_override("separation", 18 if wide else 10)
		var parent := _body.get_parent()
		var index := _body.get_index()
		for child in _body.get_children():
			_body.remove_child(child)
			target.add_child(child)
		parent.remove_child(_body)
		_body.queue_free()
		parent.add_child(target)
		parent.move_child(target, index)
		_body = target
	else:
		target.free()
	custom_minimum_size = Vector2(900 if wide else 520, 0)
	_cards.custom_minimum_size = Vector2(420 if wide else 0, 0)
	_side.custom_minimum_size = Vector2(360 if wide else 0, 0)

func _toggle_detail() -> void:
	_detail.visible = not _detail.visible
	_why.visible = not _detail.visible
	_detail_button.text = "Retour au résumé" if _detail.visible else "Voir le calcul"

## C2 : le résumé « ce qui a plu / ce qui freine / prochain essai », tiré du vrai calcul des notes.
func _show_why() -> void:
	var summary: Dictionary = EXPLAIN.summarize(_reviews)
	if not bool(summary.get("available", false)):
		_why.visible = false
		_detail_button.visible = false
		return
	var pleased: Array[String] = []
	for row_value in summary.pleased:
		var row: Dictionary = row_value
		pleased.append("%s (%s)" % [str(row.label), EXPLAIN.tenths(float(row.points))])
	var held: Array[String] = []
	for row_value in summary.held_back:
		var row: Dictionary = row_value
		held.append("%s (%s)" % [str(row.label), EXPLAIN.tenths(float(row.points))])
	_pleased.text = "Ce qui a plu : " + (", ".join(pleased) if not pleased.is_empty() else "rien de marquant.")
	_held_back.text = "Ce qui freine : " + (", ".join(held) if not held.is_empty() else "rien de marquant.")
	_next.text = "Prochain essai : " + str(summary.next)
	_sales_hint.text = "La presse ne pèse qu'un peu sur les ventes. Ce qui fait vendre : la valeur de la puce sur son marché face aux rivaux, et son prix (fiche du produit, « Pourquoi ces ventes »)."
	var lines: Array[String] = []
	for review_value in _reviews:
		var review: Dictionary = review_value
		var why: Dictionary = review.get("why", {})
		if not why.is_empty():
			lines.append("%s : %s" % [str(review.get("source_name", "Presse")), EXPLAIN.detail_line(why)])
	_detail.text = "\n".join(lines)
	_detail.visible = false
	_why.visible = true
	_detail_button.visible = not lines.is_empty()
	_detail_button.text = "Voir le calcul"

func why_text() -> String:
	return "\n".join([_pleased.text, _held_back.text, _next.text]) if _why.visible else ""

func detail_text() -> String:
	return _detail.text

## reviews : [{source_name, channel_label, score (0-100), headline}] ; other_models : autres modèles de la gamme testés.
## C2 : revoir plus tard les tests d'un produit (depuis sa fiche) — tout est affiché d'un coup, sans son.
func show_archived(product_name: String, reviews: Array) -> void:
	_silent = true
	show_reviews(product_name, reviews)
	_kicker.text = "LES TESTS DE LA PRESSE"
	_subtitle.text = "Publiés au lancement. Le résumé et le calcul de chaque note sont à droite."

func show_reviews(product_name: String, reviews: Array, other_models: int = 0, front_page: bool = false) -> void:
	_banner.visible = front_page and ResourceLoader.exists(FRONT_PAGE_ART)
	if _banner.visible and _banner.texture == null:
		_banner.texture = load(FRONT_PAGE_ART)
	_kicker.text = "À LA UNE  •  LA PRESSE A TESTÉ" if _banner.visible else "LA PRESSE A TESTÉ"
	_reviews = reviews.duplicate(true)
	_revealed = 0
	_apply_layout()
	_why.visible = false
	_detail.visible = false
	_detail_button.visible = false
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
	if is_inside_tree() and not _silent:
		_reveal_next()
	else:
		reveal_all()
	_silent = false

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
	_verdict.text = "Moyenne %s/10 — %s" % [("%.1f" % mean_ten).replace(".", ","), words]
	_continue.disabled = false
	_show_why()
	if is_inside_tree() and not _silent:
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
	# C2 : l'atout et le frein principaux de ce média, tirés du calcul de SA note.
	var why: Dictionary = review.get("why", {})
	var line := EXPLAIN.card_line(why) if not why.is_empty() else ""
	if line != "":
		var why_label := LOOK.label(line, 12)
		why_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why_label.add_theme_color_override("font_color", Color("6b4a2b"))
		text_box.add_child(why_label)
	return card
