extends RefCounted
## D2 (07/10) — Le coût de mise sur le marché d'une puce dépend du marché visé et de sa position dans la gamme.

const LINE := preload("res://scripts/CpuProductLine.gd")

static func run(_host: Node) -> String:
	var embedded := LINE.market_entry_unit_cost("EMBEDDED")
	var home := LINE.market_entry_unit_cost("HOME_PC")
	var server := LINE.market_entry_unit_cost("SERVER")
	if embedded <= 0:
		return "D2: an embedded CPU should still pay for its test, package and warranty"
	if not (embedded < home and home < server):
		return "D2: demanding markets should cost more to serve (embedded %d, home %d, server %d)" % [embedded, home, server]
	var expected := int(round(MarketManager.segment_reference_price_base("HOME_PC") * float(LINE.MARKET_ENTRY_RATE.HOME_PC) * LINE.market_entry_era_factor()))
	if absi(home - expected) > 1:
		return "D2: home PC entry cost %d differs from rate x reference price %d" % [home, expected]
	if LINE.market_entry_unit_cost("HOME_PC", 1.5) <= home or LINE.market_entry_unit_cost("HOME_PC", 0.7) >= home:
		return "D2: premium bins should cost more to qualify than entry bins"
	# 14/10 : rampe d'époque — 40 % en 1971, plein tarif à partir de 1981.
	if not is_equal_approx(LINE.market_entry_era_factor(1971), 0.4) or not is_equal_approx(LINE.market_entry_era_factor(1981), 1.0) or not is_equal_approx(LINE.market_entry_era_factor(1995), 1.0):
		return "D2: market entry ramp should go from 40 %% in 1971 to 100 %% from 1981"
	# T-3 : le coût d'entrée reste fixé au barème D2 après 1981,
	# même quand les tarifs du marché montent entre 1985 et 2030.
	var original_year := TimeManager.year
	TimeManager.year = 1985
	var entry_1985 := LINE.market_entry_unit_cost("HOME_PC")
	TimeManager.year = 2010
	var entry_2010 := LINE.market_entry_unit_cost("HOME_PC")
	TimeManager.year = 2030
	var entry_2030 := LINE.market_entry_unit_cost("HOME_PC")
	TimeManager.year = original_year
	if entry_1985 != entry_2010 or entry_2010 != entry_2030:
		return "T-3: entry cost changed with the market price era multiplier"
	return ""
