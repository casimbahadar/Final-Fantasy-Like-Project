extends Control

## Dynamic list of skills or items, built fresh on each open.
## Emits `entry_chosen(kind, payload)` where:
##   kind == &"skill" → payload is a Skill resource
##   kind == &"item"  → payload is the item id (StringName)
## Also emits `cancelled` on ui_cancel.

signal entry_chosen(kind: StringName, payload)
signal cancelled

@onready var _list: VBoxContainer = $Panel/VBox

var _kind: StringName = &""


func _ready() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide()
		cancelled.emit()


func open_skills(unit) -> void:
	_kind = &"skill"
	_clear()
	for s in unit.available_skills():
		if s == null or s.id == &"attack":
			continue
		var btn := Button.new()
		var label := s.display_name
		if s.mp_cost > 0:
			label += "  (MP %d)" % s.mp_cost
		btn.text = label
		btn.disabled = unit.mp < s.mp_cost
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(func(): entry_chosen.emit(&"skill", s))
		_list.add_child(btn)
	_show_and_focus()


func open_items(_unit) -> void:
	_kind = &"item"
	_clear()
	for item_id in Party.inventory:
		var item: Item = Database.item(item_id)
		if item == null or item.kind != Item.ItemKind.CONSUMABLE:
			continue
		var btn := Button.new()
		btn.text = "%s  x%d" % [item.display_name, Party.inventory[item_id]]
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(func(): entry_chosen.emit(&"item", item_id))
		_list.add_child(btn)
	if _list.get_child_count() == 0:
		# Nothing usable — bail out.
		hide()
		cancelled.emit()
		return
	_show_and_focus()


func refocus() -> void:
	if not visible:
		return
	for c in _list.get_children():
		if c is Button and not c.disabled:
			c.grab_focus()
			return


func _clear() -> void:
	for c in _list.get_children():
		c.queue_free()


func _show_and_focus() -> void:
	show()
	# Wait one frame so dynamically-added buttons are in the tree.
	await get_tree().process_frame
	refocus()
