extends RefCounted
class_name CpuSupportModel

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")

const ISSUE_THRESHOLD := 8.0

const FIX_OPTIONS := {
	"HOTFIX": {
		"label":"Hotfix rapide",
		"cost":8_000,
		"months":1,
		"microcode_gain":5.0,
		"compatibility_gain":2.0,
		"performance_delta":-2.0,
		"summary":"Rapide et peu coûteux, mais légère perte de performance."
	},
	"VALIDATED_PATCH": {
		"label":"Correctif validé",
		"cost":20_000,
		"months":2,
		"microcode_gain":9.0,
		"compatibility_gain":7.0,
		"performance_delta":0.0,
		"summary":"Plus lent, mais corrige proprement sans sacrifier les performances."
	},
	"COMPATIBILITY_PROGRAM": {
		"label":"Programme de compatibilité",
		"cost":35_000,
		"months":3,
		"microcode_gain":7.0,
		"compatibility_gain":14.0,
		"performance_delta":0.0,
		"summary":"Investissement lourd pour stabiliser firmware, OS et plateformes partenaires."
	}
}

static func initial_state(metrics: Dictionary, design_input: Dictionary = {}) -> Dictionary:
	var design := CPU_DESIGN.normalize(design_input)
	var design_eval := CPU_DESIGN.evaluate(design)
	var reliability := float(metrics.get("reliability", 60.0))
	var innovation := float(metrics.get("innovation", 50.0))
	var ipc_factor := float(design.get("ipc_factor", 1.0))
	var microcode := clampf(54.0 + reliability * 0.34 - maxf(innovation - 70.0, 0.0) * 0.12 - maxf(ipc_factor - 1.0, 0.0) * 10.0, 40.0, 94.0)
	var compatibility := clampf(58.0 + reliability * 0.30 - maxf(innovation - 72.0, 0.0) * 0.16 + float(design_eval.get("platform_compatibility_bonus", 0.0)), 35.0, 98.0)
	return {
		"microcode_quality":microcode,
		"compatibility":compatibility,
		"support_debt":0.0,
		"patch_level":0,
		"pending_issue":{},
		"active_fix":{}
	}

static func normalize_state(input: Dictionary, metrics: Dictionary, design: Dictionary = {}) -> Dictionary:
	var state := initial_state(metrics, design)
	for key in input.keys():
		state[key] = input[key]
	state["microcode_quality"] = clampf(float(state.get("microcode_quality", 60.0)), 0.0, 100.0)
	state["compatibility"] = clampf(float(state.get("compatibility", 60.0)), 0.0, 100.0)
	state["support_debt"] = maxf(float(state.get("support_debt", 0.0)), 0.0)
	state["patch_level"] = maxi(int(state.get("patch_level", 0)), 0)
	state["pending_issue"] = state.get("pending_issue", {}).duplicate(true)
	state["active_fix"] = state.get("active_fix", {}).duplicate(true)
	return state

static func monthly_debt_gain(state: Dictionary, metrics: Dictionary, months_on_market: int) -> float:
	var microcode := float(state.get("microcode_quality", 60.0))
	var compatibility := float(state.get("compatibility", 60.0))
	var innovation := float(metrics.get("innovation", 50.0))
	var age_pressure := maxf(float(months_on_market - 6), 0.0) * 0.04
	var complexity_pressure := maxf(innovation - 72.0, 0.0) * 0.018
	var quality_pressure := maxf(72.0 - microcode, 0.0) * 0.055
	var compatibility_pressure := maxf(70.0 - compatibility, 0.0) * 0.045
	return maxf(0.12 + age_pressure + complexity_pressure + quality_pressure + compatibility_pressure, 0.0)

static func issue_from_state(product_id: String, product_name: String, state: Dictionary, month: int, year: int) -> Dictionary:
	var microcode := float(state.get("microcode_quality", 60.0))
	var compatibility := float(state.get("compatibility", 60.0))
	var compatibility_issue := compatibility <= microcode
	var severity := "CRITICAL" if minf(microcode, compatibility) < 52.0 else "WARNING"
	return {
		"id":"SW-%s-%02d-%d" % [product_id, month, year],
		"product_id":product_id,
		"product_name":product_name,
		"type":"COMPATIBILITY" if compatibility_issue else "MICROCODE",
		"severity":severity,
		"microcode_quality":microcode,
		"compatibility":compatibility,
		"month":month,
		"year":year
	}

static func fix_options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key_value in FIX_OPTIONS.keys():
		var key := str(key_value)
		var row: Dictionary = FIX_OPTIONS[key].duplicate(true)
		row["id"] = key
		result.append(row)
	return result

static func fix_option(action_id: String) -> Dictionary:
	return FIX_OPTIONS.get(action_id, {}).duplicate(true)
