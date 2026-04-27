extends Control

## Items menu: pick a consumable, then pick a party member to use it on.
## Heals HP/MP, revives, etc. — applies the same fields a Battle item-use does.

signal back_requested
signal party_state_changed

@onready var _item_list: VBoxContainer = %ItemList
@onready var _target_panel: Control = %TargetPanel
@onready var _target_list: VBoxContainer = %TargetList
@onready var _description: Label = %Description
@onready var _empty_label: Label = %EmptyLabel

var _picking_target: bool = false
var _selected_item_id: StringName = &""


func activate() -> void:
	_picking_target = false
	_target_panel.hide()
	_description.text = ""
	_rebuild_item_list()


func _input(event: InputEvent) -> void:
	if not visible or Dialogue.is_active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _picking_target:
			_picking_target = false
			_target_panel.hide()
			_focus_first_item()
		else:
			back_requested.emit()


func _rebuild_item_list() -> void:
	for c in _item_list.get_children():
		c.queue_free()
	var any := false
	for item_id in Party.inventory:
		var item: Item = Database.item(item_id)
		if item == null or item.kind != Item.ItemKind.CONSUMABLE:
			continue
		any = true
		var btn := Button.new()
		btn.text = "%s  x%d" % [item.display_name, Party.inventory[item_id]]
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_item_chosen.bind(item_id))
		btn.focus_entered.connect(_on_item_focused.bind(item_id))
		_item_list.add_child(btn)
	_empty_label.visible = not any
	if any:
		await get_tree().process_frame
		_focus_first_item()


func _focus_first_item() -> void:
	for c in _item_list.get_children():
		if c is Button:
			c.grab_focus()
			return


func _on_item_focused(item_id: StringName) -> void:
	var item: Item = Database.item(item_id)
	_description.text = item.description if item != null else ""


func _on_item_chosen(item_id: StringName) -> void:
	_selected_item_id = item_id
	_picking_target = true
	_rebuild_target_list()
	_target_panel.show()


func _rebuild_target_list() -> void:
	for c in _target_list.get_children():
		c.queue_free()
	var item: Item = Database.item(_selected_item_id)
	for pm in Party.members:
		var btn := Button.new()
		var label := "%s  HP %d/%d  MP %d/%d" % [
			pm.actor_data().display_name, pm.hp, pm.max_hp(), pm.mp, pm.max_mp()
		]
		btn.text = label
		btn.focus_mode = Control.FOCUS_ALL
		btn.disabled = not _can_use_on(item, pm)
		btn.pressed.connect(_on_target_chosen.bind(pm))
		_target_list.add_child(btn)
	await get_tree().process_frame
	for c in _target_list.get_children():
		if c is Button and not c.disabled:
			c.grab_focus()
			return


func _can_use_on(item: Item, pm) -> bool:
	if item == null:
		return false
	if item.revives:
		return not pm.is_alive()
	if not pm.is_alive():
		return false
	if item.heal_hp > 0 and pm.hp < pm.max_hp():
		return true
	if item.heal_mp > 0 and pm.mp < pm.max_mp():
		return true
	return false


func _on_target_chosen(pm) -> void:
	var item: Item = Database.item(_selected_item_id)
	if item == null:
		return
	if not Party.remove_item(_selected_item_id, 1):
		return
	if item.revives and not pm.is_alive():
		pm.hp = mini(pm.max_hp(), maxi(1, pm.max_hp() / 2))
	if item.heal_hp > 0:
		pm.hp = mini(pm.max_hp(), pm.hp + item.heal_hp)
	if item.heal_mp > 0:
		pm.mp = mini(pm.max_mp(), pm.mp + item.heal_mp)
	_picking_target = false
	_target_panel.hide()
	_rebuild_item_list()
	party_state_changed.emit()
