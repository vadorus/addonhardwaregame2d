extends RefCounted
## Conversations avec les personnages (retour d'Alexandre, 28/09 : « les interactions sont où ? »).
## Les situations existent déjà dans la simulation (dossiers RH, découvertes R&D, offres B2B) ;
## ici elles deviennent quelqu'un qui vient vous parler, avec des réponses aux effets réels.
##
## Clés : « HR:<id> », « RND:<id> », « CLIENT:<id> ».

## Toutes les conversations en attente, avec qui parle.
static func pending() -> Array:
	var result: Array = []
	for event_value in ResearchManager.get_pending_research_events():
		var event: Dictionary = event_value
		result.append({"key":"RND:%s" % str(event.get("id", "")), "speaker":_rnd_speaker()})
	for issue_value in ExecutiveManager.get_open_hr_issues():
		var issue: Dictionary = issue_value
		result.append({"key":"HR:%s" % str(issue.get("id", "")), "speaker":_hr_speaker(issue)})
	for contract_value in MarketManager.contracts:
		var contract: Dictionary = contract_value
		if str(contract.get("status", "")) == "PENDING":
			result.append({"key":"CLIENT:%s" % str(contract.get("id", "")), "speaker":"CLIENT:%s" % str(contract.get("customer", ""))})
	if not hiring_need().is_empty():
		result.append({"key":"HIRE:DEV", "speaker":"NORA"})
	if tech_final_pending():
		result.append({"key":"MILESTONE:TECH_FINAL", "speaker":"NORA"})
	var interview := press_interview_product()
	if not interview.is_empty():
		result.append({"key":"PRESS:%s" % str(interview.get("id", "")), "speaker":"PRESS:%s" % journalist_outlet()})
	return result

## Nora pousse à grandir : le CPU en cours demande plus de développeurs que l'équipe n'en a,
## et la trésorerie permet d'embaucher (équilibrage 28/09 : l'équipe restait à 3 pendant 15 ans).
static func hiring_need() -> Dictionary:
	var project: Dictionary = {}
	for project_value in ResearchManager.projects:
		if str((project_value as Dictionary).get("status", "")) == "DEVELOPMENT":
			project = project_value
			break
	if project.is_empty():
		return {}
	if ExecutiveManager.months_operated < int(ExecutiveManager.workplace.get("hiring_reminder_at", -1)):
		return {}
	var estimator: Script = load("res://scripts/DevelopmentEstimator.gd")
	var complexity := float(project.get("complexity", 30.0))
	var required: float = estimator.call("required_developers", complexity)
	var devs := ResearchManager.get_development_team_size()
	if float(devs) >= required - 0.5:
		return {}
	var monthly_staff := 0
	for employee_value in PersonnelManager.staff:
		monthly_staff += int((employee_value as Dictionary).get("salary", 3000))
	if Economy.money < monthly_staff * 12 + 40000:
		return {}
	var now: float = estimator.call("staffing_factor", devs, complexity)
	var plus_one: float = estimator.call("staffing_factor", devs + 1, complexity)
	return {"project":str(project.get("name", "le CPU")), "required":int(ceil(required)), "devs":devs,
		"gain_pct":int(round((plus_one / maxf(now, 0.01) - 1.0) * 100.0))}

## Fin du contenu technologique de cette version (décision d'Alexandre, 28/09) :
## on le dit clairement au joueur, puis la partie continue en mode libre.
static func tech_final_pending() -> bool:
	if bool(ExecutiveManager.workplace.get("tech_final_announced", false)):
		return false
	if TimeManager.year >= MarketManager.FINAL_TECH_YEAR:
		return true
	for key in ResearchManager.get_cpu_capability_keys():
		if ResearchManager.get_cpu_capability(str(key)) < 99.5:
			return false
	return float(ResearchManager.technologies.get("manufacturing", 0.0)) >= 99.5

static func _career_summary() -> String:
	var launched := 0
	var units := 0
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "LAUNCHED" or int(product.get("months_on_market", 0)) > 0:
			launched += 1
		units += int(product.get("units_sold_total", 0))
	var parts: Array[String] = [
		"%d ans d'activité depuis %d" % [TimeManager.year - CompanyManager.founded_year, CompanyManager.founded_year],
		"%d générations de CPU, %d références" % [ProductManager.cpu_generations.size(), launched],
		"%d personnes dans l'équipe" % PersonnelManager.staff.size(),
		"trésorerie %s €" % _money(Economy.money),
	]
	if units > 0:
		parts.insert(2, "%s puces vendues" % _money(units))
	return " • ".join(parts)

## Produit tout juste lancé, pas encore testé, dont personne n'a encore parlé à la presse.
static func press_interview_product() -> Dictionary:
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		if str(product.get("status", "")) == "LAUNCHED" and int(product.get("months_on_market", 0)) == 0 and not product.has("press_pitch"):
			return product
	return {}

static func journalist_outlet() -> String:
	for outlet_value in MediaManager.available_outlets():
		var outlet: Dictionary = outlet_value
		if str(outlet.get("channel", "")) == "SPECIALIST_PRESS":
			return str(outlet.get("name", "La presse"))
	return "La presse"

## Votre réponse vaut pour toute la gamme lancée en même temps.
static func _set_press_pitch(product_id: String, pitch: String) -> void:
	var generation := str(ProductManager.get_product(product_id).get("generation_id", ""))
	for product_value in ProductManager.products:
		var product: Dictionary = product_value
		var same := str(product.get("id", "")) == product_id or (generation != "" and str(product.get("generation_id", "")) == generation)
		if same and str(product.get("status", "")) == "LAUNCHED" and int(product.get("months_on_market", 0)) == 0:
			product["press_pitch"] = pitch

## Première conversation en attente pour ce personnage (ou vide).
static func pending_for(speaker_key: String) -> String:
	for item_value in pending():
		var item: Dictionary = item_value
		if str(item.speaker) == speaker_key:
			return str(item.key)
	return ""

static func _rnd_speaker() -> String:
	for employee_value in PersonnelManager.staff:
		var employee: Dictionary = employee_value
		if str(employee.get("department", "")) == "R&D":
			return str(employee.get("id", ""))
	return "NORA"

static func _hr_speaker(issue: Dictionary) -> String:
	var subject := str(issue.get("subject_id", ""))
	if str(issue.get("type", "")) == "MORALE" and not PersonnelManager.get_employee(subject).is_empty():
		return subject
	return "NORA"

static func _person(speaker_key: String) -> Dictionary:
	if speaker_key == "NORA":
		var nora := ExecutiveManager.get_right_hand()
		return {"key":"NORA", "name":str(nora.get("name", "Nora Bernard")), "role":"Votre bras droit"}
	if speaker_key.begins_with("CLIENT:"):
		return {"key":speaker_key, "name":speaker_key.substr(7), "role":"Acheteur • visite au garage"}
	if speaker_key.begins_with("PRESS:"):
		return {"key":speaker_key, "name":"Journaliste de %s" % speaker_key.substr(6), "role":"Interview avant les premiers tests"}
	var employee := PersonnelManager.get_employee(speaker_key)
	return {"key":speaker_key, "name":str(employee.get("name", "Un salarié")), "role":str(employee.get("role", ""))}

static func _money(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out

## Contenu de la conversation : qui parle, ce qu'il dit, les réponses possibles.
static func dialogue(key: String) -> Dictionary:
	var sid := key.substr(key.find(":") + 1)
	if key.begins_with("RND:"):
		for event_value in ResearchManager.get_pending_research_events():
			var event: Dictionary = event_value
			if str(event.get("id", "")) != sid:
				continue
			var speaker := _rnd_speaker()
			var domain := str(event.get("domain", ""))
			return {"key":key, "person":_person(speaker), "mood":"HAPPY", "kicker":"DÉCOUVERTE R&D",
				"text":"Bonne nouvelle : on atteint %.0f en %s ! J'ai une piste. Si on s'y consacre à fond pendant 3 mois, on apprend beaucoup plus vite. On fonce ?" % [float(event.get("threshold", 0.0)), ResearchManager.get_cpu_research_label(domain)],
				"choices":[
					{"id":"PURSUE", "label":"Fonce, c'est la priorité !", "hint":"Élan de recherche pendant 3 mois + expérience", "primary":true},
					{"id":"ARCHIVE", "label":"Note-la, on verra plus tard.", "hint":"Le savoir acquis est conservé"},
				]}
	elif key.begins_with("HR:"):
		var issue := ExecutiveManager.get_hr_issue(sid)
		if issue.is_empty() or str(issue.get("status", "")) != "OPEN":
			return {}
		var speaker := _hr_speaker(issue)
		var text := str(issue.get("text", ""))
		var discuss := "On prend un café et on en parle."
		var discuss_hint := "Gratuit • apaise la situation"
		match str(issue.get("type", "")):
			"MORALE":
				var employee := PersonnelManager.get_employee(speaker)
				text = "Je ne vais pas vous mentir… je suis à bout en ce moment. (moral %.0f/100)" % float(employee.get("morale", 50.0))
				discuss_hint = "Gratuit • moral +8"
			"COHESION":
				text = "L'équipe %s se tire dans les pattes. Il faudrait intervenir avant que ça ralentisse les projets." % str(issue.get("subject_id", ""))
				discuss = "Je réunis tout le monde pour crever l'abcès."
				discuss_hint = "Gratuit • cohésion +7"
			"OVERCROWDING":
				text = "On se marche dessus ici. %s" % str(issue.get("text", ""))
				discuss = "On réorganise l'espace en attendant."
				discuss_hint = "Gratuit • petit mieux"
		var cost := ExecutiveManager.hr_bonus_cost(sid)
		return {"key":key, "person":_person(speaker), "mood":"WORRIED", "kicker":"L'ÉQUIPE VOUS PARLE", "text":text,
			"choices":[
				{"id":"DISCUSS", "label":discuss, "hint":discuss_hint, "primary":true},
				{"id":"BONUS", "label":"Je débloque une prime (%s €)." % _money(cost), "hint":"Effet plus fort sur le moral", "enabled":Economy.can_afford(cost)},
				{"id":"LATER", "label":"Pas maintenant.", "hint":"Le problème reste ouvert"},
			]}
	elif key == "HIRE:DEV":
		var need := hiring_need()
		if need.is_empty():
			return {}
		return {"key":key, "person":_person("NORA"), "mood":"NEUTRAL", "kicker":"GRANDIR",
			"text":"Pour %s, il faudrait environ %d développeurs. On n'est que %d : le projet traîne. Avec une recrue de plus, on avancerait %d %% plus vite. On embauche ?" % [str(need.project), int(need.required), int(need.devs), int(need.gain_pct)],
			"note":"Chaque recrue : salaire d'environ 3 000 à 4 000 €/mois + prime d'embauche (2 mois). Attention à la place dans les locaux.",
			"choices":[
				{"id":"HIRE1", "label":"Recrute un développeur.", "hint":"Le projet accélère dès le mois prochain", "primary":true},
				{"id":"HIRE2", "label":"Recrute-en deux.", "hint":"Encore plus vite, deux salaires de plus"},
				{"id":"LATER", "label":"On reste comme ça pour l'instant.", "hint":"Nora n'en reparle pas avant 6 mois"},
			]}
	elif key == "MILESTONE:TECH_FINAL":
		if not tech_final_pending():
			return {}
		return {"key":key, "person":_person("NORA"), "mood":"HAPPY", "kicker":"SOMMET TECHNOLOGIQUE",
			"text":"Patron… on y est. Gravure, architecture, cartographie : on a atteint le sommet de ce que la technologie permet dans cette version du monde. Les prochaines percées arriveront avec les futures mises à jour. D'ici là, l'entreprise continue : parts de marché à prendre, rivaux à dépasser, clients à fidéliser.",
			"note":"Bilan : %s" % _career_summary(),
			"choices":[
				{"id":"CONTINUE", "label":"On continue : l'empire n'est pas fini !", "hint":"La partie continue en mode libre", "primary":true},
			]}
	elif key.begins_with("PRESS:"):
		var product := ProductManager.get_product(sid)
		if product.is_empty() or product.has("press_pitch") or int(product.get("months_on_market", 0)) != 0:
			return {}
		return {"key":key, "person":_person("PRESS:%s" % journalist_outlet()), "mood":"NEUTRAL", "kicker":"INTERVIEW",
			"text":"Votre %s arrive en boutique. Nos lecteurs veulent savoir : qu'est-ce qui le rend spécial ?" % str(product.get("name", "CPU")),
			"note":"Votre réponse colore les premiers tests de la presse.",
			"choices":[
				{"id":"BOLD", "label":"« C'est tout simplement le meilleur CPU du marché. »", "hint":"Tests en hausse si c'est vrai (n°1 du benchmark), en forte baisse sinon", "primary":false},
				{"id":"HONEST", "label":"« Un CPU solide et honnête. Jugez sur pièce. »", "hint":"Petit bonus assuré : la presse apprécie la franchise", "primary":true},
				{"id":"TECH", "label":"« Parlons chiffres : fiabilité, consommation, fréquence. »", "hint":"Labos et presse spécialisée +, grand public −"},
				{"id":"NONE", "label":"« Pas de commentaire. »", "hint":"Aucun effet"},
			]}
	elif key.begins_with("CLIENT:"):
		for contract_value in MarketManager.contracts:
			var contract: Dictionary = contract_value
			if str(contract.get("id", "")) != sid or str(contract.get("status", "")) != "PENDING":
				continue
			var product := ProductManager.get_product(str(contract.get("product_id", "")))
			var units := int(contract.get("units_per_month", 0))
			var price := int(contract.get("unit_price", 0))
			return {"key":key, "person":_person("CLIENT:%s" % str(contract.get("customer", ""))), "mood":"HAPPY", "kicker":"UN CLIENT PASSE AU GARAGE",
				"text":"Bonjour ! Votre %s nous intéresse. Il nous en faudrait %d par mois pendant %d mois, à %s € pièce. Vous pouvez suivre ?" % [str(contract.get("product_name", "CPU")), units, int(contract.get("remaining_months", 12)), _money(price)],
				"note":"Votre capacité : %d unités/mois • ce contrat : %s €/mois de ventes" % [int(product.get("production_capacity", 0)), _money(units * price)],
				"choices":[
					{"id":"SIGN", "label":"Marché conclu !", "hint":"Clientèle pro +2 • honorez-le jusqu'au bout pour gagner leur confiance", "primary":true},
					{"id":"DECLINE", "label":"Désolé, pas cette fois.", "hint":"Le client repart ; aucune pénalité"},
					{"id":"LATER", "label":"Je vous rappelle.", "hint":"L'offre reste sur la table"},
				]}
	return {}

## Applique une réponse. Renvoie {ok, message}.
static func choose(key: String, choice_id: String) -> Dictionary:
	var sid := key.substr(key.find(":") + 1)
	if key == "HIRE:DEV":
		if choice_id == "LATER":
			ExecutiveManager.workplace["hiring_reminder_at"] = ExecutiveManager.months_operated + 6
			return {"ok":true, "message":"", "later":true}
		var hired := 0
		for _i in range(2 if choice_id == "HIRE2" else 1):
			PersonnelManager.generate_candidate("Développement")
			if PersonnelManager.hire_candidate():
				hired += 1
		return {"ok":hired > 0, "message":("%d développeur(s) rejoignent l'équipe !" % hired) if hired > 0 else "Trésorerie insuffisante pour recruter."}
	if key == "MILESTONE:TECH_FINAL":
		ExecutiveManager.workplace["tech_final_announced"] = true
		CompanyManager.add_alert("Sommet technologique atteint : la partie continue en mode libre. De nouvelles technologies arriveront avec les mises à jour.")
		return {"ok":true, "message":"Mode libre : l'empire continue."}
	if choice_id == "LATER":
		return {"ok":true, "message":"", "later":true}
	if key.begins_with("RND:"):
		var ok := ResearchManager.resolve_research_event(sid, choice_id == "PURSUE")
		return {"ok":ok, "message":"La piste devient prioritaire pour 3 mois." if choice_id == "PURSUE" else "Piste notée pour plus tard."}
	if key.begins_with("HR:"):
		var ok := ExecutiveManager.resolve_hr_issue(sid, choice_id)
		return {"ok":ok, "message":"Merci, ça fait du bien." if ok else "Trésorerie insuffisante pour cette prime."}
	if key.begins_with("PRESS:"):
		if ProductManager.get_product(sid).is_empty():
			return {"ok":false, "message":""}
		_set_press_pitch(sid, choice_id)
		var messages := {"BOLD":"Promesse faite : le benchmark dira si vous aviez raison.", "HONEST":"La presse apprécie votre franchise.",
			"TECH":"Les labos ont noté vos chiffres.", "NONE":"Le journaliste repart sans citation."}
		return {"ok":true, "message":str(messages.get(choice_id, ""))}
	if key.begins_with("CLIENT:"):
		var ok := MarketManager.accept_contract(sid) if choice_id == "SIGN" else MarketManager.decline_contract(sid)
		return {"ok":ok, "message":"Contrat signé : à vous de livrer !" if choice_id == "SIGN" else "Le client repart, sans rancune."}
	return {"ok":false, "message":""}
