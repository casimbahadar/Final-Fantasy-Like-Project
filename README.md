# Final-Fantasy-Like-Project

A Final Fantasy–inspired JRPG built in **Godot 4**, designed to ship to **itch.io (Web)**, **Android**, and **iOS** from a single codebase. Visual style targets the GBA era (FF1–6, FFTA) with a clear upgrade path to 2D-HD (Octopath, FF Pixel Remaster).

> **Status:** Phase 1 — overworld, NPCs, dialogue, and map transitions are working. New Game drops you on the Town Plaza with a 2-character party. Battles come in Phase 2.

## Roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Project skeleton, autoloads, resource schemas, title screen | ✅ done |
| 1 | Tile-based overworld, player movement, NPCs, dialogue, map transitions | ✅ done |
| 2 | ATB battle scene, skills, items, status effects, victory/defeat | ⏳ |
| 3 | Pause menu, inventory, equipment, save/load (3 slots) | ⏳ |
| 4 | Vertical slice content: town, shop, inn, dungeon, boss | ⏳ |
| 5 | Mobile touch controls, Android export, iOS prep | ⏳ |
| 6+ | Story chapters, party expansion, optional 2D-HD upgrade | ⏳ |

See [`/root/.claude/plans/i-want-to-create-enchanted-nygaard.md`](../../root/.claude/plans/i-want-to-create-enchanted-nygaard.md) for the full plan (local file).

## Requirements

- **Godot 4.2 or newer** — download from <https://godotengine.org/download>
- Git (you already have it if you're reading this from a clone)
- For mobile exports later: Android Studio + JDK (Android), Xcode on a Mac (iOS)

## How to open and run

1. Install Godot 4.2+.
2. Open Godot, click **Import**, pick this folder's `project.godot`.
3. Click the **Play** button (▶) in the top-right, or press <kbd>F5</kbd>.
4. Title screen → **New Game** → drops you in the Town Plaza. Talk to the three NPCs, walk south through the door to reach the Outskirts Road, walk back through the north door to return.

On first import Godot will:
- Generate `.godot/` (cached imports — gitignored)
- Assign UIDs to scenes/resources (don't worry about the `[res://...]` warnings — they'll resolve)

## Controls (current)

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Confirm | <kbd>Enter</kbd> / <kbd>Space</kbd> / <kbd>Z</kbd> | A |
| Cancel  | <kbd>Esc</kbd> / <kbd>X</kbd> | B |
| Move    | Arrows / <kbd>WASD</kbd> | D-pad / Left stick |
| Menu    | <kbd>Q</kbd> | Select |

Touch controls (mobile) come in Phase 5.

## Project Layout

```
project.godot            Godot project config + autoloads + input map
icon.svg                 Window/app icon (placeholder)
assets/                  Art, audio, fonts (currently empty — drop free packs here)
data/                    Game content as .tres resources, RPG-Maker-style database
  actors/                Playable characters (Aldric the warrior, Lyra the mage)
  classes/               Warrior, Mage — defines stat bias and learnsets
  skills/                Attack, Fire, Cure
  items/                 Potion, Ether, Bronze Sword, Oak Staff, Leather Armor
  enemies/               Slime, Goblin
  troops/                Pre-configured encounters (e.g. two_slimes)
  maps/                  MapData entries (added in Phase 1)
scenes/                  Godot scene files (.tscn)
  ui/TitleScreen.tscn    Title screen (main scene)
  ui/DialogueBox.tscn    Reusable dialogue box (typewriter + choices)
  world/Player.tscn      Player character (grid-snapped, camera follows)
  world/NPC.tscn         Reusable NPC template (override sprite_texture per use)
  world/maps/Plaza.tscn  Starter town plaza with 3 NPCs and a south exit
  world/maps/Outskirts.tscn  South road map (loops back to plaza)
scripts/
  globals/               Autoloaded singletons (run from boot)
    Database.gd          Loads every .tres in data/ into id-keyed dictionaries
    GameState.gd         Story flags, current map id, playtime
    Party.gd             Party members, inventory, gold, equipment
    SaveSystem.gd        JSON save/load to user:// (3 slots)
    AudioManager.gd      BGM crossfade + SFX
    SceneRouter.gd       Fade-to-black scene transitions + transition flag
  resources/             Schema scripts for the .tres files in data/
  ui/                    Title screen, Dialogue autoload + box
  world/                 OverworldMap, PlayerController, NPC, SpawnPoint, WarpTrigger
  battle/                (filled out in Phase 2)
```

## Adding content

Game content lives as **`.tres` files in `data/`** — no code changes needed to add a new sword, spell, or enemy. Open the `.tres` file in Godot's inspector or copy an existing one and edit values. `Database.gd` autoloads everything at boot.

### Adding a new map (Phase 1+)

1. Duplicate `scenes/world/maps/Plaza.tscn` and rename. Set the root's `map_id` to a unique StringName and rewrite `grid_string` (use `#=wall .=floor ,=grass ~=water +=path D=door`).
2. Add `SpawnPoint` nodes for each entry direction (give them unique `spawn_id`s).
3. Add `WarpTrigger` nodes pointing at adjacent maps' spawn ids.
4. Drop in `NPC.tscn` instances; set `npc_name`, `grid_position`, `lines`, and `sprite_texture`.
5. Create a `data/maps/<your_map>.tres` (`MapData` resource) with the same `id` and the scene's path. Database autoloads it on next run.
6. Wire it from another map via `WarpTrigger.target_map_id`.

## Branch policy

All development happens on `claude/fantasy-rpg-game-B39d1`. Each phase ends with a commit + push.

## License

Code: TBD. Game content (sprites, audio) will use CC0/CC-BY assets in Phase 0–1; we'll list attributions in `/assets/CREDITS.md` once those are imported.
