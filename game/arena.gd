extends Node2D


onready var level: Node2D = $Level

func _ready() -> void:
	Global.node_creation_parent = self
	
#	release_level():
#
#
#onready var tile_map: TileMap = $"../Level/TileMap"
#onready var level: Node2D = $"../Level"
#
#onready var level_tutorial = preload("res://game/levels/level_tutorial.tscn")
#var level_tutorial_path: String = "res://game/levels/level_tutorial.tscn"
#onready var arena: Node2D = $".."
#
#func release_level():
#	Global.release_scene(level)
#	yield(get_tree().create_timer(1), "timeout")
#	load_level()
#
#func load_level():
#
##	var current_level_scene: Node2D = level
##	var new_level_scene: PackedScene = level_tutorial
#
#	var nova_scena = Global.spawn_new_scene(level_tutorial_path, arena)
#	yield(get_tree().create_timer(1), "timeout")
#
#	var tilemap = nova_scena.get_node("TileMap")
#	printt ("nove_scena", tile_map, nova_scena)
#
#
#	tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
#	print("JUHEJ")
##	tile_map.connect("tilemap_completed", self, "_on_tilemap_completed")
