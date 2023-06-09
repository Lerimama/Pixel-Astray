class_name Pixel
extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change)

export var pixel_is_player: = false # tukaj setam al ma kontrole al ne

enum States {IDLE, STEPPING, SKILLED, BURSTING}
var current_state = States.IDLE
var pixel_color: Color

# steping
var direction = Vector2.ZERO
var step_speed = 0.15
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

# cocking
var cocked_ghosts: Array
var cocking_room: bool = true
var cocked_ghost_count_max: int = 32
var ghost_cocking_time: float = 0 # trenuten čas nastajanja cocking ghosta
var ghost_cocking_time_limit: float = 0.2 # max čas nastajanja cocking ghosta (tudi animacija)
var cocked_ghost_fill_time: float = 0.05 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
var cocked_ghost_alpha: float = 0.6
var cocked_ghost_alpha_factor: float = 14

# bursting
var burst_speed: float = 0
var burst_speed_max: float = 0 # maximalna hitrost v tweenu
var burst_speed_max_addon: float = 7
var strech_ghost_shrink_time: float = 0.2
var burst_direction_set: bool = false

# stats
var skill_change_count: int = 0
var step_cell_count: int = 1 # je naslednja


var new_tween: SceneTreeTween
onready var cell_size_x: int = Global.level_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var front_ray: RayCast2D = $FrontRay
#onready var detect_area: Area2D = $DetectArea
onready var floor_cells: Array = Global.game_manager.available_floor_positions
onready var collision_shape: CollisionShape2D = $CollisionShape2D

onready var PixelGhost = preload("res://scenes/PixelGhost.tscn")

#_temp
var collision: KinematicCollision2D
var velocity: Vector2
var bounce_size = 0.3
var current_neighbouring_cells: Array = []


func _ready() -> void:
	
	Global.print_id(self)
	
#	# zabeleži rojstvo in naj VSI pomembni vejo
#	emit_signal("stat_changed", self, "player_active", true)
#	...  po novem ob spawnanju iz GMja
#	print (name, " se je rodil na: ", global_position)
	
	modulate = pixel_color
	randomize() # za random die animacije
	snap_to_nearest_grid()


func _physics_process(delta: float) -> void:
	
	if pixel_is_player:	
		
		if detect_collision_in_direction(front_ray, direction): # more bit neodvisno od stateta, da pull dela
			skill_inputs()
		
		match current_state:
			States.IDLE: 
				idle_inputs()
			States.STEPPING: pass
			States.SKILLED: pass
			States.BURSTING: 
				burst_inputs()
#				detect_area.monitoring = false
				velocity = direction * burst_speed
				collision = move_and_collide(velocity) 
				if collision:
					on_collision()
			
		
	else: # če je stray
		# vedno ve kdo so njegovi sosedi
		current_neighbouring_cells = check_for_neighbours()


func on_collision(): # fizka je prisotna samo pri burstanju
	
	# poškodba, če je stena
	if collision.collider.is_in_group(Config.group_tilemap):
		# žrebam animacijo
		var random_animation_index = randi() % 3 + 1
		var random_animation_name: String = "glitch_%s" % random_animation_index
		animation_player.play(random_animation_name)
			
	
	# poberi barvo, če je pixel
	elif collision.collider.is_in_group(Config.group_pixels):
		# return, če je "sosed" mode, in če je sosed določen, in če pobrana barva ni enaka barvi soseda na spektru
#		if Global.game_manager.pick_neighbour_mode:
#			if Global.game_manager.colors_to_pick and not Global.game_manager.colors_to_pick.has(collision.collider.pixel_color):
#				end_move()
#				return


		var all_neighbouring_pixels: Array = []
		var neighbours_checked: Array = []
		
		# prva runda ... naberem sosede pixla v katerega sem se zaletel
		for neighbour in collision.collider.current_neighbouring_cells:
			# trenutne sosede dodam v vse sosede ... če je še ni notri
			if not all_neighbouring_pixels.has(neighbour):
				all_neighbouring_pixels.append(neighbour)
		neighbours_checked.append(collision.collider)
		
		# druga runda ... naberem sosede od pixlov v arrayu vseh sosed (ki še niso med čekiranimi pixli)
		for neighbour_pixel in all_neighbouring_pixels:
			# preverim če sosed ni tudi v "checked" arrayu, preveri in poberi še njegove sosede
			if not neighbours_checked.has(neighbour_pixel):
				# vsak od sosedov soseda se doda v med vse sosede
				for np in neighbour_pixel.current_neighbouring_cells:
					if not all_neighbouring_pixels.has(np):
						all_neighbouring_pixels.append(np)
				# po nabirki ga dodam med preverjene sosede
				neighbours_checked.append(neighbour_pixel)
		
		# efekt na nabrane sosede
		var index = 0
		for a in all_neighbouring_pixels:
			index += 1
			if index == 4:
				break
#			a.modulate.a = 0.2
			a.die()



		# efekt na kolajderjA
		var picked_color = collision.collider.pixel_color
		pixel_color = picked_color
		Global.hud.new_picked_color = picked_color
		collision.collider.die()
		

	end_move()


func check_for_neighbours(): # samo če je stray
	
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbours: Array
	
	for dir in directions_to_check:
		
		if detect_collision_in_direction(front_ray, dir):
			# če je kolajder stray in ni self
			var neighbour = detect_collision_in_direction(front_ray, dir)
			if neighbour.is_in_group(Config.group_pixels) and neighbour != self:
				current_cell_neighbours.append(neighbour)
				
	return current_cell_neighbours # uporaba v stalnem čekiranj sosedov
	
	


func bounce():
		
#	velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
	# odbojni partikli
#	if velocity.length() > 10: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
#		var new_collision_particles = CollisionParticles.instance()
#		new_collision_particles.position = collision.position
#		new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
#		new_collision_particles.amount = (velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič	
#		new_collision_particles.color = player_color
#		new_collision_particles.set_emitting(true)
#		Global.effects_creation_parent.add_child(new_collision_particles)
	pass
		
func idle_inputs():
	
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
			
	if Input.is_action_just_pressed("space"): # brez "just" dela po stisku smeri ... ni ok
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

	
func skill_inputs():
	
	var new_direction # nova smer, deluje samo, če ni enaka smeri kolizije
	
	# s tem inputom prekinem "is_pressed" input
	if Input.is_action_just_pressed("ui_up"):
		new_direction = Vector2.UP
	if Input.is_action_just_pressed("ui_down"):
		new_direction = Vector2.DOWN
	if Input.is_action_just_pressed("ui_left"):
		new_direction = Vector2.LEFT
	if Input.is_action_just_pressed("ui_right"):
		new_direction = Vector2.RIGHT
	
	if current_state != States.SKILLED:
		var collider: Object = detect_collision_in_direction(front_ray, direction)
		if new_direction == direction:
			if collider.is_in_group(Config.group_tilemap):
				teleport(direction)
			elif collider.is_in_group(Config.group_pixels):
				push(direction)	
		if new_direction == - direction:
			if collider.is_in_group(Config.group_pixels):
				pull(direction)	


# STEPS ______________________________________________________________________________________________________________


func step(step_direction):
		
	# če kolajda izbrani smeri gibanja prenesem kontrole na skill
	if not detect_collision_in_direction(front_ray, step_direction):
		snap_to_nearest_grid()
		current_state = States.STEPPING
		new_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		new_tween.tween_property(self, "position", global_position + direction * cell_size_x, step_speed)
		new_tween.tween_callback(self, "snap_to_nearest_grid")
		new_tween.tween_callback(self, "end_move")

		# pošljem signal, da odštejem točko
		emit_signal("stat_changed", self, "cells_travelled", 1)


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


func end_move():
	
	current_state = States.IDLE
	
#	temp
#	front_ray.cast_to = Vector2.ZERO
	
	burst_direction_set = false
	burst_speed = 0 # more bit tukaj pred _change state, če ne uničuje tudi sam sebe
	
#	detect_area.monitoring = true # of jo da teleport
	
	# reset direction
	modulate = pixel_color
	snap_to_nearest_grid()
	
	# reset ray dir
	front_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
	front_ray.force_raycast_update()	

	# za hud
	skill_change_count += 1
	emit_signal("stat_changed", self, "skill_change_count", 1)


func die():
#	emit_signal("stat_changed", "black_pixels", 1) 
	
	emit_signal("stat_changed", self, "pixels_in_game", -1)
	print("KVEFRI")
	animation_player.play("die") # kvefrija se v animaciji
#	queue_free()
	pass


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
				burst_speed_max += burst_speed_max_addon
				# spawnaj cock celico
				spawn_cock_ghost(cock_direction, cocked_ghosts.size() + 1) # + 1 zato, da se prvi ne spawna direktno nad pixlom
	
	
func spawn_cock_ghost(cocking_direction, cocked_ghosts_count):
	
	# instance ghost pod mano
	var new_pixel_ghost = PixelGhost.instance()
	
	# ghost je trenutne barve pixla
	new_pixel_ghost.modulate = modulate
	
	# z vsakim naj bo bolj prosojen (relativno z max številom celic)
	new_pixel_ghost.modulate.a = cocked_ghost_alpha - (cocked_ghosts_count / cocked_ghost_alpha_factor)
	# new_pixel_ghost.modulate.a = 1.0 - (cocked_ghosts_count / float(cocked_ghost_count_max + 1)) ... glede na max moč 
	
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
	
	var burts_power = ghosts_count
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
	new_tween.parallel().tween_property(self, "burst_speed", burst_speed_max, 0.01).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	# resetiram max spid
	burst_speed_max = 0
	cocking_room = true
	
	# zaključek v signalu _on_DetectArea_body_entered
	
	
# SKILLS ______________________________________________________________________________________________________________
		
		
func push(push_direction):
	
	var backup_direction = - push_direction
	var ray_collider = front_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
	
	# je prostor za zalet?
	if detect_collision_in_direction(front_ray, backup_direction):
		return
	# je pred kolajderjem prostor?
	if ray_collider.has_method("detect_collision_in_direction"):
		if ray_collider.detect_collision_in_direction(ray_collider.front_ray, push_direction):
			push_direction = Vector2.ZERO # če ni prostora se izvede po sizifovo
	
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


func pull(target_direction):
	
	var pull_direction = - target_direction
	var target_pixel = front_ray.get_collider()
	
	# preverjam če ma prostor v smeri premika
	if detect_collision_in_direction(front_ray, pull_direction): 
		return	
		
	current_state = States.SKILLED

	# spawn ghosta pod mano
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.modulate = pixel_color
	Global.node_creation_parent.add_child(new_pixel_ghost)

	new_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	new_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	new_tween.tween_property(target_pixel, "position", target_pixel.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	new_tween.parallel().tween_property(new_pixel_ghost, "position", new_pixel_ghost.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
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
	
#	detect_area.monitoring = false
	
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


func _on_DetectArea_body_entered(body: Node) -> void: # konec bursta
#
#	if current_state == States.BURSTING: # če ni tega, se že na začetku akcija izvede in je error
#
#		# poškodba, če je stena
#		if body.is_in_group(Config.group_tilemap):
#			# žrebam animacijo
#			var random_animation_index = randi() % 3 + 1
#			var random_animation_name: String = "glitch_%s" % random_animation_index
#			animation_player.play(random_animation_name)
#			print("detected ", body)
#
#		# poberi barvo, če je pixel
#		elif body.is_in_group(Config.group_pixels):
#
#			# return, če je "sosed" mode, in če je sosed določen, in če pobrana barva ni enaka barvi soseda na spektru
#			if Global.game_manager.pick_neighbour_mode:
#				if Global.game_manager.colors_to_pick and not Global.game_manager.colors_to_pick.has(body.pixel_color):
#					end_move()
#					return
#
#			var picked_color = body.pixel_color
#			pixel_color = picked_color
#			Global.hud.new_picked_color = picked_color
#			body.die()
#
#			print("detected ", body)
#		end_move() # more bit na koncu, da upošteva novo barvo pixla
	pass
