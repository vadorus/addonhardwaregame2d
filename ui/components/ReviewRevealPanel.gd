extends PanelContainer
## Le jour J : les journaux arrivent un par un sur la table (maquette « Le jour J » validée le 07/10).
## Chaque carte : la note dans un rond de couleur, le journal, un titre en italique, deux phrases, le plus et le
## moins. Puis le verdict : moyenne, record ou non face aux lancements précédents, et la leçon du carnet de Nora.
## Le détail du calcul reste à un bouton (« Voir le calcul »).

signal continue_requested

const LOOK := preload("res://ui/WorkshopStyle.gd")
const UI := preload("res://ui/UiKit.gd")
const JUICE := preload("res://ui/Juice.gd")
const EXPLAIN := preload("res://scripts/ReviewExplainer.gd")
const REVEAL_STEP := 1.0
const TROPHY_ART := "res://assets/art/v010/J7_vitrine/trophee_or.png"
const NORA_OK_ART := "res://assets/art/v010/J2_personnages/perso_02_joie.png"
const NORA_HMM_ART := "res://assets/art/v010/J2_personnages/perso_02_reflexion.png"
const FRONT_PAGE_ART := "res://assets/art/v010/J3_moments/moment_presse.webp"
const CREAM := Color("fbf3e2")
const LIGHT := Color("fff8ec")
const ORANGE := Color("f2a541")
const INK := Color("3b2b1e")
const GOOD := Color("2f7f46")
const BAD := Color("b5352d")

var _kicker: Label
var _title: Label
var _subtitle: Label
var _cards: GridContainer
var _verdict_bar: PanelContainer
var _trophy: TextureRect
var _verdict: Label
var _verdict_line: Label
var _nora: TextureRect
var _lesson: Label
var _why: VBoxContainer
var _pleased: Label
var _held_back: Label
var _next: Label
var _sales_hint: Label
var _detail: Label
var _detail_button: Button
var _continue: Button
var _reviews: Array = []
var _revealed := 0
var _silent := false
var _serif: SystemFont
var _serif_italic: SystemFont

func _ready() -> void:
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Noto Serif", "Droid Serif", "Times New Roman", "serif"])
	_serif.font_weight = 700
	_serif_italic = SystemFont.new()
	_serif_italic.font_names = _serif.font_names
	_serif_italic.font_italic = true
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	_kicker = LOOK.label("LE JOUR J", 14, ORANGE)
	_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_kicker)
	_title = LOOK.label("", 30, LIGHT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_subtitle = LOOK.label("", 13, Color("e9d6b8"))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_subtitle)
	_cards = GridContainer.new()
	_cards.columns = 3
	_cards.add_theme_constant_override("h_separation", 18)
	_cards.add_theme_constant_override("v_separation", 14)
	box.add_child(_cards)
	_verdict_bar = PanelContainer.new()
	_verdict_bar.add_theme_stylebox_override("panel", _shadowed(LIGHT, 16, 16))
	box.add_child(_verdict_bar)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 18)
	_verdict_bar.add_child(bar)
	_trophy = _art(TROPHY_ART, Vector2(64, 74))
	bar.add_child(_trophy)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 4)
	bar.add_child(words)
	_verdict = LOOK.label("", 22, INK)
	_verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(_verdict)
	_verdict_line = LOOK.label("", 15, INK)
	_verdict_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(_verdict_line)
	var nora_row := HBoxContainer.new()
	nora_row.add_theme_constant_override("separation", 8)
	words.add_child(nora_row)
	_nora = _art(NORA_HMM_ART, Vector2(28, 38))
	nora_row.add_child(_nora)
	_lesson = LOOK.label("", 14, Color("6b5640"))
	_lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lesson.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nora_row.add_child(_lesson)
	_why = VBoxContainer.new()
	_why.add_theme_constant_override("separation", 3)
	_why.visible = false
	words.add_child(_why)
	_pleased = _why_label(GOOD)
	_held_back = _why_label(Color("a8431f"))
	_next = _why_label(INK)
	_sales_hint = LOOK.muted_label("", 12)
	_sales_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_why.add_child(_sales_hint)
	_detail = LOOK.muted_label("", 12)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.visible = false
	words.add_child(_detail)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(buttons)
	_continue = Button.new()
	_continue.text = "Continuer"
	_continue.custom_minimum_size = Vector2(170, 0)
	LOOK.button_style(_continue, true)
	_continue.add_theme_font_size_override("font_size", 18)
	_continue.pressed.connect(func(): continue_requested.emit())
	buttons.add_child(_continue)
	_detail_button = Button.new()
	_detail_button.text = "Voir le calcul"
	_detail_button.visible = false
	LOOK.button_style(_detail_button, false)
	_detail_button.pressed.connect(_toggle_detail)
	buttons.add_child(_detail_button)

func _art(path: String, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = size
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if ResourceLoader.exists(path):
		rect.texture = load(path)
	return rect

func _shadowed(color: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := UI.stylebox(color, radius, 0, color, padding)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 8)
	return style

func _why_label(color: Color) -> Label:
	var label := LOOK.label("", 13, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_why.add_child(label)
	return label

## Trois journaux côte à côte sur un écran large (téléphone en paysage), un seul par ligne sinon.
func _apply_layout() -> void:
	var width := get_viewport_rect().size.x if is_inside_tree() else 1280.0
	var wide := width >= 980.0
	_cards.columns = clampi(_reviews.size(), 1, 3) if wide else 1
	custom_minimum_size = Vector2(minf(width - 60.0, 1120.0) if wide else minf(width - 24.0, 560.0), 0)

func _toggle_detail() -> void:
	var show_detail := not _detail.visible
	_detail.visible = show_detail
	_why.visible = show_detail
	_detail_button.text = "Retour au résumé" if show_detail else "Voir le calcul"

## C2 : « ce qui a plu / ce qui freine / prochain essai », tiré du vrai calcul des notes.
func _show_why() -> void:
	var summary: Dictionary = EXPLAIN.summarize(_reviews)
	if not bool(summary.get("available", false)):
		_detail_button.visible = false
		_lesson.text = ""
		_nora.visible = false
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
	_nora.visible = true
	_nora.texture = load(NORA_OK_ART if held.is_empty() else NORA_HMM_ART) if ResourceLoader.exists(NORA_HMM_ART) else null
	_lesson.text = "Carnet de Nora : " + str(summary.next)
	var lines: Array[String] = []
	for review_value in _reviews:
		var review: Dictionary = review_value
		var why: Dictionary = review.get("why", {})
		if not why.is_empty():
			lines.append("%s : %s" % [str(review.get("source_name", "Presse")), EXPLAIN.detail_line(why)])
	_detail.text = "\n".join(lines)
	_detail.visible = false
	_why.visible = false
	_detail_button.visible = not lines.is_empty()
	_detail_button.text = "Voir le calcul"

func why_text() -> String:
	if _pleased.text == "":
		return ""
	return "\n".join([_pleased.text, _held_back.text, _next.text])

func detail_text() -> String:
	return _detail.text

## C2 : revoir plus tard les tests d'un produit (depuis sa fiche) — tout est affiché d'un coup, sans son.
func show_archived(product_name: String, reviews: Array) -> void:
	_silent = true
	show_reviews(product_name, reviews)
	_kicker.text = "LES TESTS DE LA PRESSE"
	_subtitle.text = "Publiés au lancement. « Voir le calcul » détaille chaque note."

## reviews : [{source_name, channel_label, score (0-100), headline, body?, why?}].
func show_reviews(product_name: String, reviews: Array, other_models: int = 0, front_page: bool = false) -> void:
	_reviews = reviews.duplicate(true)
	_revealed = 0
	_kicker.text = "LE JOUR J  •  À LA UNE" if front_page else "LE JOUR J"
	_title.text = "%s est en vente. La presse rend son verdict…" % product_name if not _silent else product_name
	_subtitle.text = "%d journal(aux) ont testé %s." % [_reviews.size(), product_name]
	if other_models > 0:
		_subtitle.text += " %d autre(s) modèle(s) de la gamme aussi : détails dans Presse & médias." % other_models
	_apply_layout()
	_pleased.text = ""
	_verdict.text = ""
	_verdict_line.text = ""
	_lesson.text = ""
	_trophy.visible = false
	_detail_button.visible = false
	_continue.disabled = true
	_verdict_bar.modulate.a = 0.0
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for review_value in _reviews:
		var card := _review_card(review_value as Dictionary)
		card.modulate.a = 0.0
		_cards.add_child(card)
	if is_inside_tree() and not _silent and not JUICE.reduced_motion:
		get_tree().create_timer(0.5).timeout.connect(_reveal_next)
	else:
		reveal_all()
	_silent = false

func reveal_all() -> void:
	for card in _cards.get_children():
		(card as CanvasItem).modulate.a = 1.0
		(card as Control).rotation = 0.0
		(card as Control).scale = Vector2.ONE
	_revealed = _reviews.size()
	_show_verdict()

func revealed_count() -> int:
	return _revealed

func verdict_text() -> String:
	return _verdict.text

static func score_out_of_ten(score: float) -> int:
	return clampi(roundi(score / 10.0), 1, 10)

func _reveal_next() -> void:
	if not is_inside_tree() or _revealed >= _reviews.size():
		_show_verdict()
		return
	var card := _cards.get_child(_revealed) as Control
	_drop(card)
	var score := score_out_of_ten(float((_reviews[_revealed] as Dictionary).get("score", 50.0)))
	if get_node_or_null("/root/SoundManager") != null:
		SoundManager.play("review", 0.9 + 0.03 * score)
	_revealed += 1
	get_tree().create_timer(REVEAL_STEP).timeout.connect(_reveal_next)

## Le journal tombe sur la table : il arrive penché et un peu plus grand, puis se pose.
func _drop(card: Control) -> void:
	card.pivot_offset = card.size * 0.5
	card.rotation = -0.06
	card.scale = Vector2(1.08, 1.08)
	card.modulate.a = 0.0
	var tween := card.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.25)
	tween.tween_property(card, "rotation", 0.0, 0.45)
	tween.tween_property(card, "scale", Vector2.ONE, 0.45)

func _show_verdict() -> void:
	_continue.disabled = false
	_verdict_bar.modulate.a = 1.0
	if _reviews.is_empty():
		_verdict.text = "Aucun test publié pour l'instant."
		return
	var total := 0.0
	for review_value in _reviews:
		total += float((review_value as Dictionary).get("score", 50.0))
	var mean_ten := total / float(_reviews.size()) / 10.0
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
	var record := _previous_best()
	var mean_text := ("%.1f" % mean_ten).replace(".", ",")
	if record.is_empty():
		_verdict.text = "%s/10 — %s" % [mean_text, words]
		_verdict_line.text = "Premier passage de la marque devant la presse."
		_trophy.visible = mean_ten >= 6.5
	elif mean_ten > float(record.average) + 0.05:
		_verdict.text = "%s/10 — Nouveau record ! (%s : %s)" % [mean_text, str(record.name), ("%.1f" % float(record.average)).replace(".", ",")]
		_verdict_line.text = words
		_trophy.visible = true
	else:
		_verdict.text = "Moyenne %s/10 — %s" % [mean_text, words]
		_verdict_line.text = "Record à battre : %s (%s/10)." % [str(record.name), ("%.1f" % float(record.average)).replace(".", ",")]
		_trophy.visible = false
	var comparison := str((_reviews[0] as Dictionary).get("comparison_summary", ""))
	if comparison != "":
		_verdict_line.text += "  " + comparison
	_show_why()
	if is_inside_tree() and not _silent:
		JUICE.pop_in(_verdict_bar, 0.3)
		if get_node_or_null("/root/SoundManager") != null:
			SoundManager.play(sound)

## Meilleure moyenne de presse d'un lancement précédent (autres produits) : {name, average} ou vide.
func _previous_best() -> Dictionary:
	var current := {}
	for review_value in _reviews:
		current[str((review_value as Dictionary).get("product_id", ""))] = true
	var totals := {}
	var counts := {}
	var names := {}
	for item_value in MediaManager.news:
		var item: Dictionary = item_value
		if not item.has("review_score"):
			continue
		var product_id := str(item.get("product_id", ""))
		if product_id == "" or current.has(product_id):
			continue
		totals[product_id] = float(totals.get(product_id, 0.0)) + float(item.review_score)
		counts[product_id] = int(counts.get(product_id, 0)) + 1
		names[product_id] = str(item.get("product_name", "Produit"))
	var best := {}
	for product_id in totals.keys():
		var average := float(totals[product_id]) / float(counts[product_id]) / 10.0
		if best.is_empty() or average > float(best.average):
			best = {"name":names[product_id], "average":average}
	return best

func _review_card(review: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _shadowed(CREAM, 14, 16))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(280, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	var score := score_out_of_ten(float(review.get("score", 50.0)))
	var badge := Label.new()
	badge.text = str(score)
	badge.custom_minimum_size = Vector2(60, 60)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 30)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var badge_color := Color("2f8a52") if score >= 7 else (Color("c98a2b") if score >= 5 else BAD)
	badge.add_theme_stylebox_override("normal", UI.stylebox(badge_color, 30, 0, badge_color, 0))
	head.add_child(badge)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(names)
	var paper := LOOK.label(str(review.get("source_name", "Presse")), 17, INK)
	paper.add_theme_font_override("font", _serif)
	paper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	names.add_child(paper)
	names.add_child(LOOK.muted_label(str(review.get("channel_label", "")), 12))
	var headline := LOOK.label("« %s »" % str(review.get("headline", "")), 16, INK)
	headline.add_theme_font_override("font", _serif_italic)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(headline)
	var body := _short_body(str(review.get("body", "")))
	if body != "":
		var body_label := LOOK.label(body, 13, Color("4a3826"))
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(body_label)
	var why: Dictionary = review.get("why", {})
	var best: Array = []
	var worst: Array = []
	for row_value in (EXPLAIN.effects(why) if not why.is_empty() else []):
		var row: Array = row_value
		if float(row[1]) >= 1.0 and (best.is_empty() or float(row[1]) > float(best[1])):
			best = row
		if float(row[1]) <= -1.0 and (worst.is_empty() or float(row[1]) < float(worst[1])):
			worst = row
	if not best.is_empty():
		box.add_child(LOOK.label("+ %s" % str(best[2]), 13, GOOD))
	if not worst.is_empty():
		box.add_child(LOOK.label("− %s" % str(worst[2]), 13, BAD))
	return card

## Les deux premières phrases du texte du journaliste : on lit l'article, pas un rapport.
static func _short_body(body: String) -> String:
	if body == "":
		return ""
	var sentences := body.split(". ", false)
	var kept: Array[String] = []
	for sentence in sentences:
		if kept.size() >= 2:
			break
		kept.append(str(sentence).strip_edges())
	var text := ". ".join(kept)
	return text if text.ends_with(".") or text.ends_with("!") or text.ends_with("?") or text.ends_with("»") else text + "."
