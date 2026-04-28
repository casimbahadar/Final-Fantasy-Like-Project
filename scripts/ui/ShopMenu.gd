extends Control

## Modal shop overlay. Two tabs: BUY shows items the merchant sells; SELL shows
## items in the player's inventory at half price. Pressing ui_cancel from the
## item list returns to the tab row; from the tab row closes the shop.

signal close_requested

enum Tab { BUY, SELL }

@onready var _shop_label: Label = %ShopName
@onready var _gold_label: Label = %GoldLabel
@onready var _buy_btn: Button = %BuyTab
@onready var _sell_btn: Button = %SellTab
@onready var _list: VBoxContainer = %ItemList
@onready var _description: Label = %Description
@onready var _empty: Label = %Empty

var _inventory_for_sale: Array = []  # Array[StringName]
var _tab: Tab = Tab.BUY


func _ready() -> void:
	hide()
	_buy_btn.pressed.connect(func(): _switch_tab(Tab.BUY))
	_sell_btn.pressed.connect(func(): _switch_tab(Tab.SELL))


func bind_inventory(inv: Array, shop_name: String) -> void:
	_inventory_for_sale = inv.duplicate()
	_shop_label.text = shop_name
	_tab = Tab.BUY
	_refresh_gold()
	_rebuild_list()
	_buy_btn.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible or Dialogue.is_active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# If focus is in the item list, return to the tab row. Otherwise close.
		if _list_has_focus():
			if _tab == Tab.BUY:
				_buy_btn.grab_focus()
			else:
				_sell_btn.grab_focus()
		else:
			close_requested.emit()


func _list_has_focus() -> bool:
	for c in _list.get_children():
		if c is Button and c.has_focus():
			return true
	return false


func _switch_tab(t: Tab) -> void:
	_tab = t
	_rebuild_list()


func _refresh_gold() -> void:
	_gold_label.text = "Gold: %d" % Party.gold


func _rebuild_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	_description.text = ""
	var entries: Array = []
	if _tab == Tab.BUY:
		for id in _inventory_for_sale:
			entries.append(id)
	else:
		for id in Party.inventory:
			# Don't sell key items.
			var item: Item = Database.item(id)
			if item != null and item.kind != Item.ItemKind.KEY:
				entries.append(id)
	_empty.visible = entries.is_empty()

	for id in entries:
		var item: Item = Database.item(id)
		if item == null:
			continue
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		if _tab == Tab.BUY:
			btn.text = "%s — %d g" % [item.display_name, item.buy_price]
			btn.disabled = item.buy_price > Party.gold
			btn.pressed.connect(_on_buy.bind(id))
		else:
			var owned: int = Party.inventory.get(id, 0)
			var price := item.sell_price if item.sell_price > 0 else maxi(1, item.buy_price / 2)
			btn.text = "%s × %d — %d g" % [item.display_name, owned, price]
			btn.disabled = owned <= 0
			btn.pressed.connect(_on_sell.bind(id, price))
		btn.focus_entered.connect(func(): _description.text = item.description)
		_list.add_child(btn)
	await get_tree().process_frame
	for c in _list.get_children():
		if c is Button and not c.disabled:
			c.grab_focus()
			return


func _on_buy(item_id: StringName) -> void:
	var item: Item = Database.item(item_id)
	if item == null or item.buy_price > Party.gold:
		return
	Party.add_gold(-item.buy_price)
	Party.add_item(item_id, 1)
	_refresh_gold()
	_rebuild_list()


func _on_sell(item_id: StringName, price: int) -> void:
	if not Party.remove_item(item_id, 1):
		return
	Party.add_gold(price)
	_refresh_gold()
	_rebuild_list()
