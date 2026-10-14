extends PanelContainer
## RANK-01 / WORLD-01 (14/10) — Marché : les quatre couronnes du marché CPU et le défi en cours.
## Une ligne par palmarès : qui la tient, depuis combien de mois, et où vous en êtes (rang, écart).

const UI := preload("res://ui/UiKit.gd")
const PALMARES := preload("res://scripts/CpuPalmares.gd")
const RIVALRY := preload("res://scripts/CpuRivalry.gd")
const GOLD := Color("c8941f")
const GOLD_BG := Color("fff1cf")
const AMBER := Color("d9822b")

var _rows: VBoxContainer
var _challenge: Label

func _ready() -> void:
	add_theme_stylebox_override("panel", UI.stylebox(Color("fffaf1"), 14, 1, AMBER, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	box.add_child(UI.eyebrow("PALMARÈS DU MARCHÉ CPU"))
	var intro := UI.muted_label("Quatre façons d'être premier, mesurées pareil pour vous et pour les rivaux. Pas besoin d'être le plus riche.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)
	_challenge = UI.label("", 13)
	_challenge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_challenge.add_theme_color_override("font_color", Color("a8431f"))
	box.add_child(_challenge)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	box.add_child(_rows)
	refresh()

func refresh() -> void:
	if _rows == null:
		return
	var status := RIVALRY.status_line()
	_challenge.text = status
	_challenge.visible = status != ""
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var any := false
	for row_value in PALMARES.rows():
		var row: Dictionary = row_value
		if str(row.holder_company) == "":
			continue
		any = true
		_rows.add_child(_row(row))
	if not any:
		_rows.add_child(UI.muted_label("Le palmarès s'ouvrira avec les premiers CPU en vente.", 12))

func _row(row: Dictionary) -> Control:
	var mine := bool(row.holder_player)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.stylebox(GOLD_BG if mine else Color("f8efe2"), 10, 2 if mine else 1, GOLD if mine else UI.APP_LINE, 8))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	panel.add_child(line)
	var crown := UI.label("★" if mine else "☆", 20)
	crown.add_theme_color_override("font_color", GOLD if mine else UI.APP_MUTED)
	line.add_child(crown)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(left)
	left.add_child(UI.label(str(row.label), 14))
	var holder := "%s%s" % [str(row.holder_company), (" — %s" % str(row.holder_product)) if str(row.holder_product) != "" else ""]
	var since := "depuis %d mois" % int(row.months) if int(row.months) > 1 else "depuis ce mois"
	var who := UI.muted_label("%s • %s" % ["Vous (%s)" % str(row.holder_product) if mine else holder, since], 12)
	who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(who)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 0)
	line.add_child(right)
	var position: Dictionary = row.get("position", {})
	var rank := int(position.get("rank", 0))
	var you := UI.label(_position_text(str(row.category), position), 13)
	you.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	you.add_theme_color_override("font_color", Color("2f7a3a") if rank == 1 else (UI.APP_TEXT if rank > 0 else UI.APP_MUTED))
	right.add_child(you)
	if int(row.player_months) > 0:
		var record := UI.muted_label("%d mois en tête au total • record %d d'affilée" % [int(row.player_months), int(row.player_best_streak)], 11)
		record.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(record)
	return panel

func _position_text(category: String, position: Dictionary) -> String:
	var rank := int(position.get("rank", 0))
	if rank <= 0:
		return "Vous : pas classé"
	var gap := float(position.get("gap", 0.0))
	var gap_text := ""
	match category:
		"PERF", "EFFICIENCY":
			gap_text = ("%+.1f pt" % gap).replace(".", ",").replace("-", "−")
		"VALUE":
			# Écart en pourcentage du concurrent de référence (le deuxième si vous êtes en tête, sinon le premier).
			gap_text = "%+d %%" % int(round(gap / maxf(float(position.get("score", 0.0)) - gap, 0.01) * 100.0))
		"SALES":
			gap_text = "%s%s puces" % ["+" if gap >= 0.0 else "−", UI.money(absi(int(round(gap))))]
	return "Vous : %s (%s)" % ["1er" if rank == 1 else "%de" % rank, gap_text]
