extends Area2D
class_name Stray

enum STATES {IDLE, MOVING, DYING, WALL} # STATIC # static, unmovable ... ko je GO ali pa je poden
var current_state = STATES.IDLE # ni vready, da lahko setam že ob spawnu

var stray_color: Color
var visible_on_screen: bool = true # more bit prižgan, da dela pri vseh igrah
var previous_position: Vector2 = Vector2.ZERO
var step_attempt: int = 1 # začne z ena, ker preverja preostale 3 smeri (prva je že zasedena)

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

	end_move()

	# zazih ... če je v internih kaj
	set_physics_process(false)
	set_process(false)


func show_stray(): # kliče GM
	# če je pozicija res prazna

	pixel_face.stop() # zazih

	if current_state == STATES.WALL:
		turn_to_wall()
		pixel_face.set_animation("faces")
		#		pixel_face.set_deferred("frame", 1)
		pixel_face.frame = randi() % pixel_face.frames.get_frame_count("faces")
	else:
		pixel_face.hide()
		#		pixel_face.set_animation("faceless")
		if visible_on_screen:
			# žrebam animacijo
			var random_animation_index = randi() % 3 + 1
			var random_animation_name: String = "glitch_%s" % random_animation_index
			animation_player.play(random_animation_name)
		else:
			modulate.a = 1

#		if pixel_face.visible: # v home ni vidna
#			pixel_face.set_animation("faces")
##			pixel_face.set_deferred("frame", 1)
#			pixel_face.frame = randi() % pixel_face.frames.get_frame_count("faces")


func animate_face(stray_index: int = 0):
	# animiram glede na state

	randomize()
	match current_state:
		STATES.WALL: # kliče ga na hit
			pixel_face.set_animation("scramble")
			pixel_face.frame = randi() % pixel_face.frames.get_frame_count("scramble")
			pixel_face.call_deferred("play", "scramble")
			$Sounds/StrayFaceScramble.play()
			yield(get_tree().create_timer(0.85), "timeout")
			$Sounds/StrayFaceScramble.stop()
			pixel_face.stop()
		STATES.DYING:
			if stray_index == 0:
				pixel_face.set_animation("scramble")
				pixel_face.frame = randi() % pixel_face.frames.get_frame_count("scramble")
				pixel_face.play("scramble")
				yield(get_tree().create_timer(1), "timeout")
				pixel_face.stop()
				pixel_face.play("hit_ver")
				pixel_face.emit_signal("visibility_changed") # fejkam skrivanje, da die() steče naprej
				yield(pixel_face, "animation_finished")
				pixel_face.hide()
			else:
				pixel_face.set_animation("connected")
				yield(get_tree().create_timer(0.2), "timeout")
				pixel_face.hide()
		STATES.MOVING:
			pass


func die(stray_in_stack_index: int, strays_in_stack_count: int):

	if not current_state == STATES.DYING:

		current_state = STATES.DYING

		if pixel_face.visible:
			animate_face()
			yield(pixel_face, "visibility_changed") # ko je sprite animacija končana, se sprite skrije
			# zaključim die()
			#			Global.game_manager.remove_from_free_floor_positions(global_position)
			#			Global.game_manager.on_stray_die(self)
			#			call_deferred("queue_free")
			#			return
		#		else:
		#			$Sounds/StrayAu.play()

		global_position = Global.snap_to_nearest_grid(global_position)
		Global.game_manager.remove_from_free_floor_positions(global_position)

		# čakalni čas
		var wait_to_destroy_time: float = sqrt(0.07 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
		yield(get_tree().create_timer(wait_to_destroy_time), "timeout")

		var collision_disabled_delay: float = 0.3
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
			yield(get_tree().create_timer(collision_disabled_delay), "timeout") # če je delay v tvinu ne dela okej
			collision_shape.disabled = true
			Global.game_manager.add_to_free_floor_positions(global_position)


		Global.game_manager.on_stray_die(self)
		call_deferred("queue_free") # predvideva, da more bit deferd, da se lahko collision izklopi


func turn_to_wall():

	current_state = STATES.WALL

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


func step(step_direction: Vector2 = Vector2.DOWN):

	if current_state == STATES.IDLE:

		# če je pozicija prosta korakam (in restiram poiskuse, če ni pa probam v drugo smer
		var intended_position: Vector2 = global_position + step_direction * cell_size_x

		if Global.game_manager.is_floor_position_free(intended_position):

			step_attempt = 1 # reset na 1

			current_state = STATES.MOVING
			previous_position = global_position
			Global.game_manager.remove_from_free_floor_positions(global_position + step_direction * cell_size_x)

			var step_time: float = Global.game_manager.game_settings["stray_step_time"]
			var step_tween = get_tree().create_tween()
			step_tween.tween_property(self ,"position", intended_position, step_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
			yield(step_tween, "finished")
			end_move()
		else:
			# začne z ena, ker preverja preostale 3 smeri (prva je že zasedena)
			step_attempt += 1
			if step_attempt <= 4:
				var new_direction = step_direction.rotated(deg2rad(90))
				step(new_direction)
			else:
				step_attempt = 1 # reset na 1


func push_stray(push_direction: Vector2, push_time: float):

	current_state = STATES.MOVING

	previous_position = Vector2.ZERO # prejšnja poz je nova pozicija plejerja ali straysa v vrsti
	Global.game_manager.remove_from_free_floor_positions(global_position + push_direction * cell_size_x)

	var heavier_hit_delay: float = 0.0  # z delayom je porinek bolj pristen in "težak"
	var push_tween = get_tree().create_tween()
	push_tween.tween_property(self, "position", global_position + push_direction * cell_size_x, push_time / 2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(heavier_hit_delay)
	push_tween.tween_callback(self, "end_move")


func pull_stray(pull_direction: Vector2, pull_time: float):

	current_state = STATES.MOVING

	previous_position = global_position
	Global.game_manager.remove_from_free_floor_positions(global_position + pull_direction * cell_size_x)

	var pull_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pull_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x, pull_time)
	pull_tween.tween_callback(self, "end_move")


func end_move():

	if current_state == STATES.MOVING: # da se stanje resetira samo če ni DYING al pa WALL
		current_state = STATES.IDLE

	global_position = Global.snap_to_nearest_grid(global_position)

	if not previous_position == Vector2.ZERO:
		Global.game_manager.add_to_free_floor_positions(previous_position)


# UTILITI ------------------------------------------------------------------------------------------------------


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


func get_neighbor_strays_on_hit(): # kliče player on hit

	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbors: Array
	for direction in directions_to_check:
		var neighbor = Global.detect_collision_in_direction(direction, neighbor_ray)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			if not neighbor.current_state == neighbor.STATES.DYING:# # če je vstanju umiranja se ne šteje za soseda
				current_cell_neighbors.append(neighbor)

	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov


# SIGNALI ------------------------------------------------------------------------------------------------------


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
#	print("SHJO")
	visible_on_screen = true
	Global.strays_on_screen.append(self)


func _on_VisibilityNotifier2D_screen_exited() -> void:
#	print("SHJO")

	visible_on_screen = false
	Global.strays_on_screen.erase(self)
