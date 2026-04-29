class_name EnemyAI
extends RefCounted

## Stateless enemy AI. Picks a skill from the unit's skill list (uniformly,
## requires_mp filtered) and a valid target. Future: priority weights, behavior
## scripts per enemy id.


static func choose_action(unit: BattleUnit, allies: Array, enemies: Array) -> Dictionary:
	# allies/enemies here are from the AI's perspective: allies = the enemy's
	# own side; enemies = the player party.
	var skills := unit.available_skills()
	var usable: Array[Skill] = []
	var attack_only := unit.is_attack_only()
	var silenced := unit.is_silenced()
	for s in skills:
		if s == null:
			continue
		if attack_only and s.id != &"attack":
			continue
		if silenced and s.mp_cost > 0:
			continue
		if unit.mp >= s.mp_cost:
			usable.append(s)
	if usable.is_empty():
		# Last-ditch fallback to global Attack so the unit always has *something*
		# to do. Avoids a turn-skipping deadlock if all of its skills are gated.
		var atk: Skill = Database.skill(&"attack")
		if atk != null:
			usable.append(atk)
		else:
			return {}

	var pick: Skill = usable.pick_random()
	var target: BattleUnit = _pick_target(pick, unit, allies, enemies)
	if target == null:
		return {}
	return {"skill": pick, "target": target}


static func _pick_target(skill: Skill, _self_unit: BattleUnit, allies: Array, enemies: Array) -> BattleUnit:
	var pool: Array = []
	match skill.target_kind:
		Skill.TargetKind.ENEMY_SINGLE, Skill.TargetKind.ENEMY_ALL:
			for u in enemies:
				if u.is_alive():
					pool.append(u)
		Skill.TargetKind.ALLY_SINGLE, Skill.TargetKind.ALLY_ALL:
			for u in allies:
				if u.is_alive():
					pool.append(u)
		Skill.TargetKind.SELF:
			return _self_unit
	if pool.is_empty():
		return null
	return pool.pick_random()
