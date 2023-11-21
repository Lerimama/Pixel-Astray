extends Node2D


onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var label: Label = $Tag/Label


func _ready() -> void:

	modulate.a = 1
	animation_player.play("show_tag")
	# KVEFRI je v animaciji

