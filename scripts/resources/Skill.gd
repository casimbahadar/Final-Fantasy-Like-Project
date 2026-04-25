@tool
class_name Skill
extends Resource

## An action a unit can take in battle (basic attack, spell, technique).

enum TargetKind { ENEMY_SINGLE, ENEMY_ALL, ALLY_SINGLE, ALLY_ALL, SELF }
enum DamageKind { PHYSICAL, MAGICAL, HEAL, NONE }
enum Element { NONE, FIRE, ICE, THUNDER, WATER, EARTH, WIND, LIGHT, DARK }

@export var id: StringName = &""
@export var display_name: String = "Skill"
@export_multiline var description: String = ""

@export_group("Cost")
@export var mp_cost: int = 0
@export var item_cost: Item

@export_group("Targeting")
@export var target_kind: TargetKind = TargetKind.ENEMY_SINGLE
@export var damage_kind: DamageKind = DamageKind.PHYSICAL
@export var element: Element = Element.NONE

@export_group("Power")
## Base potency. Final damage uses DamageCalculator with attacker stats.
@export var power: int = 10
## Extra accuracy modifier (1.0 = baseline). 0.95 = 95% hit, etc.
@export var accuracy: float = 1.0
## Extra crit chance modifier added to attacker's base.
@export var crit_bonus: float = 0.0

@export_group("Status")
@export var inflicts_status: StringName = &""
@export_range(0.0, 1.0, 0.05) var status_chance: float = 0.0
