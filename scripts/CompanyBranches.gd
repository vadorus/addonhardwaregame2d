extends RefCounted
## Planche 7 « La carte de l'entreprise » (08/10) : ce que l'entreprise peut devenir.
## Le tronc, c'est le CPU ; les branches poussent avec les époques. Seuls le CPU et le logiciel sont jouables
## dans la démo (AGENTS.md : pas de gameplay hors CPU). Les autres branches sont des vitrines :
## « Version complète » (futures extensions payantes : défense, aérospatial) ou « Extension à venir »
## (silhouettes). Aucune n'ouvre de mécanique : leur bouton reste désactivé.

const PLAYABLE := "PLAYABLE"
const FULL := "FULL"
const COMING := "COMING"

## Position sur la carte en proportion (x, y) : le tronc en bas au centre, les branches au-dessus.
const NODES := [
	{"key":"cpu", "glyph":"◼", "label":"CPU", "kind":PLAYABLE, "pos":Vector2(0.50, 0.86), "since":1971,
		"text":"Le cœur de l'entreprise : concevoir, fabriquer et vendre vos processeurs.",
		"points":["Calculatrices, puis ordinateurs, puis serveurs", "Des architectures qui durent plusieurs générations", "Finition de la puce, presse, jour J"],
		"teaser":"« Tout commence ici, sur l'établi du garage. » — Camille", "cta":"Ouvrir le labo", "context":"LAB"},
	{"key":"soft", "glyph":"❮❯", "label":"Logiciel", "kind":PLAYABLE, "pos":Vector2(0.24, 0.58), "since":1971,
		"text":"Votre équipe écrit des outils et des firmwares entre deux CPU.",
		"points":["Fait respirer l'équipe entre deux CPU", "Un firmware peut corriger une puce déjà vendue", "Des contrats pour faire rentrer de l'argent"],
		"teaser":"« Si on passait l'équipe sur un outil pendant six mois ? » — Nora", "cta":"Ouvrir le coin logiciel", "context":"SOFTWARE"},
	{"key":"def", "glyph":"✪", "label":"Défense", "kind":FULL, "pos":Vector2(0.70, 0.40), "since":1980,
		"text":"Des puces durcies pour les programmes militaires : accréditation, appels d'offres, secret.",
		"points":["Contrats longs et très bien payés", "Fiabilité exigée au plus haut", "Une accréditation longue à obtenir"],
		"teaser":"« 1980 — une lettre officielle arrive au garage. »", "cta":"Version complète", "context":""},
	{"key":"aero", "glyph":"▲", "label":"Aérospatial", "kind":FULL, "pos":Vector2(0.30, 0.33), "since":1990,
		"text":"Ordinateurs de bord, satellites, avionique : là où une panne n'est pas permise.",
		"points":["Agences spatiales et avionneurs", "Volumes faibles, prix très élevés", "L'équipe Fiabilité devient reine"],
		"teaser":"« Une maquette de fusée apparaît sur l'étagère… »", "cta":"Version complète", "context":""},
	{"key":"mobile", "glyph":"▯", "label":"Mobile", "kind":COMING, "pos":Vector2(0.82, 0.24), "since":0,
		"text":"Téléphones et appareils nomades : l'autonomie avant tout.", "points":["Puces tout-en-un", "La consommation avant tout", "De nouveaux rivaux"],
		"teaser":"Silhouette seulement : on en reparlera.", "cta":"Bientôt", "context":""},
	{"key":"console", "glyph":"◉", "label":"Consoles", "kind":COMING, "pos":Vector2(0.54, 0.16), "since":0,
		"text":"Le processeur d'une console de salon : un seul client, des millions de puces.", "points":["Un contrat géant", "Puissance graphique", "Délais imposés"],
		"teaser":"Silhouette seulement : on en reparlera.", "cta":"Bientôt", "context":""},
	{"key":"board", "glyph":"▦", "label":"Cartes mères", "kind":COMING, "pos":Vector2(0.13, 0.27), "since":0,
		"text":"Les cartes pour votre propre socket, ou celles de partenaires.", "points":["Le pont avec vos CPU", "Alimentations, stockage ensuite", "Fidélité à la plateforme"],
		"teaser":"Silhouette seulement : on en reparlera.", "cta":"Bientôt", "context":""},
	{"key":"server", "glyph":"☰", "label":"Serveurs", "kind":COMING, "pos":Vector2(0.84, 0.62), "since":0,
		"text":"Les salles machines des grandes entreprises, puis les datacenters.", "points":["Fiabilité 24 h sur 24", "De grosses équipes", "Des marges élevées"],
		"teaser":"Silhouette seulement : on en reparlera.", "cta":"Bientôt", "context":""},
]

static func node(key: String) -> Dictionary:
	for node_value in NODES:
		if str((node_value as Dictionary).key) == key:
			return node_value
	return {}

static func tag(entry: Dictionary) -> String:
	match str(entry.kind):
		PLAYABLE:
			return "JOUABLE · LE TRONC" if str(entry.key) == "cpu" else "JOUABLE"
		FULL:
			return "VERSION COMPLÈTE"
	return "EXTENSION À VENIR"

## Le statut affiché, selon l'année en cours.
static func status(entry: Dictionary, year: int) -> String:
	match str(entry.kind):
		PLAYABLE:
			return "Jouable · depuis %d" % maxi(int(entry.since), CompanyManager.founded_year if CompanyManager.founded_year > 0 else int(entry.since))
		FULL:
			if year < int(entry.since):
				return "S'ouvrira en %d · version complète" % int(entry.since)
			return "Ouverte depuis %d · version complète" % int(entry.since)
	return "Extension à venir"

## Seules les branches jouables mènent quelque part.
static func can_open(entry: Dictionary) -> bool:
	return str(entry.kind) == PLAYABLE and str(entry.context) != ""
