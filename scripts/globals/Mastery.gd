extends Node

## Tracks which class capstones the player has unlocked from the Class Trials.
## Each class has one capstone skill — beating that class's trial in the Trial
## Hall sets the corresponding entry true here, and BattleUnit.available_skills
## auto-merges the capstone into any character whose effective_class matches.

signal mastered(class_id: StringName)

# class_id -> capstone skill_id
const CAPSTONE_BY_CLASS: Dictionary = {
	&"warrior":        &"capstone_last_defender",
	&"mage":           &"capstone_flare",
	&"rogue":          &"capstone_vanish_strike",
	&"cleric":         &"capstone_holy_aura",
	&"dragoon":        &"capstone_comet_lance",
	&"berserker":      &"capstone_apocalypse",
	&"monk":           &"capstone_thousand_hands",
	&"necromancer":    &"capstone_black_sun",
	&"paladin":        &"capstone_sanctify",
	&"bard":           &"capstone_ode_to_auren",
	&"ranger":         &"capstone_volley_of_stars",
	&"samurai":        &"capstone_shogun_strike",
	&"geomancer":      &"capstone_worlds_voice",
	&"beastmaster":    &"capstone_pack_lord",
	&"time_mage":      &"capstone_stop_world",
	&"spellblade":     &"capstone_storm_of_edges",
	&"assassin":       &"capstone_final_cut",
	&"dark_knight":    &"capstone_apostasy",
	&"summoner":       &"capstone_knights_round",
	&"chemist":        &"capstone_megalixir",
	&"dancer":         &"capstone_sun_dance",
	&"crystal_knight": &"capstone_prism_shield",
	&"grave_singer":   &"capstone_final_verse",
}

var mastered_classes: Dictionary = {}   # StringName(class_id) -> bool


func unlock(class_id: StringName) -> void:
	if class_id == &"":
		return
	mastered_classes[class_id] = true
	mastered.emit(class_id)


func is_mastered(class_id: StringName) -> bool:
	return mastered_classes.get(class_id, false)


func capstone_for(class_id: StringName) -> StringName:
	return CAPSTONE_BY_CLASS.get(class_id, &"")


func clear() -> void:
	mastered_classes.clear()


func to_dict() -> Dictionary:
	var out := {}
	for k in mastered_classes:
		out[String(k)] = bool(mastered_classes[k])
	return out


func from_dict(d: Dictionary) -> void:
	clear()
	for k in d:
		mastered_classes[StringName(k)] = bool(d[k])
