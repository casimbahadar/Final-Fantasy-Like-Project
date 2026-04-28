extends Node

## One-shot story trigger. Fires its lines once when the map loads and the
## flag is unset, then sets the flag so reloads don't replay it. Player input
## is implicitly blocked because PlayerController gates on Dialogue.is_active.

@export var lines: PackedStringArray = PackedStringArray()
@export var speaker: String = ""
## Required — without it, the cutscene would replay every map load.
@export var seen_flag: StringName = &""


func _ready() -> void:
	if seen_flag == &"":
		push_warning("IntroTrigger: seen_flag is unset; cutscene would replay forever. Skipping.")
		return
	if GameState.get_flag(seen_flag, false):
		return
	if lines.is_empty():
		return
	# Wait two frames so the parent map finishes its _post_setup (player spawn,
	# warp wiring, BGM start) before the dialogue takes over.
	await get_tree().process_frame
	await get_tree().process_frame
	await Dialogue.say(Array(lines), speaker)
	GameState.set_flag(seen_flag, true)
