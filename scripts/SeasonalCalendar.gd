extends RefCounted
## V0.10 / K4 — le calendrier commercial (idée d'Alexandre, 01/10) : les périodes de l'année changent
## vraiment le jeu, comme dans la réalité.
## - Rentrée (septembre), avant les fêtes (novembre), fêtes (décembre) : le grand public achète plus.
## - Après les fêtes (janvier), vacances (août) : on achète moins.
## - Les clients pros vident leurs budgets en décembre et ralentissent en août.
## Sur une année, les variations s'équilibrent (moyenne ≈ 1) : c'est du rythme, pas un bonus caché.
## La taille des marchés change pour tout le monde (rivaux compris).
## En décembre, Nora propose la fête de fin d'année de l'équipe (moral, donc productivité).

const CONSUMER := ["CALCULATOR", "HOBBYIST", "HOME_PC", "GAMING", "MOBILE_COMPUTING"]
## Facteur de demande par mois (janvier → décembre).
const CONSUMER_FACTORS := [0.90, 0.95, 1.00, 1.00, 1.00, 0.98, 0.95, 0.92, 1.08, 1.00, 1.10, 1.18]
const PRO_FACTORS := [0.97, 1.00, 1.02, 1.00, 1.00, 1.02, 0.98, 0.88, 1.03, 1.00, 1.00, 1.10]

const PERIODS := {
	1:{"id":"APRES_FETES", "title":"Après les fêtes", "text":"Les ventes grand public baissent ce mois-ci (−10 %), puis repartent."},
	8:{"id":"VACANCES", "title":"Vacances d'été", "text":"Grand public −8 %, clients pros −12 % : tout le monde est en vacances."},
	9:{"id":"RENTREE", "title":"La rentrée", "text":"Familles et écoles s'équipent : ventes grand public +8 %."},
	11:{"id":"AVANT_FETES", "title":"Avant les fêtes", "text":"Les achats de Noël commencent : grand public +10 %. Décembre sera encore plus fort (+18 %) : vérifiez votre capacité !"},
	12:{"id":"FETES", "title":"Fêtes de fin d'année", "text":"Grand public +18 %, et les pros dépensent leurs budgets de fin d'année (+10 %)."}
}

## Fête de fin d'année de l'équipe : coût par personne et moral gagné.
const PARTY := {
	"BIG":{"label":"Une vraie fête !", "per_person":300, "morale":8.0},
	"SMALL":{"label":"Un pot sympa.", "per_person":60, "morale":3.0},
	"SKIP":{"label":"Pas cette année.", "per_person":0, "morale":-2.0}
}

static func demand_factor(segment: String, month: int) -> float:
	var index := clampi(month, 1, 12) - 1
	return float((CONSUMER_FACTORS if segment in CONSUMER else PRO_FACTORS)[index])

static func period(month: int) -> Dictionary:
	return PERIODS.get(month, {})

## Fin du mois M : Nora annonce la période qui commence le mois suivant.
static func process_month() -> void:
	if not CompanyManager.created:
		return
	var next_month := TimeManager.month % 12 + 1
	var next := period(next_month)
	if next.is_empty():
		return
	CompanyManager.add_alert("Nora : %s. %s" % [str(next.title), str(next.text)])

static func party_pending() -> bool:
	return CompanyManager.created and TimeManager.month == 12 and not PersonnelManager.staff.is_empty() \
		and int(ExecutiveManager.workplace.get("party_year", 0)) != TimeManager.year

static func party_cost(choice: String) -> int:
	var data: Dictionary = PARTY.get(choice, PARTY.SKIP)
	return int(data.per_person) * (PersonnelManager.staff.size() + 1)

static func hold_party(choice: String) -> Dictionary:
	if not party_pending() or not PARTY.has(choice):
		return {"ok":false, "message":""}
	var cost := party_cost(choice)
	if cost > 0 and not Economy.can_afford(cost, "Fête de fin d'année"):
		return {"ok":false, "message":"Trésorerie insuffisante pour cette fête."}
	if cost > 0:
		Economy.add_expense(cost, "Fête de fin d'année")
	var data: Dictionary = PARTY[choice]
	for emp in PersonnelManager.staff:
		PersonnelManager.change_employee_morale(str(emp.get("id", "")), float(data.morale))
	ExecutiveManager.workplace["party_year"] = TimeManager.year
	var message: String = {"BIG":"Quelle soirée ! L'équipe rentre motivée (moral +8).",
		"SMALL":"Un bon moment ensemble (moral +3).",
		"SKIP":"Pas de fête cette année. L'équipe est un peu déçue (moral −2)."}[choice]
	CompanyManager.add_alert("Fête de fin d'année : " + str(message))
	return {"ok":true, "message":str(message)}
