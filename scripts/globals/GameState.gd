extends Node

## Global game state: story flags, playtime, current map, last save slot.
## Persists across scene changes (autoloaded).

signal flag_changed(flag: StringName, value)

var flags: Dictionary = {}            # StringName -> Variant
var current_map_id: StringName = &""
var spawn_point_id: StringName = &""  # id of WarpTrigger / SpawnPoint to land on after transition
var playtime_seconds: float = 0.0
var last_save_slot: int = -1

# When a save is loaded, these hold the exact tile position to drop the player
# at (overrides spawn_point_id if has_loaded_position is true). Cleared by
# OverworldMap after consumption.
var loaded_player_grid_pos: Vector2i = Vector2i.ZERO
var loaded_player_facing: int = 0
var has_loaded_position: bool = false


func _process(delta: float) -> void:
	playtime_seconds += delta


func set_flag(flag: StringName, value = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: StringName, default = false):
	return flags.get(flag, default)


func reset() -> void:
	flags.clear()
	current_map_id = &""
	spawn_point_id = &""
	playtime_seconds = 0.0


func playtime_string() -> String:
	var t := int(playtime_seconds)
	return "%02d:%02d:%02d" % [t / 3600, (t / 60) % 60, t % 60]
