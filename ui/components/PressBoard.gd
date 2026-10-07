extends VBoxContainer
## Revue des onglets (07/10) — La Presse, dans l'esprit du jour J (planche 3) :
## une scène (la salle de presse, Nora qui résume), la courbe des notes CPU après CPU,
## puis une « pile de coupures » par CPU : la meilleure critique en journal, les autres en vignettes.
## Les données viennent de MediaManager.news (les tests publiés au lancement) : rien n'est recalculé ici.

const UI := preload("res://ui/UiKit.gd")
const EXPLAIN := preload("res://scripts/ReviewExplainer.gd")
const SCENE_ART := "res://assets/art/v010/J3_moments/moment_presse.webp"
const NORA_OK := "res://assets/art/v010/J2_personnages/perso_04_joie.png"
const NORA_HMM := "res://assets/art/v010/J2_personnages/perso_04_reflexion.png"
const MAX_PRODUCTS := 8

const INK := Color("3b2b1e")
const MUTED := Color("6b5640")
const PAPER := Color("fff8ec")
const CREAM := Color("fbf3e2")
const ORANGE := Color("f2a541")
const GOOD := Color("2f7f46")
const BAD := Color("b5352d")

var _scene_line: Label
var _nora: TextureRect
var _hero_score: Label
var _hero_caption: Label
var _curve: Curve2DView
var _curve_card: Control
var _piles: VBoxContainer
var _serif: SystemFont
var _serif_italic: SystemFont
var _last_key := "-"

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Noto Serif", "Droid Serif", "Times New Roman", "serif"])
	_serif.font_weight = 700
	_serif_italic = SystemFont.new()
	_serif_italic.font_names = _serif.font_names
	_serif_italic.font_italic = true
	_build_scene()
	_curve_card = _paper_card()
	add_child(_curve_card)
	var curve_box := VBoxContainer.new()
	curve_box.add_theme_constant_override("separation", 6)
	_curve_card.add_child(curve_box)
	curve_box.add_child(_heading("Nos notes, CPU après CPU", "La moyenne de la presse à chaque lancement."))
	_curve = Curve2DView.new()
	_curve.custom_minimum_size.y = 120
	curve_box.add_child(_curve)
	_piles = VBoxContainer.new()
	_piles.add_theme_constant_override("separation", 12)
	add_child(_piles)
	refresh(true)

## Les CPU testés, du plus récent au plus ancien : {name, month, year, average, reviews[]}.
static func products_with_reviews(news: Array) -> Array:
	var order: Array = []
	var by_name := {}
	for item_value in news:
		var item: Dictionary = item_value
		if not item.has("review_score"):
			continue
		var name := str(item.get("product_name", item.get("product_id", "CPU")))
		if not by_name.has(name):
			by_name[name] = {"name":name, "month":int(item.get("month", 1)), "year":int(item.get("year", 1971)), "reviews":[]}
			order.append(name)
		(by_name[name].reviews as Array).append(item)
	var result: Array = []
	for name in order:
		var entry: Dictionary = by_name[name]
		var total := 0.0
		for review in entry.reviews:
			total += float((review as Dictionary).get("review_score", 50.0))
		entry["average"] = total / maxf(float((entry.reviews as Array).size()), 1.0)
		(entry.reviews as Array).sort_custom(func(a, b): return float(a.get("review_score", 0.0)) > float(b.get("review_score", 0.0)))
		result.append(entry)
	return result

func refresh(force: bool = false) -> void:
	if _piles == null:
		return
	var key := "%d|%s" % [MediaManager.news.size(), str((MediaManager.news[0] as Dictionary).get("headline", "")) if not MediaManager.news.is_empty() else ""]
	if key == _last_key and not force:
		return
	_last_key = key
	var products := products_with_reviews(MediaManager.news)
	_refresh_scene(products)
	_refresh_curve(products)
	_clear(_piles)
	if products.is_empty():
		var empty := _paper_card()
		var label := _text("Aucun test pour l'instant. Lancez un CPU : la presse le recevra le jour même.", 14, MUTED)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_child(label)
		_piles.add_child(empty)
		return
	for i in range(mini(products.size(), MAX_PRODUCTS)):
		_piles.add_child(_pile(products[i], products[i + 1] if i + 1 < products.size() else {}))

# --- Scène ---------------------------------------------------------------------

func _build_scene() -> void:
	var scene := PanelContainer.new()
	scene.custom_minimum_size.y = 168
	scene.clip_contents = true
	scene.add_theme_stylebox_override("panel", _box(Color("2b1f15"), 18, 0))
	add_child(scene)
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(SCENE_ART):
		art.texture = load(SCENE_ART)
	scene.add_child(art)
	var veil := TextureRect.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.13, 0.09, 0.06, 0.92))
	gradient.set_color(1, Color(0.13, 0.09, 0.06, 0.2))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	veil.texture = texture
	scene.add_child(veil)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	scene.add_child(row)
	var face_margin := MarginContainer.new()
	face_margin.add_theme_constant_override("margin_left", 14)
	face_margin.add_theme_constant_override("margin_top", 8)
	row.add_child(face_margin)
	_nora = TextureRect.new()
	_nora.custom_minimum_size = Vector2(112, 160)
	_nora.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_nora.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_nora.size_flags_vertical = Control.SIZE_SHRINK_END
	face_margin.add_child(_nora)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 6)
	row.add_child(words)
	words.add_child(_text("LA SALLE DE PRESSE", 12, ORANGE))
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _box(PAPER, 14, 10))
	words.add_child(bubble)
	_scene_line = _text("", 15, INK)
	_scene_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(_scene_line)
	var hero_margin := MarginContainer.new()
	for side in ["margin_right", "margin_top", "margin_bottom"]:
		hero_margin.add_theme_constant_override(side, 14)
	row.add_child(hero_margin)
	var hero := PanelContainer.new()
	hero.custom_minimum_size = Vector2(190, 0)
	hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hero.add_theme_stylebox_override("panel", _box(Color(0.17, 0.12, 0.08, 0.86), 14, 12))
	hero_margin.add_child(hero)
	var hero_box := VBoxContainer.new()
	hero_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_child(hero_box)
	_hero_score = _text("—", 40, Color("f6e7cf"))
	_hero_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_box.add_child(_hero_score)
	_hero_caption = _text("", 12, Color("e3cfb0"))
	_hero_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_box.add_child(_hero_caption)

func _refresh_scene(products: Array) -> void:
	if products.is_empty():
		_scene_line.text = "Nora : « Les journalistes attendent notre premier CPU. Le jour du lancement, ils le testeront tous. »"
		_hero_score.text = "—"
		_hero_caption.text = "pas encore de test"
		_nora.texture = load(NORA_HMM) if ResourceLoader.exists(NORA_HMM) else null
		return
	var last: Dictionary = products[0]
	var score := snappedf(float(last.average) / 10.0, 0.1)
	var line := "Nora : « %s : %s/10 de moyenne sur %d tests." % [str(last.name), _num(score), (last.reviews as Array).size()]
	if products.size() > 1:
		var before := float((products[1] as Dictionary).average) / 10.0
		var delta := score - before
		if delta >= 0.5:
			line += " Mieux que %s : la presse suit." % str((products[1] as Dictionary).name)
		elif delta <= -0.5:
			line += " Moins bien que %s : il faudra du neuf pour la reconquérir." % str((products[1] as Dictionary).name)
		else:
			line += " Comme %s : elle attend une vraie nouveauté." % str((products[1] as Dictionary).name)
	else:
		line += " Un premier essai, la presse s'en souviendra."
	_scene_line.text = line + " »"
	_hero_score.text = "%s/10" % _num(score)
	_hero_score.add_theme_color_override("font_color", Color("9be0b4") if score >= 7.0 else (Color("f6d28b") if score >= 5.0 else Color("f3a19a")))
	_hero_caption.text = "%s · %02d/%d" % [str(last.name), int(last.month), int(last.year)]
	var path := NORA_OK if score >= 6.5 else NORA_HMM
	_nora.texture = load(path) if ResourceLoader.exists(path) else null

func _refresh_curve(products: Array) -> void:
	var points: Array = []
	var shown := products.slice(0, 12)
	shown.reverse()
	for entry_value in shown:
		var entry: Dictionary = entry_value
		points.append({"label":str(entry.name), "value":float(entry.average) / 10.0})
	_curve.points = points
	_curve_card.visible = points.size() >= 2
	_curve.queue_redraw()

# --- Une pile de coupures par CPU ----------------------------------------------

func _pile(entry: Dictionary, previous: Dictionary) -> Control:
	var card := _paper_card()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	var score := snappedf(float(entry.average) / 10.0, 0.1)
	head.add_child(_round_score(_num(score), score, 54, 24))
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(titles)
	var name_label := _text(str(entry.name), 20, INK)
	name_label.add_theme_font_override("font", _serif)
	titles.add_child(name_label)
	var meta := "Sorti en %02d/%d · %d test(s)" % [int(entry.month), int(entry.year), (entry.reviews as Array).size()]
	if not previous.is_empty():
		var delta := score - snappedf(float(previous.average) / 10.0, 0.1)
		meta += " · %s%s face à %s" % ["+" if delta >= 0.0 else "−", _num(absf(delta)), str(previous.name)]
	titles.add_child(_text(meta, 12, MUTED))
	var reviews: Array = entry.reviews
	box.add_child(_clipping(reviews[0]))
	if reviews.size() > 1:
		var others := HFlowContainer.new()
		others.add_theme_constant_override("h_separation", 8)
		others.add_theme_constant_override("v_separation", 8)
		box.add_child(others)
		for i in range(1, reviews.size()):
			others.add_child(_mini_clipping(reviews[i]))
	return card

## La meilleure critique, façon coupure de journal : titre du journal, gros titre en italique, deux phrases.
func _clipping(review: Dictionary) -> Control:
	var clip := PanelContainer.new()
	var style := _box(CREAM, 12, 14)
	style.border_width_left = 4
	style.border_color = ORANGE
	clip.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	clip.add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var paper := _text(str(review.get("source_name", "Presse")), 15, INK)
	paper.add_theme_font_override("font", _serif)
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(paper)
	var score := clampi(roundi(float(review.get("review_score", 50.0)) / 10.0), 1, 10)
	top.add_child(_round_score(str(score), float(score), 34, 15))
	var headline := _text("« %s »" % str(review.get("headline", "")), 16, INK)
	headline.add_theme_font_override("font", _serif_italic)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(headline)
	var body := _short_body(str(review.get("body", "")))
	if body != "":
		var body_label := _text(body, 13, Color("4a3826"))
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(body_label)
	var why: Dictionary = review.get("why", {}) if typeof(review.get("why", {})) == TYPE_DICTIONARY else {}
	var best: Array = []
	var worst: Array = []
	for row_value in (EXPLAIN.effects(why) if not why.is_empty() else []):
		var row: Array = row_value
		if float(row[1]) >= 1.0 and (best.is_empty() or float(row[1]) > float(best[1])):
			best = row
		if float(row[1]) <= -1.0 and (worst.is_empty() or float(row[1]) < float(worst[1])):
			worst = row
	var verdict := HFlowContainer.new()
	verdict.add_theme_constant_override("h_separation", 14)
	if not best.is_empty():
		verdict.add_child(_text("+ %s" % str(best[2]), 13, GOOD))
	if not worst.is_empty():
		verdict.add_child(_text("− %s" % str(worst[2]), 13, BAD))
	if verdict.get_child_count() > 0:
		box.add_child(verdict)
	return clip

func _mini_clipping(review: Dictionary) -> Control:
	var clip := PanelContainer.new()
	clip.add_theme_stylebox_override("panel", _box(Color("f3e7d3"), 10, 8))
	clip.custom_minimum_size.x = 210
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	clip.add_child(row)
	var score := clampi(roundi(float(review.get("review_score", 50.0)) / 10.0), 1, 10)
	row.add_child(_round_score(str(score), float(score), 30, 13))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	var paper := _text(str(review.get("source_name", "Presse")), 12, INK)
	paper.add_theme_font_override("font", _serif)
	words.add_child(paper)
	var headline := _text(_shorten(str(review.get("headline", "")), 46), 11, MUTED)
	headline.add_theme_font_override("font", _serif_italic)
	words.add_child(headline)
	clip.tooltip_text = "%s\n%s" % [str(review.get("headline", "")), str(review.get("body", ""))]
	return clip

# --- Petites pièces ---------------------------------------------------------------

static func _short_body(body: String) -> String:
	if body == "":
		return ""
	var kept: Array[String] = []
	for sentence in body.split(". ", false):
		if kept.size() >= 2:
			break
		kept.append(str(sentence).strip_edges())
	var text := ". ".join(kept)
	return text if text.ends_with(".") or text.ends_with("!") or text.ends_with("?") or text.ends_with("»") else text + "."

static func _shorten(text: String, max_chars: int) -> String:
	return text if text.length() <= max_chars else text.substr(0, max_chars - 1).strip_edges() + "…"

static func _num(value: float) -> String:
	var text := "%.1f" % value
	if text.ends_with(".0"):
		text = text.substr(0, text.length() - 2)
	return text.replace(".", ",")

func _round_score(text: String, score: float, diameter: int, font_size: int) -> Control:
	var badge := Label.new()
	badge.text = text
	badge.custom_minimum_size = Vector2(diameter, diameter)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_font_size_override("font_size", font_size)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var tint := Color("2f8a52") if score >= 7.0 else (Color("c98a2b") if score >= 5.0 else BAD)
	badge.add_theme_stylebox_override("normal", _box(tint, diameter / 2, 0))
	return badge

func _box(bg: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _paper_card() -> PanelContainer:
	var card := PanelContainer.new()
	var style := _box(PAPER, 18, 14)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", style)
	return card

func _heading(title: String, subtitle: String) -> Control:
	var box := HFlowContainer.new()
	box.add_theme_constant_override("h_separation", 12)
	box.add_child(_text(title, 18, INK))
	if subtitle != "":
		var sub := _text(subtitle, 12, MUTED)
		sub.size_flags_vertical = Control.SIZE_SHRINK_END
		box.add_child(sub)
	return box

func _text(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

## Courbe des notes : un point par CPU (sur 10), relié au suivant, avec le nom dessous.
class Curve2DView extends Control:
	var points: Array = []

	func _draw() -> void:
		if points.size() < 2:
			return
		var font := get_theme_default_font()
		var left := 28.0
		var right := size.x - 16.0
		var top := 14.0
		var bottom := size.y - 22.0
		for level: float in [5.0, 7.0]:
			var y := bottom - (bottom - top) * level / 10.0
			draw_line(Vector2(left, y), Vector2(right, y), Color(0.42, 0.34, 0.25, 0.25), 1.0)
			draw_string(font, Vector2(2.0, y + 4.0), "%d" % int(level), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("6b5640"))
		var step := (right - left) / float(points.size() - 1)
		var previous := Vector2.ZERO
		for i in range(points.size()):
			var point: Dictionary = points[i]
			var value := clampf(float(point.value), 0.0, 10.0)
			var at := Vector2(left + step * i, bottom - (bottom - top) * value / 10.0)
			if i > 0:
				draw_line(previous, at, Color("f2a541"), 3.0, true)
			previous = at
		for i in range(points.size()):
			var point: Dictionary = points[i]
			var value := clampf(float(point.value), 0.0, 10.0)
			var at := Vector2(left + step * i, bottom - (bottom - top) * value / 10.0)
			var tint := Color("2f8a52") if value >= 7.0 else (Color("c98a2b") if value >= 5.0 else Color("b5352d"))
			draw_circle(at, 6.0, tint)
			var label := str(point.label)
			if label.length() > 12:
				label = label.substr(0, 11) + "…"
			var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
			draw_string(font, Vector2(at.x - label_size.x * 0.5, size.y - 6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("6b5640"))
