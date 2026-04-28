extends Control

## Root of TouchControls.tscn. Each button has a `target_action` metadata
## entry on it; we read it on button_down / button_up and emit our two
## signals so the autoload can inject InputEventActions.

signal action_pressed(action: StringName)
signal action_released(action: StringName)


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	for btn in _all_buttons(self):
		var action_str: String = btn.get_meta("target_action", "")
		if action_str == "":
			continue
		var action := StringName(action_str)
		btn.focus_mode = Control.FOCUS_NONE
		btn.button_down.connect(func(): action_pressed.emit(action))
		btn.button_up.connect(func(): action_released.emit(action))


func _all_buttons(node: Node) -> Array:
	var out: Array = []
	for c in node.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out
