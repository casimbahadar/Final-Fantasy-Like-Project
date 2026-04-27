extends Node

## Autoloaded as `PauseMenu`. Owns a CanvasLayer + the PauseMenu scene
## instance, exposes is_open / open() / close(). Gameplay code (PlayerController,
## etc.) gates input on PauseMenu.is_open the same way it gates on
## Dialogue.is_active.

const PAUSE_MENU_SCENE := preload("res://scenes/ui/PauseMenu.tscn")

signal opened
signal closed

var is_open: bool = false

var _layer: CanvasLayer
var _menu: Control


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 60
	add_child(_layer)
	_menu = PAUSE_MENU_SCENE.instantiate()
	_layer.add_child(_menu)
	_menu.hide()
	_menu.close_requested.connect(close)


func open() -> void:
	if is_open:
		return
	# Refuse to open during transitions or active dialogue.
	if SceneRouter.is_transitioning or Dialogue.is_active:
		return
	is_open = true
	_menu.show()
	_menu.open()
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_menu.hide()
	closed.emit()
