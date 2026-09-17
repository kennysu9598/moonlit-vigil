extends SceneTree
const Combat = preload("res://scripts/combat.gd")
var failures: int = 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func _init() -> void:
	var c = Combat.new()
	c.start()
	c.begin_turn()
	var before: String = var_to_str(c.units)
	var resource: int = c.energy
	check(not c.perform(9, 3).ok, "illegal skill")
	check(not c.perform(1, 0).ok, "illegal target")
	check(before == var_to_str(c.units) and c.energy == resource and c.action_count == 0, "illegal atomicity")
	c.energy = 0
	check(not c.perform(2, 3).ok and c.energy == 0, "energy lower")
	c.energy = 8
	check(c.perform(0, 3).ok and c.energy == 8, "energy upper")
	check(not c.perform(0, 3).ok, "one action")
	c.start()
	c.units[3].alive = false
	c.units[3].hp = 0
	c.begin_turn()
	c.perform(0, 4)
	c.advance()
	check(c.current_id == 2, "dead skipped")
	c.start()
	c.current_id = 1
	c.units[0].alive = false
	c.units[0].hp = 0
	c.begin_turn()
	check(not c.perform(1, 0).ok and not c.units[0].alive, "no resurrection")
	c.start()
	c.current_id = 2
	c.units[5].charging = true
	c.begin_turn()
	c.perform(1, 5)
	check(not c.units[5].charging and c.units[5].stun == 1, "interrupt")
	c.advance()
	c.current_id = 5
	var turn: Dictionary = c.begin_turn()
	check(turn.skipped and c.units[5].stun == 0, "stun expires")
	c.start()
	c.units[0].burn = 2
	c.begin_turn()
	var hp: int = c.units[0].hp
	c.begin_turn()
	check(c.units[0].hp == hp and c.units[0].burn == 1, "begin idempotent")
	c.perform(0, 3)
	c.advance()
	c.current_id = 0
	c.begin_turn()
	check(c.units[0].burn == 0 and c.units[0].hp == hp - 9, "burn expires")
	for loser in [0, 1]:
		c.start()
		for unit in c.units:
			if unit.team == loser:
				unit.hp = 0
				unit.alive = false
		c.begin_turn()
		check(c.winner == 1 - loser and not c.perform(0, 3).ok, "terminal winner")
	c.start()
	check(c.winner == -1 and c.action_count == 0 and c.energy == 3 and c.units[0].burn == 0 and c.units[5].hp == 470, "restart reset")
	c.start()
	check(c._turn_order == [0, 3, 2, 4, 1, 5], "speed order derived")
	c._damage(5, 235, [], true)
	check(c.units[5].enraged and c.units[5].speed == 70 and c._turn_order == [0, 3, 2, 4, 5, 1], "enrage order shift")
	var wins: int = 0
	var total: int = 0
	var min_actions: int = 999
	var max_actions: int = 0
	for seed_value in range(100):
		c.start(seed_value)
		for step in range(180):
			if c.winner != -1: break
			var begin: Dictionary = c.begin_turn()
			if not begin.skipped:
				var choice: Dictionary = c.ai_choice() if c.current_id >= 3 else strategy(c)
				check(c.perform(choice.skill, choice.target).ok, "simulation valid")
			check(c.energy >= 0 and c.energy <= 8, "simulation bounds")
			c.advance()
		check(c.winner != -1, "simulation terminates")
		if c.winner == 0: wins += 1
		total += c.action_count
		min_actions = mini(min_actions, c.action_count)
		max_actions = maxi(max_actions, c.action_count)
	print("COMBAT_TEST failures=%d seeds=100 wins=%d actions_mean=%.2f range=%d..%d" % [failures, wins, total / 100.0, min_actions, max_actions])
	quit(0 if failures == 0 else 1)
func strategy(c) -> Dictionary:
	var target: int = 5
	for id in [3, 4, 5]:
		if c.units[id].alive:
			target = id
			break
	if c.current_id == 0 and c.energy >= 3: return {"skill": 2, "target": target}
	if c.current_id == 2:
		if c.units[5].charging and c.energy >= 2: return {"skill": 1, "target": 5}
		if c.energy >= 3: return {"skill": 2, "target": target}
	if c.current_id == 1:
		var weakest: int = 1
		var missing: int = 0
		for id in range(3):
			if c.units[id].alive and c.units[id].max_hp - c.units[id].hp > missing:
				weakest = id
				missing = c.units[id].max_hp - c.units[id].hp
		if missing >= 45 and c.energy >= 2: return {"skill": 1, "target": weakest}
		if c.energy >= 3 and (c.units[5].charging or missing >= 25): return {"skill": 2, "target": 1}
	return {"skill": 0, "target": target}

