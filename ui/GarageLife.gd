extends Control
## V0.10 / K2 — le QG vit : il raconte la partie sans qu'on ouvre un menu.
## - une étagère murale en haut : vos générations de CPU (puces d'Astra), vos trophées de carrière,
##   vos « Unes » de la presse et la taille de l'équipe ;
## - les saisons : neige l'hiver (guirlande en décembre), pétales au printemps, poussière dorée l'été,
##   feuilles l'automne ;
## - les événements du moment (salon, guerre des prix, pénurie…) sur une petite pancarte.
## Toucher l'étagère ouvre le détail. Tout est dessiné en code, sous les cartes du QG.

const CHIP := preload("res://ui/ChipPreview.gd")
const CAREER := preload("res://scripts/CareerPrestige.gd")
const LATE := preload("res://scripts/LateGameEvents.gd")
const UI := preload("res://ui/UiKit.gd")
const WORKPLACE := preload("res://ui/WorkplaceArt.gd")

const MAX_CHIPS := 5
const SEASONS := {12:"WINTER", 1:"WINTER", 2:"WINTER", 3:"SPRING", 4:"SPRING", 5:"SPRING",
	6:"SUMMER", 7:"SUMMER", 8:"SUMMER", 9:"AUTUMN", 10:"AUTUMN", 11:"AUTUMN"}
const SEASON_LABELS := {"WINTER":"hiver", "SPRING":"printemps", "SUMMER":"été", "AUTUMN":"automne"}
const TINTS := {"WINTER":Color(0.55, 0.72, 1.0, 0.10), "SPRING":Color(0.85, 1.0, 0.85, 0.05),
	"SUMMER":Color(1.0, 0.8, 0.4, 0.08), "AUTUMN":Color(1.0, 0.5, 0.15, 0.09)}
const PARTICLES := {"WINTER":46, "SPRING":26, "SUMMER":30, "AUTUMN":22}
const WOOD := Color("8a5a32")
const WOOD_DARK := Color("5e3b1f")
const GOLD := Color("e2b33c")
const CREAM := Color("fffaf1")

var art_rect := Rect2()
var _season := ""
var _particles: Array = []
var _chips: Array = []
var _trophies := 0
var _trophy_labels: Array[String] = []
var _front_pages := 0
var _staff := 0
var _event := ""
var _garland := false
var _shelf := Rect2()
var _shelf_button: Button
var _card: PanelContainer
var _card_label: Label
var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shelf_button = Button.new()
	_shelf_button.flat = true
	_shelf_button.focus_mode = Control.FOCUS_NONE
	_shelf_button.tooltip_text = "Vitrine de l'entreprise"
	for state in ["normal", "hover", "pressed", "focus"]:
		_shelf_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_shelf_button.pressed.connect(_toggle_card)
	add_child(_shelf_button)
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UI.stylebox(CREAM, 12, 2, Color("d9822b"), 12))
	_card.visible = false
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	_card_label = UI.label("", 14)
	_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_label.custom_minimum_size = Vector2(320, 0)
	_card.add_child(_card_label)
	refresh()

func set_art_rect(rect: Rect2) -> void:
	art_rect = rect
	_layout()

## Ce que le QG montre en ce moment (sert aussi aux tests).
func scene_state() -> Dictionary:
	return {"season":_season, "garland":_garland, "chips":_chips.size(), "trophies":_trophies,
		"front_pages":_front_pages, "staff":_staff, "event":_event, "shelf_visible":shelf_visible()}

func shelf_visible() -> bool:
	return not _chips.is_empty() or _trophies > 0 or _front_pages > 0

func shelf_rect() -> Rect2:
	return _shelf if shelf_visible() else Rect2()

func refresh() -> void:
	if not CompanyManager.created:
		_chips.clear()
		_trophies = 0
		_front_pages = 0
		_event = ""
		visible = false
		return
	visible = true
	var season := str(SEASONS.get(TimeManager.month, "SUMMER"))
	if season != _season:
		_season = season
		_spawn_particles()
	_garland = TimeManager.month == 12
	_chips = generation_chips()
	_trophy_labels.clear()
	for row_value in CAREER.trophy_rows():
		var row: Dictionary = row_value
		if bool(row.get("unlocked", false)):
			_trophy_labels.append(str(row.get("label", "")))
	_trophies = _trophy_labels.size()
	_front_pages = int(MediaManager.front_pages)
	_staff = PersonnelManager.staff.size()
	_event = current_event()
	_layout()
	if _card.visible:
		_card_label.text = _card_text()
	queue_redraw()

## Les générations déjà sorties, les plus récentes (une puce par génération, selon sa gravure).
static func generation_chips() -> Array:
	var out: Array = []
	for generation_value in ProductManager.cpu_generations:
		var generation: Dictionary = generation_value
		var sold := false
		for model_id in generation.get("model_ids", []):
			if str(ProductManager.get_product(str(model_id)).get("status", "")) in ["LAUNCHED", "RETIRED", "DISCONTINUED"]:
				sold = true
				break
		if not sold:
			continue
		var design: Dictionary = generation.get("architecture", {})
		out.append({"name":str(generation.get("name", "CPU")), "index":int(generation.get("generation_index", 1)),
			"node":int(design.get("node_nm", 10000))})
	out.sort_custom(func(a, b): return int(a.index) < int(b.index))
	return out.slice(maxi(out.size() - MAX_CHIPS, 0))

## Ce que le QG montre, sans écran (banc 10 ans, tests) : locaux, équipe visible, vitrine, trophées, Unes, événement.
static func scene_signature() -> Dictionary:
	var tier := clampi(int(ExecutiveManager.workplace.get("tier", 0)), 0, 3)
	var seats: Array = WORKPLACE.crew_layout(tier).seats
	return {"tier":tier, "crew":mini(PersonnelManager.staff.size(), seats.size()), "chips":generation_chips().size(),
		"trophies":CAREER.unlocked_count(), "front_pages":int(MediaManager.front_pages), "event":current_event().get_slice(" (", 0),
		"season":str(SEASONS.get(TimeManager.month, "SUMMER"))}

## L'événement le plus marquant du moment ("" s'il n'y en a pas).
static func current_event() -> String:
	var expo := LATE.open_expo()
	if not expo.is_empty():
		return str(expo.get("title", "Salon annuel"))
	for threat_value in MarketManager.active_market_threats():
		var threat: Dictionary = threat_value
		return "%s (%d mois)" % [str(threat.get("title", "Menace sur le marché")), int(threat.get("remaining_months", 0))]
	for event_value in LATE.state().get("active_events", []):
		var event: Dictionary = event_value
		if str(event.get("status", "ACTIVE")) == "ACTIVE":
			return str(event.get("title", "Événement"))
	return ""

## Largeur des objets posés sur l'étagère (l'étagère s'adapte à son contenu).
func _content_width() -> float:
	var w := 44.0 * float(_chips.size())
	if not _chips.is_empty():
		w += 8.0
	w += 28.0 * float(mini(_trophies, 4)) + (30.0 if _trophies > 4 else 0.0)
	w += 26.0 * float(mini(_front_pages, 3)) + (30.0 if _front_pages > 3 else 0.0)
	return w

func _layout() -> void:
	var width := clampf(_content_width() + 36.0, 150.0, maxf(size.x * 0.45, 150.0))
	_shelf = Rect2(Vector2((size.x - width) * 0.5, 12.0), Vector2(width, 74.0))
	_shelf_button.position = _shelf.position
	_shelf_button.size = _shelf.size
	_shelf_button.visible = shelf_visible()
	_card.position = Vector2(_shelf.position.x, _shelf.end.y + (34.0 if _event != "" else 6.0)) + position
	queue_redraw()

func _toggle_card() -> void:
	# La carte passe au-dessus des repères du QG (ajoutés après nous dans la scène).
	var hub := get_parent()
	if hub != null and _card.get_parent() == self:
		remove_child(_card)
		hub.add_child(_card)
	elif hub != null:
		hub.move_child(_card, hub.get_child_count() - 1)
	_card.visible = not _card.visible
	if _card.visible:
		_card_label.text = _card_text()
		_card.reset_size()
		SoundManager.play("click")
		get_tree().create_timer(8.0).timeout.connect(func():
			if is_instance_valid(_card):
				_card.visible = false)

func card_open() -> bool:
	return _card != null and _card.visible

func _card_text() -> String:
	var lines: Array[String] = ["Vitrine de %s" % CompanyManager.company_name]
	if not _chips.is_empty():
		var names: Array[String] = []
		for chip in _chips:
			names.append("%s (G%d)" % [str(chip.name), int(chip.index)])
		lines.append("Vos CPU : " + ", ".join(names))
	lines.append("Trophées : " + (", ".join(_trophy_labels) if _trophies > 0 else "aucun pour l'instant"))
	lines.append("À la une de la presse : %d fois" % _front_pages)
	lines.append("Équipe : %d personne%s, Nora comprise" % [_staff + 1, "s" if _staff > 0 else ""])
	if _event != "":
		lines.append("En ce moment : " + _event)
	lines.append("Saison : " + str(SEASON_LABELS.get(_season, "")))
	return "\n".join(lines)

# --- Saisons -----------------------------------------------------------------------------------------

func _spawn_particles() -> void:
	_particles.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_season)
	for i in range(int(PARTICLES.get(_season, 0))):
		_particles.append({"x":rng.randf(), "y":rng.randf(), "speed":rng.randf_range(0.025, 0.06),
			"sway":rng.randf_range(0.004, 0.018), "phase":rng.randf() * TAU, "size":rng.randf_range(1.4, 3.2)})

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _particles.is_empty():
		return
	_time += delta
	var rise := _season == "SUMMER"
	for p_value in _particles:
		var p: Dictionary = p_value
		var speed := float(p.speed) * (0.35 if rise else (0.6 if _season == "AUTUMN" else 1.0))
		p.y = float(p.y) + (-speed if rise else speed) * delta
		if p.y > 1.02:
			p.y = -0.02
		elif p.y < -0.02:
			p.y = 1.02
	queue_redraw()

func _draw() -> void:
	if art_rect.size.x <= 0.0 or not CompanyManager.created:
		return
	var view := Rect2(Vector2.ZERO, size).intersection(art_rect)
	draw_rect(view, TINTS.get(_season, Color(0, 0, 0, 0)))
	_draw_particles(view)
	if _garland:
		_draw_garland(view)
	if shelf_visible():
		_draw_shelf()
	if _event != "":
		_draw_event_sign()

func _draw_particles(view: Rect2) -> void:
	for p_value in _particles:
		var p: Dictionary = p_value
		var sway := sin(_time * 0.9 + float(p.phase)) * float(p.sway)
		var pos := view.position + Vector2((float(p.x) + sway) * view.size.x, float(p.y) * view.size.y)
		var s := float(p.size) * clampf(view.size.y / 600.0, 0.8, 1.6)
		match _season:
			"WINTER":
				draw_circle(pos, s * 1.3, Color(1, 1, 1, 0.9))
			"SPRING":
				draw_circle(pos, s * 1.8, Color("f6b8c8", 0.9))
				draw_circle(pos + Vector2(s, -s * 0.5), s * 1.2, Color("fde3ea", 0.9))
			"SUMMER":
				draw_circle(pos, s * 1.1, Color("ffe08a", 0.55))
			"AUTUMN":
				var angle := _time * 1.5 + float(p.phase)
				var leaf := PackedVector2Array()
				for k in range(4):
					var a := angle + k * PI * 0.5
					leaf.append(pos + Vector2(cos(a), sin(a)) * s * (3.6 if k % 2 == 0 else 1.6))
				draw_colored_polygon(leaf, Color("c8501e") if int(float(p.phase) * 10.0) % 2 == 0 else Color("9a3b1c"))
				leaf.append(leaf[0])
				draw_polyline(leaf, Color("4a1f0e", 0.8), 1.2)

func _draw_garland(view: Rect2) -> void:
	var y0 := view.position.y + 4.0
	var count := 22
	var colors := [Color("e74c3c"), Color("f1c40f"), Color("2ecc71"), Color("3498db")]
	var last := Vector2.ZERO
	for i in range(count + 1):
		var t := float(i) / float(count)
		var x := view.position.x + t * view.size.x
		var y := y0 + sin(t * PI * 6.0) * 7.0 + 12.0
		var point := Vector2(x, y)
		if i > 0:
			draw_line(last, point, Color("2f3b2a"), 2.0)
		last = point
		var on := int(_time * 2.0 + i) % 2 == 0
		draw_circle(point + Vector2(0, 6), 5.5, (colors[i % colors.size()] as Color) * Color(1, 1, 1, 1.0 if on else 0.45))

func _draw_shelf() -> void:
	var r := _shelf
	var plank_y := r.position.y + 50.0
	# Équerres, planche, ombre.
	draw_rect(Rect2(r.position.x + 18.0, plank_y, 6.0, 16.0), WOOD_DARK)
	draw_rect(Rect2(r.end.x - 24.0, plank_y, 6.0, 16.0), WOOD_DARK)
	draw_rect(Rect2(r.position.x, plank_y + 9.0, r.size.x, 5.0), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(r.position.x, plank_y, r.size.x, 9.0), WOOD)
	draw_rect(Rect2(r.position.x, plank_y, r.size.x, 2.0), Color("b07a48"))
	var x := r.position.x + (r.size.x - _content_width()) * 0.5
	# Les puces, une par génération.
	for chip_value in _chips:
		var chip: Dictionary = chip_value
		var texture: Texture2D = CHIP.era_texture(int(chip.node))
		if texture != null:
			draw_texture_rect(texture, Rect2(Vector2(x, plank_y - 40.0), Vector2(40, 40)), false)
		else:
			draw_rect(Rect2(Vector2(x + 6.0, plank_y - 30.0), Vector2(28, 28)), Color("3a3a3a"))
		x += 44.0
	if not _chips.is_empty():
		x += 8.0
	# Les trophées de carrière (coupes) puis les Unes encadrées.
	for i in range(mini(_trophies, 4)):
		_draw_cup(Vector2(x + 12.0, plank_y))
		x += 28.0
	if _trophies > 4:
		_draw_tag(Vector2(x, plank_y - 22.0), "×%d" % _trophies)
		x += 30.0
	for i in range(mini(_front_pages, 3)):
		_draw_cover(Vector2(x, plank_y - 30.0))
		x += 26.0
	if _front_pages > 3:
		_draw_tag(Vector2(x, plank_y - 22.0), "×%d" % _front_pages)

func _draw_cup(base: Vector2) -> void:
	var cup := PackedVector2Array([base + Vector2(-9, -30), base + Vector2(9, -30), base + Vector2(6, -16), base + Vector2(-6, -16)])
	draw_colored_polygon(cup, GOLD)
	draw_rect(Rect2(base + Vector2(-2, -16), Vector2(4, 8)), GOLD.darkened(0.15))
	draw_rect(Rect2(base + Vector2(-7, -8), Vector2(14, 8)), WOOD_DARK)
	draw_arc(base + Vector2(-9, -25), 4.0, PI * 0.5, PI * 1.5, 8, GOLD, 2.0)
	draw_arc(base + Vector2(9, -25), 4.0, -PI * 0.5, PI * 0.5, 8, GOLD, 2.0)

func _draw_cover(top_left: Vector2) -> void:
	draw_rect(Rect2(top_left + Vector2(1, 1), Vector2(20, 28)), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(top_left, Vector2(20, 28)), WOOD_DARK)
	draw_rect(Rect2(top_left + Vector2(2, 2), Vector2(16, 24)), CREAM)
	draw_rect(Rect2(top_left + Vector2(2, 2), Vector2(16, 6)), Color("b5482b"))
	for k in range(3):
		draw_rect(Rect2(top_left + Vector2(4, 12 + k * 4), Vector2(12, 1.5)), Color("8a7a68"))

func _draw_tag(pos: Vector2, text: String) -> void:
	var font := get_theme_default_font()
	draw_string_outline(font, pos + Vector2(0, 16), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0, 0.6))
	draw_string(font, pos + Vector2(0, 16), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CREAM)

func _draw_event_sign() -> void:
	var font := get_theme_default_font()
	var text := "⚑ " + _event
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 22.0
	var top := (_shelf.end.y + 2.0) if shelf_visible() else 14.0
	var rect := Rect2(Vector2(size.x * 0.5 - width * 0.5, top + 6.0), Vector2(width, 24.0))
	draw_line(Vector2(rect.position.x + 12.0, top), rect.position + Vector2(12, 0), WOOD_DARK, 2.0)
	draw_line(Vector2(rect.end.x - 12.0, top), Vector2(rect.end.x - 12.0, rect.position.y), WOOD_DARK, 2.0)
	draw_style_box(UI.stylebox(Color("b5482b"), 6, 1, Color("7a2e1b"), 4), rect)
	draw_string(font, rect.position + Vector2(11, 17), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CREAM)
