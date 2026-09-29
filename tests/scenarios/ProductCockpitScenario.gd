extends RefCounted

## Lot A (29/09) : le cockpit a trois étapes (Fabriquer, Vendre, SAV). « Concevoir » renvoyait
## seulement au Labo et a été retiré.
static func run(host: Node) -> String:
	var screen_script: Script = load("res://ui/screens/ProductsScreen.gd")
	var screen: Control = screen_script.new() as Control
	host.add_child(screen)
	var mode_grid: GridContainer = screen.get("mode_grid")
	var mode_buttons_value = screen.get("mode_buttons")
	var pages_value = screen.get("pages")
	if mode_grid == null or typeof(mode_buttons_value) != TYPE_DICTIONARY or typeof(pages_value) != TYPE_DICTIONARY:
		screen.queue_free()
		return "Product cockpit did not expose its three-stage navigation"
	var mode_buttons: Dictionary = mode_buttons_value
	var pages: Dictionary = pages_value
	for mode in ["BUILD", "SELL", "SUPPORT"]:
		if not mode_buttons.has(mode) or not pages.has(mode):
			screen.queue_free()
			return "Product cockpit is missing stage %s" % mode
	if mode_buttons.has("DESIGN") or pages.has("DESIGN"):
		screen.queue_free()
		return "Product cockpit still shows the duplicate Concevoir stage"

	screen.call("set_viewport_width", 700.0)
	if mode_grid.columns != 3:
		screen.queue_free()
		return "Product cockpit should keep its three stages on one row on Android"
	screen.call("focus_product_launch")
	if str(screen.get("current_mode")) != "SELL" or not bool((pages["SELL"] as Control).visible):
		screen.queue_free()
		return "Ready-to-launch navigation did not focus the Vendre stage"
	for mode in ["BUILD", "SUPPORT"]:
		if bool((pages[mode] as Control).visible):
			screen.queue_free()
			return "Product cockpit left multiple stages visible after launch focus"

	screen.call("show_section_for_context", "SAV")
	if str(screen.get("current_mode")) != "SUPPORT" or not bool((pages["SUPPORT"] as Control).visible):
		screen.queue_free()
		return "SAV context did not open the SAV stage of the product cockpit"
	for mode in ["BUILD", "SELL"]:
		if bool((pages[mode] as Control).visible):
			screen.queue_free()
			return "Product cockpit left multiple stages visible in support mode"

	screen.queue_free()
	return ""
