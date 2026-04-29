extends Control

## Title screen: New Game / Continue / Quit.
## Shown at startup (set as main_scene in project.godot).

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var new_game_plus_button: Button = %NewGamePlusButton
@onready var quit_button: Button = %QuitButton
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	new_game_plus_button.pressed.connect(_on_new_game_plus)
	quit_button.pressed.connect(_on_quit)

	# Hide quit on web/mobile builds (no real "quit" there).
	if OS.has_feature("web") or OS.has_feature("mobile"):
		quit_button.hide()

	# Disable continue if no save slots exist.
	continue_button.disabled = not _any_save_exists()
	# New Game+ is only enabled if at least one save has reached the credits.
	new_game_plus_button.disabled = not _any_save_complete()
	if continue_button.disabled:
		new_game_button.grab_focus()
	else:
		continue_button.grab_focus()

	version_label.text = "v0.1.4 — rebalance + arena + 2 bonus dungeons + 3-stage postgame + NG+"


func _any_save_exists() -> bool:
	for slot in SaveSystem.SLOT_COUNT:
		if SaveSystem.slot_exists(slot):
			return true
	return false


func _any_save_complete() -> bool:
	for slot in SaveSystem.SLOT_COUNT:
		if not SaveSystem.slot_exists(slot):
			continue
		var s := SaveSystem.slot_summary(slot)
		if s.get("game_complete", false):
			return true
	return false


func _most_recent_complete_slot() -> int:
	var best_slot := -1
	var best_ts := 0
	for slot in SaveSystem.SLOT_COUNT:
		if not SaveSystem.slot_exists(slot):
			continue
		var s := SaveSystem.slot_summary(slot)
		if not s.get("game_complete", false):
			continue
		var ts := int(s.get("timestamp", 0))
		if ts >= best_ts:
			best_ts = ts
			best_slot = slot
	return best_slot


func _on_new_game() -> void:
	GameState.reset()
	Party.clear()
	Hunt.clear()
	Party.add_member(&"aldric")
	Party.add_member(&"lyra")
	Party.add_gold(100)
	Party.add_item(&"potion", 3)
	Party.add_item(&"antidote", 1)
	# Equip starter gear so newcomers see equipment in action.
	if Party.members.size() >= 1:
		Party.members[0].equip_weapon = &"bronze_sword"
		Party.members[0].equip_armor = &"leather_armor"
	if Party.members.size() >= 2:
		Party.members[1].equip_weapon = &"oak_staff"
	await SceneRouter.go_to_map(&"plaza", &"default")


func _on_continue() -> void:
	# Pick the most recently saved slot.
	var best_slot := -1
	var best_ts := 0
	for slot in SaveSystem.SLOT_COUNT:
		if not SaveSystem.slot_exists(slot):
			continue
		var s := SaveSystem.slot_summary(slot)
		var ts := int(s.get("timestamp", 0))
		if ts >= best_ts:
			best_ts = ts
			best_slot = slot
	if best_slot < 0:
		return
	if not SaveSystem.load_from(best_slot):
		return
	if GameState.current_map_id != &"":
		await SceneRouter.go_to_map(GameState.current_map_id, GameState.spawn_point_id)


func _on_new_game_plus() -> void:
	# Load the most recent post-credits save, then wipe story flags so the
	# player walks back into chapter 1 with their levels, gear, inventory, and
	# Hunt log intact. Increments ng_plus_count which BattleUnit reads to scale
	# enemy HP and atk on subsequent battles.
	var slot := _most_recent_complete_slot()
	if slot < 0:
		return
	if not SaveSystem.load_from(slot):
		return
	var carryover := GameState.ng_plus_count + 1
	GameState.reset_for_ng_plus()
	GameState.ng_plus_count = carryover
	# Heal the party so the player isn't dropped into NG+ with mid-fight HP.
	for pm in Party.members:
		pm.hp = pm.max_hp()
		pm.mp = pm.max_mp()
	await SceneRouter.go_to_map(&"plaza", &"default")


func _on_quit() -> void:
	get_tree().quit()
