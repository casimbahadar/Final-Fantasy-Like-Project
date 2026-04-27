extends Node2D

## Grid-snapped player controller. Smooth-tweens between tiles. Reads input only
## while not already moving and not while a Dialogue is open. On ui_accept,
## interacts with whatever occupies the tile the player is facing.

const MOVE_TIME := 0.16

enum Facing { DOWN, LEFT, RIGHT, UP }

const FACING_DIRS := {
	Facing.DOWN:  Vector2i(0, 1),
	Facing.LEFT:  Vector2i(-1, 0),
	Facing.RIGHT: Vector2i(1, 0),
	Facing.UP:    Vector2i(0, -1),
}

signal moved(from_pos: Vector2i, to_pos: Vector2i)
signal stepped_on_encounter_tile

@onready var sprite: Sprite2D = $Sprite2D

var grid_pos: Vector2i = Vector2i.ZERO
var facing: int = Facing.DOWN
var _moving: bool = false
var _map: OverworldMap


func setup(map: OverworldMap, start_grid: Vector2i, start_facing: int = Facing.DOWN, sprite_texture: Texture2D = null) -> void:
	_map = map
	grid_pos = start_grid
	facing = start_facing
	position = OverworldMap.grid_to_world(grid_pos)
	if sprite_texture != null:
		sprite.texture = sprite_texture
	if _map != null:
		_map.register_occupant(grid_pos, self)


func _process(_delta: float) -> void:
	if _moving or _map == null:
		return
	if Dialogue.is_active or SceneRouter.is_transitioning or PauseMenu.is_open:
		return

	var dir := Vector2i.ZERO
	# Single-axis priority (no diagonals). Vertical wins over horizontal so
	# pressing both up and right doesn't oscillate.
	if Input.is_action_pressed("move_up"):
		dir = Vector2i(0, -1)
	elif Input.is_action_pressed("move_down"):
		dir = Vector2i(0, 1)
	elif Input.is_action_pressed("move_left"):
		dir = Vector2i(-1, 0)
	elif Input.is_action_pressed("move_right"):
		dir = Vector2i(1, 0)

	if dir == Vector2i.ZERO:
		return

	facing = _dir_to_facing(dir)
	var target := grid_pos + dir
	if _map.is_walkable(target):
		_begin_move(target)
	else:
		# Bumping into something — let it react (e.g. NPCs face the player).
		var blocker := _map.occupant_at(target)
		if blocker != null and blocker.has_method("on_bump"):
			blocker.on_bump(self)


func _input(event: InputEvent) -> void:
	if _map == null or _moving or Dialogue.is_active or SceneRouter.is_transitioning:
		return
	# Pause menu only opens when nothing else is taking input.
	if event.is_action_pressed("menu") and not PauseMenu.is_open:
		PauseMenu.open()
		get_viewport().set_input_as_handled()
		return
	if PauseMenu.is_open:
		return
	if event.is_action_pressed("ui_accept"):
		var ahead := grid_pos + FACING_DIRS[facing]
		var target := _map.occupant_at(ahead)
		if target != null and target.has_method("interact"):
			target.interact(self)
			get_viewport().set_input_as_handled()


func _begin_move(target: Vector2i) -> void:
	_moving = true
	var from := grid_pos
	_map.move_occupant(from, target, self)
	grid_pos = target

	var tween := create_tween()
	tween.tween_property(self, "position", OverworldMap.grid_to_world(target), MOVE_TIME)
	tween.tween_callback(_on_move_finished.bind(from, target))


func _on_move_finished(from_pos: Vector2i, to_pos: Vector2i) -> void:
	_moving = false
	moved.emit(from_pos, to_pos)
	if _map != null and _map.is_encounter_tile(to_pos):
		stepped_on_encounter_tile.emit()


func face_toward(other_grid_pos: Vector2i) -> void:
	var d := other_grid_pos - grid_pos
	# Snap to the dominant axis.
	if absi(d.x) >= absi(d.y):
		facing = Facing.RIGHT if d.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if d.y > 0 else Facing.UP


static func _dir_to_facing(dir: Vector2i) -> int:
	if dir == Vector2i(0, 1):  return Facing.DOWN
	if dir == Vector2i(0, -1): return Facing.UP
	if dir == Vector2i(-1, 0): return Facing.LEFT
	return Facing.RIGHT
