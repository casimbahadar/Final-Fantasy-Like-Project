extends Control

## Save/Load screen with three slots. Each slot card shows playtime, party
## summary, gold, and timestamp. activate(true) → save mode, activate(false)
## → load mode. After saving, hangs out for a moment so the player sees the
## confirmation, then refreshes the slot rows.

signal back_requested

@onready var _slot_list: VBoxContainer = %SlotList
@onready var _mode_label: Label = %ModeLabel
@onready var _confirmation: Label = %Confirmation

var _save_mode: bool = false


func activate(save_mode: bool) -> void:
	_save_mode = save_mode
	_mode_label.text = "SAVE" if save_mode else "LOAD"
	_confirmation.text = ""
	_rebuild_slots()


func _input(event: InputEvent) -> void:
	if not visible or Dialogue.is_active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _rebuild_slots() -> void:
	for c in _slot_list.get_children():
		c.queue_free()
	for slot in SaveSystem.SLOT_COUNT:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		btn.text = _slot_label(slot)
		btn.focus_mode = Control.FOCUS_ALL
		btn.disabled = (not _save_mode) and not SaveSystem.slot_exists(slot)
		btn.pressed.connect(_on_slot_chosen.bind(slot))
		_slot_list.add_child(btn)
	await get_tree().process_frame
	for c in _slot_list.get_children():
		if c is Button and not c.disabled:
			c.grab_focus()
			return
	# Nothing usable — focus first anyway so cancel still works visually.
	if _slot_list.get_child_count() > 0:
		_slot_list.get_child(0).grab_focus()


func _slot_label(slot: int) -> String:
	if not SaveSystem.slot_exists(slot):
		return "Slot %d  —  (empty)" % (slot + 1)
	var s := SaveSystem.slot_summary(slot)
	var t := int(s.get("playtime", 0))
	var play := "%02d:%02d:%02d" % [t / 3600, (t / 60) % 60, t % 60]
	var ts := s.get("timestamp", 0)
	var when := Time.get_datetime_string_from_unix_time(ts) if ts > 0 else "?"
	return "Slot %d   %s   Play %s   Gold %d   Members %d   %s" % [
		slot + 1,
		s.get("map_id", "?"),
		play,
		s.get("gold", 0),
		s.get("member_count", 0),
		when,
	]


func _on_slot_chosen(slot: int) -> void:
	if _save_mode:
		_handle_save(slot)
	else:
		_handle_load(slot)


func _handle_save(slot: int) -> void:
	if SaveSystem.slot_exists(slot):
		var idx := await Dialogue.choose("Overwrite slot %d?" % (slot + 1), ["Cancel", "Overwrite"], true)
		if idx != 1:
			_rebuild_slots()
			return
	if SaveSystem.save_to(slot):
		_confirmation.text = "Saved to slot %d." % (slot + 1)
	else:
		_confirmation.text = "Save failed."
	_rebuild_slots()


func _handle_load(slot: int) -> void:
	if not SaveSystem.slot_exists(slot):
		return
	var idx := await Dialogue.choose("Load slot %d? Unsaved progress will be lost." % (slot + 1), ["Cancel", "Load"], true)
	if idx != 1:
		_rebuild_slots()
		return
	if not SaveSystem.load_from(slot):
		_confirmation.text = "Load failed."
		return
	# Successful load — close the pause menu and route to the saved map.
	PauseMenu.close()
	if GameState.current_map_id != &"":
		await SceneRouter.go_to_map(GameState.current_map_id, GameState.spawn_point_id)
