# Content authoring guide

The whole game is data-driven: most content additions are **a new `.tres` file** dropped into the right folder. `Database.gd` autoloads everything in `data/` at boot, so a new sword / spell / status / map shows up the next time the project runs without code changes.

This is the playbook for keeping the game growing without touching scripts.

---

## Folder map

```
data/
  actors/      — playable characters (Aldric, Lyra, Kael)
  classes/     — class definitions (warrior, mage, rogue) + their learnsets
  skills/      — every action, spell, and ability
  statuses/    — status effects (poison, sleep, haste, etc.)
  items/       — consumables, equipment, key items
  enemies/     — single-fighter enemy definitions
  troops/      — pre-configured encounter groups (members + positions)
  maps/        — MapData (id, scene path, encounter table, BGM)

scenes/world/maps/  — actual playable maps (.tscn)
scenes/world/       — Player, NPC, Chest scenes
assets/sprites/     — SVG (rasterized by Godot) or PNG art
```

---

## Add a status effect

1. Copy any file in `data/statuses/` (e.g. `poison.tres`) and rename it.
2. Open it in Godot's inspector. Fill in `id`, `display_name`, `glyph`, `color`.
3. Tick the relevant fields — every status is the sum of these:
   - `hp_drain_percent` / `hp_drain_flat` — Poison, Burn
   - `hp_regen_percent` / `hp_regen_flat` — Regen
   - `mp_drain_percent` / `mp_regen_percent`
   - `skip_turn` + `wake_chance_per_turn` + `remove_on_damage` — Sleep, Stop
   - `attack_only` — Berserk (auto-attacks)
   - `silence` — Silence (gates MP-cost skills)
   - `confuse` — Confuse (random target)
   - `accuracy_mult` — Blind (multiplied into physical hit roll)
   - `incoming_damage_mult` — Petrify (0.5x), Vulnerability (>1)
   - `only_cured_by_item` — Petrify (won't expire on its own)
   - `atb_rate_mult` — Haste (1.5x), Slow (0.5x)
   - `atk_mult` / `def_mult` / `mag_mult` / `res_mult` / `spd_mult` — buffs/debuffs
   - `duration_turns` — `-1` = lasts until battle ends
4. Save. The Database picks it up next run.

---

## Add a skill

1. Copy a file in `data/skills/` (e.g. `fire.tres` for damage, `regen_spell.tres` for status-only).
2. Set:
   - `id` (StringName, must be unique)
   - `display_name`, `description`
   - `mp_cost`
   - `target_kind` — 0=Enemy single, 1=Enemy all, 2=Ally single, 3=Ally all, 4=Self
   - `damage_kind` — 0=Physical, 1=Magical, 2=Heal, 3=None (status-only)
   - `element` — 0=None, 1=Fire, 2=Ice, 3=Thunder, 4=Water, 5=Earth, 6=Wind, 7=Light, 8=Dark
   - `power` (scaling factor; ~10 for a basic Attack, ~20 for a strong spell)
   - `accuracy` (0.0–1.0)
   - `crit_bonus` (extra crit chance on top of the base 5%)
   - `inflicts_status` + `status_chance` to apply a status on hit
3. To put the skill in a class's learnset: open the class in `data/classes/`, add a new sub-resource of type `LearnEntry` to `learnset` with the desired level + the new skill.

---

## Add an item

1. Copy a file in `data/items/`.
2. Set `kind`: 0=Consumable, 1=Weapon, 2=Armor, 3=Accessory, 4=Key.
3. For consumables: fill in `heal_hp`, `heal_mp`, `revives`, `cures_status`.
4. For equipment: set `equip_slot` (1=Weapon, 2=Armor, 3=Accessory) and the `bonus_*` stat fields. The stat names match `Actor.base_*` (atk, def, mag, res, spd, luk, max_hp, max_mp).
5. To sell from a shop: add the item's `id` (StringName) to that NPC's `shop_inventory` array in the map .tscn.

---

## Add an enemy

1. Copy a file in `data/enemies/`.
2. Set the standard stats (max_hp, atk, def, mag, res, spd, luk).
3. Set `xp_reward`, `gold_reward`. Optional `drop_item` + `drop_chance`.
4. Fill `skills` with an array of Skill resources — the AI picks at random from these (filtered by mp_cost, status restrictions).
5. Optional `element_modifiers` dict — `{1: 1.5, 2: 0.5}` means weak to Fire, resists Ice. `0.0` = immune; negative values = absorb (heal).
6. Set `battle_sprite` to a Texture2D — SVG works (Godot rasterizes), PNG works.

---

## Add a troop

A troop is a pre-baked encounter group.

1. Copy a file in `data/troops/`.
2. Add `TroopMember` sub-resources to `members`. Each has an enemy resource and a `screen_position` (where it appears on the battle field — viewport is 480×270, enemies typically live at x=80–200, y=80–180).
3. Set `no_escape = true` for boss/scripted fights.
4. Add the troop's `id` to a map's `MapData.encounter_troops` array to put it in the random pool.

---

## Add a map

1. Duplicate an existing map in `scenes/world/maps/` (e.g. `Plaza.tscn` if it has NPCs, `ForestPath.tscn` if it's mostly grass).
2. Set the root's `map_id` to a unique StringName.
3. Rewrite the `grid_string`. Characters:
   - `#` = wall, `.` = floor, `,` = grass (encounter tile), `~` = water (block), `+` = path, `D` = door
   - Every row must be the same width; viewport-friendly is 20 cols × 14 rows
4. Place SpawnPoint nodes for each entry direction, each with a unique `spawn_id`.
5. Place WarpTrigger nodes pointing at adjacent maps' spawn ids. Set `requires_flag` to gate (e.g. only after a story event).
6. Drop in `NPC.tscn` instances; set `npc_name`, `grid_position`, `lines`, and `sprite_texture`. For shops, fill `shop_inventory`. For inns, set `inn_cost`.
7. Drop in `Chest.tscn` instances with a unique `chest_id` plus `item_id` / `item_count` / `gold`.
8. Create a `data/maps/<map_id>.tres` (`MapData`) with the same id and the scene path. If you want random encounters, fill `encounter_troops` and `encounter_steps`.
9. Wire it from another map by setting `WarpTrigger.target_map_id` + `target_spawn_id`.

---

## Add a story trigger / chapter transition

The same `EndingTrigger` script handles every story beat:

| Field | What it does |
|---|---|
| `requires_flag` | Only fires when this flag is set (e.g. boss defeated) |
| `lines_locked` | Lines shown when the flag isn't set yet |
| `lines` | Main lines played on fire |
| `recruit_actor_id` | Adds this actor to the party (skips if already in party) |
| `sets_flag` | Sets this flag true after firing |
| `warp_target_map` + `warp_target_spawn` | Warps to a new map (chapter transition) |
| `is_ending` | If true and no warp set, resets state and returns to title (true ending) |

Examples:
- **Boss reward + recruit + open next chapter:** set `requires_flag` to the boss-defeated flag, `recruit_actor_id` to the new party member, `sets_flag` to a chapter flag, `warp_target_map` to the next region.
- **True ending:** set `requires_flag` to the final-boss flag, `is_ending = true`, write your epilogue in `lines`.
- **Cliffhanger / "to be continued":** set `is_ending = true`, write outro lines.

---

## Add a class + actor (new party member)

1. Create `data/classes/<class_id>.tres` from one of the existing classes. Build the `learnset` array with `LearnEntry` sub-resources (level + skill).
2. Create `data/actors/<actor_id>.tres`. Set `char_class` to your new class, fill base stats and growth rates.
3. Make placeholder sprites in `assets/sprites/placeholder/` (16×24 SVGs work; rasterized by Godot).
4. To recruit them in-game: place an `EndingTrigger` (story trigger) somewhere with `recruit_actor_id` set to the actor id. Wire it behind a flag so the recruit happens at the right story moment.

---

## Saves and the database

- Saves serialize every `PartyMember`'s actor_id + level / xp / hp / mp / equipment / statuses.
- A loaded save **only works if the actor / class / item ids it references still exist in the database.** If you rename or delete a content id, old saves will warn and skip the missing record. Treat ids as a public contract — once shipped, don't rename.

---

## Add music / SFX

`assets/audio/` is empty by design — Godot autoimports `.ogg` files dropped in there. Once you have one:

1. Drop the file into `assets/audio/bgm/` (or `sfx/` / `jingles/`).
2. Double-click it in Godot's FileSystem dock. In the Import tab, set **Loop = true** for BGM, then **Reimport**.
3. Drag it onto the relevant slot:
   - **Map music** → `data/maps/<map_id>.tres` → `bgm`
   - **Battle music** → `data/troops/<troop_id>.tres` → `battle_bgm`
   - **Victory jingle** → `data/troops/<troop_id>.tres` → `victory_jingle`
4. Update `CREDITS.md` with the source + license.

Curated free sources for fantasy/RPG tracks: see `assets/audio/README.md`.

## Add a recruit (party member who joins via dialogue)

1. Create the actor + class as documented above.
2. Place an NPC in the world with `conversation_flag` set (e.g. `&"mira_joined"`) AND `recruit_actor_id` set to the actor id (e.g. `&"mira"`). The first conversation sets the flag and adds them to the party. Subsequent talks fall through to `lines_after_first`.
3. To gate later content on the recruit, set `WarpTrigger.requires_flag = &"<flag_name>"` on warps that should only open after the recruit.

## Where the limits are

A few things that are NOT yet data-driven and currently require code changes:

- New skill **target kinds** beyond the existing 5 (Enemy/Ally Single/All + Self).
- New status **field types** (e.g. "reflect magic back at caster" needs DamageCalculator awareness).
- New input actions / control schemes (touch button targets are hand-coded).
- Battle scene layout (fighter positions are computed in `BattleManager._build_units`; for big custom encounters, edit there).
- Per-enemy-type AI (e.g. "always cast Cure if HP < 30%") — the current AI picks uniformly among usable skills.

Everything else — story arcs, towns, dungeons, quests, balance, music, art — is `.tres` or asset drop.
