extends Node2D

## Static NPC sitting on a tile. Talks via the Dialogue autoload. Faces the
## player when interacted. Optional once-only flag to disable repeat dialogue
## or run a different line set after the first conversation.

@export var npc_name: String = ""
@export var grid_position: Vector2i = Vector2i.ZERO
@export var lines: PackedStringArray = PackedStringArray()
## Optional: lines spoken on every interaction after the first.
@export var lines_after_first: PackedStringArray = PackedStringArray()
## Optional: GameState flag set true after first interaction.
@export var conversation_flag: StringName = &""
## Optional override for the placeholder villager sprite.
@export var sprite_texture: Texture2D

## If non-empty, interacting opens a shop with these items for sale.
@export var shop_inventory: Array[StringName] = []
## If > 0, interacting offers an inn stay (full heal) for this many gold.
@export var inn_cost: int = 0

@onready var sprite: Sprite2D = $Sprite2D

var _map: OverworldMap
var _facing: int = 0  # PlayerController.Facing.DOWN


func _ready() -> void:
	# Snap to grid using parent map (assumed to be the OverworldMap root).
	var p := get_parent()
	while p != null and not (p is OverworldMap):
		p = p.get_parent()
	_map = p
	if _map == null:
		push_warning("NPC '%s' has no OverworldMap ancestor" % npc_name)
		return
	position = OverworldMap.grid_to_world(grid_position)
	if sprite_texture != null:
		sprite.texture = sprite_texture
	_map.register_occupant(grid_position, self)


func interact(player) -> void:
	if Dialogue.is_active:
		return

	# Face the player.
	if player != null:
		var d := player.grid_pos - grid_position
		_face(d)
		# And player faces us.
		if player.has_method("face_toward"):
			player.face_toward(grid_position)

	var to_say: PackedStringArray = lines
	if conversation_flag != &"" and GameState.get_flag(conversation_flag, false):
		if lines_after_first.size() > 0:
			to_say = lines_after_first

	if to_say.size() > 0:
		await Dialogue.say(Array(to_say), npc_name)

	if conversation_flag != &"":
		GameState.set_flag(conversation_flag, true)

	# After the greeting (if any), branch into shop or inn flow if configured.
	if shop_inventory.size() > 0:
		Shop.open(shop_inventory, npc_name)
	elif inn_cost > 0:
		await _offer_inn()


func _offer_inn() -> void:
	if Party.gold < inn_cost:
		await Dialogue.say(["You haven't got %d gold." % inn_cost], npc_name)
		return
	var idx := await Dialogue.choose("Stay the night for %d gold?" % inn_cost, ["Cancel", "Stay"], true)
	if idx != 1:
		return
	Party.add_gold(-inn_cost)
	for pm in Party.members:
		pm.hp = pm.max_hp()
		pm.mp = pm.max_mp()
	await Dialogue.say(["The party rests. HP and MP fully restored."], npc_name)


func on_bump(player) -> void:
	# Walking into an NPC also starts dialogue (FF convention).
	interact(player)


func _face(dir: Vector2i) -> void:
	# We don't have directional sprites yet; just track for future use.
	if dir == Vector2i.ZERO:
		return
	if absi(dir.x) >= absi(dir.y):
		_facing = 2 if dir.x > 0 else 1  # RIGHT, LEFT
	else:
		_facing = 0 if dir.y > 0 else 3  # DOWN, UP
