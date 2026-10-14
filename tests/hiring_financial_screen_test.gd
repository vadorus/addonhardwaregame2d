extends Node
## BUD-01 — controle du texte et de l'action en Recrutement, sans partie personnelle.

func _ready() -> void:
	SaveManager.use_test_folder()
	SaveManager.writes_enabled = false
	SimulationManager.reset_all("Audit affichage recrutement", "CPU", "STANDARD")
	Economy.money = 28829
	PersonnelManager.shortlist = []
	PersonnelManager.candidate = {
		"name":"Candidat témoin","department":"Développement","salary":5607,
		"skill":70,"aptitude":75,"experience_years":5.0,
		"specialization":"product","leadership":50,"profile":{}
	}
	var screen: ScrollContainer = (load("res://ui/screens/PersonnelScreen.gd") as Script).new() as ScrollContainer
	add_child(screen)
	screen.call("show_section", "RECRUIT")
	for i in range(5):
		await get_tree().process_frame
	var lines: Array[String] = []
	for label in screen.find_children("*", "Label", true, false):
		lines.append(str(label.text))
	var all_text := " / ".join(lines)
	var has_quote := all_text.contains("Engagement réel")
	var has_risk := all_text.contains("Risque financier")
	var disabled := bool(screen.get("hire_button").disabled)
	print("[UI_BUD] quote=", has_quote, " risk=", has_risk, " disabled=", disabled)
	if not has_quote or not has_risk or disabled:
		push_error("[UI_BUD] L'aperçu ne s'affiche pas correctement")
		get_tree().quit(1)
		return
	Economy.money = 5000
	screen.call("refresh")
	await get_tree().process_frame
	var blocked := bool(screen.get("hire_button").disabled)
	print("[UI_BUD] blocked_missing_cash=", blocked)
	if not blocked:
		push_error("[UI_BUD] Le bouton doit être désactivé sans la prime")
		get_tree().quit(1)
		return
	print("[CI] HiringFinancialScreenSmoke PASS")
	get_tree().quit(0)
