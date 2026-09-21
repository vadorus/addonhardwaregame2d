extends Node

signal settings_changed(section, key, value)

const SETTINGS_PATH := "user://tech_empire_settings.cfg"
const SETTINGS_SCHEMA_VERSION := 2

const DEFAULTS := {
	"display": {
		"fullscreen": true,
		"ui_scale": 1.0,
		"reduce_motion": false
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.80,
		"sfx_volume": 0.90
	},
	"gameplay": {
		"language": "fr",
		"tutorial_enabled": true
	}
}

var _config := ConfigFile.new()

func _ready() -> void:
	load_settings()
	call_deferred("apply_runtime_settings")

func load_settings() -> void:
	_config = ConfigFile.new()
	var error := _config.load(SETTINGS_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Tech Empire : impossible de lire les paramètres (%s)." % error)
	var previous_schema := int(_config.get_value("meta", "schema_version", 0))
	for section in DEFAULTS.keys():
		var section_defaults: Dictionary = DEFAULTS[section]
		for key in section_defaults.keys():
			if not _config.has_section_key(str(section), str(key)):
				_config.set_value(str(section), str(key), section_defaults[key])
	if previous_schema < 2 and not OS.has_feature("mobile"):
		_config.set_value("display", "fullscreen", true)
	_config.set_value("meta", "schema_version", SETTINGS_SCHEMA_VERSION)
	save_settings()

func save_settings() -> bool:
	var error := _config.save(SETTINGS_PATH)
	return error == OK

func get_setting(section: String, key: String):
	var fallback = DEFAULTS.get(section, {}).get(key, null)
	return _config.get_value(section, key, fallback)

func set_setting(section: String, key: String, value) -> void:
	_config.set_value(section, key, value)
	save_settings()
	settings_changed.emit(section, key, value)

func reset_to_defaults() -> void:
	_config = ConfigFile.new()
	_config.set_value("meta", "schema_version", SETTINGS_SCHEMA_VERSION)
	for section in DEFAULTS.keys():
		var section_defaults: Dictionary = DEFAULTS[section]
		for key in section_defaults.keys():
			_config.set_value(str(section), str(key), section_defaults[key])
	save_settings()
	apply_runtime_settings()
	settings_changed.emit("*", "*", null)

func apply_runtime_settings() -> void:
	if not OS.has_feature("mobile"):
		_apply_window_mode(bool(get_setting("display", "fullscreen")))
	var ui_scale := clampf(float(get_setting("display", "ui_scale")), 0.85, 1.35)
	var window := get_window()
	if window != null:
		window.content_scale_factor = ui_scale

func _apply_window_mode(fullscreen: bool) -> void:
	var desired_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != desired_mode:
		DisplayServer.window_set_mode(desired_mode)

func set_fullscreen(enabled: bool) -> void:
	set_setting("display", "fullscreen", enabled)
	if not OS.has_feature("mobile"):
		_apply_window_mode(enabled)

func set_ui_scale(value: float) -> void:
	var scale := clampf(value, 0.85, 1.35)
	set_setting("display", "ui_scale", scale)
	var window := get_window()
	if window != null:
		window.content_scale_factor = scale
