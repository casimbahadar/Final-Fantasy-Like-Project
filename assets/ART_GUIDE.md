# Art replacement guide

This game ships with placeholder SVG sprites that get the engine working but aren't suitable for a real release. Replacing them is a **drop-in** operation: every sprite is referenced by file path, so swapping the file (keeping the path the same) flips the entire game over to the new art with no code changes.

This document is the playbook for that swap on a near-zero budget.

---

## What you have today

```
assets/sprites/placeholder/   (75 SVGs, mostly procedurally-generated rectangles)
  player_<class>.svg          12 actor sprites — 16×24 (overworld), used at battle too
  npc_<role>.svg               4 NPC sprites   — 16×24
  enemy_<id>.svg              56 battle enemies — 32×32
  chest_closed/open.svg        2 props          — 16×16
  crystal_heart.svg            1 misc prop      — 32×32
```

Tilesets are *not* image-based today — `OverworldMap.gd` draws colored rectangles in `_draw()` from a `grid_string`. That's an intentional placeholder; see *Tilesets* below for the real-art path.

UI, fonts, and battle backgrounds are empty placeholders — the game uses Godot's default theme.

---

## Recommended free art sources (zero-budget path)

The shortlist below is the **only** set I'd recommend if you have no money and don't want license-compliance headaches at launch:

### Tier 1: CC0 (no attribution required, no copyleft, commercial OK)

- **Kenney.nl** — `kenney.nl/assets`. Specifically: *Tiny Town*, *Tiny Dungeon*, *Tiny Battle*, *RPG Urban Pack*, *Pixel Platformer*, *UI Pack*, *Shape Characters*. CC0. **My top recommendation** because it's the largest CC0 RPG-style library that exists and you can ship Steam/Mobile without thinking about credits.
- **OpenGameArt.org** — filter for **CC0** specifically. Look at user *Buch*, *Surt*, *Antifarea*, *Calciumtrice* — many CC0 RPG packs.
- **Itch.io free assets** — search `kind=assets` `tag=pixel-art` `tag=free`. Read each pack's license page; many are CC0 or "free for commercial use".

### Tier 2: CC-BY (free, attribution required)

- **Liberated Pixel Cup (LPC)** base set — huge character/animation library, CC-BY-SA 3.0. **Watch the SA**: it's *share-alike*, meaning derivative work has to be released under the same license. Some interpretations of SA make commercial Steam release tricky. If you want zero license risk, skip LPC entirely. If you understand the license, it's the most complete CC RPG sprite set in existence.
- **Aekashics Librarium** — `akashics.moe`. ~1500 enemy sprites in FF-style, free for commercial use with attribution. **Best free enemy art on the internet.**
- **Time Fantasy** by Finalbossblues (`finalbossblues.com`) — has both free demo packs and paid full sets. The free packs are CC-BY and stylistically perfect for this project.
- **Eric Matyas / soundimage.org** — also has some free pixel art alongside the music, CC-BY.

### Tier 3: Cheap paid packs (when free runs out)

- **Time Fantasy full packs** ($5–25 each) — about 20 themed packs covering exactly the regions this game needs (deserts, forests, dungeons, ruins). One coherent style. **If you can spend $50, this is where I'd put it.**
- **OpenGameArt patron-supported packs** ($1–5 on the artist's pages).
- **Itch.io paid asset packs** — usually $2–10, look for "RPG asset pack pixel art".

### What to **avoid**

- **Mixing styles** — the single biggest tell of an asset-flip game on Steam. Pick ONE pack family for tiles+characters+UI and stick to it. Enemies can be a second source if needed.
- **Generic Unity/Unreal asset store rips** — most of those are not licensed for redistribution.
- **AI-generated sprite art** — Steam's policy is murky and the Internet's reaction is hostile. Avoid for a real release.

---

## My recommended free combo (what I'd do for a real Steam launch)

1. **Tilesets**: Kenney *Tiny Dungeon* + *Tiny Town* + *Roguelike RPG Pack*. CC0, all 16×16, instant ship-ready. Covers caves, towns, forests, ruins, marshes.
2. **Player + NPC sprites**: Kenney *Tiny Heroes* / *Tiny Town* / *RPG Urban Pack* characters. Same 16×16 grid as tiles. CC0. Covers all 12 playable classes plus shopkeeper/villager NPCs.
3. **Battle enemies**: Aekashics Librarium pulls. CC-BY (attribution in CREDITS.md). 1500+ FF-style monsters, plenty for our 55 enemies + bosses.
4. **UI**: Kenney *UI Pack RPG Expansion*. CC0. Buttons, panels, frames, icons.
5. **Fonts**: Google Fonts (`fonts.google.com`) — *Press Start 2P*, *VT323*, *Pixelify Sans*. SIL Open Font License, free for any use.
6. **Music**: as documented in `assets/audio/README.md` — Eric Matyas, Kevin MacLeod, OpenGameArt CC0.
7. **SFX**: Kenney *RPG Sound Pack* + *Interface Sounds*. CC0.

**Total cost: $0.** Total style consistency: very high (Kenney + Aekashics is a known indie combo). Total polish ceiling: solid B+. This will not impress at GDC but it will sell on itch and survive Steam's "looks like a real game" filter.

---

## Sprite swap procedure

The repo's sprite paths are stable. Replacement is mechanical:

1. **Decide on dimensions before you start.** All current placeholders are either 16×24 (characters) or 32×32 (enemies) or 16×16 (props). Stick to a multiple of 16. If you go 32×32 for characters, tiles should also bump to 32×32 — change `OverworldMap.TILE_SIZE` from 16 to 32 in one place. Don't mix.
2. **Drop replacement files** into `assets/sprites/placeholder/` with the **same filename** as the placeholder. Godot's import system will overwrite the cached asset on next run; nothing in `data/*.tres` or any scene file needs to change.
3. **Set texture filter to Nearest.** Pixel art *must* render with `texture_filter = 0` (nearest-neighbor). Project default is already Nearest, but the Sprite2D nodes in scenes (`scenes/world/Player.tscn`, `NPC.tscn`, `Chest.tscn`, `BattleUnit.tscn`) currently override to `1` (linear) because the SVG placeholders look better smoothed. For real pixel art, flip those to `0`. One-line edit per scene.
4. **Add the source pack to `CREDITS.md`** before you commit. Track which file came from which pack; it's painful to reconstruct license compliance after the fact.

---

## Tilesets (when you replace the procedural draw)

`scripts/world/OverworldMap.gd` currently draws every tile in `_draw()` from a per-character `grid_string`. To swap to real tile art:

1. Create a Godot `TileSet` resource at `assets/tilesets/main.tres`.
2. For each tile char (`.` floor, `,` grass, `~` water, `#` wall, `+` path, `D` door), pick a tile from your imported tileset and assign it to a constant tile-id in the TileSet.
3. In `OverworldMap.gd`:
   - Remove the `_draw()` body.
   - In `_parse_grid()`, instead of populating the `grid` array with tile-type ints, call `tilemap_layer.set_cell(...)` for each char.
   - Add a child `TileMapLayer` node (Godot 4.3+) under each `OverworldMap` instance, with the imported `TileSet` assigned.

The `is_walkable` / `is_encounter_tile` / `tile_at` API stays the same — those just read the `grid` array, which we keep populated alongside the visual tilemap. So existing maps don't need to change.

This is a **one-file refactor** that takes about an hour once you have a tileset in hand. Don't do it before you have art — the procedural draw is fine until then.

---

## Fonts

Today's UI uses Godot's default fallback font. To swap:

1. Drop a `.ttf` or `.otf` into `assets/fonts/`.
2. Set the import setting to `Generate MipMaps = false`, `Antialiasing = none` for pixel-perfect bitmap fonts.
3. Open `scenes/ui/PauseMenu.tscn`, `TitleScreen.tscn`, etc., and assign the font to the root Theme. Godot will cascade it.

For a JRPG: **VT323** (terminal-y, very readable), **Press Start 2P** (1-bit retro), or **Pixelify Sans** (clean modern pixel) all work.

---

## Battle backgrounds

`scenes/battle/Battle.tscn` currently uses a flat color background. To replace:

1. Drop a 480×270 (or larger, will downscale) image into `assets/sprites/battle_bg/`.
2. Open `scenes/battle/Battle.tscn`, replace the root background `ColorRect` with a `TextureRect` + the new image.
3. Optional: per-map battle backgrounds via a new `MapData.battle_background` field. Trivial to add.

For source: search Itch.io for "RPG battle background pixel art free."

---

## Polish checklist for a real Steam launch

These are the visual polish items that convert "asset-flip" to "looks like a game":

- [ ] Title screen has a real image (not just text on a colored background).
- [ ] Battle has a non-flat background per region (5–8 backgrounds).
- [ ] Boss intros have a unique sprite zoom / shake.
- [ ] Damage popups use a real bitmap font, not the engine fallback.
- [ ] All UI panels use 9-slice borders from a UI pack, not solid colored rects.
- [ ] Status effect icons exist (not text glyphs in colored boxes).
- [ ] At least one parallax background somewhere (overworld field works).
- [ ] Item icons exist for inventory.
- [ ] Cursor / selection arrow is animated.
- [ ] Game has at least ONE original-looking screen — usually the title — that isn't pure asset reuse.

The first two and the last one are the highest-ROI; everything else is incremental. Plan ~40 hours of polish work after the art swap is mechanically done.

---

## Anti-checklist

Things that look like obvious wins but aren't:

- **Don't** start drawing original art "just to see how hard it is" before you've committed to a style. Wasted hours.
- **Don't** mix high-fidelity sprite art with the 480×270 viewport — the viewport stays small. Higher-res sprites get downscaled and look mushy. If you go to 32×32 sprites, also bump the viewport to 640×360 (one line in `project.godot`).
- **Don't** skip `CREDITS.md`. The cost of attribution is one line of text per pack. The cost of forgetting is a takedown notice.
- **Don't** outsource piecemeal — getting one artist to draw 5 sprites then another to draw 5 more produces an inconsistent set that's worse than placeholders.

---

## What I just did to make this swap easier

- Created `assets/CREDITS.md` with the exact attribution template.
- This document.
- (Future) Categorized sprite folders (`assets/sprites/actors/`, `assets/sprites/enemies/`, `assets/sprites/tiles/`, `assets/sprites/ui/`) — leave the path *changes* until you actually swap, since renaming files now means editing every `.tres` reference too.

When you're ready to start the swap:

1. Pick ONE source pack from the recommended list above.
2. Pick ONE viewport size (480×270 sticks with current code; 640×360 if you want bigger sprites).
3. Replace **only** the player sprites first. Run the game. Confirm everything visible looks coherent. **Then** replace the next batch.
4. Update `CREDITS.md` after each batch — never at the end.
