extends Node2D

## Fires a fixed (story / boss) battle when the player steps into / bumps it.
## After the battle is won, sets `defeated_flag` so the trigger stays inactive,
## letting the player walk through.

@export var grid_position: Vector2i = Vector2i.ZERO
@export var troop_id: StringName = &""
@export var defeated_flag: StringName = &""
## Optional pre-fight dialogue. Lines are read sequentially.
@export var intro_lines: PackedStringArray = PackedStringArray()
@export var intro_speaker: String = ""

var _map: OverworldMap
var _firing: bool = false


func _ready() -> void:
	var p := get_parent()
	while p != null and not (p is OverworldMap):
		p = p.get_parent()
	_map = p
	if _map == null:
		push_warning("EncounterTrigger has no OverworldMap ancestor")
		return
	position = OverworldMap.grid_to_world(grid_position)
	if _is_defeated():
		hide()
		return
	_map.register_occupant(grid_position, self)


func _is_defeated() -> bool:
	if defeated_flag == &"":
		return false
	return GameState.get_flag(defeated_flag, false)


func interact(_player) -> void:
	_fire()


func on_bump(_player) -> void:
	_fire()


func _fire() -> void:
	if _firing or _is_defeated():
		return
	_firing = true
	if intro_lines.size() > 0:
		await Dialogue.say(Array(intro_lines), intro_speaker)
	# Save player position so battle return drops them right here.
	if _map.player != null:
		SceneRouter.battle_return_map = _map.map_id
		SceneRouter.battle_return_grid_pos = _map.player.grid_pos
		SceneRouter.battle_return_facing = _map.player.facing
	# Tag the troop run so BattleManager can mark this trigger defeated on win.
	SceneRouter.battle_victory_flag = defeated_flag
	SceneRouter.go_to_battle(troop_id, _map.map_id)
