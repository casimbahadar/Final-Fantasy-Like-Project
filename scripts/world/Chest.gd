extends Node2D

## Treasure chest. Once-only loot. Sets a unique flag on GameState so it stays
## opened across saves. Sprite swaps between closed/open textures.

const TEX_CLOSED := preload("res://assets/sprites/placeholder/chest_closed.svg")
const TEX_OPEN := preload("res://assets/sprites/placeholder/chest_open.svg")

@export var grid_position: Vector2i = Vector2i.ZERO
@export var item_id: StringName = &""
@export var item_count: int = 1
@export var gold: int = 0
## Used to remember "already opened" state. MUST be unique per chest.
@export var chest_id: StringName = &""

@onready var sprite: Sprite2D = $Sprite2D

var _map: OverworldMap
var _opened: bool = false


func _ready() -> void:
	var p := get_parent()
	while p != null and not (p is OverworldMap):
		p = p.get_parent()
	_map = p
	if _map == null:
		push_warning("Chest '%s' has no OverworldMap ancestor" % chest_id)
		return
	position = OverworldMap.grid_to_world(grid_position)
	_map.register_occupant(grid_position, self)
	_opened = GameState.get_flag(_flag(), false)
	sprite.texture = TEX_OPEN if _opened else TEX_CLOSED


func interact(_player) -> void:
	if Dialogue.is_active:
		return
	if _opened:
		await Dialogue.say(["The chest is empty."])
		return
	_opened = true
	GameState.set_flag(_flag(), true)
	sprite.texture = TEX_OPEN

	var lines: Array[String] = []
	if item_id != &"":
		Party.add_item(item_id, item_count)
		var item: Item = Database.item(item_id)
		var label := item.display_name if item != null else String(item_id)
		if item_count > 1:
			lines.append("Got %d × %s!" % [item_count, label])
		else:
			lines.append("Got %s!" % label)
	if gold > 0:
		Party.add_gold(gold)
		lines.append("Got %d gold." % gold)
	if lines.is_empty():
		lines.append("The chest is empty.")
	await Dialogue.say(lines)


func on_bump(player) -> void:
	interact(player)


func _flag() -> StringName:
	if chest_id != &"":
		return StringName("chest_opened_" + String(chest_id))
	# Fallback: derive from grid + map.
	var map_id := _map.map_id if _map != null else &"unknown"
	return StringName("chest_opened_%s_%d_%d" % [String(map_id), grid_position.x, grid_position.y])
