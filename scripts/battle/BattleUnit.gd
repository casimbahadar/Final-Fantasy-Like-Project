class_name BattleUnit
extends Node2D

## A combatant in a battle. Wraps either a PartyMember (for allies, persists
## back to Party state) or an Enemy resource (ephemeral). Holds runtime fields
## (hp, mp, atb gauge, status effects, defending) and exposes a uniform stat()
## API so DamageCalculator and AI don't care which side a unit is on.
##
## Status effects are stored as an array of {effect, turns_left} entries.
## stat() multiplies by every active status's stat_multiplier so callers see
## the buffed/debuffed numbers without knowing about statuses at all.

signal hp_changed(new_hp: int, max_hp: int)
signal mp_changed(new_mp: int, max_mp: int)
signal damaged(amount: int)
signal died
signal status_added(status_id: StringName)
signal status_removed(status_id: StringName)

enum Side { ALLY, ENEMY }

const HIT_FLASH_TIME := 0.15

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
## Array of {effect: StatusEffect, turns_left: int} dicts. Cleared on battle end.
var active_statuses: Array = []


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


func _base_stat(stat_name: String) -> int:
	if party_member != null:
		return party_member.stat(stat_name)
	return enemy.get(stat_name)


func stat(stat_name: String) -> int:
	var base := float(_base_stat(stat_name))
	for s in active_statuses:
		var effect: StatusEffect = s.get("effect")
		if effect == null:
			continue
		base *= effect.stat_multiplier(stat_name)
	return int(round(base))


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
	damaged.emit(amount)
	flash_hit()
	# Statuses like Sleep clear on any damage taken.
	_remove_damage_breaking_statuses()
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


# ---- Status effects ----------------------------------------------------------

func apply_status(status_id: StringName) -> bool:
	var effect: StatusEffect = Database.status(status_id)
	if effect == null:
		push_warning("BattleUnit.apply_status: unknown status %s" % status_id)
		return false
	# If already present, refresh duration to the higher of (current, new).
	for s in active_statuses:
		if s.effect.id == status_id:
			s.turns_left = maxi(s.turns_left, effect.duration_turns)
			queue_redraw()
			return true
	active_statuses.append({"effect": effect, "turns_left": effect.duration_turns})
	status_added.emit(status_id)
	queue_redraw()
	return true


func remove_status(status_id: StringName) -> bool:
	for i in active_statuses.size():
		if active_statuses[i].effect.id == status_id:
			active_statuses.remove_at(i)
			status_removed.emit(status_id)
			queue_redraw()
			return true
	return false


func has_status(status_id: StringName) -> bool:
	for s in active_statuses:
		if s.effect.id == status_id:
			return true
	return false


func is_skipping_turn() -> bool:
	for s in active_statuses:
		if s.effect.skip_turn:
			return true
	return false


func is_silenced() -> bool:
	for s in active_statuses:
		if s.effect.silence:
			return true
	return false


func is_attack_only() -> bool:
	for s in active_statuses:
		if s.effect.attack_only:
			return true
	return false


func is_confused() -> bool:
	for s in active_statuses:
		if s.effect.confuse:
			return true
	return false


func atb_rate_multiplier() -> float:
	var m := 1.0
	for s in active_statuses:
		m *= s.effect.atb_rate_mult
	return m


func accuracy_multiplier() -> float:
	var m := 1.0
	for s in active_statuses:
		m *= s.effect.accuracy_mult
	return m


func incoming_damage_multiplier() -> float:
	var m := 1.0
	for s in active_statuses:
		m *= s.effect.incoming_damage_mult
	return m


## Called at start of this unit's turn. Applies HP drain / regen, decrements
## duration, checks wake_chance for skip-turn statuses, removes expired ones.
## Returns a summary dictionary so the BattleManager can show the appropriate
## log lines and damage popups.
func tick_statuses() -> Dictionary:
	var result := {
		"hp_drained": 0,
		"hp_regened": 0,
		"mp_drained": 0,
		"mp_regened": 0,
		"woke_up": [],     # status ids that recovered via wake_chance
		"expired": [],     # status ids that hit duration 0
	}
	# Reverse iterate so removals are safe.
	for i in range(active_statuses.size() - 1, -1, -1):
		var s = active_statuses[i]
		var effect: StatusEffect = s.effect

		# HP drain (poison, burn).
		var drain := 0
		if effect.hp_drain_percent > 0.0:
			drain += int(round(float(max_hp()) * effect.hp_drain_percent))
		drain += effect.hp_drain_flat
		if drain > 0:
			hp = maxi(0, hp - drain)
			if party_member != null:
				party_member.hp = hp
			hp_changed.emit(hp, max_hp())
			result.hp_drained += drain

		# HP regen.
		var regen := 0
		if effect.hp_regen_percent > 0.0:
			regen += int(round(float(max_hp()) * effect.hp_regen_percent))
		regen += effect.hp_regen_flat
		if regen > 0 and hp > 0 and hp < max_hp():
			heal(regen)
			result.hp_regened += regen

		# MP drain.
		if effect.mp_drain_percent > 0.0:
			var mp_drain := int(round(float(max_mp()) * effect.mp_drain_percent))
			if mp_drain > 0:
				mp = maxi(0, mp - mp_drain)
				if party_member != null:
					party_member.mp = mp
				mp_changed.emit(mp, max_mp())
				result.mp_drained += mp_drain

		# MP regen.
		if effect.mp_regen_percent > 0.0:
			var mp_regen := int(round(float(max_mp()) * effect.mp_regen_percent))
			if mp_regen > 0:
				var got := restore_mp(mp_regen)
				result.mp_regened += got

		# Wake-from-sleep early roll.
		if effect.skip_turn and effect.wake_chance_per_turn > 0.0:
			if randf() < effect.wake_chance_per_turn:
				result.woke_up.append(effect.id)
				active_statuses.remove_at(i)
				status_removed.emit(effect.id)
				queue_redraw()
				continue

		# Decrement duration. -1 = until battle end / cured by item only.
		if s.turns_left > 0:
			s.turns_left -= 1
			if s.turns_left <= 0:
				result.expired.append(effect.id)
				active_statuses.remove_at(i)
				status_removed.emit(effect.id)
				queue_redraw()

	if hp == 0:
		died.emit()
	return result


func clear_statuses() -> void:
	for s in active_statuses:
		status_removed.emit(s.effect.id)
	active_statuses.clear()


func _remove_damage_breaking_statuses() -> void:
	for i in range(active_statuses.size() - 1, -1, -1):
		var s = active_statuses[i]
		if s.effect.remove_on_damage:
			active_statuses.remove_at(i)
			status_removed.emit(s.effect.id)


# ---- Visual feedback ---------------------------------------------------------

func flash_hit() -> void:
	if sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(2.5, 2.5, 2.5), HIT_FLASH_TIME * 0.4)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), HIT_FLASH_TIME * 0.6)


# Status badges drawn below the sprite. queue_redraw is called whenever the
# active list changes; otherwise this method is idle.
const _BADGE_Y := 26
const _BADGE_W := 9
const _BADGE_H := 9

func _draw() -> void:
	if active_statuses.is_empty():
		return
	var n := active_statuses.size()
	var total_w := n * _BADGE_W - 1
	var x := -total_w / 2
	var font := ThemeDB.fallback_font
	for s in active_statuses:
		var effect: StatusEffect = s.effect
		draw_rect(Rect2(x, _BADGE_Y, _BADGE_W - 1, _BADGE_H), effect.color, true)
		draw_rect(Rect2(x, _BADGE_Y, _BADGE_W - 1, _BADGE_H), Color(0, 0, 0, 0.6), false, 1.0)
		if font != null:
			draw_string(font, Vector2(x + 1, _BADGE_Y + _BADGE_H - 1), effect.glyph,
				HORIZONTAL_ALIGNMENT_LEFT, _BADGE_W - 1, 9, Color(0, 0, 0))
		x += _BADGE_W
