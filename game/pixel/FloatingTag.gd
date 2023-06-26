extends Node2D


onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var label: Label = $Tag/Label


func _ready() -> void:
	
	print ("Tag lokacija, ", global_position, get_parent())
	modulate.a = 1
	animation_player.play("show_tag")
	# KVEFRI je v animaciji
	pass

