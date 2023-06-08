class_name Pixel
extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change)

var skill_change_count: int = 0

var pixel_color: Color = Config.color_white

# motion
var speed: float = 0
var velocity: Vector2
var direction = Vector2.ZERO
#var collision: KinematicCollision2D
	
# steps
export(int, 1, 10)  var death_mode_frame_skip = 2
export(int, 1, 10) var slide_frame_skip: int = 4 # za kontrolo hitrosti
#var frame_counter: int # pseudo time 
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
var ghost_cocking_time: float = 0 # trenuten čas nastajanja cocking ghosta
var ghost_cocking_time_limit: float = 0.2 # max čas nastajanja cocking ghosta (tudi animacija)
var cocked_ghost_fill_time: float = 0.05 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
var cocked_ghosts: Array
var cocked_ghost_count_max: int = 5

# burst release
var speed_burst_max: float = 0
var speed_cock_ghost_ad: float = 7
var strech_ghost_shrink_time: float = 0.2

# arena
var cell_size_x: int # pogreba od arene, ki jo dobi od tilemapa
onready var floor_cells: Array = Global.game_manager.available_positions

var new_tween: SceneTreeTween
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var front_ray: RayCast2D = $FrontRay
#onready var rear_ray: RayCast2D = $RearRay

var pixel_color_sum: Color # suma barv za picla

onready var detect_area: Area2D = $DetectArea

onready var PixelGhost = preload("res://scenes/PixelGhost.tscn")

var step_speed = 0.15

# stanja
export var pixel_is_player: = false # tukaj setam al ma kontrole al ne
#var skill_in_progress: bool = false # ob štartu skill kontrol ... deaktivacija na end_move
var step_in_progress = false

#var move_activated: bool = false
var cocking_room: bool = true
#var burst_on = false
var burst_in_progress: bool = false # zaenkrat nič ne vpliva	# _temp za bug
var burst_direction_set: bool = false


var collision_detected = false
var colliding_with_tilemap = false
var colliding_with_pixel = false

enum States {IDLE, STEPPING, SKILLED, BURSTING}
var current_state = States.IDLE



func _ready() -> void:
	
	randomize()
	
	Global.print_id(self)
	
#	# zabeleži rojstvo in naj VSI pomembni vejo
#	emit_signal("stat_changed", self, "player_active", true)
#	...  po novem ob spawnanju iz GMja
#	print (name, " se je rodil na: ", global_position)
	
	# snap it
	cell_size_x = 32 #Global.game_manager.grid_cell_size.x # get cell size ... če je tole noče delat sama
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
	
	if pixel_is_player:	
		
		match current_state:
			States.IDLE: regular_inputs()
			States.STEPPING: pass
			States.SKILLED: pass #skill_inputs()
			States.BURSTING: 
				burst_inputs()
				velocity = direction * speed # dokler je speed 0, je velocity tudi 0 v tweenih speed se regulira v tweenu 
				move_and_collide(velocity) 
			
		printt("current_state", current_state)
		
	else:
#		rear_ray.cast_to = front_ray.cast_to
		front_ray.cast_to = Vector2.ZERO
		
func regular_inputs():
		
	if Input.is_action_pressed("ui_up"):
		direction = Vector2.UP
		step(direction)
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2.DOWN
		step(direction)
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2.LEFT
		step(direction)
	elif Input.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT
		step(direction)
			
	if Input.is_action_just_pressed("space"):
		current_state = States.BURSTING


func burst_inputs():

	if Input.is_action_pressed("ui_up"):
		if not burst_direction_set:
			direction = Vector2.DOWN
			burst_direction_set = true
		else:
			cock_burst(direction)
	elif Input.is_action_pressed("ui_down"):
		if not burst_direction_set:
			direction = Vector2.UP
			burst_direction_set = true
		else:
			cock_burst(direction)
	elif Input.is_action_pressed("ui_left"):
		if not burst_direction_set:
			direction = Vector2.RIGHT
			burst_direction_set = true
		else:
			cock_burst(direction)
	elif Input.is_action_pressed("ui_right"):
		if not burst_direction_set:
			direction = Vector2.LEFT
			burst_direction_set = true
		else:
			cock_burst(direction)
			
	if Input.is_action_just_released("space"):
		if burst_direction_set:
			release_burst(direction)
		else:
			end_move()
	
#func skill_inputs():
#
##	if not skill_in_progress:
##		if Input.is_action_just_pressed("ui_up"):
##			direction = Vector2.UP
##		if Input.is_action_just_pressed("ui_down"):
##			direction = Vector2.DOWN
##		if Input.is_action_just_pressed("ui_left"):
##			direction = Vector2.LEFT
##		if Input.is_action_just_pressed("ui_right"):
##			direction = Vector2.RIGHT
#
#
#	if Input.is_action_pressed("space"):
#		burst_activated = true
#		skill_in_progress = true
#		burst_control()
#	if Input.is_action_just_released("space"):
#		skill_in_progress = false
#		burst_activated = false			


func end_move():
	
	current_state = States.IDLE
	
	burst_direction_set = false
	speed = 0 # more bit tukaj pred _change state, če ne uničuje tudi sam sebe
	
	detect_area.monitoring = true # of jo da teleport
	
	# reset direction
#	direction = Vector2.ZERO
	modulate = pixel_color
	snap_to_nearest_grid()
	
	# reset ray dir
	front_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
	front_ray.force_raycast_update()	

	# za hud
	skill_change_count += 1
	emit_signal("stat_changed", self, "skill_change_count", 1)
	

# STEPS ______________________________________________________________________________________________________________


func step(step_direction):
	
#	if not move_activated:
		
		# če kolajda izbrani smeri gibanja
		if detect_collision_in_direction(front_ray, direction): 
			
#			collision_detected =  true
			var collider: Object = detect_collision_in_direction(front_ray, direction)

##			move_activated = true
#			if collider.is_in_group(Config.group_tilemap):
#				colliding_with_tilemap = true 
#				colliding_with_pixel = false
#			elif collider.is_in_group(Config.group_pixels):
#				colliding_with_pixel = true
#				colliding_with_tilemap = false

#			return
#			move_activated = true
			if collider.is_in_group(Config.group_tilemap):
				teleport(direction)
			elif collider.is_in_group(Config.group_pixels):
				push(direction)
		
#		elif detect_collision_in_direction(rear_ray, direction): 
#			var collider: Object = detect_collision_in_direction(rear_ray, direction)
#			if collider.is_in_group(Config.group_pixels):
#				pull(direction)
				
		else: # če ni stena naredi korak
			snap_to_nearest_grid()
#			step_in_progress = true
			current_state = States.STEPPING
#			skill_activated = true
			
			new_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
			new_tween.tween_property(self, "position", global_position + direction * cell_size_x, step_speed)
			new_tween.tween_callback(self, "snap_to_nearest_grid")
			new_tween.tween_callback(self, "end_move")
		
#		front_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
#		front_ray.force_raycast_update()
		

		# pošljem signal, da odštejem točko
		emit_signal("stat_changed", self, "cells_travelled", 1)


func pull(target_direction):
	# ray je usmerjen v smer 
	# če je tam tarča, spelje step()
	# če je prostor (preverja c stepu) se premakne stran od tarče
	# tarčina pozicija sledi pixlu
	# če je s se premakne v smer stran od nje
	
	# preverjam obstoj kolizijo s pixlom ... if collision_ray.is_colliding(): .. ne rabim
	var skill_in_progress 
	if not detect_collision_in_direction(front_ray, target_direction) or skill_in_progress: 
		return	
	skill_in_progress = true

	var pull_direction = - target_direction
	var ray_collider = front_ray.get_collider()

	if not ray_collider.is_in_group(Config.group_pixels):
		return

	# spawn ghost pod mano
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.modulate = pixel_color
	Global.node_creation_parent.add_child(new_pixel_ghost)

	new_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	new_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	new_tween.tween_property(ray_collider, "position", ray_collider.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	new_tween.parallel().tween_property(new_pixel_ghost, "position", new_pixel_ghost.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	new_tween.tween_callback(self, "finish_move")
	new_tween.parallel().tween_callback(new_pixel_ghost, "queue_free")


	skill_in_progress = false
	

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
	


# BURST ______________________________________________________________________________________________________________



func cock_burst(burst_direction):

	var cock_direction = - burst_direction
	
	# prostor za začetek napenjanja preverja pixel
	if detect_collision_in_direction(front_ray, cock_direction): 
		end_move() 
		return	# dobra praksa ... zazih
		
	# prostor nadaljevanje napenjanja preverja ghost
	if cocked_ghosts.size() < cocked_ghost_count_max and cocking_room:
			
			# čas držanja tipke (znotraj nastajanja ene cock celice)
			ghost_cocking_time += 1 / 60.0 # fejk delta
			
			# ko poteče čas za eno celico mimo, jo spawnam
			if ghost_cocking_time > ghost_cocking_time_limit:
				
				ghost_cocking_time = 0
				
				# prištejem hitrost bursta
				speed_burst_max += speed_cock_ghost_ad
				# spawnaj cock celico
				spawn_cock_ghost(cock_direction, cocked_ghosts.size() + 1) # + 1 zato, da se prvi ne spawna direktno nad pixlom
	
	
func spawn_cock_ghost(cocking_direction, cocked_ghosts_count):
	
	# instance ghost pod mano
	var new_pixel_ghost = PixelGhost.instance()
	
	# ghost je trenutne barve pixla
	new_pixel_ghost.modulate = modulate
	# z vsakim naj bo bolj prosojen (relativno z max številom celic)
	new_pixel_ghost.modulate.a = 1.0 - (cocked_ghosts_count / float(cocked_ghost_count_max + 1))
	# z vsakim se zamika pozicija
	new_pixel_ghost.global_position = global_position + cocking_direction * cell_size_x * cocked_ghosts_count# pozicija se zamakne za celico
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
	new_tween.tween_property(new_pixel_ghost, "scale", Vector2.ONE, ghost_cocking_time_limit).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	new_tween.parallel().tween_property(new_pixel_ghost, "position", global_position + cocking_direction * cell_size_x * cocked_ghosts_count, ghost_cocking_time_limit).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# ray detect velikost je velikost napenjanja
	new_pixel_ghost.ghost_ray.cast_to = direction * cell_size_x
	new_pixel_ghost.connect("ghost_detected_body", self, "_on_ghost_detected_body")
	
	# dodam celico v array celic tega zaleta
	cocked_ghosts.append(new_pixel_ghost)


func release_burst(burst_direction):
	
	for ghost in cocked_ghosts:
		new_tween = get_tree().create_tween()
		new_tween.tween_property(ghost, "modulate:a", 1, cocked_ghost_fill_time)
		yield(get_tree().create_timer(cocked_ghost_fill_time),"timeout")
	
	burst(burst_direction, cocked_ghosts.size())
		
		
func burst(burst_direction, ghosts_count):
	
	# laser preverja kolizije za toliko enot kolikor je bil burst napet		
#		detect_collision_in_direction(burst_direction * ghosts_count)
		
	var ray_collider = front_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
	var backup_direction = - burst_direction

	# spawn stretch ghost
	var new_stretch_ghost = PixelGhost.instance()
	new_stretch_ghost.global_position = global_position
	new_stretch_ghost.modulate = pixel_color
	Global.node_creation_parent.add_child(new_stretch_ghost)
	
	# vertikalno ali horizontalno?
	if burst_direction.y == 0: # če je smer horiz
		new_stretch_ghost.scale = Vector2(ghosts_count, 1)
	elif burst_direction.x == 0: # če je smer ver
		new_stretch_ghost.scale = Vector2(1, ghosts_count)
	
	# strech ghost 
	new_stretch_ghost.position = global_position - (burst_direction * cell_size_x * ghosts_count)/2 - burst_direction * cell_size_x/2
	
	# sprazni ghoste
	for ghost in cocked_ghosts:
		ghost.queue_free()
	cocked_ghosts = []
	
	# release ghost 
	new_tween = get_tree().create_tween()
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
	
	var ray_collider = front_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
	var backup_direction = - push_direction
	
	# ima prostor za zalet?
	if detect_collision_in_direction(front_ray, backup_direction):
		return
	
	current_state = States.SKILLED
		
	# spawn ghost pod mano
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.modulate = pixel_color
	Global.node_creation_parent.add_child(new_pixel_ghost)

	# napnem
	new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
	# spustim
	new_tween.tween_property(self, "position", global_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
	new_tween.tween_property(ray_collider, "position", ray_collider.global_position + push_direction * cell_size_x * push_cell_count, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	new_tween.tween_callback(self, "end_move")
	new_tween.parallel().tween_callback(new_pixel_ghost, "queue_free")
		

func teleport(teleport_direction):
	
	current_state = States.SKILLED
	
	# spawn ghost
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.direction = teleport_direction
	new_pixel_ghost.max_speed = ghost_max_speed
	new_pixel_ghost.modulate = pixel_color
	new_pixel_ghost.modulate.a = 0.5
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
	pass


# UTIL ________________________________________________________________________________________________________________


func detect_collision_in_direction(ray, direction_to_check):
	
	ray.cast_to = direction_to_check * cell_size_x # ray kaže na naslednjo pozicijo 
	ray.force_raycast_update()	
	
	if ray.is_colliding():
		var ray_collider = ray.get_collider()
		return ray_collider


func random_blink():

	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	return random_animation_name
	

func reset_direction():
	direction = Vector2.ZERO
	front_ray.cast_to = direction * cell_size_x 


func snap_to_nearest_grid():
	
	var current_position = Vector2(global_position.x - cell_size_x/2, global_position.y - cell_size_x/2)
	
	# če ni že snepano
	if not floor_cells.has(current_position): 
		# določimo distanco znotraj katere preverjamo bližino točke
		var distance_to_position: float = cell_size_x # začetna distanca je velikosti celice, ker na koncu je itak bližja
		var nearest_cell: Vector2
		for cell in floor_cells:
			if cell.distance_to(current_position) < distance_to_position:
				distance_to_position = cell.distance_to(current_position)
				nearest_cell = cell
		
		# snap it
		global_position = Vector2(nearest_cell.x + cell_size_x/2, nearest_cell.y + cell_size_x/2)
		
	
# SIGNALI ______________________________________________________________________________________________________________

		
func _on_ghost_target_reached(ghost_body, ghost_position):
	
	detect_area.monitoring = false
	
	new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "modulate:a", 0, ghost_fade_time)
	new_tween.tween_property(self, "global_position", ghost_position, 0.01)
	
	# camera follow reset
	new_tween.parallel().tween_property(Global, "camera_target", self, 0.01)
	new_tween.parallel().tween_callback(self, "snap_to_nearest_grid") # zaenkrat v end skill
	new_tween.tween_property(self, "modulate:a", 1, ghost_fade_time)
	new_tween.tween_callback(ghost_body, "fade_out")
	new_tween.tween_callback(self, "end_move")
	

func _on_ghost_detected_body(body):
	
	if body != self:
		cocking_room = false


func _on_DetectArea_body_entered(body: Node) -> void:
		
	# pobiranje  barv 
	if current_state == States.BURSTING: # če ni tega, se že na začetku akcija izvede in je error
		cocking_room = true
		end_move()
		
		# poškodba
		if body.is_in_group(Config.group_tilemap):
			# žrebam animacijo
			var random_animation_index = randi() % 3 + 1
			var random_animation_name: String = "glitch_%s" % random_animation_index
			animation_player.play(random_animation_name)
		
		# glow-up
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
			new_tween.parallel().tween_property(self, "pixel_color.g", pixel_color.g + glow_adon, 1)
			new_tween.parallel().tween_property(self, "pixel_color.b", pixel_color.b + glow_adon, 1)
#			pixel_color = Color(pixel_color.r + glow_adon, pixel_color.g + glow_adon, pixel_color.b + glow_adon)
			print(pixel_color)
		
			# stray disabled
			body.die()
