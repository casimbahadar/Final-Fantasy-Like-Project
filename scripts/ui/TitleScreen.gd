extends Control

## Title screen: New Game / Continue / Quit.
## Shown at startup (set as main_scene in project.godot).

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	quit_button.pressed.connect(_on_quit)

	# Hide quit on web/mobile builds (no real "quit" there).
	if OS.has_feature("web") or OS.has_feature("mobile"):
		quit_button.hide()

	# Disable continue if no save slots exist.
	continue_button.disabled = not _any_save_exists()
	if continue_button.disabled:
		new_game_button.grab_focus()
	else:
		continue_button.grab_focus()

	version_label.text = "v0.0.1 - Phase 0 foundation"


func _any_save_exists() -> bool:
	for slot in SaveSystem.SLOT_COUNT:
		if SaveSystem.slot_exists(slot):
			return true
	return false


func _on_new_game() -> void:
	GameState.reset()
	Party.clear()
	# Phase 1 will hook this up to the starting map.
	# For now: print so we know the wiring works.
	print("[TitleScreen] New Game pressed. World scene not yet implemented (Phase 1).")


func _on_continue() -> void:
	for slot in SaveSystem.SLOT_COUNT:
		if SaveSystem.slot_exists(slot):
			if SaveSystem.load_from(slot):
				if GameState.current_map_id != &"":
					await SceneRouter.go_to_map(GameState.current_map_id, GameState.spawn_point_id)
			return


func _on_quit() -> void:
	get_tree().quit()
