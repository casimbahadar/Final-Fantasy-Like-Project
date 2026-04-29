extends Node2D

## Story trigger fired by walking onto / interacting with a tile after a
## prerequisite flag is set. Plays dialogue, optionally recruits a party
## member, optionally sets a flag, and either:
##   - warps to another map (chapter transition), OR
##   - resets state and goes back to the title screen (true end-of-game).
##
## Despite the legacy name, this script handles both intermediate story
## beats (recruit + warp) and the final ending (no warp specified).

@export var grid_position: Vector2i = Vector2i.ZERO
## If set, only fires when this GameState flag is true.
@export var requires_flag: StringName = &""
## If set, this flag is set to true when the trigger fires successfully.
@export var sets_flag: StringName = &""
@export var lines: PackedStringArray = PackedStringArray()
@export var lines_locked: PackedStringArray = PackedStringArray()
@export var speaker: String = ""
## If set, adds this actor id to the party when the trigger fires.
@export var recruit_actor_id: StringName = &""
## If set, warps to this map after firing instead of returning to title.
@export var warp_target_map: StringName = &""
@export var warp_target_spawn: StringName = &"default"
## When true and no warp_target_map is set, this is the "true ending" — resets
## state and returns to the title screen.
@export var is_ending: bool = false
## Optional item granted when the trigger fires successfully.
@export var grants_item: StringName = &""
@export var grants_item_count: int = 1
@export var grants_gold: int = 0

var _map: OverworldMap
var _firing: bool = false


func _ready() -> void:
	var p := get_parent()
	while p != null and not (p is OverworldMap):
		p = p.get_parent()
	_map = p
	if _map == null:
		return
	position = OverworldMap.grid_to_world(grid_position)
	_map.register_occupant(grid_position, self)


func interact(_player) -> void:
	_fire()


func on_bump(_player) -> void:
	_fire()


func _fire() -> void:
	if _firing:
		return
	if requires_flag != &"" and not GameState.get_flag(requires_flag, false):
		var locked := lines_locked
		if locked.is_empty():
			locked = PackedStringArray(["The crystal flickers, but does not respond."])
		await Dialogue.say(Array(locked), speaker)
		return
	# One-shot guard: if the trigger has already fired (sets_flag is set),
	# don't replay the dialogue or re-warp on re-entry.
	if sets_flag != &"" and GameState.get_flag(sets_flag, false):
		return
	_firing = true
	if lines.size() > 0:
		await Dialogue.say(Array(lines), speaker)
	if recruit_actor_id != &"":
		# Don't add the same actor twice (e.g. on save/load reentry).
		var already := false
		for pm in Party.members:
			if pm.actor_id == recruit_actor_id:
				already = true
				break
		if not already:
			Party.add_member(recruit_actor_id)
	if grants_item != &"":
		Party.add_item(grants_item, grants_item_count)
	if grants_gold > 0:
		Party.add_gold(grants_gold)
	if sets_flag != &"":
		GameState.set_flag(sets_flag, true)
	if warp_target_map != &"":
		# Chapter transition — keep state, go to the next map.
		await SceneRouter.go_to_map(warp_target_map, warp_target_spawn)
	elif is_ending:
		GameState.reset()
		Party.clear()
		await SceneRouter.go_to_scene("res://scenes/ui/TitleScreen.tscn")
	else:
		# Plain story trigger — leave the player where they are.
		_firing = false
