extends VBoxContainer

const CPU_DESIGN := preload("res://scripts/CpuDesign.gd")
const UI := preload("res://ui/UiKit.gd")

var market_product_select: OptionButton
var market_label: Label
var product_pulse_panel: Control
var market_competitor_select: OptionButton
var market_comparison_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build()
	refresh()

## Parties de ce panneau que l'écran Marché répartit en sous-pages.
var product_nodes: Array = []
var needs_nodes: Array = []
var competitor_nodes: Array = []
var ranking_box: VBoxContainer
var needs_box: VBoxContainer
var competitors_box: VBoxContainer

func _build() -> void:
	add_child(UI.section("Votre produit"))
	market_product_select = OptionButton.new()
	market_product_select.custom_minimum_size.y = 42
	market_product_select.item_selected.connect(func(_i): refresh())
	add_child(market_product_select)
	var pulse_script: Script = load("res://ui/components/ProductPulsePanel.gd")
	product_pulse_panel = pulse_script.new() as Control
	add_child(product_pulse_panel)
	add_child(UI.eyebrow("CLASSEMENT FACE AUX CONCURRENTS"))
	ranking_box = VBoxContainer.new()
	ranking_box.add_theme_constant_override("separation", 6)
	add_child(ranking_box)
	# Ancien récapitulatif texte : conservé (tests, détails) mais plus affiché.
	market_label = UI.rich_label()
	market_label.visible = false
	add_child(market_label)
	product_nodes = get_children()

	add_child(UI.section("Besoins du marché"))
	needs_box = VBoxContainer.new()
	needs_box.add_theme_constant_override("separation", 8)
	add_child(needs_box)
	needs_nodes = get_children().slice(product_nodes.size())

	var first_competitor_index := get_child_count()
	add_child(UI.section("Concurrents"))
	competitors_box = VBoxContainer.new()
	competitors_box.add_theme_constant_override("separation", 8)
	add_child(competitors_box)
	add_child(UI.section("Comparaison détaillée"))
	var intro := UI.muted_label("Comparez les informations publiques disponibles. Les données internes des concurrents restent cachées : la simulation les utilise, mais votre entreprise ne les connaît pas automatiquement.", 12)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(intro)
	market_competitor_select = OptionButton.new()
	market_competitor_select.item_selected.connect(func(_i): _refresh_comparison())
	add_child(market_competitor_select)
	market_comparison_label = UI.rich_label()
	market_comparison_label.custom_minimum_size.y = 150
	add_child(market_comparison_label)
	competitor_nodes = get_children().slice(first_competitor_index)

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _info_card(title: String, subtitle: String, body: String, badge: String = "") -> Control:
	var card := UI.card(UI.APP_PANEL, 12, 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	var head := UI.label(title, 15)
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(head)
	if subtitle != "":
		column.add_child(UI.label(subtitle, 13))
	if body != "":
		var text := UI.muted_label(body, 12)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(text)
	if badge != "":
		var tag := UI.label(badge, 13)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tag.add_theme_stylebox_override("normal", UI.stylebox(UI.APP_CYAN_DARK, 12, 0, UI.APP_CYAN_DARK, 8))
		row.add_child(tag)
	return card

## Besoins, concurrents et classement en fiches (avant : un seul long texte).
func _refresh_cards() -> void:
	if needs_box == null:
		return
	_clear(needs_box)
	needs_box.add_child(UI.muted_label("Marché CPU %d • maturité technologique %.0f/100" % [TimeManager.year, MarketManager.market_technology_signal()], 13))
	for row_value in MarketManager.market_landscape():
		var row: Dictionary = row_value
		needs_box.add_child(_info_card(str(row.get("label", "")),
			"~%s unités/mois • prix de référence %s €" % [UI.money(int(row.get("units", 0))), UI.money(int(row.get("reference_price", 0)))],
			str(row.get("description", ""))))
	var next_needs := MarketManager.next_market_needs()
	if not next_needs.is_empty():
		needs_box.add_child(UI.eyebrow("BIENTÔT"))
		for next_value in next_needs:
			var next_need: Dictionary = next_value
			needs_box.add_child(_info_card(str(next_need.get("label", "")), "",
				"Vers %d, ou plus tôt quand la maturité technologique atteindra %.0f." % [int(next_need.get("historical_year", 0)), float(next_need.get("tech_trigger", 0.0))],
				"À venir"))

	_clear(competitors_box)
	for competitor_value in MarketManager.cpu_competitor_public_profiles():
		var competitor: Dictionary = competitor_value
		var extra: Array[String] = []
		# Lot F1 : santé du rival (génération ratée, difficultés) - c'est là que naissent les rachats.
		var health := str(competitor.get("health", ""))
		if health != "":
			extra.append("État : %s" % health)
		for key_label in [["technology_partner", "Partenaire"], ["public_b2b_customer", "Client B2B"], ["recent_public_action", "Récemment"]]:
			var value := str(competitor.get(str(key_label[0]), ""))
			if value != "":
				extra.append("%s : %s" % [str(key_label[1]), value])
		competitors_box.add_child(_info_card(
			"%s — %s" % [str(competitor.get("company", "")), str(competitor.get("product", ""))],
			"Cible %s • %s € • %s" % [MarketManager.segment_label(str(competitor.get("target_segment", "EMBEDDED"))), UI.money(int(competitor.get("price", 0))), str(competitor.get("market_signal", "Présence limitée"))],
			" • ".join(extra),
			"%.0f pts" % float(competitor.get("benchmark_score", 0.0))))
	# Les fiches ne doivent pas bloquer le défilement au doigt.
	UI.prepare_touch_scroll_children(needs_box)
	UI.prepare_touch_scroll_children(competitors_box)

	_clear(ranking_box)
	if market_product_select.item_count == 0:
		ranking_box.add_child(UI.muted_label("Aucun de vos CPU n'est encore en vente.", 13))
		return
	var product := ProductManager.get_product(UI.option_meta(market_product_select))
	if product.is_empty():
		return
	var benchmark := MarketManager.benchmark_for(product)
	var best := 1.0
	for entry in benchmark:
		best = maxf(best, float(entry.score))
	for i in range(benchmark.size()):
		var entry: Dictionary = benchmark[i]
		var meter := UI.meter_row("%d. %s%s" % [i + 1, str(entry.name), "  ← vous" if bool(entry.player) else ""], "%s €" % UI.money(int(entry.price)))
		UI.set_meter(meter, float(entry.score) / best * 100.0, "%.0f pts" % float(entry.score))
		ranking_box.add_child(meter)
	UI.prepare_touch_scroll_children(ranking_box)

func refresh() -> void:
	_refresh_product_options()
	_refresh_product_pulse()
	_refresh_overview()
	_refresh_cards()
	_refresh_comparison()

func set_viewport_width(width: float) -> void:
	if product_pulse_panel != null and product_pulse_panel.has_method("set_viewport_width"):
		product_pulse_panel.call("set_viewport_width", width)

func _refresh_product_pulse() -> void:
	if product_pulse_panel == null or not product_pulse_panel.has_method("refresh_product"):
		return
	if market_product_select.item_count == 0:
		product_pulse_panel.call("refresh_product", {})
		return
	product_pulse_panel.call("refresh_product", ProductManager.get_product(UI.option_meta(market_product_select)))

func _refresh_product_options() -> void:
	var current := UI.option_meta(market_product_select) if market_product_select.item_count > 0 else ""
	market_product_select.clear()
	# 29/09 : la liste s'ouvrait sur le plus vieux CPU (30 ventes/mois). Meilleures ventes d'abord.
	var launched: Array = []
	for product_value in ProductManager.products:
		if str((product_value as Dictionary).status) == "LAUNCHED":
			launched.append(product_value)
	launched.sort_custom(func(a, b): return int(a.get("last_month_sales", 0)) > int(b.get("last_month_sales", 0)))
	for product_value in launched:
		var product: Dictionary = product_value
		market_product_select.add_item("%s — %s ventes/mois" % [str(product.name), UI.money(int(product.get("last_month_sales", 0)))])
		market_product_select.set_item_metadata(market_product_select.item_count - 1, str(product.id))
	if current != "":
		UI.select_meta(market_product_select, current)
	if market_product_select.selected < 0 and market_product_select.item_count > 0:
		market_product_select.select(0)

	var current_competitor := UI.option_meta(market_competitor_select) if market_competitor_select.item_count > 0 else ""
	market_competitor_select.clear()
	for profile_value in MarketManager.cpu_competitor_public_profiles():
		var profile: Dictionary = profile_value
		market_competitor_select.add_item("%s — %s" % [str(profile.get("company", "")), str(profile.get("product", ""))])
		market_competitor_select.set_item_metadata(market_competitor_select.item_count - 1, str(profile.get("id", "")))
	if current_competitor != "":
		UI.select_meta(market_competitor_select, current_competitor)
	if market_competitor_select.selected < 0 and market_competitor_select.item_count > 0:
		market_competitor_select.select(0)

func _refresh_overview() -> void:
	var lines: Array[String] = [
		"Marché CPU — %d • signal technologique %.0f/100" % [TimeManager.year, MarketManager.market_technology_signal()],
		"",
		"Besoins actifs :"
	]
	for row_value in MarketManager.market_landscape():
		var row: Dictionary = row_value
		lines.append("• %s — marché ~%s unités/mois • repère prix %s €" % [
			str(row.get("label", "")), UI.money(int(row.get("units", 0))), UI.money(int(row.get("reference_price", 0)))
		])
		lines.append("  %s" % str(row.get("description", "")))

	var next_needs := MarketManager.next_market_needs()
	if not next_needs.is_empty():
		lines.append("\nBesoins susceptibles d'émerger ensuite :")
		for next_value in next_needs:
			var next_need: Dictionary = next_value
			lines.append("• %s — repère historique %d, ou plus tôt si le signal techno atteint %.0f/100" % [
				str(next_need.get("label", "")), int(next_need.get("historical_year", 0)),
				float(next_need.get("tech_trigger", 0.0))
			])

	lines.append("\nConcurrents CPU — informations publiques :")
	for competitor_value in MarketManager.cpu_competitor_public_profiles():
		var competitor: Dictionary = competitor_value
		lines.append("• %s — %s G%d • %s • cible %s • %s €" % [
			str(competitor.get("company", "")), str(competitor.get("product", "")), int(competitor.get("generation", 1)),
			CPU_DESIGN.node_label(int(competitor.get("node_nm", 10000))),
			MarketManager.segment_label(str(competitor.get("target_segment", "EMBEDDED"))),
			UI.money(int(competitor.get("price", 0)))
		])
		lines.append("  benchmark %.1f • %s • %d mois sur le marché" % [
			float(competitor.get("benchmark_score", 0.0)), str(competitor.get("market_signal", "Présence limitée")),
			int(competitor.get("months_on_market", 0))
		])
		var technology_partner := str(competitor.get("technology_partner", ""))
		if technology_partner != "":
			lines.append("  Partenariat technologique public : %s" % technology_partner)
		var public_b2b_customer := str(competitor.get("public_b2b_customer", ""))
		if public_b2b_customer != "":
			lines.append("  Contrat B2B public : %s" % public_b2b_customer)
		var public_action := str(competitor.get("recent_public_action", ""))
		if public_action != "":
			lines.append("  Mouvement observé : %s" % public_action)

	if market_product_select.item_count == 0:
		lines.append("\nAucun de vos CPU n'est encore commercialisé. Le marché et les concurrents continuent néanmoins d'évoluer.")
	else:
		var product := ProductManager.get_product(UI.option_meta(market_product_select))
		if not product.is_empty():
			var benchmark := MarketManager.benchmark_for(product)
			lines.append("\nBenchmark %s :" % str(product.get("name", "CPU")))
			for i in range(benchmark.size()):
				lines.append("%d. %s — %.1f pts — %s €%s" % [
					i + 1, str(benchmark[i].name), float(benchmark[i].score), UI.money(int(benchmark[i].price)),
					" ← vous" if bool(benchmark[i].player) else ""
				])
			lines.append("\nÉvaluation sur les marchés actuellement ouverts :")
			for segment_value in MarketManager.available_segment_keys():
				var segment := str(segment_value)
				lines.append("• %s : %.1f/100" % [MarketManager.segment_label(segment), MarketManager.evaluate_product(product, segment)])
			var age_penalty := float(product.get("last_month_age_penalty", MarketManager.product_age_penalty(product)))
			lines.append("\nCycle commercial : %s | %d mois sur le marché | pression d'âge -%.1f pts" % [
				MarketManager.product_lifecycle_label(product), int(product.get("months_on_market", 0)), age_penalty
			])
			var lifecycle := ProductManager.get_post_launch_summary(str(product.get("id", "")))
			var promotion_note := "aucune promotion"
			if str(lifecycle.get("promotion_type", "NONE")) != "NONE":
				promotion_note = "%s • %d mois restants" % [
					ProductManager.promotion_label(str(lifecycle.promotion_type)), int(lifecycle.promotion_months_remaining)
				]
			lines.append("Suivi produit : stepping %s • firmware v%d • %s" % [
				str(lifecycle.get("revision", "A0")), int(lifecycle.get("firmware_version", 1)), promotion_note
			])
			lines.append("Dernier mois : %s ventes | %.1f%% part estimée | %d retours SAV | satisfaction %.1f/100" % [
				UI.money(int(product.get("last_month_sales", 0))), float(product.get("last_month_share", 0.0)) * 100.0,
				int(product.get("last_month_returns", 0)), float(product.get("customer_satisfaction", 50.0))
			])
			var feedback := ProductManager.get_market_feedback(str(product.get("id", "")))
			if not feedback.is_empty():
				var forecast_text := "prévision initiale indisponible"
				if int(feedback.get("expected_units", 0)) > 0:
					forecast_text = "prévision %s–%s, centre %s" % [
						UI.money(int(feedback.get("min_units", 0))),
						UI.money(int(feedback.get("max_units", 0))),
						UI.money(int(feedback.get("expected_units", 0)))
					]
				lines.append("Retour marché : %s • %s • contribution %s € • capacité %.0f%% • demande non servie %s" % [
					str(feedback.get("verdict", "Mesuré")),
					forecast_text,
					UI.money(int(feedback.get("net_contribution", 0))),
					float(feedback.get("capacity_utilization", 0.0)) * 100.0,
					UI.money(int(feedback.get("unserved_demand", 0)))
				])
				lines.append("Leçon : %s" % str(feedback.get("lesson", "")))
	market_label.text = "\n".join(lines)

func _refresh_comparison() -> void:
	if market_product_select.item_count == 0:
		market_comparison_label.text = "Commercialisez un CPU pour le comparer directement aux produits concurrents."
		return
	if market_competitor_select.item_count == 0:
		market_comparison_label.text = "Aucun concurrent public disponible pour cette comparaison."
		return
	var product := ProductManager.get_product(UI.option_meta(market_product_select))
	var comparison := MarketManager.compare_cpu_public(product, UI.option_meta(market_competitor_select))
	if comparison.is_empty():
		market_comparison_label.text = "Comparaison indisponible."
		return
	var lines: Array[String] = [
		"%s face à %s — %s" % [
			str(product.get("name", "Votre CPU")), str(comparison.get("competitor_name", "Concurrent")),
			str(comparison.get("competitor_company", ""))
		],
		"Cible comparée : %s" % MarketManager.segment_label(str(comparison.get("target_segment", MarketManager.default_segment()))),
		"",
		"Votre prix : %s € • concurrent : %s € • écart %+.1f%%" % [
			UI.money(int(comparison.get("player_price", 0))), UI.money(int(comparison.get("competitor_price", 0))),
			float(comparison.get("price_premium_pct", 0.0))
		],
		"Adéquation cible : %.1f vs %.1f • benchmark : %.1f vs %.1f" % [
			float(comparison.get("player_fit", 0.0)), float(comparison.get("competitor_fit", 0.0)),
			float(comparison.get("player_benchmark", 0.0)), float(comparison.get("competitor_benchmark", 0.0))
		]
	]
	for row_value in comparison.get("rows", []):
		var row: Dictionary = row_value
		lines.append("• %s : %.1f vs %.1f (%+.1f)" % [
			str(row.get("label", "")), float(row.get("player", 0.0)),
			float(row.get("competitor", 0.0)), float(row.get("delta", 0.0))
		])
	lines.append("")
	lines.append(str(comparison.get("summary", "")))
	market_comparison_label.text = "\n".join(lines)
