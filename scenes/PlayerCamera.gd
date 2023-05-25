extends Camera2D


#var camera_target = null setget change_target


func _ready() -> void:
	
	Global.print_id(name)
	Global.player_camera = self
	Global.camera_target = null # da se nulira (pri quit game) in je naslednji play brez errorja ... seta se ob spawnanju plejerja
	
	position = Global.level_start_position.global_position
	
	
func _physics_process(delta: float) -> void:
	
#	if camera_target:
#		position = camera_target.position
	if Global.camera_target:
		position = Global.camera_target.position
	pass
func reset_camera_position():
	drag_margin_top = 0
	drag_margin_bottom = 0
	drag_margin_left = 0
	drag_margin_right = 0
	position = Global.level_start_position.global_position
	
#		# camera target
#		Global.camera_target = new_player_pixel
#		Global.player_camera.reset_camera_position()
		# _temp
#		P1 = new_player_pixel	
		
	yield(get_tree().create_timer(1), "timeout")
	drag_margin_top = 0.2
	drag_margin_bottom = 0.2
	drag_margin_left = 0.3
	drag_margin_right = 0.3
