extends Control

## Top-level command menu shown when an ally's ATB fills up.
## Emits `command_chosen(command_id, payload)` where command_id is one of:
##   &"attack", &"skill", &"item", &"defend", &"run"
## The BattleManager is responsible for follow-up (skill submenu, target picker).

signal command_chosen(command: StringName, payload)
signal cancelled

@onready var _list: VBoxContainer = $Panel/VBox

var _buttons: Array[Button] = []
var _unit


func _ready() -> void:
	hide()
	for c in _list.get_children():
		if c is Button:
			_buttons.append(c)
	_buttons[0].pressed.connect(func(): command_chosen.emit(&"attack", null))
	_buttons[1].pressed.connect(func(): command_chosen.emit(&"skill", null))
	_buttons[2].pressed.connect(func(): command_chosen.emit(&"item", null))
	_buttons[3].pressed.connect(func(): command_chosen.emit(&"defend", null))
	_buttons[4].pressed.connect(func(): command_chosen.emit(&"run", null))


func open(unit) -> void:
	_unit = unit
	# Skill is enabled if the unit has at least one usable non-Attack skill.
	# Silence makes mp_cost > 0 skills unusable.
	var has_real_skills := false
	for s in unit.available_skills():
		if s == null or s.id == &"attack":
			continue
		if unit.is_silenced() and s.mp_cost > 0:
			continue
		has_real_skills = true
		break
	_buttons[1].disabled = not has_real_skills
	_buttons[2].disabled = Party.inventory.is_empty()
	show()
	# Pick first non-disabled button.
	for b in _buttons:
		if not b.disabled:
			b.grab_focus()
			break
