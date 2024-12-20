extends Stray

# spawn strani
enum SpawnSides {TOP, BOTTOM, RIGHT, LEFT}
var stray_spawn_side: int
var steps_count: int = 0
var stray_in_game_steps_count: int = 2


func _ready() -> void:
	# namen: grupiranje glede na izvorno stran, setanje collision bitov na ray

	add_to_group(Global.group_strays)
	randomize() # za random die animacije
	modulate.a = 0
	color_poly.modulate = stray_color

	pixel_face.hide()
	pixel_face.stop() # zazih
	if Global.game_manager.game_settings["show_expressions"]:
		pixel_face.show()
		manage_expressions()

	# set props glede na spawn stran
	var collision_bit_to_add: int
	var player_spawn_position: Vector2 = Global.game_manager.player_start_positions[0]
	if global_position.y < Global.current_tilemap.top_screen_limit.global_position.y:
		stray_spawn_side = SpawnSides.TOP
		collision_bit_to_add = 2
	elif global_position.y > Global.current_tilemap.bottom_screen_limit.global_position.y:
		stray_spawn_side = SpawnSides.BOTTOM
		collision_bit_to_add = 1
	elif global_position.x > Global.current_tilemap.right_screen_limit.global_position.x:
		stray_spawn_side = SpawnSides.RIGHT
		collision_bit_to_add = 3
	elif global_position.x < Global.current_tilemap.left_screen_limit.global_position.x:
		stray_spawn_side = SpawnSides.LEFT
		collision_bit_to_add = 4

	neighbor_ray.set_collision_mask_bit(collision_bit_to_add, true)


func check_collider_type(collider_in_check: Node2D):

	# prva runda ... kolajder tilemap (tla)
	if collider_in_check.is_in_group(Global.group_tilemap):
		turn_to_white()
	# druge runde ... kolajder stray in je rob tal
	elif collider_in_check.is_in_group(Global.group_strays) and collider_in_check != self:
		if collider_in_check.current_state == collider_in_check.STATES.WHITE:
			turn_to_white()


func step(follow_target: Node2D = null):
	# namen: določanje smeri glede na tip straya in časovni zamik premika glede na smer
	# namen: step kliče igra (line_step), je pa preverjanje kolajderja za spreminjanje v steno
	# namen: moduliranje
	# namen: step_count "namesto" step_attempt

	if current_state == STATES.IDLE or current_state == STATES.HUNTING or current_state == STATES.HOLDING:
		if modulate.a == 0:
			modulate.a = 1

		# določim side_set ali follow
		var is_following: bool = false
		var step_direction: Vector2
		if not follow_target or steps_count < stray_in_game_steps_count: # na korak v ekran še ne sledi
			is_following = false
			step_direction = _get_direction_from_spawn_side()
		else:
			is_following = true
			step_direction = _get_direction_to_target(follow_target)[0]

		# step
		var intended_position: Vector2 = global_position + step_direction * cell_size_x
		var current_collider: Object = Global.detect_collision_in_direction(step_direction, neighbor_ray)
		if (not current_collider and Global.game_manager.is_floor_position_free(intended_position)) or steps_count < stray_in_game_steps_count:

			# hunting
			if is_following == true:
				var target_vector: Vector2 = _get_direction_to_target(follow_target)[1]
				if target_vector.x == 0 or target_vector.y == 0:
					_hunting_step(step_direction, target_vector.length()) # metoda kliče hunting
					return
				color_poly.modulate = stray_color

			# moving
			current_state = STATES.MOVING
			manage_expressions()
			previous_position = global_position
			Global.game_manager.remove_from_free_floor_positions(intended_position)

			var step_time: float = Global.game_manager.game_settings["stray_step_time"]
			var step_tween = get_tree().create_tween()
			step_tween.tween_property(self ,"position", intended_position, step_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			step_tween.tween_callback(self ,"end_move")
			yield(step_tween, "finished")
			steps_count += 1


		else:
			# whitening
			if current_collider and current_collider and current_collider.is_in_group(Global.group_tilemap):
				turn_to_white()
			elif current_collider and current_collider.is_in_group(Global.group_strays) and not current_collider == self: # self rabm?
				if current_collider.current_state == current_collider.STATES.WHITE:
					turn_to_white()
				else:
					current_state = STATES.IDLE # pavza do GM klica
			# holding
			elif current_collider and current_collider.is_in_group(Global.group_players): # OPT ... podvaja se v hunting stepu
				color_poly.modulate = Global.color_holding
				current_state = STATES.HOLDING
			# če ni kolajderja, ni pa frej pozicija ... neželjen primer
			else:
				current_state = STATES.IDLE # pavza do GM klica


func play_sound(effect_for: String):
	# namen: ni soundow na spawn

	if not Global.sound_manager.game_sfx_set_to_off:
		match effect_for:
			"turning_color":
				var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
				$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
			"blinking":
				var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
				$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
				if current_state == STATES.DYING: # da se ne oglaša ob obračanju v steno
					var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
					$Sounds/BlinkingStatic.get_child(random_static_index).play()


func get_all_neighbors_in_directions(directions_to_check: Array): # kliče player on hit
	# namen: preverjanje vseh_sosedov, tudi tilemapa

	var current_cell_neighbors: Array
	for direction in directions_to_check:
		var neighbor: Object = Global.detect_collision_in_direction(direction, neighbor_ray)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			current_cell_neighbors.append(neighbor)
		if neighbor and neighbor.is_in_group(Global.group_tilemap): # če je kolajder, je tilemap
			current_cell_neighbors.append(neighbor)

	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov


func _get_direction_from_spawn_side():

	var direction_from_side: Vector2 = Vector2.ZERO
	match stray_spawn_side:
		SpawnSides.TOP:
			direction_from_side = Vector2.DOWN
		SpawnSides.BOTTOM:
			direction_from_side = Vector2.UP
		SpawnSides.LEFT:
			direction_from_side = Vector2.RIGHT
		SpawnSides.RIGHT:
			direction_from_side = Vector2.LEFT

	return direction_from_side

