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


func _random_step(step_direction: Vector2 = Vector2.DOWN): # smer določa preferenco
	# namen: detect collision namesto detect free positions
	# namen: manj preferiranja smeri
	# name: sam sebe kliče samo, če je neuspešen
	
	if current_state == STATES.IDLE:

		randomize()

		var available_directions: Array = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]
		available_directions.append_array([step_direction]) # dodam preferirano smer, da je več možnosti, da obdrži smer
		var random_index: int = randi() % available_directions.size()
		step_direction = available_directions[random_index]

		var intended_position: Vector2 = global_position + step_direction * cell_size_x
		# če je pozicija prosta korakam (in restiram poiskuse, če ni pa probam v drugo smer
		var current_collider: Object = Global.detect_collision_in_direction(step_direction, neighbor_ray)
		if not current_collider:
#		if Global.game_manager.is_floor_position_free(intended_position) and not Global.detect_collision_in_direction(step_direction, neighbor_ray): # drug del je zazih
			current_state = STATES.MOVING
			previous_position = global_position
			Global.game_manager.remove_from_free_floor_positions(global_position + step_direction * cell_size_x)
			var step_time: float = Global.game_manager.game_settings["stray_step_time"]*2
			var step_tween = get_tree().create_tween()
			step_tween.tween_property(self ,"position", intended_position, step_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
			step_tween.tween_callback(self ,"end_move")
			yield(step_tween, "finished")
		else:
#		_random_step(step_direction)
			call_deferred("_random_step", step_direction)


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
