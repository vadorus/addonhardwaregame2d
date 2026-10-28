extends RefCounted

const LIVE := preload("res://scripts/LiveTheme.gd")
const JUICE := preload("res://ui/Juice.gd")

class CountingCrew extends "res://ui/CrewMember.gd":
	var redraw_requests := 0
	func _on_animation_tick(delta: float) -> void:
		var before := _t
		super._on_animation_tick(delta)
		if _t != before:
			redraw_requests += 1

static func run(host: Node) -> String:
	var saved_created := CompanyManager.created
	var saved_speed := TimeManager.time_scale
	var saved_clock_process := AnimationClock.is_processing()
	var saved_time_process := TimeManager.is_processing()
	var saved_elapsed: float = AnimationClock._elapsed
	var saved_since: float = AnimationClock._since_tick
	var saved_low := OS.low_processor_usage_mode
	var saved_reduced := JUICE.reduced_motion
	var saved_theme := LIVE.override
	var saved_enabled := LIVE.enabled
	AnimationClock.set_process(false)
	TimeManager.set_process(false)
	AnimationClock._elapsed = 0.0
	AnimationClock._since_tick = 0.0
	CompanyManager.created = true
	JUICE.reduced_motion = false
	LIVE.override = "FIN_ANNEE"
	LIVE.enabled = true
	var error := await _check(host)
	CompanyManager.created = saved_created
	TimeManager.time_scale = saved_speed
	AnimationClock._elapsed = saved_elapsed
	AnimationClock._since_tick = saved_since
	AnimationClock.set_process(saved_clock_process)
	TimeManager.set_process(saved_time_process)
	OS.low_processor_usage_mode = saved_low
	JUICE.reduced_motion = saved_reduced
	LIVE.override = saved_theme
	LIVE.enabled = saved_enabled
	return error

static func _check(host: Node) -> String:
	var holder := Control.new()
	host.add_child(holder)
	var crew := CountingCrew.new()
	var entries := [
		[crew, "_t"],
		[(load("res://ui/CpuBench.gd") as Script).new(), "_clock"],
		[(load("res://ui/ProjectVisual.gd") as Script).new(), "_clock"],
		[(load("res://ui/components/ComponentArt.gd") as Script).new(), "spin"],
		[(load("res://ui/GarageLife.gd") as Script).new(), "_time"],
		[(load("res://ui/LiveThemeOverlay.gd") as Script).new(), "_time"]
	]
	var failure := ""
	for entry in entries:
		var item: Control = entry[0]
		holder.add_child(item)
		if item.is_processing(): failure = "An animation still processes every frame"
	(entries[3][0] as Control).set("family", "PSU")
	# Au QG en pause, 120 images sur une seconde demandent 20 redessins de l'équipier.
	TimeManager.time_scale = 0.0
	AnimationClock.update_power_mode()
	if not OS.low_processor_usage_mode: failure = "Pause did not enable low processor usage"
	for i in range(120): AnimationClock.advance(1.0 / 120.0)
	if crew.redraw_requests != 20:
		failure = "Paused crew requested %d redraws instead of 20 per second" % crew.redraw_requests
	TimeManager.time_scale = 1.0
	AnimationClock.update_power_mode()
	if OS.low_processor_usage_mode: failure = "Resume did not disable low processor usage"
	for i in range(30): AnimationClock.advance(1.0 / 30.0)
	if crew.redraw_requests != 40: failure = "The shared beat drifted at 30 FPS"
	var before := []
	for entry in entries: before.append(entry[0].get(entry[1]))
	holder.hide()
	for i in range(60): AnimationClock.advance(1.0 / 60.0)
	for i in range(entries.size()):
		if entries[i][0].get(entries[i][1]) != before[i]:
			failure = "Hidden animation advanced: " + str(entries[i][1])
	if crew.redraw_requests != 40: failure = "Hidden crew still requested redraws"
	holder.show()
	AnimationClock.advance(0.05)
	if crew.redraw_requests != 41: failure = "Showing an animation did not restore its beat"
	# Une image très lente ne doit pas provoquer de rafale de redessins.
	AnimationClock.advance(0.5)
	if crew.redraw_requests != 42: failure = "A slow frame caused multiple redraws"
	JUICE.reduced_motion = true
	AnimationClock.advance(0.05)
	if crew.redraw_requests != 42: failure = "Reduced motion no longer stops the crew"
	var menu := Control.new()
	menu.hide()
	host.add_child(menu)
	AnimationClock.watch_menu(menu)
	menu.show()
	if not OS.low_processor_usage_mode: failure = "A covering menu did not enable low processor usage"
	menu.hide()
	if OS.low_processor_usage_mode: failure = "Closing the menu did not restore active processing"
	menu.free()
	var callback := Callable(crew, "_on_animation_tick")
	holder.free()
	if AnimationClock.tick.is_connected(callback): failure = "Freed animation retained its subscription"
	AnimationClock.update_power_mode()
	return failure
