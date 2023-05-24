extends Camera2D


func _ready() -> void:
	Global.print_id(name)
	
func _physics_process(delta: float) -> void:
	
	if Global.camera_target:
		position = Global.camera_target.position
	pass
