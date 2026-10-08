extends RefCounted

static func run(host: Node) -> String:
	SimulationManager.reset_all("CI Entreprise garage", "CPU", "STANDARD")
	ExecutiveManager.months_operated = 24
	Economy.money = 6000000
	ExecutiveManager.sync_interface_unlocks()
	if ExecutiveManager.is_interface_feature_unlocked("CO_GROUP"):
		return "Garage company: cash alone must not announce the Group page in a garage"
	# Ancienne sauvegarde : ces pages et un mandat ont déjà été débloqués.
	var saved := ExecutiveManager.get_state().duplicate(true)
	saved.interface_unlocks["CO_DIVISIONS"] = true
	saved.interface_unlocks["CO_GROUP"] = true
	saved.interface_unlocks["CO_BUDGETS"] = true
	ExecutiveManager.load_state(saved)
	DivisionManager.record_completed_generation("CPU")
	var screen := (load("res://ui/screens/CompanyScreen.gd") as Script).new() as Control
	host.add_child(screen)
	screen.call("refresh")
	var error := _check(screen)
	screen.queue_free()
	return error

static func _check(screen: Control) -> String:
	var pager: Control = screen.get("pager")
	for key in ["DIVISIONS", "GROUP"]:
		if bool(pager.call("is_page_available", key)):
			return "Garage company: legacy %s page still visible in garage" % key
		screen.call("show_section", key)
		if str(screen.call("current_section")) != "OVERVIEW":
			return "Garage company: a navigation shortcut bypasses the garage layout"
	screen.call("show_section", "BUDGETS")
	if str(screen.call("current_section")) != "BUDGETS" or (screen.get("department_delegation_group") as Control).visible or (screen.get("division_delegation_group") as Control).visible:
		return "Garage company: budgets should stay usable without delegation controls"
	# Aucun mandat ni drapeau effacé ; la sortie du garage restaure les pages existantes.
	if not bool(ExecutiveManager.interface_unlocks.get("CO_GROUP", false)) or not DivisionManager.delegation_available("CPU"):
		return "Garage company: hiding controls must preserve saved unlocks and division state"
	ExecutiveManager.workplace["tier"] = 1
	screen.call("refresh")
	for key in ["DIVISIONS", "GROUP"]:
		if not bool(pager.call("is_page_available", key)):
			return "Garage company: %s did not return after leaving the garage" % key
	if not (screen.get("department_delegation_group") as Control).visible or not (screen.get("division_delegation_group") as Control).visible:
		return "Garage company: delegation did not return after leaving the garage"
	# Un rechargement de garage ferme aussi une page qui était sélectionnée.
	screen.call("show_section", "GROUP")
	ExecutiveManager.workplace["tier"] = 0
	screen.call("refresh")
	if str(screen.call("current_section")) == "GROUP":
		return "Garage company: selected Group page survived a garage reload"
	return ""
