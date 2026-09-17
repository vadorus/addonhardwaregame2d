extends Node

signal settings_changed

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "general"

var master_volume := 0.80
var ui_scale := 1.0
var max_fps := 60
var fullscreen := false
var vsync := true
var window_size := Vector2i(1280, 720)

func _ready() -> void:
	load_settings()
	apply_all()

func is_android() -> bool:
	return OS.get_name() == "Android"

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	master_volume = clampf(float(cfg.get_value(SECTION, "master_volume", master_volume)), 0.0, 1.0)
	ui_scale = clampf(float(cfg.get_value(SECTION, "ui_scale", ui_scale)), 0.85, 1.30)
	max_fps = clampi(int(cfg.get_value(SECTION, "max_fps", max_fps)), 30, 120)
	fullscreen = bool(cfg.get_value(SECTION, "fullscreen", fullscreen))
	vsync = bool(cfg.get_value(SECTION, "vsync", vsync))
	var stored_size = cfg.get_value(SECTION, "window_size", window_size)
	if stored_size is Vector2i:
		window_size = stored_size

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "master_volume", master_volume)
	cfg.set_value(SECTION, "ui_scale", ui_scale)
	cfg.set_value(SECTION, "max_fps", max_fps)
	cfg.set_value(SECTION, "fullscreen", fullscreen)
	cfg.set_value(SECTION, "vsync", vsync)
	cfg.set_value(SECTION, "window_size", window_size)
	cfg.save(CONFIG_PATH)

func apply_all() -> void:
	_apply_audio()
	_apply_ui_scale()
	_apply_fps()
	_apply_desktop_display()
	settings_changed.emit()

func _apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.001)))

func _apply_ui_scale() -> void:
	var root := get_tree().root
	if root != null:
		root.content_scale_factor = ui_scale

func _apply_fps() -> void:
	Engine.max_fps = max_fps

func _apply_desktop_display() -> void:
	if is_android() or DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(window_size)

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	save_settings()
	settings_changed.emit()

func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, 0.85, 1.30)
	_apply_ui_scale()
	save_settings()
	settings_changed.emit()

func set_max_fps(value: int) -> void:
	max_fps = clampi(value, 30, 120)
	_apply_fps()
	save_settings()
	settings_changed.emit()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_desktop_display()
	save_settings()
	settings_changed.emit()

func set_vsync(value: bool) -> void:
	vsync = value
	_apply_desktop_display()
	save_settings()
	settings_changed.emit()

func set_window_size(value: Vector2i) -> void:
	window_size = value
	_apply_desktop_display()
	save_settings()
	settings_changed.emit()

func reset_defaults() -> void:
	master_volume = 0.80
	ui_scale = 1.0
	max_fps = 60
	fullscreen = false
	vsync = true
	window_size = Vector2i(1280, 720)
	apply_all()
	save_settings()
