extends Node2D

## A Brighthollow NPC that lets the player change a party member's class.
## Available once the player has cleared chapter 4 (post-Stormwyrm). Each
## class change is free — the cost is the time spent re-leveling skills,
## since the new class's learnset is checked against the character's current
## level.

@export var grid_position: Vector2i = Vector2i.ZERO
@export var npc_name: String = "Guildmaster Veris"
@export var sprite_texture: Texture2D
## Quest gate — class change unlocks once this flag is set.
@export var requires_flag: StringName = &"stormwyrm_defeated"

const CLASS_OPTIONS: Array[StringName] = [&"warrior", &"mage", &"rogue", &"cleric", &"dragoon"]

@onready var sprite: Sprite2D = $Sprite2D

var _map: OverworldMap


func _ready() -> void:
	var p := get_parent()
	while p != null and not (p is OverworldMap):
		p = p.get_parent()
	_map = p
	if _map == null:
		return
	position = OverworldMap.grid_to_world(grid_position)
	if sprite_texture != null:
		sprite.texture = sprite_texture
	_map.register_occupant(grid_position, self)


func interact(player) -> void:
	if Dialogue.is_active:
		return
	if player != null and player.has_method("face_toward"):
		player.face_toward(grid_position)

	if requires_flag != &"" and not GameState.get_flag(requires_flag, false):
		await Dialogue.say(["The Guild's classroom is closed to those who haven't yet seen the high passes. Come back when the Stormwyrm is dead."], npc_name)
		return

	if Party.members.size() == 0:
		return

	await Dialogue.say(["The Guild trains every kind of fighter. If one of yours wants a different shape — bring them in. They keep their level. They learn new skills as they grow."], npc_name)

	# Pick the party member.
	var member_options: Array = []
	for pm in Party.members:
		var actor := pm.actor_data()
		var cls := pm.effective_class()
		var cls_name := cls.display_name if cls != null else "?"
		member_options.append("%s — %s" % [actor.display_name if actor != null else "?", cls_name])
	member_options.append("Cancel")
	var member_idx := await Dialogue.choose("Re-train whom?", member_options, true)
	if member_idx < 0 or member_idx >= Party.members.size():
		return
	var pm = Party.members[member_idx]

	# Pick the class.
	var class_labels: Array = []
	for cls_id in CLASS_OPTIONS:
		var cls: CharClass = Database.classes.get(cls_id)
		class_labels.append(cls.display_name if cls != null else String(cls_id))
	class_labels.append("Cancel")
	var class_idx := await Dialogue.choose("To which discipline?", class_labels, true)
	if class_idx < 0 or class_idx >= CLASS_OPTIONS.size():
		return

	var chosen := CLASS_OPTIONS[class_idx]
	# Treat picking the same class as a reset of the override (back to authored).
	var actor := pm.actor_data()
	if actor != null and actor.char_class != null and actor.char_class.id == chosen:
		pm.class_override = &""
	else:
		pm.class_override = chosen
	var label := class_labels[class_idx]
	await Dialogue.say(["Done. %s is now a %s. The skills will come as they grow." % [actor.display_name if actor != null else "?", label]], npc_name)


func on_bump(player) -> void:
	interact(player)
