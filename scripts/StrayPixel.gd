extends KinematicBody2D


var velocity = Vector2.ZERO
var collision: KinematicCollision2D


func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	
	collision = move_and_collide(velocity * delta, false)

	if collision:
		queue_free()
		print("collision")	
	
