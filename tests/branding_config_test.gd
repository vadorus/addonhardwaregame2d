extends SceneTree

const MAIN_ICON := "res://assets/branding/tech_empire_icon.svg"
const PLAY_ICON := "res://assets/branding/play_store_icon.png"
const WINDOWS_ICON := "res://assets/branding/tech_empire_windows.ico"

func _init() -> void:
	var failures: Array[String] = []
	_check(ProjectSettings.get_setting("application/config/icon", "") == MAIN_ICON, "project icon is not Tech Empire", failures)
	for path in [MAIN_ICON, PLAY_ICON, WINDOWS_ICON, "res://assets/branding/tech_empire_adaptive_foreground.svg", "res://assets/branding/tech_empire_adaptive_background.svg", "res://assets/branding/tech_empire_adaptive_monochrome.svg"]:
		_check(FileAccess.file_exists(path), "missing branding asset: %s" % path, failures)
	var export_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check(export_text.contains("application/icon=\"%s\"" % WINDOWS_ICON), "Windows export icon is not configured", failures)
	_check(export_text.count("launcher_icons/main_192x192=\"%s\"" % MAIN_ICON) == 2, "main Android icon must be configured in APK and AAB presets", failures)
	_check(export_text.count("launcher_icons/adaptive_foreground_432x432") == 2, "adaptive foreground missing from an Android preset", failures)
	_check(export_text.count("launcher_icons/adaptive_background_432x432") == 2, "adaptive background missing from an Android preset", failures)
	_check(export_text.count("launcher_icons/adaptive_monochrome_432x432") == 2, "themed Android icon missing from an Android preset", failures)
	_check(export_text.count("version/name=\"0.11.1-rc3\"") == 2, "Android version name must be 0.11.1-rc3", failures)
	_check(export_text.count("gradle_build/target_sdk=\"36\"") == 1, "Play Store preset must target Android API 36", failures)
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(PLAY_ICON))
	_check(err == OK, "Play Store PNG cannot be loaded", failures)
	if err == OK:
		_check(image.get_width() == 512 and image.get_height() == 512, "Play Store icon must be 512x512", failures)
	if failures.is_empty():
		print("[CI] Branding config test passed")
		quit(0)
		return
	for failure in failures:
		push_error("Branding: " + failure)
	quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
