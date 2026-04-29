# Last Light of Auren

A Final Fantasy–inspired JRPG built in **Godot 4**, designed to ship to **itch.io (Web)**, **Android**, and **iOS** from a single codebase. Visual style targets the GBA era (FF1–6, FFTA) with a clear upgrade path to 2D-HD (Octopath, FF Pixel Remaster).

> **Status:** Phase 12 — **insertion pass.** Four entirely new chapter regions slotted between existing ones (Sun-Dried Wastes, Sky Islands, Cinder Marsh, Royal Crypt), each with its own boss, gear tier, and theme. The main story is now **12 distinct dungeon regions** (8 original + 4 new) plus 7 mini-boss middle floors, running ~8–9 hours. 40 enemies, 19 bosses (12 main + 7 mini), 27 maps. See [`CONTENT.md`](CONTENT.md) for side-content authoring.

## Chapter map

```
   Ch 1: Plaza → Outskirts → Crystal Cave Entrance → CRYSTAL TUNNELS (mini: Crystal Sentinel)
                                                  → Crystal Cave Deep
                                                       └─ BOSS: Crystal Wraith  +  Kael joins
   Ch 2: Forest Path → FOREST HEART (mini: Treant)
   Ch 3: Brighthollow → TEMPLE ANTECHAMBER (mini: Skeletal Champion)
                       → Sunken Temple
                                                       └─ BOSS: Hollow King  +  Aila found
   Ch 4: Mountain Pass (Tessera joins) → MOUNTAIN PEAK (mini: Wyvern)
                       → Storm Aerie
                                                       └─ BOSS: Stormwyrm
                                                              "three roots cut" — but the seal is gone
   Ch 5: TIDAL REEF (mini: Tide Beast) → Ashen Coast
                                                       └─ BOSS: Drowned Choir
   Ch 6: HOLLOW GATE (mini: Inquisitor) → Hollow Court
                                                       └─ BOSS: The Pretender
   Ch 7: WOUND DESCENT (mini: Hollow Aldric) → World's Wound
                                                       └─ BOSS: The First Plague
   Ch 8: Where the King Waits
                                                       └─ FINAL BOSS: The Sovereign Eternal
                                                              ENDING: a sunrise across Auren
```

## Roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Project skeleton, autoloads, resource schemas, title screen | ✅ done |
| 1 | Tile-based overworld, player movement, NPCs, dialogue, map transitions | ✅ done |
| 2 | ATB battle scene, skills, items, victory/defeat, encounters | ✅ done |
| 3 | Pause menu, inventory, equipment, save/load (3 slots) | ✅ done |
| 4 | Vertical slice: town, shop, inn, dungeon with chests, boss, ending | ✅ done |
| 5 | Mobile touch controls, audio settings, export targets | ✅ done |
| 6 | Status effects + battle polish (hit flash, screen shake, status badges) | ✅ done |
| 7 | Chapter 2: Rogue class, Kael, Whispering Wood, status framework deepening | ✅ done |
| 8 | Chapter 3: Cleric class, Mira, Brighthollow, Sunken Temple, Hollow King | ✅ done |
| 9 | Chapter 4: Dragoon class, Tessera, Mountain Pass, Storm Aerie, Stormwyrm | ✅ done |
| 10 | Chapters 5–8: full main story arc (Drowned Choir → Pretender → First Plague → Sovereign Eternal) | ✅ done |
| 11 | Deepening pass: mid-floor mini-boss in every chapter (Sentinel, Treant, Champion, Wyvern, Tide Beast, Inquisitor, Hollow Twin) | ✅ done |
| 12 | Insertion pass: 4 new chapters (Sun-Dried Wastes, Sky Islands, Cinder Marsh, Royal Crypt) | ✅ done |
| 13 | Side-content layer: town quests, optional dungeons, hunt log, postgame | ⏳ |
| 14+ | Music & SFX, real art swap (see [`CONTENT.md`](CONTENT.md) and [`assets/audio/README.md`](assets/audio/README.md)) | ⏳ |

See [`/root/.claude/plans/i-want-to-create-enchanted-nygaard.md`](../../root/.claude/plans/i-want-to-create-enchanted-nygaard.md) for the full plan (local file).

## Requirements

- **Godot 4.2 or newer** — download from <https://godotengine.org/download>
- Git (you already have it if you're reading this from a clone)
- For mobile exports later: Android Studio + JDK (Android), Xcode on a Mac (iOS)

## How to open and run

1. Install Godot 4.2+.
2. Open Godot, click **Import**, pick this folder's `project.godot`.
3. Click the **Play** button (▶) in the top-right, or press <kbd>F5</kbd>.
4. Title screen → **New Game** → drops you in the Town Plaza. Talk to NPCs, walk south through the door to reach the Outskirts Road. Walk on the grass for a bit — you'll trigger a battle.

### Battle controls
- Arrows: move cursor / select target
- <kbd>Enter</kbd> / <kbd>Z</kbd>: confirm
- <kbd>Esc</kbd> / <kbd>X</kbd>: cancel (back out of submenu / target picker)
- Lyra learns **Cure** at level 3 — keep her alive!

### Pause menu (overworld only)
- <kbd>Q</kbd>: open / close
- **Items** — use Potions / Ethers on a party member
- **Equip** — swap weapons / armor / accessories with stat preview
- **Status** — see full stats, level, XP-to-next, equipment summary
- **Save** / **Load** — three slots, each card shows playtime and timestamp
- **Settings** — BGM / SFX volume sliders, text speed, touch UI mode (auto / on / off). Persists to `user://settings.json`.
- **Title** — return to title screen (with confirmation)

### Touch controls
On mobile (or any device with a touchscreen) on-screen buttons appear automatically: a D-pad in the lower-left, A / B in the lower-right, and a MENU button in the upper-right. Force on or off in **Pause → Settings → Touch UI**.

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

## Exporting (Phase 5)

Godot generates `export_presets.cfg` interactively in the export dialog, so the project deliberately doesn't ship a hand-written one. Walk through the export dialog once per platform and Godot writes it for you.

### Common to every export

1. Open the project in Godot 4.2+.
2. **Project → Export...**
3. **Manage Export Templates...** the first time, then **Download and Install**.

### Web (itch.io)

1. **Add → Web** in the export dialog.
2. Set **Export Path** to `exports/web/index.html`.
3. **Export Project** (uncheck "Export with Debug").
4. On itch.io: New project → Kind **HTML**. Zip the contents of `exports/web/` (not the folder itself) and upload as a Web build. **Set viewport size 480×270** in itch.io's project page or it'll show at 1×1.

### Android

1. Install **Android Studio** + an Android SDK + JDK 17.
2. In Godot: **Editor Settings → Export → Android** — point to the SDK and the debug keystore (Editor Settings has a one-click "Generate Debug Keystore" button).
3. **Add → Android** in the export dialog.
4. Fill in **Package → Unique Name** (e.g. `com.yourname.crystalplague`), **Name**, version code/name.
5. Under **Display**, **uncheck Immersive Mode** for the first build (easier debugging).
6. Plug in an Android phone with USB debugging on. Click the small **device icon** in Godot's top bar to one-click run on device. Or **Export Project** to write an APK / AAB to `exports/android/`.
7. For Google Play: build an **AAB** (Android App Bundle), set up a release keystore, upload to the Play Console internal testing track first.

### iOS

iOS requires a **Mac**, **Xcode 14+**, and an **Apple Developer account** ($99/year for App Store). The Godot side:

1. **Add → iOS** in the export dialog.
2. Fill in **Application → Bundle Identifier**, app name, signing team ID, provisioning profile.
3. **Export Project** writes an Xcode project to `exports/ios/`.
4. Open that `.xcodeproj` in Xcode, set the signing team, build to a connected device or to TestFlight.

### Performance notes for mobile

- The viewport (480×270) is intentionally small so SVG sprites rasterize cheaply on mid-range Android.
- Renderer is **GL Compatibility** (set in `project.godot`) — works on all but the oldest devices and exports to Web cleanly.
- Touch-control detection uses `OS.has_feature("mobile") || DisplayServer.is_touchscreen_available()`. Override in **Settings**.

## Branch policy

All development happens on `claude/fantasy-rpg-game-B39d1`. Each phase ends with a commit + push.

## License

Code: TBD. Game content (sprites, audio) will use CC0/CC-BY assets in Phase 0–1; we'll list attributions in `/assets/CREDITS.md` once those are imported.
