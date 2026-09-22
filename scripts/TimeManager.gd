extends Node

signal month_changed(month, year)
signal day_changed(day, month, year)

var day := 1
var month := 1
var year := 1971
var time_scale := 1.0
var day_duration := 0.8
var _timer := 0.0

func reset():
	day = 1
	month = 1
	year = 1971
	time_scale = 1.0
	_timer = 0.0
	day_changed.emit(day, month, year)

func _process(delta):
	if time_scale <= 0.0 or not CompanyManager.created:
		return
	_timer += delta * time_scale
	while _timer >= day_duration:
		_timer -= day_duration
		_next_day()
		if time_scale <= 0.0:
			break

func _next_day():
	day += 1
	SimulationManager.process_day()
	if day > 30:
		SimulationManager.process_month_end()
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1
		month_changed.emit(month, year)
	day_changed.emit(day, month, year)

func get_state() -> Dictionary:
	return {"day":day,"month":month,"year":year,"time_scale":time_scale,"timer":_timer}

func load_state(state: Dictionary):
	day = int(state.get("day", 1))
	month = int(state.get("month", 1))
	year = int(state.get("year", 1971))
	time_scale = float(state.get("time_scale", 1.0))
	_timer = float(state.get("timer", 0.0))
	day_changed.emit(day, month, year)
