extends Control

## Settings subview: BGM volume, SFX volume, text speed, touch-control mode.
## Bound to the Settings autoload — sliders push values via setters which
## persist + apply immediately.

signal back_requested

@onready var _bgm_slider: HSlider = %BGMSlider
@onready var _bgm_value: Label = %BGMValue
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _sfx_value: Label = %SFXValue
@onready var _text_slider: HSlider = %TextSlider
@onready var _text_value: Label = %TextValue
@onready var _touch_option: OptionButton = %TouchOption


func _ready() -> void:
	# Populate the touch option button.
	_touch_option.add_item("Auto", 0)
	_touch_option.add_item("Always on", 1)
	_touch_option.add_item("Always off", 2)

	_bgm_slider.value_changed.connect(_on_bgm_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_text_slider.value_changed.connect(_on_text_changed)
	_touch_option.item_selected.connect(_on_touch_option)


func _on_bgm_changed(v: float) -> void:
	Settings.set_bgm_volume(v)
	_refresh_labels()


func _on_sfx_changed(v: float) -> void:
	Settings.set_sfx_volume(v)
	_refresh_labels()


func _on_text_changed(v: float) -> void:
	Settings.set_text_cps(v)
	_refresh_labels()


func activate() -> void:
	# Pull current values into the widgets.
	_bgm_slider.value = Settings.bgm_volume
	_sfx_slider.value = Settings.sfx_volume
	_text_slider.value = Settings.text_cps
	_touch_option.selected = _touch_index_for(Settings.touch_mode)
	_refresh_labels()
	_bgm_slider.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible or Dialogue.is_active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _refresh_labels() -> void:
	_bgm_value.text = "%d%%" % int(round(_bgm_slider.value * 100.0))
	_sfx_value.text = "%d%%" % int(round(_sfx_slider.value * 100.0))
	_text_value.text = "%d / sec" % int(round(_text_slider.value))


func _on_touch_option(idx: int) -> void:
	match idx:
		0: Settings.set_touch_mode("auto")
		1: Settings.set_touch_mode("on")
		2: Settings.set_touch_mode("off")


func _touch_index_for(mode: String) -> int:
	match mode:
		"on": return 1
		"off": return 2
		_: return 0
