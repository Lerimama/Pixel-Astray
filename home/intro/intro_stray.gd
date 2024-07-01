extends Stray


func step(step_direction: Vector2 = Vector2.DOWN):
	# namen: detect collision namesto detect free positions
	
	if not current_state == States.IDLE:
		return

	var intended_position: Vector2 = global_position + step_direction * cell_size_x

	#	if get_parent().is_floor_position_free(intended_position):
	var current_collider: Object = Global.detect_collision_in_direction(step_direction, vision_ray)
	if not current_collider:
		step_attempt = 1 # reset na 1

		current_state = States.MOVING
		previous_position = global_position
		get_parent().remove_from_free_floor_positions(global_position + step_direction * cell_size_x)	

		var step_time: float = 0.2
		var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		step_tween.tween_property(self, "position", intended_position, step_time)
		step_tween.tween_callback(self, "end_move")

	else:
		# začne z ena, ker preverja preostale 3 smeri (prva je že zasedena)
		step_attempt += 1
		if step_attempt <= 4:
			var new_direction = step_direction.rotated(deg2rad(90))
			step(new_direction)
		else:
			step_attempt = 1 # reset na 1
			return
		
	
func play_sound(effect_for: String):

	if Global.sound_manager.game_sfx_set_to_off:
		return

	match effect_for:
		"blinking":
			Global.sound_manager.play_sfx("blinking")
			#			var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
			#			$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
			#			var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
			#			$Sounds/BlinkingStatic.get_child(random_static_index).play()
		"stepping":
			var random_step_index = randi() % $Sounds/Stepping.get_child_count()
			var selected_step_sound = $Sounds/Stepping.get_child(random_step_index).play()


# SIGNALI ------------------------------------------------------------------------------------------------------


func _on_Stray_tree_exiting() -> void:
	# namen: ven štetje strajsov v igri
	
	get_parent().add_to_free_floor_positions(global_position)	


func _on_Stray_tree_entered() -> void:
	# namen: ven štetje strajsov v igri in zaznavanje overspawna
	
	get_parent().remove_from_free_floor_positions(global_position)	
