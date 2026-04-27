extends Control

## One row of PartySummary: name, level, HP/MP.

@onready var _name: Label = %NameLabel
@onready var _level: Label = %LevelLabel
@onready var _hp: Label = %HPLabel
@onready var _mp: Label = %MPLabel


func set_state(pm) -> void:
	var actor: Actor = pm.actor_data()
	_name.text = actor.display_name if actor != null else "?"
	_level.text = "Lv %d" % pm.level
	_hp.text = "HP %d/%d" % [pm.hp, pm.max_hp()]
	_mp.text = "MP %d/%d" % [pm.mp, pm.max_mp()]
	if not pm.is_alive():
		modulate = Color(0.6, 0.4, 0.4)
	else:
		modulate = Color(1, 1, 1)
