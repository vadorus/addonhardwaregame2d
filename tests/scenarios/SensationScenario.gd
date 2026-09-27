extends RefCounted
## Étape 1 « Sensation » : sons synthétisés, fil de notifications, révélation des notes, décision signalée.

const EXPECTED_SOUNDS := ["click", "open", "close", "notify", "decision", "month", "cash", "launch", "review", "review_good", "review_bad", "unlock", "error"]

static func run(host: Node) -> String:
	# Sons : tous présents, non vides, jouables sans erreur.
	for sound_name in EXPECTED_SOUNDS:
		if not SoundManager.has_sound(sound_name):
			return "Missing synthesized sound: %s" % sound_name
		SoundManager.play(sound_name)
	var previous_volume := SoundManager.sfx_volume
	SoundManager.set_volume(0.0, false)
	if not SoundManager.muted:
		return "Setting volume to 0 does not mute the game"
	SoundManager.set_volume(previous_volume, false)

	# Notifications : empilées, plafonnées, texte conservé.
	var feed: Control = (load("res://ui/NotificationFeed.gd") as Script).new() as Control
	host.add_child(feed)
	for i in range(6):
		feed.call("push", "Notification %d" % i, "info", -1)
	if int(feed.call("toast_count")) != 3:
		feed.queue_free()
		return "Notification feed should keep at most 3 cards (got %d)" % int(feed.call("toast_count"))
	var texts: Array = feed.call("toast_texts")
	if str(texts.back()) != "Notification 5":
		feed.queue_free()
		return "Newest notification is not shown last"
	feed.queue_free()

	# Révélation des notes : une carte par média, moyenne et verdict.
	var panel: Control = (load("res://ui/components/ReviewRevealPanel.gd") as Script).new() as Control
	host.add_child(panel)
	var reviews := [
		{"source_name":"Circuit Lab", "channel_label":"Laboratoire", "score":82.0, "headline":"Rapide"},
		{"source_name":"Systems & Industry Review", "channel_label":"Presse spécialisée", "score":74.0, "headline":"Solide"}
	]
	panel.call("show_reviews", "Nova 1", reviews)
	panel.call("reveal_all")
	if int(panel.call("revealed_count")) != 2:
		panel.queue_free()
		return "Review reveal did not show one card per outlet"
	if not str(panel.call("verdict_text")).contains("7.8/10"):
		panel.queue_free()
		return "Review reveal verdict does not show the average out of 10: %s" % str(panel.call("verdict_text"))
	panel.queue_free()

	# La presse émet bien l'événement qui déclenche l'écran de révélation.
	SimulationManager.reset_all("CI Sensation", "CPU", "STANDARD")
	var captured: Array = []
	var capture := func(product_name: String, published: Array): captured.append([product_name, published.size()])
	MediaManager.reviews_published.connect(capture)
	MediaManager.publish_product_review({"id":"CI-P", "name":"Nova CI", "target_segment":"EMBEDDED", "quality":70.0}, {}, 1, 3)
	MediaManager.reviews_published.disconnect(capture)
	if captured.is_empty() or int(captured[0][1]) < 1:
		return "MediaManager did not emit reviews_published with the outlets' reviews"

	# Garage : une nouvelle décision émet decision_raised (toast + son dans le jeu).
	var garage: Control = (load("res://ui/GarageHub.gd") as Script).new() as Control
	var decisions: Array = []
	garage.set("decision_source", func() -> Array: return decisions)
	host.add_child(garage)
	var raised: Array = []
	garage.connect("decision_raised", func(title: String, tab: int): raised.append(title))
	decisions.append({"id":"RH:9", "category":"RH", "severity":50.0, "title":"Recrutement urgent", "recommendation":"", "target_tab":1})
	garage.call("focus_decision")
	garage.call("focus_decision")
	garage.queue_free()
	if raised.size() != 1 or str(raised[0]) != "Recrutement urgent":
		return "Garage should raise a new decision exactly once (got %s)" % str(raised)
	return ""
