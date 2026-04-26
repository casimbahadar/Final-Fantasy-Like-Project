extends Control

## One row of the party stats panel: name, HP/MP, ATB bar.

@onready var _name: Label = %NameLabel
@onready var _hp: Label = %HPLabel
@onready var _mp: Label = %MPLabel
@onready var _atb: ProgressBar = %ATBBar
@onready var _bg: ColorRect = %Background


func set_state(unit, is_highlighted: bool) -> void:
	_name.text = unit.display_name()
	_hp.text = "HP %d/%d" % [unit.hp, unit.max_hp()]
	_mp.text = "MP %d/%d" % [unit.mp, unit.max_mp()]
	_atb.value = unit.atb * 100.0
	_atb.modulate = Color(1, 1, 1, 1.0 if unit.is_alive() else 0.3)
	if not unit.is_alive():
		_name.modulate = Color(0.6, 0.4, 0.4)
		_hp.modulate = Color(0.6, 0.4, 0.4)
	else:
		_name.modulate = Color(1, 1, 1)
		_hp.modulate = Color(1, 1, 1)
	if is_highlighted:
		_bg.color = Color(0.2, 0.3, 0.5, 0.6)
	else:
		_bg.color = Color(0, 0, 0, 0)
