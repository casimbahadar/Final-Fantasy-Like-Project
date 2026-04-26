extends Control

## The visual dialogue box. Driven by the Dialogue autoload. Handles:
##   - Typewriter reveal (speed configurable, ui_accept skips to full line)
##   - Multi-line sequencing with a "▼" indicator between lines
##   - Choice menus
## Emits `finished` when a `say` sequence ends and `choice_made(int)` for
## choices.

signal finished
signal choice_made(index: int)

const CHARS_PER_SECOND := 60.0
const INDICATOR_BLINK_HZ := 2.0

@onready var _name_panel: Panel = %NamePanel
@onready var _name_label: Label = %NameLabel
@onready var _body_label: RichTextLabel = %BodyLabel
@onready var _indicator: Label = %Indicator
@onready var _choice_box: VBoxContainer = %ChoiceBox

var _lines: Array = []
var _line_index: int = -1
var _typing: bool = false
var _typing_progress: float = 0.0
var _full_text_len: int = 0
var _waiting_for_input: bool = false
var _in_choice_mode: bool = false
var _cancellable_choice: bool = false


func _ready() -> void:
	hide()
	_indicator.hide()
	_choice_box.hide()
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if _typing:
		_typing_progress += delta * CHARS_PER_SECOND
		var vis_chars := mini(int(_typing_progress), _full_text_len)
		_body_label.visible_characters = vis_chars
		if vis_chars >= _full_text_len:
			_finish_typing()
	elif _waiting_for_input:
		# Flash the ▼.
		_indicator.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * INDICATOR_BLINK_HZ * TAU)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _in_choice_mode:
		# ChoiceBox children handle their own input via focus + ui_accept.
		if _cancellable_choice and event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_emit_choice(-1)
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _typing:
			# Skip to full line on first press.
			_typing_progress = float(_full_text_len)
			_body_label.visible_characters = _full_text_len
			_finish_typing()
		elif _waiting_for_input:
			_advance_line()


func show_lines(lines: Array, speaker: String) -> void:
	_lines = lines.duplicate()
	_line_index = -1
	_in_choice_mode = false
	_choice_box.hide()
	_set_speaker(speaker)
	show()
	_advance_line()


func show_choice(prompt: String, options: Array, cancellable: bool) -> void:
	_lines = [prompt]
	_line_index = 0
	_in_choice_mode = true
	_cancellable_choice = cancellable
	_set_speaker("")
	_set_body(prompt)
	_indicator.hide()
	_waiting_for_input = false
	_typing = false
	# Build option buttons.
	for child in _choice_box.get_children():
		child.queue_free()
	for i in options.size():
		var btn := Button.new()
		btn.text = str(options[i])
		btn.theme_type_variation = "DialogueChoice"
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_emit_choice.bind(i))
		_choice_box.add_child(btn)
	_choice_box.show()
	show()
	# Defer to ensure children are in tree before grabbing focus.
	await get_tree().process_frame
	if _choice_box.get_child_count() > 0:
		_choice_box.get_child(0).grab_focus()


func _set_speaker(speaker: String) -> void:
	if speaker == "":
		_name_panel.hide()
	else:
		_name_label.text = speaker
		_name_panel.show()


func _set_body(text: String) -> void:
	_body_label.text = text
	_body_label.visible_characters = 0
	# Use the raw string length (we don't use BBCode markup in dialogue lines).
	# Avoids a one-frame staleness in RichTextLabel.get_total_character_count().
	_full_text_len = text.length()


func _advance_line() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		hide()
		_indicator.hide()
		_waiting_for_input = false
		finished.emit()
		return
	_set_body(str(_lines[_line_index]))
	_typing_progress = 0.0
	_typing = _full_text_len > 0
	_waiting_for_input = false
	_indicator.hide()


func _finish_typing() -> void:
	_typing = false
	_waiting_for_input = true
	_indicator.show()
	_indicator.modulate.a = 1.0


func _emit_choice(index: int) -> void:
	_in_choice_mode = false
	_choice_box.hide()
	hide()
	choice_made.emit(index)
