extends Node

## JSON-backed save/load to user://. Three slots.

const SLOT_COUNT := 3

signal saved(slot: int)
signal loaded(slot: int)


func slot_path(slot: int) -> String:
	return "user://save_%d.json" % slot


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_to(slot: int) -> bool:
	var data := {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"playtime": GameState.playtime_seconds,
		"current_map_id": String(GameState.current_map_id),
		"spawn_point_id": String(GameState.spawn_point_id),
		"flags": _stringify_keys(GameState.flags),
		"gold": Party.gold,
		"inventory": _stringify_keys(Party.inventory),
		"key_items": _stringify_keys(Party.key_items),
		"members": _serialize_members(),
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot open slot %d for write" % slot)
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	GameState.last_save_slot = slot
	saved.emit(slot)
	return true


func load_from(slot: int) -> bool:
	if not slot_exists(slot):
		return false
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return false
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveSystem: corrupted slot %d" % slot)
		return false

	GameState.reset()
	Party.clear()

	GameState.playtime_seconds = float(parsed.get("playtime", 0.0))
	GameState.current_map_id = StringName(parsed.get("current_map_id", ""))
	GameState.spawn_point_id = StringName(parsed.get("spawn_point_id", ""))
	for k in parsed.get("flags", {}):
		GameState.flags[StringName(k)] = parsed["flags"][k]

	Party.gold = int(parsed.get("gold", 0))
	for k in parsed.get("inventory", {}):
		Party.inventory[StringName(k)] = int(parsed["inventory"][k])
	for k in parsed.get("key_items", {}):
		Party.key_items[StringName(k)] = bool(parsed["key_items"][k])

	for m in parsed.get("members", []):
		var actor_id := StringName(m.get("actor_id", ""))
		var actor := Database.actor(actor_id)
		if actor == null:
			continue
		var pm := Party.PartyMember.new(actor)
		pm.level = int(m.get("level", 1))
		pm.xp = int(m.get("xp", 0))
		pm.hp = int(m.get("hp", pm.max_hp()))
		pm.mp = int(m.get("mp", pm.max_mp()))
		pm.equip_weapon = StringName(m.get("equip_weapon", ""))
		pm.equip_armor = StringName(m.get("equip_armor", ""))
		pm.equip_accessory = StringName(m.get("equip_accessory", ""))
		for s in m.get("statuses", []):
			pm.statuses.append(StringName(s))
		Party.members.append(pm)

	GameState.last_save_slot = slot
	loaded.emit(slot)
	return true


func slot_summary(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return {
		"timestamp": parsed.get("timestamp", 0),
		"playtime": parsed.get("playtime", 0.0),
		"map_id": parsed.get("current_map_id", ""),
		"member_count": (parsed.get("members", []) as Array).size(),
		"gold": parsed.get("gold", 0),
	}


func _stringify_keys(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[String(k)] = d[k]
	return out


func _serialize_members() -> Array:
	var arr: Array = []
	for pm in Party.members:
		arr.append({
			"actor_id": String(pm.actor_id),
			"level": pm.level,
			"xp": pm.xp,
			"hp": pm.hp,
			"mp": pm.mp,
			"equip_weapon": String(pm.equip_weapon),
			"equip_armor": String(pm.equip_armor),
			"equip_accessory": String(pm.equip_accessory),
			"statuses": pm.statuses.map(func(s): return String(s)),
		})
	return arr
