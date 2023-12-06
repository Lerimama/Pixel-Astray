extends KinematicBody2D


signal stat_changed # spremenjena statistika se pošlje v hud

enum States {IDLE, STEPPING, SKILLED, SKILLING, COCKING, RELEASING, BURSTING}
var current_state # = States.IDLE

export var pixel_color: Color # exportano za animacijo "become_white"

var direction = Vector2.ZERO # prenosna
var collision: KinematicCollision2D
var skill_sfx_playing: bool = false # da lahko kličem is procesne funkcije
var player_camera: Node
var player_camera_target: Node

# steping
var step_time: float # uporabi se pri step tweenu in je nekonstanten, če je "energy_speed_mode"
var step_time_fast: float = Global.game_manager.game_settings["step_time_fast"]
var step_time_slow: float = Global.game_manager.game_settings["step_time_slow"]
var step_slowdown_rate: float = Global.game_manager.game_settings["step_slowdown_rate"]

# cocking
var cocked_ghosts: Array
var cocking_room: bool = true
var cocked_ghost_count_max: int = 7
var cock_ghost_setup_time = 0.12 # čas nastajanja cocking ghosta in njegova animacija 
var ghost_cocking_time: float = 0 # trenuten čas nastajanja cocking ghosta ... more bit zunaj, da ga ne resetira na 0 z vsakim frejmom

# bursting
var burst_speed: float = 0 # trenutna hitrost
var burst_speed_max: float = 0 # maximalna hitrost v tweenu (določena med kokanjem)
#var burst_direction_set: bool = false
var burst_cocked_ghost_count: int # moč v številu ghosts_count
var burst_speed_addon: float = 12
var burst_velocity: Vector2

# heartbeat
var heartbeat_active: bool = false 
var heartbeat_loop: int = 0
var has_no_energy: bool

# controls
var key_left: String
var key_right: String
var key_up: String
var key_down: String
var key_burst: String

onready var cell_size_x: int = Global.game_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var glow_light: Light2D = $GlowLight
onready var skill_light: Light2D = $SkillLight

onready var Ghost: PackedScene = preload("res://game/pixel/ghost.tscn")
onready var PixelCollisionParticles: PackedScene = preload("res://game/pixel/pixel_collision_particles.tscn")
onready var PixelDizzyParticles: PackedScene = preload("res://game/pixel/pixel_dizzy_particles.tscn")
onready var FloatingTag: PackedScene = preload("res://game/hud/floating_tag.tscn")

# NEU
var is_virgin: bool = true # začne kot devičnik ... neha bit na prvi end_move ali na začetku cockanja
var player_stats: Dictionary # se aplicira ob spawnanju
var lose_life_on_hit: bool = true # če je lajf na štartu večji od 1
onready var game_settings: Dictionary = Global.game_manager.game_settings 

var current_colider: Node
var teleporting_wall_tile_id = 3


func _unhandled_input(event: InputEvent) -> void:
	
	if name == "p1":
		if Input.is_action_pressed("no1"):
			player_stats["player_energy"] -= 10
			player_stats["player_energy"] = clamp(player_stats["player_energy"], 5, game_settings["player_start_energy"])
			emit_signal("stat_changed", self, player_stats)
	elif name == "p2":
		if Input.is_action_pressed("no2") and player_stats["player_energy"] > 1:
			player_stats["player_energy"] -= 10
			player_stats["player_energy"] = clamp(player_stats["player_energy"], 5, game_settings["player_start_energy"])
			emit_signal("stat_changed", self, player_stats)
	
	
func _ready() -> void:
	print("player")
	
	add_to_group(Global.group_players)
	
	# controler setup
	if Global.game_manager.players_count == 2:
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
		key_burst = "burst"
	
	if game_settings["player_start_life"] > 1:
		lose_life_on_hit = true
	else:
		lose_life_on_hit = false
		
	skill_light.enabled = false
	glow_light.enabled = false
	
	modulate = pixel_color # pixel_color je določen ob spawnu z GM
	current_state = States.IDLE
	
	randomize() # za random blink animacije
	
	
func _physics_process(delta: float) -> void:
	
	state_machine()
	
	# heartbeat
	if player_stats["player_energy"] <= 1:
		has_no_energy = true
	else:
		has_no_energy = false
	if not heartbeat_active and has_no_energy:
		heartbeat_active = true
		heartbeat_loop = 0
		animation_player.play("heartbeat")		
	elif heartbeat_active and not has_no_energy:
		heartbeat_active = false
		animation_player.stop()
	
	# stepping slowdown
	if Global.game_manager.game_settings["step_slowdown_mode"]:
		var slow_trim_size: float = step_time_slow * Global.game_manager.game_settings["player_max_energy"]
		var energy_factor: float = (Global.game_manager.game_settings["player_max_energy"] - slow_trim_size) / player_stats["player_energy"]
		var energy_step_time = energy_factor / step_slowdown_rate # variabla, da FP ne kliče na vsak frejm
		step_time = clamp(energy_step_time, step_time_fast, step_time_slow) # omejim najbolj počasno korakanje
	else:
		step_time = step_time_fast	


func state_machine():
	
	match current_state:
		States.IDLE:
			var current_colider = Global.detect_collision_in_direction(vision_ray, direction)
			if current_colider:
				if current_colider.is_in_group(Global.group_strays):
					current_state = States.SKILLED
				elif current_colider.is_in_group(Global.group_tilemap):
					if current_colider.get_collision_tile_id(self, direction) == teleporting_wall_tile_id:
						current_state = States.SKILLED
			idle_inputs()
		States.SKILLED:
			skill_inputs()
			if not skill_light.enabled:
				skill_light_on()
		States.COCKING:
			cocking_inputs()
		States.BURSTING:
			burst_velocity = direction * burst_speed
			collision = move_and_collide(burst_velocity) 
			if collision:
				on_collision()
			bursting_inputs()

	
func on_collision(): 
	
	Global.sound_manager.stop_sfx("burst")
	
	if collision.collider.is_in_group(Global.group_tilemap):
		on_hit_wall()
	elif collision.collider.is_in_group(Global.group_strays):
		on_hit_stray(collision.collider)
	elif collision.collider.is_in_group(Global.group_players):
		on_hit_player(collision.collider)

	
# INPUTS ------------------------------------------------------------------------------------------


func idle_inputs():
	
	if Input.is_action_pressed(key_up):# and current_state == States.IDLE: # idle state dodam, zato, da ne dela, ko je enkrat v kocking ... zazih
		direction = Vector2.UP
		step()
	elif Input.is_action_pressed(key_down):# and current_state == States.IDLE:
		direction = Vector2.DOWN
		step()
	elif Input.is_action_pressed(key_left):# and current_state == States.IDLE:
		direction = Vector2.LEFT
		step()
	elif Input.is_action_pressed(key_right):# and current_state == States.IDLE:
		direction = Vector2.RIGHT
		step()
	
	if Input.is_action_just_pressed(key_burst): # brez "just" dela po stisku smeri ... ni ok
		current_state = States.COCKING
		glow_light_on()
			

func cocking_inputs():
	
	# cocking
	if Input.is_action_pressed(key_up):
		direction = Vector2.DOWN
		cock_burst()
	elif Input.is_action_pressed(key_down):
		direction = Vector2.UP
		cock_burst()
	elif Input.is_action_pressed(key_left):
		direction = Vector2.RIGHT
		cock_burst()
	elif Input.is_action_pressed(key_right):
		direction = Vector2.LEFT
		cock_burst()
	
	# releasing		
	if Input.is_action_just_released(key_burst):
		if cocked_ghosts.empty():
			end_move()
		else:
			release_burst()
			glow_light_off()
			

func bursting_inputs():
	
	if Input.is_action_just_pressed(key_burst):
		end_move()
		Input.start_joy_vibration(0, 0.6, 0.2, 0.2)
		Global.sound_manager.play_sfx("burst_stop")
		Global.sound_manager.stop_sfx("burst_cocking")	


func skill_inputs():
	
	if has_no_energy: # ne more skillat, če ni energije
		return
		
	var new_direction # nova smer, ker pritisnem še enkrat
	
	# s tem inputom prekinem "is_pressed" input
	if Input.is_action_just_pressed(key_up):
		new_direction = Vector2.UP
	elif Input.is_action_just_pressed(key_down):
		new_direction = Vector2.DOWN
	elif Input.is_action_just_pressed(key_left):
		new_direction = Vector2.LEFT
	elif Input.is_action_just_pressed(key_right):
		new_direction = Vector2.RIGHT
		
	# prehod v cocking stanje
	if Input.is_action_just_pressed(key_burst): # brez "just" dela po stisku smeri ... ni ok
		current_state = States.COCKING
		skill_light_off()
		glow_light_on()
		return	
			
	# izhod iz skilled stanja
#	if new_direction:
#		var pressed_direction_angle: float = round(rad2deg(vision_ray.cast_to.angle_to(new_direction)))
#		if abs(pressed_direction_angle) == 90 or (pressed_direction_angle == 180 and collider.is_in_group(Global.group_tilemap)):
#			current_state = States.IDLE
#			return	
	
	# izbor skila
	var collider: Object = Global.detect_collision_in_direction(vision_ray, direction)
	if new_direction:
		if new_direction == direction:
			if collider.is_in_group(Global.group_tilemap):
				teleport()
			elif collider.is_in_group(Global.group_strays):
				skill_light_off()
				push()
		elif new_direction == - direction:
			skill_light_off()
			if collider.is_in_group(Global.group_strays):
				pull()	
			if collider.is_in_group(Global.group_tilemap):
				current_state = States.IDLE
		else:
			skill_light_off()
			current_state = States.IDLE

				
# MOVEMENT ------------------------------------------------------------------------------------------


func step():
	
	if has_no_energy: # ne more stepat, če ni energije
		return
		
	var step_direction = direction
	
	# če kolajda izbrani smeri gibanja prenesem kontrole na skill
	if not Global.detect_collision_in_direction(vision_ray, step_direction):
		current_state = States.STEPPING
		global_position = Global.snap_to_nearest_grid(global_position)
		spawn_trail_ghost()
		var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		step_tween.tween_property(self, "position", global_position + direction * cell_size_x, step_time)
		step_tween.tween_callback(self, "end_move")
		Global.sound_manager.play_stepping_sfx(player_stats["player_energy"] / Global.game_manager.game_settings["player_max_energy"]) # ulomek je za pitch zvoka
		change_stat("cells_traveled", 1)

		
func end_move():
	
	# reset burst
	burst_speed = 0
	burst_speed_max = 0
	cocking_room = true
	burst_cocked_ghost_count = 0
	if not cocked_ghosts.empty():
		empty_cocking_ghosts()
		
	# ugasnem lučke
	if glow_light.enabled:
		glow_light_off()
	if skill_light.enabled:
		skill_light_off()
	
	# reset vision ray
	direction = Vector2.ZERO 
	
	if is_virgin:
		lose_virginity() # barvo prevzame na koncu tweena
	else:
		modulate = pixel_color
	
	global_position = Global.snap_to_nearest_grid(global_position) 
	current_state = States.IDLE # more bit na kocnu
	
	if Global.sound_manager.teleport_loop.is_playing(): # zazih ... export for windows 
		Global.sound_manager.stop_sfx("teleport")
	

# BURST ------------------------------------------------------------------------------------------


func cock_burst():
	
	var burst_direction = direction
	var cock_direction = - burst_direction
	
	# prostor za začetek napenjanja preverja pixel
	if Global.detect_collision_in_direction(vision_ray, cock_direction): 
		Global.sound_manager.stop_sfx("burst_cocking")
		end_move()
		return
	
	if is_virgin:
		lose_virginity()
		
	# prostor nadaljevanje napenjanja preverja ghost
	if cocked_ghosts.size() < cocked_ghost_count_max and cocking_room:
		ghost_cocking_time += 1 / 60.0 # čas držanja tipke (znotraj nastajanja ene cock celice) ... fejk delta
		if ghost_cocking_time > cock_ghost_setup_time: # ko je čas za eno celico mimo, jo spawnam
			ghost_cocking_time = 0
			burst_speed_max += burst_speed_addon # prištejem hitrost bursta
			spawn_cock_ghost(cock_direction, cocked_ghosts.size() + 1) # + 1 zato, da se prvi ne spawna direktno nad pixlom
			Global.sound_manager.play_sfx("burst_cocking")


func release_burst():
	
	if burst_speed_max == 0: # če je vmes zadet
		return
		
	current_state = States.RELEASING
	
	Global.sound_manager.play_sfx("burst_cocked")

	var cocked_ghost_fill_time: float = 0.04 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
	var cocked_pause_time: float = 0.05 # pavza pred strelom

	# napeti ghosti animirajo do alfa 1
	for ghost in cocked_ghosts:
		var get_set_tween = get_tree().create_tween()
		get_set_tween.tween_property(ghost, "modulate:a", 1, cocked_ghost_fill_time)
		yield(get_tree().create_timer(cocked_ghost_fill_time),"timeout")

	yield(get_tree().create_timer(cocked_pause_time), "timeout")
	burst(cocked_ghosts.size())
		

func burst(current_ghost_count):
	
	
	var burst_direction = direction
	burst_cocked_ghost_count = current_ghost_count
	var ray_collider = vision_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
	var backup_direction = - burst_direction

	# spawn stretch ghost
	var new_stretch_ghost = spawn_ghost(global_position)
	if burst_direction.y == 0: # če je smer horiz
		new_stretch_ghost.scale = Vector2(current_ghost_count, 1)
	elif burst_direction.x == 0: # če je smer ver
		new_stretch_ghost.scale = Vector2(1, current_ghost_count)
	new_stretch_ghost.position = global_position - (burst_direction * cell_size_x * current_ghost_count)/2 - burst_direction * cell_size_x/2
	
	empty_cocking_ghosts() # sprazni ghoste
	
	Global.sound_manager.play_sfx("burst")
	Global.sound_manager.stop_sfx("burst_cocking")
	change_stat("burst_released", 1)
	
	# release ghost 
	var strech_ghost_shrink_time: float = 0.2
	var release_tween = get_tree().create_tween()
	release_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.tween_callback(new_stretch_ghost, "queue_free")
	# release pixel
	release_tween.parallel().tween_property(self, "current_state", States.BURSTING, 0)
	release_tween.parallel().tween_property(self, "burst_speed", burst_speed_max, 0)
	
	# zaključek v on_collision()


func empty_cocking_ghosts():
	
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()
	
	
# SKILLS ------------------------------------------------------------------------------------------

		
func push():
			
	var push_direction = direction
	var backup_direction = - push_direction
	var ray_collider = vision_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
		
	# prostor za zalet?
	if Global.detect_collision_in_direction(vision_ray, backup_direction):
		end_move()
		return

	current_state = States.SKILLING
	
	var push_time: float = 0.3
	var push_cell_count: int = 1	
	var new_push_ghost_position = global_position + push_direction * cell_size_x
	var new_push_ghost = spawn_ghost(new_push_ghost_position)
	
	if ray_collider.is_in_group(Global.group_strays):
		# ni prostora
		if Global.detect_collision_in_direction(ray_collider.vision_ray, push_direction):
			Global.sound_manager.play_sfx("push")
			var empty_push_tween = get_tree().create_tween()
			empty_push_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			empty_push_tween.parallel().tween_property(skill_light, "position", skill_light.position - backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			empty_push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost.global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			empty_push_tween.tween_property(self, "position", global_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
			# empty_push_tween.parallel().tween_callback(self, "skill_light_off")
			empty_push_tween.tween_property(skill_light, "position", skill_light.position, 0) # reset pozicije luči # reset pozicije luči
			empty_push_tween.parallel().tween_callback(self, "end_move")
			empty_push_tween.parallel().tween_callback(new_push_ghost, "queue_free")
		# je prostor
		else: 
			Global.sound_manager.play_sfx("push")
			# napnem
			var push_tween = get_tree().create_tween()
			push_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			push_tween.parallel().tween_property(skill_light, "position", skill_light.position - backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost.global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			# spustim
			push_tween.tween_property(self, "position", global_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
			# push_tween.parallel().tween_callback(self, "skill_light_off")
			push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
			push_tween.tween_property(skill_light, "position", skill_light.position, 0) # reset pozicije luči
			push_tween.parallel().tween_callback(Global.sound_manager, "play_sfx", ["pushed"])
			push_tween.parallel().tween_callback(new_push_ghost, "queue_free")
			push_tween.tween_property(ray_collider, "position", ray_collider.global_position + push_direction * cell_size_x * push_cell_count, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.05)
			push_tween.tween_callback(self, "end_move")
			push_tween.tween_callback(self, "change_stat", ["push_used"]) # 0 = push, 1 = pull, 2 = teleport ... za prepoznavanje
			

func pull():
	
	var target_direction = direction
	var pull_direction = - target_direction
	var target_pixel = vision_ray.get_collider()
	
	# preverjam če ma prostor v smeri premika
	if Global.detect_collision_in_direction(vision_ray, pull_direction): 
		end_move()
		return	
	
	current_state = States.SKILLING
	
	var pull_time: float = 0.3
	var pull_cell_count: int = 1
	var new_pull_ghost = spawn_ghost(global_position + target_direction * cell_size_x)
	
	Global.sound_manager.play_sfx("pull")
	var pull_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	pull_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.parallel().tween_property(skill_light, "position", skill_light.position - pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.parallel().tween_property(new_pull_ghost, "position", new_pull_ghost.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.tween_property(target_pixel, "position", target_pixel.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.parallel().tween_callback(self, "skill_light_off")
	pull_tween.parallel().tween_callback(Global.sound_manager, "play_sfx", ["pulled"])
	pull_tween.tween_property(skill_light, "position", skill_light.position, 0) # reset pozicije luči
	pull_tween.parallel().tween_callback(self, "end_move")
	pull_tween.parallel().tween_callback(new_pull_ghost, "queue_free")
	pull_tween.tween_callback(self, "change_stat", ["pull_used"]) # 0 = push, 1 = pull, 2 = teleport ... za prepoznavanje
	

func teleport():
		
	var teleport_direction = direction
	
	current_state = States.SKILLING
	
	Input.start_joy_vibration(0, 0.3, 0, 0)
	Global.sound_manager.play_sfx("teleport")
	
	var ghost_max_speed: float = 10
	var new_teleport_ghost = spawn_ghost(global_position)

	new_teleport_ghost.direction = teleport_direction
	new_teleport_ghost.max_speed = ghost_max_speed
	new_teleport_ghost.modulate.a = modulate.a * 0.5
	new_teleport_ghost.z_index = 3
	new_teleport_ghost.connect("ghost_target_reached", self, "_on_ghost_target_reached")
	
	# kamera target
	player_camera.camera_target = new_teleport_ghost
	
	yield(get_tree().create_timer(0.2), "timeout")
	# zaključek v signalu _on_ghost_target_reached
	

# SPAWNING ------------------------------------------------------------------------------------------


func spawn_dizzy_particles():
	
	var new_dizzy_pixels = PixelDizzyParticles.instance()
	new_dizzy_pixels.global_position = global_position
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

	var cocked_ghost_alpha: float = 0.55 # najnižji alfa za ghoste
	var cocked_ghost_alpha_divisor: float = 14 # faktor nižanja po zaporedju (manjši je bolj oster
	
	# spawn ghosta pod manom
	var new_cock_ghost = spawn_ghost(global_position + cocking_direction * cell_size_x * cocked_ghosts_count)
	new_cock_ghost.global_position -= cocking_direction * cell_size_x/2
	new_cock_ghost.modulate.a  = cocked_ghost_alpha - (cocked_ghosts_count / cocked_ghost_alpha_divisor)
	new_cock_ghost.direction = cocking_direction
	
	# v kateri smeri je scale
	if direction.y == 0: # smer horiz
		new_cock_ghost.scale.x = 0
	elif direction.x == 0: # smer ver
		new_cock_ghost.scale.y = 0

	# animiram cock celico
	var cock_cell_tween = get_tree().create_tween()
	cock_cell_tween.tween_property(new_cock_ghost, "scale", Vector2.ONE, cock_ghost_setup_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cock_cell_tween.parallel().tween_property(new_cock_ghost, "position", global_position + cocking_direction * cell_size_x * cocked_ghosts_count, cock_ghost_setup_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# ray detect velikost je velikost napenjanja
	new_cock_ghost.ghost_ray.cast_to = direction * cell_size_x
	new_cock_ghost.connect("ghost_detected_body", self, "_on_ghost_detected_body")
	
	# dodam celico v array celic tega zaleta
	cocked_ghosts.append(new_cock_ghost)	

	
func spawn_trail_ghost():
	
	var trail_alpha: float = 0.2
	var trail_ghost_fade_time: float = 0.4
	var new_trail_ghost = spawn_ghost(global_position)
	new_trail_ghost.modulate = pixel_color
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

	return new_pixel_ghost

	
func spawn_floating_tag(value): # kliče ga GM
	
	if value == 0:
		return
	
	var new_floating_tag = FloatingTag.instance()
	new_floating_tag.z_index = 3 # višje od straysa in playerja
	new_floating_tag.global_position = global_position
	new_floating_tag.tag_owner = self
	Global.node_creation_parent.add_child(new_floating_tag)
	
	if value < 0:
		new_floating_tag.modulate = Global.color_red
		new_floating_tag.label.text = str(value)
	elif value > 0:
		new_floating_tag.label.text = "+" + str(value)
		
		
# ON HIT ------------------------------------------------------------------------------------------


func on_hit_player(hit_player: KinematicBody2D):
	
	var player_direction = direction # za korekcijo
	if burst_speed > hit_player.burst_speed: # zmaga
		print ("winner is ", name)
		if hit_player.pixel_color != Global.game_manager.game_settings["player_start_color"]: # če nima nobene barve mu je ne prevzamem
			pixel_color = hit_player.pixel_color # prevzamem barvo
		var burst_speed_difference: float = burst_speed - hit_player.burst_speed
		hit_player.on_get_hit(burst_speed_difference)
		hit_player.end_move() # plejer, ki prvi zazna kontakt ukaže naprej, da je zaporedje pod kontrolo 
		shake_player_camera(2)
		end_move()
		change_stat("hit_player", 1)
	elif burst_speed_max == hit_player.burst_speed: # neodločeno
		print ("draw")
		var burst_speed_sum = burst_speed + hit_player.burst_speed
		shake_player_camera(burst_speed_sum/burst_speed_addon)
		end_move()
		hit_player.shake_player_camera(burst_speed_sum/burst_speed_addon) # plejer, ki prvi zazna kontakt ukaže naprej, da je zaporedje pod kontrolo 
		hit_player.end_move() # plejer, ki prvi zazna kontakt ukaže naprej, da je zaporedje pod kontrolo 
		
	# korekcija, če končata na isti poziciji ali preveč narazen
	global_position = hit_player.global_position + (cell_size_x * (- player_direction)) # plejer eno polje ob zadetem
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	Global.sound_manager.play_sfx("hit_stray")
	spawn_collision_particles()
	
	
func on_hit_wall():
	
	if heartbeat_active: # enako, kot, da bi bil zadnji bit ... kar umre, da se ne animacija ne meša z revive
		heartbeat_active = false
		glow_light.enabled = false
		change_stat("energy_depleted", 1)
	else:
		var value_to_lose_part: float = burst_cocked_ghost_count / float(cocked_ghost_count_max)
		printt("value hit_wall", value_to_lose_part, burst_cocked_ghost_count, cocked_ghost_count_max)
		change_stat("hit_wall", value_to_lose_part)
	
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	Global.sound_manager.play_sfx("hit_wall")
	spawn_dizzy_particles()
	spawn_collision_particles()
	shake_player_camera(burst_cocked_ghost_count)
	
	die()
	end_move()


func on_hit_stray(hit_stray: KinematicBody2D):
	
	var hit_strays_count: int # število zadetih straysov
	var stacked_neighbors = check_for_neighbors(hit_stray)
	
	if stacked_neighbors.empty(): 
		hit_stray.die(0) # 0 pomeni, da je solo (drugačna animacija)
		hit_strays_count = 1
	else:
		var stray_in_row = 1 # za določanje koliko jih uniči določena moč in zaporedje
		hit_stray.die(stray_in_row)
		for neighboring_stray in stacked_neighbors: # uničim sosede
			if stray_in_row < burst_cocked_ghost_count or burst_cocked_ghost_count == cocked_ghost_count_max: # odvisnost od moči bursta
				Global.hud.show_picked_color(neighboring_stray.pixel_color) # indikator efekt
				neighboring_stray.die(stray_in_row)
				stray_in_row += 1 # prištejem šele po uporabi, ker se array vedno začne z 0
			else: break
		hit_strays_count = stray_in_row
		
	pixel_color = hit_stray.pixel_color # more bit pred coll partikli (barva)
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	Global.sound_manager.play_sfx("hit_stray")	
	spawn_collision_particles()
	shake_player_camera(hit_strays_count)			

	Global.hud.show_picked_color(hit_stray.pixel_color)
	change_stat("hit_stray", hit_strays_count)
	
	end_move() # more bit pred coll partikli (smer)
	

func on_get_hit(burst_speed_difference):
	
	var burst_speed_difference_units = burst_speed_difference / burst_speed_addon # dobim število cock ghosts
	var burst_speed_difference_part: float = burst_speed_difference_units / float(cocked_ghost_count_max)
	
	printt("value hit by player", burst_speed_difference_part, burst_speed_difference_units, cocked_ghost_count_max)
	
	# efekti
	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	spawn_dizzy_particles()
	shake_player_camera(burst_speed_difference_units)
	
	# uničim morebitno napenjanje
	if burst_speed_max > 0: 
		burst_speed_max = 0
		empty_cocking_ghosts()
				
	# stats				
	pixel_color = Global.game_manager.game_settings["player_start_color"] # postane začetne barve
	change_stat("hit_by_player", burst_speed_difference_part)
	
	die()


func die():

	set_physics_process(false)
	animation_player.play("die_player")


func revive():
	
	var dead_time: float = 1
	yield(get_tree().create_timer(dead_time), "timeout")
	animation_player.play("revive")


# UTIL ------------------------------------------------------------------------------------------


func shake_player_camera(shake_multiplier):
	
	# shake_multiplier je lahko: enote moči brusta, št. uničenih straysov, razlika v enotah moči bursta med plejerjema
	shake_multiplier = clamp(shake_multiplier, 0, cocked_ghost_count_max) # omejen je z navečjo možno močjo bursta
	
	var shake_multiplier_factor: float = 0.03
	var shake_power: float = 0.2
	var shake_power_multiplied: float = shake_power + shake_multiplier_factor * shake_multiplier
	var shake_time: float = 0.3
	var shake_time_multiplied: float = shake_time + shake_multiplier_factor * shake_multiplier
	var shake_decay: float = 0.7
		
#	printt("shake", shake_power_multiplied, shake_time_multiplied, shake_decay)
	player_camera.shake_camera(shake_power_multiplied, shake_time_multiplied, shake_decay)	

				
func check_for_neighbors(hit_stray: KinematicBody2D):

		var all_neighboring_strays: Array = [] # vsi nabrani sosedi
		var neighbors_checked: Array = [] # vsi sosedi, katerih sosede sem že preveril

		# prva runda ... sosede zadetega straya
		var first_neighbors: Array = hit_stray.check_for_neighbors()
		for first_neighbor in first_neighbors:
			if not all_neighboring_strays.has(first_neighbor): # če še ni dodan med vse sosede
				all_neighboring_strays.append(first_neighbor) # ... ga dodam med vse sosede
		neighbors_checked.append(hit_stray) # zadeti stray gre med "že preverjene" 
		
		# druga runda ... sosede vseh sosed
		for neighbor in all_neighboring_strays:
			if not neighbors_checked.has(neighbor): # če še ni med "že preverjenimi" ...
				var extra_neighbors: Array = neighbor.check_for_neighbors() # ... preverim še njegove sosede
				for extra_neighbor in extra_neighbors:
					if not all_neighboring_strays.has(extra_neighbor):  # če še ni dodan med vse sosede ...
						all_neighboring_strays.append(extra_neighbor) # ... ga dodam med vse sosede
				neighbors_checked.append(neighbor) # po nabirki ga dodam med preverjene sosede
		
		# hit stray izbrišem iz sosed, ker bo uničen posebej
		if all_neighboring_strays.has(hit_stray): 
			all_neighboring_strays.erase(hit_stray)
			
		return all_neighboring_strays
		
	
func play_blinking_sound(): 
	# kličem iz animacije
	
	Global.sound_manager.play_sfx("blinking")


func lose_virginity():
	
	if not has_no_energy:
		animation_player.stop()
	var color_fade_in = get_tree().create_tween()
	color_fade_in.tween_property(self, "modulate", pixel_color, 0.3).set_ease(Tween.EASE_OUT)
	color_fade_in.tween_property(self, "is_virgin", false, 0)


func glow_light_on():
	
	glow_light.color = pixel_color

	var glow_light_base_energy: float = 0.35

	if pixel_color.get_luminance() == 1: # bela
		glow_light_base_energy = 0.55
	elif pixel_color.get_luminance() > 0.90:
		glow_light_base_energy += 0.2
	elif pixel_color.get_luminance() > 0.75:
		glow_light_base_energy += 0.15
	elif pixel_color.get_luminance() > 0.50:
		glow_light_base_energy += 0.05
	
	var glow_light_energy: float = glow_light_base_energy / pixel_color.get_luminance()

	var light_fade_in = get_tree().create_tween()
	light_fade_in.tween_callback(glow_light, "set_enabled", [true])
	light_fade_in.tween_property(glow_light, "energy", glow_light_energy, 0.2).set_ease(Tween.EASE_IN)


func glow_light_off():
	
	var light_fade_out = get_tree().create_tween()
	light_fade_out.tween_property(glow_light, "energy", 0, 0.2).set_ease(Tween.EASE_IN)
	light_fade_out.tween_callback(glow_light, "set_enabled", [false])


func skill_light_on():
	
	skill_light.rotation = vision_ray.cast_to.angle()
	skill_light.color = pixel_color
	
	var skilled_light_base_energy: float = 0.55
	if pixel_color.get_luminance() == 1: # bela
		skilled_light_base_energy = 0.65
	elif pixel_color.get_luminance() < 0.1: # temno siva
		skilled_light_base_energy = 0.3
	var skilled_light_energy: float = skilled_light_base_energy / pixel_color.get_luminance()
		
	var light_fade_in = get_tree().create_tween()
	light_fade_in.tween_callback(skill_light, "set_enabled", [true])
	light_fade_in.tween_property(skill_light, "energy", skilled_light_energy, 0.2).set_ease(Tween.EASE_IN)
	
	
func skill_light_off():
	
	var light_fade_out = get_tree().create_tween()
	light_fade_out.tween_property(skill_light, "energy", 0, 0.2).set_ease(Tween.EASE_IN)
	light_fade_out.tween_callback(skill_light, "set_enabled", [false])


# SIGNALI ------------------------------------------------------------------------------------------
	
		
func _on_ghost_target_reached(ghost_body: Area2D, ghost_position: Vector2):
	
	Global.sound_manager.stop_sfx("teleport")
	Input.stop_joy_vibration(0)
			
	var ghost_fade_time: float = 0.5
	
	var teleport_tween = get_tree().create_tween()
	teleport_tween.tween_property(self, "modulate:a", 0, ghost_fade_time * 2/3).set_ease(Tween.EASE_IN)
	teleport_tween.parallel().tween_callback(self, "skill_light_off")
	teleport_tween.parallel().tween_property(ghost_body, "modulate:a", 1, ghost_fade_time).set_ease(Tween.EASE_IN)
	teleport_tween.tween_property(self, "global_position", ghost_position, 0)
	teleport_tween.parallel().tween_callback(self, "end_move")
	teleport_tween.parallel().tween_property(self, "modulate:a", 1, 0)
	teleport_tween.parallel().tween_property(player_camera, "camera_target", self, 0) # camera follow reset
	teleport_tween.parallel().tween_callback(ghost_body, "queue_free")
	teleport_tween.tween_callback(self, "change_stat", ["teleport_used"]) # 0 = push, 1 = pull, 2 = teleport ... za prepoznavanje


func _on_ghost_detected_body(body):
	
	if body != self:
		cocking_room = false
		Global.sound_manager.play_sfx("burst_limit")
		

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"virgin_blink":
			if is_virgin and not heartbeat_active:
				animation_player.play("virgin_blink")
		"heartbeat":
			heartbeat_loop += 1
			if heartbeat_loop <= 5 and heartbeat_active:
				animation_player.play("heartbeat")
				Global.sound_manager.play_sfx("heartbeat")
			elif heartbeat_active:
				glow_light.enabled = false
				change_stat("energy_depleted", 1)
				die()
		"die_player":
			if player_stats["player_life"] > 0:
				revive()
			else:
				Global.game_manager.game_over(Global.game_manager.GameoverReason.LIFE)	
		"revive":
			set_physics_process(true)
			if lose_life_on_hit:
				change_stat("new_life", 1)


# STAT EVENTS ------------------------------------------------------------------------------------------


func change_stat(event: String, change_value):
	
	match event:
		# hits
		"hit_stray":
			# izračun točk
			var points_rewarded: int = 0
			var energy_rewarded: int = 0
			var hit_strays_count: int =  change_value
			for stray_in_row in hit_strays_count:
				points_rewarded += game_settings["color_picked_points"] * (stray_in_row + 1) # + 1 je da se izognem nuli
				energy_rewarded += game_settings["color_picked_energy"] * (stray_in_row + 1)
			# stats
			player_stats["colors_collected"] += hit_strays_count
			player_stats["player_points"] += points_rewarded
			player_stats["player_energy"] += energy_rewarded
			spawn_floating_tag(points_rewarded) 
			
			# tutorial
			if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
				Global.tutorial_gui.finish_bursting()
				if hit_strays_count >= 3:
					Global.tutorial_gui.finish_stacking()
			# cleaned game-over
#			yield(self, "all_strays_cleaned") # počaka, da vsi uničijo, potem ugotovi, če jih ni več
#			if strays_in_game.size() == 0:
#				stat_owner.animation_player.play("become_white")
#				yield(get_tree().create_timer(2), "timeout") # počakam da postane bel ... usklajeno z animacijo
#				player_stats["player_points"] += game_settings["all_cleaned_points"]
#				spawn_floating_tag(stat_owner,game_settings["all_cleaned_points"]) 
#				yield(get_tree().create_timer(1), "timeout") # mal počakam
#				game_over(GameoverReason.CLEANED)
		"hit_wall":
			if lose_life_on_hit:
				player_stats["player_life"] -= 1
			else:
				var energy_to_lose = round(player_stats["player_energy"] * change_value)
				player_stats["player_energy"] -= energy_to_lose
			var points_to_lose = round(player_stats["player_points"] * change_value)
			player_stats["player_points"] -= points_to_lose
			spawn_floating_tag(- points_to_lose) 
		"hit_player":
			player_stats["player_energy"] = game_settings["player_max_energy"]
			player_stats["player_points"] = game_settings["hit_player_points"]
			spawn_floating_tag(game_settings["hit_player_points"])
		"hit_by_player":
			if lose_life_on_hit:
				player_stats["player_life"] -= 1
			else:
				var energy_to_lose = round(player_stats["player_energy"] * change_value)
				player_stats["player_energy"] -= energy_to_lose
			var points_to_lose = round(player_stats["player_points"] * change_value)
			player_stats["player_points"] -= points_to_lose
			spawn_floating_tag(- points_to_lose) 
		# stats
		"energy_depleted":
			player_stats["player_life"] -= 1
#			player_stats["player_energy"] -= 1 # predvsem, da warning popup izgine
		"new_life":
			player_stats["player_energy"] = game_settings["player_max_energy"]
		"cells_traveled": 
			player_stats["cells_traveled"] += 1
			player_stats["player_energy"] += game_settings["cell_traveled_energy"]
			player_stats["player_points"] += game_settings["cell_traveled_points"]
		"push_used":
			player_stats["skill_count"] += 1
			player_stats["player_energy"] += game_settings["skill_used_energy"]
			player_stats["player_points"] += game_settings["skill_used_points"]
			# tutorial
			if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
				Global.tutorial_gui.push_done()
		"pull_used":
			player_stats["skill_count"] += 1
			player_stats["player_energy"] += game_settings["skill_used_energy"]
			player_stats["player_points"] += game_settings["skill_used_points"]
			# tutorial
			if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
				Global.tutorial_gui.pull_done()
		"teleport_used":
			player_stats["skill_count"] += 1
			player_stats["player_energy"] += game_settings["skill_used_energy"]
			player_stats["player_points"] += game_settings["skill_used_points"]
			# tutorial
			if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
				Global.tutorial_gui.teleport_done()
		"burst_released": 
			player_stats["burst_count"] += 1 # tukaj se kot valju poda burst power
			
	# klempanje
	player_stats["player_energy"] = clamp(player_stats["player_energy"], 1, game_settings["player_max_energy"]) # pri 1 se že odšteva zadnji izdihljaj
	player_stats["player_points"] = clamp(player_stats["player_points"], 0, player_stats["player_points"])	

	# signal na hud
	emit_signal("stat_changed", self, player_stats)
	
	# ON HIT WALL 
	# - loser jo izgubi energijo odvisno od moči bursta glede na max moč
	# - loser jo izgubi točke odvisno od moči bursta glede na max moč
	# - energija izgubi, če ni lajf lose
	
	# ON HIT PLAYER 
	# - winner dobi nazaj vso energijo
	# - winner dobi toliko točk, kot je določeno v settingsih
	# - loser izgubi energijo odvisno od razlike v moči bursta
	# - loser zgubi točke glede na razliko v moči bursta
	# - energija izgubi, če ni lajf lose
	
	# LAJF LOOP
	# - die() kliče
	#	- hit wall ... on collision()
	#	- hit by player ... on_get_hit()
	#	- no energy ... heartbeat_end in on_get_hit(), če ni energije
	# - kjer kličem die(), kličem tudi stat_change()
	#	- die() ima čez obnašanje
	#		- FP off
	#		- kliče revive(), če je lajf še na voljo
	#		- kliče GO na GM, če lajfa ni več
	#	- stat_change() pedena statistiko
	#		- vzame lajf, če je to pogojeno
	#		- vzame energijo, če je to pogojeno
	# - revive() se zgodi, če je še lajfa
	#	- kliče stat_change ("new_life") resetira energijo, če je to pogojeno
	#	- FP on
	# - če je na štartu samo en lajf, se na hit ne izgublja lajfa, ampak energijo
