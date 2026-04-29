# Audio assets

This folder is empty by design — Godot autoimports any `.ogg` you drop in here, and the rest of the codebase reads them via `AudioStream` references on `MapData` / `Troop` resources, so adding music is **drop file → assign in inspector → save**.

```
audio/
  bgm/        — looping background tracks (towns, fields, dungeons, battle)
  sfx/        — short one-shots (menu confirm, hit, item pickup)
  jingles/    — non-looping stings (victory, level-up, fanfare)
```

## Curated sources (all free, license-clear)

All of these are widely used in commercial indie games. Read the license on each track — most need attribution, some (CC0) don't.

### Background music

- **Eric Matyas / [soundimage.org](https://soundimage.org)** — huge fantasy/RPG library. Look in *Fantasy 1–11*, *Drama 1–6*, *Town/Village*, *Dark/Ominous*. License: free with attribution to "Eric Matyas / soundimage.org".
- **Kevin MacLeod / [incompetech.com](https://incompetech.com)** — CC-BY 4.0. Search for *Wizard's Castle*, *Distant Tower*, *Five Armies*, *Adventure Meme*. Filter by genre "Folk".
- **OpenGameArt.org** — search tags `[fantasy] [rpg] [town] [battle] [boss] [dungeon]`. Each track lists its own license; sort by CC0 first, then CC-BY.
- **Joel Steudler** — paid asset packs at humble prices ($10–30) covering full RPG soundtracks. Search "RPG Music Pack".
- **HumbleBundle / itch.io asset packs** — periodic music-pack bundles for $1–$5 each.

### Sound effects

- **Kenney.nl Audio Packs** — all CC0. *RPG Sound Pack*, *Sci-fi Sounds*, *Interface Sounds*, *Impact Sounds*. Drop in and use.
- **Freesound.org** — mixed licenses (filter by CC0). Search "sword hit", "menu blip", "level up".
- **OpenGameArt.org** — same as above for SFX.

### Jingles / stings

- **Eric Matyas** has dedicated *Misc* and *Action* sections with short stings.
- **Kenney.nl Audio Packs** include UI confirm / cancel / win jingles.

## How to wire a track

1. Download a track (`.ogg` is preferred — Godot's native streaming format; `.wav` works too but bigger).
2. Drop it into `assets/audio/bgm/` (or `sfx/` / `jingles/`).
3. In Godot's FileSystem dock, double-click the file. The Import tab should auto-detect as `AudioStreamOggVorbis` (for `.ogg`) — for BGM, set **Loop** → `true` in the import settings, then click **Reimport**.
4. Open the relevant data resource:
   - **Per-map music**: `data/maps/<map_id>.tres` → drag the `.ogg` onto the `bgm` slot.
   - **Per-encounter music**: `data/troops/<troop_id>.tres` → `battle_bgm` slot.
   - **Victory jingle**: `data/troops/<troop_id>.tres` → `victory_jingle` slot.
5. Save. The Database picks it up next run, and `AudioManager.play_bgm` crossfades between tracks automatically when the player changes maps.

## Recommended tracks per area (suggestions, fill in as you go)

| Area | Mood | Search terms |
|---|---|---|
| Title screen | Hopeful / cinematic intro | "fantasy adventure intro", "epic theme" |
| Plaza | Warm village | "town", "village", "tavern" |
| Outskirts Road | Travel | "field", "world map", "journey" |
| Crystal Cave | Mysterious / dark | "cave", "dungeon", "crystal", "ambient ominous" |
| Boss: Crystal Wraith | Tense | "boss battle", "battle 2", "epic boss" |
| Whispering Wood | Eerie forest | "forest", "ancient", "mystery" |
| Brighthollow | Brighter town | "festival", "merchant", "bright town" |
| Sunken Temple | Underwater / ruins | "ancient ruin", "sunken", "lost temple" |
| Boss: Hollow King | Big boss | "final boss", "dark king" |
| Random battle | Standard combat | "battle", "encounter", "rpg fight" |

## Volume balancing

Each track has a `volume_db` field on the AudioStream import. `0 dB` = file volume; `-6 dB` is a reasonable default for BGM under sound effects. The in-game **Settings → BGM / SFX** sliders sit on top of that as bus-level multipliers.

## Don't forget attribution

Every track you ship requires acknowledgement (unless it's CC0). Update `CREDITS.md` at the project root every time you add a track. License compliance is way easier when you do it as you go.
