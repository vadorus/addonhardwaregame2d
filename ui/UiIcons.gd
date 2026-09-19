extends RefCounted
class_name UiIcons

# Glyphes monochromes volontairement simples pour rester stables sur PC et Android.
const DOMAINS := {
	"HQ":"⌂",
	"COMPANY":"◆",
	"TEAM":"●",
	"LAB":"⚗",
	"CPU":"▣",
	"PRODUCT":"▣",
	"PRODUCTION":"⚙",
	"MARKET":"↗",
	"PRESS":"▤",
	"SUPPORT":"◇",
	"FINANCE":"€",
	"RISK":"▲",
	"TIME":"◷",
	"DISCOVERY":"✦",
	"EVOLUTION":"◇",
	"SETTINGS":"⚙"
}

const STATES := {
	"SUCCESS":"✓",
	"WARNING":"!",
	"CRITICAL":"▲",
	"LOCKED":"×",
	"ACTIVE":"●",
	"PENDING":"○",
	"DONE":"✓",
	"RECOMMENDED":"★"
}

static func domain(key: String) -> String:
	return str(DOMAINS.get(key, "•"))

static func state(key: String) -> String:
	return str(STATES.get(key, "•"))

static func with_domain(key: String, text: String) -> String:
	return "%s %s" % [domain(key), text]

static func with_state(key: String, text: String) -> String:
	return "%s %s" % [state(key), text]
