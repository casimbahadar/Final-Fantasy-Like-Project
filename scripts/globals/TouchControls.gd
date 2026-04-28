extends Node

## Autoloaded as `TouchControls`. Owns a CanvasLayer with on-screen D-pad + A/B
## /Menu buttons. Buttons inject InputEventAction so the rest of the game keeps
## reading the same input actions whether the source is keyboard, gamepad, or
## a finger on glass.
##
## Visibility is driven by Settings.touch_should_show() and refreshed when
## Settings emits `changed`.

const TOUCH_SCENE := preload("res://scenes/ui/TouchControls.tscn")

var _layer: CanvasLayer
var _root: Control


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 40  # below pause(60) / shop(70) / dialogue(80) / fade(100)
	add_child(_layer)
	_root = TOUCH_SCENE.instantiate()
	_layer.add_child(_root)
	_root.action_pressed.connect(_on_action_pressed)
	_root.action_released.connect(_on_action_released)
	_refresh_visibility()
	if Settings != null:
		Settings.changed.connect(_refresh_visibility)


func _refresh_visibility() -> void:
	_root.visible = Settings.touch_should_show() if Settings != null else false


func _on_action_pressed(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)


func _on_action_released(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
