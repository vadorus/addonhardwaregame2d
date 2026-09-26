extends ScrollContainer

const UI := preload("res://ui/UiKit.gd")

var media_label: Label

func _ready() -> void:
	name = "Presse & médias"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build()

func _build() -> void:
	var box := UI.content_box()
	add_child(box)
	box.add_child(UI.eyebrow("PRESSE & MÉDIAS"))
	box.add_child(UI.label("Ce que le marché raconte de votre industrie", 24))
	var intro := UI.muted_label("Actualités, lancements, contrats publics et mouvements observables des entreprises.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)
	media_label = UI.rich_label()
	box.add_child(media_label)
	refresh()

func refresh() -> void:
	if media_label == null:
		return
	var lines: Array[String] = []
	for news_value in MediaManager.news.slice(0, 20):
		var news: Dictionary = news_value
		var source := str(news.get("source_name", ""))
		var channel := MediaManager.channel_label(str(news.get("channel", ""))) if news.has("channel") else str(news.get("category", "Actualite"))
		var source_line := channel if source.is_empty() else "%s ? %s" % [channel, source]
		lines.append("[%02d/%d] %s\n%s\n%s" % [
			int(news.month), int(news.year), source_line, str(news.headline), str(news.body)
		])
	media_label.text = "\n\n".join(lines) if not lines.is_empty() else "Aucune actualité."
