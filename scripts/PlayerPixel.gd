#class_name Pixel
extends Pixel
#
#
#signal stat_changed (stat_owner, stat, stat_change)
#signal stat_chang(stat_owner, stat, stat_change)
#
## states
#enum States {
#	WHITE = 1, # steping
#	BLUE, # push 
#	GREEN, # pull 
#	RED, # burst 
#	YELLOW, # teleport
#} 
#var current_state : int = States.WHITE setget _change_state # tole je int ker je rezultat številka
#var state_colors: Dictionary = {
#	1: Config.color_white, 
#	2: Config.color_blue, 
#	3: Config.color_green, 
#	4: Config.color_red, 
#	5: Config.color_yellow,
#}
#var pixel_color = state_colors[current_state]
#var skill_activated: bool = false
#var skill_change_count: int = 0
#
## motion
#var speed: float = 0
#var velocity: Vector2
#var direction = Vector2.ZERO
#var collision: KinematicCollision2D
#
## steps
#export(int, 1, 10) var steping_frame_skip: int = 2 # za kontrolo hitrosti
#export(int, 1, 10)  var death_mode_frame_skip = 2
#var frame_counter: int # pseudo time 
#var step_time: float = 0.15 # tween time
#var step_cell_count: int = 1 # je naslednja
#var slide_on = false
#var trail_ghost_fade_time: float = 0.2
#
## push & pull
#var pull_time: float = 0.6
#var pull_cell_count: int = 1
#var push_time: float = 0.5
#var push_cell_count: int = 1
#
## teleport
#var ghost_fade_time: float = 0.2
#var backup_time: float = 0.32
#
## burst cocking
#var cocking_time: float = 0
#var cocking_ghost_spawn_time: float = 0.2 # niso sekunde a
#var cocking_ghost_fill_time: float = 0.1
#var cocking_ghosts: Array
#var cocking_ghost_count_max: int = 5
#var cocking_room: bool = true
#
## burst release
#var speed_burst_max: float = 0
#var speed_cock_ghost_ad: float = 7
#var strech_ghost_shrink_time: float = 0.2
## _temp za bug
#var burst_activated: bool = false # zaenkrat nič ne vpliva	
#
## arena
#var cell_size_x: int # pogreba od arene, ki jo dobi od tilemapa
##var floor_cells: Array = []
#onready var floor_cells: Array = Global.game_manager.available_positions
#
#
#var new_tween: SceneTreeTween
#onready var collision_ray: RayCast2D = $RayCast2D
#onready var animation_player: AnimationPlayer = $AnimationPlayer
#
#onready var PixelGhost = preload("res://scenes/PixelGhost.tscn")
#
#
#func _ready() -> void:
##	floor_cells = Global.game_manager.available_positions
#
#	randomize()
#
#	Global.print_id(self)
##	print (name, " se je rodil na: ", global_position)
#
#	add_to_group(Config.group_players)
#
#	# snap it
#	cell_size_x = 32 #Global.game_manager.grid_cell_size.x # get cell size ... če je tole noče delat sama
##	global_position = global_position.snapped(Vector2.ONE * cell_size_x)
##	global_position += Vector2.ONE * cell_size_x/2 # zamik centra
#	snap_to_nearest_grid()
#
#	# določimo distanco znotraj katere preverjamo bližino točke
#	var distance_to_position: float = cell_size_x/2 # začetna distanca je velikosti celice, ker na koncu je itak bližja
#	var nearest_cell: Vector2
#	for cell in floor_cells:
#		if cell.distance_to(global_position) < distance_to_position:
#			distance_to_position = cell.distance_to(global_position)
#			nearest_cell = cell
#		else:
#			break


func _physics_process(delta: float) -> void:

	if Input.is_action_just_pressed("x"):
		light_out()

#	if slide_on:
##		modulate = Color.red
#		pass
#	else:
#		modulate = state_colors[current_state]

	state_machine()

	frame_counter += 1

	# gibanje za burst
	velocity = direction * speed # dokler je speed 0, je velocity tudi 0 v tweenih speed se regulira v tweenu 
	move_and_collide(velocity) 
#	if collision:
##		velocity = velocity.bounce(collision.normal)
#		print("KOLIZIJA")
	pass
	

func state_machine():
		
	match current_state: 
		States.WHITE:
			step_control()
		States.BLUE:
			push_control()
		States.GREEN: 
			pull_control()
		States.RED:
			burst_control()
		States.YELLOW:
			teleport_control()
#		States.BLACK:
#			pass	


	# ne manjaj stanj sredi akcije
	if not skill_activated:
		# change state
		if Input.is_action_just_pressed("shift"):
			select_next_state()	
		
	# change state
#	if Input.is_action_just_pressed("ctrl"):
#		select_next_state()	
				
				
#func select_next_state():
#
#		# ciklanje v zaporedju
#		if current_state < States.size():
#			self.current_state = current_state + 1 
#		else:		
#			self.current_state = 1	


func _change_state(new_state_id):
	
	# set normal mode
	skill_activated = false
	direction = Vector2.ZERO
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
	collision_ray.force_raycast_update()	
#	snap_to_nearest_grid()

	# transition
	
	# statistika
	skill_change_count += 1
	emit_signal("stat_changed", self, "skill_change_count", 1)
	
	# new state
	current_state = new_state_id
	modulate = state_colors[current_state]

	# new state
	current_state = new_state_id
	modulate = state_colors[current_state]
		

func step_control():
	
	if not slide_on:
		if Input.is_action_just_pressed("ui_up"):
			direction = Vector2.UP
			step(direction)
		elif Input.is_action_just_released("ui_up"):
			reset_direction()
		if Input.is_action_just_pressed("ui_down"):
			direction = Vector2.DOWN
			step(direction)
		elif Input.is_action_just_released("ui_down"):
			reset_direction()
		if Input.is_action_just_pressed("ui_left"):
			direction = Vector2.LEFT
			step(direction)
		elif Input.is_action_just_released("ui_left"):
			reset_direction()
		if Input.is_action_just_pressed("ui_right"):
			direction = Vector2.RIGHT
			step(direction)
		elif Input.is_action_just_released("ui_right"):
			reset_direction()
	else:	
		slide_control()

	if Input.is_action_pressed("space"):
		slide_on = true
	else:
		slide_on = false	


func step(step_direction):
	
	snap_to_nearest_grid()
	
	# če vidi steno v planirani smeri
	if detect_collision_in_direction(direction) or skill_activated: 
		return		
	
	# pošljem signal, da odštejem točko
#	emit_signal("stat_changed", self, "cells_travelled", 1)
	
#	# trail ghosts
#	var new_pixel_ghost = PixelGhost.instance()
#	new_pixel_ghost.global_position = global_position
#	Global.node_creation_parent.add_child(new_pixel_ghost)
#	# fadeout
#	new_tween = get_tree().create_tween()
#	new_tween.tween_property(new_pixel_ghost, "modulate:a", 0, trail_ghost_fade_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
#	new_tween.tween_callback(new_pixel_ghost, "queue_free")
#
	# če ni stena naredi korak
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
	collision_ray.force_raycast_update()
	if not collision_ray.is_colliding():
		new_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		new_tween.tween_property(self, "position", global_position + direction * cell_size_x, 0.2)
	
		
func slide_control():
	
	if Input.is_action_pressed("ui_up"):
		direction = Vector2.UP
		slide(direction)
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2.DOWN
		slide(direction)
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2.LEFT
		slide(direction)
	elif Input.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT
		slide(direction)
	elif Input.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT
		slide(direction)
	else:
		reset_direction()


func slide(slide_direction):
	
	# če vidi steno v planirani smeri
	if detect_collision_in_direction(slide_direction) or skill_activated: 
		return	

	if Global.game_manager.deathmode_on:
		steping_frame_skip = death_mode_frame_skip

	# trail ghosts
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	Global.node_creation_parent.add_child(new_pixel_ghost)
	# fadeout
	new_tween = get_tree().create_tween()
	new_tween.tween_property(new_pixel_ghost, "modulate:a", 0, trail_ghost_fade_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	new_tween.tween_callback(new_pixel_ghost, "queue_free")

	
	if frame_counter % steping_frame_skip == 0:
		global_position += slide_direction * cell_size_x # premik za velikost celice


# SKILLS SEKCIJA ______________________________________________________________________________________________________________


func burst_control():

	if Input.is_action_pressed("ui_up"):
		direction = Vector2.DOWN
		burst_cocking(direction)
	if Input.is_action_just_released("ui_up"):
		cocking_time = 0
		if skill_activated:
			direction = Vector2.DOWN
			release_burst(direction)

	if Input.is_action_pressed("ui_down"):
		direction = Vector2.UP
		burst_cocking(direction)
	if Input.is_action_just_released("ui_down"):
		cocking_time = 0
		if skill_activated:
			direction = Vector2.UP
			release_burst(direction)

	if Input.is_action_pressed("ui_left"):
		direction = Vector2.RIGHT
		burst_cocking(direction)
	if Input.is_action_just_released("ui_left"):
		cocking_time = 0
		if skill_activated:
			direction = Vector2.RIGHT
			release_burst(direction)

	if Input.is_action_pressed("ui_right"):
		direction = Vector2.LEFT
		burst_cocking(direction)
	if Input.is_action_just_released("ui_right"):
		cocking_time = 0
		if skill_activated:
			direction = Vector2.LEFT
			release_burst(direction)
	

func burst_cocking(burst_direction):
#	print("set_burst_power")

	var cock_direction = - burst_direction
	
	# prostor začetek napenjanja preverja pixel ... če vidi kaj v planirani smeri
	if detect_collision_in_direction(cock_direction): 
		return	
	
	# prostor nadaljevanje napenjanja preverja ghost
	if cocking_ghosts.size() < cocking_ghost_count_max and cocking_room:
			
			# čas držanja tipke (znotraj nastajanja ene cock celice)
			cocking_time += 1 / 60.0 # fejk delta
			
			# ko poteče čas za eno celico mimo, jo spawnam
			if cocking_time > cocking_ghost_spawn_time:
				
				# aktiviram skill
				skill_activated = true
				
				cocking_time = 0
				# prištejem hitrost
				speed_burst_max += speed_cock_ghost_ad
				# spawnaj g+cock celico
				spawn_cock_ghost(cock_direction, cocking_ghosts.size() + 1) # + 1 zato, da se prvi ne spawna direktno nad pixlom
	
	
func spawn_cock_ghost(cocking_direction, cocking_ghosts_count):
#	print("spawn_cock_ghost")
	
	var final_ghost_scale: Vector2 # ghost se lahko skejl v hor ali ver vektorju ...v katero smer zunaj zato, da jo lahko twinamo
	
	# instance ghost pod mano
	var new_pixel_ghost = PixelGhost.instance()
	
	# ghost je trenutne barve pixla
	new_pixel_ghost.modulate = state_colors[current_state]
	# z vsakim naj bo bolj prosojen (relativno z max številom celic)
	new_pixel_ghost.modulate.a = 1.0 - (cocking_ghosts_count / float(cocking_ghost_count_max + 1))
	# z vsakim se zamika pozicija
	new_pixel_ghost.global_position = global_position + cocking_direction * cell_size_x * cocking_ghosts_count# pozicija se zamakne za celico
	new_pixel_ghost.global_position -= cocking_direction * cell_size_x/2
	
	# v kateri smeri je scale
	if direction.y == 0: # smer horiz
		new_pixel_ghost.scale.x = 0
	elif direction.x == 0: # smer ver
		new_pixel_ghost.scale.y = 0
	
	# spawn
	Global.node_creation_parent.add_child(new_pixel_ghost)
	
	# animiram cell strech
	new_tween = get_tree().create_tween()
	new_tween.tween_property(new_pixel_ghost, "scale", Vector2.ONE, cocking_ghost_spawn_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	new_tween.parallel().tween_property(new_pixel_ghost, "position", global_position + cocking_direction * cell_size_x * cocking_ghosts_count, cocking_ghost_spawn_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# ray detect velikost je velikost napenjanja
	new_pixel_ghost.ghost_ray.cast_to = direction * cell_size_x
	new_pixel_ghost.connect("ghost_detected_body", self, "_on_ghost_detected_body")
	
	# dodam celico v array celic tega zaleta
	cocking_ghosts.append(new_pixel_ghost)


func release_burst(burst_direction):
	print("release_burst")
	
	for ghost in cocking_ghosts:
		new_tween = get_tree().create_tween()
		new_tween.tween_property(ghost, "modulate:a", 1, cocking_ghost_fill_time)
		yield(get_tree().create_timer(cocking_ghost_fill_time),"timeout")
	
	
	burst(burst_direction, cocking_ghosts.size())
		
		
func burst(burst_direction, ghosts_count):
#	print("burst")
	
	if not burst_activated:
		
		burst_activated =  true
		# laser preverja kolizije za toliko enot kolikor je bil burst napet		
		detect_collision_in_direction(burst_direction * ghosts_count)
			
		var ray_collider = collision_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
		var backup_direction = - burst_direction

		# spawn stretch ghost
		var new_stretch_ghost = PixelGhost.instance()
		new_stretch_ghost.global_position = global_position
		new_stretch_ghost.modulate = state_colors[current_state]
		Global.node_creation_parent.add_child(new_stretch_ghost)
		
		# vertikalno ali horizontalno?
		if burst_direction.y == 0: # če je smer horiz
			new_stretch_ghost.scale = Vector2(ghosts_count, 1)
		elif burst_direction.x == 0: # če je smer ver
			new_stretch_ghost.scale = Vector2(1, ghosts_count)
		
		# strech ghost 
		new_stretch_ghost.position = global_position - (burst_direction * cell_size_x * ghosts_count)/2 - burst_direction * cell_size_x/2
		
		# spazni ghoste
		for ghost in cocking_ghosts:
			ghost.queue_free()
		cocking_ghosts = []
		
		new_tween = get_tree().create_tween()
		
		# release ghost 
		new_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		new_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		
		# release pixel
		new_tween.tween_callback(new_stretch_ghost, "queue_free")
		new_tween.parallel().tween_property(self, "speed", speed_burst_max, 0.01).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		
		# resetiram max spid
		speed_burst_max = 0
		
		# zaključek v signalu _on_DetectArea_body_entered
	
	
func push_control():
	
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.UP
		push(direction)
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.DOWN
		push(direction)
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.LEFT
		push(direction)
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.RIGHT
		push(direction)
	

func push(push_direction):
	
	# se dotika nečesa v smeri?	
	if not detect_collision_in_direction(push_direction) or skill_activated: # preverjam obstoj kolizijo s pixlom ... if collision_ray.is_colliding(): .. ne rabim
		return
		
	var ray_collider = collision_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
	var backup_direction = - push_direction
	
	# se dotika pixla v smeri?
	if not ray_collider.is_in_group(Config.group_strays):
		return	
	# ima prostor za zalet?
	if detect_collision_in_direction(backup_direction):
		return	
	
	skill_activated = true
		
	# spawn ghost pod mano
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.modulate = state_colors[current_state]
	Global.node_creation_parent.add_child(new_pixel_ghost)


	new_tween = get_tree().create_tween()
	# napnem
	new_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
	# spustim
	new_tween.tween_property(self, "position", global_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
	new_tween.tween_property(ray_collider, "position", ray_collider.global_position + push_direction * cell_size_x * push_cell_count, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	new_tween.tween_callback(self, "_change_state", [States.WHITE])
	new_tween.parallel().tween_callback(new_pixel_ghost, "queue_free")
	
	
func pull_control():
	
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.DOWN
		pull(direction)
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.UP
		pull(direction)
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.RIGHT
		pull(direction)
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.LEFT
		pull(direction)
	

func pull(target_direction):
	# ray je usmerjen v smer 
	# če je tam tarča, spelje step()
	# če je prostor (preverja c stepu) se premakne stran od tarče
	# tarčina pozicija sledi pixlu
	# če je s se premakne v smer stran od nje
	
	if not detect_collision_in_direction(target_direction) or skill_activated: # preverjam obstoj kolizijo s pixlom ... if collision_ray.is_colliding(): .. ne rabim
		return	
	skill_activated = true

	var pull_direction = - target_direction
	var ray_collider = collision_ray.get_collider()
	
	if not ray_collider.is_in_group(Config.group_strays):
		return
	
	# spawn ghost pod mano
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.modulate = state_colors[current_state]
	Global.node_creation_parent.add_child(new_pixel_ghost)
	
	new_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	new_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	new_tween.tween_property(ray_collider, "position", ray_collider.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	new_tween.parallel().tween_property(new_pixel_ghost, "position", new_pixel_ghost.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	new_tween.tween_callback(self, "_change_state", [States.WHITE])
	new_tween.tween_callback(ray_collider, "select_next_state")
	new_tween.parallel().tween_callback(new_pixel_ghost, "queue_free")


func teleport_control():
	
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.UP
		teleport(direction)
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.DOWN
		teleport(direction)
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.LEFT
		teleport(direction)
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.RIGHT
		teleport(direction)


func teleport(teleport_direction):
	
	# preverim če kolajda s steno
	if not detect_collision_in_direction(teleport_direction) or skill_activated:
		return	
	if collision_ray.get_collider().is_in_group(Config.group_strays):
		return
	skill_activated = true
	
	# spawn ghost
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.direction = teleport_direction
	new_pixel_ghost.modulate = state_colors[current_state]
	new_pixel_ghost.floor_cells = floor_cells
	new_pixel_ghost.cell_size_x = cell_size_x
	Global.node_creation_parent.add_child(new_pixel_ghost)
	new_pixel_ghost.connect("ghost_target_reached", self, "_on_ghost_target_reached")
	
	# zaključek v signalu _on_ghost_target_reached
	

func light_out():
#	var random_animation_index =  randi() % 3 + 1
#	var random_animation_name: String = "glitch_%s" % random_animation_index
#	print (random_animation_name)
	animation_player.play("light_out")


func die():
	emit_signal("stat_changed", self, "player_life", -1)
	print("KVEFRI")
	queue_free()


# UTILITI SEKCIJA ______________________________________________________________________________________________________________


func reset_direction():
	direction = Vector2.ZERO
	collision_ray.cast_to = direction * cell_size_x 


func detect_collision_in_direction(next_direction):
	
	collision_ray.cast_to = next_direction * cell_size_x # ray kaže na naslednjo pozicijo 
	collision_ray.force_raycast_update()	
	
	if collision_ray.is_colliding():
		return true


func snap_to_nearest_grid():
	
#	floor_cells = Global.game_manager.available_positions
	
	var current_position = Vector2(global_position.x - cell_size_x/2, global_position.y - cell_size_x/2)
	
#	print (name, current_position)
#	if name == "Moe":
#		print (name, " before: ", current_position)
#		print (floor_cells)
	
	# če ni že snepano
	if not floor_cells.has(current_position): 
		# določimo distanco znotraj katere preverjamo bližino točke
		var distance_to_position: float = cell_size_x # začetna distanca je velikosti celice, ker na koncu je itak bližja
		var nearest_cell: Vector2
		for cell in floor_cells:
			if cell.distance_to(current_position) < distance_to_position:
				distance_to_position = cell.distance_to(current_position)
				nearest_cell = cell
		
#	if name == "Moe":
#		print (name, " after: ", current_position)
#		print (floor_cells)
		
		# snap it
		global_position = Vector2(nearest_cell.x + cell_size_x/2, nearest_cell.y + cell_size_x/2)
		
	
# SIGNALI ______________________________________________________________________________________________________________

		
func _on_ghost_target_reached(ghost_body, ghost_position):
	
	new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "modulate:a", 0, ghost_fade_time)
	new_tween.tween_property(self, "global_position", ghost_position, 0.1)
	new_tween.tween_callback(self, "_change_state", [States.WHITE])
	new_tween.parallel().tween_callback(ghost_body, "fade_out")
#	new_tween.tween_property(self, "skill_activated", false, 0.01)
	pass

		
func _on_ghost_detected_body(body):
	
	if body != self:
		cocking_room = false


#var pixel_color_sum: Color # suma barv za picla
#
## stats v hudu
#onready var picked_color_rect: ColorRect = $"../UI/HUD/HudControl/PickedColor/ColorBox/ColorRect"
#onready var color_value: Label = $"../UI/HUD/HudControl/PickedColor/Value"
#
#var pixel_color_sum_r: float
#var pixel_color_sum_g: float
#var pixel_color_sum_b: float

func _on_DetectArea_body_entered(body: Node) -> void:
	
	speed = 0
	burst_activated = false
	
	if body.is_in_group(Config.group_tilemap):
		_change_state(States.WHITE)
		
		#žrebam animacijo
		var random_animation_index = randi() % 3 + 1
		var random_animation_name: String = "glitch_%s" % random_animation_index
		animation_player.play(random_animation_name)
		
	# pobiranje  barv 
	if skill_activated:
#		speed = 0
		if body.is_in_group(Config.group_strays):
			
			# poberi trenutni seštevek barv
			var current_color_sum = state_colors[current_state]
			
			# change pixel
			speed = 0
			_change_state(States.WHITE)
			
			# poberi barvo pixla
			var picked_color = body.modulate
			picked_color_rect.color = picked_color
			
			# picked color
			var rgb_red: float = picked_color.r * 255
			var rgb_green: float = picked_color.g * 255
			var rgb_blue: float = picked_color.b * 255
			var display_red: String = "%03d" % rgb_red
			var display_green: String = " %03d" % rgb_green
			var display_blue: String = " %03d" % rgb_blue
			
			# v hud
			color_value.text = display_red + display_green + display_blue
			
			# skupna barva
			pixel_color_sum = current_color_sum + picked_color # statistika jo pobere
						
			# za hud
			var pixel_color_sum_values = Color(pixel_color_sum)
			pixel_color_sum_r = round(pixel_color_sum_values.r * 255)
			pixel_color_sum_g = round(pixel_color_sum_values.g * 255)
			pixel_color_sum_b = round(pixel_color_sum_values.b * 255)
			Global.game_manager.player_color_sum_r = pixel_color_sum_r
			Global.game_manager.player_color_sum_g = pixel_color_sum_g
			Global.game_manager.player_color_sum_b = pixel_color_sum_b
			print("pixel_color_sum_values", pixel_color_sum_values, pixel_color_sum_r, pixel_color_sum_g, pixel_color_sum_b)
			
			# player color
			modulate = pixel_color_sum
		
			# stray disabled
			body.current_state = body.States.BLACK
			body.turn_off() # stray javi svojo smrt v hud
			
			
			printt("prev color sum", current_color_sum)
			printt("picked color", body.state_colors[body.current_state])
			printt("new color sum", pixel_color_sum)
			# seštej in zabeleži v statistiko
			
#		else:	
#			explode_pixel()



#func turn_off():
#
#	new_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
#	new_tween.tween_property(self, "modulate:a", 0, 3)
#	new_tween.tween_callback(self, "die")
#
#
#func die():
#	# pošljem barvo
##	emit_signal("stat_changed", "black_pixels", 1) 
#
#	# pošljem turnoff
#	emit_signal("stat_changed", self, "black_pixels", 1) # owner je v tem primeru nepomemben ... zato ga ni
#	print("strey kvfrid")
#	queue_free()
