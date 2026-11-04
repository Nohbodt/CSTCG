extends SceneTree

const World = preload("res://scripts/spatial/dust_world.gd")
const Live = preload("res://scripts/spatial/spatial_match_sim.gd")
const State = preload("res://scripts/club_state.gd")
var checks = 0
var failures = 0
var shots = 0
var world: DustWorld
var snapshot: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("LIVE FAIL: " + description)

func _run() -> void:
	world = World.new()
	world.navigation_failed.connect(func(reason):
		printerr("LIVE FAIL: " + reason)
		quit(1))
	root.add_child(world)
	await world.navigation_ready
	var game = State.new()
	game.save_enabled = false
	game.new_club()
	game.rng.seed = 77
	check(game.begin_spatial_match(), "fixture starts")
	var active = game.data.active_match.duplicate(true)
	snapshot = active.snapshot
	var sim = Live.new()
	sim.configure(world, snapshot)
	sim.shot_created.connect(func(start, finish, _team, _hit):
		shots += 1
		check(world.has_sight(start, finish), "every emitted shot has a real unobstructed geometry ray"))
	check(sim.spawn_groups.t.size() == 5 and sim.spawn_groups.ct.size() == 5, "ten supported spawns")
	for key in sim.spawn_groups:
		for feet in sim.spawn_groups[key]:
			check(world.body_clear(feet) and not world.floor_at(feet).is_empty(), "spawns are supported and have capsule clearance")
	sim.start_next_round()
	var resume_checked = false
	for tick in range(90000):
		sim.step()
		if tick % 40 == 0:
			for actor in sim.actors:
				check(world.body_clear(actor.position), "live actor remains outside map collision")
				check(actor.cash >= 0 and actor.cash <= 16000 and actor.ammo >= 0, "equipment and ammo cannot become negative")
		if sim.phase == "round_end":
			check(game.checkpoint_match(active.snapshot.id, sim.checkpoint()), "round checkpoint saved")
			if sim.round_number == 1:
				var resumed = Live.new()
				# JSON roundtrip is the actual representation used after closing a match.
				var serialized = JSON.stringify(sim.checkpoint(), "", true, true)
				resumed.configure(world, snapshot, game._normalize_numbers(JSON.parse_string(serialized)))
				resumed.tracks = sim.tracks.duplicate()
				resumed.start_next_round()
				_advance_to_end(resumed)
				sim.start_next_round()
				_advance_to_end(sim)
				check(sim.rounds[-1] == resumed.rounds[-1], "resume reproduces the same next-round events, not a rerolled winner")
				check(sim.totals == resumed.totals and sim.carry == resumed.carry, "resume preserves damage, kills and equipment economy")
				check(game.checkpoint_match(snapshot.id, sim.checkpoint()), "resumed round commits")
				resume_checked = true
			sim.start_next_round()
		if sim.finished:
			break
	check(sim.finished, "match terminates within a bounded number of ticks")
	check(resume_checked and shots > 100, "fixture exercises actual gunfights and interruption recovery")
	check(sim.route_failures == 0, "agents physically traverse every requested route in the fixture")
	check(sim.totals.reduce(func(n, t): return n + t.kills, 0) == sim.totals.reduce(func(n, t): return n + t.deaths, 0), "each elimination is recorded exactly once")
	check(sim.rounds.any(func(r): return r.events.any(func(e): return e.kind == "plant")), "full fixture reaches and plants on an actual site")
	if sim.finished:
		var raw = sim.result()
		var before_commit = game.data.duplicate(true)
		game.save_enabled = true
		game.save_path = "user://missing-live-fixture-dir/no-save.json"
		check(game.complete_spatial_match(raw).is_empty() and game.data == before_commit, "failed final save preserves active fixture and does not pay out")
		DirAccess.make_dir_recursive_absolute("user://test-fixtures")
		game.save_path = "user://test-fixtures/completed-live.json"
		var result = game.complete_spatial_match(sim.result())
		check(not result.is_empty(), "real match settles through club state")
		check(not game.has_active_match() and game.data.matches == 1, "completed match clears pending fixture")
		check(result.reward == (160 if result.won else 85) and result.xp == (100 if result.won else 60), "played result earns full credits and XP")
		var saved = game.data.duplicate(true)
		check(game.complete_spatial_match(raw).is_empty() and game.data == saved, "repeated completion cannot pay out again")
		check(game._valid_save(game.data), "complete causal report passes save validation")
		var reloaded = State.new()
		reloaded.save_path = game.save_path
		var loaded = reloaded.load_club()
		var diff = _difference(game.data, reloaded.data, "club") if loaded else reloaded.last_error
		if not diff.is_empty():
			printerr("ROUNDTRIP DIFF: ", diff)
		check(loaded and diff.is_empty(), "full causal report, events and rewards survive a disk roundtrip")
		check(game.last_error.is_empty(), "successful retry clears stale save error")
		reloaded.free()
		DirAccess.remove_absolute(game.save_path)
		print("CSTCG_LIVE_FIXTURE: ", sim.score, "; ", sim.rounds.size(), " rounds; ", shots, " clear-ray shots; ", sim.route_failures, " route failures")
	_scenarios(sim.tracks)
	game.free()
	world.queue_free()
	await process_frame
	print("CSTCG_LIVE_TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _advance_to_end(sim: SpatialMatchSim) -> void:
	for tick in range(1800):
		sim.step()
		if sim.phase in ["round_end", "finished"]:
			return
	check(false, "single round time bound")

func _fixture(tracks: Dictionary) -> SpatialMatchSim:
	var sim = Live.new()
	sim.configure(world, snapshot)
	sim.tracks = tracks.duplicate()
	sim.start_next_round()
	sim.phase = "live"
	return sim

func _scenarios(tracks: Dictionary) -> void:
	var sim = _fixture(tracks)
	var attacker = sim.actors[0]
	var defender = sim.actors[5]
	attacker.position = world.supported_feet(world.closest(world.landmark("t_spawn")))
	defender.position = sim.sites.site_a.position
	attacker.visible = [5]
	attacker.target = 5
	attacker.reaction = 0
	var ammo = attacker.ammo
	sim._shoot(attacker)
	check(attacker.ammo == ammo and defender.hp == 100, "a stale sighting cannot fire through a wall")
	defender.position = attacker.position + Vector3.RIGHT
	check(sim._visible(attacker, defender), "local target visible before smoke")
	sim.smokes = [{"position": attacker.position + Vector3.RIGHT * 2, "radius": 3.4, "left": 18.0}]
	defender.position = attacker.position + Vector3.RIGHT * 3
	check(not sim._visible(attacker, defender), "smoke blocks otherwise clear geometry sightlines")
	sim.smokes = []
	var carrier = sim.actors[sim.bomb.carrier]
	carrier.visible = []
	carrier.position = sim.spawn_groups.t[3]
	for tick in range(40):
		sim._objective(carrier)
	check(sim.bomb.status == "carried", "bomb cannot plant outside a site volume")
	carrier.position = sim.sites[sim.target_site].position
	for tick in range(40):
		sim._objective(carrier)
	check(sim.bomb.status == "planted" and sim.totals[carrier.index].plants == 1, "supported site plus uninterrupted plant completes exactly once")
	defender.position = sim.bomb.position
	defender.visible = []
	defender.kit = false
	for tick in range(60):
		sim._objective(defender)
	check(sim.bomb.status == "planted", "six seconds is insufficient to defuse without a kit")
	for tick in range(45):
		sim._objective(defender)
	check(sim.bomb.status == "defused" and sim.totals[defender.index].defuses == 1, "continuous ten-second defuse completes")
	for actor in sim.actors:
		if actor.team != sim.t_team:
			actor.alive = false
	sim._check_round_end()
	check(sim.round_winner == 1 - sim.t_team and sim.round_reason == "defuse", "completed defuse determines the winner even if the last defender dies that tick")
	sim = _fixture(tracks)
	carrier = sim.actors[sim.bomb.carrier]
	var killer = sim.actors[5]
	sim._kill(killer, carrier, false)
	check(sim.bomb.status == "dropped" and sim.bomb.position == carrier.position, "carrier elimination drops the bomb at the actual position")
	var recovering = sim.actors[2]
	recovering.position = sim.bomb.position
	sim._objective(recovering)
	check(sim.bomb.status == "carried" and sim.bomb.carrier == recovering.index, "nearby surviving teammate picks up dropped bomb")
	sim = _fixture(tracks)
	sim.bomb.status = "planted"
	sim.bomb.was_planted = true
	sim.bomb.time_left = 1.0
	for actor in sim.actors:
		if actor.team == sim.t_team:
			actor.alive = false
	sim._check_round_end()
	check(sim.phase == "live", "planted bomb keeps the round alive after all attackers die")
	for tick in range(11):
		sim._check_round_end()
	check(sim.round_winner == sim.t_team and sim.round_reason == "explosion", "bomb detonation wins with no surviving attacker")
	sim = _fixture(tracks)
	sim.round_time = Live.ROUND_SECONDS
	sim._check_round_end()
	check(sim.round_winner == 1 - sim.t_team and sim.round_reason == "time", "unplanted round timeout awards defenders")
	# Seed a legal 12-12 boundary and play causally into MR3 overtime.
	sim = _fixture(tracks)
	sim.rounds.resize(24)
	sim.score = [12, 12]
	sim.start_next_round()
	check(sim.round_number == 25 and sim.t_team == 0 and sim.actors.all(func(a): return a.cash <= 10000), "overtime starts with a fresh equipment economy")
	for tick in range(16000):
		sim.step()
		if sim.phase == "round_end":
			sim.start_next_round()
		if sim.finished:
			break
	check(sim.finished and maxi(sim.score[0], sim.score[1]) >= 16 and absi(sim.score[0] - sim.score[1]) >= 2, "overtime ends with a legal MR3 result")

func _difference(a, b, path: String) -> String:
	# Godot's JSON parser can differ in the final double-precision bit. Permit
	# <1e-9 coordinate/time error; integral counters and all other data stay exact.
	if (a is int or a is float) and (b is int or b is float):
		if a is int and b is int:
			return "" if a == b else "%s: %s -> %s" % [path, str(a), str(b)]
		return "" if absf(float(a) - float(b)) < 0.000000001 else "%s: %s -> %s" % [path, str(a), str(b)]
	if typeof(a) != typeof(b):
		return "%s: %s %s -> %s %s" % [path, type_string(typeof(a)), str(a), type_string(typeof(b)), str(b)]
	if a is Dictionary:
		if a.size() != b.size():
			return path + " changed keys"
		for key in a:
			if not b.has(key):
				return path + "." + key + " missing"
			var diff = _difference(a[key], b[key], path + "." + key)
			if not diff.is_empty():
				return diff
	elif a is Array:
		if a.size() != b.size():
			return path + " changed size"
		for i in range(a.size()):
			var diff = _difference(a[i], b[i], path + "[%d]" % i)
			if not diff.is_empty():
				return diff
	elif a != b:
		return "%s: %s -> %s" % [path, str(a), str(b)]
	return ""
