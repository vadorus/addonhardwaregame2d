extends Node

func _ready() -> void:
  print("[CI] Tech Empire smoke test starting")
  SimulationManager.reset_all("CI Test", "CPU")
  if not CompanyManager.created:
    _fail("Company was not created")
    return
  if Economy.money != 500_000:
    _fail("Unexpected starting money: %s" % Economy.money)
    return
  var started: bool = ResearchManager.start_project("CI CPU", "CPU", "MAINSTREAM", "INTERNAL", "PERFORMANCE", 42_000)
  if not started:
    _fail("Could not start R&D project")
    return
  var report: Dictionary = SimulationManager.process_month_end()
  if report.is_empty():
    _fail("Monthly report is empty")
    return
  if int(report.get("money", -1)) != Economy.money:
    _fail("Monthly report balance does not match economy")
    return
  print("[CI] Smoke test passed")
  get_tree().quit(0)

func _fail(message: String) -> void:
  push_error("[CI] " + message)
  get_tree().quit(1)
