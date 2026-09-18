extends Node

signal technologies_changed
signal technology_unlocked(technology)

const CATALOG := {
	"ADAPTIVE_POWER": {
		"label":"Gestion de puissance adaptative",
		"summary":"Méthodes réutilisables de contrôle dynamique de puissance et de tension.",
		"effects":{"efficiency":2.5,"sustainability":1.0}
	},
	"SMART_CACHE": {
		"label":"Politique de cache intelligente",
		"summary":"Règles de cache réutilisables pour améliorer les performances sans dépendre uniquement de la fréquence.",
		"effects":{"performance":2.5}
	},
	"CROSS_VALIDATION": {
		"label":"Validation croisée CPU",
		"summary":"Méthodologie de validation matérielle et firmware plus robuste.",
		"effects":{"reliability":2.5,"initial_microcode":3.0,"initial_compatibility":2.0}
	},
	"FOUNDRY_DRC": {
		"label":"Règles de conception fonderie",
		"summary":"Optimisations de conception et de préparation industrielle issues du partenariat fonderie.",
		"effects":{"industrial_setup":0.96,"industrial_unit_cost":0.97,"industrial_capacity":1.04}
	},
	"FIELD_FAILURE_ANALYTICS": {
		"label":"Analyse des pannes terrain",
		"summary":"Retour d'expérience SAV transformé en règles de conception préventives.",
		"effects":{"reliability":2.0,"initial_compatibility":1.0}
	},
	"MICROCODE_TOOLING": {
		"label":"Outillage microcode avancé",
		"summary":"Outils réutilisables de validation microcode, firmware et compatibilité plateforme.",
		"effects":{"initial_microcode":6.0,"initial_compatibility":4.0,"support_debt":0.85}
	}
}

var unlocked: Dictionary = {}

func reset():
	unlocked = {}
	technologies_changed.emit()

func unlock(technology_id: String, source: String = "") -> bool:
	if not CATALOG.has(technology_id) or unlocked.has(technology_id):
		return false
	var row: Dictionary = CATALOG[technology_id].duplicate(true)
	row["id"] = technology_id
	row["source"] = source
	row["month"] = TimeManager.month
	row["year"] = TimeManager.year
	unlocked[technology_id] = row
	CompanyManager.add_alert("Technologie réutilisable débloquée : %s." % str(row.get("label", technology_id)))
	technology_unlocked.emit(row.duplicate(true))
	technologies_changed.emit()
	return true

func has_technology(technology_id: String) -> bool:
	return unlocked.has(technology_id)

func get_unlocked() -> Array:
	var result: Array = []
	for technology_id in unlocked.keys():
		result.append(unlocked[technology_id].duplicate(true))
	return result

func metric_bonus(metric: String) -> float:
	var total := 0.0
	for technology_id in unlocked.keys():
		var effects: Dictionary = CATALOG.get(str(technology_id), {}).get("effects", {})
		total += float(effects.get(metric, 0.0))
	return total

func initial_microcode_bonus() -> float:
	return _sum_effect("initial_microcode", 0.0)

func initial_compatibility_bonus() -> float:
	return _sum_effect("initial_compatibility", 0.0)

func support_debt_modifier() -> float:
	var value := 1.0
	for technology_id in unlocked.keys():
		var effects: Dictionary = CATALOG.get(str(technology_id), {}).get("effects", {})
		value *= float(effects.get("support_debt", 1.0))
	return clampf(value, 0.65, 1.0)

func industrial_modifier(effect_key: String) -> float:
	var value := 1.0
	var key := "industrial_%s" % effect_key
	for technology_id in unlocked.keys():
		var effects: Dictionary = CATALOG.get(str(technology_id), {}).get("effects", {})
		value *= float(effects.get(key, 1.0))
	return clampf(value, 0.80, 1.20)

func _sum_effect(key: String, fallback: float) -> float:
	var total := fallback
	for technology_id in unlocked.keys():
		var effects: Dictionary = CATALOG.get(str(technology_id), {}).get("effects", {})
		total += float(effects.get(key, 0.0))
	return total

func get_state() -> Dictionary:
	return {"unlocked":unlocked}

func load_state(state: Dictionary):
	unlocked = {}
	var saved = state.get("unlocked", {})
	if typeof(saved) == TYPE_DICTIONARY:
		for technology_id in saved.keys():
			var key := str(technology_id)
			if CATALOG.has(key):
				var row = saved[technology_id]
				if typeof(row) == TYPE_DICTIONARY:
					unlocked[key] = row.duplicate(true)
				else:
					var fallback: Dictionary = CATALOG[key].duplicate(true)
					fallback["id"] = key
					unlocked[key] = fallback
	technologies_changed.emit()
