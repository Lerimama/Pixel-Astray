extends Stray



func die(stray_in_stack_index: int, strays_in_stack_count: int):
	# namen: samo animacija

	# čakalni čas
	var wait_to_destroy_time: float = sqrt(0.005 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
	yield(get_tree().create_timer(wait_to_destroy_time), "timeout")

	# animacije
	if strays_in_stack_count > 3:
		animation_player.play("die_stray")
	else:
		var random_animation_index = randi() % 5 + 1
		var random_animation_name: String = "die_stray_%s" % random_animation_index
		animation_player.play(random_animation_name)
	yield(animation_player, "animation_finished")
	queue_free()


func step(step_direction: Vector2 = Vector2.DOWN):
	# namen: detect collision namesto detect free positions

	if current_state == STATES.IDLE:

		var intended_position: Vector2 = global_position + step_direction * cell_size_x

		#	if get_parent().is_floor_position_free(intended_position):
		var current_collider: Object = Global.detect_collision_in_direction(step_direction, neighbor_ray)
		if not current_collider:
			step_attempt = 1 # reset na 1

			current_state = STATES.MOVING
			previous_position = global_position
			get_parent().remove_from_free_floor_positions(global_position + step_direction * cell_size_x)

			var step_time: float = Profiles.game_settings["stray_step_time"]
			var step_tween = get_tree().create_tween()
			step_tween.tween_property(self ,"position", intended_position, step_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			step_tween.tween_callback(self ,"end_move")

		else:
			# začne z ena, ker preverja preostale 3 smeri (prva je že zasedena)
			step_attempt += 1
			if step_attempt <= 4:
				var new_direction = step_direction.rotated(deg2rad(90))
				step(new_direction)
			else:
				step_attempt = 1 # reset na 1


func play_sound(effect_for: String):

	if not Global.sound_manager.game_sfx_set_to_off:
		match effect_for:
			"blinking":
				var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
				$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
				var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
				$Sounds/BlinkingStatic.get_child(random_static_index).play()


# SIGNALI ------------------------------------------------------------------------------------------------------


func _on_Stray_tree_exiting() -> void:
	# namen: ven štetje strajsov v igri

	get_parent().add_to_free_floor_positions(global_position)


func _on_Stray_tree_entered() -> void:
	# namen: ven štetje strajsov v igri in zaznavanje overspawna

	get_parent().remove_from_free_floor_positions(global_position)
