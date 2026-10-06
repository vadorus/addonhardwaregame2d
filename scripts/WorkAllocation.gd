extends RefCounted
## Pure allocation: the sum of assigned engineers never exceeds capacity.
static func plan(capacity: float, tasks: Array, focus: String = "BALANCED") -> Dictionary:
	var allocations := {}
	var remaining := maxf(0.0, capacity)
	var pending: Array = tasks.duplicate(true)
	var demand := 0.0
	for value in tasks:
		var task: Dictionary = value
		demand += maxf(0.0, float(task.get("need", 1.0)))
		allocations[str(task.id)] = {"assigned":0.0, "factor":0.0, "need":float(task.get("need", 1.0))}
	for iteration in range(tasks.size() + 1):
		if pending.is_empty() or remaining <= 0.0001:
			break
		var weights := 0.0
		for value in pending:
			weights += _weight(value, focus)
		var used := 0.0
		var next: Array = []
		for value in pending:
			var task: Dictionary = value
			var entry: Dictionary = allocations[str(task.id)]
			var left := maxf(0.0, float(entry.need) - float(entry.assigned))
			var amount := minf(left, remaining * _weight(task, focus) / maxf(weights, 0.001))
			entry["assigned"] = float(entry.assigned) + amount
			entry["factor"] = clampf(float(entry.assigned) / maxf(float(entry.need), 0.001), 0.0, 1.0)
			used += amount
			if amount + 0.0001 < left:
				next.append(task)
		remaining = maxf(0.0, remaining - used)
		pending = next
	return {"capacity":capacity, "demand":demand, "used":maxf(0.0, capacity - remaining), "free":remaining, "allocations":allocations, "focus":focus}

static func _weight(task: Dictionary, focus: String) -> float:
	return 2.5 if str(task.get("kind", "")) == focus else 1.0
