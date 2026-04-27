extends Control

## Equipment screen: pick a member, pick a slot, pick an item from the inventory
## that matches that slot. Stat preview shows the delta from the currently
## equipped item. Cycles columns left → right with cancel returning to the
## previous column.

signal back_requested
signal party_state_changed

enum Column { MEMBER, SLOT, ITEM }

@onready var _member_list: VBoxContainer = %MemberList
@onready var _slot_list: VBoxContainer = %SlotList
@onready var _item_list: VBoxContainer = %ItemList
@onready var _preview: Label = %Preview

var _current_column: Column = Column.MEMBER
var _current_member = null
var _current_slot: int = Item.EquipSlot.WEAPON

const SLOT_LABELS := {
	Item.EquipSlot.WEAPON: "Weapon",
	Item.EquipSlot.ARMOR: "Armor",
	Item.EquipSlot.ACCESSORY: "Accessory",
}


func activate() -> void:
	_current_column = Column.MEMBER
	_preview.text = ""
	_rebuild_members()


func _input(event: InputEvent) -> void:
	if not visible or Dialogue.is_active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back_one_column()


func _back_one_column() -> void:
	match _current_column:
		Column.MEMBER:
			back_requested.emit()
		Column.SLOT:
			_current_column = Column.MEMBER
			_focus_first_in(_member_list)
		Column.ITEM:
			_current_column = Column.SLOT
			_focus_first_in(_slot_list)


func _rebuild_members() -> void:
	for c in _member_list.get_children():
		c.queue_free()
	for pm in Party.members:
		var btn := Button.new()
		btn.text = pm.actor_data().display_name
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_member_chosen.bind(pm))
		btn.focus_entered.connect(func(): _current_member = pm)
		_member_list.add_child(btn)
	await get_tree().process_frame
	_focus_first_in(_member_list)


func _on_member_chosen(pm) -> void:
	_current_member = pm
	_current_column = Column.SLOT
	_rebuild_slots()


func _rebuild_slots() -> void:
	for c in _slot_list.get_children():
		c.queue_free()
	for slot in [Item.EquipSlot.WEAPON, Item.EquipSlot.ARMOR, Item.EquipSlot.ACCESSORY]:
		var btn := Button.new()
		btn.text = "%s: %s" % [SLOT_LABELS[slot], _equipped_name(_current_member, slot)]
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_slot_chosen.bind(slot))
		_slot_list.add_child(btn)
	await get_tree().process_frame
	_focus_first_in(_slot_list)


func _on_slot_chosen(slot: int) -> void:
	_current_slot = slot
	_current_column = Column.ITEM
	_rebuild_items()


func _rebuild_items() -> void:
	for c in _item_list.get_children():
		c.queue_free()
	# "Unequip" option first.
	var none_btn := Button.new()
	none_btn.text = "(remove)"
	none_btn.focus_mode = Control.FOCUS_ALL
	none_btn.pressed.connect(_on_item_chosen.bind(StringName("")))
	none_btn.focus_entered.connect(func(): _show_preview(StringName("")))
	_item_list.add_child(none_btn)

	for item_id in Party.inventory:
		var item: Item = Database.item(item_id)
		if item == null or item.equip_slot != _current_slot:
			continue
		var btn := Button.new()
		btn.text = "%s  x%d" % [item.display_name, Party.inventory[item_id]]
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_item_chosen.bind(item_id))
		btn.focus_entered.connect(func(): _show_preview(item_id))
		_item_list.add_child(btn)
	await get_tree().process_frame
	_focus_first_in(_item_list)


func _on_item_chosen(item_id: StringName) -> void:
	var current_id: StringName = _current_equip_id(_current_member, _current_slot)
	if current_id == item_id:
		_back_one_column()
		return

	# Equipment items live in the inventory just like consumables — when
	# equipping we conceptually move from inventory to slot, and vice versa
	# when unequipping. Take the new item from inventory FIRST so we don't
	# leak a duplicate of the old one if the take fails.
	if item_id != &"":
		if not Party.remove_item(item_id, 1):
			return
	if current_id != &"":
		Party.add_item(current_id, 1)

	match _current_slot:
		Item.EquipSlot.WEAPON:
			_current_member.equip_weapon = item_id
		Item.EquipSlot.ARMOR:
			_current_member.equip_armor = item_id
		Item.EquipSlot.ACCESSORY:
			_current_member.equip_accessory = item_id
	# Clamp HP/MP if the equip change reduces max.
	_current_member.hp = mini(_current_member.hp, _current_member.max_hp())
	_current_member.mp = mini(_current_member.mp, _current_member.max_mp())

	party_state_changed.emit()
	_rebuild_slots()
	_current_column = Column.SLOT


func _show_preview(item_id: StringName) -> void:
	if _current_member == null:
		return
	var current_id: StringName = _current_equip_id(_current_member, _current_slot)
	var current_item: Item = Database.item(current_id)
	var new_item: Item = Database.item(item_id)
	var stats := ["max_hp", "max_mp", "atk", "def", "mag", "res", "spd", "luk"]
	var lines: Array[String] = []
	for s in stats:
		var cur: int = current_item.get("bonus_" + s) if current_item != null else 0
		var nxt: int = new_item.get("bonus_" + s) if new_item != null else 0
		var delta := nxt - cur
		if delta == 0:
			continue
		var prefix := "+" if delta > 0 else ""
		lines.append("%s: %s%d" % [s.to_upper(), prefix, delta])
	if lines.is_empty():
		_preview.text = "(no change)"
	else:
		_preview.text = "\n".join(lines)


func _current_equip_id(pm, slot: int) -> StringName:
	match slot:
		Item.EquipSlot.WEAPON: return pm.equip_weapon
		Item.EquipSlot.ARMOR: return pm.equip_armor
		Item.EquipSlot.ACCESSORY: return pm.equip_accessory
	return &""


func _equipped_name(pm, slot: int) -> String:
	var id := _current_equip_id(pm, slot)
	if id == &"":
		return "—"
	var item: Item = Database.item(id)
	return item.display_name if item != null else "?"


func _focus_first_in(container: VBoxContainer) -> void:
	for c in container.get_children():
		if c is Button:
			c.grab_focus()
			return
