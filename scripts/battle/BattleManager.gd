extends Node2D

## Battle scene root and orchestrator. State machine drives the ATB loop:
##
##   INTRO  → "Encountered <troop>!" message, then ACTIVE
##   ACTIVE → all alive units' ATB gauges tick. First to 1.0 triggers unit_ready.
##   INPUT  → ally is ready; ActionMenu / target picker await player choice.
##   RESOLVE→ skill is being executed: damage popups, log line, brief delay.
##   VICTORY/DEFEAT → outcome screens. Then EXITING returns control.
##
## The ATB loop deliberately runs in _process and stops processing the moment
## any unit hits 1.0, so multiple gauges never fill on the same frame.

const BATTLE_UNIT_SCENE := preload("res://scenes/battle/BattleUnit.tscn")
const DAMAGE_POPUP_SCENE := preload("res://scenes/ui/DamagePopup.tscn")

const ATB_BASE_RATE := 0.30  # gauge fraction per second at spd=10
const RESOLVE_HOLD := 0.55   # seconds to hold the log line after an action
const ENEMY_TURN_DELAY := 0.4
const ALLY_X := 360
const ALLY_BASE_Y := 80
const ALLY_Y_SPACING := 32

enum State { INTRO, ACTIVE, INPUT, RESOLVE, VICTORY, DEFEAT, EXITING }

@onready var enemies_root: Node2D = $Foreground/EnemiesRoot
@onready var allies_root: Node2D = $Foreground/AlliesRoot
@onready var party_panel = $UI/PartyPanel
@onready var action_menu = $UI/ActionMenu
@onready var submenu = $UI/SubMenu
@onready var target_cursor = $TargetCursor
@onready var battle_log: Label = $UI/BattleLog
@onready var reward_screen: Control = $UI/RewardScreen
@onready var reward_label: Label = $UI/RewardScreen/Panel/Label
@onready var game_over_screen: Control = $UI/GameOverScreen
@onready var continue_button: Button = %ContinueButton
@onready var title_button: Button = %TitleButton

var state: State = State.INTRO
var allies: Array = []     # Array[BattleUnit]
var enemies: Array = []    # Array[BattleUnit]
var pending_action_unit: BattleUnit = null
var troop: Troop = null


func _ready() -> void:
	troop = Database.troop(SceneRouter.pending_troop_id)
	if troop == null:
		push_error("Battle: no troop set in SceneRouter")
		_return_to_overworld()
		return

	_build_units()
	party_panel.bind_units(allies)
	action_menu.hide()
	submenu.hide()
	target_cursor.hide()
	reward_screen.hide()
	game_over_screen.hide()
	battle_log.text = ""

	action_menu.command_chosen.connect(_on_command_chosen)
	action_menu.cancelled.connect(_on_action_menu_cancelled)
	submenu.entry_chosen.connect(_on_submenu_chosen)
	submenu.cancelled.connect(_on_submenu_cancelled)

	await _show_intro()
	if not allies.any(func(u): return u.is_alive()):
		# (Should never happen at battle start, but be safe.)
		_enter_defeat()
		return
	_change_state(State.ACTIVE)


# ----------------------------- State machine ----------------------------------

func _change_state(new_state: int) -> void:
	state = new_state


func _process(delta: float) -> void:
	if state != State.ACTIVE:
		return
	# If anyone already at full gauge, wait for handler to consume them.
	for u in allies + enemies:
		if u.is_alive() and u.atb >= 1.0:
			return
	for u in allies + enemies:
		if not u.is_alive():
			continue
		var rate := ATB_BASE_RATE * (float(u.stat("spd")) / 10.0)
		u.atb = minf(1.0, u.atb + rate * delta)
		if u.atb >= 1.0:
			_on_unit_ready(u)
			return
	party_panel.refresh()


func _on_unit_ready(unit: BattleUnit) -> void:
	pending_action_unit = unit
	party_panel.refresh()
	if unit.is_ally():
		_change_state(State.INPUT)
		party_panel.highlight_unit(unit)
		action_menu.open(unit)
	else:
		await _resolve_enemy_turn(unit)


# ----------------------------- Action resolution ------------------------------

func _resolve_enemy_turn(unit: BattleUnit) -> void:
	_change_state(State.RESOLVE)
	await get_tree().create_timer(ENEMY_TURN_DELAY).timeout
	var action := EnemyAI.choose_action(unit, enemies, allies)
	if action.is_empty():
		_log("%s hesitates." % unit.display_name())
		await get_tree().create_timer(RESOLVE_HOLD).timeout
		_post_action()
		return
	await _resolve_skill(unit, action.skill, action.target)
	_post_action()


func _on_command_chosen(command: StringName, _payload) -> void:
	if pending_action_unit == null:
		return
	match command:
		&"attack":
			action_menu.hide()
			var atk := Database.skill(&"attack")
			var target = await _pick_target(atk, pending_action_unit)
			if target == null:
				_reopen_action_menu()
				return
			await _begin_player_resolve(atk, target)
		&"skill":
			action_menu.hide()
			submenu.open_skills(pending_action_unit)
		&"item":
			action_menu.hide()
			submenu.open_items(pending_action_unit)
		&"defend":
			action_menu.hide()
			pending_action_unit.defending = true
			_log("%s defends." % pending_action_unit.display_name())
			_change_state(State.RESOLVE)
			await get_tree().create_timer(RESOLVE_HOLD).timeout
			_post_action()
		&"run":
			action_menu.hide()
			await _attempt_escape()


func _on_action_menu_cancelled() -> void:
	# Intentionally a no-op: top-level command menu doesn't cancel.
	pass


func _on_submenu_chosen(kind: StringName, payload) -> void:
	if pending_action_unit == null:
		return
	if kind == &"skill":
		var skill: Skill = payload
		var target = await _pick_target(skill, pending_action_unit)
		if target == null:
			submenu.refocus()
			return
		await _begin_player_resolve(skill, target)
	elif kind == &"item":
		var item_id: StringName = payload
		var item: Item = Database.item(item_id)
		if item == null:
			return
		var target = await _pick_item_target(item, pending_action_unit)
		if target == null:
			submenu.refocus()
			return
		await _begin_item_resolve(item_id, item, target)


func _on_submenu_cancelled() -> void:
	_reopen_action_menu()


func _begin_player_resolve(skill: Skill, target: BattleUnit) -> void:
	action_menu.hide()
	submenu.hide()
	if skill.mp_cost > pending_action_unit.mp:
		_log("Not enough MP!")
		await get_tree().create_timer(RESOLVE_HOLD).timeout
		_reopen_action_menu()
		return
	_change_state(State.RESOLVE)
	await _resolve_skill(pending_action_unit, skill, target)
	_post_action()


func _begin_item_resolve(item_id: StringName, item: Item, target: BattleUnit) -> void:
	action_menu.hide()
	submenu.hide()
	if not Party.remove_item(item_id):
		_log("Out of %s!" % item.display_name)
		await get_tree().create_timer(RESOLVE_HOLD).timeout
		_reopen_action_menu()
		return
	_change_state(State.RESOLVE)
	_log("%s uses %s." % [pending_action_unit.display_name(), item.display_name])
	if item.heal_hp > 0:
		var got_hp := target.heal(item.heal_hp)
		_spawn_popup(target, "+%d" % got_hp, Color(0.4, 0.95, 0.4))
	if item.heal_mp > 0:
		var got_mp := target.restore_mp(item.heal_mp)
		_spawn_popup(target, "+%d MP" % got_mp, Color(0.5, 0.7, 1.0))
	await get_tree().create_timer(RESOLVE_HOLD).timeout
	_post_action()


func _resolve_skill(actor: BattleUnit, skill: Skill, target: BattleUnit) -> void:
	if skill.mp_cost > 0:
		actor.use_mp(skill.mp_cost)
	var msg: String
	if skill.damage_kind == Skill.DamageKind.PHYSICAL:
		msg = "%s attacks!" % actor.display_name()
	else:
		msg = "%s casts %s." % [actor.display_name(), skill.display_name]
	_log(msg)

	var targets := _resolve_targets(skill, actor, target)
	for t: BattleUnit in targets:
		var r := DamageCalculator.compute(actor, t, skill)
		_apply_result(t, r)
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(RESOLVE_HOLD).timeout


func _resolve_targets(skill: Skill, actor: BattleUnit, primary: BattleUnit) -> Array:
	match skill.target_kind:
		Skill.TargetKind.ENEMY_ALL:
			return _alive_on(_opposite_side(actor))
		Skill.TargetKind.ALLY_ALL:
			return _alive_on(_same_side(actor))
		Skill.TargetKind.SELF:
			return [actor]
		_:
			return [primary] if primary != null and primary.is_alive() else []


func _apply_result(target: BattleUnit, r: Dictionary) -> void:
	if r.miss:
		_spawn_popup(target, "MISS", Color(0.95, 0.85, 0.4))
		return
	if r.damage > 0:
		var dealt := target.take_damage(r.damage)
		var col := Color(1.0, 0.55, 0.4) if r.crit else Color(1.0, 1.0, 1.0)
		var label := str(dealt)
		if r.crit:
			label += "!"
		_spawn_popup(target, label, col)
	elif r.damage < 0:
		var amt := -r.damage
		target.heal(amt)
		var col2 := Color(0.4, 0.6, 1.0) if r.absorbed else Color(0.4, 0.95, 0.4)
		var prefix := "" if r.absorbed else "+"
		_spawn_popup(target, "%s%d" % [prefix, amt], col2)


func _post_action() -> void:
	if pending_action_unit != null:
		pending_action_unit.atb = 0.0
		pending_action_unit.clear_turn_flags()
		pending_action_unit = null
	party_panel.clear_highlight()
	party_panel.refresh()
	if _check_outcome():
		return
	_change_state(State.ACTIVE)


func _reopen_action_menu() -> void:
	if pending_action_unit == null:
		return
	_change_state(State.INPUT)
	action_menu.open(pending_action_unit)


# ----------------------------- Targeting --------------------------------------

func _pick_target(skill: Skill, actor: BattleUnit):
	if skill.target_kind == Skill.TargetKind.SELF:
		return actor
	var enemy_side := skill.target_kind == Skill.TargetKind.ENEMY_SINGLE or skill.target_kind == Skill.TargetKind.ENEMY_ALL
	var pool := _alive_on(_opposite_side(actor) if enemy_side else _same_side(actor))
	if pool.is_empty():
		return null
	if skill.target_kind == Skill.TargetKind.ENEMY_ALL or skill.target_kind == Skill.TargetKind.ALLY_ALL:
		return pool[0]  # AOE; _resolve_targets will fan out from any alive unit.
	return await target_cursor.pick(pool)


func _pick_item_target(item: Item, actor: BattleUnit):
	# Most items target allies (potions). Damage-items would target enemies.
	var pool: Array = _alive_on(_same_side(actor)) if (item.heal_hp > 0 or item.heal_mp > 0 or item.revives) else _alive_on(_opposite_side(actor))
	if pool.is_empty():
		return null
	return await target_cursor.pick(pool)


# ----------------------------- Outcome ----------------------------------------

func _check_outcome() -> bool:
	if not allies.any(func(u): return u.is_alive()):
		_enter_defeat()
		return true
	if not enemies.any(func(u): return u.is_alive()):
		_enter_victory()
		return true
	return false


func _enter_victory() -> void:
	_change_state(State.VICTORY)
	var xp_total := 0
	var gold_total := 0
	var drops: Array[StringName] = []
	for e in enemies:
		var ed: Enemy = e.enemy
		xp_total += ed.xp_reward
		gold_total += ed.gold_reward
		if ed.drop_item != null and randf() < ed.drop_chance:
			drops.append(ed.drop_item.id)
	Party.add_gold(gold_total)
	for d in drops:
		Party.add_item(d, 1)
	var leveled := PackedStringArray()
	for ally in allies:
		if ally.party_member != null and ally.is_alive():
			var gained := ally.party_member.gain_xp(xp_total)
			if gained > 0:
				leveled.append("%s reached level %d!" % [ally.display_name(), ally.party_member.level])
			# Refresh hp/mp post-heal-on-level
			ally.hp = ally.party_member.hp
			ally.mp = ally.party_member.mp
	var lines := PackedStringArray()
	lines.append("Victory!")
	lines.append("EXP +%d   Gold +%d" % [xp_total, gold_total])
	for d in drops:
		var it: Item = Database.item(d)
		if it != null:
			lines.append("Got %s!" % it.display_name)
	for l in leveled:
		lines.append(l)
	lines.append("")
	lines.append("Press confirm to continue.")
	reward_label.text = "\n".join(lines)
	reward_screen.show()
	await _await_confirm()
	_return_to_overworld()


func _enter_defeat() -> void:
	_change_state(State.DEFEAT)
	game_over_screen.show()
	# Continue is only available if there's at least one save slot.
	var any_save := false
	for slot in SaveSystem.SLOT_COUNT:
		if SaveSystem.slot_exists(slot):
			any_save = true
			break
	continue_button.disabled = not any_save
	if any_save:
		continue_button.grab_focus()
	else:
		title_button.grab_focus()
	var picked_continue := await _await_game_over_choice()
	if picked_continue:
		await _load_most_recent_save()
	else:
		GameState.reset()
		Party.clear()
		await SceneRouter.go_to_scene("res://scenes/ui/TitleScreen.tscn")


func _await_game_over_choice() -> bool:
	# Race the two buttons; whichever fires first wins.
	var result := [false, false]  # [picked, picked_continue]
	var on_continue := func():
		if not result[0]:
			result[0] = true
			result[1] = true
	var on_title := func():
		if not result[0]:
			result[0] = true
			result[1] = false
	continue_button.pressed.connect(on_continue)
	title_button.pressed.connect(on_title)
	while not result[0]:
		await get_tree().process_frame
	# Tear down the listeners so we don't fire twice if the scene lingers.
	if continue_button.pressed.is_connected(on_continue):
		continue_button.pressed.disconnect(on_continue)
	if title_button.pressed.is_connected(on_title):
		title_button.pressed.disconnect(on_title)
	return result[1]


func _load_most_recent_save() -> void:
	var best_slot := -1
	var best_ts := 0
	for slot in SaveSystem.SLOT_COUNT:
		if not SaveSystem.slot_exists(slot):
			continue
		var s := SaveSystem.slot_summary(slot)
		var ts := int(s.get("timestamp", 0))
		if ts >= best_ts:
			best_ts = ts
			best_slot = slot
	if best_slot < 0:
		GameState.reset()
		Party.clear()
		await SceneRouter.go_to_scene("res://scenes/ui/TitleScreen.tscn")
		return
	if not SaveSystem.load_from(best_slot):
		await SceneRouter.go_to_scene("res://scenes/ui/TitleScreen.tscn")
		return
	if GameState.current_map_id != &"":
		await SceneRouter.go_to_map(GameState.current_map_id, GameState.spawn_point_id)
	else:
		await SceneRouter.go_to_scene("res://scenes/ui/TitleScreen.tscn")


func _attempt_escape() -> void:
	_change_state(State.RESOLVE)
	if troop.no_escape:
		_log("Cannot escape!")
		await get_tree().create_timer(RESOLVE_HOLD).timeout
		_post_action()
		return
	var party_spd := 0
	var enemy_spd := 0
	for u in allies:
		if u.is_alive():
			party_spd += u.stat("spd")
	for u in enemies:
		if u.is_alive():
			enemy_spd += u.stat("spd")
	var chance := 0.5 + 0.05 * float(party_spd - enemy_spd)
	chance = clampf(chance, 0.1, 0.95)
	if randf() < chance:
		_log("Got away safely!")
		await get_tree().create_timer(RESOLVE_HOLD).timeout
		_change_state(State.EXITING)
		_return_to_overworld()
	else:
		_log("Couldn't escape!")
		await get_tree().create_timer(RESOLVE_HOLD).timeout
		_post_action()


func _return_to_overworld() -> void:
	_change_state(State.EXITING)
	var return_map := SceneRouter.battle_return_map
	SceneRouter.pending_troop_id = &""
	if return_map == &"":
		await SceneRouter.go_to_scene("res://scenes/ui/TitleScreen.tscn")
	else:
		# Special spawn id signals OverworldMap to use the saved battle return pos.
		await SceneRouter.go_to_map(return_map, &"_battle_return")


# ----------------------------- Helpers ----------------------------------------

func _build_units() -> void:
	allies.clear()
	enemies.clear()

	var alive_party: Array = []
	for pm in Party.members:
		if pm.is_alive():
			alive_party.append(pm)
	for i in alive_party.size():
		var pm = alive_party[i]
		var u: BattleUnit = BATTLE_UNIT_SCENE.instantiate()
		allies_root.add_child(u)
		u.bind_ally(pm)
		u.position = Vector2(ALLY_X, ALLY_BASE_Y + i * ALLY_Y_SPACING)
		u.sprite.texture = u.get_battle_sprite()
		u.atb = randf() * 0.4  # stagger initial gauges so turns aren't synchronized
		allies.append(u)

	for tm: TroopMember in troop.members:
		if tm == null or tm.enemy == null:
			continue
		var u: BattleUnit = BATTLE_UNIT_SCENE.instantiate()
		enemies_root.add_child(u)
		u.bind_enemy(tm.enemy)
		u.position = tm.screen_position
		u.sprite.texture = u.get_battle_sprite()
		u.atb = randf() * 0.3
		enemies.append(u)


func _show_intro() -> void:
	var names := PackedStringArray()
	for u in enemies:
		names.append(u.display_name())
	_log("Encountered %s!" % ", ".join(names))
	await get_tree().create_timer(0.9).timeout
	battle_log.text = ""


func _log(msg: String) -> void:
	battle_log.text = msg


func _spawn_popup(unit: BattleUnit, text: String, color: Color) -> void:
	var p := DAMAGE_POPUP_SCENE.instantiate()
	$DamagePopupLayer.add_child(p)
	p.position = unit.position + Vector2(0, -8)
	p.show_text(text, color)


func _alive_on(side: int) -> Array:
	var pool: Array = []
	var src: Array = allies if side == BattleUnit.Side.ALLY else enemies
	for u in src:
		if u.is_alive():
			pool.append(u)
	return pool


func _same_side(u: BattleUnit) -> int:
	return u.side


func _opposite_side(u: BattleUnit) -> int:
	return BattleUnit.Side.ENEMY if u.side == BattleUnit.Side.ALLY else BattleUnit.Side.ALLY


func _await_confirm() -> void:
	# Wait for the next ui_accept or ui_cancel press.
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
			return
