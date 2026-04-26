extends Node2D

## Floating damage / heal number that rises and fades, then frees itself.

const RISE := 24.0
const LIFE := 0.85

@onready var _label: Label = $Label

var _t: float = 0.0
var _start_pos: Vector2


func show_text(text: String, color: Color) -> void:
	_label.text = text
	_label.modulate = color


func _ready() -> void:
	_start_pos = position


func _process(delta: float) -> void:
	_t += delta
	var progress := _t / LIFE
	if progress >= 1.0:
		queue_free()
		return
	# Ease-out vertical rise + fade in last third.
	position.y = _start_pos.y - RISE * (1.0 - pow(1.0 - progress, 2.0))
	if progress > 0.66:
		_label.modulate.a = 1.0 - (progress - 0.66) / 0.34
