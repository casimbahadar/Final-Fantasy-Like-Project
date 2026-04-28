extends Node

## Loads every Actor / CharClass / Skill / Item / Enemy / Troop / MapData
## .tres file under res://data/ at startup so they can be looked up by id.

const DATA_ROOT := "res://data"

var actors: Dictionary = {}    # StringName -> Actor
var classes: Dictionary = {}   # StringName -> CharClass
var skills: Dictionary = {}    # StringName -> Skill
var items: Dictionary = {}     # StringName -> Item
var enemies: Dictionary = {}   # StringName -> Enemy
var troops: Dictionary = {}    # StringName -> Troop
var maps: Dictionary = {}      # StringName -> MapData
var statuses: Dictionary = {}  # StringName -> StatusEffect


func _ready() -> void:
	_load_folder("actors", actors)
	_load_folder("classes", classes)
	_load_folder("skills", skills)
	_load_folder("items", items)
	_load_folder("enemies", enemies)
	_load_folder("troops", troops)
	_load_folder("maps", maps)
	_load_folder("statuses", statuses)
	print("[Database] loaded: %d actors, %d classes, %d skills, %d items, %d enemies, %d troops, %d maps, %d statuses" % [
		actors.size(), classes.size(), skills.size(),
		items.size(), enemies.size(), troops.size(), maps.size(), statuses.size()
	])


func _load_folder(subdir: String, target: Dictionary) -> void:
	var path := "%s/%s" % [DATA_ROOT, subdir]
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = load("%s/%s" % [path, file_name])
			if res != null and "id" in res and res.id != &"":
				target[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


func actor(id: StringName) -> Actor:
	return actors.get(id)


func skill(id: StringName) -> Skill:
	return skills.get(id)


func item(id: StringName) -> Item:
	return items.get(id)


func enemy(id: StringName) -> Enemy:
	return enemies.get(id)


func troop(id: StringName) -> Troop:
	return troops.get(id)


func map(id: StringName) -> MapData:
	return maps.get(id)


func status(id: StringName) -> StatusEffect:
	return statuses.get(id)


## Default XP-to-next-level if a class doesn't define a curve.
static func default_xp_to_next(level: int) -> int:
	return int(round(20.0 * pow(level, 1.5)))
