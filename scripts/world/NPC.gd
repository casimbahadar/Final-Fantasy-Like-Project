extends Node2D

## Static NPC sitting on a tile. Talks via the Dialogue autoload. Faces the
## player when interacted. Optional once-only flag to disable repeat dialogue
## or run a different line set after the first conversation.

@export var npc_name: String = ""
@export var grid_position: Vector2i = Vector2i.ZERO
@export var lines: PackedStringArray = PackedStringArray()
## Optional: lines spoken on every interaction after the first.
@export var lines_after_first: PackedStringArray = PackedStringArray()
## Optional: GameState flag set true after first interaction.
@export var conversation_flag: StringName = &""
## Optional override for the placeholder villager sprite.
@export var sprite_texture: Texture2D

## If non-empty, interacting opens a shop with these items for sale.
@export var shop_inventory: Array[StringName] = []
## If > 0, interacting offers an inn stay (full heal) for this many gold.
@export var inn_cost: int = 0
## If set, the actor with this id joins the party after the first conversation
## (skipped if they're already in the party). Pair with conversation_flag so
## the recruit only happens once.
@export var recruit_actor_id: StringName = &""

@export_group("Quest")
## If non-empty, the quest is hidden until this flag is set on GameState.
## Used to gate sidequests behind story progress (e.g. chapter completion).
@export var quest_required_flag: StringName = &""
## Set true the first time the player accepts the quest (after offer_lines).
@export var quest_accept_flag: StringName = &""
## Set externally (chest, encounter, hunt count) when the objective is met.
## When set and accept_flag is set, the NPC moves to the reward branch.
@export var quest_objective_flag: StringName = &""
## Set true after the player claims the reward.
@export var quest_reward_flag: StringName = &""
## Optional: must have this many of an item; consumed on reward.
@export var quest_required_item: StringName = &""
@export var quest_required_item_count: int = 1
## Optional kill-count gate. The reward is unlocked when the Hunt singleton
## reports at least this many kills of the named enemy id (in addition to
## quest_objective_flag, if also set).
@export var quest_required_kill_enemy: StringName = &""
@export var quest_required_kill_count: int = 0
## Lines spoken when the quest is first offered (before accept_flag is set).
@export var quest_offer_lines: PackedStringArray = PackedStringArray()
## Lines spoken while the quest is in progress (accept set, objective unmet).
@export var quest_progress_lines: PackedStringArray = PackedStringArray()
## Lines spoken when objective is met and the reward is being granted.
@export var quest_complete_lines: PackedStringArray = PackedStringArray()
## Lines spoken on every interaction after the reward is claimed.
@export var quest_done_lines: PackedStringArray = PackedStringArray()
## Reward granted on completion.
@export var quest_reward_item: StringName = &""
@export var quest_reward_item_count: int = 1
@export var quest_reward_gold: int = 0
## If set, this flag is set on GameState when the reward is claimed (separate
## from quest_reward_flag, which is the bookkeeping flag — useful for unlocking
## downstream content like the postgame dungeon).
@export var quest_unlock_flag: StringName = &""

@onready var sprite: Sprite2D = $Sprite2D

var _map: OverworldMap
var _facing: int = 0  # PlayerController.Facing.DOWN


func _ready() -> void:
	# Snap to grid using parent map (assumed to be the OverworldMap root).
	var p := get_parent()
	while p != null and not (p is OverworldMap):
		p = p.get_parent()
	_map = p
	if _map == null:
		push_warning("NPC '%s' has no OverworldMap ancestor" % npc_name)
		return
	position = OverworldMap.grid_to_world(grid_position)
	if sprite_texture != null:
		sprite.texture = sprite_texture
	_map.register_occupant(grid_position, self)


func interact(player) -> void:
	if Dialogue.is_active:
		return

	# Face the player.
	if player != null:
		var d := player.grid_pos - grid_position
		_face(d)
		# And player faces us.
		if player.has_method("face_toward"):
			player.face_toward(grid_position)

	# Quest flow takes priority when configured (and not gated out). After the
	# quest is fully claimed we fall through to normal shop/inn behaviour so
	# vendor NPCs keep working as vendors — but the post-quest greeting (if
	# any) replaces the original `lines` so the dialogue doesn't double up.
	var post_quest_greet := false
	if _quest_active():
		if _quest_claimed():
			post_quest_greet = true
		else:
			await _run_quest_flow()
			return

	var to_say: PackedStringArray = lines
	if post_quest_greet and quest_done_lines.size() > 0:
		to_say = quest_done_lines
	elif conversation_flag != &"" and GameState.get_flag(conversation_flag, false):
		if lines_after_first.size() > 0:
			to_say = lines_after_first

	# Capture whether this is the very first conversation BEFORE we set the
	# flag, so a one-shot recruit fires exactly once.
	var first_time := conversation_flag != &"" and not GameState.get_flag(conversation_flag, false)

	if to_say.size() > 0:
		await Dialogue.say(Array(to_say), npc_name)

	if conversation_flag != &"":
		GameState.set_flag(conversation_flag, true)

	# Recruit on first conversation (idempotent — won't re-add).
	if first_time and recruit_actor_id != &"":
		var already := false
		for pm in Party.members:
			if pm.actor_id == recruit_actor_id:
				already = true
				break
		if not already:
			Party.add_member(recruit_actor_id)

	# After the greeting (if any), branch into shop or inn flow if configured.
	if shop_inventory.size() > 0:
		Shop.open(shop_inventory, npc_name)
	elif inn_cost > 0:
		await _offer_inn()


func _quest_active() -> bool:
	if quest_accept_flag == &"":
		return false
	if quest_required_flag != &"" and not GameState.get_flag(quest_required_flag, false):
		return false
	return true


func _quest_claimed() -> bool:
	return quest_reward_flag != &"" and GameState.get_flag(quest_reward_flag, false)


func _objective_met() -> bool:
	# Both objective_flag (if set) and kill-count (if set) must be satisfied.
	# Empty fields are treated as "not gating".
	if quest_objective_flag != &"" and not GameState.get_flag(quest_objective_flag, false):
		return false
	if quest_required_kill_enemy != &"" and quest_required_kill_count > 0:
		if not Hunt.has_killed_at_least(quest_required_kill_enemy, quest_required_kill_count):
			return false
	if quest_required_item != &"" and not Party.has_item(quest_required_item, quest_required_item_count):
		return false
	# If none of the gates are configured, treat objective as met (instant
	# turn-in quest — useful for "deliver this letter" with no real gate).
	return true


func _run_quest_flow() -> void:
	# Phase 2: accepted but not yet complete.
	if GameState.get_flag(quest_accept_flag, false):
		if _objective_met():
			# Grant reward.
			if quest_complete_lines.size() > 0:
				await Dialogue.say(Array(quest_complete_lines), npc_name)
			if quest_required_item != &"":
				Party.remove_item(quest_required_item, quest_required_item_count)
			if quest_reward_item != &"":
				Party.add_item(quest_reward_item, quest_reward_item_count)
				var item: Item = Database.item(quest_reward_item)
				var label := item.display_name if item != null else String(quest_reward_item)
				if quest_reward_item_count > 1:
					await Dialogue.say(["Got %d × %s!" % [quest_reward_item_count, label]], npc_name)
				else:
					await Dialogue.say(["Got %s!" % label], npc_name)
			if quest_reward_gold > 0:
				Party.add_gold(quest_reward_gold)
				await Dialogue.say(["Got %d gold!" % quest_reward_gold], npc_name)
			GameState.set_flag(quest_reward_flag, true)
			if quest_unlock_flag != &"":
				GameState.set_flag(quest_unlock_flag, true)
		else:
			if quest_progress_lines.size() > 0:
				await Dialogue.say(Array(quest_progress_lines), npc_name)
		return

	# Phase 3: first encounter — offer the quest.
	if quest_offer_lines.size() > 0:
		await Dialogue.say(Array(quest_offer_lines), npc_name)
	GameState.set_flag(quest_accept_flag, true)


func _offer_inn() -> void:
	if Party.gold < inn_cost:
		await Dialogue.say(["You haven't got %d gold." % inn_cost], npc_name)
		return
	var idx := await Dialogue.choose("Stay the night for %d gold?" % inn_cost, ["Cancel", "Stay"], true)
	if idx != 1:
		return
	Party.add_gold(-inn_cost)
	for pm in Party.members:
		pm.hp = pm.max_hp()
		pm.mp = pm.max_mp()
	await Dialogue.say(["The party rests. HP and MP fully restored."], npc_name)


func on_bump(player) -> void:
	# Walking into an NPC also starts dialogue (FF convention).
	interact(player)


func _face(dir: Vector2i) -> void:
	# We don't have directional sprites yet; just track for future use.
	if dir == Vector2i.ZERO:
		return
	if absi(dir.x) >= absi(dir.y):
		_facing = 2 if dir.x > 0 else 1  # RIGHT, LEFT
	else:
		_facing = 0 if dir.y > 0 else 3  # DOWN, UP
