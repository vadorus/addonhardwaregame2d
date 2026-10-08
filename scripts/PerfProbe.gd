extends Node
## P0 - Instrumentation locale, desactivee tant que l'utilisateur ne l'active pas.
## Aucun paquet reseau, aucune decision de jeu et aucune ecriture CSV en cours de serie.

signal status_changed(message: String)

const REFERENCE := "user://perf_reference.json"
const SANDBOX := "user://perf_sandbox/"
const FRAME_CAPACITY := 48000
const MONTH_TARGET := 12
const TAB_ORDER := [0, 1, 2, 3, 4, 5, 6]
const CSV_HEADER := "series,type,index,screen,mean_ms,p50_ms,p95_ms,p99_ms,worst_ms,over_50,over_100,simulation_ms,refresh_ms,other_ms,tab_ms,checkpoint,result,commit,fps_setting,reference_sha,process_mean_ms,slow_screen"

var enabled := false
var _secret_taps := 0
var _game: Control
var _panel_layer: CanvasLayer
var _panel: PanelContainer
var _summary: Label
var _state := "idle"
var _series := ""
var _screen_name := ""
var _screen_id := 0
var _start_us := 0
var _prev_us := 0
var _finish_after_frame := -1
var _frame_values := PackedFloat32Array()
var _process_values := PackedFloat32Array()
var _frame_count := 0
var _pending_month: Dictionary = {}
var _month_count := 0
var _month_rows: Array[Dictionary] = []
var _tab_rows: Array[Dictionary] = []
var _span_starts: Dictionary = {}
var _frame_sim_ms := 0.0
var _frame_ui_ms := 0.0
var _frame_screens: Dictionary = {}
var _max_month_frame := 0.0
var _max_month_sim := 0.0
var _max_month_ui := 0.0
var _max_month_screen := ""
var _tab_request_us := 0
var _tab_request_index := -1
var _tab_step := 0
var _last_tick_frame := -1
var _reference_hash := ""
var reference_path := REFERENCE
var _previous_checkpoints: Dictionary = {}
var _output_sequence := 0
var last_csv_path := ""
var last_result := ""

func _ready() -> void:
	set_process(false)
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if str(arg) == "--perf-probe":
			enable()
			break

func attach_game(game: Control) -> void:
	_game = game

func secret_tap() -> void:
	_secret_taps += 1
	if _secret_taps >= 5:
		_secret_taps = 0
		enable()
		show_panel()

func enable() -> void:
	if enabled:
		return
	enabled = true
	set_process(true)
	status_changed.emit("P0 actif : aucune mesure avant de lancer une serie.")

func show_panel() -> void:
	if not enabled or _game == null:
		return
	if _panel_layer == null:
		_build_panel()
	_panel_layer.visible = true
	_update_summary()

func hide_panel() -> void:
	if _panel_layer != null:
		_panel_layer.visible = false

func _build_panel() -> void:
	_panel_layer = CanvasLayer.new()
	_panel_layer.layer = 200
	get_tree().root.add_child(_panel_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.03, 0.04, 0.07, 0.92)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_layer.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_layer.add_child(center)
	var scroll := ScrollContainer.new()
	# Sur Android, une hauteur minimale nulle collapse ce ScrollContainer :
	# le fond de P0 s'affichait, mais aucun bouton n'etait visible.
	var available_height := get_viewport().get_visible_rect().size.y
	scroll.custom_minimum_size = Vector2(560, maxf(240.0, minf(650.0, available_height - 64.0)))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(scroll)
	_panel = PanelContainer.new()
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.13, 0.17, 1.0)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	scroll.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "P0 - Mesures locales (partie de test)"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size.x = 490
	box.add_child(_summary)
	_add_button(box, "Copier la sauvegarde existante comme reference", capture_reference)
	_add_button(box, "Comparaison a 30 images/s", set_probe_fps.bind(30))
	_add_button(box, "Comparaison a 60 images/s", set_probe_fps.bind(60))
	_add_button(box, "QG : 12 fins de mois a x3", start_month_series.bind(0))
	_add_button(box, "Entreprise : 12 fins de mois a x3", start_month_series.bind(1))
	_add_button(box, "Produits : 12 fins de mois a x3", start_month_series.bind(4))
	_add_button(box, "QG en pause : 30 secondes", start_idle_series.bind(false))
	_add_button(box, "QG a x1 : 60 secondes", start_idle_series.bind(true))
	_add_button(box, "Trois tours des sept onglets", start_tab_series)
	_add_button(box, "Masquer P0", hide_panel)

func _add_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 36
	button.pressed.connect(action)
	parent.add_child(button)

func _update_summary() -> void:
	if _summary == null:
		return
	var ref_text := "presente" if FileAccess.file_exists(reference_path) else "ABSENTE"
	_summary.text = "Reference : %s\nEtat : %s\nDernier resultat : %s\nCSV : %s\nAucun transfert Internet." % [
		ref_text, _state, last_result, last_csv_path
	]

func set_probe_fps(target: int) -> void:
	if not enabled or _state != "idle":
		return
	Engine.max_fps = target
	_report("Plafond de comparaison : %d images/s." % target)

func capture_reference() -> void:
	if _state != "idle":
		_report("Impossible : une serie est en cours.")
		return
	if SaveManager.save_root != "user://":
		_report("Quitter et relancer le jeu avant de copier une nouvelle reference.")
		return
	var source: String = SaveManager.save_path()
	if FileAccess.file_exists(reference_path):
		_report("Une reference existe deja. Elle reste inchangee.")
		return
	if not FileAccess.file_exists(source):
		_report("Sauvegarde absente. Importer d'abord une COPIE saine de la partie.")
		return
	if DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(reference_path)) != OK:
		_report("Impossible de copier la sauvegarde de reference.")
		return
	_reference_hash = FileAccess.get_sha256(reference_path)
	_report("Copie de reference creee. Original non modifie.")

func _prepare_reference() -> bool:
	if _game == null or not FileAccess.file_exists(reference_path):
		_report("Reference absente : il faut une copie de sauvegarde saine.")
		return false
	var global_sandbox := ProjectSettings.globalize_path(SANDBOX)
	if DirAccess.make_dir_recursive_absolute(global_sandbox) != OK:
		_report("Dossier de test inaccessible.")
		return false
	for suffix in [".tmp", ".bak"]:
		var old := global_sandbox.path_join("tech_empire_save.json" + suffix)
		if FileAccess.file_exists(old):
			DirAccess.remove_absolute(old)
	var destination := global_sandbox.path_join("tech_empire_save.json")
	if DirAccess.copy_absolute(ProjectSettings.globalize_path(reference_path), destination) != OK:
		_report("Impossible d'isoler la sauvegarde de test.")
		return false
	_reference_hash = FileAccess.get_sha256(reference_path)
	# Ne jamais ecrire la sauvegarde de l'utilisateur pendant le banc d'essai.
	SaveManager.save_root = SANDBOX
	SaveManager.writes_enabled = false
	_game.call("_load_game_slot", 0)
	_game.set("menu_previous_speed", 0.0)
	_game.call("close_system_menu")
	TimeManager.time_scale = 0.0
	if not CompanyManager.created or SimulationManager.is_game_over:
		_report("Sauvegarde de reference invalide ou partie terminee.")
		return false
	return true

func _reset_measurement(name: String, screen_name: String) -> void:
	_series = name
	_screen_name = screen_name
	_month_rows.clear()
	_tab_rows.clear()
	_month_count = 0
	_tab_step = 0
	_span_starts.clear()
	_frame_values.resize(FRAME_CAPACITY)
	_process_values.resize(FRAME_CAPACITY)
	_frame_count = 0
	_pending_month.clear()
	_frame_sim_ms = 0.0
	_frame_ui_ms = 0.0
	_frame_screens.clear()
	_reset_month_peak()
	_start_us = Time.get_ticks_usec()
	_prev_us = _start_us
	_finish_after_frame = -1
	_last_tick_frame = Engine.get_process_frames()
	last_result = ""
	hide_panel()

func start_month_series(index: int) -> void:
	if _state != "idle" or not _prepare_reference():
		return
	var screens := {0:"QG", 1:"Entreprise", 4:"Produits"}
	if not screens.has(index):
		_report("Ecran non mesure.")
		return
	_screen_id = index
	_game.call("_show_tab", index)
	_reset_measurement("mois_x3", str(screens[index]))
	_state = "months"
	TimeManager.time_scale = 3.0

func start_idle_series(playing: bool) -> void:
	if _state != "idle" or not _prepare_reference():
		return
	_game.call("_show_tab", 0)
	_reset_measurement("jeu_x1_60s" if playing else "repos_30s", "QG")
	_state = "timed"
	TimeManager.time_scale = 1.0 if playing else 0.0

func start_tab_series() -> void:
	if _state != "idle" or not _prepare_reference():
		return
	_game.call("_show_tab", 0)
	_reset_measurement("onglets_3_tours", "Tous")
	_state = "tabs"
	TimeManager.time_scale = 0.0
	call_deferred("_next_tab")

func _next_tab() -> void:
	if _state != "tabs":
		return
	if _tab_step >= TAB_ORDER.size() * 3:
		_finish("OK")
		return
	# Trois cycles complets : revenir a l'indice 0 apres chacun des sept onglets.
	var tab_id: int = TAB_ORDER[_tab_step % TAB_ORDER.size()]
	_tab_request_us = Time.get_ticks_usec()
	_tab_request_index = tab_id
	_tab_step += 1
	_game.call("_show_tab", tab_id)
	# La fin du rendu est le point d'arrivee, pas simplement le changement de propriete current_tab.
	if not RenderingServer.frame_post_draw.is_connected(_tab_presented):
		RenderingServer.frame_post_draw.connect(_tab_presented, CONNECT_ONE_SHOT)

func _tab_label(index: int) -> String:
	return str({0:"QG", 1:"Entreprise", 2:"Equipe", 3:"Labo", 4:"Produits", 5:"Marche", 6:"Presse"}.get(index, index))

func _tab_presented() -> void:
	if _state != "tabs":
		return
	var elapsed := float(Time.get_ticks_usec() - _tab_request_us) / 1000.0
	_tab_rows.append({"index":_tab_step, "screen":_tab_label(_tab_request_index), "tab_ms":elapsed})
	call_deferred("_next_tab")

func begin_span(name: String) -> void:
	if not enabled or _state == "idle":
		return
	_span_starts[name] = Time.get_ticks_usec()

func end_span(name: String) -> void:
	if not enabled or _state == "idle" or not _span_starts.has(name):
		return
	var elapsed := float(Time.get_ticks_usec() - int(_span_starts[name])) / 1000.0
	_span_starts.erase(name)
	if name == "simulation":
		# Les actualisations synchrones imbriquees ne doivent pas etre comptees deux fois.
		_frame_sim_ms += maxf(0.0, elapsed - _frame_ui_ms)
	elif name in ["ui_all", "ui_parts", "ui_stale"]:
		_frame_ui_ms += elapsed
	elif name.begins_with("screen:"):
		_frame_screens[name.trim_prefix("screen:")] = elapsed

func mark_month(report: Dictionary) -> void:
	if not enabled or _state != "months":
		return
	_flush_pending_month()
	_month_count += 1
	_pending_month = {
		"index":_month_count, "screen":_screen_name,
		"simulation_ms":_frame_sim_ms,
		"refresh_ms":_frame_ui_ms,
		"checkpoint":"%d-%02d" % [TimeManager.year, TimeManager.month],
		"money":int(report.get("money", Economy.money))
	}
	if _month_count >= MONTH_TARGET:
		TimeManager.time_scale = 0.0
		_finish_after_frame = Engine.get_process_frames() + 2

func _flush_pending_month() -> void:
	if _pending_month.is_empty():
		return
	_pending_month["worst_ms"] = _max_month_frame
	_pending_month["other_ms"] = maxf(0.0, _max_month_frame - _max_month_sim - _max_month_ui)
	_pending_month["slow_screen"] = _max_month_screen
	_month_rows.append(_pending_month)
	_pending_month = {}
	_reset_month_peak()

func _reset_month_peak() -> void:
	_max_month_frame = 0.0
	_max_month_sim = 0.0
	_max_month_ui = 0.0
	_max_month_screen = ""

func _process(_delta: float) -> void:
	if not enabled:
		return
	if _state == "idle":
		return
	var now := Time.get_ticks_usec()
	var elapsed_ms := float(now - _prev_us) / 1000.0
	_prev_us = now
	if elapsed_ms > 0.0 and elapsed_ms < 30000.0:
		if _frame_count >= _frame_values.size():
			_frame_values.resize(_frame_values.size() + 12000)
			_process_values.resize(_process_values.size() + 12000)
		_frame_values[_frame_count] = elapsed_ms
		_process_values[_frame_count] = float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
		_frame_count += 1
		if elapsed_ms > _max_month_frame:
			_max_month_frame = elapsed_ms
			_max_month_sim = _frame_sim_ms
			_max_month_ui = _frame_ui_ms
			if not _frame_screens.is_empty():
				var slowest := 0.0
				for name in _frame_screens:
					if float(_frame_screens[name]) > slowest:
						slowest = float(_frame_screens[name])
						_max_month_screen = str(name)
	_frame_sim_ms = 0.0
	_frame_ui_ms = 0.0
	_frame_screens.clear()
	if not _pending_month.is_empty() and _month_count < MONTH_TARGET:
		_flush_pending_month()
	if _state == "months":
		if _finish_after_frame >= 0 and Engine.get_process_frames() >= _finish_after_frame:
			_finish("OK")
		elif _finish_after_frame < 0 and TimeManager.time_scale <= 0.0:
			_abort("Serie interrompue : decision en attente au mois %d" % (_month_count + 1))
	elif _state == "timed":
		var duration_us := 60000000 if _series == "jeu_x1_60s" else 30000000
		if now - _start_us >= duration_us:
			_finish("OK")

func _stats() -> Dictionary:
	if _frame_count == 0:
		return {"mean":0.0,"p50":0.0,"p95":0.0,"p99":0.0,"worst":0.0,"gt50":0,"gt100":0}
	var values := _frame_values.slice(0, _frame_count)
	values.sort()
	var process_total := 0.0
	for index in range(_frame_count):
		process_total += _process_values[index]
	var total := 0.0
	var gt50 := 0
	var gt100 := 0
	for value in values:
		total += value
		if value > 50.0: gt50 += 1
		if value > 100.0: gt100 += 1
	return {
		"mean":total / _frame_count,
		"p50":values[int((_frame_count - 1) * 0.5)],
		"p95":values[int((_frame_count - 1) * 0.95)],
		"p99":values[int((_frame_count - 1) * 0.99)],
		"worst":values[_frame_count-1],
		"gt50":gt50, "gt100":gt100, "process_mean":process_total / _frame_count
	}

func _abort(reason: String) -> void:
	TimeManager.time_scale = 0.0
	_finish(reason)

func _finish(result: String) -> void:
	if _state == "idle":
		return
	_flush_pending_month()
	var finished := _state
	_state = "idle"
	TimeManager.time_scale = 0.0
	var checkpoint := ""
	if result == "OK" and finished == "months":
		checkpoint = _checkpoint()
		var key := _reference_hash + ":" + _screen_name
		if _previous_checkpoints.has(key) and str(_previous_checkpoints[key]) != checkpoint:
			result = "NON REPRODUCTIBLE : checksum de fin differente"
		else:
			_previous_checkpoints[key] = checkpoint
	last_result = result
	var stats := _stats()
	_write_csv(result, stats, checkpoint)
	status_changed.emit("%s | %d mois | %d images" % [result, _month_count, _frame_count])
	if _game != null:
		show_panel()

func _checkpoint() -> String:
	# Ecriture uniquement apres la fin de la serie, dans le dossier de test.
	SaveManager.writes_enabled = true
	var ok := SaveManager.save_to_slot(0, true)
	SaveManager.writes_enabled = false
	if not ok:
		return "ERREUR_CHECKPOINT"
	var file := FileAccess.open(SANDBOX + "tech_empire_save.json", FileAccess.READ)
	if file == null:
		return "ERREUR_LECTURE"
	var state = JSON.parse_string(file.get_as_text())
	if not state is Dictionary:
		return "ERREUR_JSON"
	state.erase("meta")
	if state.has("time"):
		var sim_time: Dictionary = state["time"]
		sim_time["timer"] = 0.0
		sim_time["time_scale"] = 0.0
	return JSON.stringify(state).sha256_text()

func _write_csv(result: String, stats: Dictionary, checkpoint: String) -> void:
	_output_sequence += 1
	var when := Time.get_datetime_string_from_system().replace(":", "").replace("-", "")
	var path := "user://perf_%s_%02d.csv" % [when, _output_sequence]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_csv_path = "ECHEC ECRITURE"
		return
	file.store_line(CSV_HEADER)
	var commit := _build_commit()
	for m in _month_rows:
		var row: Dictionary = m
		file.store_csv_line(PackedStringArray([
			_series,"month",str(row.get("index",0)),str(row.get("screen","")),
			"", "", "", "", str(row.get("worst_ms",0)), "", "",
			str(row.get("simulation_ms",0)), str(row.get("refresh_ms",0)),
			str(row.get("other_ms",0)), "", str(row.get("checkpoint","")),
			result, commit, str(Engine.max_fps), _reference_hash, "", str(row.get("slow_screen", ""))
		]))
	for t in _tab_rows:
		var row: Dictionary = t
		file.store_csv_line(PackedStringArray([
			_series,"tab",str(row.get("index",0)),str(row.get("screen","")),
			"", "", "", "", "", "", "", "", "", "", str(row.get("tab_ms",0)),
			checkpoint,result,commit,str(Engine.max_fps),_reference_hash, "", ""
		]))
	file.store_csv_line(PackedStringArray([
		_series,"summary","0",_screen_name,
		str(stats.mean),str(stats.p50),str(stats.p95),str(stats.p99),str(stats.worst),
		str(stats.gt50),str(stats.gt100),"","","","",checkpoint,
		result,commit,str(Engine.max_fps),_reference_hash,str(stats.get("process_mean",0.0)), ""
	]))
	file.flush()
	file.close()
	last_csv_path = path

func _build_commit() -> String:
	# L'exporteur peut placer le SHA exact avant de produire l'APK, sans changer le commit P0.
	if FileAccess.file_exists("res://perf_build_commit.txt"):
		var file := FileAccess.open("res://perf_build_commit.txt", FileAccess.READ)
		if file != null:
			return file.get_as_text().strip_edges()
	return "SHA export non renseigne"

func _report(msg: String) -> void:
	last_result = msg
	status_changed.emit(msg)
	_update_summary()

# Crochets de test : pas de simulation reelle, pas d'ecriture avant finalize.
func test_inject_tab(label: String, duration_ms: float) -> void:
	_tab_rows.append({"index":_tab_rows.size()+1,"screen":label,"tab_ms":duration_ms})
func test_begin() -> void:
	enable()
	_reset_measurement("synthetic", "QG")
	_state = "months"

func test_mark(simulation_ms: float, refresh_ms: float) -> void:
	_frame_sim_ms = simulation_ms
	_frame_ui_ms = refresh_ms
	mark_month({"money":0})

func test_abort(message: String) -> void:
	_abort(message)

func test_finalize() -> void:
	_finish("OK")
