extends Node
## Mesure locale indicative du surcout des crochets P0 (pas une mesure GPU).
const N := 20000

func _ready() -> void:
	var original_enabled: bool = PerfProbe.enabled
	var original_state: String = PerfProbe._state
	PerfProbe.enabled = false
	var before := Time.get_ticks_usec()
	for i in range(N):
		PerfProbe.begin_span("simulation")
		PerfProbe.end_span("simulation")
	var disabled_us := Time.get_ticks_usec() - before
	PerfProbe.enabled = true
	PerfProbe._state = "months"
	before = Time.get_ticks_usec()
	for i in range(N):
		PerfProbe.begin_span("simulation")
		PerfProbe.end_span("simulation")
	var enabled_us := Time.get_ticks_usec() - before
	PerfProbe._state = original_state
	PerfProbe.enabled = original_enabled
	print("[P0] %d crochets sur PC : inactif %.3f us/appel double, actif %.3f us/appel double ; surcout %.3f us" % [
		N, float(disabled_us)/N, float(enabled_us)/N, float(enabled_us-disabled_us)/N
	])
	get_tree().quit(0)
