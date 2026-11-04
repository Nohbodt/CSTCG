class_name CardCatalog
extends RefCounted

const ROLES = ["ENTRY", "AWPER", "IGL", "SUPPORT", "LURKER"]
const RARITIES = ["COMMON", "RARE", "EPIC", "LEGENDARY"]
const COLORS = [Color("8eaaa6"), Color("69adf3"), Color("b5a0ff"), Color("f2c66c")]
const QUICK_SELL = [8, 20, 55, 150]
const MAPS = ["DE / OVERPASS", "DE / MIRAGE", "DE / ANCIENT"]
const MAP_ROLES = ["SUPPORT", "AWPER", "LURKER"]
const TACTICS = ["BALANCED", "FAST EXECUTE", "MAP CONTROL"]
const PACKS = {
	"contender": {"name": "CONTENDER", "subtitle": "A new name. A new possibility.", "price": 200,
		"color": Color("f0804b"), "base_weights": [65, 28, 6, 1], "last_weights": [0, 80, 18, 2],
		"guarantee": "1 RARE OR BETTER", "short": "The foundation of your next five."},
	"elite": {"name": "ELITE CIRCUIT", "subtitle": "For the moments that define a club.", "price": 600,
		"color": Color("b5a0ff"), "base_weights": [30, 50, 17, 3], "last_weights": [0, 0, 90, 10],
		"guarantee": "1 EPIC OR BETTER", "short": "Bigger stages. Exceptional talent."}
}

# Fictional players and clubs. Rarity is fixed per card; odds select a rarity,
# then uniformly select a player in that rarity. No paid currency.
const PLAYERS = [
	["spark", "SPARK", "Milo Voss", "ENTRY", 0, "NORTHLINE", "DK", 66, 58, 61],
	["scope", "SCOPE", "Leon Beck", "AWPER", 0, "NORTHLINE", "DE", 69, 57, 59],
	["relay", "RELAY", "Alex Chen", "IGL", 0, "NORTHLINE", "CA", 57, 70, 63],
	["patch", "PATCH", "Sam Costa", "SUPPORT", 0, "NORTHLINE", "BR", 59, 65, 69],
	["drift", "DRIFT", "Noah Reed", "LURKER", 0, "NORTHLINE", "UK", 64, 64, 62],
	["flint", "FLINT", "Theo Park", "ENTRY", 0, "STATIC", "KR", 70, 60, 60],
	["glass", "GLASS", "Eli Ward", "AWPER", 0, "STATIC", "US", 71, 62, 60],
	["tempo", "TEMPO", "Ivo Silva", "IGL", 0, "STATIC", "PT", 61, 72, 65],
	["moss", "MOSS", "Owen Lake", "SUPPORT", 0, "STATIC", "AU", 61, 66, 71],
	["rune", "RUNE", "Nils Berg", "LURKER", 0, "STATIC", "SE", 67, 68, 62],
	["raze", "RAZE", "Luca Vale", "ENTRY", 1, "AFTERHOURS", "IT", 82, 69, 70],
	["sight", "SIGHT", "Emil Frost", "AWPER", 1, "AFTERHOURS", "DK", 84, 70, 67],
	["atlas", "ATLAS", "Robin Nyx", "IGL", 1, "AFTERHOURS", "FI", 68, 86, 72],
	["echo", "ECHO", "Yuri Sol", "SUPPORT", 1, "AFTERHOURS", "BR", 71, 76, 83],
	["veil", "VEIL", "Jules Arno", "LURKER", 1, "AFTERHOURS", "FR", 77, 82, 70],
	["fuse", "FUSE", "Kim Sol", "ENTRY", 1, "RED SHIFT", "KR", 85, 70, 72],
	["zero", "ZERO", "Max Adler", "AWPER", 1, "RED SHIFT", "DE", 86, 73, 69],
	["vector", "VECTOR", "Ari West", "IGL", 1, "RED SHIFT", "US", 72, 85, 74],
	["haven", "HAVEN", "Ben Ellis", "SUPPORT", 1, "RED SHIFT", "UK", 72, 78, 84],
	["haze", "HAZE", "Rene Holm", "LURKER", 1, "RED SHIFT", "NO", 81, 81, 73],
	["nova", "NOVA", "Enzo Moreau", "ENTRY", 2, "MONOLITH", "FR", 93, 77, 78],
	["prism", "PRISM", "Tomas Varga", "AWPER", 2, "MONOLITH", "CZ", 95, 78, 76],
	["axiom", "AXIOM", "Sasha Volkov", "IGL", 2, "MONOLITH", "UA", 78, 94, 82],
	["pulse", "PULSE", "Dani Lima", "SUPPORT", 2, "MONOLITH", "BR", 79, 85, 93],
	["ghost", "GHOST", "Kai Jensen", "LURKER", 2, "MONOLITH", "DK", 88, 91, 80],
	["blaze", "BLAZE", "Rafi Noor", "ENTRY", 3, "SOLSTICE", "TR", 99, 87, 89],
	["oracle", "ORACLE", "Jae Moon", "AWPER", 3, "SOLSTICE", "KR", 99, 90, 87],
	["crown", "CROWN", "Lars Winter", "IGL", 3, "SOLSTICE", "SE", 87, 99, 91],
	["saint", "SAINT", "Andre Cruz", "SUPPORT", 3, "SOLSTICE", "PT", 88, 92, 99],
	["onyx", "ONYX", "Leo Sato", "LURKER", 3, "SOLSTICE", "JP", 94, 98, 88]
]

static func cards() -> Array:
	var result: Array = []
	for p in PLAYERS:
		result.append({"id": p[0], "handle": p[1], "name": p[2], "role": p[3], "rarity": p[4],
			"club": p[5], "country": p[6], "aim": p[7], "sense": p[8], "utility": p[9],
			"overall": roundi((p[7] + p[8] + p[9]) / 3.0)})
	return result

static func card(id: String) -> Dictionary:
	for c in cards():
		if c.id == id:
			return c
	return {}

static func roll_card(weights: Array, rng: RandomNumberGenerator) -> String:
	var roll = rng.randi_range(1, 100)
	var rarity = 0
	var cumulative = 0
	for i in range(4):
		cumulative += weights[i]
		if roll <= cumulative:
			rarity = i
			break
	var pool = cards().filter(func(c): return c.rarity == rarity)
	return pool[rng.randi_range(0, pool.size() - 1)].id
