extends RefCounted
class_name ArchitectureCatalog
## V0.9 — Architectures CPU : la base de chaque puce (modèle d'Alexandre, 28/09).
## Une architecture fixe les limites (cœurs, cache, fréquence par rapport au procédé) et ses qualités
## sur les trois axes du jeu : vitesse, énergie, fiabilité. Les dates suivent l'histoire réelle.
## Tranche 1 : une architecture devient disponible à sa date historique, ou jusqu'à 3 ans plus tôt
## si l'équipe maîtrise assez l'architecture des circuits. Tranche 2 : ce sont les équipes R&D qui la conçoivent.

const CPU := [
	{"id":"A4", "name":"Architecture 4 bits", "short":"4 bits", "year":1971, "capability":0.0,
	 "max_cores":1, "max_cache_kb":0, "max_freq_factor":1.3,
	 "axes":{"speed":30.0, "energy":45.0, "reliability":55.0},
	 "pitch":"La première puce : calculatrices et petits automatismes."},
	{"id":"A8", "name":"Architecture 8 bits", "short":"8 bits", "year":1974, "capability":20.0,
	 "max_cores":1, "max_cache_kb":0, "max_freq_factor":1.5,
	 "axes":{"speed":42.0, "energy":45.0, "reliability":58.0},
	 "pitch":"Ordinateurs de loisir, terminaux, automatismes plus riches."},
	{"id":"A16", "name":"Architecture 16 bits", "short":"16 bits", "year":1978, "capability":27.0,
	 "max_cores":1, "max_cache_kb":1, "max_freq_factor":1.6,
	 "axes":{"speed":52.0, "energy":46.0, "reliability":60.0},
	 "pitch":"Les premiers ordinateurs personnels."},
	{"id":"A32", "name":"Architecture 32 bits", "short":"32 bits", "year":1985, "capability":36.0,
	 "max_cores":1, "max_cache_kb":8, "max_freq_factor":1.7,
	 "axes":{"speed":61.0, "energy":48.0, "reliability":62.0},
	 "pitch":"PC modernes et stations de travail."},
	{"id":"APIPE", "name":"Pipeline et cache intégré", "short":"Pipeline", "year":1989, "capability":45.0,
	 "max_cores":1, "max_cache_kb":32, "max_freq_factor":1.8,
	 "axes":{"speed":69.0, "energy":50.0, "reliability":63.0},
	 "pitch":"La puce travaille à la chaîne : gros gain de vitesse."},
	{"id":"ASUPER", "name":"Superscalaire", "short":"Superscalaire", "year":1993, "capability":52.0,
	 "max_cores":1, "max_cache_kb":512, "max_freq_factor":1.9,
	 "axes":{"speed":76.0, "energy":52.0, "reliability":64.0},
	 "pitch":"Plusieurs instructions à la fois."},
	{"id":"AOOO", "name":"Exécution dans le désordre", "short":"Désordre", "year":1995, "capability":60.0,
	 "max_cores":1, "max_cache_kb":2048, "max_freq_factor":2.0,
	 "axes":{"speed":82.0, "energy":54.0, "reliability":66.0},
	 "pitch":"La puce réorganise son travail pour ne jamais attendre."},
	{"id":"A64", "name":"Architecture 64 bits", "short":"64 bits", "year":2003, "capability":70.0,
	 "max_cores":2, "max_cache_kb":8192, "max_freq_factor":2.0,
	 "axes":{"speed":86.0, "energy":60.0, "reliability":70.0},
	 "pitch":"Serveurs et beaucoup de mémoire."},
	{"id":"AMC", "name":"Multicœur", "short":"Multicœur", "year":2005, "capability":76.0,
	 "max_cores":64, "max_cache_kb":65536, "max_freq_factor":2.0,
	 "axes":{"speed":92.0, "energy":68.0, "reliability":74.0},
	 "pitch":"Plusieurs processeurs dans une seule puce."}
]

const AXIS_LABELS := {"speed":"Vitesse", "energy":"Énergie", "reliability":"Fiabilité"}

static func all() -> Array:
	return CPU

static func get_by_id(arch_id: String) -> Dictionary:
	for arch in CPU:
		if str(arch.id) == arch_id:
			return arch
	return CPU[0]

static func is_available(arch: Dictionary, year: int, capability: float) -> bool:
	if year >= int(arch.year):
		return true
	return year >= int(arch.year) - 3 and capability >= float(arch.capability)

static func unlock_hint(arch: Dictionary) -> String:
	return "Disponible en %d, ou jusqu'à 3 ans plus tôt avec une architecture des circuits à %.0f." % [int(arch.year), float(arch.capability)]
