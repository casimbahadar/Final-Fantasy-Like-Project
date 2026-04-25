@tool
class_name CharClass
extends Resource

## A character class (Warrior, Mage, etc.). Defines stat bias and learnable skills.

@export var id: StringName = &""
@export var display_name: String = "Class"
@export_multiline var description: String = ""

## Skills learned at given levels: { level: int -> skill: Skill }.
## Stored as Array of dictionaries because Godot's inspector doesn't edit
## typed Dictionary[int, Resource] cleanly yet.
@export var learnset: Array[LearnEntry] = []

## XP curve: xp needed to reach this level (index = level, [0] unused).
## If empty, Database falls back to a default formula.
@export var xp_curve: PackedInt32Array = PackedInt32Array()
