class_name BattleUnit
extends Node2D

## A combatant in a battle. Wraps either a PartyMember (for allies, persists
## back to Party state) or an Enemy resource (ephemeral). Holds runtime fields
## (hp, mp, atb gauge, status, defending) and exposes a uniform stat() API so
## DamageCalculator and AI don't care which side a unit is on.

signal hp_changed(new_hp: int, max_hp: int)
signal mp_changed(new_mp: int, max_mp: int)
signal died
signal action_finished

enum Side { ALLY, ENEMY }

@export var side: Side = Side.ALLY

@onready var sprite: Sprite2D = $Sprite2D

# ---- Backing data (exactly one of these is set) ----
var party_member  # Party.PartyMember reference (allies)
var enemy: Enemy  # Enemy resource (enemies)

# ---- Runtime ----
var hp: int = 0
var mp: int = 0
var atb: float = 0.0
var defending: bool = false
var statuses: Array[StringName] = []


func bind_ally(member) -> void:
	side = Side.ALLY
	party_member = member
	hp = member.hp
	mp = member.mp


func bind_enemy(enemy_data: Enemy) -> void:
	side = Side.ENEMY
	enemy = enemy_data
	hp = enemy_data.max_hp
	mp = enemy_data.max_mp


func display_name() -> String:
	if party_member != null:
		return party_member.actor_data().display_name
	return enemy.display_name


func max_hp() -> int:
	if party_member != null:
		return party_member.max_hp()
	return enemy.max_hp


func max_mp() -> int:
	if party_member != null:
		return party_member.max_mp()
	return enemy.max_mp


func stat(stat_name: String) -> int:
	if party_member != null:
		return party_member.stat(stat_name)
	return enemy.get(stat_name)


func is_alive() -> bool:
	return hp > 0


func is_ally() -> bool:
	return side == Side.ALLY


func is_enemy() -> bool:
	return side == Side.ENEMY


func get_battle_sprite() -> Texture2D:
	if party_member != null:
		var actor: Actor = party_member.actor_data()
		return actor.battle_sprite if actor != null else null
	return enemy.battle_sprite


func take_damage(amount: int) -> int:
	if defending:
		amount = maxi(1, amount / 2)
	hp = maxi(0, hp - amount)
	if party_member != null:
		party_member.hp = hp
	hp_changed.emit(hp, max_hp())
	if hp == 0:
		died.emit()
	return amount


func heal(amount: int) -> int:
	hp = mini(max_hp(), hp + amount)
	if party_member != null:
		party_member.hp = hp
	hp_changed.emit(hp, max_hp())
	return amount


func use_mp(amount: int) -> bool:
	if amount <= 0:
		return true
	if mp < amount:
		return false
	mp -= amount
	if party_member != null:
		party_member.mp = mp
	mp_changed.emit(mp, max_mp())
	return true


func restore_mp(amount: int) -> int:
	if amount <= 0:
		return 0
	var before := mp
	mp = mini(max_mp(), mp + amount)
	if party_member != null:
		party_member.mp = mp
	mp_changed.emit(mp, max_mp())
	return mp - before


## Skills available in the battle's action menu.
func available_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	if party_member != null:
		var cls: CharClass = party_member.actor_data().char_class
		if cls != null:
			for entry in cls.learnset:
				if entry == null or entry.skill == null:
					continue
				if entry.level <= party_member.level:
					out.append(entry.skill)
		return out
	for sk in enemy.skills:
		if sk != null:
			out.append(sk)
	return out


func clear_turn_flags() -> void:
	defending = false


func reset_atb(value: float = 0.0) -> void:
	atb = clampf(value, 0.0, 1.0)
