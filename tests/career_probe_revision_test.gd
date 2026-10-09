extends Node
## Test hors sauvegarde : la sonde C3 doit etiqueter chaque CSV avec le checkout reel.
const PROBE := preload("res://tests/tools/career_probe.gd")

func _ready() -> void:
	var probe: Node = PROBE.new()
	var initial := OS.get_environment("TECH_EMPIRE_GIT_COMMIT")
	var fake := "abcdef0123456789abcdef0123456789abcdef01"
	OS.set_environment("TECH_EMPIRE_GIT_COMMIT", fake.to_upper())
	if str(probe.call("_revision_from_git")) != fake:
		_fail("Environment SHA should override git checkout and be normalized")
		_restore(initial)
		return
	if str(probe.call("_normalize_revision", "BAD-SHA")) != "":
		_fail("Malformed revision must be rejected")
		_restore(initial)
		return
	_restore(initial)
	var origin := str(probe.call("_revision_from_git"))
	if origin == "eff0871":
		_fail("Stale hardcoded revision detected")
		return
	if origin != "UNKNOWN" and origin.length() != 40:
		_fail("Git revision must be 40 hex chars or UNKNOWN")
		return
	probe.free()
	print("[CI] CareerProbeRevisionTest PASS; source=", origin)
	get_tree().quit(0)

func _restore(value: String) -> void:
	if value == "":
		OS.unset_environment("TECH_EMPIRE_GIT_COMMIT")
	else:
		OS.set_environment("TECH_EMPIRE_GIT_COMMIT", value)

func _fail(message: String) -> void:
	push_error("[CI] CareerProbeRevisionTest FAIL: " + message)
	get_tree().quit(1)
