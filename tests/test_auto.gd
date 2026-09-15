extends SceneTree
const Combat = preload("res://scripts/combat.gd")
const AI = preload("res://scripts/auto_policy.gd")
var failures: int = 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func _init() -> void:
	var c = Combat.new()
	c.start()
	c.current_id = 2
	c.units[5].charging = true
	c.begin_turn()
	var snapshot: String = var_to_str(c.units)
	var choice: Dictionary = AI.choose(c)
	check(choice.skill == 1 and choice.target == 5, "interrupt priority")
	check(snapshot == var_to_str(c.units), "policy pure")
	c.start()
	c.current_id = 1
	c.units[0].hp = 15
	c.begin_turn()
	choice = AI.choose(c)
	check(choice.skill == 1 and choice.target == 0, "urgent heal")
	c.start()
	c.current_id = 1
	c.units[0].hp -= 30
	c.units[2].hp -= 30
	c.begin_turn()
	check(AI.choose(c).skill == 2, "group protection")
	c.start()
	c.units[3].hp = 1
	c.begin_turn()
	choice = AI.choose(c)
	check(choice.skill == 0 and choice.target == 3, "cheap kill")
	c.energy = 0
	check(AI.choose(c).skill == 0, "resource fallback")
	c.units[0].alive = false
	check(AI.choose(c).target == -1, "dead actor skipped")
	var wins: int = 0
	var total: int = 0
	var minimum: int = 999
	var maximum: int = 0
	for seed_value in range(100):
		c.start(seed_value)
		for step in range(200):
			if c.winner != -1: break
			var begin: Dictionary = c.begin_turn()
			if not begin.skipped:
				choice = AI.choose(c)
				var result: Dictionary = c.perform(choice.skill, choice.target)
				check(result.ok, "illegal action seed=%d step=%d" % [seed_value, step])
				if not result.ok: break
			c.advance()
		check(c.winner != -1, "deadlock seed=%d" % seed_value)
		if c.winner == 0: wins += 1
		total += c.action_count
		minimum = mini(minimum, c.action_count)
		maximum = maxi(maximum, c.action_count)
	check(wins > 50, "majority wins")
	print("AUTO_TEST failures=%d seeds=100 wins=%d mean_actions=%.2f range=%d..%d" % [failures, wins, total / 100.0, minimum, maximum])
	quit(0 if failures == 0 else 1)
