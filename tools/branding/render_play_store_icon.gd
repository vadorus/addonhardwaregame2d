extends SceneTree

func _init() -> void:
	var svg_path := "res://assets/branding/tech_empire_icon.svg"
	var output_path := "res://assets/branding/play_store_icon.png"
	var svg := FileAccess.get_file_as_string(svg_path)
	if svg.is_empty():
		push_error("Branding: SVG source is empty")
		quit(2)
		return
	var image := Image.new()
	var err := image.load_svg_from_string(svg, 1.0)
	if err != OK:
		push_error("Branding: SVG render failed: %s" % error_string(err))
		quit(err)
		return
	err = image.save_png(ProjectSettings.globalize_path(output_path))
	if err != OK:
		push_error("Branding: PNG save failed: %s" % error_string(err))
	quit(err)
