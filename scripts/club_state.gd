extends Node

signal changed

const C = preload("res://scripts/catalog.gd")
const Sim = preload("res://scripts/match_simulator.gd")
const STARTERS = ["spark", "scope", "relay", "patch", "drift"]
const OPPONENTS = [
	{"name": "STATIC FIVE", "rating": 69.0, "tactic": 1, "tag": "ST5"},
	{"name": "RED SHIFT", "rating": 72.0, "tactic": 2, "tag": "RDS"},
	{"name": "AFTERHOURS", "rating": 75.0, "tactic": 0, "tag": "AFH"},
	{"name": "MONOLITH", "rating": 78.0, "tactic": 2, "tag": "MNL"}
]

var data: Dictionary = {}
var rng = RandomNumberGenerator.new()
var save_enabled = true
var save_path = "user://club_v1.json"
var last_error = ""

func _ready() -> void:
	rng.randomize()
	if "--ephemeral" in OS.get_cmdline_user_args():
		save_enabled = false
	if not save_enabled or not load_club():
		new_club()
		if last_error.is_empty():
			save_club()

func new_club() -> void:
	data = {"version": 1, "credits": 800, "matches": 0, "wins": 0, "xp": 0,
		"cards": {}, "squad": STARTERS.duplicate(), "packs": {"contender": 2, "elite": 0},
		"pending_pack": {}, "history": [], "used_trades": [], "map": 0, "tactic": 0}
	for id in STARTERS:
		data.cards[id] = 1
	data.cards.spark = 2

func _valid_save(candidate: Dictionary) -> bool:
	for key in ["version", "credits", "matches", "wins", "xp", "map", "tactic"]:
		if not candidate.has(key) or not (candidate[key] is int or candidate[key] is float):
			return false
		if candidate[key] < 0 or float(candidate[key]) != floorf(float(candidate[key])):
			return false
	if candidate.version != 1 or candidate.credits < 0 or candidate.matches < 0 or candidate.wins < 0 or candidate.wins > candidate.matches:
		return false
	if candidate.map < 0 or candidate.map >= C.MAPS.size() or candidate.tactic < 0 or candidate.tactic >= C.TACTICS.size():
		return false
	for key in ["cards", "packs", "pending_pack"]:
		if not candidate.get(key) is Dictionary:
			return false
	for key in ["squad", "history", "used_trades"]:
		if not candidate.get(key) is Array:
			return false
	if candidate.history.size() > 12:
		return false
	for trade_key in candidate.used_trades:
		if not trade_key is String:
			return false
	for result in candidate.history:
		if not _valid_result(result):
			return false
	var squad = candidate.squad
	if squad.size() != 5:
		return false
	var unique: Array = []
	for i in range(5):
		var id = squad[i]
		if not id is String or C.card(id).is_empty() or id in unique:
			return false
		if C.card(id).role != C.ROLES[i]:
			return false
		unique.append(id)
	for id in candidate.cards:
		if C.card(str(id)).is_empty() or not (candidate.cards[id] is int or candidate.cards[id] is float) or candidate.cards[id] < 0:
			return false
		if float(candidate.cards[id]) != floorf(float(candidate.cards[id])):
			return false
	for id in squad:
		if candidate.cards.get(id, 0) < 1:
			return false
	for id in C.PACKS:
		if not (candidate.packs.get(id) is int or candidate.packs.get(id) is float) or candidate.packs[id] < 0:
			return false
		if float(candidate.packs[id]) != floorf(float(candidate.packs[id])):
			return false
	var pending = candidate.pending_pack
	if not pending.is_empty():
		if not C.PACKS.has(pending.get("pack_id", "")) or not pending.get("cards") is Array or not pending.get("new_flags") is Array:
			return false
		if pending.cards.size() != 5 or pending.new_flags.size() != 5 or not (pending.get("revealed") is int or pending.get("revealed") is float):
			return false
		if pending.revealed < 0 or pending.revealed > 5:
			return false
		if float(pending.revealed) != floorf(float(pending.revealed)):
			return false
		for flag in pending.new_flags:
			if not flag is bool:
				return false
		for id in pending.cards:
			if not id is String or C.card(id).is_empty() or candidate.cards.get(id, 0) < 1:
				return false
	return true

func _valid_result(result) -> bool:
	if not result is Dictionary:
		return false
	for key in ["score", "rounds"]:
		if not result.get(key) is Array:
			return false
	if result.score.size() != 2 or result.rounds.size() < 13 or result.rounds.size() > 61:
		return false
	for score in result.score:
		if not (score is int or score is float) or score < 0:
			return false
	if result.score[0] + result.score[1] != result.rounds.size():
		return false
	for key in ["won", "sudden_death"]:
		if not result.get(key) is bool:
			return false
	for key in ["reward", "xp", "map", "tactic", "rating"]:
		if not (result.get(key) is int or result.get(key) is float):
			return false
	if result.map < 0 or result.map >= 3 or result.tactic < 0 or result.tactic >= 3:
		return false
	if not result.get("opponent") is Dictionary or not result.opponent.get("name") is String:
		return false
	if not result.get("earned_pack") is String or not result.get("kills") is Dictionary or not result.get("mvp") is String:
		return false
	if C.card(result.mvp).is_empty() or not (result.kills.get(result.mvp) is int or result.kills.get(result.mvp) is float):
		return false
	for round_data in result.rounds:
		if not round_data is Dictionary:
			return false
		for key in ["score", "cash"]:
			if not round_data.get(key) is Array or round_data[key].size() != 2:
				return false
			for amount in round_data[key]:
				if not (amount is int or amount is float) or amount < 0:
					return false
		for key in ["number", "winner", "chance"]:
			if not (round_data.get(key) is int or round_data.get(key) is float):
				return false
		if (round_data.winner != 0 and round_data.winner != 1) or round_data.number < 1 or round_data.number > 61:
			return false
		if not round_data.get("detail") is String or not round_data.get("ct") is bool or not round_data.get("pistol") is bool:
			return false
	return true

func load_club() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var json = JSON.new()
	var error = json.parse(FileAccess.get_file_as_string(save_path))
	var parsed = _normalize_numbers(json.data)
	if error != OK or not parsed is Dictionary or not _valid_save(parsed):
		last_error = "The local save could not be read. It was preserved; this session starts fresh without saving."
		save_enabled = false
		return false
	data = parsed
	return true

func _normalize_numbers(value):
	# Godot JSON decodes every number as float. Restore integral counters so
	# reloaded inventories compare and behave exactly like a new club.
	if value is float and value == floorf(value):
		return int(value)
	if value is Dictionary:
		var normalized: Dictionary = {}
		for key in value:
			normalized[key] = _normalize_numbers(value[key])
		return normalized
	if value is Array:
		var normalized: Array = []
		for item in value:
			normalized.append(_normalize_numbers(item))
		return normalized
	return value

func save_club() -> bool:
	if not save_enabled:
		return true
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Could not write the local save. Your action was not applied."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK or DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK:
		last_error = "Could not commit the local save. Your action was not applied."
		return false
	return true

func _commit(previous: Dictionary) -> bool:
	if not save_club():
		data = previous
		return false
	changed.emit()
	return true

func copies(id: String) -> int:
	return int(data.cards.get(id, 0))

func unique_cards() -> int:
	var count = 0
	for n in data.cards.values():
		if n > 0:
			count += 1
	return count

func total_cards() -> int:
	var total = 0
	for n in data.cards.values():
		total += int(n)
	return total

func total_packs() -> int:
	return int(data.packs.contender + data.packs.elite)

func club_level() -> int:
	return 1 + int(data.xp / 250)

func opponent() -> Dictionary:
	return OPPONENTS[int(data.matches) % OPPONENTS.size()].duplicate()

func team_rating() -> int:
	return roundi(Sim.rating(data.squad, int(data.map), int(data.tactic)))

func purchase_pack(pack_id: String) -> bool:
	if not C.PACKS.has(pack_id) or not data.pending_pack.is_empty():
		return false
	var price = C.PACKS[pack_id].price
	if data.credits < price:
		return false
	var previous = data.duplicate(true)
	data.credits -= price
	data.packs[pack_id] += 1
	return _commit(previous)

func open_pack(pack_id: String) -> bool:
	if not C.PACKS.has(pack_id) or data.packs[pack_id] <= 0 or not data.pending_pack.is_empty():
		return false
	var previous = data.duplicate(true)
	var pack = C.PACKS[pack_id]
	var pulled: Array = []
	var new_flags: Array = []
	for slot in range(5):
		var id = C.roll_card(pack.last_weights if slot == 4 else pack.base_weights, rng)
		new_flags.append(copies(id) == 0)
		pulled.append(id)
		data.cards[id] = copies(id) + 1
	data.packs[pack_id] -= 1
	# Cards and the pending reveal are saved together BEFORE the presentation.
	data.pending_pack = {"pack_id": pack_id, "cards": pulled, "new_flags": new_flags, "revealed": 0}
	return _commit(previous)

func reveal_cards(all_cards: bool = false) -> bool:
	if data.pending_pack.is_empty() or data.pending_pack.revealed >= 5:
		return false
	var previous = data.duplicate(true)
	data.pending_pack.revealed = 5 if all_cards else int(data.pending_pack.revealed) + 1
	return _commit(previous)

func finish_pack() -> bool:
	if data.pending_pack.is_empty() or data.pending_pack.revealed < 5:
		return false
	var previous = data.duplicate(true)
	data.pending_pack = {}
	return _commit(previous)

func equip(id: String) -> bool:
	var c = C.card(id)
	if c.is_empty() or copies(id) < 1 or id in data.squad or not data.pending_pack.is_empty():
		return false
	var previous = data.duplicate(true)
	data.squad[C.ROLES.find(c.role)] = id
	return _commit(previous)

func can_release(id: String) -> bool:
	return copies(id) > (1 if id in data.squad else 0)

func quick_sell(id: String) -> bool:
	if not can_release(id) or not data.pending_pack.is_empty():
		return false
	var previous = data.duplicate(true)
	data.cards[id] -= 1
	data.credits += C.QUICK_SELL[C.card(id).rarity]
	return _commit(previous)

func offers() -> Array:
	var epoch = int(data.matches / 4)
	var choices = [["spark", "flint"], ["scope", "glass"], ["atlas", "echo"], ["nova", "prism"]]
	var result: Array = []
	for i in range(choices.size()):
		var choice = choices[i].duplicate()
		if epoch % 2 == 1:
			choice.reverse()
		var key = "%d:%d" % [epoch, i]
		result.append({"key": key, "give": choice[0], "receive": choice[1], "used": key in data.used_trades,
			"manager": ["MIRA / STATIC", "ELIAS / NORTHLINE", "NOOR / AFTERHOURS", "KAI / MONOLITH"][i]})
	return result

func trade(key: String) -> bool:
	if not data.pending_pack.is_empty():
		return false
	for offer in offers():
		if offer.key == key and not offer.used and can_release(offer.give):
			var previous = data.duplicate(true)
			data.cards[offer.give] -= 1
			data.cards[offer.receive] = copies(offer.receive) + 1
			data.used_trades.append(key)
			return _commit(previous)
	return false

func set_strategy(map_index: int, tactic: int) -> bool:
	if map_index < 0 or map_index >= C.MAPS.size() or tactic < 0 or tactic >= C.TACTICS.size():
		return false
	var previous = data.duplicate(true)
	data.map = map_index
	data.tactic = tactic
	return _commit(previous)

func play_match() -> Dictionary:
	if not data.pending_pack.is_empty():
		return {}
	var previous = data.duplicate(true)
	var result = Sim.simulate(data.squad, int(data.map), int(data.tactic), opponent(), rng)
	data.matches += 1
	data.wins += 1 if result.won else 0
	var reward = 160 if result.won else 85
	var xp = 100 if result.won else 60
	data.credits += reward
	data.xp += xp
	var earned_pack = ""
	if int(data.matches) % 4 == 0:
		data.packs.contender += 1
		earned_pack = "contender"
		data.used_trades = []
	if int(data.matches) % 12 == 0:
		data.packs.elite += 1
		earned_pack = "both"
	result["reward"] = reward
	result["xp"] = xp
	result["earned_pack"] = earned_pack
	data.history.push_front(result)
	if data.history.size() > 12:
		data.history.resize(12)
	if not _commit(previous):
		return {}
	return result
