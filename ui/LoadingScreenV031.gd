extends Control

const MAIN_SCENE := "res://main.tscn"
const WORKSHOP_ART: Texture2D = preload("res://assets/ui/runtime/menu/menu_background_1971.png")
const LOGO_ART: Texture2D = preload("res://assets/ui/runtime/branding/tech_empire_logo.png")

const TIPS: Array[String] = [
	"Un contrat trop difficile peut être rentable… ou vous faire perdre plusieurs semaines.",
	"La compétence Programmation augmente directement vos points de développement par jour.",
	"Une approche rapide produit davantage, mais crée plus facilement des défauts.",
	"Votre premier garage n'est pas qu'un décor : chaque nouvel outil doit finir par changer ce que vous pouvez réaliser.",
	"Tech Empire commence en 1971. Les technologies apparaissent progressivement avec votre expérience et l'époque.",
	"Les contrats logiciels restent utiles après le premier CPU : ils financent et outillent votre R&D."
]

var _progress_bar: ProgressBar
var _status_label: Label
var _tip_label: Label
var _requested := false
var _switching := false

func _ready() -> void:
	_build_loading_screen()
	var error: Error = ResourceLoader.load_threaded_request(MAIN_SCENE, "", true)
	if error != OK:
		_show_error("Impossible de préparer la scène principale.")
		return
	_requested = true
	set_process(true)

func _process(_delta: float) -> void:
	if not _requested or _switching:
		return
	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(MAIN_SCENE, progress)
	if not progress.is_empty():
		_progress_bar.value = clampf(float(progress[0]) * 100.0, 4.0, 96.0)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_status_label.text = _loading_status_for_progress(_progress_bar.value)
		ResourceLoader.THREAD_LOAD_LOADED:
			_switching = true
			_progress_bar.value = 100.0
			_status_label.text = "Ouverture du garage…"
			var loaded: Resource = ResourceLoader.load_threaded_get(MAIN_SCENE)
			var packed: PackedScene = loaded as PackedScene
			if packed == null:
				_show_error("La scène principale est invalide.")
				return
			await get_tree().process_frame
			get_tree().change_scene_to_packed(packed)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_show_error("Le chargement de Tech Empire a échoué.")

func _build_loading_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background_color := ColorRect.new()
	background_color.color = Color("#07111c")
	background_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_color)

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var use_workshop: bool = rng.randi_range(0, 1) == 0

	var art := TextureRect.new()
	art.texture = WORKSHOP_ART if use_workshop else LOGO_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if use_workshop else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not use_workshop:
		art.modulate = Color(0.82, 0.90, 0.96, 0.94)
	add_child(art)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.045, 0.58 if use_workshop else 0.30)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 42)
	safe.add_theme_constant_override("margin_top", 36)
	safe.add_theme_constant_override("margin_right", 42)
	safe.add_theme_constant_override("margin_bottom", 38)
	add_child(safe)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 10)
	safe.add_child(column)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var era := Label.new()
	era.text = "1971  •  LE GARAGE"
	era.add_theme_color_override("font_color", Color("#f2bd5b"))
	era.add_theme_font_size_override("font_size", 16)
	column.add_child(era)

	var title := Label.new()
	title.text = "Tech Empire"
	title.add_theme_color_override("font_color", Color("#f4f0e7"))
	title.add_theme_font_size_override("font_size", 34)
	column.add_child(title)

	_status_label = Label.new()
	_status_label.text = "Préparation de votre atelier…"
	_status_label.add_theme_color_override("font_color", Color("#d8e7f0"))
	_status_label.add_theme_font_size_override("font_size", 17)
	column.add_child(_status_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 4
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 18)
	column.add_child(_progress_bar)

	_tip_label = Label.new()
	var tip_index: int = rng.randi_range(0, TIPS.size() - 1)
	_tip_label.text = "ASTUCE  •  " + TIPS[tip_index]
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.add_theme_color_override("font_color", Color("#a9bfce"))
	_tip_label.add_theme_font_size_override("font_size", 14)
	column.add_child(_tip_label)

func _loading_status_for_progress(value: float) -> String:
	if value < 30.0:
		return "Chargement des systèmes…"
	if value < 65.0:
		return "Préparation de l'atelier…"
	if value < 90.0:
		return "Installation de l'interface…"
	return "Presque prêt…"

func _show_error(message: String) -> void:
	_requested = false
	_switching = false
	set_process(false)
	_progress_bar.value = 0.0
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Color("#ff7b7b"))
