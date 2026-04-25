@tool
class_name MapData
extends Resource

## Metadata for a world map: which scene to load, its display name, BGM, encounter table.

@export var id: StringName = &""
@export var display_name: String = "Map"
@export_file("*.tscn") var scene_path: String = ""
@export var bgm: AudioStream

@export_group("Encounters")
## Troop ids that can spawn here. Empty = no random encounters.
@export var encounter_troops: Array[StringName] = []
## Average steps between encounters. 0 disables.
@export_range(0, 200) var encounter_steps: int = 30
