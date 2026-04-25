extends Node

## Centralized BGM + SFX playback with a simple crossfade.

const FADE_TIME := 0.6

var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _active_is_a: bool = true
var _current_stream: AudioStream


func _ready() -> void:
	_bgm_a = _make_player(-6.0)
	_bgm_b = _make_player(-6.0)
	_sfx = _make_player(0.0)


func _make_player(default_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = default_db
	add_child(p)
	return p


func play_bgm(stream: AudioStream) -> void:
	if stream == _current_stream:
		return
	_current_stream = stream

	var fading_out: AudioStreamPlayer = _bgm_a if _active_is_a else _bgm_b
	var fading_in: AudioStreamPlayer = _bgm_b if _active_is_a else _bgm_a
	_active_is_a = not _active_is_a

	fading_in.stream = stream
	fading_in.volume_db = -40.0
	if stream != null:
		fading_in.play()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(fading_in, "volume_db", -6.0, FADE_TIME)
	tween.tween_property(fading_out, "volume_db", -40.0, FADE_TIME)
	tween.chain().tween_callback(fading_out.stop)


func stop_bgm() -> void:
	play_bgm(null)


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.volume_db = volume_db
	_sfx.play()
