extends RefCounted
## Google Play (08/10) : la politique de confidentialité est lisible dans le jeu, et ce qu'elle promet reste vrai :
## aucune permission Android n'est demandée par les réglages d'export.

const POLICY := preload("res://scripts/PrivacyPolicy.gd")

static func run(host: Node) -> String:
	var text := POLICY.text()
	if not text.contains("Aucune donnée personnelle") or not text.contains("aucune autorisation"):
		return "Privacy: the in-game policy text is missing its key promises"
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	for line in presets.split("\n"):
		if line.begins_with("permissions/") and line.strip_edges().ends_with("=true"):
			return "Privacy: the policy says no Android permission, but the export asks for %s" % line
	var panel: Control = (load("res://ui/components/PrivacyPanel.gd") as Script).new() as Control
	host.add_child(panel)
	panel.call("open")
	var shown := panel.visible
	panel.queue_free()
	if not shown:
		return "Privacy: the policy panel did not open"
	return ""
