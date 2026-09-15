extends RefCounted

# Pure decision helper: no combat state, random generator or resources are changed.
# Call after begin_turn(); the caller advances turns marked skipped.
static func choose(combat) -> Dictionary:
	var none := {"skill": 0, "target": -1}
	if combat.units.is_empty() or combat.winner != -1:
		return none
	var id: int = combat.current_id
	if id < 0 or id >= combat.units.size() or not combat.units[id].alive:
		return none
	if id >= 3:
		return combat.ai_choice()
	var enemies: Array[int] = []
	var allies: Array[int] = []
	for unit in combat.units:
		if unit.alive:
			if unit.team == 1: enemies.append(int(unit.id))
			else: allies.append(int(unit.id))
	if enemies.is_empty(): return none
	var energy: int = combat.energy
	var charging: bool = combat.units[5].alive and combat.units[5].charging
	if id == 2 and charging and energy >= 2:
		return {"skill": 1, "target": 5}
	var target: int = enemies[0]
	var weakest: int = allies[0]
	var missing: int = 0
	var hurt_count: int = 0
	for ally in allies:
		var deficit: int = combat.units[ally].max_hp - combat.units[ally].hp
		if deficit > missing:
			missing = deficit
			weakest = ally
		if deficit >= 25: hurt_count += 1
	if id == 1:
		if energy >= 2 and combat.units[weakest].hp < combat.units[weakest].max_hp * 0.45:
			return {"skill": 1, "target": weakest}
		if energy >= 3 and (hurt_count >= 2 or charging):
			return {"skill": 2, "target": id}
		if energy >= 2 and missing >= 45:
			return {"skill": 1, "target": weakest}
	# Secure a kill with the cheapest action using minimum random damage.
	for enemy in enemies:
		var effective: int = combat.units[enemy].hp + combat.units[enemy].shield
		if effective < combat.units[target].hp + combat.units[target].shield:
			target = enemy
		if effective <= combat.units[id].atk - 3:
			return {"skill": 0, "target": enemy}
	if id == 2 and energy >= 3:
		for enemy in enemies:
			if combat.units[enemy].hp <= 72:
				return {"skill": 2, "target": enemy}
	if id == 0:
		# Next player is the controller and receives +1 at turn start.
		var reserve: int = 1 if charging and combat.units[2].alive else 0
		if energy >= 3 + reserve: return {"skill": 2, "target": target}
		if energy >= 2 + reserve and enemies.size() >= 2: return {"skill": 1, "target": target}
	if id == 2 and energy >= 3: return {"skill": 2, "target": target}
	return {"skill": 0, "target": target}
