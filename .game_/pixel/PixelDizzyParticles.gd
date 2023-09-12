extends Node2D


onready var particles: Particles2D = $Particles

func _ready() -> void:
	particles.emitting = true
#	yield(get_tree().create_timer(0.5), "timeout") # tole je precej amaterski način
#	queue_free()
#	print("partikls dizi kvefri")


func _on_Particles_tree_exited() -> void:
	queue_free()
	print("partikls dizi kvefri")

