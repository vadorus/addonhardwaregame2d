extends RefCounted
## Conversations avec les personnages (retour d'Alexandre, 28/09 : « les interactions sont où ? »).
## Les situations existent déjà dans la simulation (dossiers RH, découvertes R&D, offres B2B) ;
## ici elles deviennent quelqu'un qui vient vous parler, avec des réponses aux effets réels.
##
## Clés : « HR:<id> », « RND:<id> », « CLIENT:<id> ».

const TEAM_LESSONS := preload("res://scripts/TeamLessons.gd")
const NEXT_GENERATION := preload("res://scripts/NextGeneration.gd")
const SEASONAL := preload("res://scripts/SeasonalCalendar.gd")

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
	# K4 : en décembre, Nora propose la fête de fin d'année de l'équipe.
	if SEASONAL.party_pending():
		result.append({"key":"PARTY:%d" % TimeManager.year, "speaker":"NORA"})
	if tech_final_pending():
		result.append({"key":"MILESTONE:TECH_FINAL", "speaker":"NORA"})
	# V0.10 / H4 : l'équipe n'a plus rien en chantier et le dernier CPU vieillit.
	if not NEXT_GENERATION.advice().is_empty():
		result.append({"key":"NEXT:GEN", "speaker":"NORA"})
	# Lot B : clients avec une petite puce à concevoir, prêt bancaire, grands moments du premier CPU.
	for study_value in GarageBusiness.open_offers():
		var study: Dictionary = study_value
		result.append({"key":"STUDY:%s" % str(study.get("id", "")), "speaker":"CLIENT:%s" % str(study.get("customer", ""))})
	if GarageBusiness.loan_offer_pending():
		result.append({"key":"FINANCE:LOAN", "speaker":"NORA"})
	if not GarageBusiness.first_silicon_project().is_empty():
		result.append({"key":"MILESTONE:FIRST_SILICON", "speaker":_dev_speaker()})
	if not GarageBusiness.first_binning_generation().is_empty():
		result.append({"key":"MILESTONE:FIRST_BINNING", "speaker":"NORA"})
	# Lot E1 : l'équipe de développement vient proposer une correction sur un CPU en vente.
	var advice: Dictionary = TEAM_LESSONS.pending_advice()
	if not advice.is_empty():
		result.append({"key":"ADVICE:%s:%s" % [str(advice.generation_id), str(advice.type)], "speaker":_dev_speaker()})
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

static func _dev_speaker() -> String:
	for employee_value in PersonnelManager.staff:
		var employee: Dictionary = employee_value
		if str(employee.get("department", "")) == "Développement":
			return str(employee.get("id", ""))
	return _rnd_speaker()

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
	elif key.begins_with("PARTY:"):
		if not SEASONAL.party_pending():
			return {}
		var people := PersonnelManager.staff.size() + 1
		return {"key":key, "person":_person("NORA"), "mood":"HAPPY", "kicker":"FÊTE DE FIN D'ANNÉE",
			"text":"Patron, c'est bientôt Noël ! L'équipe a bien travaillé cette année. On organise quelque chose ?",
			"note":"%d personnes. Le moral joue un peu sur la qualité du travail de chacun." % people,
			"choices":[
				{"id":"BIG", "label":str(SEASONAL.PARTY.BIG.label), "hint":"%s € • moral +8" % _money(SEASONAL.party_cost("BIG")), "primary":true},
				{"id":"SMALL", "label":str(SEASONAL.PARTY.SMALL.label), "hint":"%s € • moral +3" % _money(SEASONAL.party_cost("SMALL"))},
				{"id":"SKIP", "label":str(SEASONAL.PARTY.SKIP.label), "hint":"0 € • moral −2"},
			]}
	elif key == "NEXT:GEN":
		var next := NEXT_GENERATION.advice()
		if next.is_empty():
			return {}
		return {"key":key, "person":_person("NORA"), "mood":"WORRIED" if str(next.urgency) == "LATE" else "NEUTRAL", "kicker":"PRÉPAREZ LA SUITE",
			"text":NEXT_GENERATION.dialogue_text(next),
			"note":"%s : %d ventes le mois dernier. Les ventes baissent nettement après 2 ans sur le marché." % [str(next.product), int(next.sales)],
			"choices":[
				{"id":"START", "label":"On lance la suite !", "hint":"Ouvre l'atelier CPU (suite de la gamme ou nouvelle gamme)", "primary":true},
				{"id":"LATER", "label":"Pas tout de suite.", "hint":"Nora en reparle dans %d mois" % NEXT_GENERATION.LATER_MONTHS},
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
	elif key.begins_with("STUDY:"):
		var study := GarageBusiness.get_study(sid)
		if study.is_empty() or str(study.get("status", "")) != "OFFER":
			return {}
		var busy := int(round(float(study.get("load", 0.3)) * 100.0))
		var own_project := ResearchManager.get_active_development_project_count() > 0
		return {"key":key, "person":_person("CLIENT:%s" % str(study.get("customer", ""))), "mood":"HAPPY", "kicker":"UN CLIENT PASSE AU GARAGE",
			"text":"Bonjour ! On m'a dit que vous saviez concevoir des puces. Il nous faudrait %s, livré dans %d mois. On paie %s €, dont %s € d'avance à la signature. Ça vous intéresse ?" % [
				str(study.get("task", "une puce")), int(study.get("months", 2)), _money(int(study.get("pay", 0))), _money(GarageBusiness.study_advance(study))],
			"note":("Pendant %d mois, environ %d %% de votre équipe Développement y travaillera : votre propre CPU avancera moins vite." % [int(study.get("months", 2)), busy]) if own_project else "Votre équipe n'a pas de projet en cours : ce contrat ne ralentit rien.",
			"choices":[
				{"id":"SIGN", "label":"Marché conclu, on s'en occupe !", "hint":"Avance tout de suite, solde à la livraison • clientèle pro +1", "primary":true},
				{"id":"DECLINE", "label":"Désolé, on est concentrés sur notre CPU.", "hint":"Le client repart ; aucune pénalité"},
				{"id":"LATER", "label":"Laissez-moi y réfléchir.", "hint":"L'offre tient encore quelques semaines"},
			]}
	elif key == "FINANCE:LOAN":
		if not GarageBusiness.loan_offer_pending():
			return {}
		var terms := GarageBusiness.loan_terms()
		return {"key":key, "person":_person("NORA"), "mood":"WORRIED", "kicker":"TRÉSORERIE",
			"text":"Patron, au rythme actuel on tient à peine %d mois. J'ai vu la banque : elle nous prête %s € tout de suite, remboursés %s € par mois pendant %d mois. Ça nous donnerait de l'air jusqu'au lancement." % [
				int(floor(GarageBusiness.cash_runway_months())), _money(int(terms.amount)), _money(int(terms.monthly)), int(terms.months)],
			"note":"Coût total du prêt : %s € (%s € d'intérêts). Autre piste : accepter un contrat d'études d'un client." % [_money(int(terms.total)), _money(int(terms.total) - int(terms.amount))],
			"choices":[
				{"id":"ACCEPT", "label":"On signe, il faut tenir jusqu'au lancement.", "hint":"Trésorerie +%s € • mensualité de %s €" % [_money(int(terms.amount)), _money(int(terms.monthly))], "primary":true},
				{"id":"DECLINE", "label":"Non, on se serre la ceinture.", "hint":"Nora n'en reparle pas avant un an"},
			]}
	elif key.begins_with("ADVICE:"):
		var advice: Dictionary = TEAM_LESSONS.pending_advice()
		if advice.is_empty() or key != "ADVICE:%s:%s" % [str(advice.generation_id), str(advice.type)]:
			return {}
		return {"key":key, "person":_person(_dev_speaker()), "mood":"NEUTRAL", "kicker":"L'ÉQUIPE A UNE IDÉE",
			"text":"Patron, sur la gamme %s, %s. On peut sortir un %s : %s. On s'y met ?" % [
				str(advice.generation_name), str(advice.reason), str(advice.label), str(advice.effect)],
			"note":"Coût : %s € pour %d modèle(s) en vente." % [_money(int(advice.cost)), int(advice.products)],
			"choices":[
				{"id":"APPLY", "label":"Vas-y, on corrige.", "hint":"%s • %s €" % [str(advice.effect), _money(int(advice.cost))], "primary":true, "enabled":Economy.can_afford(int(advice.cost))},
				{"id":"NO", "label":"Non, gardons l'argent.", "hint":"L'équipe ne reviendra pas sur ce point pour cette gamme"},
				{"id":"LATER", "label":"On en reparle plus tard.", "hint":"Le « ! » reste au-dessus de sa tête"},
			]}
	elif key == "MILESTONE:FIRST_SILICON":
		var project := GarageBusiness.first_silicon_project()
		if project.is_empty():
			return {}
		var review: Dictionary = project.get("pending_decision", {})
		var confidence := float(review.get("confidence", 55.0))
		var story := "Il a démarré du premier coup. Toute l'équipe a applaudi."
		var mood := "HAPPY"
		if confidence < 50.0:
			story = "Il a fallu deux nuits blanches et un fer à souder, mais il tourne… en chauffant plus que prévu."
			mood = "WORRIED"
		elif confidence < 68.0:
			story = "Premier essai : rien. Deuxième essai, après une soudure refaite : il calcule !"
		return {"key":key, "person":_person(_dev_speaker()), "mood":mood, "kicker":"PREMIER SILICIUM",
			"text":"On vient de mettre sous tension le tout premier prototype de %s. %s" % [str(project.get("name", "notre CPU")), story],
			"note":"Confiance de l'équipe : %.0f %%. Point faible signalé : %s. C'est maintenant que se décide la suite du projet." % [confidence, GameData.metric_label(str(review.get("weakness", "reliability")))],
			"choices":[
				{"id":"SEE", "label":"Montre-moi ça au banc de test !", "hint":"Ouvre la revue du prototype", "primary":true},
			]}
	elif key == "MILESTONE:FIRST_BINNING":
		var generation := GarageBusiness.first_binning_generation()
		if generation.is_empty():
			return {}
		var yield_rate := float(generation.get("yield_rate", 0.7))
		var parts: Array[String] = []
		for product_value in ProductManager.products:
			var product: Dictionary = product_value
			if str(product.get("generation_id", "")) == str(generation.get("id", "")):
				parts.append("%d %% en %s" % [int(round(float(product.get("bin_share", 0.0)) * yield_rate * 100.0)), str(product.get("sku_label", product.get("name", "")))])
		var scrap := int(round((1.0 - yield_rate) * 100.0))
		return {"key":key, "person":_person("NORA"), "mood":"HAPPY" if yield_rate >= 0.65 else "NEUTRAL", "kicker":"TRI DES PUCES",
			"text":"Les premières plaquettes de %s sont sorties de l'usine. On a testé chaque puce une par une : %s, et %d %% au rebut." % [str(generation.get("name", "notre CPU")), ", ".join(parts), scrap],
			"note":"Chaque puce est classée selon sa qualité réelle : les meilleures deviennent le modèle haut de gamme. Un meilleur rendement = plus de puces vendables.",
			"choices":[
				{"id":"GO", "label":"Parfait, préparons le lancement !", "hint":"Direction Produits › Vendre", "primary":true},
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
	if key.begins_with("PARTY:"):
		return SEASONAL.hold_party(choice_id)
	if key == "NEXT:GEN":
		if choice_id == "START":
			return {"ok":true, "message":"", "open":"CPU_STEPPER"}
		NEXT_GENERATION.later()
		return {"ok":true, "message":"", "later":true}
	if key == "MILESTONE:TECH_FINAL":
		ExecutiveManager.workplace["tech_final_announced"] = true
		CompanyManager.add_alert("Sommet technologique atteint : la partie continue en mode libre. De nouvelles technologies arriveront avec les mises à jour.")
		return {"ok":true, "message":"Mode libre : l'empire continue."}
	if key == "MILESTONE:FIRST_SILICON":
		GarageBusiness.mark_shown("first_silicon_shown")
		return {"ok":true, "message":"Premier silicium ! Place à la revue du prototype."}
	if key == "MILESTONE:FIRST_BINNING":
		GarageBusiness.mark_shown("first_binning_shown")
		return {"ok":true, "message":"Puces triées : chaque modèle de la gamme est prêt à être lancé."}
	if key == "FINANCE:LOAN":
		if choice_id == "ACCEPT":
			var ok := GarageBusiness.accept_loan()
			return {"ok":ok, "message":"Prêt signé : la trésorerie respire." if ok else "La banque ne peut plus suivre."}
		GarageBusiness.decline_loan()
		return {"ok":true, "message":"Pas de prêt : chaque euro compte."}
	if choice_id == "LATER":
		return {"ok":true, "message":"", "later":true}
	if key.begins_with("ADVICE:"):
		var parts := key.split(":")
		if parts.size() < 3:
			return {"ok":false, "message":""}
		if choice_id == "APPLY":
			var count: int = TEAM_LESSONS.apply_advice(parts[1], parts[2])
			return {"ok":count > 0, "message":("Correction lancée sur %d modèle(s)." % count) if count > 0 else "Trésorerie insuffisante pour cette correction."}
		TEAM_LESSONS.decline_advice(parts[1], parts[2])
		return {"ok":true, "message":"L'équipe se concentre sur la suite."}
	if key.begins_with("STUDY:"):
		var ok := GarageBusiness.accept_study(sid) if choice_id == "SIGN" else GarageBusiness.decline_study(sid)
		return {"ok":ok, "message":"Contrat signé : l'avance est encaissée." if choice_id == "SIGN" else "Le client repart, sans rancune."}
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
