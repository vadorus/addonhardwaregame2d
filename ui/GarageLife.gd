extends Control
## V0.10 / K2 — le QG vit : il raconte la partie sans qu'on ouvre un menu.
## - une étagère murale en haut : vos générations de CPU (puces d'Astra), vos trophées de carrière,
##   vos « Unes » de la presse et la taille de l'équipe ;
## - les saisons : neige l'hiver (guirlande en décembre), pétales au printemps, poussière dorée l'été,
##   feuilles l'automne ;
## - les événements du moment (salon, guerre des prix, pénurie…) sur une petite pancarte.
## Toucher l'étagère ouvre le détail. Dessiné sous les cartes du QG, avec les images d'Astra
## (fêtes J6, vitrine J7) quand elles sont là, sinon en code.

## La nuit tombe ou la météo change : le QG peut passer sur un décor d'ambiance (nuit, pluie) d'Astra.
signal ambiance_changed

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
## K3 (01/10, idée d'Alexandre) : le temps qu'il fait et le moment de la journée, pour sentir le temps passer.
## Météo tirée chaque mois selon la saison (toujours la même pour un mois donné) ; journée qui avance avec le
## jeu (figée en pause) : matin, journée, soir, nuit avec les lampes allumées. Rien ne change le jeu.
const WEATHER_WEIGHTS := {
	"WINTER":[["SNOW", 40], ["CLOUDY", 25], ["SUNNY", 20], ["FOG", 15]],
	"SPRING":[["SUNNY", 45], ["RAIN", 30], ["CLOUDY", 25]],
	"SUMMER":[["SUNNY", 60], ["STORM", 15], ["CLOUDY", 15], ["RAIN", 10]],
	"AUTUMN":[["RAIN", 35], ["CLOUDY", 25], ["FOG", 20], ["SUNNY", 20]]}
const WEATHER_LABELS := {"SUNNY":"beau temps", "CLOUDY":"nuageux", "RAIN":"pluie", "STORM":"orage", "SNOW":"neige", "FOG":"brouillard"}
const WEATHER_TINTS := {"CLOUDY":Color(0.4, 0.42, 0.48, 0.12), "RAIN":Color(0.26, 0.32, 0.44, 0.2),
	"STORM":Color(0.18, 0.22, 0.34, 0.26), "SNOW":Color(0.85, 0.9, 1.0, 0.08), "FOG":Color(0.9, 0.9, 0.92, 0.1)}
## Une journée complète dure 2 minutes à vitesse ×1 (elle va plus vite en accéléré, et s'arrête en pause).
const DAY_SECONDS := 120.0
const DAY_KEYS := [[0.0, Color(0.95, 0.55, 0.55, 0.10)], [0.10, Color(1, 1, 1, 0.0)], [0.55, Color(1, 1, 1, 0.0)],
	[0.65, Color(1.0, 0.5, 0.2, 0.15)], [0.75, Color(0.05, 0.07, 0.2, 0.38)], [0.92, Color(0.05, 0.07, 0.2, 0.38)],
	[1.0, Color(0.95, 0.55, 0.55, 0.10)]]
## Lampes de chaque décor (position dans l'image), allumées le soir et la nuit.
const LAMPS := {
	0:[Vector2(0.05, 0.37), Vector2(0.525, 0.2), Vector2(0.615, 0.42), Vector2(0.40, 0.50), Vector2(0.27, 0.36)],
	1:[Vector2(0.49, 0.17), Vector2(0.15, 0.42), Vector2(0.36, 0.38), Vector2(0.62, 0.40), Vector2(0.80, 0.33)],
	2:[Vector2(0.28, 0.18), Vector2(0.55, 0.12), Vector2(0.42, 0.45), Vector2(0.70, 0.35), Vector2(0.85, 0.30)],
	3:[Vector2(0.25, 0.30), Vector2(0.45, 0.25), Vector2(0.62, 0.30), Vector2(0.80, 0.25), Vector2(0.50, 0.50)]}
const RAIN_DROPS := 260

## J6 : les fêtes du moment. Les objets d'Astra (assets/art/v010/J6_fetes/) apparaissent dès qu'ils
## sont livrés ; sans fichier, rien n'est dessiné. [fichier, x, y, hauteur (part de la hauteur du décor)]
## Livrés le 01/10 : à l'écran, chaque objet reste entier et évite l'équipe (_fit_prop) ; la guirlande
## court le long du haut de l'écran ; la toile pend en haut, à gauche de la carte de projet.
const FETE_DIR := "res://assets/art/v010/J6_fetes/"
const FETE_LABELS := {"NOEL":"Noël", "NOUVEL_AN":"Nouvel An", "HALLOWEEN":"Halloween", "PAQUES":"Pâques",
	"ETE":"les vacances d'été", "ANNIVERSAIRE":"l'anniversaire de l'entreprise"}
const FETE_PROPS := {
	"NOEL":[["fete_noel_sapin", 0.30, 0.84, 0.30], ["fete_noel_guirlande", 0.50, 0.10, 0.08]],
	"NOUVEL_AN":[["fete_nouvel_an_ballons", 0.70, 0.80, 0.26], ["fete_nouvel_an_table", 0.62, 0.86, 0.13]],
	"HALLOWEEN":[["fete_halloween_citrouilles", 0.33, 0.86, 0.10], ["fete_halloween_toile", 0.70, 0.12, 0.18]],
	"PAQUES":[["fete_paques_panier", 0.34, 0.85, 0.09]],
	"ETE":[["fete_ete_ventilateur", 0.68, 0.82, 0.20]],
	"ANNIVERSAIRE":[["fete_anniversaire_gateau", 0.56, 0.86, 0.17]]}

## J7 : la vitrine d'Astra (étagère, coupes, Unes encadrées, pancarte). Sans fichier, on garde le dessin en code.
const SHOWCASE_DIR := "res://assets/art/v010/J7_vitrine/"
## Coupe en or pour les grands trophées (prestige ≥ 1,2), en argent pour les autres.
const GOLD_PRESTIGE := 1.2
## Tailles à l'écran. L'étagère (1000 × 90) et la pancarte (640 × 110) s'allongent par le milieu :
## leurs bouts (équerres, ficelles) gardent leurs proportions. Les objets posent à 22/90 de l'étagère.
const SHELF_H := 34.0
const SHELF_FOOT := 22.0 / 90.0
const SHELF_CAP := 210.0
const SIGN_H := 44.0
const SIGN_CAP := 110.0
const SIGN_TEXT_Y := 79.0 / 110.0
const CUP_H := 36.0
const COVER_H := 34.0

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
var _trophy_gold: Array[bool] = []
var _showcase_textures := {}
var _front_pages := 0
var _staff := 0
var _event := ""
var _garland := false
var _shelf := Rect2()
var _shelf_button: Button
var _card: PanelContainer
var _card_label: Label
var _time := 0.0
var _weather := "SUNNY"
var _weather_month := -1
var _drops: Array = []
var _day := -1.0
var _flash := 0.0
var _next_flash := 4.0
var _glow: GradientTexture2D
## Vrai si le décor affiché est déjà la version nuit d'Astra (on n'assombrit plus en code).
var night_art := false
var _fetes: Array = []
var _fete_textures := {}
var _was_night := false

## La pluie et la neige tombent dehors : au-dessus des murs et sur le trottoir, pas au milieu des bureaux.
static func outdoors(y: float) -> bool:
	return y < 0.17 or y > 0.84

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
		"front_pages":_front_pages, "staff":_staff, "event":_event, "shelf_visible":shelf_visible(),
		"weather":_weather, "day_phase":day_phase_name(), "night":night_amount(), "fetes":_fetes.duplicate(),
		"showcase_art":_showcase_texture("vitrine_etagere") != null, "gold_cups":_trophy_gold.count(true)}

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
	var month_index := TimeManager.year * 12 + TimeManager.month
	if month_index != _weather_month:
		_weather_month = month_index
		_weather = weather_for(TimeManager.year, TimeManager.month)
		_spawn_particles()
		ambiance_changed.emit()
		if _day < 0.0:
			_day = fmod(float(month_index) * 0.37, 1.0)
	_garland = TimeManager.month == 12
	_fetes = fetes_for(TimeManager.year, TimeManager.month, TimeManager.day, CompanyManager.founded_year)
	_chips = generation_chips()
	_trophy_labels.clear()
	_trophy_gold.clear()
	for row_value in CAREER.trophy_rows():
		var row: Dictionary = row_value
		if bool(row.get("unlocked", false)):
			_trophy_labels.append(str(row.get("label", "")))
			var data: Dictionary = CAREER.TROPHIES.get(str(row.get("id", "")), {})
			_trophy_gold.append(float(data.get("prestige", 0.0)) >= GOLD_PRESTIGE)
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
	# K4 : la période commerciale du moment (rentrée, fêtes…).
	var period: Dictionary = (load("res://scripts/SeasonalCalendar.gd") as Script).call("period", TimeManager.month)
	if not period.is_empty():
		return str(period.title)
	return ""

## Largeur des objets posés sur l'étagère (l'étagère s'adapte à son contenu).
func _content_width() -> float:
	var w := 44.0 * float(_chips.size())
	if not _chips.is_empty():
		w += 8.0
	w += 30.0 * float(mini(_trophies, 4)) + (30.0 if _trophies > 4 else 0.0)
	w += 28.0 * float(mini(_front_pages, 3)) + (30.0 if _front_pages > 3 else 0.0)
	return w

func _layout() -> void:
	# Les équerres de l'étagère d'Astra prennent ~55 px de chaque côté : l'étagère ne descend pas en dessous de 190 px.
	var width := clampf(_content_width() + 60.0, 190.0, maxf(size.x * 0.45, 190.0))
	_shelf = Rect2(Vector2((size.x - width) * 0.5, 12.0), Vector2(width, 80.0))
	_shelf_button.position = _shelf.position
	_shelf_button.size = _shelf.size
	_shelf_button.visible = shelf_visible()
	_card.position = Vector2(_shelf.position.x, _shelf.end.y + (SIGN_H + 4.0 if _event != "" else 6.0)) + position
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
	if not _fetes.is_empty():
		var names: Array[String] = []
		for fete in _fetes:
			names.append(str(FETE_LABELS.get(str(fete), fete)))
		lines.append("C'est " + " et ".join(names) + " !")
	lines.append("Saison : %s • %s • %s" % [str(SEASON_LABELS.get(_season, "")), str(WEATHER_LABELS.get(_weather, "")), day_phase_name()])
	return "\n".join(lines)

# --- Saisons -----------------------------------------------------------------------------------------

## Les fêtes du moment (plusieurs possibles le même mois).
static func fetes_for(year: int, month: int, day: int, founded_year: int) -> Array:
	var out: Array = []
	match month:
		12:
			out.append("NOEL")
		1:
			out.append("NOUVEL_AN")
			if year > founded_year:
				out.append("ANNIVERSAIRE")
		10:
			if day >= 15:
				out.append("HALLOWEEN")
		4:
			out.append("PAQUES")
		7, 8:
			out.append("ETE")
	return out

func _fete_texture(name: String) -> Texture2D:
	if not _fete_textures.has(name):
		var path := FETE_DIR + name + ".png"
		_fete_textures[name] = load(path) if ResourceLoader.exists(path) else null
	return _fete_textures[name]

func _draw_fetes() -> void:
	if _fetes.is_empty():
		return
	var view := Rect2(Vector2.ZERO, size).intersection(art_rect)
	var obstacles := _people_rects()
	for fete in _fetes:
		for prop_value in FETE_PROPS.get(str(fete), []):
			var prop: Array = prop_value
			var texture := _fete_texture(str(prop[0]))
			if texture == null:
				continue
			if str(prop[0]) == "fete_noel_guirlande":
				_draw_garland_art(texture)
				continue
			var h := art_rect.size.y * float(prop[3])
			var w := h * float(texture.get_width()) / maxf(float(texture.get_height()), 1.0)
			var foot := art_rect.position + Vector2(float(prop[1]), float(prop[2])) * art_rect.size
			var rect := _fit_prop(Rect2(foot - Vector2(w * 0.5, h), Vector2(w, h)), view, obstacles)
			obstacles.append(rect)
			draw_texture_rect(texture, rect, false)

## Où sont Nora et l'équipe à l'écran (rectangles des personnages, pieds aux postes du décor).
func _people_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var tier := clampi(int(ExecutiveManager.workplace.get("tier", 0)), 0, 3)
	var layout: Dictionary = WORKPLACE.crew_layout(tier)
	var ch := art_rect.size.y * float(layout.scale)
	var spots: Array = [layout.nora]
	var seats: Array = layout.seats
	for i in range(mini(_staff, seats.size())):
		var seat: Vector3 = seats[i]
		spots.append(Vector2(seat.x, seat.y))
	for spot_value in spots:
		var foot := art_rect.position + (spot_value as Vector2) * art_rect.size
		out.append(Rect2(foot - Vector2(ch * 0.3, ch), Vector2(ch * 0.6, ch)))
	return out

## Un objet de fête reste entier à l'écran (sur téléphone, le décor est rogné en haut et en bas) et
## se décale sur le côté s'il cache quelqu'un ou un autre objet.
func _fit_prop(rect: Rect2, view: Rect2, obstacles: Array[Rect2]) -> Rect2:
	const MARGIN := 4.0
	rect.position.y = clampf(rect.position.y, view.position.y + MARGIN, maxf(view.end.y - MARGIN - rect.size.y, view.position.y + MARGIN))
	for attempt in range(3):
		var moved := false
		for obstacle in obstacles:
			if rect.intersection(obstacle).get_area() < obstacle.get_area() * 0.08:
				continue
			var left := obstacle.position.x - rect.end.x - 4.0
			var right := obstacle.end.x - rect.position.x + 4.0
			var shift := left if absf(left) < absf(right) else right
			if rect.position.x + shift < view.position.x or rect.end.x + shift > view.end.x:
				shift = right if shift == left else left
			rect.position.x += shift
			moved = true
		if not moved:
			break
	rect.position.x = clampf(rect.position.x, view.position.x + MARGIN, maxf(view.end.x - MARGIN - rect.size.x, view.position.x + MARGIN))
	return rect

## La météo d'un mois : tirée selon la saison, toujours la même pour ce mois-là.
static func weather_for(year: int, month: int) -> String:
	var weights: Array = WEATHER_WEIGHTS.get(str(SEASONS.get(month, "SUMMER")), [["SUNNY", 1]])
	var total := 0
	for pair in weights:
		total += int(pair[1])
	var roll := absi(hash("meteo:%d:%d" % [year, month])) % maxi(total, 1)
	for pair in weights:
		roll -= int(pair[1])
		if roll < 0:
			return str(pair[0])
	return "SUNNY"

func day_phase_name() -> String:
	var d := maxf(_day, 0.0)
	if d < 0.10 or d >= 0.95:
		return "matin"
	if d < 0.58:
		return "journée"
	if d < 0.70:
		return "soir"
	return "nuit"

## 0 = plein jour, 1 = pleine nuit.
func night_amount() -> float:
	return clampf((_day_tint().a - 0.15) / 0.23, 0.0, 1.0) if _day_tint().b > 0.15 else 0.0

func _day_tint() -> Color:
	var d := maxf(_day, 0.0)
	for i in range(DAY_KEYS.size() - 1):
		var a: Array = DAY_KEYS[i]
		var b: Array = DAY_KEYS[i + 1]
		if d >= float(a[0]) and d <= float(b[0]):
			var t := (d - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			return (a[1] as Color).lerp(b[1] as Color, t)
	return Color(1, 1, 1, 0)

func set_day_phase(value: float) -> void:
	_day = fposmod(value, 1.0)
	_was_night = night_amount() >= 0.5
	ambiance_changed.emit()
	queue_redraw()

func _spawn_particles() -> void:
	_particles.clear()
	_drops.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_season + _weather)
	if _weather in ["RAIN", "STORM"]:
		for i in range(RAIN_DROPS):
			_drops.append({"x":rng.randf(), "y":rng.randf(), "speed":rng.randf_range(0.9, 1.4), "len":rng.randf_range(10.0, 18.0)})
		return
	var count := int(PARTICLES.get(_season, 0))
	if _weather == "SNOW":
		count = 95
	elif _weather == "FOG":
		count = count / 2
	for i in range(count):
		_particles.append({"x":rng.randf(), "y":rng.randf(), "speed":rng.randf_range(0.025, 0.06),
			"sway":rng.randf_range(0.004, 0.018), "phase":rng.randf() * TAU, "size":rng.randf_range(1.4, 3.2)})

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not CompanyManager.created:
		return
	_time += delta
	if _day >= 0.0 and TimeManager.time_scale > 0.0:
		_day = fposmod(_day + delta * TimeManager.time_scale / DAY_SECONDS, 1.0)
		var is_night := night_amount() >= 0.5
		if is_night != _was_night:
			_was_night = is_night
			ambiance_changed.emit()
	for d_value in _drops:
		var d: Dictionary = d_value
		d.y = float(d.y) + float(d.speed) * delta
		if d.y > 1.02:
			d.y = -0.05
			d.x = fposmod(float(d.x) + 0.37, 1.0)
	if _weather == "STORM":
		_flash = maxf(_flash - delta * 3.0, 0.0)
		_next_flash -= delta
		if _next_flash <= 0.0:
			_flash = 1.0
			_next_flash = 5.0 + fposmod(_time * 7.3, 6.0)
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
	draw_rect(view, WEATHER_TINTS.get(_weather, Color(0, 0, 0, 0)))
	if _weather == "FOG":
		for k in range(4):
			var band := Rect2(view.position.x, view.position.y + view.size.y * (0.45 + 0.13 * k), view.size.x, view.size.y * 0.13)
			draw_rect(band, Color(0.95, 0.95, 0.97, 0.05 + 0.03 * k))
	_draw_fetes()
	_draw_day(view)
	_draw_particles(view)
	_draw_rain(view)
	if _flash > 0.0:
		draw_rect(view, Color(1, 1, 1, 0.35 * _flash))
	if _garland and _fete_texture("fete_noel_guirlande") == null:
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
				if not outdoors((pos.y - art_rect.position.y) / maxf(art_rect.size.y, 1.0)):
					continue
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

## La guirlande d'Astra court tout le long du haut de l'écran (le haut du décor est souvent coupé
## sur téléphone) : autant de guirlandes côte à côte qu'il faut, à 30-60 px de haut.
func _draw_garland_art(texture: Texture2D) -> void:
	var view := Rect2(Vector2.ZERO, size).intersection(art_rect)
	if view.size.x <= 0.0:
		return
	var ratio := float(texture.get_width()) / maxf(float(texture.get_height()), 1.0)
	var natural_w := clampf(view.size.y * 0.085, 30.0, 60.0) * ratio
	var count := maxi(1, roundi(view.size.x / natural_w))
	var w := view.size.x / float(count)
	var h := w / ratio
	for i in range(count):
		draw_texture_rect(texture, Rect2(Vector2(view.position.x + w * float(i), view.position.y + 2.0), Vector2(w, h)), false)

func _showcase_texture(name: String) -> Texture2D:
	if not _showcase_textures.has(name):
		var path := SHOWCASE_DIR + name + ".png"
		_showcase_textures[name] = load(path) if ResourceLoader.exists(path) else null
	return _showcase_textures[name]

## Dessine une image en l'allongeant par le milieu seulement : ses deux bouts (cap, en pixels de l'image)
## gardent leurs proportions, à l'échelle de la hauteur demandée.
func _draw_capped(texture: Texture2D, rect: Rect2, cap: float) -> void:
	var th := float(texture.get_height())
	var tw := float(texture.get_width())
	var s := rect.size.y / th
	var cap_px := minf(cap * s, rect.size.x * 0.5)
	var cap_src := cap_px / s
	draw_texture_rect_region(texture, Rect2(rect.position, Vector2(cap_px, rect.size.y)), Rect2(0, 0, cap_src, th))
	draw_texture_rect_region(texture, Rect2(rect.position + Vector2(cap_px, 0), Vector2(rect.size.x - cap_px * 2.0, rect.size.y)),
		Rect2(cap_src, 0, tw - cap_src * 2.0, th))
	draw_texture_rect_region(texture, Rect2(Vector2(rect.end.x - cap_px, rect.position.y), Vector2(cap_px, rect.size.y)),
		Rect2(tw - cap_src, 0, cap_src, th))

func _draw_shelf() -> void:
	var r := _shelf
	var plank_y := r.position.y + 50.0
	var shelf_art := _showcase_texture("vitrine_etagere")
	if shelf_art != null:
		_draw_capped(shelf_art, Rect2(r.position.x, plank_y - SHELF_H * SHELF_FOOT, r.size.x, SHELF_H), SHELF_CAP)
	else:
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
		var gold := i < _trophy_gold.size() and _trophy_gold[i]
		var cup_art := _showcase_texture("trophee_or" if gold else "trophee_argent")
		if cup_art != null:
			var cup_w := CUP_H * float(cup_art.get_width()) / float(cup_art.get_height())
			draw_texture_rect(cup_art, Rect2(Vector2(x + 15.0 - cup_w * 0.5, plank_y - CUP_H), Vector2(cup_w, CUP_H)), false)
		else:
			_draw_cup(Vector2(x + 12.0, plank_y))
		x += 30.0
	if _trophies > 4:
		_draw_tag(Vector2(x, plank_y - 22.0), "×%d" % _trophies)
		x += 30.0
	var cover_art := _showcase_texture("une_encadree")
	for i in range(mini(_front_pages, 3)):
		if cover_art != null:
			var cover_w := COVER_H * float(cover_art.get_width()) / float(cover_art.get_height())
			draw_texture_rect(cover_art, Rect2(Vector2(x + 14.0 - cover_w * 0.5, plank_y - COVER_H), Vector2(cover_w, COVER_H)), false)
		else:
			_draw_cover(Vector2(x, plank_y - 30.0))
		x += 28.0
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
	var top := (_shelf.end.y + 2.0) if shelf_visible() else 14.0
	var sign_art := _showcase_texture("pancarte_evenement")
	if sign_art != null:
		# La pancarte d'Astra pend à ses ficelles ; le jeu écrit au milieu de la planche.
		var label := _event
		var text_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var s := SIGN_H / float(sign_art.get_height())
		var sign_w := maxf(text_w + 40.0, SIGN_CAP * s * 2.0 + 20.0)
		# Sous l'étagère, les ficelles partent de dessous la planche, entre les équerres.
		var sign_top := (top - 16.0) if shelf_visible() else (top - 4.0)
		var sign_rect := Rect2(Vector2(size.x * 0.5 - sign_w * 0.5, sign_top), Vector2(sign_w, SIGN_H))
		_draw_capped(sign_art, sign_rect, SIGN_CAP)
		var base := Vector2(size.x * 0.5 - text_w * 0.5, sign_rect.position.y + SIGN_H * SIGN_TEXT_Y + 5.0)
		draw_string_outline(font, base, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, Color("4a1a10", 0.7))
		draw_string(font, base, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CREAM)
		return
	var text := "⚑ " + _event
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 22.0
	var rect := Rect2(Vector2(size.x * 0.5 - width * 0.5, top + 6.0), Vector2(width, 24.0))
	draw_line(Vector2(rect.position.x + 12.0, top), rect.position + Vector2(12, 0), WOOD_DARK, 2.0)
	draw_line(Vector2(rect.end.x - 12.0, top), Vector2(rect.end.x - 12.0, rect.position.y), WOOD_DARK, 2.0)
	draw_style_box(UI.stylebox(Color("b5482b"), 6, 1, Color("7a2e1b"), 4), rect)
	draw_string(font, rect.position + Vector2(11, 17), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CREAM)

func _draw_day(view: Rect2) -> void:
	var tint := _day_tint()
	if night_art:
		tint.a *= 0.25
	if tint.a <= 0.0:
		return
	draw_rect(view, tint)
	var night := night_amount()
	if night <= 0.0 or art_rect.size.x <= 0.0:
		return
	# Les lampes du décor s'allument : halos chauds superposés.
	if _glow == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 0.8, 0.45, 0.55))
		gradient.set_color(1, Color(1.0, 0.8, 0.45, 0.0))
		_glow = GradientTexture2D.new()
		_glow.gradient = gradient
		_glow.fill = GradientTexture2D.FILL_RADIAL
		_glow.fill_from = Vector2(0.5, 0.5)
		_glow.fill_to = Vector2(1.0, 0.5)
		_glow.width = 128
		_glow.height = 128
	var tier := clampi(int(ExecutiveManager.workplace.get("tier", 0)), 0, 3)
	var radius := art_rect.size.x * 0.06
	for spot_value in LAMPS.get(tier, []):
		var spot: Vector2 = spot_value
		var center := art_rect.position + spot * art_rect.size
		draw_texture_rect(_glow, Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, Color(1, 1, 1, night))

func _draw_rain(view: Rect2) -> void:
	if _drops.is_empty():
		return
	for d_value in _drops:
		var d: Dictionary = d_value
		var pos := view.position + Vector2(float(d.x) * view.size.x, float(d.y) * view.size.y)
		var art_y := (pos.y - art_rect.position.y) / maxf(art_rect.size.y, 1.0)
		if not outdoors(art_y):
			continue
		draw_line(pos, pos + Vector2(-0.25, 1.0) * float(d.len), Color(0.85, 0.9, 1.0, 0.75), 1.6)
