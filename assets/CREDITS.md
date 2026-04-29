# Asset credits

This file tracks every third-party asset shipped with the game and its license. **Update it any time you add or replace an asset** — license compliance after the fact is painful, license compliance as you go is one line per pack.

Currently the game ships with **only placeholder SVG sprites generated procedurally for this project**. They have no third-party origin and require no attribution. As soon as you swap real art in, log it here.

---

## Sprite art

| File / folder | Pack name | Author | License | Source URL | Notes |
|---------------|-----------|--------|---------|------------|-------|
| `assets/sprites/placeholder/*.svg` | (in-house placeholder) | This project | CC0 | n/a | All hand-coded SVG; will be replaced. |

When you replace, expand this table. Example rows:

| `assets/sprites/actors/aldric.png` | Tiny Heroes | Kenney | CC0 | https://kenney.nl/assets/tiny-heroes | warrior sprite |
| `assets/sprites/enemies/wraith.png` | Aekashics Librarium | Akashics | CC-BY 4.0 | https://akashics.moe | "Wraith" battle enemy |

---

## Audio

| File / folder | Pack name | Author | License | Source URL | Notes |
|---------------|-----------|--------|---------|------------|-------|
| (none yet)    |           |        |         |            |       |

When you add a track, append a row. Example:

| `assets/audio/bgm/town_plaza.ogg` | Fantasy Music 4 | Eric Matyas / soundimage.org | CC-BY 4.0 | https://soundimage.org | Plaza BGM |

---

## Fonts

| File / folder | Font name | Author | License | Source URL |
|---------------|-----------|--------|---------|------------|
| (none yet)    |           |        |         |            |

Recommended: VT323, Press Start 2P, Pixelify Sans — all SIL Open Font License, free for any use including commercial.

---

## Tilesets

| File / folder | Pack name | Author | License | Source URL | Notes |
|---------------|-----------|--------|---------|------------|-------|
| (none yet — overworld is procedurally drawn until tilesets are added) | | | | | |

---

## License compliance checklist (read before publishing)

For every CC-BY asset:
- [ ] Attribution text is in this file with author + source URL.
- [ ] Same attribution is reachable from inside the game (Title screen → Credits, or a Credits screen on the menu).
- [ ] License URL is linked, not just named (e.g. https://creativecommons.org/licenses/by/4.0/ for CC-BY 4.0).

For every CC-BY-SA asset (LPC etc.):
- [ ] All requirements above.
- [ ] **Read the SA clause carefully.** Share-alike means downstream derivatives must also be released under the same license. For a closed-source commercial Steam release, this is a yellow flag — talk to a lawyer or skip these assets.

For every CC0 / Public Domain asset:
- [ ] Listed in this file (good practice even though attribution is not required).
- [ ] No further action needed.

For every paid pack:
- [ ] License terms read in full (some forbid resale-of-derivatives, some require listing in credits, some are royalty-free for unlimited use).
- [ ] Receipt / purchase record retained off-repo.
- [ ] Pack listed in this file with note "Paid: licensed for use in this project."
