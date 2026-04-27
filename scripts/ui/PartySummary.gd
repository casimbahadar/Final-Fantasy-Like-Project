extends Control

## Bottom-of-pause-menu read-only summary: each party member's name/level/HP/MP,
## plus gold and playtime. Rebuilds rows from Party.members each refresh().

const ROW_SCENE := preload("res://scenes/ui/PartySummaryRow.tscn")

@onready var _rows: VBoxContainer = %Rows
@onready var _gold: Label = %GoldLabel
@onready var _time: Label = %TimeLabel


func refresh() -> void:
	for c in _rows.get_children():
		c.queue_free()
	for pm in Party.members:
		var row = ROW_SCENE.instantiate()
		_rows.add_child(row)
		row.set_state(pm)
	_gold.text = "Gold: %d" % Party.gold
	_time.text = "Time: " + GameState.playtime_string()
