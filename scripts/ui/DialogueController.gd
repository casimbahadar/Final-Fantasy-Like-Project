extends Node

## Autoloaded as `Dialogue`. Owns a CanvasLayer + DialogueBox scene that's
## always available. Public API:
##   await Dialogue.say(["line one", "line two"], "Sage")
##   var pick = await Dialogue.choose("Accept the quest?", ["Yes", "No"])
## `is_active` is true while the box is visible — gameplay scripts gate input
## on it.

const DIALOGUE_BOX_SCENE := preload("res://scenes/ui/DialogueBox.tscn")

var is_active: bool = false

var _box: Control
var _layer: CanvasLayer


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)
	_box = DIALOGUE_BOX_SCENE.instantiate()
	_layer.add_child(_box)
	_box.hide()


## Shows a sequence of lines. Awaits until the user has dismissed every line.
func say(lines: Array, speaker: String = "") -> void:
	if lines.is_empty():
		return
	if is_active:
		await _box.finished
	is_active = true
	_box.show_lines(lines, speaker)
	await _box.finished
	is_active = false


## Shows a prompt and a list of options. Returns the index the user picked.
## If the user cancels (and `cancellable` is true), returns -1.
func choose(prompt: String, options: Array, cancellable: bool = false) -> int:
	if options.is_empty():
		return -1
	if is_active:
		await _box.finished
	is_active = true
	_box.show_choice(prompt, options, cancellable)
	var idx: int = await _box.choice_made
	is_active = false
	return idx
