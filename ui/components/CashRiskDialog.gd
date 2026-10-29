extends ConfirmationDialog
## Confirmation commune aux deux parcours de fabrication.
const UI := preload("res://ui/UiKit.gd")
const STYLE := preload("res://ui/WorkshopStyle.gd")

func _init() -> void:
	name = "CashRiskConfirmation"
	title = "Fabrication : trésorerie insuffisante"
	ok_button_text = "Lancer malgré le risque"
	cancel_button_text = "Revoir mon choix"
	# Rendu embarqué : les couleurs restent celles du jeu sur Android aussi.

func _style_dialog() -> void:
	force_native = false
	add_theme_stylebox_override("panel", UI.stylebox(Color("fbf4e8"), 14, 2, STYLE.BLUE, 20))
	add_theme_color_override("title_color", STYLE.INK)
	get_label().add_theme_color_override("font_color", STYLE.INK)
	get_label().add_theme_font_size_override("font_size", 18)
	get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for button in [get_ok_button(), get_cancel_button()]:
		STYLE.button_style(button)
		button.custom_minimum_size.y = 56
		button.add_theme_font_size_override("font_size", 18)
	get_cancel_button().grab_focus.call_deferred()

func show_quote(quote: Dictionary) -> void:
	dialog_text = GarageBusiness.fabrication_cash_text(quote)
	_style_dialog()
	popup_centered_clamped(Vector2i(660, 380), 0.92)
	_style_dialog()

static func reserve_text(months: float) -> String:
	var value := maxf(months, 0.0)
	return (("%.1f" % value).replace(".", ",") if value < 3.0 else "%.0f" % value) + " mois"
