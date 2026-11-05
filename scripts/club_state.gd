extends Node

signal changed

const C = preload("res://scripts/catalog.gd")
const Sim = preload("res://scripts/match_simulator.gd")
const STARTERS = ["yekindar", "syrson", "gla1ve", "rush", "jks"]
const FULL_REWARDS = {"win_credits": 160, "loss_credits": 85, "win_xp": 100, "loss_xp": 60}
const SKIP_FACTOR = 0.5
const OPPONENTS = [
	{"name": "PROSPECT FIVE", "tactic": 1, "tag": "P5", "lineup": ["rain", "sh1ro", "alex", "interz", "f1ku"]},
	{"name": "CHALLENGER MIX", "tactic": 2, "tag": "CMX", "lineup": ["yekindar", "broky", "siuhy", "rush", "ropz"]},
	{"name": "WORLD FIVE", "tactic": 0, "tag": "W5", "lineup": ["xantares", "m0nesy", "karrigan", "perfecto", "nertz"]},
	{"name": "ELITE ALL-STARS", "tactic": 2, "tag": "EAS", "lineup": ["donk", "zywoo", "aleksib", "magisk", "spinx"]}
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
	data = {"version": 3, "credits": 800, "matches": 0, "wins": 0, "xp": 0,
		"cards": {}, "card_origins": {}, "squad_origins": ["starter", "starter", "starter", "starter", "starter"], "squad": STARTERS.duplicate(), "packs": {"contender": 2, "elite": 0},
		"pending_pack": {}, "active_match": {}, "history": [], "used_trades": [], "map": 0, "tactic": 0}
	for id in STARTERS:
		_grant_cards(id, "starter", 1)
	_grant_cards("yekindar", "starter", 1)

func _valid_save(candidate: Dictionary) -> bool:
	for key in ["version", "credits", "matches", "wins", "xp", "map", "tactic"]:
		if not candidate.has(key) or not (candidate[key] is int or candidate[key] is float):
			return false
		if candidate[key] < 0 or float(candidate[key]) != floorf(float(candidate[key])):
			return false
	if candidate.version != 3 or candidate.credits < 0 or candidate.matches < 0 or candidate.wins < 0 or candidate.wins > candidate.matches:
		return false
	if candidate.map < 0 or candidate.map >= C.MAPS.size() or candidate.tactic < 0 or candidate.tactic >= C.TACTICS.size():
		return false
	for key in ["cards", "card_origins", "packs", "pending_pack", "active_match"]:
		if not candidate.get(key) is Dictionary:
			return false
	for key in ["squad", "squad_origins", "history", "used_trades"]:
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
	if not candidate.active_match.is_empty():
		if not candidate.pending_pack.is_empty() or not _valid_active_match(candidate.active_match):
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
	if not _valid_origins(candidate):
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
			if candidate.card_origins.get(id, {}).get(pending.pack_id, 0) < pending.cards.count(id):
				return false
	return true

func _valid_origins(candidate: Dictionary) -> bool:
	if candidate.squad_origins.size() != 5:
		return false
	for id in candidate.card_origins:
		if not candidate.cards.has(id) or not candidate.card_origins[id] is Dictionary:
			return false
	for id in candidate.cards:
		var bucket = candidate.card_origins.get(id, {})
		if not bucket is Dictionary:
			return false
		var total = 0
		for origin in bucket:
			var count = bucket[origin]
			if origin not in C.CARD_ORIGINS or not (count is int or count is float) or count < 1 or float(count) != floorf(float(count)):
				return false
			total += int(count)
		if total != int(candidate.cards[id]):
			return false
	for i in range(5):
		var origin = candidate.squad_origins[i]
		if origin not in C.CARD_ORIGINS or candidate.card_origins.get(candidate.squad[i], {}).get(origin, 0) < 1:
			return false
	return true

func _valid_active_match(active: Dictionary) -> bool:
	if not active.get("snapshot") is Dictionary or not active.get("checkpoint") is Dictionary:
		return false
	var snapshot = active.snapshot
	if not snapshot.get("id") is String or snapshot.id.is_empty() or not snapshot.get("seed") is int:
		return false
	if snapshot.get("mode") != "played" or snapshot.get("map", -1) != 0 or snapshot.get("tactic", -1) not in [0, 1, 2]:
		return false
	if not snapshot.get("engine_version") is String or not snapshot.get("map_name") is String:
		return false
	if not snapshot.get("opponent") is Dictionary or not snapshot.opponent.get("name") is String or not snapshot.opponent.get("tag") is String or snapshot.opponent.get("tactic", -1) not in [0, 1, 2]:
		return false
	for key in ["squad", "own_cards", "enemy_cards"]:
		if not snapshot.get(key) is Array or snapshot[key].size() != 5:
			return false
	for id in snapshot.squad:
		if not id is String or C.card(id).is_empty():
			return false
	for key in ["own_cards", "enemy_cards"]:
		for index in range(5):
			var card = snapshot[key][index]
			if not card is Dictionary or not card.get("id") is String or C.card(card.id).is_empty():
				return false
			for stat in ["aim", "sense", "utility", "overall"]:
				if not (card.get(stat) is int or card.get(stat) is float) or card[stat] < 0 or card[stat] > 150:
					return false
			if not card.get("handle") is String or card.get("role") not in C.ROLES:
				return false
			if not card.get("name") is String:
				return false
			if key == "own_cards" and card.id != snapshot.squad[index]:
				return false
	var checkpoint = active.checkpoint
	if not checkpoint.is_empty():
		if not checkpoint.get("rounds") is Array or checkpoint.rounds.size() > 60:
			return false
		if not checkpoint.get("score") is Array or checkpoint.score.size() != 2:
			return false
		for n in checkpoint.score:
			if not n is int or n < 0:
				return false
		if checkpoint.score[0] + checkpoint.score[1] != checkpoint.rounds.size():
			return false
		for key in ["carry", "totals", "loss_streak"]:
			if not checkpoint.get(key) is Array:
				return false
		if checkpoint.carry.size() != 10 or checkpoint.totals.size() != 10 or checkpoint.loss_streak.size() != 2:
			return false
		for item in checkpoint.carry:
			if not item is Dictionary or not item.get("cash") is int or item.cash < 0 or item.cash > 16000:
				return false
			if item.get("weapon") not in ["pistol", "p250", "smg", "rifle", "awp"] or not item.get("armor") is bool or not item.get("alive") is bool:
				return false
		for item in checkpoint.totals:
			if not item is Dictionary:
				return false
			for key in ["kills", "deaths", "damage", "plants", "defuses", "flashes"]:
				if not item.get(key) is int or item[key] < 0:
					return false
		for count in checkpoint.loss_streak:
			if not count is int or count < 0 or count > 4:
				return false
		if not checkpoint.get("sequence") is int or checkpoint.sequence < 0 or not checkpoint.get("sudden_death") is bool:
			return false
		if not (checkpoint.get("simulated_seconds") is int or checkpoint.get("simulated_seconds") is float) or checkpoint.simulated_seconds < 0:
			return false
		var counted = [0, 0]
		for index in range(checkpoint.rounds.size()):
			var round_data = checkpoint.rounds[index]
			if not round_data is Dictionary or round_data.get("number") != index + 1 or round_data.get("winner", -1) not in [0, 1]:
				return false
			counted[round_data.winner] += 1
			if round_data.get("score") != counted or not round_data.get("events") is Array:
				return false
		if counted != checkpoint.score:
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
	var migrated_from = 0
	if error == OK and parsed is Dictionary and parsed.get("version") == 1:
		parsed = _migrate_v1(parsed)
		migrated_from = 1
	if error == OK and parsed is Dictionary and parsed.get("version") == 2:
		if migrated_from == 0:
			migrated_from = 2
		parsed = _migrate_v2(parsed)
	if error != OK or not parsed is Dictionary or not _valid_save(parsed):
		last_error = "The local save could not be read. It was preserved; this session starts fresh without saving."
		save_enabled = false
		return false
	data = parsed
	if migrated_from > 0 and save_enabled:
		var backup = save_path + (".before-alpha2.bak" if migrated_from == 1 else ".before-card-backs.bak")
		if not FileAccess.file_exists(backup) and DirAccess.copy_absolute(save_path, backup) != OK:
			last_error = "The old club was loaded, but its migration backup could not be saved. This session is unsaved."
			save_enabled = false
		elif not save_club():
			save_enabled = false
	return true

func _migrate_v1(old: Dictionary) -> Dictionary:
	var migrated = old.duplicate(true)
	if not migrated.get("cards") is Dictionary or not migrated.get("squad") is Array:
		return migrated
	var inventory: Dictionary = {}
	for id in migrated.cards:
		var target = C.canonical_id(str(id))
		var amount = migrated.cards[id]
		if not (amount is int or amount is float):
			return old
		inventory[target] = inventory.get(target, 0) + amount
	migrated.cards = inventory
	for i in range(migrated.squad.size()):
		migrated.squad[i] = C.canonical_id(str(migrated.squad[i]))
	if migrated.get("pending_pack") is Dictionary and migrated.pending_pack.get("cards") is Array:
		for i in range(migrated.pending_pack.cards.size()):
			migrated.pending_pack.cards[i] = C.canonical_id(str(migrated.pending_pack.cards[i]))
	if migrated.get("history") is Array:
		for result in migrated.history:
			if not result is Dictionary:
				continue
			result["mvp"] = C.canonical_id(str(result.get("mvp", "")))
			var kills: Dictionary = {}
			if result.get("kills") is Dictionary:
				for id in result.kills:
					kills[C.canonical_id(str(id))] = result.kills[id]
			result["kills"] = kills
			result["mode"] = "legacy"
			var old_map = clampi(int(result.get("map", 0)), 0, 2)
			result["map_name"] = C.LEGACY_MAPS[old_map]
	migrated["active_match"] = {}
	migrated.map = 0
	migrated.version = 2
	return migrated

func _migrate_v2(old: Dictionary) -> Dictionary:
	if not old.get("cards") is Dictionary or not old.get("squad") is Array:
		return old
	var migrated = old.duplicate(true)
	migrated["card_origins"] = {}
	migrated["squad_origins"] = []
	for id in old.cards:
		var count = old.cards[id]
		if not (count is int or count is float) or count < 0 or float(count) != floorf(float(count)):
			return old
		migrated.card_origins[id] = {"legacy": int(count)} if count > 0 else {}
	for id in old.squad:
		migrated.squad_origins.append("legacy")
	# An unfinished pack is the one source old saves can prove exactly.
	var pending = old.get("pending_pack", {})
	if not pending is Dictionary:
		return old
	if not pending.is_empty():
		if not pending.get("cards") is Array or not C.PACKS.has(pending.get("pack_id", "")):
			return old
		for id in pending.cards:
			if not migrated.card_origins.has(id) or migrated.card_origins[id].get("legacy", 0) < 1:
				return old
			migrated.card_origins[id].legacy -= 1
			if migrated.card_origins[id].legacy == 0:
				migrated.card_origins[id].erase("legacy")
			migrated.card_origins[id][pending.pack_id] = migrated.card_origins[id].get(pending.pack_id, 0) + 1
	migrated.version = 3
	return migrated

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
	# Retain full available precision for event coordinates and simulation time.
	file.store_string(JSON.stringify(data, "\t", true, true))
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK or DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK:
		last_error = "Could not commit the local save. Your action was not applied."
		return false
	last_error = ""
	return true

func _commit(previous: Dictionary) -> bool:
	if not save_club():
		data = previous
		return false
	changed.emit()
	return true

func copies(id: String) -> int:
	return int(data.cards.get(C.canonical_id(id), 0))

func copies_from(id: String, origin: String) -> int:
	return int(data.card_origins.get(C.canonical_id(id), {}).get(origin, 0))

func origins_for(id: String) -> Dictionary:
	return data.card_origins.get(C.canonical_id(id), {}).duplicate()

func squad_origin(id: String) -> String:
	var slot = data.squad.find(C.canonical_id(id))
	return str(data.squad_origins[slot]) if slot >= 0 else ""

func preferred_origin(id: String) -> String:
	var active = squad_origin(id)
	if not active.is_empty():
		return active
	for origin in C.CARD_ORIGINS:
		if copies_from(id, origin) > 0:
			return origin
	return ""

func release_origin(id: String, requested: String = "") -> String:
	for origin in ([requested] if not requested.is_empty() else ["legacy", "trade", "starter", "contender", "elite"]):
		if copies_from(id, origin) > (1 if squad_origin(id) == origin else 0):
			return origin
	return ""

func _grant_cards(id: String, origin: String, count: int) -> void:
	id = C.canonical_id(id)
	data.cards[id] = copies(id) + count
	if not data.card_origins.has(id):
		data.card_origins[id] = {}
	data.card_origins[id][origin] = copies_from(id, origin) + count

func _remove_copy(id: String, origin: String) -> void:
	data.cards[id] -= 1
	data.card_origins[id][origin] -= 1
	if data.card_origins[id][origin] == 0:
		data.card_origins[id].erase(origin)

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
	var selected = OPPONENTS[int(data.matches) % OPPONENTS.size()].duplicate(true)
	selected["rating"] = Sim.rating(selected.lineup, 0, selected.tactic)
	return selected

func has_active_match() -> bool:
	return not data.get("active_match", {}).is_empty()

func team_rating() -> int:
	return roundi(Sim.rating(data.squad, int(data.map), int(data.tactic)))

func purchase_pack(pack_id: String) -> bool:
	if not C.PACKS.has(pack_id) or not data.pending_pack.is_empty() or has_active_match():
		return false
	var price = C.PACKS[pack_id].price
	if data.credits < price:
		return false
	var previous = data.duplicate(true)
	data.credits -= price
	data.packs[pack_id] += 1
	return _commit(previous)

func open_pack(pack_id: String) -> bool:
	if not C.PACKS.has(pack_id) or data.packs[pack_id] <= 0 or not data.pending_pack.is_empty() or has_active_match():
		return false
	var previous = data.duplicate(true)
	var pack = C.PACKS[pack_id]
	var pulled: Array = []
	var new_flags: Array = []
	for slot in range(5):
		var id = C.roll_card(pack.last_weights if slot == 4 else pack.base_weights, rng)
		new_flags.append(copies(id) == 0)
		pulled.append(id)
		_grant_cards(id, pack_id, 1)
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

func equip(id: String, origin: String = "") -> bool:
	id = C.canonical_id(id)
	var card = C.card(id)
	if card.is_empty() or copies(id) < 1 or not data.pending_pack.is_empty() or has_active_match():
		return false
	if origin.is_empty():
		if id in data.squad:
			return false
		origin = preferred_origin(id)
	if copies_from(id, origin) < 1:
		return false
	var slot = C.ROLES.find(card.role)
	if data.squad[slot] == id and data.squad_origins[slot] == origin:
		return false
	var previous = data.duplicate(true)
	data.squad[slot] = id
	data.squad_origins[slot] = origin
	return _commit(previous)

func can_release(id: String, origin: String = "") -> bool:
	return not has_active_match() and not release_origin(id, origin).is_empty()

func quick_sell(id: String, origin: String = "") -> bool:
	id = C.canonical_id(id)
	origin = release_origin(id, origin)
	if origin.is_empty() or not can_release(id, origin) or not data.pending_pack.is_empty():
		return false
	var previous = data.duplicate(true)
	_remove_copy(id, origin)
	data.credits += C.QUICK_SELL[C.card(id).rarity]
	return _commit(previous)

func offers() -> Array:
	var epoch = int(data.matches / 4)
	var choices = [["yekindar", "rain"], ["syrson", "sh1ro"], ["siuhy", "perfecto"], ["donk", "zywoo"]]
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
	if not data.pending_pack.is_empty() or has_active_match():
		return false
	for offer in offers():
		if offer.key == key and not offer.used and can_release(offer.give):
			var previous = data.duplicate(true)
			_remove_copy(offer.give, release_origin(offer.give))
			_grant_cards(offer.receive, "trade", 1)
			data.used_trades.append(key)
			return _commit(previous)
	return false

func set_strategy(map_index: int, tactic: int) -> bool:
	if has_active_match() or map_index != 0 or tactic < 0 or tactic >= C.TACTICS.size():
		return false
	var previous = data.duplicate(true)
	data.map = map_index
	data.tactic = tactic
	return _commit(previous)

func play_match() -> Dictionary:
	return skip_match()

func skip_match() -> Dictionary:
	if not data.pending_pack.is_empty() or has_active_match():
		return {}
	var result = Sim.simulate(data.squad, 0, int(data.tactic), opponent(), rng)
	result["match_id"] = _new_match_id()
	return _settle_match(result, "skipped")

func _new_match_id() -> String:
	return "%d-%08x" % [int(Time.get_unix_time_from_system() * 1000), rng.randi()]

func begin_spatial_match() -> bool:
	if has_active_match() or not data.pending_pack.is_empty():
		return false
	var previous = data.duplicate(true)
	var enemy = opponent()
	var own_cards = data.squad.map(func(id): return C.card(id).duplicate(true))
	var enemy_cards = enemy.lineup.map(func(id): return C.card(id).duplicate(true))
	data.active_match = {"snapshot": {"id": _new_match_id(), "seed": rng.randi_range(1, 2000000000),
		"mode": "played", "map": 0, "map_name": C.MAPS[0], "tactic": int(data.tactic),
		"squad": data.squad.duplicate(), "own_cards": own_cards, "enemy_cards": enemy_cards,
		"opponent": enemy, "engine_version": "dust-alpha-2"}, "checkpoint": {}}
	data.active_match = _normalize_numbers(data.active_match)
	return _commit(previous)

func checkpoint_match(match_id: String, checkpoint: Dictionary) -> bool:
	if not has_active_match() or data.active_match.snapshot.id != match_id:
		return false
	var previous = data.duplicate(true)
	data.active_match.checkpoint = _normalize_numbers(checkpoint)
	if not _valid_active_match(data.active_match):
		data = previous
		return false
	return _commit(previous)

func complete_spatial_match(result: Dictionary) -> Dictionary:
	if not has_active_match() or result.get("match_id", "") != data.active_match.snapshot.id:
		return {}
	return _settle_match(result, "played")

func _settle_match(result: Dictionary, mode: String) -> Dictionary:
	for previous_result in data.history:
		if previous_result.get("match_id", "old") == result.get("match_id", "new"):
			return {}
	var previous = data.duplicate(true)
	var factor = SKIP_FACTOR if mode == "skipped" else 1.0
	var reward = roundi((FULL_REWARDS.win_credits if result.won else FULL_REWARDS.loss_credits) * factor)
	var xp = roundi((FULL_REWARDS.win_xp if result.won else FULL_REWARDS.loss_xp) * factor)
	result["reward"] = reward
	result["xp"] = xp
	result["mode"] = mode
	result["map_name"] = C.MAPS[0]
	result["earned_pack"] = ""
	if not _valid_result(result):
		return {}
	data.matches += 1
	data.wins += 1 if result.won else 0
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
	# JSON reload canonicalizes whole-valued floats to integer counters. Apply
	# the same representation before storing/returning a fresh event report.
	result = _normalize_numbers(result)
	data.active_match = {}
	data.history.push_front(result)
	if data.history.size() > 12:
		data.history.resize(12)
	if not _commit(previous):
		return {}
	return result
