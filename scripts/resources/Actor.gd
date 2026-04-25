@tool
class_name Actor
extends Resource

## A playable character (party member). Mirrors RPG Maker's "Actor" concept.
## Authored as a .tres file in res://data/actors/, edited in the inspector.

@export var id: StringName = &""
@export var display_name: String = "Hero"
@export_multiline var bio: String = ""

@export_group("Class & Level")
@export var char_class: CharClass
@export_range(1, 99) var starting_level: int = 1

@export_group("Base Stats (level 1)")
@export var base_max_hp: int = 100
@export var base_max_mp: int = 20
@export var base_atk: int = 10
@export var base_def: int = 8
@export var base_mag: int = 8
@export var base_res: int = 8
@export var base_spd: int = 10
@export var base_luk: int = 5

@export_group("Per-Level Growth (added each level)")
@export var grow_max_hp: int = 8
@export var grow_max_mp: int = 2
@export var grow_atk: int = 2
@export var grow_def: int = 1
@export var grow_mag: int = 1
@export var grow_res: int = 1
@export var grow_spd: int = 1
@export var grow_luk: int = 1

@export_group("Visuals")
@export var portrait: Texture2D
@export var battle_sprite: Texture2D
@export var overworld_sprite: Texture2D


func stat_at_level(level: int, base: int, grow: int) -> int:
	return base + grow * maxi(level - 1, 0)
