extends Node

## Tracks lifetime enemy kill counts. Used by quest givers and the Huntmaster
## bounty board to gate rewards on "kill N of X" objectives. Persisted by
## SaveSystem alongside flags / inventory.

signal kill_recorded(enemy_id: StringName, total: int)

var kills: Dictionary = {}              # StringName(enemy_id) -> int


func record_kill(enemy_id: StringName) -> void:
	if enemy_id == &"":
		return
	var total: int = int(kills.get(enemy_id, 0)) + 1
	kills[enemy_id] = total
	kill_recorded.emit(enemy_id, total)


func kill_count(enemy_id: StringName) -> int:
	return int(kills.get(enemy_id, 0))


func has_killed_at_least(enemy_id: StringName, n: int) -> bool:
	return kill_count(enemy_id) >= n


func total_kills() -> int:
	var t := 0
	for k in kills.values():
		t += int(k)
	return t


func unique_species() -> int:
	return kills.size()


func clear() -> void:
	kills.clear()


func to_dict() -> Dictionary:
	var out := {}
	for k in kills:
		out[String(k)] = int(kills[k])
	return out


func from_dict(d: Dictionary) -> void:
	clear()
	for k in d:
		kills[StringName(k)] = int(d[k])
