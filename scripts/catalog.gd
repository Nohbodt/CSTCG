class_name CardCatalog
extends RefCounted

const ROLES = ["ENTRY", "AWPER", "IGL", "SUPPORT", "LURKER"]
const RARITIES = ["COMMON", "RARE", "EPIC", "LEGENDARY"]
const COLORS = [Color("a2adc6"), Color("53aeff"), Color("a66bff"), Color("eee4ff")]
const QUICK_SELL = [8, 20, 55, 150]
const CARD_ORIGINS = ["starter", "contender", "elite", "trade", "legacy"]
const ORIGIN_LABELS = {"starter": "Foundation / starter", "contender": "Contender", "elite": "Elite Circuit", "trade": "Trade / pack not recorded", "legacy": "Archive / pack not recorded"}

static func origin_label(origin: String) -> String:
	return ORIGIN_LABELS.get(origin, "Origin not recorded")
const MAPS = ["DE / DUST II"]
const MAP_ROLES = ["SUPPORT"]
const LEGACY_MAPS = ["DE / OVERPASS", "DE / MIRAGE", "DE / ANCIENT"]
const TACTICS = ["BALANCED", "FAST EXECUTE", "MAP CONTROL"]
const PACKS = {
	"contender": {"name": "CONTENDER", "subtitle": "A new name. A new possibility.", "price": 200,
		"color": Color("53aeff"), "flair": 0, "base_weights": [65, 28, 6, 1], "last_weights": [0, 80, 18, 2],
		"guarantee": "1 RARE OR BETTER", "short": "The foundation of your next five."},
	"elite": {"name": "ELITE CIRCUIT", "subtitle": "For the moments that define a club.", "price": 600,
		"color": Color("a66bff"), "flair": 2, "base_weights": [30, 50, 17, 3], "last_weights": [0, 0, 90, 10],
		"guarantee": "1 EPIC OR BETTER", "short": "Bigger stages. Exceptional talent."}
}

# Real public player identities, spanning different eras. Roles and numbers are
# alpha gameplay tuning, not live statistics, real-world rankings or contracts.
# The collection label is not a player's real organization.
const PLAYERS = [
	["yekindar", "YEKINDAR", "Mareks Gaļinskis", "ENTRY", 0, "FOUNDATION", "LV", 66, 58, 61],
	["syrson", "syrsoN", "Florian Rische", "AWPER", 0, "FOUNDATION", "DE", 69, 57, 59],
	["gla1ve", "gla1ve", "Lukas Rossander", "IGL", 0, "FOUNDATION", "DK", 57, 70, 63],
	["rush", "RUSH", "William Wierzba", "SUPPORT", 0, "FOUNDATION", "US", 59, 65, 69],
	["jks", "jks", "Justin Savage", "LURKER", 0, "FOUNDATION", "AU", 64, 64, 62],
	["rain", "rain", "Håvard Nygaard", "ENTRY", 0, "PROSPECTS", "NO", 70, 60, 60],
	["sh1ro", "sh1ro", "Dmitriy Sokolov", "AWPER", 0, "PROSPECTS", "RU", 71, 62, 60],
	["alex", "ALEX", "Alex McMeekin", "IGL", 0, "PROSPECTS", "GB", 61, 72, 65],
	["interz", "interz", "Timofey Yakushin", "SUPPORT", 0, "PROSPECTS", "RU", 61, 66, 71],
	["f1ku", "F1KU", "Maciej Miklas", "LURKER", 0, "PROSPECTS", "PL", 67, 68, 62],
	["xantares", "XANTARES", "İsmail Dörtkardeş", "ENTRY", 1, "CHALLENGERS", "TR", 82, 69, 70],
	["broky", "broky", "Helvijs Saukants", "AWPER", 1, "CHALLENGERS", "LV", 84, 70, 67],
	["siuhy", "siuhy", "Kamil Szkaradek", "IGL", 1, "CHALLENGERS", "PL", 68, 86, 72],
	["perfecto", "Perfecto", "Ilya Zalutskiy", "SUPPORT", 1, "CHALLENGERS", "RU", 71, 76, 83],
	["ropz", "ropz", "Robin Kool", "LURKER", 1, "CHALLENGERS", "EE", 77, 82, 70],
	["elige", "EliGE", "Jonathan Jablonowski", "ENTRY", 1, "WORLD CIRCUIT", "US", 85, 70, 72],
	["m0nesy", "m0NESY", "Ilya Osipov", "AWPER", 1, "WORLD CIRCUIT", "RU", 86, 73, 69],
	["karrigan", "karrigan", "Finn Andersen", "IGL", 1, "WORLD CIRCUIT", "DK", 72, 85, 74],
	["xyp9x", "Xyp9x", "Andreas Højsleth", "SUPPORT", 1, "WORLD CIRCUIT", "DK", 72, 78, 84],
	["nertz", "NertZ", "Guy Iluz", "LURKER", 1, "WORLD CIRCUIT", "IL", 81, 81, 73],
	["donk", "donk", "Danil Kryshkovets", "ENTRY", 2, "ELITE SERIES", "RU", 93, 77, 78],
	["zywoo", "ZywOo", "Mathieu Herbaut", "AWPER", 2, "ELITE SERIES", "FR", 95, 78, 76],
	["aleksib", "Aleksib", "Aleksi Virolainen", "IGL", 2, "ELITE SERIES", "FI", 78, 94, 82],
	["magisk", "Magisk", "Emil Reif", "SUPPORT", 2, "ELITE SERIES", "DK", 79, 85, 93],
	["spinx", "Spinx", "Lotan Giladi", "LURKER", 2, "ELITE SERIES", "IL", 88, 91, 80],
	["niko", "NiKo", "Nikola Kovač", "ENTRY", 3, "ICONS", "BA", 99, 87, 89],
	["s1mple", "s1mple", "Oleksandr Kostyliev", "AWPER", 3, "ICONS", "UA", 99, 90, 87],
	["fallen", "FalleN", "Gabriel Toledo", "IGL", 3, "ICONS", "BR", 87, 99, 91],
	["twistzz", "Twistzz", "Russel Van Dulken", "SUPPORT", 3, "ICONS", "CA", 88, 92, 99],
	["get_right", "GeT_RiGhT", "Christopher Alesund", "LURKER", 3, "ICONS", "SE", 94, 98, 88]
]

const LEGACY_IDS = {
	"spark": "yekindar", "scope": "syrson", "relay": "gla1ve", "patch": "rush", "drift": "jks",
	"flint": "rain", "glass": "sh1ro", "tempo": "alex", "moss": "interz", "rune": "f1ku",
	"raze": "xantares", "sight": "broky", "atlas": "siuhy", "echo": "perfecto", "veil": "ropz",
	"fuse": "elige", "zero": "m0nesy", "vector": "karrigan", "haven": "xyp9x", "haze": "nertz",
	"nova": "donk", "prism": "zywoo", "axiom": "aleksib", "pulse": "magisk", "ghost": "spinx",
	"blaze": "niko", "oracle": "s1mple", "crown": "fallen", "saint": "twistzz", "onyx": "get_right"
}

static func cards() -> Array:
	var result: Array = []
	for p in PLAYERS:
		result.append({"id": p[0], "handle": p[1], "name": p[2], "role": p[3], "rarity": p[4],
			"club": p[5], "country": p[6], "aim": p[7], "sense": p[8], "utility": p[9],
			"overall": roundi((p[7] + p[8] + p[9]) / 3.0), "portrait": "res://assets/players/" + p[0] + ".png"})
	return result

static func canonical_id(id: String) -> String:
	return LEGACY_IDS.get(id, id)

static func map_label(result: Dictionary) -> String:
	return str(result.get("map_name", "DE / DUST II"))

static func card(id: String) -> Dictionary:
	id = canonical_id(id)
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
