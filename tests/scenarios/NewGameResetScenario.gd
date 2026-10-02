extends RefCounted
## C3 (02/10) — Une nouvelle partie repart vraiment de 1971. Bug trouvé par la sonde de carrière : après une partie
## menée jusqu'en 2030, « Nouvelle partie » gardait tous les marchés ouverts (datacenters dès 1971), parce que
## MarketManager.reset() recalculait la liste en lisant l'ancienne. Vérifie aussi la migration des sauvegardes touchées.

static func run(_host: Node) -> String:
	SimulationManager.reset_all("CI Longue partie", "CPU", "STANDARD")
	TimeManager.year = 2030
	MarketManager._update_market_opportunities()
	if not MarketManager.known_segments.has("DATACENTER"):
		return "New game: the 2030 game should know the datacenter market (test setup)"
	var late_state := MarketManager.get_state()
	SimulationManager.reset_all("CI Nouvelle partie", "CPU", "STANDARD")
	if TimeManager.year != 1971 or MarketManager.is_segment_available("DATACENTER") or MarketManager.known_segments.has("MOBILE_COMPUTING"):
		return "New game: markets of the previous game leak into the new one (%s)" % str(MarketManager.known_segments)
	# Migration : une sauvegarde de 1975 qui « connaît » les datacenters (bug) les oublie au chargement.
	late_state["known_segments"] = MarketManager.MARKET_NEED_ORDER.duplicate()
	TimeManager.year = 1975
	MarketManager.load_state(late_state)
	if MarketManager.known_segments.has("DATACENTER") or not MarketManager.known_segments.has("EMBEDDED"):
		return "New game: loading a 1975 save must drop markets that cannot exist yet (%s)" % str(MarketManager.known_segments)
	SimulationManager.reset_all("CI Fin", "CPU", "STANDARD")
	return ""
