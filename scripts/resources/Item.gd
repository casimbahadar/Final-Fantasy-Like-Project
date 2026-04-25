@tool
class_name Item
extends Resource

## A consumable, equippable, or key item.

enum ItemKind { CONSUMABLE, WEAPON, ARMOR, ACCESSORY, KEY }
enum EquipSlot { NONE, WEAPON, ARMOR, ACCESSORY }

@export var id: StringName = &""
@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Type")
@export var kind: ItemKind = ItemKind.CONSUMABLE
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var stackable: bool = true
@export var max_stack: int = 99

@export_group("Economy")
@export var buy_price: int = 0
@export var sell_price: int = 0

@export_group("Consumable Effect")
## Healing on use (HP). Negative = damage.
@export var heal_hp: int = 0
@export var heal_mp: int = 0
@export var revives: bool = false
@export var cures_status: StringName = &""

@export_group("Equip Stats (added when equipped)")
@export var bonus_max_hp: int = 0
@export var bonus_max_mp: int = 0
@export var bonus_atk: int = 0
@export var bonus_def: int = 0
@export var bonus_mag: int = 0
@export var bonus_res: int = 0
@export var bonus_spd: int = 0
@export var bonus_luk: int = 0
