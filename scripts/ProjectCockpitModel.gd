extends RefCounted

const AXIS_MIN := 5
const AXIS_MAX := 70

static func balanced(axes: Array) -> Dictionary:
	var result := {}
	if axes.is_empty():
		return result
	var base := int(floor(100.0 / float(axes.size())))
	var remaining := 100
	for i in range(axes.size()):
		var axis := str(axes[i])
		var value := base if i < axes.size() - 1 else remaining
		result[axis] = value
		remaining -= value
	return result

static func normalize(raw: Dictionary, axes: Array) -> Dictionary:
	if axes.is_empty():
		return {}
	var result := {}
	var total := 0
	for axis_value in axes:
		var axis := str(axis_value)
		var value := clampi(int(raw.get(axis, 0)), AXIS_MIN, AXIS_MAX)
		result[axis] = value
		total += value
	if total <= 0:
		return balanced(axes)
	while total != 100:
		var direction := 1 if total < 100 else -1
		var changed := false
		for axis_value in axes:
			var axis := str(axis_value)
			var current := int(result[axis])
			if direction > 0 and current < AXIS_MAX:
				result[axis] = current + 1
				total += 1
				changed = true
			elif direction < 0 and current > AXIS_MIN:
				result[axis] = current - 1
				total -= 1
				changed = true
			if total == 100:
				break
		if not changed:
			break
	return result

static func adjust(raw: Dictionary, axes: Array, axis_id: String, delta: int) -> Dictionary:
	var result := normalize(raw, axes)
	if not result.has(axis_id) or delta == 0:
		return result
	var target := clampi(int(result[axis_id]) + delta, AXIS_MIN, AXIS_MAX)
	var diff := target - int(result[axis_id])
	if diff == 0:
		return result
	result[axis_id] = target
	var others: Array = []
	for axis_value in axes:
		var axis := str(axis_value)
		if axis != axis_id:
			others.append(axis)
	var remaining: int = absi(diff)
	var direction: int = -1 if diff > 0 else 1
	while remaining > 0:
		var changed := false
		for axis_value in others:
			var axis := str(axis_value)
			var current := int(result[axis])
			if direction < 0 and current > AXIS_MIN:
				result[axis] = current - 1
				remaining -= 1
				changed = true
			elif direction > 0 and current < AXIS_MAX:
				result[axis] = current + 1
				remaining -= 1
				changed = true
			if remaining <= 0:
				break
		if not changed:
			break
	if remaining > 0:
		result[axis_id] = int(result[axis_id]) - direction * remaining
	return normalize(result, axes)

static func month_bias(priorities: Dictionary, axes: Array, strength := 1.0) -> Dictionary:
	var normalized := normalize(priorities, axes)
	var baseline := 100.0 / maxf(float(axes.size()), 1.0)
	var result := {}
	for axis_value in axes:
		var axis := str(axis_value)
		result[axis] = (float(normalized.get(axis, baseline)) - baseline) / baseline * strength
	return result
