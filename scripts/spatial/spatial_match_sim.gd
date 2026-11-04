class_name SpatialMatchSim
extends RefCounted

# An automatic alpha match: stateful ten-agent rounds on the supplied geometry.
# Nothing selects the round winner before movement, combat, or the objective.
signal event_created(event: Dictionary)
signal shot_created(from: Vector3, to: Vector3, team: int, hit: bool)
signal round_finished(summary: Dictionary)
signal match_finished(result: Dictionary)

const C = preload("res://scripts/catalog.gd")
const Aggregate = preload("res://scripts/match_simulator.gd")
const DT = 0.1
const ROUND_SECONDS = 100.0
const BOMB_SECONDS = 40.0
const PLANT_SECONDS = 3.2
const WEAPONS = {
	"pistol": {"name": "Pistol", "price": 0, "interval": 0.30, "damage": 28.0, "reward": 300, "range": 30.0},
	"p250": {"name": "P250", "price": 300, "interval": 0.27, "damage": 33.0, "reward": 300, "range": 35.0},
	"smg": {"name": "SMG", "price": 1250, "interval": 0.12, "damage": 24.0, "reward": 600, "range": 24.0},
	"rifle": {"name": "Rifle", "price": 2900, "interval": 0.11, "damage": 35.0, "reward": 300, "range": 55.0},
	"awp": {"name": "AWP", "price": 4750, "interval": 1.25, "damage": 120.0, "reward": 100, "range": 110.0}
}

var world: DustWorld
var snapshot: Dictionary
var rng = RandomNumberGenerator.new()
var actors: Array = []
var rounds: Array = []
var score: Array = [0, 0]
var carry: Array = []
var totals: Array = []
var loss_streak: Array = [0, 0]
var phase = "idle"
var round_number = 0
var round_time = 0.0
var transition_time = 0.0
var t_team = 0
var target_site = "site_a"
var bomb: Dictionary = {}
var smokes: Array = []
var grenades: Array = []
var round_events: Array = []
var sequence = 0
var finished = false
var sudden_death = false
var round_winner = -1
var round_reason = ""
var tracks: Dictionary = {}
var sites: Dictionary = {}
var spawn_groups: Dictionary = {}
var goal_groups: Dictionary = {}
var tick_number = 0
var route_failures = 0
var simulated_seconds = 0.0

func configure(map_world: DustWorld, match_snapshot: Dictionary, checkpoint: Dictionary = {}) -> void:
	world = map_world
	snapshot = match_snapshot.duplicate(true)
	for id in ["site_a", "site_b"]:
		var feet = world.supported_feet(world.closest(world.landmark(id)))
		sites[id] = {"position": feet, "radius": 2.8, "height_tolerance": 0.75}
		goal_groups[id] = world.formation(feet, 5)
	spawn_groups["t"] = world.formation(world.landmark("t_spawn"), 5)
	spawn_groups["ct"] = world.formation(world.landmark("ct_spawn"), 5)
	for i in range(10):
		carry.append({"cash": 800, "weapon": "pistol", "armor": false, "alive": true})
		totals.append({"kills": 0, "deaths": 0, "damage": 0, "plants": 0, "defuses": 0, "flashes": 0})
	if not checkpoint.is_empty():
		rounds = checkpoint.rounds.duplicate(true)
		score = checkpoint.score.duplicate()
		carry = checkpoint.carry.duplicate(true)
		totals = checkpoint.totals.duplicate(true)
		loss_streak = checkpoint.loss_streak.duplicate()
		sequence = int(checkpoint.get("sequence", 0))
		simulated_seconds = float(checkpoint.get("simulated_seconds", 0.0))
		sudden_death = bool(checkpoint.get("sudden_death", false))

func start_next_round() -> void:
	if finished:
		return
	round_number = rounds.size() + 1
	rng.seed = int(snapshot.seed) + round_number * 104729
	round_time = 0
	tick_number = 0
	phase = "buy"
	transition_time = 2.5
	round_events = []
	smokes = []
	grenades = []
	round_winner = -1
	round_reason = ""
	t_team = 0 if round_number <= 12 else 1
	if round_number > 24:
		t_team = 0 if (round_number - 25) % 6 < 3 else 1
	var reset = round_number == 1 or round_number == 13 or (round_number > 24 and (round_number - 25) % 6 == 0)
	if reset:
		loss_streak = [0, 0]
		for item in carry:
			item.cash = 10000 if round_number > 24 else 800
			item.weapon = "pistol"
			item.armor = false
			item.alive = true
	var tactic = int(snapshot.tactic) if t_team == 0 else int(snapshot.opponent.tactic)
	var b_weight = 0.65 if tactic == 1 else 0.4
	target_site = "site_b" if rng.randf() < b_weight else "site_a"
	actors = []
	for i in range(10):
		var team = int(i / 5)
		var slot = i % 5
		var profile = snapshot.own_cards[slot] if team == 0 else snapshot.enemy_cards[slot]
		var is_t = team == t_team
		var spawn = spawn_groups["t" if is_t else "ct"][slot]
		var actor = {"index": i, "team": team, "slot": slot, "profile": profile,
			"position": spawn, "facing": Vector3.FORWARD, "hp": 100.0, "alive": true,
			"cash": int(carry[i].cash), "weapon": carry[i].weapon if carry[i].alive else "pistol",
			"armor": carry[i].armor if carry[i].alive else false, "kit": false,
			"ammo": 30, "reserve": 90, "reload": 0.0, "smoke": 0, "flash": 0,
			"fire_wait": 0.0, "reaction": 0.0, "target": -1, "visible": [], "memory": {},
			"blind": 0.0, "form": rng.randf_range(0.92, 1.08), "intent": "BUYING",
			"track": {}, "travel": 0.0, "track_cursor": 0, "waypoints": [],
			"goal": spawn, "hold_facing": Vector3.ZERO, "plant_time": 0.0,
			"round_kills": 0, "route_failed": false, "last_utility": -100.0,
			"visible_at": -100.0, "heard_until": 0.0,
			"tactic": int(snapshot.tactic) if team == 0 else int(snapshot.opponent.tactic)}
		actor["move_delay"] = (2.0 + slot * 0.4) if actor.tactic == 2 else (slot * 0.25 if actor.tactic == 0 else 0.0)
		_buy(actor, is_t)
		actors.append(actor)
	for i in range(10):
		var actor = actors[i]
		var is_t = actor.team == t_team
		var destination = target_site if is_t else ("site_a" if actor.slot in [0, 1, 2] else "site_b")
		if (not is_t and actor.slot == 2) or (is_t and actor.tactic == 2 and actor.slot == 4):
			actor.waypoints.append(world.supported_feet(world.closest(world.landmark("mid"))))
		var places = goal_groups[destination]
		actor.waypoints.append(places[actor.slot % places.size()])
		actor.hold_facing = (world.landmark("t_spawn") - sites[destination].position).normalized() if not is_t else (world.landmark("ct_spawn") - sites[destination].position).normalized()
		_next_waypoint(actor)
	var carrier = t_team * 5 + 3
	bomb = {"status": "carried", "carrier": carrier, "position": actors[carrier].position,
		"time_left": BOMB_SECONDS, "defuser": -1, "defuse_time": 0.0, "site": target_site,
		"was_planted": false}
	_emit("round_start", -1, "Round %d · %s attack %s" % [round_number, "NORTHLINE" if t_team == 0 else snapshot.opponent.name, "A" if target_site == "site_a" else "B"])

func _buy(actor: Dictionary, is_t: bool) -> void:
	var desired = "pistol"
	if actor.profile.role == "AWPER" and actor.cash >= 5400:
		desired = "awp"
	elif actor.cash >= 3550:
		desired = "rifle"
	elif actor.cash >= 1900:
		desired = "smg"
	elif actor.cash >= 500:
		desired = "p250"
	if WEAPONS[desired].price > WEAPONS[actor.weapon].price:
		actor.cash -= WEAPONS[desired].price
		actor.weapon = desired
	if not actor.armor and actor.cash >= 650:
		actor.cash -= 650
		actor.armor = true
	# Utility is paid for, belongs to the agent, and can only be thrown once.
	if actor.cash >= 200:
		actor.cash -= 200
		actor.flash = 1
	if actor.cash >= 300:
		actor.cash -= 300
		actor.smoke = 1
	if not is_t and actor.cash >= 400:
		actor.cash -= 400
		actor.kit = true
	actor.ammo = 10 if actor.weapon == "awp" else (13 if actor.weapon in ["pistol", "p250"] else 30)
	actor.reserve = actor.ammo * 3

func _track(start: Vector3, goal: Vector3) -> Dictionary:
	var key = str(start) + "|" + str(goal)
	if not tracks.has(key):
		tracks[key] = world.trace_route(start, goal)
	return tracks[key]

func _set_route(actor: Dictionary, goal: Vector3) -> void:
	actor.goal = goal
	actor.track = _track(actor.position, goal)
	actor.travel = 0.0
	actor.track_cursor = 0
	actor.route_failed = not actor.track.ok
	if actor.route_failed:
		route_failures += 1
		actor.intent = "HOLD / ROUTE BLOCKED"
	else:
		actor.intent = "MOVING"

func _next_waypoint(actor: Dictionary) -> void:
	if actor.waypoints.is_empty():
		actor.track = {}
		actor.facing = actor.hold_facing
		actor.intent = "HOLDING"
		return
	var goal = actor.waypoints.pop_front()
	_set_route(actor, goal)
	if actor.route_failed:
		# Try a known connected site seed, never an invented connector or teleport.
		var fallback = sites[target_site].position
		if actor.position.distance_to(fallback) > 1:
			_set_route(actor, fallback)

func step() -> void:
	if finished or phase in ["idle", "round_end", "finished"]:
		return
	simulated_seconds += DT
	if phase == "buy":
		transition_time -= DT
		if transition_time <= 0:
			phase = "live"
		return
	round_time += DT
	tick_number += 1
	_update_utility()
	for actor in actors:
		actor.fire_wait -= DT
		actor.reaction = maxf(0.0, actor.reaction - DT)
		var was_reloading = actor.reload > 0
		actor.reload = maxf(0.0, actor.reload - DT)
		actor.blind = maxf(0.0, actor.blind - DT)
		if was_reloading and actor.reload <= 0 and actor.ammo == 0 and actor.reserve > 0:
			var amount = mini(actor.reserve, 10 if actor.weapon == "awp" else (13 if actor.weapon in ["pistol", "p250"] else 30))
			actor.ammo = amount
			actor.reserve -= amount
	if tick_number % 2 == 0:
		_perceive()
	var order = range(10)
	# Stable seeded shuffle avoids a fixed team-first firing advantage.
	for i in range(order.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var old = order[i]
		order[i] = order[j]
		order[j] = old
	for index in order:
		var actor = actors[index]
		if not actor.alive:
			continue
		if actor.team == t_team and bomb.status == "carried" and bomb.carrier == index:
			bomb.position = actor.position
		if _objective(actor):
			continue
		if not actor.visible.is_empty() and actor.blind <= 0:
			actor.intent = "ENGAGING"
			_try_utility(actor)
			_shoot(actor)
		else:
			_move(actor)
	_check_round_end()

func _move(actor: Dictionary) -> void:
	if round_time < actor.move_delay:
		actor.intent = "SETTING UP"
		return
	if actor.track.is_empty() or not actor.track.get("ok", false):
		return
	var points: PackedVector3Array = actor.track.points
	var cumulative: PackedFloat32Array = actor.track.cumulative
	var speed = 5.15 if actor.profile.role == "ENTRY" else 4.9
	speed *= [1.0, 1.1, 0.92][actor.tactic]
	if actor.weapon == "awp":
		speed *= 0.9
	actor.travel += speed * DT
	while actor.track_cursor + 1 < points.size() and cumulative[actor.track_cursor + 1] <= actor.travel:
		actor.track_cursor += 1
	var next_position = points[actor.track_cursor]
	var motion = next_position - actor.position
	if motion.length_squared() > 0.00001:
		actor.facing = motion.normalized()
	actor.position = next_position
	actor.intent = "ROTATING" if bomb.status == "planted" and actor.team != t_team else "MOVING"
	if actor.track_cursor >= points.size() - 1:
		_next_waypoint(actor)

func _perceive() -> void:
	for actor in actors:
		actor.visible = []
		if not actor.alive or actor.blind > 0:
			continue
		for enemy in actors:
			if not enemy.alive or enemy.team == actor.team:
				continue
			var delta = enemy.position - actor.position
			var distance = delta.length()
			var facing = Vector3(actor.facing.x, 0, actor.facing.z).normalized()
			var toward = Vector3(delta.x, 0, delta.z).normalized()
			if distance > 4.0 and facing.dot(toward) < -0.15:
				continue
			if _visible(actor, enemy):
				actor.visible.append(enemy.index)
				actor.memory[enemy.index] = {"position": enemy.position, "time": round_time}
				actor.visible_at = round_time
				# Teammates receive observations, not a global enemy-position array.
				for mate in actors:
					if mate.team == actor.team and mate.alive:
						mate.memory[enemy.index] = {"position": enemy.position, "time": round_time - 0.25}
		if actor.visible.is_empty() and not actor.memory.is_empty() and round_time < actor.heard_until:
			var latest = actor.memory.values()[-1]
			actor.facing = (latest.position - actor.position).normalized()

func _visible(actor: Dictionary, enemy: Dictionary) -> bool:
	var start = actor.position + Vector3.UP * world.EYE
	var finish = enemy.position + Vector3.UP * world.EYE
	if not world.has_sight(start, finish):
		return false
	for smoke in smokes:
		if _segment_near(start, finish, smoke.position, smoke.radius) and start.distance_to(finish) > 2.2:
			return false
	return true

func _segment_near(a: Vector3, b: Vector3, center: Vector3, radius: float) -> bool:
	var delta = b - a
	var t = clampf((center - a).dot(delta) / maxf(0.0001, delta.length_squared()), 0.0, 1.0)
	return (a + delta * t).distance_to(center) < radius

func _shoot(actor: Dictionary) -> void:
	var candidates: Array = []
	for index in actor.visible:
		if actors[index].alive and _visible(actor, actors[index]):
			candidates.append(index)
	if candidates.is_empty():
		actor.target = -1
		return
	candidates.sort_custom(func(a, b): return actor.position.distance_squared_to(actors[a].position) < actor.position.distance_squared_to(actors[b].position))
	var target_index = candidates[0]
	if actor.target != target_index:
		actor.target = target_index
		actor.reaction = lerpf(0.5, 0.15, actor.profile.sense / 100.0)
		return
	if actor.fire_wait > 0 or actor.reaction > 0 or actor.reload > 0:
		return
	if actor.ammo <= 0:
		if actor.reserve > 0:
			actor.reload = 2.3
			actor.intent = "RELOADING"
		return
	var target = actors[target_index]
	var weapon = WEAPONS[actor.weapon]
	actor.ammo -= 1
	actor.fire_wait = weapon.interval
	var distance = actor.position.distance_to(target.position)
	var precision = (0.12 + actor.profile.aim * 0.0046 + actor.profile.sense * 0.0015) * actor.form
	var range_factor = 1.0 / (1.0 + maxf(0, distance - 8.0) / weapon.range)
	var probability = clampf(precision * range_factor, 0.04, 0.92)
	var hit = rng.randf() < probability
	var start = actor.position + Vector3.UP * world.EYE
	var finish = target.position + Vector3.UP * world.EYE
	shot_created.emit(start, finish, actor.team, hit)
	# Audible fire gives a direction to investigate, not permission to hit a wall-hidden target.
	for listener in actors:
		if listener.alive and listener.team != actor.team and listener.position.distance_to(actor.position) < 32:
			listener.memory[actor.index] = {"position": actor.position, "time": round_time}
			listener.heard_until = round_time + 2.0
			if listener.visible.is_empty():
				listener.facing = (actor.position - listener.position).normalized()
	if not hit:
		return
	var headshot = actor.weapon != "awp" and rng.randf() < 0.10 + actor.profile.aim * 0.0018
	var damage = weapon.damage * (2.8 if headshot else 1.0)
	if target.armor:
		damage *= 0.82
	var effective = minf(target.hp, damage)
	target.hp -= effective
	totals[actor.index].damage += roundi(effective)
	if target.hp <= 0:
		_kill(actor, target, headshot)

func _kill(killer: Dictionary, target: Dictionary, headshot: bool) -> void:
	if not target.alive:
		return
	target.alive = false
	target.hp = 0
	target.intent = "ELIMINATED"
	totals[target.index].deaths += 1
	totals[killer.index].kills += 1
	killer.round_kills += 1
	killer.cash = mini(16000, killer.cash + WEAPONS[killer.weapon].reward)
	_emit("kill", killer.index, "%s  [%s%s]  %s" % [killer.profile.handle, WEAPONS[killer.weapon].name, " · HS" if headshot else "", target.profile.handle], target.position, {"victim": target.index, "headshot": headshot})
	if bomb.status == "carried" and bomb.carrier == target.index:
		bomb.status = "dropped"
		bomb.carrier = -1
		bomb.position = target.position
		_emit("bomb_drop", target.index, "Bomb dropped · " + target.profile.handle, target.position)
	if bomb.defuser == target.index:
		bomb.defuser = -1
		bomb.defuse_time = 0.0

func _try_utility(actor: Dictionary) -> void:
	if round_time - actor.last_utility < 8.0 or round_time < 3 or actor.reaction > 0.1:
		return
	var target = actors[actor.visible[0]].position
	var kind = "flash" if actor.flash > 0 else ("smoke" if actor.smoke > 0 and actor.profile.role in ["SUPPORT", "IGL"] else "")
	if kind.is_empty() or actor.position.distance_to(target) > 24:
		return
	actor[kind] -= 1
	actor.last_utility = round_time
	var direction = (target - actor.position).normalized()
	var landing = actor.position + direction * minf(8.0, actor.position.distance_to(target) * 0.65)
	var arc = PackedVector3Array()
	var start = actor.position + Vector3.UP * 1.4
	var end = landing + Vector3.UP * 0.7
	var previous = start
	for i in range(1, 13):
		var t = i / 12.0
		var p = start.lerp(end, t) + Vector3.UP * sin(PI * t) * 2.0
		var collision = world.ray(previous, p)
		if not collision.is_empty():
			end = collision.position + collision.normal * 0.12
			arc.append(end)
			break
		arc.append(p)
		previous = p
	grenades.append({"kind": kind, "owner": actor.index, "position": end, "left": 0.9, "arc": arc})
	_emit("utility", actor.index, actor.profile.handle + " throws " + kind, end, {"utility": kind})

func _update_utility() -> void:
	for i in range(smokes.size() - 1, -1, -1):
		smokes[i].left -= DT
		if smokes[i].left <= 0:
			smokes.remove_at(i)
	for i in range(grenades.size() - 1, -1, -1):
		var grenade = grenades[i]
		grenade.left -= DT
		if grenade.left > 0:
			continue
		if grenade.kind == "smoke":
			smokes.append({"position": grenade.position, "radius": 3.4, "left": 18.0})
		else:
			for actor in actors:
				if not actor.alive:
					continue
				var eye = actor.position + Vector3.UP * world.EYE
				var delta = grenade.position - eye
				if delta.length() < 14 and actor.facing.dot(delta.normalized()) > -0.2 and world.has_sight(eye, grenade.position):
					var skill = actors[grenade.owner].profile.utility / 100.0
					actor.blind = maxf(actor.blind, (1.3 + skill) * (1.0 - delta.length() / 18.0))
					if actor.team != actors[grenade.owner].team:
						totals[grenade.owner].flashes += 1
		grenades.remove_at(i)

func _objective(actor: Dictionary) -> bool:
	if actor.team == t_team:
		if bomb.status == "dropped":
			if actor.position.distance_to(bomb.position) < 1.2:
				bomb.status = "carried"
				bomb.carrier = actor.index
				_emit("bomb_pickup", actor.index, actor.profile.handle + " recovers the bomb", actor.position)
				actor.waypoints = [sites[target_site].position]
				_next_waypoint(actor)
			else:
				var candidates = actors.filter(func(a): return a.alive and a.team == t_team)
				candidates.sort_custom(func(a, b): return a.position.distance_squared_to(bomb.position) < b.position.distance_squared_to(bomb.position))
				if not candidates.is_empty() and candidates[0].index == actor.index and actor.goal.distance_to(bomb.position) > 0.5:
					_set_route(actor, bomb.position)
					actor.intent = "RECOVER BOMB"
		if bomb.status == "carried" and bomb.carrier == actor.index:
			var site = sites[target_site]
			var flat = Vector2(actor.position.x - site.position.x, actor.position.z - site.position.z).length()
			if flat <= site.radius and absf(actor.position.y - site.position.y) < site.height_tolerance:
				if not actor.visible.is_empty() and round_time < ROUND_SECONDS - 7:
					actor.plant_time = 0
					return false
				actor.intent = "PLANTING"
				actor.plant_time += DT
				if actor.plant_time >= PLANT_SECONDS:
					bomb.status = "planted"
					bomb.was_planted = true
					bomb.position = actor.position
					bomb.time_left = BOMB_SECONDS
					totals[actor.index].plants += 1
					actor.cash = mini(16000, actor.cash + 300)
					_emit("plant", actor.index, actor.profile.handle + " plants on " + ("A" if target_site == "site_a" else "B"), actor.position)
					for defender in actors:
						if defender.team != t_team and defender.alive:
							defender.waypoints = [bomb.position]
							_next_waypoint(defender)
				return true
	else:
		if bomb.status == "planted" and actor.position.distance_to(bomb.position) < 1.2:
			var duration = 5.0 if actor.kit else 10.0
			if not actor.visible.is_empty() and bomb.time_left > duration + 3:
				if bomb.defuser == actor.index:
					bomb.defuser = -1
					bomb.defuse_time = 0
				return false
			if bomb.defuser in [-1, actor.index]:
				bomb.defuser = actor.index
				bomb.defuse_time += DT
				actor.intent = "DEFUSING"
				if bomb.defuse_time >= duration:
					bomb.status = "defused"
					totals[actor.index].defuses += 1
					actor.cash = mini(16000, actor.cash + 300)
					_emit("defuse", actor.index, actor.profile.handle + " defuses the bomb", bomb.position)
				return true
	return false

func _alive(team: int) -> int:
	return actors.filter(func(a): return a.team == team and a.alive).size()

func _check_round_end() -> void:
	var ct_team = 1 - t_team
	if bomb.status == "defused":
		_end_round(ct_team, "defuse")
	elif _alive(ct_team) == 0:
		_end_round(t_team, "elimination")
	elif bomb.status == "planted":
		bomb.time_left -= DT
		if bomb.time_left <= 0:
			bomb.status = "exploded"
			_emit("explosion", -1, "The bomb detonates", bomb.position)
			_end_round(t_team, "explosion")
	elif _alive(t_team) == 0:
		_end_round(ct_team, "elimination")
	elif round_time >= ROUND_SECONDS:
		_end_round(ct_team, "time")

func _end_round(winner: int, reason: String) -> void:
	if phase == "round_end" or finished:
		return
	round_winner = winner
	round_reason = reason
	phase = "round_end"
	score[winner] += 1
	loss_streak[winner] = maxi(0, int(loss_streak[winner]) - 1)
	loss_streak[1 - winner] = mini(4, int(loss_streak[1 - winner]) + 1)
	for actor in actors:
		var income = (3500 if reason in ["defuse", "explosion"] else 3250) if actor.team == winner else 1400 + mini(4, loss_streak[actor.team]) * 500
		if actor.team == t_team and actor.team != winner and bomb.was_planted:
			income += 600
		actor.cash = mini(16000, actor.cash + income)
		carry[actor.index] = {"cash": actor.cash, "weapon": actor.weapon, "armor": actor.armor, "alive": actor.alive}
	_emit("round_end", -1, "%s win · %s" % ["NORTHLINE" if winner == 0 else snapshot.opponent.name, reason])
	var average_cash = [0, 0]
	for actor in actors:
		average_cash[actor.team] += actor.cash
	average_cash = [int(average_cash[0] / 5), int(average_cash[1] / 5)]
	var summary = {"number": round_number, "winner": winner, "score": score.duplicate(),
		"detail": ("NORTHLINE" if winner == 0 else snapshot.opponent.name) + " win by " + reason + ".",
		"reason": reason, "cash": average_cash, "chance": -1.0, "ct": t_team != 0,
		"pistol": round_number in [1, 13], "duration": snappedf(round_time, 0.1),
		"events": round_events.duplicate(true), "site": target_site}
	rounds.append(summary)
	if _match_over():
		finished = true
		phase = "finished"
		emit_signal("match_finished", result())
	else:
		round_finished.emit(summary)

func _match_over() -> bool:
	if round_number <= 24:
		return score[0] >= 13 or score[1] >= 13
	if sudden_death:
		return true
	var target = 16 + int((round_number - 25) / 6) * 3
	if score[0] >= target or score[1] >= target:
		return true
	if round_number >= 60 and (round_number - 24) % 6 == 0:
		sudden_death = true
	return false

func _emit(kind: String, actor_index: int, text: String, position: Vector3 = Vector3.ZERO, extra: Dictionary = {}) -> void:
	sequence += 1
	var item = {"id": sequence, "round": round_number, "time": snappedf(round_time, 0.1),
		"kind": kind, "actor": actor_index, "text": text, "position": [position.x, position.y, position.z]}
	item.merge(extra)
	if actor_index >= 0:
		item["team"] = actors[actor_index].team
	# Only significant actual events are retained; shot tracers are a transient signal.
	round_events.append(item)
	event_created.emit(item)

func checkpoint() -> Dictionary:
	return {"rounds": rounds.duplicate(true), "score": score.duplicate(), "carry": carry.duplicate(true),
		"totals": totals.duplicate(true), "loss_streak": loss_streak.duplicate(),
		"sequence": sequence, "simulated_seconds": simulated_seconds, "sudden_death": sudden_death}

func result() -> Dictionary:
	var kills: Dictionary = {}
	var mvp = snapshot.squad[0]
	var best = -1
	for i in range(5):
		var id = snapshot.squad[i]
		kills[id] = int(totals[i].kills)
		if totals[i].kills > best:
			best = totals[i].kills
			mvp = id
	return {"match_id": snapshot.id, "score": score.duplicate(), "won": score[0] > score[1],
		"rounds": rounds.duplicate(true), "kills": kills, "mvp": mvp,
		"rating": Aggregate.rating(snapshot.squad, 0, snapshot.tactic), "opponent": snapshot.opponent.duplicate(true),
		"map": 0, "map_name": C.MAPS[0], "tactic": snapshot.tactic, "mode": "played",
		"sudden_death": sudden_death, "statistics": totals.duplicate(true), "seed": snapshot.seed,
		"engine_version": snapshot.engine_version, "route_failures": route_failures,
		"reward": 0, "xp": 0, "earned_pack": ""}
