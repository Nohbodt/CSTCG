class_name MatchSimulator
extends RefCounted

const C = preload("res://scripts/catalog.gd")

static func rating(lineup: Array, map_index: int, tactic: int) -> float:
	if lineup.size() != 5:
		return 0.0
	var total = 0.0
	var roles: Array = []
	var clubs: Dictionary = {}
	for id in lineup:
		var c = C.card(id)
		if c.is_empty():
			return 0.0
		var value = float(c.overall)
		if tactic == 1:
			value = c.aim * 0.60 + c.sense * 0.25 + c.utility * 0.15
		elif tactic == 2:
			value = c.aim * 0.25 + c.sense * 0.40 + c.utility * 0.35
		if c.role == C.MAP_ROLES[clampi(map_index, 0, C.MAP_ROLES.size() - 1)]:
			value += 3.0
		total += value
		if c.role not in roles:
			roles.append(c.role)
		clubs[c.club] = clubs.get(c.club, 0) + 1
	var chemistry = 0.0
	for count in clubs.values():
		chemistry += maxf(0.0, float(count - 1)) * 0.35
	return total / 5.0 + roles.size() * 0.6 + chemistry

static func economy_bonus(cash: int) -> float:
	return clampf((cash - 2500.0) / 4000.0, -0.06, 0.06)

static func simulate(lineup: Array, map_index: int, tactic: int, opponent: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	var own_rating = rating(lineup, map_index, tactic)
	var score = [0, 0]
	var cash = [800, 800]
	var loss_streak = [0, 0]
	var rounds: Array = []
	var kills: Dictionary = {}
	for id in lineup:
		kills[id] = 0
	var number = 0
	var sudden_death = false
	while true:
		number += 1
		if number == 13:
			cash = [800, 800]
			loss_streak = [0, 0]
		# MR3 overtime: reset both teams to a full-buy budget every six rounds.
		if number > 24 and (number - 25) % 6 == 0:
			cash = [10000, 10000]
			loss_streak = [0, 0]
		var is_ct = (number <= 12 or (number > 24 and (number - 25) % 6 >= 3))
		var pistol = number == 1 or number == 13
		var tactical = 0.0
		# Fast execute pressures control; control punishes balanced; balanced punishes fast.
		if (tactic == 1 and opponent.tactic == 2) or (tactic == 2 and opponent.tactic == 0) or (tactic == 0 and opponent.tactic == 1):
			tactical = 0.025
		elif tactic != opponent.tactic:
			tactical = -0.025
		var p = clampf(0.5 + (own_rating - opponent.rating) * 0.011 + tactical + (0.025 if is_ct else -0.025), 0.18, 0.82)
		if not pistol:
			p = clampf(p + economy_bonus(cash[0]) - economy_bonus(cash[1]), 0.15, 0.85)
		var spend = [mini(cash[0], 4200), mini(cash[1], 4200)]
		var winner = 0 if rng.randf() < p else 1
		score[winner] += 1
		var loser = 1 - winner
		loss_streak[winner] = 0
		loss_streak[loser] = mini(4, loss_streak[loser] + 1)
		cash[winner] = mini(16000, cash[winner] - spend[winner] + 3250)
		cash[loser] = mini(16000, cash[loser] - spend[loser] + 1400 + loss_streak[loser] * 500)
		var star = lineup[rng.randi_range(0, lineup.size() - 1)]
		for _k in range(rng.randi_range(3, 5) if winner == 0 else rng.randi_range(0, 3)):
			var killer = lineup[rng.randi_range(0, lineup.size() - 1)]
			kills[killer] += 1
		var reasons = ["finds the opening and converts the site.", "holds the retake with perfect utility.", "wins the late-round duel.", "turns a mid-round call into a clean finish."]
		var detail = C.card(star).handle + " " + reasons[rng.randi_range(0, 3)] if winner == 0 else opponent.name + " controls the final exchange."
		if pistol:
			detail = "Pistol round · " + detail
		rounds.append({"number": number, "winner": winner, "score": score.duplicate(),
			"detail": detail, "cash": cash.duplicate(), "chance": p, "ct": is_ct, "pistol": pistol})
		if number <= 24:
			if score[0] == 13 or score[1] == 13:
				break
		elif sudden_death:
			break
		else:
			var played = (number - 24) % 6
			var target = 16 + int((number - 25) / 6) * 3
			if score[0] >= target or score[1] >= target:
				break
			if played == 0 and number >= 60:
				# Explicit prototype cap: after six tied OTs, one deciding round.
				sudden_death = true
	var mvp = lineup[0]
	for id in kills:
		if kills[id] > kills[mvp]:
			mvp = id
	return {"score": score, "won": score[0] > score[1], "rounds": rounds, "kills": kills,
		"mvp": mvp, "rating": own_rating, "opponent": opponent.duplicate(), "map": map_index,
		"tactic": tactic, "sudden_death": sudden_death}
