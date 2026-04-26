extends Node2D

## A tile (or rectangle of tiles) that warps the player to another map when
## they step onto it. Connects to the player's `moved` signal.

@export var grid_position: Vector2i = Vector2i.ZERO
## How many tiles wide/tall this warp is (defaults to 1x1).
@export var grid_size: Vector2i = Vector2i.ONE
@export var target_map_id: StringName = &""
@export var target_spawn_id: StringName = &"default"
## Optional flag that must be true for the warp to fire (e.g., quest gates).
@export var requires_flag: StringName = &""

var _map: OverworldMap
var _player: Node


func _ready() -> void:
	add_to_group("warps")
	var p := get_parent()
	while p != null and not (p is OverworldMap):
		p = p.get_parent()
	_map = p
	position = OverworldMap.grid_to_world(grid_position)


func attach_player(player: Node) -> void:
	if _player == player:
		return
	if is_instance_valid(_player) and _player.is_connected("moved", _on_player_moved):
		_player.moved.disconnect(_on_player_moved)
	_player = player
	if is_instance_valid(_player):
		_player.moved.connect(_on_player_moved)


func _on_player_moved(_from: Vector2i, to: Vector2i) -> void:
	var rect := Rect2i(grid_position, grid_size)
	if not rect.has_point(to):
		return
	if requires_flag != &"" and not GameState.get_flag(requires_flag, false):
		return
	if target_map_id == &"":
		push_warning("WarpTrigger has no target_map_id set")
		return
	if is_instance_valid(_player) and _player.is_connected("moved", _on_player_moved):
		_player.moved.disconnect(_on_player_moved)
	_player = null
	SceneRouter.go_to_map(target_map_id, target_spawn_id)
