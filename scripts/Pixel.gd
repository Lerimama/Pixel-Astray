class_name Pixel
extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change)

export var pixel_is_player: = false


# states
enum States {
	WHITE = 1, # steping
	BLUE, # push 
	GREEN, # pull 
	RED, # burst 
	YELLOW, # teleport
} 
var current_state : int = States.WHITE setget _change_state # tole je int ker je rezultat številka
var state_colors: Dictionary = {
	1: Config.color_white, 
	2: Config.color_blue, 
	3: Config.color_green, 
	4: Config.color_red, 
	5: Config.color_yellow,
}
#var pixel_color: Color = Color.white
var pixel_color = state_colors[current_state]
var skill_activated: bool = false
var skill_change_count: int = 0

# motion
var speed: float = 0
var velocity: Vector2
var direction = Vector2.ZERO
#var collision: KinematicCollision2D
	
# steps
export(int, 1, 10)  var death_mode_frame_skip = 2
export(int, 1, 10) var slide_frame_skip: int = 4 # za kontrolo hitrosti
var frame_counter: int # pseudo time 
var step_time: float = 0.15 # tween time
var step_cell_count: int = 1 # je naslednja
var slide_on = false
var trail_ghost_fade_time: float = 0.4

# push & pull
var pull_time: float = 0.6
var pull_cell_count: int = 1
var push_time: float = 0.5
var push_cell_count: int = 1

# teleport
var ghost_fade_time: float = 0.2
var backup_time: float = 0.32
var ghost_max_speed: float = 10

# burst cocking
var cocking_time: float = 0
var cocking_ghost_spawn_time: float = 0.2 # niso sekunde a
var cocking_ghost_fill_time: float = 0.05
var cocking_ghosts: Array
var cocking_ghost_count_max: int = 5
var cocking_room: bool = true

# burst release
var speed_burst_max: float = 0
var speed_cock_ghost_ad: float = 7
var strech_ghost_shrink_time: float = 0.2
# _temp za bug
var burst_activated: bool = false # zaenkrat nič ne vpliva	

# arena
var cell_size_x: int # pogreba od arene, ki jo dobi od tilemapa
onready var floor_cells: Array = Global.game_manager.available_positions

var new_tween: SceneTreeTween
onready var collision_ray: RayCast2D = $RayCast2D
onready var animation_player: AnimationPlayer = $AnimationPlayer

var pixel_color_sum: Color # suma barv za picla

onready var detect_area: Area2D = $DetectArea

onready var PixelGhost = preload("res://scenes/PixelGhost.tscn")
#onready var picked_color_rect: ColorRect = $"../HudLayer/HudControl/PickedColor/ColorBox/ColorRect"
#onready var picked_color_value_label: Label = $"../HudLayer/HudControl/PickedColor/Value"
#onready var player_color_label: Label = $"../HudLayer/HudControl/ColorSum/Value"





func _ready() -> void:
	
	randomize()
	
	Global.print_id(self)
	
#	# zabeleži rojstvo in naj VSI pomembni vejo
#	emit_signal("stat_changed", self, "player_active", true)
#	...  po novem ob spawnanju iz GMja
	
#	print (name, " se je rodil na: ", global_position)
	
	add_to_group(Config.group_pixels)
	
	# snap it
	cell_size_x = 32 #Global.game_manager.grid_cell_size.x # get cell size ... če je tole noče delat sama
#	global_position = global_position.snapped(Vector2.ONE * cell_size_x)
#	global_position += Vector2.ONE * cell_size_x/2 # zamik centra
	snap_to_nearest_grid()

	# določimo distanco znotraj katere preverjamo bližino točke
	var distance_to_position: float = cell_size_x/2 # začetna distanca je velikosti celice, ker na koncu je itak bližja
	var nearest_cell: Vector2
	for cell in floor_cells:
		if cell.distance_to(global_position) < distance_to_position:
			distance_to_position = cell.distance_to(global_position)
			nearest_cell = cell
		else:
			break


func _physics_process(delta: float) -> void:
#	printt("pixel_color_sum", pixel_color_sum)
	
	
	if pixel_is_player:	
#		modulate = pixel_color
		if current_state == States.WHITE:
			modulate = pixel_color
		elif current_state == States.RED:
			# gibanje za burst
			velocity = direction * speed # dokler je speed 0, je velocity tudi 0 v tweenih speed se regulira v tweenu 
			move_and_collide(velocity) 
#		modulate = pixel_color
		manage_input()
	else:
		if Input.is_action_just_pressed("ctrl"):
			select_next_state()	
	
	frame_counter += 1

	
func manage_input():
	
	if current_state == States.RED: 
		burst_control() # nestrandardni inputi
	elif slide_on:
		slide_control() # nestrandardni inputi
	 # strandardni inputi
	else:
		if Input.is_action_just_pressed("ui_up"):
			direction = Vector2.UP
			apply_skill(direction)
		if Input.is_action_just_pressed("ui_down"):
			direction = Vector2.DOWN
			apply_skill(direction)
		if Input.is_action_just_pressed("ui_left"):
			direction = Vector2.LEFT
			apply_skill(direction)
		if Input.is_action_just_pressed("ui_right"):
			direction = Vector2.RIGHT
			apply_skill(direction)
	
	# ne manjaj stanj sredi akcije
	if not skill_activated:
		# change state
		if Input.is_action_just_pressed("shift"):
			select_next_state()	
		if Input.is_action_just_pressed("x"):
			die()
	
	
	if Input.is_action_pressed("space") and current_state == States.WHITE:
		slide_on = true
	else:
		slide_on = false			
				
						
func apply_skill(pressed_direction):
	
	match current_state: 
		States.WHITE:
			step(pressed_direction)
#			if Input.is_action_pressed("space"):
#				slide_on = true
#			else:
#				slide_on = false	
		States.BLUE:
			push(pressed_direction)
		States.GREEN: 
			pull(-pressed_direction)
		States.YELLOW:
			teleport(pressed_direction)
				
				
func select_next_state():
		
	# ciklanje v zaporedju
	if current_state < States.size():
		self.current_state = current_state + 1 
	else:		
		self.current_state = 1	


func _change_state(new_state_id):
	
#	# set normal mode
#	speed = 0
	skill_activated = false
	detect_area.monitoring = true
	direction = Vector2.ZERO
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
	collision_ray.force_raycast_update()	

	# statistika
	skill_change_count += 1
	emit_signal("stat_changed", self, "skill_change_count", 1)
	
	# new state
	current_state = new_state_id
#	pixel_color = state_colors[current_state]
	modulate = state_colors[current_state]


# STEPS ______________________________________________________________________________________________________________


func step(step_direction):
	
	
#	print(global_position)
	
	# če vidi steno v planirani smeri
	if detect_collision_in_direction(direction) or skill_activated: 
		return		
	
	# pošljem signal, da odštejem točko
	emit_signal("stat_changed", self, "cells_travelled", 1)
	
	# če ni stena naredi korak
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
	collision_ray.force_raycast_update()
	if not collision_ray.is_colliding():
		snap_to_nearest_grid()
		new_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		new_tween.tween_property(self, "position", global_position + direction * cell_size_x, 0.2)
		new_tween.tween_callback(self, "snap_to_nearest_grid")
		
#	print(global_position)
		
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

func spaw_trail_ghost():
	# trail ghosts
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.modulate = pixel_color
	new_pixel_ghost.modulate.a = 0.15
	Global.node_creation_parent.add_child(new_pixel_ghost)
	# fadeout
	new_tween = get_tree().create_tween()
	new_tween.tween_property(new_pixel_ghost, "modulate:a", 0, trail_ghost_fade_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	new_tween.tween_callback(new_pixel_ghost, "queue_free")
	
	
func slide(slide_direction):
	
	# če vidi steno v planirani smeri
	if detect_collision_in_direction(slide_direction) or skill_activated: 
		return	

	if Global.game_manager.deathmode_on:
		slide_frame_skip = death_mode_frame_skip
	spaw_trail_ghost()


	
	if frame_counter % slide_frame_skip == 0:
		global_position += slide_direction * cell_size_x # premik za velikost celice


# BURST ______________________________________________________________________________________________________________


func burst_control():

	if Input.is_action_pressed("ui_up"):
		direction = Vector2.DOWN
		cock_burst(direction)
	if Input.is_action_just_released("ui_up"):
		cocking_time = 0
		if skill_activated:
			direction = Vector2.DOWN
			release_burst(direction)

	if Input.is_action_pressed("ui_down"):
		direction = Vector2.UP
		cock_burst(direction)
	if Input.is_action_just_released("ui_down"):
		cocking_time = 0
		if skill_activated:
			direction = Vector2.UP
			release_burst(direction)

	if Input.is_action_pressed("ui_left"):
		direction = Vector2.RIGHT
		cock_burst(direction)
	if Input.is_action_just_released("ui_left"):
		cocking_time = 0
		if skill_activated:
			direction = Vector2.RIGHT
			release_burst(direction)

	if Input.is_action_pressed("ui_right"):
		direction = Vector2.LEFT
		cock_burst(direction)
	if Input.is_action_just_released("ui_right"):
		cocking_time = 0
		if skill_activated:
			direction = Vector2.LEFT
			release_burst(direction)
	

func cock_burst(burst_direction):
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
	
	# instance ghost pod mano
	var new_pixel_ghost = PixelGhost.instance()
	
	# ghost je trenutne barve pixla
	new_pixel_ghost.modulate = modulate
	# z vsakim naj bo bolj prosojen (relativno z max številom celic)
	new_pixel_ghost.modulate.a = 1.0 - (cocking_ghosts_count / float(cocking_ghost_count_max + 1))
	# z vsakim se zamika pozicija
	new_pixel_ghost.global_position = global_position + cocking_direction * cell_size_x * cocking_ghosts_count# pozicija se zamakne za celico
	new_pixel_ghost.global_position -= cocking_direction * cell_size_x/2
	
	new_pixel_ghost.direction = cocking_direction
	
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
		
		# sprazni ghoste
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
	
	
# SKILLS ______________________________________________________________________________________________________________


func push(push_direction):
	
	# se dotika nečesa v smeri?	
	if not detect_collision_in_direction(push_direction) or skill_activated: # preverjam obstoj kolizijo s pixlom ... if collision_ray.is_colliding(): .. ne rabim
		return
		
	var ray_collider = collision_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
	var backup_direction = - push_direction
	
	# se dotika pixla v smeri?
	if not ray_collider.is_in_group(Config.group_pixels):
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
	
	if not ray_collider.is_in_group(Config.group_pixels):
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


func teleport(teleport_direction):
	
	# preverim če kolajda s steno
	if not detect_collision_in_direction(teleport_direction) or skill_activated:
		return	
	if collision_ray.get_collider().is_in_group(Config.group_pixels):
		return
	skill_activated = true
	
	# spawn ghost
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.direction = teleport_direction
	new_pixel_ghost.max_speed = ghost_max_speed
	new_pixel_ghost.modulate = state_colors[current_state]
	new_pixel_ghost.floor_cells = floor_cells
	new_pixel_ghost.cell_size_x = cell_size_x
	Global.node_creation_parent.add_child(new_pixel_ghost)
	new_pixel_ghost.connect("ghost_target_reached", self, "_on_ghost_target_reached")
	
		
	# camera target
	Global.camera_target = new_pixel_ghost
	
	# zaključek v signalu _on_ghost_target_reached

	
# COLLISIONS __________________________________________________________________________________________________________


func die():
#	emit_signal("stat_changed", "black_pixels", 1) 
	
	emit_signal("stat_changed", self, "pixels_in_game", -1)
	print("KVEFRI")
	animation_player.play("die") # kvefrija se v animaciji
#	queue_free()


# UTIL ________________________________________________________________________________________________________________


func random_blink():

	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	return random_animation_name
	

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
	
	detect_area.monitoring = false
	
	new_tween = get_tree().create_tween()
	
	new_tween.tween_property(self, "modulate:a", 0, ghost_fade_time)
	new_tween.tween_property(self, "global_position", ghost_position, 0.1)
	# camera follow reset
	new_tween.tween_property(Global, "camera_target", self, 0.1)
	new_tween.tween_callback(self, "_change_state", [States.WHITE])
	new_tween.parallel().tween_callback(self, "snap_to_nearest_grid")
	new_tween.parallel().tween_callback(ghost_body, "fade_out")


func _on_ghost_detected_body(body):
	
	if body != self:
		cocking_room = false


func _on_DetectArea_body_entered(body: Node) -> void:
	
		
	# pobiranje  barv 
	if skill_activated: # če ni tega, se že na začetku izvede ... lahko bolje
		speed = 0 # more bit tukaj pred _change state, če ne uničuje tudi sam sebe
		cocking_room = true
		burst_activated = false
		_change_state(States.WHITE)
		snap_to_nearest_grid()
		
#		if body.is_in_group(Config.group_tilemap):
			
		#žrebam animacijo
#		var random_animation_index = randi() % 3 + 1
#		var random_animation_name: String = "glitch_%s" % random_animation_index
#		animation_player.play(random_animation_name)
		
		# animiram glow
		
		if body.is_in_group(Config.group_pixels):
			
			# pobrana barva pixla
			var picked_color = body.modulate
			 
			# skupna barva
			pixel_color_sum = pixel_color + picked_color
				
			pixel_color = picked_color
			Global.hud.new_picked_color = picked_color
			
			var glow_adon: float = 0.5
			print(pixel_color)
			new_tween = get_tree().create_tween()
			new_tween.tween_property(self, "pixel_color.r", pixel_color.r + glow_adon, 1)
			new_tween.paralell().tween_property(self, "pixel_color.g", pixel_color.g + glow_adon, 1)
			new_tween.paralell().tween_property(self, "pixel_color.b", pixel_color.b + glow_adon, 1)
			pixel_color = Color(pixel_color.r + glow_adon, pixel_color.g + glow_adon, pixel_color.b + glow_adon)
			print(pixel_color)
			
		
			# stray disabled
			body.die()
