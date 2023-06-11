extends Node

onready var home_scene_path: String = "res://scenes/Home.tscn"
onready var game_scene_path: String = "res://scenes/game/Game.tscn"

func _ready() -> void:
	
	Global.main_root = self
	yield(get_tree().create_timer(1), "timeout")
	Global.spawn_new_scene(home_scene_path, self)
	
	
func _process(delta: float) -> void:
#	print("main is still here")
	pass
