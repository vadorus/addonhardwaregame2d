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
	return result

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
	if choice_id == "LATER":
		return {"ok":true, "message":"", "later":true}
	if key.begins_with("RND:"):
		var ok := ResearchManager.resolve_research_event(sid, choice_id == "PURSUE")
		return {"ok":ok, "message":"La piste devient prioritaire pour 3 mois." if choice_id == "PURSUE" else "Piste notée pour plus tard."}
	if key.begins_with("HR:"):
		var ok := ExecutiveManager.resolve_hr_issue(sid, choice_id)
		return {"ok":ok, "message":"Merci, ça fait du bien." if ok else "Trésorerie insuffisante pour cette prime."}
	if key.begins_with("CLIENT:"):
		var ok := MarketManager.accept_contract(sid) if choice_id == "SIGN" else MarketManager.decline_contract(sid)
		return {"ok":ok, "message":"Contrat signé : à vous de livrer !" if choice_id == "SIGN" else "Le client repart, sans rancune."}
	return {"ok":false, "message":""}
