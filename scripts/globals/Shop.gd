extends Node

## Autoloaded as `Shop`. Opens the ShopMenu scene as an overlay. Caller
## passes the inventory (array of item ids) and the shop's display name.

const SHOP_MENU_SCENE := preload("res://scenes/ui/ShopMenu.tscn")

signal opened
signal closed

var is_open: bool = false

var _layer: CanvasLayer
var _menu: Control


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 70  # above pause menu (60), below dialogue (80)
	add_child(_layer)
	_menu = SHOP_MENU_SCENE.instantiate()
	_layer.add_child(_menu)
	_menu.hide()
	_menu.close_requested.connect(close)


func open(inventory: Array, shop_name: String = "Shop") -> void:
	if is_open:
		return
	if SceneRouter.is_transitioning or Dialogue.is_active:
		return
	is_open = true
	_menu.show()
	_menu.bind_inventory(inventory, shop_name)
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_menu.hide()
	closed.emit()
