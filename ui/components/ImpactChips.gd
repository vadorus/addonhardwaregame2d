extends RefCounted
## Fiche d'impact : la rangée de pastilles colorées, identique partout (conception CPU, recherche…).
## Vert = ce que vous gagnez, rouge = ce que ça coûte.

const UI := preload("res://ui/UiKit.gd")
const GOOD_TEXT := Color("2f7a3a")
const BAD_TEXT := Color("b3261e")

static func flow(chip_list: Array, prefix: String = "", font_size: int = 12) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if prefix != "":
		var head := UI.muted_label(prefix, font_size)
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(head)
	if chip_list.is_empty():
		var none := UI.muted_label("sans effet notable", font_size)
		none.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(none)
	for chip_value in chip_list:
		var chip: Dictionary = chip_value
		var label := UI.label(str(chip.text), font_size)
		label.add_theme_color_override("font_color", GOOD_TEXT if bool(chip.good) else BAD_TEXT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
	return row
