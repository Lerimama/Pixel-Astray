extends Camera2D

var target = null


func _physics_process(delta: float) -> void:
	
	if target:
		position = target.position
