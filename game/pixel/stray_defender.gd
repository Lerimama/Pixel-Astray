extends Stray

# spawn strani
enum SpawnSides {TOP, BOTTOM, RIGHT, LEFT}
var stray_spawn_side: int 


func _ready() -> void:
	# namen: grupiranje glede na izvorno stran, setanje collision bitov na ray
	
	add_to_group(Global.group_strays)
	randomize() # za random die animacije
	modulate.a = 0
	color_poly.modulate = stray_color
	position_indicator_poly.color = stray_color
	position_indicator.set_as_toplevel(true) # strayse skrijem ko so offscreen
	position_indicator.visible = false

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
	
	vision_ray.set_collision_mask_bit(collision_bit_to_add, true)
		
	
func show_stray(): # kliče GM
	# namen: simple prikaz streja

	modulate.a = 1
	
	if current_state == States.WALL:
		stray_color.s = 0.0
		color_poly.modulate = Global.color_white_pixel

	
func check_collider_for_wall(collider_in_check: Node2D):
	
	# prva runda ... kolajder tilemap (tla)
	if collider_in_check.is_in_group(Global.group_tilemap):
		die_to_wall()
	# druge runde ... kolajder stray in je rob tal
	elif collider_in_check.is_in_group(Global.group_strays) and collider_in_check != self:
		if collider_in_check.current_state == collider_in_check.States.WALL:
			die_to_wall()	

	
func step(step_direction: Vector2 = Vector2.DOWN):
	# namen: določanje smeri glede na tip straya in časovni zamik premika glede na smer
	# namen: ni večih poskusov, je preverjanje kolajderja
	
	if not current_state == States.IDLE:
		return
		
	if modulate.a == 0:
		modulate.a = 1

	match stray_spawn_side:
		SpawnSides.TOP:
			step_direction = Vector2.DOWN
		SpawnSides.BOTTOM:
			step_direction = Vector2.UP
		SpawnSides.LEFT:
			step_direction = Vector2.RIGHT
		SpawnSides.RIGHT:
			step_direction = Vector2.LEFT	
	
	# če je pozicija prosta korakam, če ni pa preverjam kolajderja in ga returnam
	var intended_position: Vector2 = global_position + step_direction * cell_size_x
	if Global.game_manager.is_floor_position_free(intended_position):
		
		current_state = States.MOVING
		previous_position = global_position
		Global.game_manager.remove_from_free_floor_positions(intended_position)	
		
		var step_time: float = 0.2
		var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		step_tween.tween_property(self, "position", intended_position, step_time)
		step_tween.tween_callback(self, "end_move")	
	else:
		# če je kolajder ga returnam, drugače pa ne naredim nič
		var current_collider = detect_collision_in_direction(step_direction)
		if current_collider:
			check_collider_for_wall(current_collider)
			return current_collider
	
	
func play_sound(effect_for: String):
	# namen: ni soundow na spawn
	
	if Global.sound_manager.game_sfx_set_to_off:
		return
		
	match effect_for:
		"turning_color":
			var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
			$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
		"blinking":
			var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
			$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
			if current_state == States.DYING: # da se ne oglaša ob obračanju v steno
				var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
				$Sounds/BlinkingStatic.get_child(random_static_index).play()
		"stepping":
			var random_step_index = randi() % $Sounds/Stepping.get_child_count()
			var selected_step_sound = $Sounds/Stepping.get_child(random_step_index).play()
			
				
func get_all_neighbors_in_directions(directions_to_check: Array): # kliče player on hit
	# namen: preverjanje vseh_sosedov, tudi tilemapa
	
	var current_cell_neighbors: Array
	for direction in directions_to_check:
		var neighbor = detect_collision_in_direction(direction)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			current_cell_neighbors.append(neighbor)
		if neighbor and neighbor.is_in_group(Global.group_tilemap): # če je kolajder, je tilemap
			current_cell_neighbors.append(neighbor)
		
	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov
