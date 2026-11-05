extends SceneTree

const State = preload("res://scripts/club_state.gd")
const C = preload("res://scripts/catalog.gd")
const Sim = preload("res://scripts/match_simulator.gd")

var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func fresh():
	var game = State.new()
	game.save_enabled = false
	game.new_club()
	game.rng.seed = 1467
	return game

func _run() -> void:
	_catalog()
	_packs()
	_lineup_and_trades()
	_card_provenance()
	_simulation()
	_progression()
	_persistence()
	_migration_and_pending_match()
	print("CSTCG_TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _catalog() -> void:
	check(C.cards().size() == 30, "Series 01 contains 30 players")
	var ids: Array = []
	for c in C.cards():
		check(c.id not in ids, "unique card identity: " + c.id)
		ids.append(c.id)
		check(c.role in C.ROLES and c.rarity in range(4), "valid role and rarity")
	for rarity in range(4):
		for role in C.ROLES:
			check(not C.cards().filter(func(c): return c.rarity == rarity and c.role == role).is_empty(), "each rarity supports every role")
	for pack in C.PACKS.values():
		check(pack.base_weights.reduce(func(a, b): return a + b, 0) == 100, "base odds sum to 100")
		check(pack.last_weights.reduce(func(a, b): return a + b, 0) == 100, "guaranteed odds sum to 100")
		var expected_release = 0.0
		for i in range(4):
			expected_release += (4 * pack.base_weights[i] + pack.last_weights[i]) * C.QUICK_SELL[i] / 100.0
		check(expected_release < pack.price, "releasing whole packs is not positive-expected-value credit farming")

func _packs() -> void:
	var game = fresh()
	check(game.total_cards() == 6 and game.data.squad.size() == 5, "starter roster and spare card")
	check(game.data.credits == 800 and game.total_packs() == 2, "starter credits and packs")
	var previous = game.data.duplicate(true)
	check(not game.purchase_pack("unknown") and game.data == previous, "invalid pack leaves state unchanged")
	game.data.credits = 0
	previous = game.data.duplicate(true)
	check(not game.purchase_pack("elite") and game.data == previous, "insufficient credits do not create a pack")
	game.data.credits = 800
	check(game.purchase_pack("contender") and game.data.credits == 600 and game.data.packs.contender == 3, "purchase debits exact pack price")
	var before = game.data.cards.duplicate()
	var total = game.total_cards()
	check(game.open_pack("contender"), "owned pack opens")
	check(game.total_cards() == total + 5 and game.data.packs.contender == 2, "open consumes exactly one pack and adds five cards")
	check(game.data.pending_pack.cards.size() == 5, "five reveal slots")
	check(C.card(game.data.pending_pack.cards[4]).rarity >= 1, "Contender guaranteed slot is Rare+")
	for i in range(5):
		var id = game.data.pending_pack.cards[i]
		check(game.data.pending_pack.new_flags[i] == (before.get(id, 0) == 0), "NEW status handles within-pack duplicates")
		before[id] = before.get(id, 0) + 1
	previous = game.data.duplicate(true)
	check(not game.open_pack("contender") and game.data == previous, "cannot open another pack during pending reveal")
	check(not game.purchase_pack("contender"), "cannot purchase during pending reveal")
	check(game.play_match().is_empty(), "cannot launch a match during pending reveal")
	check(not game.quick_sell("yekindar"), "cannot release pending cards")
	check(not game.finish_pack(), "cannot discard an incomplete reveal")
	check(game.reveal_cards() and game.data.pending_pack.revealed == 1, "single reveal advances exactly one slot")
	check(game.reveal_cards(true) and game.data.pending_pack.revealed == 5, "skip reveals the rest")
	check(not game.reveal_cards(), "reveals cannot exceed five")
	check(game.finish_pack() and game.data.pending_pack.is_empty(), "finish clears pending reveal")
	for pack_id in ["contender", "elite"]:
		game.data.packs[pack_id] = 160
		for _i in range(160):
			check(game.open_pack(pack_id), "seeded pack open")
			var minimum = 1 if pack_id == "contender" else 2
			check(C.card(game.data.pending_pack.cards[4]).rarity >= minimum, "guarantee holds across seeded pack samples")
			game.reveal_cards(true)
			game.finish_pack()
	game.free()

func _lineup_and_trades() -> void:
	var game = fresh()
	check(not game.quick_sell("syrson"), "last active card cannot be released")
	check(game.quick_sell("yekindar") and game.copies("yekindar") == 1 and game.data.credits == 808, "spare active card can be released at correct price")
	check(not game.quick_sell("yekindar"), "last remaining active copy is protected")
	check(not game.equip("donk"), "unowned player cannot be equipped")
	game._grant_cards("rain", "trade", 1)
	check(game.equip("rain") and game.data.squad[0] == "rain", "equipping replaces matching role")
	check(game.copies("yekindar") == 1 and game.copies("rain") == 1, "substitution preserves collection")
	check(not game.equip("rain"), "cannot insert same card twice")
	check(game.equip("yekindar"), "original player can be restored")
	check(not game.trade(game.offers()[0].key), "cannot trade last active copy")
	game._grant_cards("yekindar", "legacy", 1)
	var key = game.offers()[0].key
	var count = game.total_cards()
	check(game.trade(key), "valid AI trade executes")
	check(game.copies("yekindar") == 1 and game.copies("rain") == 2 and game.total_cards() == count, "one-for-one atomic card transfer")
	check(not game.trade(key), "completed offer cannot execute twice")
	game.data.matches = 4
	check(game.offers()[0].key != key and not game.offers()[0].used, "trade epoch refreshes after four matches")
	check(not game.set_strategy(-1, 0) and not game.set_strategy(0, 3), "invalid strategy rejected")
	game.free()

func _card_provenance() -> void:
	var game = fresh()
	check(game.data.version == 3 and game.copies_from("yekindar", "starter") == 2, "new club records starter-copy provenance")
	check(game._valid_save(game.data), "new origin ledger validates")
	game._grant_cards("niko", "contender", 1)
	game._grant_cards("niko", "elite", 1)
	check(game.copies("niko") == 2 and game.origins_for("niko").size() == 2, "one player can have two real pack-back variants")
	check(game.equip("niko", "elite"), "a specific pack copy can be equipped")
	var rating = game.team_rating()
	check(not game.can_release("niko", "elite") and game.can_release("niko", "contender"), "reserve protects the exact active origin rather than another copy")
	check(game.equip("niko", "contender") and game.team_rating() == rating, "changing back variant cannot change player strength")
	check(not game.quick_sell("niko", "contender"), "cannot release the active origin's last copy")
	var before = game.data.duplicate(true)
	game.save_enabled = true
	game.save_path = "user://missing-provenance-directory/club.json"
	check(not game.quick_sell("niko", "elite") and game.data == before, "failed save rolls back quantities and origin ledger together")
	game.save_enabled = false
	check(game.quick_sell("niko", "elite") and game.copies_from("niko", "contender") == 1 and game.copies_from("niko", "elite") == 0, "release consumes only the selected spare origin")
	check(game.trade(game.offers()[0].key) and game.copies_from("rain", "trade") == 1, "AI trade without source provenance remains explicitly unrecorded")
	game.open_pack("contender")
	var pending = game.data.pending_pack.duplicate(true)
	for id in pending.cards:
		check(game.copies_from(id, "contender") >= pending.cards.count(id), "every pending copy retains its proven opening pack")
	check(game._valid_save(game.data), "ledger stays consistent across collection transactions and pending duplicates")
	var malformed = game.data.duplicate(true)
	malformed.card_origins.niko.contender += 1
	check(not game._valid_save(malformed), "origin totals must equal inventory quantities")
	malformed = game.data.duplicate(true)
	malformed.squad_origins[0] = "elite"
	check(not game._valid_save(malformed), "lineup cannot reserve a nonexistent origin")
	malformed = game.data.duplicate(true)
	malformed.card_origins.niko = {"invented-pack": 1}
	check(not game._valid_save(malformed), "unknown pack origins are rejected")
	# Older schemas never tracked the pack of completed openings. Keep them
	# unknown; recover only the provable cards in the unfinished opening.
	var old = game.data.duplicate(true)
	old.version = 2
	old.erase("card_origins")
	old.erase("squad_origins")
	var original = JSON.stringify(old)
	game.save_path = "user://test-fixtures/provenance-migration.json"
	DirAccess.make_dir_recursive_absolute("user://test-fixtures")
	var backup = game.save_path + ".before-card-backs.bak"
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	var file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(original)
	file.close()
	game.save_enabled = true
	check(game.load_club() and game.data.version == 3, "schema 2 migrates to per-pack provenance")
	check(FileAccess.get_file_as_string(backup) == original, "card-back migration backs up exact original bytes")
	check(game.data.cards == old.cards and game.data.pending_pack == pending, "migration preserves inventory and every pending result")
	check(game.copies_from("niko", "legacy") >= 1 and game.squad_origin("niko") == "legacy", "migration does not invent an old card's pack")
	for id in pending.cards:
		check(game.copies_from(id, "contender") == pending.cards.count(id), "migration recovers exact pending-pack sources")
	var migrated = game.data.duplicate(true)
	check(game.load_club() and game.data == migrated, "origin ledger and active copies survive JSON roundtrip")
	game.reveal_cards(true)
	game.finish_pack()
	check(game.begin_spatial_match(), "migration fixture can start a played match")
	var old_match = game.data.duplicate(true)
	old_match.version = 2
	old_match.erase("card_origins")
	old_match.erase("squad_origins")
	for group in ["own_cards", "enemy_cards"]:
		for profile in old_match.active_match.snapshot[group]:
			profile.portrait = str(profile.portrait).replace(".png", ".jpg")
	var frozen_match = old_match.active_match.duplicate(true)
	file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old_match))
	file.close()
	DirAccess.remove_absolute(backup)
	check(game.load_club() and game.data.active_match == frozen_match, "schema-2 played fixture and frozen portrait paths survive provenance migration unchanged")
	DirAccess.remove_absolute(game.save_path)
	DirAccess.remove_absolute(backup)
	game.free()

func _simulation() -> void:
	var game = fresh()
	var rng_a = RandomNumberGenerator.new()
	var rng_b = RandomNumberGenerator.new()
	rng_a.seed = 42
	rng_b.seed = 42
	var result = Sim.simulate(game.data.squad, 0, 0, game.opponent(), rng_a)
	check(result == Sim.simulate(game.data.squad, 0, 0, game.opponent(), rng_b), "same seed and input reproduce every round")
	var overt = 0
	var low_wins = 0
	var high_wins = 0
	var high = ["niko", "s1mple", "fallen", "twistzz", "get_right"]
	for seed_value in range(180):
		rng_a.seed = seed_value
		result = Sim.simulate(game.data.squad, 0, seed_value % 3, game.opponent(), rng_a)
		var winner_score = maxi(result.score[0], result.score[1])
		var loser_score = mini(result.score[0], result.score[1])
		check(result.score[0] + result.score[1] == result.rounds.size(), "each round produces exactly one point")
		check(result.rounds.size() <= 61 and result.rounds.size() >= 13, "match terminates within documented round limit")
		if result.rounds.size() <= 24:
			check(winner_score == 13 and loser_score <= 11, "valid MR12 regulation score")
		else:
			overt += 1
			check(winner_score >= 16 and (winner_score - 16) % 3 == 0 and winner_score - loser_score >= 2, "valid MR3 overtime finish")
		check(result.rounds[0].pistol and (result.rounds.size() < 13 or result.rounds[12].pistol), "pistol round at each regulation half")
		for round_data in result.rounds:
			check(round_data.chance >= 0.15 and round_data.chance <= 0.85 and round_data.cash.min() >= 0 and round_data.cash.max() <= 16000, "bounded probabilities and equipment budgets")
		low_wins += 1 if result.won else 0
		rng_b.seed = seed_value
		high_wins += 1 if Sim.simulate(high, 0, seed_value % 3, game.opponent(), rng_b).won else 0
	check(overt > 0, "sample actually exercises overtime")
	check(high_wins > low_wins + 35, "better skill lineup materially improves win rate")
	print("Simulation sample: starter %d/180, elite %d/180; %d overtime matches" % [low_wins, high_wins, overt])
	game.free()

func _progression() -> void:
	var game = fresh()
	var balance = int(game.data.credits)
	var xp = 0
	for i in range(12):
		var result = game.play_match()
		check(not result.is_empty(), "match result generated")
		balance += 80 if result.won else 43
		xp += 50 if result.won else 30
		check(game.data.credits == balance and game.data.xp == xp, "exact match rewards")
		check(game.data.matches == i + 1, "one match advancement per result")
	check(game.data.packs.contender == 5 and game.data.packs.elite == 1, "milestone packs at 4/8/12 and elite at 12")
	check(game.data.history.size() == 12, "history retains last twelve results")
	game.play_match()
	check(game.data.history.size() == 12 and game.data.matches == 13, "history retention does not block progression")
	game.free()

func _persistence() -> void:
	var game = fresh()
	var directory = "user://test-fixtures"
	DirAccess.make_dir_recursive_absolute(directory)
	game.save_path = directory + "/roundtrip.json"
	game.save_enabled = true
	check(game.save_club(), "fresh save persists")
	check(game.open_pack("contender") and game.reveal_cards(), "pending reveal persists")
	var reloaded = fresh()
	reloaded.save_path = game.save_path
	check(reloaded.load_club(), "saved state loads")
	check(reloaded.data == game.data, "save roundtrip preserves exact cards, wallet, and reveal position")
	check(not reloaded.open_pack("elite"), "reload cannot bypass pending pack")
	var original = FileAccess.get_file_as_string(game.save_path)
	var f = FileAccess.open(game.save_path, FileAccess.WRITE)
	f.store_string("{broken json")
	f.close()
	check(not reloaded.load_club() and not reloaded.save_enabled, "corrupt save is detected and writes disabled")
	check(FileAccess.get_file_as_string(game.save_path) == "{broken json", "corrupt save remains intact")
	f = FileAccess.open(game.save_path, FileAccess.WRITE)
	f.store_string(original)
	f.close()
	check(game._valid_save(JSON.parse_string(original)), "valid JSON schema accepted")
	var malformed = game.data.duplicate(true)
	malformed.squad = ["yekindar", "yekindar", "gla1ve", "rush", "jks"]
	check(not game._valid_save(malformed), "duplicate role save rejected")
	game.reveal_cards(true)
	game.finish_pack()
	game.play_match()
	check(game._valid_save(game.data), "fresh completed-match state is valid")
	check(reloaded.load_club() and reloaded.data.history.size() == 1, "completed match report survives reload")
	if not reloaded.data.history.is_empty():
		check(reloaded.data.history[0].score == game.data.history[0].score and reloaded.data.credits == game.data.credits, "reloaded score and rewards match committed result")
	malformed = game.data.duplicate(true)
	malformed.history = [{"incomplete": true}]
	check(not game._valid_save(malformed), "malformed report is rejected before UI presentation")
	malformed = game.data.duplicate(true)
	malformed.cards.yekindar = 1.5
	check(not game._valid_save(malformed), "fractional ownership is rejected")
	var before = game.data.duplicate(true)
	game.save_path = directory + "/missing-directory/no-save.json"
	check(not game.purchase_pack("contender") and game.data == before, "failed disk write rolls back complete transaction")
	DirAccess.remove_absolute(directory + "/roundtrip.json")
	game.free()
	reloaded.free()

func _migration_and_pending_match() -> void:
	var game = fresh()
	game.skip_match()
	game.open_pack("contender")
	game.reveal_cards()
	var expected = game.data.duplicate(true)
	var old = game.data.duplicate(true)
	var reverse: Dictionary = {}
	for id in C.LEGACY_IDS:
		reverse[C.LEGACY_IDS[id]] = id
	old.version = 1
	old.erase("card_origins")
	old.erase("squad_origins")
	old.erase("active_match")
	old.map = 1
	old.cards = {}
	for id in expected.cards:
		old.cards[reverse[id]] = expected.cards[id]
	old.squad = expected.squad.map(func(id): return reverse[id])
	old.pending_pack.cards = expected.pending_pack.cards.map(func(id): return reverse[id])
	for report in old.history:
		report.mvp = reverse[report.mvp]
		var kills: Dictionary = {}
		for id in report.kills:
			kills[reverse[id]] = report.kills[id]
		report.kills = kills
		report.map = 1
		report.erase("map_name")
	game.save_path = "user://test-fixtures/migration.json"
	var backup = game.save_path + ".before-alpha2.bak"
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	var original = JSON.stringify(old)
	var file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(original)
	file.close()
	game.save_enabled = true
	check(game.load_club(), "v1 club migrates on load")
	check(FileAccess.get_file_as_string(backup) == original, "pre-migration backup preserves exact original bytes")
	check(game.data.cards == expected.cards and game.data.squad == expected.squad, "all card quantities and lineup identities migrate one-for-one")
	check(game.data.pending_pack == expected.pending_pack, "partly revealed pack preserves cards, flags and reveal position")
	check(game.data.credits == expected.credits and game.data.xp == expected.xp and game.data.matches == expected.matches, "migration preserves progression")
	check(game.data.history[0].mvp == expected.history[0].mvp and game.data.history[0].map_name == C.LEGACY_MAPS[1], "history retains its original map and canonical MVP")
	check(game.data.version == 3 and game.data.map == 0 and game.load_club(), "migrated schema survives subsequent load")
	game.reveal_cards(true)
	game.finish_pack()
	check(game.begin_spatial_match(), "played fixture saved before scene transition")
	var snapshot = game.data.active_match.snapshot.duplicate(true)
	check(game.load_club() and game.data.active_match.snapshot == snapshot, "interrupted fixture reloads exact seed, opponent, lineup and stats")
	var before = game.data.duplicate(true)
	check(not game.begin_spatial_match() and game.skip_match().is_empty(), "pending fixture prevents another result")
	check(not game.open_pack("contender") and not game.purchase_pack("contender"), "pending fixture locks pack transactions")
	check(not game.equip("rain") and not game.quick_sell("yekindar") and not game.trade(game.offers()[0].key), "pending fixture locks lineup and collection transactions")
	check(not game.set_strategy(0, 1) and game.data == before, "pending fixture cannot change saved strategy or other state")
	check(not game.checkpoint_match("wrong-id", {}), "checkpoint for another fixture rejected")
	var malformed = before.duplicate(true)
	malformed.active_match.checkpoint = {"score": [0, 0], "rounds": [], "carry": [], "totals": [], "loss_streak": []}
	check(not game._valid_save(malformed), "truncated checkpoint rejected before match view")
	malformed = before.duplicate(true)
	malformed.active_match.snapshot.opponent.erase("tactic")
	check(not game._valid_save(malformed), "incomplete opponent snapshot rejected")
	DirAccess.remove_absolute(game.save_path)
	DirAccess.remove_absolute(backup)
	game.free()
