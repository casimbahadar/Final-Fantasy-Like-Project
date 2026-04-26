extends Node2D

## Triangle pointer that hovers over a selectable target. Public coroutine
## pick(units) returns the chosen BattleUnit, or null on cancel.

signal selected(unit)
signal cancelled

const HOVER_AMPLITUDE := 2.0
const HOVER_HZ := 2.0

@onready var _arrow: Polygon2D = $Arrow

var _pool: Array = []
var _idx: int = 0
var _waiting: bool = false


func _ready() -> void:
	hide()


func pick(pool: Array):
	_pool = pool.duplicate()
	if _pool.is_empty():
		return null
	_idx = 0
	_waiting = true
	show()
	_snap()
	while _waiting:
		await get_tree().process_frame
	hide()
	if _idx < 0:
		return null
	return _pool[_idx]


func _process(_delta: float) -> void:
	if not _waiting:
		return
	# Drop off-screen cursor when its target dies mid-selection.
	if not _pool[_idx].is_alive():
		_advance(1)
		_snap()
	# Bobble.
	var bob := sin(Time.get_ticks_msec() * 0.001 * HOVER_HZ * TAU) * HOVER_AMPLITUDE
	_arrow.position.y = bob


func _input(event: InputEvent) -> void:
	if not _waiting:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_idx = -1
		_waiting = false
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _pool[_idx].is_alive():
			_waiting = false
	elif event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		_advance(-1)
		_snap()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_advance(1)
		_snap()


func _advance(step: int) -> void:
	if _pool.is_empty():
		return
	# Wrap, skipping dead targets. Bail out after a full cycle to avoid infinite loop.
	for _i in _pool.size():
		_idx = (_idx + step) % _pool.size()
		if _idx < 0:
			_idx += _pool.size()
		if _pool[_idx].is_alive():
			return


func _snap() -> void:
	if _pool.is_empty() or _idx < 0 or _idx >= _pool.size():
		return
	var t = _pool[_idx]
	if t == null:
		return
	# Position cursor just left of the target sprite.
	position = t.position + Vector2(-20, 0)
