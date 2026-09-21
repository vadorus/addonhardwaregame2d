extends RefCounted

const Bg1 = preload("res://assets/ui/runtime/menu/MenuBgPart01.gd")
const Bg2 = preload("res://assets/ui/runtime/menu/MenuBgPart02.gd")
const Bg3 = preload("res://assets/ui/runtime/menu/MenuBgPart03.gd")
const Bg4 = preload("res://assets/ui/runtime/menu/MenuBgPart04.gd")
const Logo1 = preload("res://assets/ui/runtime/menu/MenuLogoPart01.gd")
const Logo2 = preload("res://assets/ui/runtime/menu/MenuLogoPart02.gd")
const Logo3 = preload("res://assets/ui/runtime/menu/MenuLogoPart03.gd")

static var _background_texture: Texture2D
static var _logo_texture: Texture2D

static func menu_background() -> Texture2D:
	if _background_texture == null:
		_background_texture = _decode_webp([
			Bg1.DATA, Bg2.DATA, Bg3.DATA, Bg4.DATA
		])
	return _background_texture

static func game_logo() -> Texture2D:
	if _logo_texture == null:
		_logo_texture = _decode_webp([
			Logo1.DATA, Logo2.DATA, Logo3.DATA
		])
	return _logo_texture

static func _decode_webp(parts: Array) -> Texture2D:
	var encoded := ""
	for part in parts:
		encoded += str(part)
	var bytes := Marshalls.base64_to_raw(encoded)
	var image := Image.new()
	var error := image.load_webp_from_buffer(bytes)
	if error != OK:
		push_error("Tech Empire UI: impossible de décoder un asset WebP embarqué (%s)." % error)
		return null
	return ImageTexture.create_from_image(image)
