extends RefCounted
## Politique de confidentialité affichée DANS le jeu (exigence Google Play, 08/10).
## Le jeu ne demande aucune permission Android (pas d'accès réseau) : il ne peut rien envoyer.
## `ONLINE_URL` : l'adresse déclarée dans la Play Console (Contenu de l'appli > Règles de confidentialité).
## Vide tant qu'Alexandre ne l'a pas recopiée ici : le bouton « version en ligne » reste alors caché.

const ONLINE_URL := ""
const TITLE := "Confidentialité"
const UPDATED := "8 octobre 2026"

static func text() -> String:
	return "\n\n".join([
		"Tech Empire est un jeu qui fonctionne entièrement sur votre appareil.",
		"Aucune donnée personnelle n'est collectée. Le jeu ne demande aucun compte, n'affiche aucune publicité et ne contient aucun outil de mesure d'audience ni de suivi.",
		"Vos parties sont enregistrées uniquement sur votre appareil, dans le dossier privé du jeu. Elles ne sont jamais envoyées ailleurs. Désinstaller le jeu les efface.",
		"Le jeu ne demande aucune autorisation Android : il n'accède ni à Internet, ni à vos contacts, ni à votre position, ni à vos photos.",
		"Si des achats intégrés sont proposés plus tard, ils passeront par Google Play, selon les règles de confidentialité de Google. Cette page sera alors mise à jour.",
		"Pour toute question, utilisez l'adresse de contact indiquée sur la fiche du jeu dans Google Play.",
		"Dernière mise à jour : %s." % UPDATED,
	])

static func has_online_version() -> bool:
	return ONLINE_URL.begins_with("https://")
