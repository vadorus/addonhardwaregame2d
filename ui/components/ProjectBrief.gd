extends HBoxContainer
## Three plain-language estimates; technical detail belongs in the optional view.
const LOOK := preload("res://ui/WorkshopStyle.gd")
var _values: Array[Label] = []

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for title in ["COÛT ESTIMÉ", "DÉLAI ESTIMÉ", "PROMESSE DU PRODUIT"]:
		var card := LOOK.card(Color("faf0e0"), 10, 9)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		card.add_child(box)
		var heading := LOOK.eyebrow(title)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(heading)
		var value := LOOK.label("—", 17)
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(value)
		_values.append(value)

func update_estimates(monthly: String, duration: String, promise: String) -> void:
	var texts := [monthly, duration, promise]
	for index in range(_values.size()):
		_values[index].text = texts[index]

func texts() -> Array[String]:
	var result: Array[String] = []
	for value in _values: result.append(value.text)
	return result
