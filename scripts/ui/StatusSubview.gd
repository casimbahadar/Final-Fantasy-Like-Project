extends Control

## Read-only status screen: pick a party member, see full stats.

signal back_requested

@onready var _member_list: VBoxContainer = %MemberList
@onready var _detail: RichTextLabel = %DetailText


func activate() -> void:
	_rebuild_member_list()


func _input(event: InputEvent) -> void:
	if not visible or Dialogue.is_active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _rebuild_member_list() -> void:
	for c in _member_list.get_children():
		c.queue_free()
	for pm in Party.members:
		var btn := Button.new()
		btn.text = "%s (Lv %d)" % [pm.actor_data().display_name, pm.level]
		btn.focus_mode = Control.FOCUS_ALL
		btn.focus_entered.connect(_on_member_focused.bind(pm))
		_member_list.add_child(btn)
	await get_tree().process_frame
	for c in _member_list.get_children():
		if c is Button:
			c.grab_focus()
			break


func _on_member_focused(pm) -> void:
	var actor: Actor = pm.actor_data()
	var cls: CharClass = actor.char_class if actor != null else null
	var class_name_str := cls.display_name if cls != null else "—"
	var xp_to_next := _xp_to_next(pm)
	_detail.text = "[b]%s[/b]\n%s   Level %d   XP %d / %d\n\nHP %d / %d\nMP %d / %d\n\nATK %d   DEF %d\nMAG %d   RES %d\nSPD %d   LUK %d\n\n%s" % [
		actor.display_name,
		class_name_str,
		pm.level,
		pm.xp,
		xp_to_next,
		pm.hp, pm.max_hp(),
		pm.mp, pm.max_mp(),
		pm.stat("atk"), pm.stat("def"),
		pm.stat("mag"), pm.stat("res"),
		pm.stat("spd"), pm.stat("luk"),
		_equipment_summary(pm),
	]


func _xp_to_next(pm) -> int:
	var cls: CharClass = pm.actor_data().char_class
	if cls != null and cls.xp_curve.size() > pm.level + 1:
		return cls.xp_curve[pm.level + 1]
	return Database.default_xp_to_next(pm.level)


func _equipment_summary(pm) -> String:
	var lines: Array[String] = ["[i]Equipment[/i]"]
	for slot_pair in [["Weapon", pm.equip_weapon], ["Armor", pm.equip_armor], ["Accessory", pm.equip_accessory]]:
		var label: String = slot_pair[0]
		var id: StringName = slot_pair[1]
		if id == &"":
			lines.append("  %s: —" % label)
			continue
		var item: Item = Database.item(id)
		lines.append("  %s: %s" % [label, item.display_name if item != null else "?"])
	return "\n".join(lines)
