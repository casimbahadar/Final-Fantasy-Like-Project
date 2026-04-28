extends Node2D

## Touched after the final boss is defeated. Plays the ending dialogue, then
## resets state and routes to the title screen.

@export var grid_position: Vector2i = Vector2i.ZERO
@export var requires_flag: StringName = &""
@export var lines: PackedStringArray = PackedStringArray()
@export var speaker: String = ""

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
		await Dialogue.say(["The crystal flickers, but does not respond."], speaker)
		return
	_firing = true
	if lines.size() > 0:
		await Dialogue.say(Array(lines), speaker)
	GameState.reset()
	Party.clear()
	await SceneRouter.go_to_scene("res://scenes/ui/TitleScreen.tscn")
