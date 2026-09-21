extends Node

signal founder_changed
signal level_up(new_level)

const SKILL_PROGRAMMING := "PROGRAMMING"
const SKILL_ELECTRONICS := "ELECTRONICS"
const SKILL_MANAGEMENT := "MANAGEMENT"
const SKILL_COMMERCIAL := "COMMERCIAL"

const SKILL_LABELS := {
	SKILL_PROGRAMMING:"Programmation",
	SKILL_ELECTRONICS:"Électronique",
	SKILL_MANAGEMENT:"Gestion",
	SKILL_COMMERCIAL:"Commercial"
}

var level := 1
var level_xp := 0
var total_xp := 0
var skills := {
	SKILL_PROGRAMMING:18.0,
	SKILL_ELECTRONICS:5.0,
	SKILL_MANAGEMENT:8.0,
	SKILL_COMMERCIAL:6.0
}

func reset() -> void:
	level = 1
	level_xp = 0
	total_xp = 0
	skills = {
		SKILL_PROGRAMMING:18.0,
		SKILL_ELECTRONICS:5.0,
		SKILL_MANAGEMENT:8.0,
		SKILL_COMMERCIAL:6.0
	}
	founder_changed.emit()

func xp_to_next_level() -> int:
	return 100 + (level - 1) * 60

func xp_progress_ratio() -> float:
	return clampf(float(level_xp) / maxf(float(xp_to_next_level()), 1.0), 0.0, 1.0)

func skill_value(skill: String) -> float:
	return clampf(float(skills.get(skill, 0.0)), 0.0, 100.0)

func skill_label(skill: String) -> String:
	return str(SKILL_LABELS.get(skill, skill.capitalize()))

func add_experience(skill: String, xp_amount: int, skill_gain: float) -> void:
	if xp_amount > 0:
		total_xp += xp_amount
		level_xp += xp_amount
	if SKILL_LABELS.has(skill) and skill_gain > 0.0:
		skills[skill] = clampf(skill_value(skill) + skill_gain, 0.0, 100.0)

	while level_xp >= xp_to_next_level():
		level_xp -= xp_to_next_level()
		level += 1
		level_up.emit(level)

	founder_changed.emit()

func add_multi_experience(xp_amount: int, gains: Dictionary) -> void:
	if xp_amount > 0:
		total_xp += xp_amount
		level_xp += xp_amount
	for skill_value_key in gains.keys():
		var skill := str(skill_value_key)
		if SKILL_LABELS.has(skill):
			skills[skill] = clampf(skill_value(skill) + float(gains[skill_value_key]), 0.0, 100.0)

	while level_xp >= xp_to_next_level():
		level_xp -= xp_to_next_level()
		level += 1
		level_up.emit(level)

	founder_changed.emit()

func programming_multiplier() -> float:
	return lerpf(0.88, 1.28, skill_value(SKILL_PROGRAMMING) / 100.0)

func electronics_multiplier() -> float:
	return lerpf(0.85, 1.32, skill_value(SKILL_ELECTRONICS) / 100.0)

func commercial_multiplier() -> float:
	return lerpf(0.90, 1.25, skill_value(SKILL_COMMERCIAL) / 100.0)

func management_multiplier() -> float:
	return lerpf(0.92, 1.22, skill_value(SKILL_MANAGEMENT) / 100.0)

func get_state() -> Dictionary:
	return {
		"level":level,
		"level_xp":level_xp,
		"total_xp":total_xp,
		"skills":skills.duplicate(true)
	}

func load_state(state: Dictionary) -> void:
	if state.is_empty():
		reset()
		return
	level = maxi(int(state.get("level", 1)), 1)
	level_xp = maxi(int(state.get("level_xp", 0)), 0)
	total_xp = maxi(int(state.get("total_xp", level_xp)), 0)
	var loaded_skills: Dictionary = state.get("skills", {})
	for skill in SKILL_LABELS.keys():
		skills[skill] = clampf(float(loaded_skills.get(skill, skills.get(skill, 0.0))), 0.0, 100.0)
	founder_changed.emit()
