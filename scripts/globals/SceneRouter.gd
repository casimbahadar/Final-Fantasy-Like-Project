extends Node

## Centralized scene transitions with a fade-to-black.
## Use SceneRouter.go_to_map(map_id, spawn_point_id) instead of get_tree().change_scene_to_file
## so we keep GameState.current_map_id and BGM in sync.

const FADE_TIME := 0.35

signal transition_started
signal transition_finished

# Transient handoff for battle scene (not persisted in saves).
var pending_troop_id: StringName = &""
var battle_return_map: StringName = &""
var battle_return_grid_pos: Vector2i = Vector2i.ZERO
var battle_return_facing: int = 0
## If set, BattleManager sets this GameState flag true on victory.
## Used by EncounterTrigger to mark a fixed/boss battle as defeated.
var battle_victory_flag: StringName = &""

# True from the start of fade-out until fade-in completes. Gameplay code reads
# this to suppress input during transitions.
var is_transitioning: bool = false

var _fade: ColorRect


func _ready() -> void:
	# Build a CanvasLayer with a full-screen black ColorRect for fades.
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func go_to_scene(scene_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	transition_started.emit()
	await _fade_to(1.0)
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneRouter: change_scene_to_file failed for %s (err %d)" % [scene_path, err])
	await _fade_to(0.0)
	is_transitioning = false
	transition_finished.emit()


func go_to_map(map_id: StringName, spawn_point_id: StringName = &"") -> void:
	var map_data: MapData = Database.map(map_id)
	if map_data == null:
		push_error("SceneRouter: unknown map %s" % map_id)
		return
	GameState.current_map_id = map_id
	GameState.spawn_point_id = spawn_point_id
	if map_data.bgm != null:
		AudioManager.play_bgm(map_data.bgm)
	await go_to_scene(map_data.scene_path)


func go_to_battle(troop_id: StringName, return_map_id: StringName) -> void:
	var troop: Troop = Database.troop(troop_id)
	if troop == null:
		push_error("SceneRouter: unknown troop %s" % troop_id)
		return
	pending_troop_id = troop_id
	battle_return_map = return_map_id
	if troop.battle_bgm != null:
		AudioManager.play_bgm(troop.battle_bgm)
	await go_to_scene("res://scenes/battle/Battle.tscn")


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished
