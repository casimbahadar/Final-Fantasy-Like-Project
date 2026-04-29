extends Node

## Party state: living characters, inventory, gold, equipment.
## A party member is an instance of PartyMember (declared inline below as a
## RefCounted helper) holding mutable runtime state derived from an Actor template.

signal gold_changed(new_total: int)
signal inventory_changed
signal member_added(member)
signal member_removed(member_id: StringName)

var members: Array = []                      # Array[PartyMember]
var inventory: Dictionary = {}               # StringName(item_id) -> int(count)
var key_items: Dictionary = {}               # StringName -> bool
var gold: int = 0


class PartyMember extends RefCounted:
	var actor_id: StringName
	var level: int = 1
	var xp: int = 0
	var hp: int
	var mp: int
	var statuses: Array[StringName] = []
	# Equipped item ids by slot:
	var equip_weapon: StringName = &""
	var equip_armor: StringName = &""
	var equip_accessory: StringName = &""
	# Optional class override set by the Brighthollow guildmaster — when set,
	# this character uses the named class for XP curves and learnset instead of
	# their actor's default class. Empty = use the actor's class as authored.
	var class_override: StringName = &""

	func _init(actor: Actor) -> void:
		actor_id = actor.id
		level = actor.starting_level
		hp = actor.stat_at_level(level, actor.base_max_hp, actor.grow_max_hp)
		mp = actor.stat_at_level(level, actor.base_max_mp, actor.grow_max_mp)

	func actor_data() -> Actor:
		return Database.actor(actor_id)

	func effective_class() -> CharClass:
		if class_override != &"":
			var cls: CharClass = Database.classes.get(class_override)
			if cls != null:
				return cls
		var actor := actor_data()
		return actor.char_class if actor != null else null

	func max_hp() -> int:
		var a := actor_data()
		return a.stat_at_level(level, a.base_max_hp, a.grow_max_hp) + _equip_bonus("bonus_max_hp")

	func max_mp() -> int:
		var a := actor_data()
		return a.stat_at_level(level, a.base_max_mp, a.grow_max_mp) + _equip_bonus("bonus_max_mp")

	func stat(name: String) -> int:
		var a := actor_data()
		var base: int = a.get("base_" + name)
		var grow: int = a.get("grow_" + name)
		return a.stat_at_level(level, base, grow) + _equip_bonus("bonus_" + name)

	func _equip_bonus(field: String) -> int:
		var total := 0
		for slot_id in [equip_weapon, equip_armor, equip_accessory]:
			if slot_id == &"":
				continue
			var item: Item = Database.item(slot_id)
			if item != null:
				total += item.get(field)
		return total

	func is_alive() -> bool:
		return hp > 0

	func gain_xp(amount: int) -> int:
		xp += amount
		var levels_gained := 0
		var cls: CharClass = effective_class()
		while level < 99:
			var needed: int
			if cls != null and cls.xp_curve.size() > level + 1:
				needed = cls.xp_curve[level + 1]
			else:
				needed = Database.default_xp_to_next(level)
			if needed <= 0 or xp < needed:
				break
			xp -= needed
			level += 1
			levels_gained += 1
			# heal-on-level (FF tradition):
			hp = max_hp()
			mp = max_mp()
		return levels_gained


func add_member(actor_id: StringName) -> void:
	var actor := Database.actor(actor_id)
	if actor == null:
		push_warning("Party.add_member: unknown actor %s" % actor_id)
		return
	var pm := PartyMember.new(actor)
	members.append(pm)
	member_added.emit(pm)


func remove_member(actor_id: StringName) -> void:
	for i in members.size():
		if members[i].actor_id == actor_id:
			members.remove_at(i)
			member_removed.emit(actor_id)
			return


func add_gold(amount: int) -> void:
	gold = maxi(gold + amount, 0)
	gold_changed.emit(gold)


func add_item(item_id: StringName, count: int = 1) -> void:
	if count <= 0:
		return
	inventory[item_id] = inventory.get(item_id, 0) + count
	inventory_changed.emit()


func remove_item(item_id: StringName, count: int = 1) -> bool:
	var have: int = inventory.get(item_id, 0)
	if have < count:
		return false
	if have == count:
		inventory.erase(item_id)
	else:
		inventory[item_id] = have - count
	inventory_changed.emit()
	return true


func has_item(item_id: StringName, count: int = 1) -> bool:
	return inventory.get(item_id, 0) >= count


func clear() -> void:
	members.clear()
	inventory.clear()
	key_items.clear()
	gold = 0
