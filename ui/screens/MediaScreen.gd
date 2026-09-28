extends ScrollContainer
## Presse & médias : des fiches courtes (date, titre, note) triées par pastilles,
## au lieu d'un long texte de 20 articles (retour d'Alexandre, 28/09).

const UI := preload("res://ui/UiKit.gd")
const MAX_ITEMS := 20

var media_label: Label
var pager: Control
var _lists: Dictionary = {}
var _last_key := "-"

func _ready() -> void:
	name = "Presse & médias"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()
	UI.configure_touch_scroll(self)
	UI.prepare_touch_scroll_children(self)

func _build() -> void:
	var box := UI.content_box()
	add_child(box)
	box.add_child(UI.eyebrow("PRESSE & MÉDIAS"))
	box.add_child(UI.label("Ce que le marché raconte de votre industrie", 24))
	pager = (load("res://ui/SectionPager.gd") as Script).new() as Control
	box.add_child(pager)
	for data in [["TESTS", "Tests de vos produits"], ["BUSINESS", "Business & contrats"], ["ALL", "Tout"]]:
		var page: VBoxContainer = pager.call("add_page", str(data[0]), str(data[1]))
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 8)
		page.add_child(list)
		_lists[str(data[0])] = list
	pager.call("show_page", "TESTS")
	# Texte récapitulatif conservé pour les tests et l'accessibilité, non affiché.
	media_label = UI.rich_label()
	media_label.visible = false
	box.add_child(media_label)
	refresh()

func show_section(key: String) -> void:
	if pager != null:
		pager.call("show_page", key)

func current_section() -> String:
	return str(pager.get("current")) if pager != null else ""

func refresh() -> void:
	if media_label == null:
		return
	var items: Array = MediaManager.news.slice(0, MAX_ITEMS)
	# Les fiches ne sont reconstruites que si les actualités ont changé (économise le téléphone).
	var key_now := "%d|%s" % [MediaManager.news.size(), str((items[0] as Dictionary).get("headline", "")) if not items.is_empty() else ""]
	if key_now == _last_key:
		return
	_last_key = key_now
	var lines: Array[String] = []
	for news_value in items:
		var news: Dictionary = news_value
		lines.append("[%02d/%d] %s\n%s\n%s" % [int(news.get("month", 1)), int(news.get("year", 1971)), _source_line(news), str(news.get("headline", "")), str(news.get("body", ""))])
	media_label.text = "\n\n".join(lines) if not lines.is_empty() else "Aucune actualité."
	for key in _lists.keys():
		var list: VBoxContainer = _lists[key]
		for child in list.get_children():
			list.remove_child(child)
			child.queue_free()
		var count := 0
		for news_value in items:
			var news: Dictionary = news_value
			var is_test := news.has("review_score")
			if (key == "TESTS" and not is_test) or (key == "BUSINESS" and is_test):
				continue
			list.add_child(_news_card(news))
			count += 1
		if count == 0:
			list.add_child(UI.muted_label("Rien pour l'instant. Lancez un produit : la presse le testera.", 13) if key == "TESTS" else UI.muted_label("Aucune actualité.", 13))
	if pager != null:
		var tests := 0
		for news_value in items:
			if (news_value as Dictionary).has("review_score"):
				tests += 1
		if current_section() == "TESTS" and tests == 0 and not items.is_empty():
			pager.call("show_page", "BUSINESS")
	UI.prepare_touch_scroll_children(self)

func _source_line(news: Dictionary) -> String:
	var source := str(news.get("source_name", ""))
	var channel := MediaManager.channel_label(str(news.get("channel", ""))) if news.has("channel") else str(news.get("category", "Actualité"))
	return channel if source.is_empty() else "%s — %s" % [source, channel]

func _news_card(news: Dictionary) -> Control:
	var card := UI.card(UI.APP_PANEL, 12, 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var date := UI.muted_label("%02d/%d" % [int(news.get("month", 1)), int(news.get("year", 1971))], 12)
	date.custom_minimum_size.x = 64
	date.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(date)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)
	var headline := UI.label(str(news.get("headline", "")), 15)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(headline)
	text_box.add_child(UI.muted_label(_source_line(news), 11))
	var body := UI.muted_label(str(news.get("body", "")), 12)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(body)
	if news.has("review_score"):
		var score := clampi(roundi(float(news.get("review_score", 50.0)) / 10.0), 1, 10)
		var badge := Label.new()
		badge.text = "%d/10" % score
		badge.custom_minimum_size = Vector2(64, 44)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.add_theme_font_size_override("font_size", 17)
		badge.add_theme_color_override("font_color", Color.WHITE)
		var tint := UI.APP_GREEN if score >= 7 else (UI.APP_AMBER if score >= 5 else UI.APP_RED)
		badge.add_theme_stylebox_override("normal", UI.stylebox(tint, 22, 0, tint, 4))
		row.add_child(badge)
	return card
