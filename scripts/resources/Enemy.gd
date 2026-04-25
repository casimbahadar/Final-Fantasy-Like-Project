@tool
class_name Enemy
extends Resource

## A single enemy unit. Combined into Troops for encounters.

@export var id: StringName = &""
@export var display_name: String = "Enemy"
@export var battle_sprite: Texture2D

@export_group("Stats")
@export var max_hp: int = 30
@export var max_mp: int = 0
@export var atk: int = 8
@export var def: int = 4
@export var mag: int = 4
@export var res: int = 4
@export var spd: int = 6
@export var luk: int = 1

@export_group("Rewards")
@export var xp_reward: int = 5
@export var gold_reward: int = 3
@export var drop_item: Item
@export_range(0.0, 1.0, 0.05) var drop_chance: float = 0.0

@export_group("AI")
## Skills the enemy can use; the AI picks weighted-randomly.
@export var skills: Array[Skill] = []
## Element vulnerabilities: 1.0 = neutral, 1.5 = weak, 0.5 = resist, 0.0 = immune, -1.0 = absorb.
@export var element_modifiers: Dictionary = {}
