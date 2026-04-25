@tool
class_name Troop
extends Resource

## A configured encounter: a group of enemies and where they stand on screen.

@export var id: StringName = &""
@export var members: Array[TroopMember] = []
@export var battle_bg: Texture2D
@export var battle_bgm: AudioStream
@export var victory_jingle: AudioStream

## If true, escape is disabled (boss / scripted fight).
@export var no_escape: bool = false
