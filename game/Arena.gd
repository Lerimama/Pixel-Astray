extends Node2D


func _ready() -> void:
	Global.print_id(self)
	Global.node_creation_parent = self
	
