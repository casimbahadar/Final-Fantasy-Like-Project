class_name DamageCalculator
extends RefCounted

## Pure-function damage math. Returns a Dictionary so callers see a single
## structured result without juggling out-params or magic numbers.
##
## Result fields:
##   miss: bool       — true if the action failed to land
##   damage: int      — final HP delta (positive = damage, negative = heal)
##   crit: bool       — was this a critical hit?
##   elem_mod: float  — element multiplier applied (1.0 = neutral, 0.0 = immune)
##   absorbed: bool   — defender absorbed this element (heals instead)

const VARIANCE_LOW := 0.85
const VARIANCE_HIGH := 1.15
const BASE_CRIT_CHANCE := 0.05
const LUK_CRIT_FACTOR := 0.005


static func compute(attacker: BattleUnit, target: BattleUnit, skill: Skill) -> Dictionary:
	var result := {
		"miss": false,
		"damage": 0,
		"crit": false,
		"elem_mod": 1.0,
		"absorbed": false,
	}

	if skill == null:
		return result

	# Heals don't miss and don't apply target defenses.
	if skill.damage_kind == Skill.DamageKind.HEAL:
		var amt: int = maxi(1, attacker.stat("mag") + skill.power)
		result.damage = -amt
		return result

	if skill.damage_kind == Skill.DamageKind.NONE:
		return result

	if randf() > skill.accuracy:
		result.miss = true
		return result

	var atk_stat: int
	var def_stat: int
	if skill.damage_kind == Skill.DamageKind.PHYSICAL:
		atk_stat = attacker.stat("atk")
		def_stat = target.stat("def")
	else:
		atk_stat = attacker.stat("mag")
		def_stat = target.stat("res")

	var base: float = float(maxi(1, atk_stat * 2 - def_stat))
	var raw: float = base * float(skill.power) / 10.0

	raw *= randf_range(VARIANCE_LOW, VARIANCE_HIGH)

	var luk_diff: int = attacker.stat("luk") - target.stat("luk")
	var crit_chance: float = BASE_CRIT_CHANCE + skill.crit_bonus + maxf(0.0, float(luk_diff) * LUK_CRIT_FACTOR)
	if randf() < crit_chance:
		raw *= 2.0
		result.crit = true

	# Element modifier — only applies if the target has an element table.
	if target.is_enemy() and target.enemy != null and skill.element != Skill.Element.NONE:
		var mod: float = float(target.enemy.element_modifiers.get(skill.element, 1.0))
		raw *= absf(mod)
		result.elem_mod = mod
		if mod < 0.0:
			# Negative modifier = absorb (heal target instead of damaging).
			result.absorbed = true
			result.damage = -maxi(1, int(raw))
			return result
		if mod == 0.0:
			result.damage = 0
			return result

	result.damage = maxi(1, int(raw))
	return result
