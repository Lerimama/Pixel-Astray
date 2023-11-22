extends KinematicBody2D


signal stat_changed (stat_owner, event, stat_change)

enum States {IDLE, STEPPING, SKILLING, COCKING, RELEASING, BURSTING}
var current_state # = States.IDLE

var direction = Vector2.ZERO # prenosna
var collision: KinematicCollision2D
var step_time: float # uporabi se pri step tweenu in je nekonstanten, če je "energy_speed_mode"

# push & pull
var pull_time: float = 0.3
var pull_cell_count: int = 1
var push_time: float = 0.3
var push_cell_count: int = 1

# teleport
var ghost_fade_time: float = 0.2
var backup_time: float = 0.32
var ghost_max_speed: float = 10

# cocking
var cocked_ghosts: Array
var cocking_room: bool = true
var cocked_ghost_count_max: int = 7
var cocked_ghost_alpha: float = 0.55 # najnižji alfa za ghoste
var cocked_ghost_alpha_divisor: float = 14 # faktor nižanja po zaporedju (manjši je bolj oster
var ghost_cocking_time: float = 0 # trenuten čas nastajanja cocking ghosta
var ghost_cocking_time_limit: float = 0.12 # max čas nastajanja cocking ghosta (tudi animacija)
var cocked_ghost_fill_time: float = 0.04 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
var cocked_pause_time: float = 0.05 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)

# bursting
var burst_speed: float = 0 # glavna (trenutna) hitrost
var burst_speed_max: float = 0 # maximalna hitrost v tweenu (določena med kokanjem)
var burst_speed_addon: float = 12
var strech_ghost_shrink_time: float = 0.2
var burst_direction_set: bool = false
var burst_power: int # moč v številu ghosts_count
var burst_velocity: Vector2

# shaking camera
var burst_power_shake_addon: float = 0.03
var hit_wall_shake_power: float = 0.25
var hit_wall_shake_time: float = 0.5
var hit_wall_shake_decay: float = 0.2
var hit_stray_shake_power: float = 0.2
var hit_stray_shake_time: float = 0.3
var hit_stray_shake_decay: float = 0.7
var die_shake_power: float = 0.2
var die_shake_time: float = 0.7
var die_shake_decay: float = 0.1

# energija in hitrost
var current_player_energy_part: float # za uravnavanje step zvoka
var player_energy: float # player jo pozna samo zaradi spreminjanja obnašanja ... = Global.game_manager.player_stats["player_energy"]
var max_player_energy: float = Global.game_manager.game_settings["player_start_energy"]
var step_time_slow: float = Global.game_manager.game_settings["step_time_slow"]
var step_time_fast: float = Global.game_manager.game_settings["step_time_fast"]
var slowdown_rate: int = Global.game_manager.game_settings["slowdown_rate"] # višja je, počasneje se manjša

# dihanje
var last_breath_active: bool = false 
var last_breath_loop: int = 0
var last_breath_loop_limit: int = 5

# transparenca energije
var skill_sfx_playing: bool = false # da lahko kličem is procesne funkcije
onready var poly_pixel: Polygon2D = $PolyPixel

var pixel_color: Color
onready var cell_size_x: int = Global.game_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay
onready var floor_cells: Array = Global.game_manager.floor_positions
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var Ghost: PackedScene = preload("res://game/pixel/ghost.tscn")
onready var PixelCollisionParticles: PackedScene = preload("res://game/pixel/pixel_collision_particles.tscn")
onready var PixelDizzyParticles: PackedScene = preload("res://game/pixel/pixel_dizzy_particles.tscn")
onready var light_2d: Light2D = $Light2D

# new
var key_left: String
var key_right: String
var key_up: String
var key_down: String
var key_burst: String
var player_camera: Node

func _ready() -> void:
	
	randomize() # za random blink animacije
	add_to_group(Global.group_players)

	# controls setup
	if Global.game_manager.game_data["game"] == Profiles.Games.DUEL:
		key_left = "%s_left" % name
		key_right = "%s_right" % name
		key_up = "%s_up" % name
		key_down = "%s_down" % name
		key_burst = "%s_burst" % name
	else:
		key_left = "ui_left"
		key_right = "ui_right"
		key_up = "ui_up"
		key_down = "ui_down"
		key_burst = "space"
	
	light_2d.enabled = false
	modulate = pixel_color # pixel_color je določen ob spawnu z GM
	current_state = States.IDLE
	
	# global_position = Global.snap_to_nearest_grid(global_position, Global.game_tilemap.floor_cells_global_positions)
	
	
func _physics_process(delta: float) -> void:
	
	current_player_energy_part = player_energy / max_player_energy # delež celotne energije
			
	if Global.detect_collision_in_direction(vision_ray, direction): # more bit neodvisno od stateta, da pull dela
		skill_inputs()
	
	last_breath()
	state_machine()
	
		 
func state_machine():
	
	match current_state:
		States.IDLE:
			# skilled
			if Global.detect_collision_in_direction(vision_ray, direction) and player_energy > 1: # koda je tukaj, da ne blinkne ob kontaktu s sosedo
				animation_player.stop() # stop dihanje
				light_on()
				if Global.detect_collision_in_direction(vision_ray, direction).is_in_group(Global.group_strays):
					emit_signal("stat_changed", self, "skilled",1) # signal, da je skilled (kaj se zgodi je na GMju)
					if not skill_sfx_playing and Global.game_manager.game_settings["skilled_energy_drain_mode"]: # to je zato da FP ne klie na vsak frejm
						Global.sound_manager.play_sfx("skilled")
						skill_sfx_playing = true
			else: # not skilled
				if skill_sfx_playing: # da FP ne kliče na vsak frejm
					Global.sound_manager.stop_sfx("skilled")
					skill_sfx_playing = false
			# toggle energy_speed_mode
			if Global.game_manager.game_settings["slowdown_mode"]:
				var slow_trim_size: float = step_time_slow * max_player_energy
				var energy_factor: float = (max_player_energy - slow_trim_size) / player_energy
				var energy_step_time = energy_factor / slowdown_rate # variabla, da FP ne kliče na vsak frejm
				step_time = clamp(energy_step_time, step_time_fast, step_time_slow) # omejim najbolj počasno korakanje
			else:
				step_time = step_time_fast
			idle_inputs()
		States.STEPPING:
			pass
		States.SKILLING: # stanje ko se skill izvaja
			animation_player.stop() # stop dihanje
		States.COCKING: 
			animation_player.stop() # stop dihanje
			cocking_inputs()
		States.RELEASING:
			pass
		States.BURSTING:
			burst_velocity = direction * burst_speed
			collision = move_and_collide(burst_velocity) 
			if collision:
				on_collision()
			bursting_inputs()

	
func on_collision(): 
	
	spawn_collision_particles()
	Global.sound_manager.stop_sfx("burst")
	
	# shake calc
	var added_shake_power = hit_stray_shake_power + burst_power_shake_addon * burst_power
	var added_shake_time = hit_stray_shake_time + burst_power_shake_addon * burst_power
	
	if collision.collider.is_in_group(Global.group_tilemap):
		# efekti
		Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
		Global.sound_manager.play_sfx("hit_wall")
		player_camera.shake_camera(added_shake_power, added_shake_time, hit_stray_shake_decay)
		spawn_dizzy_particles()
		# posledice
		emit_signal("stat_changed", self, "hit_wall", 1)
		die()
		end_move()
		
	elif collision.collider.is_in_group(Global.group_strays):
		# efekti
		Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
		Global.sound_manager.play_sfx("hit_stray")	
		player_camera.shake_camera(added_shake_power, added_shake_time, hit_stray_shake_decay)
		# posledice
		on_hit_stray(collision.collider)
		end_move()
	
	elif collision.collider.is_in_group(Global.group_players):
		
		var hit_player: KinematicBody2D = collision.collider
		var hit_player_direction = hit_player.direction # za korekcijo
		# zmaga
		if burst_speed > hit_player.burst_speed:
			# efekti
			Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
			Global.sound_manager.play_sfx("hit_stray")	
			player_camera.shake_camera(added_shake_power, added_shake_time, hit_stray_shake_decay)
			# posledice
			if hit_player.pixel_color != Global.game_manager.game_settings["player_start_color"]: 
				pixel_color = hit_player.pixel_color # prevzamem barvo
				emit_signal("stat_changed", self, "hit_player", 1) # vzamem mu pobrane barve
			hit_player.on_get_hit(added_shake_power, added_shake_time)
			
			end_move()
			hit_player.end_move() # plejer, ki prvi zazna kontakt ukaže naprej, da je zaporedje pod kontrolo 
		# neodločeno
		elif burst_speed_max == hit_player.burst_speed:
			Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
			Global.sound_manager.play_sfx("hit_stray")
			player_camera.shake_camera(added_shake_power, added_shake_time, hit_stray_shake_decay)
			
			end_move()
			hit_player.end_move() # plejer, ki prvi zazna kontakt ukaže naprej, da je zaporedje pod kontrolo 
		# korekcija, če končata na isti poziciji 	
		if global_position == hit_player.global_position:
			printt ("končala sta na isti poziciji > ", global_position, hit_player.global_position)
			hit_player.global_position = hit_player.global_position + (cell_size_x * (-hit_player_direction))
			printt ("premik zadetega za polje nazaj > ", global_position, hit_player.global_position)

				
func stop_on_hit():
	
	burst_speed = 0
	printt("pozicija pred > ", global_position, burst_speed)
	global_position = Global.snap_to_nearest_grid(global_position, Global.game_tilemap.floor_cells_global_positions)
	printt("pozicija > ", global_position, burst_speed)
	
	current_state = States.IDLE
	modulate = pixel_color

		
func end_move():
	
	# orig zaporedje
	# current_state = States.IDLE
#	global_position = Global.snap_to_nearest_grid(global_position, Global.game_tilemap.floor_cells_global_positions) 
	
	# reset burst
	burst_speed = 0 # more bit tukaj pred _change state, če ne uničuje tudi sam sebe ... trenutno ni treba?
	burst_speed_max = 0
	burst_direction_set = false
	cocking_room = true
	
	if light_2d.enabled:
		light_off()
	
	modulate = pixel_color
	last_breath_active = false # če je burst v steno se ponovno začne
	direction = Vector2.ZERO # reset ray dir
	
	global_position = Global.snap_to_nearest_grid(global_position, Global.game_tilemap.floor_cells_global_positions) 
	
	current_state = States.IDLE


func on_get_hit(added_shake_power, added_shake_time):
	
	# efekti
	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	player_camera.shake_camera(added_shake_power, added_shake_time, hit_stray_shake_decay)	
	spawn_dizzy_particles()

	# uničim morebitno napenjanje
	if burst_speed_max > 0: 
		burst_speed_max = 0
		for ghost in cocked_ghosts:
			var fade_out = get_tree().create_tween()
			fade_out.tween_property(ghost.poly_pixel, "modulate:a", 0, 0.2)
			fade_out.tween_callback(ghost, "queue_free")
		cocked_ghosts = []
				
	# stats				
	Global.game_manager.game_settings["player_start_color"] = Color("#545454") # _temp
	pixel_color = Global.game_manager.game_settings["player_start_color"] # postane začetne barve
	emit_signal("stat_changed", self, "hit_by_player", 1)
	die()


# INPUTS ------------------------------------------------------------------------------------------


func idle_inputs():
	
	if Input.is_action_pressed(key_up) and player_energy > 1: # ne koraka z 1 energijo
		direction = Vector2.UP
		step()
	elif Input.is_action_pressed(key_down) and player_energy > 1:
		direction = Vector2.DOWN
		step()
	elif Input.is_action_pressed(key_left) and player_energy > 1:
		direction = Vector2.LEFT
		step()
	elif Input.is_action_pressed(key_right) and player_energy > 1:
		direction = Vector2.RIGHT
		step()
	
	if Input.is_action_just_pressed(key_burst) and current_state == States.IDLE: # brez "just" dela po stisku smeri ... ni ok
		if Global.game_manager.game_settings["burst_limit_mode"] and Global.game_manager.player_stats["burst_count"] >= Global.game_manager.game_settings["burst_limit_count"]:
			return	
		current_state = States.COCKING
		light_on()
		

func cocking_inputs():
	
	# cocking
	if Input.is_action_pressed(key_up):
		if not burst_direction_set:
			direction = Vector2.DOWN
			burst_direction_set = true
		else:
			cock_burst()
	if Input.is_action_pressed(key_down):
		if not burst_direction_set:
			direction = Vector2.UP
			burst_direction_set = true
		else:
			cock_burst()
	if Input.is_action_pressed(key_left):
		if not burst_direction_set:
			direction = Vector2.RIGHT
			burst_direction_set = true
		else:
			cock_burst()
	if Input.is_action_pressed(key_right):
		if not burst_direction_set:
			direction = Vector2.LEFT
			burst_direction_set = true
		else:
			cock_burst()
	
	# releasing		
	if Input.is_action_just_released(key_burst):
		if not burst_direction_set:
			end_move()
		else:
			release_burst()


func bursting_inputs():
	
	if Input.is_action_just_pressed(key_burst):
		end_move()
		Input.start_joy_vibration(0, 0.6, 0.2, 0.2)
		Global.sound_manager.play_sfx("burst_stop")
		Global.sound_manager.stop_sfx("burst_cocking")	
#		current_state = States.IDLE
		

func skill_inputs():
	
	if Global.game_manager.game_settings["skill_limit_mode"] and Global.game_manager.player_stats["skill_count"] >= Global.game_manager.game_settings["skill_limit_count"]:
		return
	if player_energy <= 1:
		return
		
	var new_direction # nova smer, deluje samo, če ni enaka smeri kolizije
	
	# s tem inputom prekinem "is_pressed" input
	if Input.is_action_just_pressed(key_up):
		new_direction = Vector2.UP
	elif Input.is_action_just_pressed(key_down):
		new_direction = Vector2.DOWN
	elif Input.is_action_just_pressed(key_left):
		new_direction = Vector2.LEFT
	elif Input.is_action_just_pressed(key_right):
		new_direction = Vector2.RIGHT
	
	# select skill, če ga še nima 
	if current_state != States.SKILLING:
		# skill glede na kolajderja 
		var collider: Object = Global.detect_collision_in_direction(vision_ray, direction)
		var wall_tile_index = 3
		if new_direction == direction:
			if collider.is_in_group(Global.group_tilemap):
				var colliding_tile_id = collider.get_collision_tile_id(self, direction) # pošljem self, ker kolajder (tilemap) ima koordinate 0,0
				if colliding_tile_id == wall_tile_index:
					teleport()
			elif collider.is_in_group(Global.group_strays):
				push()	
		if new_direction == - direction:
			if collider.is_in_group(Global.group_strays):
				pull()	

	
# MOVEMENT ------------------------------------------------------------------------------------------


func step():

	var step_direction = direction
	
	# če kolajda izbrani smeri gibanja prenesem kontrole na skill
	if not Global.detect_collision_in_direction(vision_ray, step_direction):
		current_state = States.STEPPING
		global_position = Global.snap_to_nearest_grid(global_position, Global.game_tilemap.floor_cells_global_positions)
		spawn_trail_ghost()
		var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		step_tween.tween_property(self, "position", global_position + direction * cell_size_x, step_time)
		step_tween.tween_callback(self, "end_move")
		Global.sound_manager.play_stepping_sfx(current_player_energy_part)

		# pošljem signal, da odštejem točko
		emit_signal("stat_changed", self, "cells_travelled", 1)


# BURST ------------------------------------------------------------------------------------------


func cock_burst():

	var burst_direction = direction
	var cock_direction = - burst_direction
	
	# prostor za začetek napenjanja preverja pixel
	if Global.detect_collision_in_direction(vision_ray, cock_direction): 
		end_move()
		Global.sound_manager.stop_sfx("burst_cocking")
		return	# dobra praksa ... zazih
		
	# prostor nadaljevanje napenjanja preverja ghost
	if cocked_ghosts.size() < cocked_ghost_count_max and cocking_room:
		# čas držanja tipke (znotraj nastajanja ene cock celice)
		ghost_cocking_time += 1 / 60.0 # fejk delta
		# ko poteče čas za eno celico mimo, jo spawnam
		if ghost_cocking_time > ghost_cocking_time_limit:
			ghost_cocking_time = 0
			# prištejem hitrost bursta
			burst_speed_max += burst_speed_addon
			# spawnaj cock celico
			spawn_cock_ghost(cock_direction, cocked_ghosts.size() + 1) # + 1 zato, da se prvi ne spawna direktno nad pixlom
		Global.sound_manager.play_sfx("burst_cocking")


func release_burst():
	
	if burst_speed_max == 0: # če je vmes zadet
		return
		
	current_state = States.RELEASING
	
	Global.sound_manager.play_sfx("burst_cocked")
	light_off()

	# napeti ghosti animirajo do alfa 1
	for ghost in cocked_ghosts:
		var get_set_tween = get_tree().create_tween()
		get_set_tween.tween_property(ghost.poly_pixel, "modulate:a", 1, cocked_ghost_fill_time)
		yield(get_tree().create_timer(cocked_ghost_fill_time),"timeout")
	# pavza pred strelom	
	yield(get_tree().create_timer(cocked_pause_time), "timeout")
	burst(cocked_ghosts.size())
		

func burst(ghosts_count):
	
	
	emit_signal("stat_changed", self, "burst_released", 1)		
	
	var burst_direction = direction
	burst_power = ghosts_count
	var ray_collider = vision_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
	var backup_direction = - burst_direction

	# spawn stretch ghost
	var new_stretch_ghost = spawn_ghost(global_position)
	
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
	
	Global.sound_manager.play_sfx("burst")
	Global.sound_manager.stop_sfx("burst_cocking")
	
	# release ghost 
	current_state = States.BURSTING
	
	var release_tween = get_tree().create_tween()
	release_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	# release pixel
	release_tween.tween_callback(new_stretch_ghost, "queue_free")
	release_tween.parallel().tween_property(self, "burst_speed", burst_speed_max, 0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	# zaključek .. tudi signal za pobiranje barv ... v on_collision()

	
# SKILLS ------------------------------------------------------------------------------------------

		
func push():
	
			
	var push_direction = direction
	var backup_direction = - push_direction
	var ray_collider = vision_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
	
	# prostor za zalet?
	if Global.detect_collision_in_direction(vision_ray, backup_direction):
		return
	current_state = States.SKILLING
	
	# spawn ghosta pod pixlom
	var new_push_ghost_position = global_position + push_direction * cell_size_x
	var new_push_ghost = spawn_ghost(new_push_ghost_position)
	
	if ray_collider.is_in_group(Global.group_strays):
		# prostor pred kolajderjem?
		if Global.detect_collision_in_direction(ray_collider.vision_ray, push_direction):
			Global.sound_manager.play_sfx("push")
			var empty_push_tween = get_tree().create_tween()
			empty_push_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			empty_push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost.global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			empty_push_tween.tween_property(self, "position", global_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
			empty_push_tween.parallel().tween_callback(self, "light_off")
			empty_push_tween.tween_callback(self, "end_move")
			empty_push_tween.parallel().tween_callback(new_push_ghost, "queue_free")

		else:
			Global.sound_manager.play_sfx("push")
			# napnem
			var push_tween = get_tree().create_tween()
			push_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost.global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			# spustim
			push_tween.tween_property(self, "position", global_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
			push_tween.parallel().tween_callback(self, "light_off")
			push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
			push_tween.tween_callback(Global.sound_manager, "play_sfx", ["pushed"])
			push_tween.parallel().tween_callback(new_push_ghost, "queue_free")
			push_tween.tween_property(ray_collider, "position", ray_collider.global_position + push_direction * cell_size_x * push_cell_count, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.05)
			push_tween.tween_callback(self, "end_move")
			push_tween.tween_callback(Global.sound_manager, "play_sfx", ["skill_success"])
			
		# za hud
		emit_signal("stat_changed", self, "skill_used", 0) # 0 = push, 1 = pull, 2 = teleport ... zaprepoznavanje


func pull():
	
	var target_direction = direction
	var pull_direction = - target_direction
	var target_pixel = vision_ray.get_collider()
	
	# preverjam če ma prostor v smeri premika
	if Global.detect_collision_in_direction(vision_ray, pull_direction): 
		return	
	current_state = States.SKILLING
	
	# spawn ghosta pod mano
	var new_pull_ghost = spawn_ghost(global_position + target_direction * cell_size_x)
	
	Global.sound_manager.play_sfx("pull")
	var pull_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	pull_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.parallel().tween_property(new_pull_ghost, "position", new_pull_ghost.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.tween_property(target_pixel, "position", target_pixel.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.parallel().tween_callback(Global.sound_manager, "play_sfx", ["pulled"])
	pull_tween.parallel().tween_callback(self, "light_off")
	pull_tween.tween_callback(self, "end_move")
	pull_tween.tween_callback(Global.sound_manager, "play_sfx", ["skill_success"])
	pull_tween.parallel().tween_callback(new_pull_ghost, "queue_free")
	
	# za hud
	emit_signal("stat_changed", self, "skill_used", 1) # 0 = push, 1 = pull, 2 = teleport ... zaprepoznavanje
	

func teleport():
		
	var teleport_direction = direction
	
	current_state = States.SKILLING
	
	Input.start_joy_vibration(0, 0.3, 0, 0)
	Global.sound_manager.play_sfx("teleport")
	
	# spawn ghost
	var new_teleport_ghost = spawn_ghost(global_position)
	new_teleport_ghost.direction = teleport_direction
	new_teleport_ghost.max_speed = ghost_max_speed
	new_teleport_ghost.poly_pixel.modulate.a = poly_pixel.modulate.a * 0.5
	new_teleport_ghost.floor_cells = floor_cells
	new_teleport_ghost.cell_size_x = cell_size_x
	new_teleport_ghost.connect("ghost_target_reached", self, "_on_ghost_target_reached")
	
	Global.camera_target = new_teleport_ghost
	
	yield(get_tree().create_timer(0.2), "timeout")
	light_off()
	
	# zaključek v signalu _on_ghost_target_reached
	

# SPAWNING ------------------------------------------------------------------------------------------


func spawn_dizzy_particles():
	
	var new_dizzy_pixels = PixelDizzyParticles.instance()
	new_dizzy_pixels.global_position = global_position
	if pixel_color == Global.game_manager.game_settings["player_start_color"]:
		new_dizzy_pixels.modulate = Global.color_white
	else:
		new_dizzy_pixels.modulate = pixel_color
	Global.node_creation_parent.add_child(new_dizzy_pixels)
	

func spawn_collision_particles():
	
	var new_collision_pixels = PixelCollisionParticles.instance()
	new_collision_pixels.global_position = global_position
	new_collision_pixels.modulate = pixel_color
	match direction:
		Vector2.UP: new_collision_pixels.rotate(deg2rad(-90))
		Vector2.DOWN: new_collision_pixels.rotate(deg2rad(90))
		Vector2.LEFT: new_collision_pixels.rotate(deg2rad(180))
		Vector2.RIGHT:new_collision_pixels.rotate(deg2rad(0))
	Global.node_creation_parent.add_child(new_collision_pixels)
	

func spawn_cock_ghost(cocking_direction, cocked_ghosts_count):
	
	# spawn ghosta pod manom
	var new_cock_ghost = spawn_ghost(global_position + cocking_direction * cell_size_x * cocked_ghosts_count)
	new_cock_ghost.global_position -= cocking_direction * cell_size_x/2
	# alfa ghosta je enaka alfi polipixla
	new_cock_ghost.modulate.a  = poly_pixel.modulate.a
	new_cock_ghost.poly_pixel.modulate.a  = cocked_ghost_alpha - (cocked_ghosts_count / cocked_ghost_alpha_divisor)
	new_cock_ghost.direction = cocking_direction
	
	# v kateri smeri je scale
	if direction.y == 0: # smer horiz
		new_cock_ghost.scale.x = 0
	elif direction.x == 0: # smer ver
		new_cock_ghost.scale.y = 0

	# animiram cell animacijo
	var cock_cell_tween = get_tree().create_tween()
	cock_cell_tween.tween_property(new_cock_ghost, "scale", Vector2.ONE, ghost_cocking_time_limit).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cock_cell_tween.parallel().tween_property(new_cock_ghost, "position", global_position + cocking_direction * cell_size_x * cocked_ghosts_count, ghost_cocking_time_limit).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# ray detect velikost je velikost napenjanja
	new_cock_ghost.ghost_ray.cast_to = direction * cell_size_x
	new_cock_ghost.connect("ghost_detected_body", self, "_on_ghost_detected_body")
	
	# dodam celico v array celic tega zaleta
	cocked_ghosts.append(new_cock_ghost)	


func spawn_trail_ghost():
	
	var trail_alpha: float = 0.2
	var trail_ghost_fade_time: float = 0.4
	var new_trail_ghost = spawn_ghost(global_position)
	new_trail_ghost.modulate.a = trail_alpha
	
	# fadeout
	var trail_fade_tween = get_tree().create_tween()
	trail_fade_tween.tween_property(new_trail_ghost, "modulate:a", 0, trail_ghost_fade_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	trail_fade_tween.tween_callback(new_trail_ghost, "queue_free")
	
	
func spawn_ghost(current_pixel_position):
	
	var new_pixel_ghost = Ghost.instance()
	new_pixel_ghost.global_position = current_pixel_position
	new_pixel_ghost.modulate = pixel_color
	Global.node_creation_parent.add_child(new_pixel_ghost)
	new_pixel_ghost.poly_pixel.modulate.a = poly_pixel.modulate.a

	return new_pixel_ghost


# UTIL ------------------------------------------------------------------------------------------


func light_off():

	var light_fade_out = get_tree().create_tween()
	light_fade_out.tween_property(light_2d, "energy", 0, 0.5).set_ease(Tween.EASE_IN)
	light_fade_out.tween_callback(light_2d, "set_enabled", [false])

	
func light_on():
	
	var light_energy: float
	
	if pixel_color == Global.game_manager.game_settings["player_start_color"]:
		light_2d.color = Global.color_white
		if last_breath_active == true:
			light_energy = 1
		else:
			light_energy = 0.8
	else:
		light_2d.color = pixel_color
		if last_breath_active == true:
			light_energy = 0.5
		else:
			light_energy = 0.64
	
	var light_fade_in = get_tree().create_tween()
	light_fade_in.tween_callback(light_2d, "set_enabled", [true])
	light_fade_in.tween_property(light_2d, "energy", light_energy, 0.2).set_ease(Tween.EASE_IN)
	

func last_breath():
	
	if player_energy == 1 and not last_breath_active: # to se zgodi ob prehodu v stanje
		last_breath_active = true
		last_breath_loop = 0
		light_on()
		animation_player.play("last_breath")		
	elif player_energy > 1:
		last_breath_active = false
		animation_player.stop()
	

func on_hit_stray(hit_stray: KinematicBody2D):
		if Global.game_manager.game_settings["pick_neighbor_mode"]:
			if Global.game_manager.colors_to_pick and not Global.game_manager.colors_to_pick.has(hit_stray.pixel_color): # če pobrana barva ni enaka barvi soseda
				end_move()
				return # nadaljna koda se ne izvede
		# destroj prvega pixla
		pixel_color = hit_stray.pixel_color
		Global.hud.show_picked_color(hit_stray.pixel_color)
		if not Global.game_manager.game_settings["pick_neighbor_mode"]:
			multikill(hit_stray)
		else: # pick_neighbor_mode ne podpira multikilla ... tukaj je pomembno zaporedje
			hit_stray.die(1) # edini oziroma prvi v vrsti	

	
func multikill(hit_stray):

		var all_neighboring_strays: Array = []
		var neighbors_checked: Array = []
		
		# prva runda ... sosede pixla v katerega sem se zaletel
		for neighbor in hit_stray.neighboring_cells:
			# trenutne sosede dodam v vse sosede ... če je še ni notri
			if not all_neighboring_strays.has(neighbor):
				all_neighboring_strays.append(neighbor)
		neighbors_checked.append(hit_stray)
		
		# druga runda ... sosede od pixlov v arrayu vseh sosed (ki še niso med čekiranimi pixli)
		for neighbor_stray in all_neighboring_strays:
			# preverim če sosed ni tudi v "checked" arrayu, preveri in poberi še njegove sosede
			if not neighbors_checked.has(neighbor_stray):
				# vsak od sosedov soseda se doda v med vse sosede
				for stray in neighbor_stray.neighboring_cells:
					if not all_neighboring_strays.has(stray):
						all_neighboring_strays.append(stray)
				# po nabirki ga dodam med preverjene sosede
				neighbors_checked.append(neighbor_stray)
		
		# odstranim kolajderja iz sosed, če je bil sosed nekomu
		if all_neighboring_strays.has(hit_stray):
			all_neighboring_strays.erase(hit_stray)
		
		# destroj prvega soseda
		var stray_in_row = 1 # 2 ker je 1 distrojan po defoltu
		hit_stray.die(stray_in_row) # edini oziroma prvi v vrsti
		emit_signal("stat_changed", self, "hit_stray", [stray_in_row, hit_stray])
		# destroj sosedov od sosedov
		for neighboring_stray in all_neighboring_strays:
			if stray_in_row < burst_power or burst_power == cocked_ghost_count_max: 
				Global.hud.show_picked_color(neighboring_stray.pixel_color) # indikator efekt
				neighboring_stray.die(stray_in_row + 1)
				emit_signal("stat_changed", self, "hit_stray", [(stray_in_row + 1), neighboring_stray])
			stray_in_row += 1


func die():

	player_camera.shake_camera(die_shake_power, die_shake_time, die_shake_decay)
#	modulate = pixel_color
#	end_move()
	
	set_physics_process(false)
	animation_player.play("die_player")


func revive():
	
#	modulate.a = 0
	var dead_time: float = 2
	yield(get_tree().create_timer(dead_time), "timeout")
	animation_player.play("revive")


func play_blinking_sound(): 
	# kličem iz animacije
	
	Global.sound_manager.play_sfx("blinking")


# SIGNALI ------------------------------------------------------------------------------------------
	
		
func _on_ghost_target_reached(ghost_body, ghost_position):
	
	var teleport_tween = get_tree().create_tween()
	teleport_tween.tween_property(poly_pixel, "modulate:a", 0, ghost_fade_time)
	teleport_tween.tween_property(self, "global_position", ghost_position, 0.01)
	# camera follow reset
	teleport_tween.parallel().tween_property(Global, "camera_target", self, 0.01)
	teleport_tween.tween_callback(self, "end_move")
	teleport_tween.tween_property(poly_pixel, "modulate:a", 1, ghost_fade_time)
	teleport_tween.tween_callback(ghost_body, "fade_out")
	
	Global.sound_manager.stop_sfx("teleport")
			
	# za hud
	emit_signal("stat_changed", self, "skill_used", 2) # 0 = push, 1 = pull, 2 = teleport ... za prepoznavanje
	
	Input.stop_joy_vibration(0)


func _on_ghost_detected_body(body):
	
	if body != self:
		cocking_room = false
		Global.sound_manager.play_sfx("burst_limit")
		

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"last_breath":
			last_breath_loop += 1
			if last_breath_loop > last_breath_loop_limit:
#				Global.game_manager.current_gameover_reason = Global.game_manager.GameoverReason.ENERGY
				emit_signal("stat_changed", self, "out_of_breath", 1)
				die()
			else:
				animation_player.play("last_breath")
				Global.sound_manager.play_sfx("last_breath")
		"revive":
			set_physics_process(true)
		
