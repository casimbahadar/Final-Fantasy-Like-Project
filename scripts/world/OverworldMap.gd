class_name OverworldMap
extends Node2D

## Owns the tile grid for a map. Drawn programmatically (no TileMap yet) so the
## project ships without binary art assets. When real tiles arrive, swap _draw()
## for a TileMapLayer — the gameplay API (is_walkable, occupants) stays the same.

const TILE_SIZE := 16

enum Tile { FLOOR, WALL, GRASS, WATER, PATH, DOOR }

const TILE_COLORS := {
	Tile.FLOOR: Color("c8b890"),
	Tile.WALL:  Color("444444"),
	Tile.GRASS: Color("6da050"),
	Tile.WATER: Color("4090d0"),
	Tile.PATH:  Color("909090"),
	Tile.DOOR:  Color("6a4030"),
}

const TILE_BLOCKED := {
	Tile.WALL: true,
	Tile.WATER: true,
}

const TILE_ENCOUNTER := {
	Tile.GRASS: true,
}

## Authored as a multi-line string in the inspector. Characters:
##   #=wall  .=floor  ,=grass  ~=water  +=path  D=door  (anything else = floor)
@export_multiline var grid_string: String = ""

## Identifier matching the MapData.id this scene corresponds to (used for
## SpawnPoint resolution).
@export var map_id: StringName = &""

## Optional BGM played when this map is entered. SceneRouter also handles this
## via MapData; either source works.
@export var bgm: AudioStream

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const BATTLE_RETURN_SPAWN_ID := &"_battle_return"

var grid: Array = []        # grid[y][x] -> int tile type
var width: int = 0
var height: int = 0
var player: Node = null

# Vector2i grid_pos -> Node currently standing there (player, NPC, etc.)
var _occupants: Dictionary = {}

# Encounter step counter (decrements only on encounter tiles). Reset to a
# randomized value around MapData.encounter_steps after every encounter.
var _step_counter: int = 0
var _map_data: MapData


func _ready() -> void:
	_parse_grid()
	queue_redraw()
	if bgm != null:
		AudioManager.play_bgm(bgm)
	if map_id != &"":
		GameState.current_map_id = map_id
	# Children's _ready ran first (Godot bottom-up order), so NPCs / spawn
	# points / warps have all registered themselves by now. Safe to spawn
	# the player and connect warps without deferring.
	_post_setup()


func _post_setup() -> void:
	_map_data = Database.map(map_id)
	_reset_step_counter()

	var spawn_pos: Vector2i
	var spawn_facing: int = 0
	if GameState.has_loaded_position:
		# Just loaded a save — drop player at the exact saved tile.
		spawn_pos = GameState.loaded_player_grid_pos
		spawn_facing = GameState.loaded_player_facing
		GameState.has_loaded_position = false
	elif GameState.spawn_point_id == BATTLE_RETURN_SPAWN_ID and SceneRouter.battle_return_map == map_id:
		spawn_pos = SceneRouter.battle_return_grid_pos
		spawn_facing = SceneRouter.battle_return_facing
	else:
		var spawn := _find_spawn(GameState.spawn_point_id)
		if spawn != null:
			spawn_pos = spawn.grid_position
			spawn_facing = spawn.facing
		else:
			spawn_pos = Vector2i(width / 2, height / 2)
			push_warning("OverworldMap '%s': no SpawnPoint matched id '%s'; using map center" % [map_id, GameState.spawn_point_id])

	player = PLAYER_SCENE.instantiate()
	add_child(player)
	var sprite_tex: Texture2D = null
	if Party.members.size() > 0:
		var actor: Actor = Party.members[0].actor_data()
		if actor != null and actor.overworld_sprite != null:
			sprite_tex = actor.overworld_sprite
	player.setup(self, spawn_pos, spawn_facing, sprite_tex)
	player.moved.connect(_on_player_step)

	for warp in get_tree().get_nodes_in_group("warps"):
		if is_ancestor_of(warp) and warp.has_method("attach_player"):
			warp.attach_player(player)


func _on_player_step(_from_pos: Vector2i, to_pos: Vector2i) -> void:
	if _map_data == null or _map_data.encounter_steps <= 0 or _map_data.encounter_troops.is_empty():
		return
	if not is_encounter_tile(to_pos):
		return
	_step_counter -= 1
	if _step_counter > 0:
		return
	_trigger_encounter()


func _reset_step_counter() -> void:
	if _map_data == null or _map_data.encounter_steps <= 0:
		_step_counter = 0
		return
	var avg := _map_data.encounter_steps
	_step_counter = randi_range(maxi(1, avg / 2), maxi(2, avg + avg / 2))


func _trigger_encounter() -> void:
	if _map_data == null or _map_data.encounter_troops.is_empty():
		return
	var troop_id: StringName = _map_data.encounter_troops.pick_random()
	# Save where to drop the player back when battle ends.
	SceneRouter.battle_return_map = map_id
	SceneRouter.battle_return_grid_pos = player.grid_pos
	SceneRouter.battle_return_facing = player.facing
	_reset_step_counter()
	SceneRouter.go_to_battle(troop_id, map_id)


func _find_spawn(spawn_id: StringName):
	var fallback = null
	for sp in get_tree().get_nodes_in_group("spawn_points"):
		if not is_ancestor_of(sp):
			continue
		if sp.spawn_id == spawn_id:
			return sp
		if fallback == null:
			fallback = sp
	return fallback


func _parse_grid() -> void:
	grid.clear()
	width = 0
	height = 0
	# Trim a leading blank line so authors can write the grid on the line
	# below the opening triple-quote without having a blank top row.
	var raw := grid_string.lstrip("\n").rstrip("\n")
	for raw_line in raw.split("\n"):
		var row: Array = []
		for ch in raw_line:
			row.append(_char_to_tile(ch))
		grid.append(row)
		width = maxi(width, row.size())
	height = grid.size()


func _char_to_tile(ch: String) -> int:
	match ch:
		"#": return Tile.WALL
		".": return Tile.FLOOR
		",": return Tile.GRASS
		"~": return Tile.WATER
		"+": return Tile.PATH
		"D": return Tile.DOOR
		_:   return Tile.FLOOR


func _draw() -> void:
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			var t: int = row[x]
			var color: Color = TILE_COLORS.get(t, Color.MAGENTA)
			draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), color, true)
			# Wall: darker stripe across the top fakes a tiny bit of depth.
			if t == Tile.WALL:
				draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, 4), Color("2a2a2a"), true)
			elif t == Tile.DOOR:
				# Door highlight band so it reads as an exit.
				draw_rect(Rect2(x * TILE_SIZE + 2, y * TILE_SIZE + 4, TILE_SIZE - 4, TILE_SIZE - 8), Color("8a5040"), true)


func tile_at(grid_pos: Vector2i) -> int:
	if grid_pos.y < 0 or grid_pos.y >= grid.size():
		return Tile.WALL
	var row: Array = grid[grid_pos.y]
	if grid_pos.x < 0 or grid_pos.x >= row.size():
		return Tile.WALL
	return row[grid_pos.x]


func is_walkable(grid_pos: Vector2i) -> bool:
	if TILE_BLOCKED.has(tile_at(grid_pos)):
		return false
	if _occupants.has(grid_pos):
		return false
	return true


func is_encounter_tile(grid_pos: Vector2i) -> bool:
	return TILE_ENCOUNTER.has(tile_at(grid_pos))


func occupant_at(grid_pos: Vector2i) -> Node:
	return _occupants.get(grid_pos)


func register_occupant(grid_pos: Vector2i, node: Node) -> void:
	_occupants[grid_pos] = node


func unregister_occupant(grid_pos: Vector2i) -> void:
	_occupants.erase(grid_pos)


func move_occupant(from_pos: Vector2i, to_pos: Vector2i, node: Node) -> void:
	if _occupants.get(from_pos) == node:
		_occupants.erase(from_pos)
	_occupants[to_pos] = node


static func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)


static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / float(TILE_SIZE)), floori(world_pos.y / float(TILE_SIZE)))
