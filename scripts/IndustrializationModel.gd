extends RefCounted
class_name IndustrializationModel

const CONTRACTS := {
	"FLEXIBLE": {
		"label":"Sous-traitance flexible",
		"summary":"Faible engagement initial, mais coût unitaire plus élevé et capacité moins prioritaire.",
		"setup_factor":0.72,
		"unit_cost_factor":1.08,
		"capacity_factor":0.86,
		"overhead_factor":0.72,
		"return_factor":1.03
	},
	"RESERVED": {
		"label":"Capacité réservée",
		"summary":"Équilibre entre engagement, coût, capacité et stabilité.",
		"setup_factor":1.00,
		"unit_cost_factor":1.00,
		"capacity_factor":1.00,
		"overhead_factor":1.00,
		"return_factor":1.00
	},
	"PARTNER": {
		"label":"Partenariat fonderie",
		"summary":"Investissement plus lourd, mais meilleur coût unitaire, capacité prioritaire et qualité plus régulière.",
		"setup_factor":1.30,
		"unit_cost_factor":0.95,
		"capacity_factor":1.10,
		"overhead_factor":1.12,
		"return_factor":0.94
	}
}

const PACKAGING := {
	"STANDARD": {
		"label":"Packaging standard",
		"summary":"Solution économique et polyvalente.",
		"setup_factor":1.00,
		"unit_cost_factor":1.00,
		"capacity_factor":1.00,
		"overhead_factor":1.00,
		"return_factor":1.00
	},
	"ADVANCED": {
		"label":"Packaging avancé",
		"summary":"Coût supérieur, mais meilleure robustesse et moins de retours.",
		"setup_factor":1.08,
		"unit_cost_factor":1.05,
		"capacity_factor":0.97,
		"overhead_factor":1.04,
		"return_factor":0.86
	},
	"PREMIUM": {
		"label":"Packaging premium",
		"summary":"Qualité maximale au prix d'un assemblage plus coûteux et plus lent.",
		"setup_factor":1.16,
		"unit_cost_factor":1.09,
		"capacity_factor":0.93,
		"overhead_factor":1.08,
		"return_factor":0.74
	}
}

const TESTING := {
	"ECONOMY": {
		"label":"Tests économiques",
		"summary":"Débit élevé et coût réduit, mais davantage de défauts passent en production.",
		"setup_factor":0.94,
		"unit_cost_factor":0.98,
		"capacity_factor":1.06,
		"overhead_factor":0.96,
		"return_factor":1.22
	},
	"BALANCED": {
		"label":"Tests équilibrés",
		"summary":"Couverture standard adaptée à une gamme grand public.",
		"setup_factor":1.00,
		"unit_cost_factor":1.00,
		"capacity_factor":1.00,
		"overhead_factor":1.00,
		"return_factor":1.00
	},
	"INTENSIVE": {
		"label":"Tests intensifs",
		"summary":"Plus cher et plus lent, mais réduit fortement les retours SAV.",
		"setup_factor":1.12,
		"unit_cost_factor":1.06,
		"capacity_factor":0.92,
		"overhead_factor":1.07,
		"return_factor":0.68
	}
}

static func default_choices() -> Dictionary:
	return {
		"contract":"RESERVED",
		"packaging":"STANDARD",
		"testing":"BALANCED"
	}

static func normalize_choices(input: Dictionary) -> Dictionary:
	var choices := default_choices()
	for key in ["contract", "packaging", "testing"]:
		if input.has(key):
			choices[key] = str(input[key])
	if not CONTRACTS.has(str(choices.contract)):
		choices.contract = "RESERVED"
	if not PACKAGING.has(str(choices.packaging)):
		choices.packaging = "STANDARD"
	if not TESTING.has(str(choices.testing)):
		choices.testing = "BALANCED"
	return choices

static func contract_keys() -> Array:
	return CONTRACTS.keys()

static func packaging_keys() -> Array:
	return PACKAGING.keys()

static func testing_keys() -> Array:
	return TESTING.keys()

static func contract(key: String) -> Dictionary:
	return CONTRACTS.get(key, CONTRACTS.RESERVED)

static func packaging(key: String) -> Dictionary:
	return PACKAGING.get(key, PACKAGING.STANDARD)

static func testing(key: String) -> Dictionary:
	return TESTING.get(key, TESTING.BALANCED)

static func evaluate(input: Dictionary) -> Dictionary:
	var choices := normalize_choices(input)
	var contract_data: Dictionary = contract(str(choices.contract))
	var packaging_data: Dictionary = packaging(str(choices.packaging))
	var testing_data: Dictionary = testing(str(choices.testing))
	var setup_factor := (
		float(contract_data.setup_factor)
		* float(packaging_data.setup_factor)
		* float(testing_data.setup_factor)
	)
	var unit_cost_factor := (
		float(contract_data.unit_cost_factor)
		* float(packaging_data.unit_cost_factor)
		* float(testing_data.unit_cost_factor)
	)
	var capacity_factor := (
		float(contract_data.capacity_factor)
		* float(packaging_data.capacity_factor)
		* float(testing_data.capacity_factor)
	)
	var overhead_factor := (
		float(contract_data.overhead_factor)
		* float(packaging_data.overhead_factor)
		* float(testing_data.overhead_factor)
	)
	var return_factor := (
		float(contract_data.return_factor)
		* float(packaging_data.return_factor)
		* float(testing_data.return_factor)
	)
	return {
		"choices":choices,
		"setup_factor":clampf(setup_factor, 0.55, 1.75),
		"unit_cost_factor":clampf(unit_cost_factor, 0.85, 1.30),
		"capacity_factor":clampf(capacity_factor, 0.65, 1.30),
		"overhead_factor":clampf(overhead_factor, 0.55, 1.45),
		"return_factor":clampf(return_factor, 0.45, 1.45)
	}
