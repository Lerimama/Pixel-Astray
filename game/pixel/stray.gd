extends Area2D
class_name Stray


enum STATES {IDLE, MOVING, HUNTING, DYING, WHITE, HOLDING} # STATIC # static, unmovable ... ko je GO ali pa je poden
var current_state = STATES.IDLE # ni vready, da lahko setam že ob spawnu

var stray_color: Color # poly modulate ... ko je poly bel, je stray color še vedno original barva
var visible_on_screen: bool = true # more bit prižgan, da dela pri vseh igrah
var previous_position: Vector2 = Vector2.ZERO
var animation_current_frame: int = 0 # za ustavljanje random loopanja
var next_step_pause: float = 0.5
var current_following_target: Node2D # (re)seta GM ob klic prvewg stepa
var _temp_is_from_hunting: bool = false

onready var step_timer: Timer = $StepTimer
onready var neighbor_ray: RayCast2D = $NeighborRay
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var color_poly: Polygon2D = $ColorPoly
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var cell_size_x: int = Global.current_tilemap.cell_size.x
onready var pixel_face: AnimatedSprite = $PixelFace



func _ready() -> void:

	add_to_group(Global.group_strays)
	randomize() # za random die animacije

	color_poly.modulate = stray_color
	modulate.a = 0
	pixel_face.hide()
	pixel_face.stop() # zazih
	if Global.game_manager.game_settings["show_expressions"]:
		pixel_face.show()
		manage_expressions()

	end_move()


func show_stray(): # kliče GM
	# če je pozicija res prazna



	if current_state == STATES.WHITE:
		turn_to_white()
		# random expression
		pixel_face.set_animation("faces")
		pixel_face.frame = randi() % pixel_face.frames.get_frame_count("faces")
	else:
		if visible_on_screen:
			# žrebam animacijo
			var random_animation_index = randi() % 3 + 1
			var random_animation_name: String = "glitch_%s" % random_animation_index
			animation_player.play(random_animation_name)
		else:
			modulate.a = 1


func die(stray_in_stack_index: int, strays_in_stack_count: int):

	current_state = STATES.DYING

	global_position = Global.snap_to_nearest_grid(global_position)
	Global.game_manager.remove_from_free_floor_positions(global_position)

	# wait time
	var wait_to_destroy_time: float = sqrt(0.07 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
	yield(get_tree().create_timer(wait_to_destroy_time), "timeout")

	var anim_audio_wait_time: float = 0.2
	if pixel_face.visible:
		if stray_in_stack_index < 400: # prvi se animira
			manage_expressions(true)
			yield(get_tree().create_timer(anim_audio_wait_time), "timeout") # da se sound odpleja pred kvefri
		else:
			manage_expressions()

	# animacije
	if not visible_on_screen and strays_in_stack_count > 3:
		collision_shape.set_deferred("disabled", true)
		Global.game_manager.add_to_free_floor_positions(global_position)
	else:
		if strays_in_stack_count > 3:
			animation_player.play("die_stray")
		else:
			var random_animation_index = randi() % 5 + 1
			var random_animation_name: String = "die_stray_%s" % random_animation_index
			animation_player.play(random_animation_name)

		# color vanish
		var collision_disabled_delay: float = 0.3
		yield(get_tree().create_timer(collision_disabled_delay), "timeout") # če je delay v tvinu ne dela okej
		collision_shape.disabled = true
		Global.game_manager.add_to_free_floor_positions(global_position)

	Global.game_manager.on_stray_die(self)
	call_deferred("queue_free") # predvideva, da more bit deferd, da se lahko collision izklopi


func turn_to_white():

	current_state = STATES.WHITE

	if visible_on_screen:
		var random_animation_index = randi() % 5 + 1
		var random_animation_name: String = "die_stray_%s" % random_animation_index
		animation_player.play(random_animation_name)
		yield(animation_player, "animation_finished")

	# wall color
	modulate.a = 1
	color_poly.modulate = Global.color_white_pixel_bloom
	# ugasni delovanje
	set_deferred("set_physics_process", false)


# MOVEMENT ------------------------------------------------------------------------------------------------------


func step(following_target: Node2D = null):

	if following_target == null or not Global.game_manager.game_settings["follow_mode"]:
		_random_step()
	else:

		current_following_target = following_target

		if current_state == STATES.IDLE or current_state == STATES.HOLDING: # or current_state == STATES.HUNTING

			# spawn side ali follow smer
			var step_direction: Vector2
			step_direction = _get_direction_to_target(current_following_target)[0]
			# step ... preverim, če je prostor
			var current_collider: Object = Global.detect_collision_in_direction(step_direction, neighbor_ray)
			var intended_position: Vector2 = global_position + step_direction * cell_size_x
			if not current_collider and Global.game_manager.is_floor_position_free(intended_position):

				var target_vector: Vector2 = _get_direction_to_target(current_following_target)[1]
				if target_vector.x == 0 or target_vector.y == 0 and not _temp_is_from_hunting:# and not current_state == STATES.HOLDING:
					print("step > hunting")
					_hunting_step(step_direction, target_vector.length()) # metoda kliče hunting
					return
				_temp_is_from_hunting = false
#					if _hunting_step(step_direction, target_vector.length()) == false: # metoda kliče hunting
#						pass
#					else:
#						return

				current_state = STATES.MOVING
				color_poly.modulate = stray_color
				manage_expressions()
				previous_position = global_position
				Global.game_manager.remove_from_free_floor_positions(intended_position)

				var step_time: float = Global.game_manager.game_settings["stray_step_time"]
				var step_tween = get_tree().create_tween()
				step_tween.tween_property(self ,"position", intended_position, step_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
				step_tween.tween_callback(self ,"end_move")
				yield(step_tween, "finished")
				step(current_following_target)

			elif current_collider and current_collider.is_in_group(Global.group_players): # OPT ... podvaja se v hunting stepu

				current_state = STATES.HOLDING
				color_poly.modulate = Global.color_holding
				if step_timer.is_stopped():
					step_timer.start(next_step_pause) # _temp ... refaktor v frugo metodo


func _random_step(step_direction: Vector2 = Vector2.DOWN): # smer določa preferenco

	if current_state == STATES.IDLE:

		randomize()

		var available_directions: Array = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]
		available_directions.append_array([step_direction, step_direction]) # dodam preferirano smer, da je več možnosti, da obdrži smer
		var random_index: int = randi() % available_directions.size()
		step_direction = available_directions[random_index]

		var intended_position: Vector2 = global_position + step_direction * cell_size_x
		# če je pozicija prosta korakam (in restiram poiskuse, če ni pa probam v drugo smer
		if Global.game_manager.is_floor_position_free(intended_position) and not Global.detect_collision_in_direction(step_direction, neighbor_ray): # drug del je zazih
			current_state = STATES.MOVING
			previous_position = global_position
			Global.game_manager.remove_from_free_floor_positions(global_position + step_direction * cell_size_x)
			var step_time: float = Global.game_manager.game_settings["stray_step_time"]
			var step_tween = get_tree().create_tween()
			step_tween.tween_property(self ,"position", intended_position, step_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
			step_tween.tween_callback(self ,"end_move")
			yield(step_tween, "finished")

		_random_step(step_direction)


func _hunting_step(step_direction: Vector2, distance_to_target: float):
	# stegne ray in preveri, če kolajda s plejerjem ... če s katerim drugim, ga itak ne vidi

	var target_collider: Node2D = Global.detect_collision_in_direction(step_direction, neighbor_ray, distance_to_target - 8)
	var intended_position: Vector2 = global_position + step_direction * cell_size_x

	# če je dolgi kolajder plejer
	if target_collider and target_collider.is_in_group(Global.group_players):
		_temp_is_from_hunting = false

		# če ima do njega dolgo pot
		if Global.game_manager.is_floor_position_free(intended_position):
			if not current_state == STATES.HUNTING:
				current_state = STATES.HUNTING
				manage_expressions()
			#			color_poly.modulate = Global.color_hunting
			previous_position = global_position
			Global.game_manager.remove_from_free_floor_positions(intended_position)
			var step_time: float = Global.game_manager.game_settings["stray_step_time"] / 3
			var step_tween = get_tree().create_tween()
			step_tween.tween_property(self ,"position", intended_position, step_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).set_delay(0.01)
			step_tween.tween_callback(self ,"end_move")
			yield(step_tween, "finished")
			_hunting_step(step_direction, distance_to_target - cell_size_x)

		# če je ob plejerju (pozicija je zasedena in kolajda s plejerjem)
		else:
			current_state = STATES.HOLDING
			manage_expressions()
			color_poly.modulate = Global.color_holding
			if step_timer.is_stopped():
				step_timer.start(next_step_pause)

	# če kolajder ni plejer proba spet kasneje
	elif target_collider:
		print ("hunting ... stray interfers")
		_temp_is_from_hunting = true
		current_state = STATES.IDLE
		end_move()
		step_timer.start(next_step_pause)

	# če ni kolajderja proba spet takoj
	else:
		print ("hunting ... lost target")
		_temp_is_from_hunting = true
		current_state = STATES.IDLE
		end_move()
		step_timer.start(next_step_pause)

func push_stray(push_direction: Vector2, push_time: float):

#	if not current_state == STATES.MOVING and not current_state == STATES.HUNTING: # and not current_state == STATES.HOLDING:
		current_state = STATES.MOVING
#	if current_state == STATES.IDLE:

		previous_position = Vector2.ZERO # prejšnja poz je nova pozicija plejerja ali straysa v vrsti
		Global.game_manager.remove_from_free_floor_positions(global_position + push_direction * cell_size_x)

		var heavier_hit_delay: float = 0.0  # z delayom je porinek bolj pristen in "težak"
		var push_tween = get_tree().create_tween()
		push_tween.tween_property(self, "position", global_position + push_direction * cell_size_x, push_time / 2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(heavier_hit_delay)
		push_tween.tween_callback(self, "end_move")


func pull_stray(pull_direction: Vector2, pull_time: float):

#	if not current_state == STATES.MOVING and not current_state == STATES.HUNTING: # and not current_state == STATES.HOLDING:
		current_state = STATES.MOVING

#	if current_state == STATES.IDLE:
		previous_position = global_position
		Global.game_manager.remove_from_free_floor_positions(global_position + pull_direction * cell_size_x)

		var pull_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		pull_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x, pull_time)
		pull_tween.tween_callback(self, "end_move")


func end_move():

	if current_state == STATES.MOVING: # prepreči reset stanja na DYING, WHITE ali HUNTING
		current_state = STATES.IDLE

	global_position = Global.snap_to_nearest_grid(global_position)

	if not previous_position == Vector2.ZERO:
		Global.game_manager.add_to_free_floor_positions(previous_position)


# UTILITI ------------------------------------------------------------------------------------------------------


func manage_expressions(with_sound: bool = false):
	# animiram glede na state

	randomize()
	match current_state:
		STATES.WHITE: # kliče ga na player on_hit
			pixel_face.set_animation("scramble")
			pixel_face.frame = randi() % pixel_face.frames.get_frame_count("scramble")
			pixel_face.call_deferred("play", "scramble") # defered zato, da se upošteva žrebanje štarta
			if with_sound:
				$Sounds/StrayFaceScramble.play()
		STATES.HUNTING:
#			print("HUNT")
			pixel_face.set_animation("scramble")
			pixel_face.frame = randi() % pixel_face.frames.get_frame_count("scramble")
		STATES.HOLDING:
#			print("HOLD")
			pixel_face.set_animation("scramble")
			pixel_face.frame = randi() % pixel_face.frames.get_frame_count("scramble")
			pixel_face.call_deferred("play", "scramble") # defered zato, da se upošteva žrebanje štarta
			if with_sound:
				$Sounds/StrayFaceScramble.play()
		STATES.DYING:
			pixel_face.set_animation("scramble")
			pixel_face.frame = randi() % pixel_face.frames.get_frame_count("scramble")
			pixel_face.call_deferred("play", "scramble") # defered zato, da se upošteva žrebanje štarta
			if with_sound:
					#				if color_poly.modulate == Global.color_white_pixel_bloom:
					#					$Sounds/StrayFaceScramble.play()
					#				else:
					$Sounds/StrayAu.play()
		_:
#			print("ALL")
			pixel_face.set_animation("faceless")
			pixel_face.stop() # zazih
#			pixel_face.


func play_sound(effect_for: String): # za klic iz animacije

	if not Global.sound_manager.game_sfx_set_to_off:
		match effect_for:
			#			"turning_color":
			#				var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
			#				$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
			"blinking":
				var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
				$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
				if current_state == STATES.DYING: # da se ne oglaša ob obračanju v steno
					var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
					$Sounds/BlinkingStatic.get_child(random_static_index).play()


func check_floor_for_move(move_direction: Vector2):

#	var move_to_position: Vector2 = global_position + move_direction * cell_size_x
#	if Global.game_manager.is_floor_position_free(move_to_position):
#		return true
#	else:
#		return false

	var neighbor = Global.detect_collision_in_direction(move_direction, neighbor_ray)
	return neighbor # uporaba v stalnem čekiranj sosedov


func get_neighbor_strays_on_hit(): # kliče player on hit

	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbors: Array
	for direction in directions_to_check:
		var neighbor = Global.detect_collision_in_direction(direction, neighbor_ray)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			if not neighbor.current_state == neighbor.STATES.DYING:# # če je vstanju umiranja se ne šteje za soseda
				current_cell_neighbors.append(neighbor)

	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov


func _get_direction_to_target(target_node: Node2D): # target_global_position: Vector2

	var vector_to_target: Vector2 = target_node.global_position - global_position

	# če je bližje v x smeri grem v x
	var following_direction: Vector2
	if (abs(vector_to_target.x) < abs(vector_to_target.y) and not vector_to_target.x == 0) or vector_to_target.y == 0:
		if vector_to_target.x < 0:
			following_direction = Vector2.LEFT
		elif vector_to_target.x > 0:
			following_direction = Vector2.RIGHT
	elif abs(vector_to_target.x) >= abs(vector_to_target.y) or vector_to_target.x == 0:
		if vector_to_target.y < 0:
			following_direction = Vector2.UP
		elif vector_to_target.y > 0:
			following_direction = Vector2.DOWN
	else:
		following_direction = Vector2.ZERO # zazih ... ni se še zgodilo

	return [following_direction, vector_to_target]


# SIGNALI ------------------------------------------------------------------------------------------------------


func _on_StepTimer_timeout() -> void:

	step(current_following_target)


func _on_PixelFace_frame_changed() -> void:

	var current_animation: String = pixel_face.get_animation()
	var animation_frame_count: int = pixel_face.frames.get_frame_count(current_animation)

	animation_current_frame +=1

	match current_animation:
		"scramble":
			match current_state:
				STATES.WHITE:
					if animation_current_frame >= animation_frame_count * 2:
						animation_current_frame = 0
						$Sounds/StrayFaceScramble.stop()
						pixel_face.stop()
				STATES.DYING:
					if animation_current_frame >= animation_frame_count * 2:
						animation_current_frame = 0
						$Sounds/StrayFaceScramble.stop()
						pixel_face.stop()
						pixel_face.play("hit_ver")


func _on_PixelFace_animation_finished() -> void:

	match pixel_face.get_animation():
		"hit_ver":
			pixel_face.hide()


func _on_Stray_tree_exiting() -> void:

	Global.game_manager.strays_in_game_count = - 1
	Global.game_manager.add_to_free_floor_positions(global_position)


func _on_Stray_tree_entered() -> void:

	Global.game_manager.remove_from_free_floor_positions(global_position)
	Global.game_manager.strays_in_game_count = 1

	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		if stray.global_position == global_position:
			printt ("overspawn II on stray - stray tree entered", self)
			call_deferred("queue_free")

	for player in get_tree().get_nodes_in_group(Global.group_players):
		if player.global_position == global_position:
			printt ("overspawn II on player - stray tree entered", self)
			call_deferred("queue_free")


func _on_StepTween_tween_all_completed() -> void:

	end_move()


func _on_VisibilityNotifier2D_screen_entered() -> void:
#	print("S5HJO")
	visible_on_screen = true
	Global.strays_on_screen.append(self)


func _on_VisibilityNotifier2D_screen_exited() -> void:
#	print("SHJO")

	visible_on_screen = false
	Global.strays_on_screen.erase(self)

