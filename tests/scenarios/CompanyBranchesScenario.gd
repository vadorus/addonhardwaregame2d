extends RefCounted
## Planche 7 « La carte de l'entreprise » (08/10) : le tronc CPU et le logiciel sont jouables ; les autres
## branches sont des vitrines (version complète, extension à venir) qui n'ouvrent aucune mécanique.

const BRANCHES := preload("res://scripts/CompanyBranches.gd")

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Carte", "CPU", "STANDARD")
	var playable: Array[String] = []
	for entry_value in BRANCHES.NODES:
		var entry: Dictionary = entry_value
		if BRANCHES.can_open(entry):
			playable.append(str(entry.key))
	if playable != ["cpu", "soft"]:
		return "Branch map: only the CPU trunk and software may open (%s)" % str(playable)
	if not BRANCHES.status(BRANCHES.node("def"), 1975).contains("1980") or BRANCHES.tag(BRANCHES.node("mobile")) != "EXTENSION À VENIR":
		return "Branch map: locked branches should say when they open and what they are"

	var map: Control = (load("res://ui/components/BranchMap.gd") as Script).new() as Control
	host.add_child(map)
	map.call("refresh")
	map.call("select", "def")
	var locked: Button = map.call("cta_button")
	if locked == null or not locked.disabled:
		map.queue_free()
		return "Branch map: a full-version branch must not open anything"
	map.call("select", "soft")
	var opened := []
	map.connect("open_requested", func(context: String): opened.append(context))
	(map.call("cta_button") as Button).emit_signal("pressed")
	map.queue_free()
	if opened != ["SOFTWARE"]:
		return "Branch map: the software branch should open the software corner (%s)" % str(opened)

	var screen: Control = (load("res://ui/screens/CompanyScreen.gd") as Script).new() as Control
	host.add_child(screen)
	screen.call("refresh")
	var line := str((screen.get("scene") as Control).call("line_text"))
	var navigation := []
	screen.connect("navigate_requested", func(tab: int, context: String): navigation.append([tab, context]))
	screen.call("_on_branch_open", "LAB")
	screen.queue_free()
	if not line.contains(CompanyManager.company_name) or navigation != [[3, ""]]:
		return "Branch map: the company tab should open on Nora and lead to the lab (%s · %s)" % [line, str(navigation)]
	return ""
