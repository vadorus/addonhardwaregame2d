extends RefCounted
## V0.10 / I3 (Claude, 01/10) — la boîte de décisions ne déborde plus.
## Le joueur voit au plus 3 décisions (les plus importantes). Une décision qui attend trop longtemps
## hors de ces 3 (ou très longtemps tout court) est tranchée par Nora avec le choix prudent et gratuit
## (reporter, décliner, surveiller), et elle le dit. Les décisions qui engagent vraiment le joueur
## (prototype, validation, lancement, choix de fabrication) ne sont jamais tranchées à sa place.

const MAX_VISIBLE := 3
## Mois d'attente hors des 3 visibles avant que Nora tranche.
const OVERFLOW_PATIENCE := 2
## Mois d'attente maximum, même parmi les 3 visibles.
const MAX_PATIENCE := 6

## Choix prudent par catégorie : [libellé annoncé].
const DEFAULT_LABELS := {
	"LOCAUX":"déménagement reporté de 3 mois",
	"RH":"un entretien avec la personne",
	"ARBITRAGE":"décision actuelle conservée",
	"SAV":"dossier placé sous surveillance",
	"MARCHÉ":"retour marché noté",
	"GAMME":"gamme conservée telle quelle",
	"RIVAL":"pas d'offensive pour l'instant",
	"RACHAT":"offre de rachat déclinée",
	"FILIALE":"projet de la filiale refusé",
	"STRATEGIE":"accréditation reportée",
	"SALON":"rumeur démentie",
	"CONTRAT":"appel d'offres laissé de côté",
	"CLIENT":"offre déclinée poliment",
	"SOUS-TRAITANCE":"contrat d'études décliné",
	"FINANCEMENT":"prêt non souscrit",
	"ÉQUIPE":"correction non lancée",
	"MENACE":"aucune réponse financée"
}

static func can_settle(decision: Dictionary) -> bool:
	var id := str(decision.get("id", ""))
	if id.begins_with("PROJECT:") or id.begins_with("LAUNCH:"):
		return false
	return DEFAULT_LABELS.has(str(decision.get("category", "")))

## Applique le choix prudent. true si la décision a disparu de la boîte.
static func settle(decision: Dictionary) -> bool:
	var id := str(decision.get("id", ""))
	var sid := id.substr(id.find(":") + 1) if id.find(":") >= 0 else id
	match str(decision.get("category", "")):
		"LOCAUX":
			return ExecutiveManager.defer_workplace_upgrade(3)
		"RH":
			return ExecutiveManager.resolve_hr_issue(sid, "DISCUSS")
		"ARBITRAGE":
			return DivisionManager.resolve_escalation(sid, false)
		"SAV":
			return AfterSalesManager.monitor_case(sid)
		"MARCHÉ":
			var product: Dictionary = ProductManager.get_product(sid)
			if product.is_empty():
				return false
			product["market_feedback_seen"] = true
			return true
		"GAMME":
			ProductManager.snooze_range_advice(6)
			return true
		"RIVAL":
			MarketManager.snooze_attack_advice(12)
			return true
		"RACHAT":
			return MarketManager.RIVAL_LIFE.decline_offer(sid)
		"FILIALE":
			return CompanyManager.SUBSIDIARIES.answer_request(sid, false)
		"STRATEGIE":
			return MarketManager.STRATEGIC.snooze(sid)
		"SALON":
			return MarketManager.LATE_GAME.resolve_expo("DENY")
		"CONTRAT":
			var tender: Dictionary = MarketManager.get_tender(sid)
			if tender.is_empty():
				return false
			tender["ceo_ignored"] = true
			return true
		"CLIENT":
			return MarketManager.decline_contract(sid)
		"SOUS-TRAITANCE":
			return GarageBusiness.decline_study(sid)
		"FINANCEMENT":
			GarageBusiness.decline_loan()
			return true
		"ÉQUIPE":
			var parts := id.split(":")
			if parts.size() < 3:
				return false
			(load("res://scripts/TeamLessons.gd") as Script).call("decline_advice", parts[1], parts[2])
			return true
		"MENACE":
			return MarketManager.resolve_market_threat(sid, false)
	return false
