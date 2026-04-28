extends Node

## Autoloaded as `Settings`. Holds user preferences (volumes, text speed,
## touch-control toggle), persists them to user://settings.json, applies them
## to the running engine. UI widgets bind to the values and call set_*
## helpers to keep state, persistence, and runtime in sync in one place.

const SETTINGS_PATH := "user://settings.json"
const VERSION := 1

# Default values:
const DEFAULT_BGM_VOLUME := 0.7   # 0.0 = mute, 1.0 = unity
const DEFAULT_SFX_VOLUME := 0.85
const DEFAULT_TEXT_CPS := 60.0    # characters per second in dialogue
const DEFAULT_TOUCH_AUTO := true  # touch shown automatically on mobile

signal changed

var bgm_volume: float = DEFAULT_BGM_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var text_cps: float = DEFAULT_TEXT_CPS
## "auto" → on for mobile, off otherwise. true → always on. false → always off.
var touch_mode: String = "auto"


func _ready() -> void:
	load_from_disk()
	apply_all()


func set_bgm_volume(v: float) -> void:
	bgm_volume = clampf(v, 0.0, 1.0)
	_apply_bus("Music", bgm_volume)
	_save_deferred()
	changed.emit()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_bus("SFX", sfx_volume)
	_save_deferred()
	changed.emit()


func set_text_cps(v: float) -> void:
	text_cps = clampf(v, 10.0, 240.0)
	_save_deferred()
	changed.emit()


func set_touch_mode(mode: String) -> void:
	if mode != "auto" and mode != "on" and mode != "off":
		return
	touch_mode = mode
	_save_deferred()
	changed.emit()


func touch_should_show() -> bool:
	if touch_mode == "on":
		return true
	if touch_mode == "off":
		return false
	# auto: on for mobile / web-on-touch, off otherwise.
	if OS.has_feature("mobile"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	return false


func apply_all() -> void:
	_apply_bus("Music", bgm_volume)
	_apply_bus("SFX", sfx_volume)
	# Text speed and touch are read by their consumers — nothing to push here.
	changed.emit()


func _apply_bus(bus_name: String, value_0_1: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	# Linear 0..1 → -40 dB to 0 dB curve, with a hard mute at value < 0.005.
	if value_0_1 <= 0.005:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(value_0_1))


func load_from_disk() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	bgm_volume = clampf(float(parsed.get("bgm_volume", DEFAULT_BGM_VOLUME)), 0.0, 1.0)
	sfx_volume = clampf(float(parsed.get("sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	text_cps = clampf(float(parsed.get("text_cps", DEFAULT_TEXT_CPS)), 10.0, 240.0)
	var mode = parsed.get("touch_mode", "auto")
	if mode in ["auto", "on", "off"]:
		touch_mode = mode


func save_to_disk() -> void:
	var data := {
		"version": VERSION,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"text_cps": text_cps,
		"touch_mode": touch_mode,
	}
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()


# Coalesce rapid setter calls (e.g. dragging a slider) into one disk write.
var _save_pending: bool = false

func _save_deferred() -> void:
	if _save_pending:
		return
	_save_pending = true
	# Defer past the current frame; if many setters fire, only one save runs.
	call_deferred("_do_save")


func _do_save() -> void:
	_save_pending = false
	save_to_disk()
