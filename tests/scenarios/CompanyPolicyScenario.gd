extends RefCounted

static func run() -> String:
	var original := CompanyManager.get_state().duplicate(true)
	if not CompanyManager.set_policies(250000, -5000, 275000, "PREMIUM"):
		return "Validated company policy API rejected a valid support level"
	if int(CompanyManager.policies.get("marketing_budget", -1)) != 200000:
		CompanyManager.load_state(original)
		return "Company policy API did not clamp marketing budget"
	if int(CompanyManager.policies.get("support_budget", -1)) != 0:
		CompanyManager.load_state(original)
		return "Company policy API did not clamp support budget"
	if int(CompanyManager.policies.get("environment_budget", -1)) != 200000:
		CompanyManager.load_state(original)
		return "Company policy API did not clamp environment budget"
	if str(CompanyManager.policies.get("support_level", "")) != "PREMIUM":
		CompanyManager.load_state(original)
		return "Company policy API did not persist the selected support level"

	var accepted_state := CompanyManager.policies.duplicate(true)
	if CompanyManager.set_policies(1000, 1000, 1000, "INVALID"):
		CompanyManager.load_state(original)
		return "Company policy API accepted an invalid support level"
	if CompanyManager.policies != accepted_state:
		CompanyManager.load_state(original)
		return "Invalid company policy request partially mutated manager state"

	CompanyManager.load_state(original)
	return ""
