extends RefCounted
## R1 : préférence locale de fluidité, distincte des sauvegardes de partie.
const SECTION := "display"
const KEY := "max_fps"
const CHOICES := [30, 60]

static func default_fps(mobile: bool) -> int:
	return 30 if mobile else 60

static func apply_saved(path: String, mobile: bool) -> int:
	var config := ConfigFile.new()
	var fps := default_fps(mobile)
	if config.load(path) == OK:
		var value = config.get_value(SECTION, KEY, fps)
		if typeof(value) == TYPE_INT and value in CHOICES:
			fps = value
	Engine.max_fps = fps
	return fps

static func save_and_apply(fps: int, path: String) -> Error:
	if fps not in CHOICES:
		return ERR_INVALID_PARAMETER
	var config := ConfigFile.new()
	var read_error := config.load(path)
	if read_error != OK and read_error != ERR_FILE_NOT_FOUND:
		# Ne pas écraser un fichier existant illisible ou invalide.
		return read_error
	config.set_value(SECTION, KEY, fps)
	var write_error := config.save(path)
	if write_error == OK:
		Engine.max_fps = fps
	return write_error
