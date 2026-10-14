extends "res://tests/tools/career_probe.gd"
## Outil (pas un test CI) — fabrique une partie « en cours de route » pour revoir tous les onglets :
## une carrière ADAPTÉE jusqu'à l'année voulue (CPU, gammes, équipe, rivaux), plus quelques logiciels du studio.
## Sauvegarde dans l'emplacement 0 du dossier de test, que capture_tabs relit.
## Usage : godot --headless --path . res://tests/tools/tabs_probe.tscn -- <année> [STANDARD|ACCESSIBLE] [graine]

const STUDIO := preload("res://scripts/SoftwareStudio.gd")
var _stop_year := 1990

func _ready() -> void:
	SaveManager.use_test_folder()
	_source_commit = _revision_from_git()
	_profiles = PROFILES_PROBE.new()
	var args := OS.get_cmdline_user_args()
	_stop_year = int(args[0]) if args.size() > 0 else 1990
	var mode := str(args[1]).to_upper() if args.size() > 1 else "ACCESSIBLE"
	var seed := int(args[2]) if args.size() > 2 else 104729
	_run_strategy("ADAPTEE", seed, mode)
	_profiles.free()
	SaveManager.writes_enabled = true
	print("[TABS] sauvegarde %s : %s" % [SaveManager.slot_path(0), str(SaveManager.save_to_slot(0, true))])
	print("[TABS] %d/%d trésorerie %d, CPU %d, logiciels %d" % [TimeManager.month, TimeManager.year, Economy.money, ProductManager.products.size(), SoftwareManager.products.size()])
	get_tree().quit(0)

func _end_year() -> int:
	return _stop_year - 1

## Un logiciel du studio de temps en temps, comme un joueur curieux : bonne idée, effort proposé par Camille.
func _extra_month(_state: Dictionary) -> void:
	for value in SoftwareManager.projects:
		if str(value.get("status", "")) == "REVIEW":
			SoftwareManager.choose_release(str(value.id), "RELEASE")
	if TimeManager.month != 3 or Economy.money < 300000:
		return
	for type_id in SoftwareManager.open_types():
		if not SoftwareManager.project_for(str(type_id)).is_empty():
			continue
		var best := ""
		for aud in STUDIO.open_audiences(TimeManager.year):
			if best == "" or STUDIO.fit(str(type_id), str(aud)) > STUDIO.fit(str(type_id), best):
				best = str(aud)
		var features: Array = []
		for id in STUDIO.sorted_features(str(type_id), TimeManager.year):
			if features.size() < 3:
				features.append(str(id))
		var tokens := {}
		for phase in STUDIO.PHASE_ORDER:
			tokens[phase] = STUDIO.ideal_tokens(str(type_id), phase, SoftwareManager.known_areas(str(type_id)))
		var spec := {"type":str(type_id), "audience":best, "platform":"OWN" if SoftwareManager.has_own_cpu() else "LEADER",
			"features":features, "tokens":tokens, "price_mode":"MARKET"}
		if SoftwareManager.start_studio_project(spec):
			return
