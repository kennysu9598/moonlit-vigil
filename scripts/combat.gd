class_name MoonCombat
extends RefCounted

var units: Array[Dictionary] = []
var current_id: int = 0
var winner: int = -1
var energy: int = 3
var round_index: int = 1
var action_count: int = 0
var _rng := RandomNumberGenerator.new()
var _order: Array[int] = [0, 3, 2, 4, 1, 5]
var _cursor: int = 0
var _begun: bool = false
var _spent: bool = false
var _begin_result: Dictionary = {}

func start(seed_value: int = 42) -> void:
	_rng.seed = hash(str(seed_value))
	units.clear()
	var names := ["绯羽", "澄铃", "玄刃", "灾鸦", "灯魇", "荒祟"]
	var health := [160, 175, 185, 175, 190, 470]
	var attack := [25, 18, 28, 39, 34, 46]
	var speeds := [100, 60, 80, 90, 70, 50]
	for id in range(6):
		units.append({"id": id, "name": names[id], "team": 0 if id < 3 else 1, "hp": health[id], "max_hp": health[id], "atk": attack[id], "speed": speeds[id], "shield": 0, "stun": 0, "burn": 0, "alive": true, "charging": false, "enraged": false, "turns": 0})
	current_id = 0
	winner = -1
	energy = 3
	round_index = 1
	action_count = 0
	_cursor = 0
	_begun = false
	_spent = false
	_begin_result = {}

func _skill(title: String, description: String, cost: int, target: String, kind: String) -> Dictionary:
	return {"name": title, "description": description, "cost": cost, "target": target, "kind": kind}

func skills_for(id: int) -> Array[Dictionary]:
	match id:
		0: return [_skill("朱羽", "单体伤害，获得1灵火", 0, "enemy", "damage"), _skill("流火", "全体伤害并灼烧2回合", 2, "all_enemies", "burn"), _skill("天羽焚夜", "强力全体火雨并灼烧2回合", 3, "all_enemies", "damage")]
		1: return [_skill("铃击", "单体伤害，获得1灵火", 0, "enemy", "damage"), _skill("月露", "治疗存活友方60生命", 2, "ally", "heal"), _skill("澄月结界", "全队治疗25并获得40护盾", 3, "all_allies", "shield")]
		2: return [_skill("影切", "单体伤害，获得1灵火", 0, "enemy", "damage"), _skill("封魂", "单体伤害并眩晕1回合，打断蓄力", 2, "enemy", "stun"), _skill("断夜", "先破盾再造成强力单体伤害", 3, "enemy", "damage")]
		3: return [_skill("鸦啄", "单体伤害", 0, "enemy", "damage"), _skill("黑焰", "伤害并灼烧2回合", 2, "enemy", "burn"), _skill("群鸦", "全体伤害", 3, "all_enemies", "damage")]
		4: return [_skill("鬼灯", "单体伤害", 0, "enemy", "damage"), _skill("幽障", "给予友方35护盾", 2, "ally", "shield"), _skill("夜雾", "全体伤害", 3, "all_enemies", "damage")]
		5: return [_skill("荒爪", "单体伤害", 0, "enemy", "damage"), _skill("聚厄", "蓄力；下一行动释放全体重击，可眩晕打断", 2, "self", "charge"), _skill("厄月坠", "释放已蓄力的全体重击", 3, "all_enemies", "damage")]
	return []

func _event(events: Array, kind: String, id: int, value: int = 0) -> void:
	events.append({"type": kind, "id": id, "value": value})

func _snapshot(result: Dictionary) -> Dictionary:
	result["units"] = units.duplicate(true)
	result["energy"] = energy
	result["winner"] = winner
	return result

func begin_turn() -> Dictionary:
	if _begun:
		return _begin_result.duplicate(true)
	var events: Array = []
	var skipped: bool = winner != -1 or units.is_empty() or not units[current_id].alive
	_begun = true
	if not skipped:
		var actor: Dictionary = units[current_id]
		actor.turns += 1
		if actor.burn > 0:
			actor.burn -= 1
			_damage(current_id, 9, events, true)
			_event(events, "burn_tick", current_id, actor.burn)
		if actor.alive and actor.stun > 0:
			actor.stun -= 1
			actor.charging = false
			skipped = true
			_event(events, "skip", current_id)
		if not actor.alive:
			skipped = true
		if actor.alive and actor.team == 0:
			energy = mini(8, energy + 1)
			_event(events, "energy", current_id, energy)
	_check_winner()
	if winner != -1:
		skipped = true
	_spent = skipped
	_begin_result = _snapshot({"actor": current_id, "id": current_id, "events": events, "skipped": skipped})
	return _begin_result.duplicate(true)

func perform(skill_index: int, target_id: int) -> Dictionary:
	var result := {"ok": false, "reason": "", "actor": current_id, "skill": skill_index, "events": [], "ultimate": skill_index == 2}
	if winner != -1 or units.is_empty():
		result.reason = "战斗已结束"
	elif not _begun or _spent or not units[current_id].alive:
		result.reason = "当前无法行动"
	elif skill_index < 0 or skill_index > 2:
		result.reason = "技能不存在"
	else:
		var actor: Dictionary = units[current_id]
		var skill: Dictionary = skills_for(current_id)[skill_index]
		var valid_target: bool = target_id >= 0 and target_id < units.size() and units[target_id].alive
		if actor.team == 0 and energy < skill.cost:
			result.reason = "灵火不足"
		elif current_id == 5 and skill_index == 2 and not actor.charging:
			result.reason = "需要先蓄力"
		elif not valid_target:
			result.reason = "目标已倒下或不存在"
		elif skill.target in ["enemy", "all_enemies"] and units[target_id].team == actor.team:
			result.reason = "请选择敌方目标"
		elif skill.target in ["ally", "all_allies"] and units[target_id].team != actor.team:
			result.reason = "请选择友方目标"
		elif skill.target == "self" and target_id != current_id:
			result.reason = "该技能只能以自身为目标"
		else:
			result.ok = true
			_spent = true
			action_count += 1
			var events: Array = result.events
			if actor.team == 0:
				energy = clampi(energy - int(skill.cost) + (1 if skill_index == 0 else 0), 0, 8)
				_event(events, "energy", current_id, energy)
			_resolve(skill_index, target_id, events)
			_check_winner()
	return _snapshot(result)

func _resolve(skill: int, target: int, events: Array) -> void:
	var actor: Dictionary = units[current_id]
	if skill == 0:
		_damage(target, int(actor.atk) + _rng.randi_range(-3, 3), events)
		return
	match current_id:
		0:
			for id in _living(1):
				_damage(id, (24 if skill == 1 else 40) + _rng.randi_range(-3, 3), events)
				_status(id, "burn", 2, events)
		1:
			if skill == 1:
				_heal(target, 60, events)
			else:
				for id in _living(0):
					_heal(id, 25, events)
					_shield(id, 40, events)
		2:
			if skill == 2:
				units[target].shield = 0
				_event(events, "break", target)
			_damage(target, 32 if skill == 1 else 72, events)
			if skill == 1:
				_status(target, "stun", 1, events)
		3:
			if skill == 1:
				_damage(target, 33, events)
				_status(target, "burn", 2, events)
			else:
				for id in _living(0): _damage(id, 17, events)
		4:
			if skill == 1: _shield(target, 35, events)
			else:
				for id in _living(0): _damage(id, 15, events)
		5:
			if skill == 1:
				actor.charging = true
				_event(events, "charge", current_id, 1)
			else:
				actor.charging = false
				for id in _living(0): _damage(id, 44 if actor.enraged else 34, events)

func _damage(id: int, amount: int, events: Array, ignore_shield: bool = false) -> void:
	var unit: Dictionary = units[id]
	if not unit.alive: return
	var absorbed := 0 if ignore_shield else mini(int(unit.shield), amount)
	unit.shield -= absorbed
	if absorbed > 0: _event(events, "absorb", id, absorbed)
	var loss := mini(int(unit.hp), maxi(0, amount - absorbed))
	unit.hp -= loss
	_event(events, "damage", id, loss)
	if unit.hp <= 0:
		unit.alive = false
		unit.charging = false
		unit.stun = 0
		unit.burn = 0
		unit.shield = 0
		_event(events, "death", id)
	elif id == 5 and unit.hp <= unit.max_hp / 2 and not unit.enraged:
		unit.enraged = true
		unit.atk += 7
		_event(events, "enrage", id, 1)

func _heal(id: int, amount: int, events: Array) -> void:
	if not units[id].alive: return
	var value := mini(amount, int(units[id].max_hp - units[id].hp))
	units[id].hp += value
	_event(events, "heal", id, value)

func _shield(id: int, amount: int, events: Array) -> void:
	if not units[id].alive: return
	units[id].shield = mini(60, int(units[id].shield) + amount)
	_event(events, "shield", id, int(units[id].shield))

func _status(id: int, status: String, duration: int, events: Array) -> void:
	if not units[id].alive: return
	units[id][status] = maxi(int(units[id][status]), duration)
	_event(events, status, id, duration)
	if status == "stun" and units[id].charging:
		units[id].charging = false
		_event(events, "interrupt", id)

func _living(team: int) -> Array[int]:
	var result: Array[int] = []
	for unit in units:
		if unit.alive and unit.team == team: result.append(int(unit.id))
	return result

func _check_winner() -> void:
	if _living(0).is_empty(): winner = 1
	elif _living(1).is_empty(): winner = 0

func advance() -> void:
	if winner != -1 or not _spent: return
	for unused in range(6):
		_cursor = (_cursor + 1) % _order.size()
		if _cursor == 0: round_index += 1
		current_id = _order[_cursor]
		if units[current_id].alive: break
	_begun = false
	_spent = false
	_begin_result = {}

func ai_choice() -> Dictionary:
	if units.is_empty() or winner != -1: return {"skill": 0, "target": -1}
	var actor: Dictionary = units[current_id]
	var enemies := _living(1 - int(actor.team))
	if enemies.is_empty(): return {"skill": 0, "target": -1}
	var target: int = enemies[_rng.randi_range(0, enemies.size() - 1)]
	if current_id == 5:
		if actor.charging: return {"skill": 2, "target": target}
		if actor.turns % 2 == 1: return {"skill": 1, "target": 5}
	if current_id == 4 and actor.turns % 3 == 1: return {"skill": 1, "target": 5 if units[5].alive else 4}
	if current_id == 3 and actor.turns % 2 == 0: return {"skill": 1, "target": target}
	return {"skill": 0, "target": target}









