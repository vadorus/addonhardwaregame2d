extends RefCounted

const FRAME_RATE := preload("res://scripts/FrameRateSettings.gd")
const PATH := "user://ci_tests/r1_frame_settings.cfg"

static func run(host: Node) -> String:
	var previous_fps := Engine.max_fps
	var previous_time := TimeManager.get_state()
	var previous_created := CompanyManager.created
	var previous_low := OS.low_processor_usage_mode
	CompanyManager.created = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://ci_tests"))
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var error := await _check(host)
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Engine.max_fps = previous_fps
	CompanyManager.created = previous_created
	TimeManager.load_state(previous_time)
	OS.low_processor_usage_mode = previous_low
	return error

static func _check(host: Node) -> String:
	if int(ProjectSettings.get_setting("application/run/max_fps", 0)) != 60 \
		or int(ProjectSettings.get_setting("application/run/max_fps.mobile", 0)) != 30:
		return "Default project caps must be 60 on desktop and 30 on mobile"
	if FRAME_RATE.apply_saved(PATH, false) != 60 or Engine.max_fps != 60:
		return "Fresh desktop settings did not apply 60 FPS"
	if FRAME_RATE.apply_saved(PATH, true) != 30 or Engine.max_fps != 30:
		return "Fresh mobile settings did not apply 30 FPS"
	# Une ancienne configuration reste lisible, et ses autres préférences sont conservées.
	var legacy := ConfigFile.new()
	legacy.set_value("ui", "scale", 1.2)
	legacy.set_value("audio", "sfx_volume", 0.65)
	if legacy.save(PATH) != OK: return "Could not write isolated settings fixture"
	if FRAME_RATE.apply_saved(PATH, false) != 60 or FRAME_RATE.apply_saved(PATH, true) != 30:
		return "Legacy settings without the FPS key lost their platform defaults"
	for fps in [60, 30]:
		if FRAME_RATE.save_and_apply(fps, PATH) != OK or Engine.max_fps != fps:
			return "Changing fluidity did not immediately apply the selected cap"
		Engine.max_fps = 0
		if FRAME_RATE.apply_saved(PATH, true) != fps or FRAME_RATE.apply_saved(PATH, false) != fps:
			return "Saved choice was not restored on both platforms"
	var saved := ConfigFile.new()
	if saved.load(PATH) != OK or saved.get_value("ui", "scale") != 1.2 \
		or saved.get_value("audio", "sfx_volume") != 0.65:
		return "Saving FPS overwrote another preference"
	for invalid in [0, 120, "60", {"unexpected":true}]:
		saved.set_value(FRAME_RATE.SECTION, FRAME_RATE.KEY, invalid)
		saved.save(PATH)
		if FRAME_RATE.apply_saved(PATH, true) != 30 or FRAME_RATE.apply_saved(PATH, false) != 60:
			return "Invalid setting did not fall back to the platform default"
	if FRAME_RATE.save_and_apply(120, PATH) != ERR_INVALID_PARAMETER or Engine.max_fps != 60:
		return "An unsupported cap was accepted"
	FRAME_RATE.save_and_apply(30, PATH)
	# P0 peut fixer temporairement son plafond sans qu'un traitement R1 le réécrive.
	var previous_probe := PerfProbe.enabled
	PerfProbe.enabled = true
	PerfProbe.set_probe_fps(60)
	PerfProbe.enabled = previous_probe
	if Engine.max_fps != 60: return "P0 could not override the comparison cap"
	var game: Control = (load("res://main.tscn") as PackedScene).instantiate()
	game.set("frame_settings_path", PATH)
	host.add_child(game)
	for i in range(3): await host.get_tree().process_frame
	var failure := ""
	if Engine.max_fps != 30: failure = "Scene startup did not reload the stored setting"
	game.call("open_system_menu")
	var button: Button = game.get("menu_frame_rate_button")
	if button == null:
		failure = "Fluidity setting is absent from the menu"
	else:
		if not button.text.contains("30"): failure = "Menu did not display the loaded cap"
		button.emit_signal("pressed")
		if Engine.max_fps != 60 or not button.text.contains("60"):
			failure = "Menu button did not immediately apply and display 60 FPS"
		button.emit_signal("pressed")
		if Engine.max_fps != 30 or not button.text.contains("30"):
			failure = "Menu button did not immediately apply and display 30 FPS"
	if TimeManager.time_scale != 0.0 or not OS.low_processor_usage_mode:
		failure = "Changing fluidity broke C2 pause/menu behavior"
	game.call("_process", 0.0)
	if Engine.max_fps != 30: failure = "A per-frame handler reset the selected cap"
	game.queue_free()
	await host.get_tree().process_frame
	Engine.max_fps = 0
	if FRAME_RATE.apply_saved(PATH, true) != 30: failure = "Menu choice was not persisted"
	return failure
