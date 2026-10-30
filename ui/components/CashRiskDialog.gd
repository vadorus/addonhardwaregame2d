extends ConfirmationDialog
## Confirmation commune aux deux parcours de fabrication.
const UI := preload("res://ui/UiKit.gd")
const STYLE := preload("res://ui/WorkshopStyle.gd")

func _init() -> void:
	dialog_autowrap = true
	name = "CashRiskConfirmation"
	title = "Fabrication : trésorerie insuffisante"
	ok_button_text = "Lancer malgré le risque"
	cancel_button_text = "Revoir mon choix"
	# Rendu embarqué : les couleurs restent celles du jeu sur Android aussi.

func _style_dialog() -> void:
	force_native = false
	add_theme_stylebox_override("panel", UI.stylebox(Color("fbf4e8"), 14, 2, STYLE.BLUE, 20))
	var border := UI.stylebox(Color("fbf4e8"), 14, 2, STYLE.BLUE, 20)
	border.expand_margin_top = 36
	border.content_margin_top = 36
	add_theme_stylebox_override("embedded_border", border)
	add_theme_stylebox_override("embedded_unfocused_border", border)
	add_theme_color_override("title_color", STYLE.INK)
	add_theme_color_override("title_unfocused_color", STYLE.INK)
	get_label().add_theme_color_override("font_color", STYLE.INK)
	get_label().add_theme_font_size_override("font_size", 18)
	get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for button in [get_ok_button(), get_cancel_button()]:
		STYLE.button_style(button)
		button.custom_minimum_size.y = 56
		button.add_theme_font_size_override("font_size", 18)
	get_cancel_button().grab_focus.call_deferred()

func show_quote(quote: Dictionary) -> void:
	_style_dialog()
	var root := get_tree().root
	var width := int(minf(720.0, root.get_visible_rect().size.x * 0.9))
	var panel := get_theme_stylebox("panel")
	get_label().custom_minimum_size.x = width - panel.get_margin(SIDE_LEFT) - panel.get_margin(SIDE_RIGHT)
	size = Vector2i(width, 0)
	dialog_text = GarageBusiness.fabrication_cash_text(quote)
	reset_size()
	popup_centered(Vector2i(width, 0))
	_style_dialog()

static func reserve_text(months: float) -> String:
	var value := maxf(months, 0.0)
	return (("%.1f" % value).replace(".", ",") if value < 3.0 else "%.0f" % value) + " mois"
