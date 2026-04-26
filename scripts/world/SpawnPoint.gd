@tool
extends Node2D

## A named landing position for the player. SceneRouter's go_to_map sets
## GameState.spawn_point_id; the destination map's _ready() finds the matching
## SpawnPoint and places the player on its grid_position.

@export var spawn_id: StringName = &"default"
@export var grid_position: Vector2i = Vector2i.ZERO
@export var facing: int = 0  # PlayerController.Facing.DOWN


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("spawn_points")
	position = OverworldMap.grid_to_world(grid_position)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	# Editor-only marker so spawn points are visible in the editor.
	draw_rect(Rect2(0, 0, OverworldMap.TILE_SIZE, OverworldMap.TILE_SIZE), Color(0, 1, 1, 0.35), true)
	draw_rect(Rect2(0, 0, OverworldMap.TILE_SIZE, OverworldMap.TILE_SIZE), Color(0, 1, 1, 1.0), false, 1.0)
