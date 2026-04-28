extends Control

## Root controller for PauseMenu.tscn. Dispatches the seven command buttons to
## the matching subview. Subviews emit `back_requested` when the user presses
## Cancel inside them, returning focus to the command list. Cancel from the
## command list itself closes the pause menu.

signal close_requested

@onready var _commands: VBoxContainer = %CommandList
@onready var _items_view = %ItemsView
@onready var _equip_view = %EquipView
@onready var _status_view = %StatusView
@onready var _saveload_view = %SaveLoadView
@onready var _settings_view = %SettingsView
@onready var _summary: Control = %PartySummary

var _last_focused_command: Button = null
var _all_subviews: Array = []


func _ready() -> void:
	_all_subviews = [_items_view, _equip_view, _status_view, _saveload_view, _settings_view]
	for s in _all_subviews:
		s.hide()
		if s.has_signal("back_requested"):
			s.back_requested.connect(_on_subview_back)
		if s.has_signal("party_state_changed"):
			s.party_state_changed.connect(_refresh_summary)

	# Wire command list buttons by name (so designers can reorder safely).
	for btn in _commands.get_children():
		if btn is Button:
			btn.pressed.connect(_on_command_pressed.bind(btn.name))


func open() -> void:
	# Hide every subview, show command list, focus the first command.
	for s in _all_subviews:
		s.hide()
	_refresh_summary()
	_focus_first_command()


func _on_command_pressed(command: String) -> void:
	_last_focused_command = _focused_command_button()
	for s in _all_subviews:
		s.hide()
	match command:
		"Items":
			_items_view.show()
			_items_view.activate()
		"Equip":
			_equip_view.show()
			_equip_view.activate()
		"Status":
			_status_view.show()
			_status_view.activate()
		"Save":
			_saveload_view.show()
			_saveload_view.activate(true)  # save mode
		"Load":
			_saveload_view.show()
			_saveload_view.activate(false) # load mode
		"Settings":
			_settings_view.show()
			_settings_view.activate()
		"Title":
			_request_title()


func _on_subview_back() -> void:
	for s in _all_subviews:
		s.hide()
	_refresh_summary()
	if _last_focused_command != null and is_instance_valid(_last_focused_command):
		_last_focused_command.grab_focus()
	else:
		_focus_first_command()


func _input(event: InputEvent) -> void:
	if not visible or Dialogue.is_active:
		return
	if not _any_subview_visible() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_requested.emit()


func _any_subview_visible() -> bool:
	for s in _all_subviews:
		if s.visible:
			return true
	return false


func _focused_command_button() -> Button:
	for c in _commands.get_children():
		if c is Button and c.has_focus():
			return c
	return null


func _focus_first_command() -> void:
	for c in _commands.get_children():
		if c is Button:
			c.grab_focus()
			return


func _refresh_summary() -> void:
	if _summary != null and _summary.has_method("refresh"):
		_summary.refresh()


func _request_title() -> void:
	var idx := await Dialogue.choose("Return to title screen? Unsaved progress will be lost.", ["Cancel", "Return to Title"], true)
	if idx == 1:
		PauseMenu.close()
		GameState.reset()
		Party.clear()
		await SceneRouter.go_to_scene("res://scenes/ui/TitleScreen.tscn")
	else:
		_focus_first_command()
