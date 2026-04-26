extends Control

## Bottom-screen status block showing each party member's name, HP/MP, and
## ATB gauge. Built dynamically from the BattleUnits passed to bind_units().

const ROW_SCENE := preload("res://scenes/ui/PartyPanelRow.tscn")

@onready var _list: VBoxContainer = $Panel/VBox

var _rows: Array = []  # Array of row controls
var _units: Array = []
var _highlight_unit = null


func bind_units(units: Array) -> void:
	_units = units
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	for u in units:
		var row = ROW_SCENE.instantiate()
		_list.add_child(row)
		_rows.append(row)
	# Defer first refresh to next frame so newly-added rows are ready.
	await get_tree().process_frame
	refresh()


func refresh() -> void:
	for i in _units.size():
		var u = _units[i]
		var row = _rows[i] if i < _rows.size() else null
		if row == null:
			continue
		row.set_state(u, u == _highlight_unit)


func highlight_unit(unit) -> void:
	_highlight_unit = unit
	refresh()


func clear_highlight() -> void:
	_highlight_unit = null
	refresh()
