@tool
class_name StatusEffect
extends Resource

## Data-driven battle status. Behavior is the sum of these fields — adding
## a new effect (Berserk, Regen, Stop, etc.) is just a new .tres file.
##
## Lifecycle in a battle:
##   * On apply (skill resolves with status_chance roll) → BattleUnit.apply_status
##   * At start of unit's turn → BattleUnit.tick_statuses applies hp_drain /
##     atb_rate / skip-turn checks, decrements duration, removes expired ones
##   * On battle end → BattleUnit.clear_statuses
##
## Stat multipliers are read by BattleUnit.stat() so DamageCalculator and the
## party panel see modified numbers automatically.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Visual")
## Single-character glyph (▼, Z, ↑, ↓) used for the badge under the sprite.
@export var glyph: String = "?"
@export var color: Color = Color(1, 1, 1, 1)

@export_group("Per-Turn Tick")
## Fraction of max HP lost at start of turn. 0.08 = 8%.
@export_range(0.0, 1.0, 0.01) var hp_drain_percent: float = 0.0
@export var hp_drain_flat: int = 0
## Fraction of max HP recovered at start of turn (Regen).
@export_range(0.0, 1.0, 0.01) var hp_regen_percent: float = 0.0
@export var hp_regen_flat: int = 0
## Fraction of max MP lost at start of turn (for spells that drain mana).
@export_range(0.0, 1.0, 0.01) var mp_drain_percent: float = 0.0
## Fraction of max MP recovered at start of turn.
@export_range(0.0, 1.0, 0.01) var mp_regen_percent: float = 0.0

@export_group("Action Restrictions")
@export var skip_turn: bool = false
## If skip_turn is on, chance per turn to wake/recover early (0 = stays full duration).
@export_range(0.0, 1.0, 0.05) var wake_chance_per_turn: float = 0.0
## If true, taking damage immediately removes this status (sleep convention).
@export var remove_on_damage: bool = false
## If true, only basic Attack is allowed (no Skill / Item / Defend / Run). Berserk.
@export var attack_only: bool = false
## If true, MP-cost skills are unusable. Silence.
@export var silence: bool = false
## If true, the unit's command is replaced by a random valid action against a
## random target (could be ally or enemy). Confuse.
@export var confuse: bool = false
## Multiplier on the attacker's hit roll for physical damage. 0.5 = blind.
@export_range(0.0, 2.0, 0.05) var accuracy_mult: float = 1.0
## Multiplier on incoming damage (0.5 = stoneskin, petrify), 1.0 = normal.
@export_range(0.0, 4.0, 0.05) var incoming_damage_mult: float = 1.0
## If true, unit cannot be cured by ordinary status removal — only specific
## items (e.g. Soft cures Petrify). When set, items must list cures_status to
## the same id.
@export var only_cured_by_item: bool = false

@export_group("ATB Modifier")
## Multiplier on the unit's ATB fill rate (1.5 = haste, 0.5 = slow).
@export_range(0.05, 4.0, 0.05) var atb_rate_mult: float = 1.0

@export_group("Stat Multipliers (active while applied)")
@export_range(0.1, 4.0, 0.05) var atk_mult: float = 1.0
@export_range(0.1, 4.0, 0.05) var def_mult: float = 1.0
@export_range(0.1, 4.0, 0.05) var mag_mult: float = 1.0
@export_range(0.1, 4.0, 0.05) var res_mult: float = 1.0
@export_range(0.1, 4.0, 0.05) var spd_mult: float = 1.0

@export_group("Duration")
## Number of turns the status sticks around before auto-expiring. -1 = until
## the battle ends.
@export_range(-1, 99) var duration_turns: int = 4

## Returns the effective multiplier this status applies to a given stat name.
func stat_multiplier(stat_name: String) -> float:
	match stat_name:
		"atk": return atk_mult
		"def": return def_mult
		"mag": return mag_mult
		"res": return res_mult
		"spd": return spd_mult
		_: return 1.0
