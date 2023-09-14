extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change)


enum States {IDLE, STEPPING, SKILLING, BURSTING}
var current_state # = States.IDLE

var pixel_color: Color # = Global.color_white
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
var cocked_ghost_alpha: float = 0.3
var cocked_ghost_alpha_factor: float = 25
var ghost_cocking_time: float = 0 # trenuten čas nastajanja cocking ghosta
var ghost_cocking_time_limit: float = 0.12 # max čas nastajanja cocking ghosta (tudi animacija)
var cocked_ghost_fill_time: float = 0.04 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
var cocked_pause_time: float = 0.05 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)

# bursting
var burst_speed: float = 0
var burst_speed_max: float = 0 # maximalna hitrost v tweenu
var burst_speed_max_addon: float = 15
var strech_ghost_shrink_time: float = 0.2
var burst_direction_set: bool = false
var burst_power: int # moč v številu ghosts_count

# shaking camera
var burst_power_shake_adon: float = 0.03
var hit_wall_shake_power: float = 0.25
var hit_wall_shake_time: float = 0.5
var hit_wall_shake_decay: float = 0.2
var hit_stray_shake_power: float = 0.2
var hit_stray_shake_time: float = 0.3
var hit_stray_shake_decay: float = 0.7
var die_shake_power: float = 0.2
var die_shake_time: float = 0.7
var die_shake_decay: float = 0.1

# energija
var player_energy: float = Global.game_manager.player_stats["player_energy"] # energija je edini stat, ki gamore plejer poznat ... greba se iz globalnih statsov
onready var max_player_energy: float = Profiles.game_rules["player_max_energy"]
onready var tired_energy: int = Profiles.game_rules["tired_energy"] # del energije pri kateri velja, da je utrujen (diha hitreje)
onready var current_player_energy_part: float # = player_energy/default_player_energy # delež celotne energije

# dihanje
var breath_speed: float = 2.4
#var tired_breath_speed: float = 2.4
#export var breath_alpha_adon: float = 0.25 # exportan za animacijo
export var skilled_alpha: float = 1.2

# zadnji dih
var last_breath_active: bool = false 
var last_breath_time = 5
onready var last_breath_timer: Timer = $LastBreathTimer

# transparenca energije
onready var poly_pixel: Polygon2D = $PolyPixel
#onready var skilled_on: bool = false
var skill_sfx_playing: bool = false # da lahko kličem is procesne funkcije

onready var cell_size_x: int = Global.level_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay
onready var floor_cells: Array = Global.game_manager.floor_positions
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var Ghost: PackedScene = preload("res://game/pixel/ghost.tscn")
onready var PixelCollisionParticles: PackedScene = preload("res://game/pixel/pixel_collision_particles.tscn")
onready var PixelDizzyParticles: PackedScene = preload("res://game/pixel/pixel_dizzy_particles.tscn")

# speed
onready var max_step_time: float = Profiles.game_rules["max_step_time"]
onready var min_step_time: float = Profiles.game_rules["min_step_time"]


func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Global.group_players)
	
	modulate = pixel_color
	randomize() # za random blink animacije
	global_position = Global.snap_to_nearest_grid(global_position)
	
	# deaktiviram plejerja ... aktivira ga GM, ko v start_game
	set_physics_process(false)
	
#	modulate.a = 1
#	poly_pixel.modulate.a = 1
	animation_player.play("stil_alive_poly")
	current_state = States.IDLE
	
func tets():
	print("dsddddddddddddddddddddddddddddddddddddddddddddddddsddddddddddddddddddddddddddddddddddddddddddddddd")	
#	poly_pixel.modulate.a = 0.5
	
	
func _physics_process(delta: float) -> void:
	
	player_energy = Global.game_manager.player_stats["player_energy"] # stalni apdejt energije iz GMja
	current_player_energy_part = player_energy / max_player_energy # delež celotne energije
	
	# toggle energy_apha mode
	if Profiles.game_rules["energy_alpha_mode"]:
		var alpha_factor = current_player_energy_part
		poly_pixel.modulate.a = clamp(alpha_factor, 0.2, alpha_factor)
	else:
		poly_pixel.modulate.a = 1
	
	# zadnji izdihljaji
	if player_energy == 1 and not last_breath_active: 
		last_breath_active = true
		animation_player.set_speed_scale(breath_speed)
		animation_player.play("breath")
		Global.sound_manager.play_sfx("last_breath")
		if Profiles.game_rules["last_breath_mode"]:
			last_breath_timer.start(last_breath_time)
	elif player_energy == 1:
		modulate = Global.color_red
		poly_pixel.modulate.a = 1 # da je svetel, ko krvavi (tudi kadar je energy_alpha on
	elif player_energy > 1:
		last_breath_active = false
		animation_player.stop()		
		Global.sound_manager.stop_sfx("last_breath")
		if Profiles.game_rules["last_breath_mode"]:
			last_breath_timer.stop()
		modulate = pixel_color
			
	if Global.detect_collision_in_direction(vision_ray, direction): # more bit neodvisno od stateta, da pull dela
		skill_inputs()
	
	match current_state:
		
		States.IDLE:
			
			# skilled
			if Global.detect_collision_in_direction(vision_ray, direction) and player_energy > 1: # koda je tukaj, da ne blinkne ob kontaktu s sosedo
				animation_player.stop() # stop dihanje
				modulate.a = skilled_alpha # resetiraš na skill ready stanje
				emit_signal("stat_changed", self, "skilled",1) # signal, da je skilled (kaj se zgodi je na GMju)
				if not skill_sfx_playing: # to je zato da FP ne klie na vsak frejm
					Global.sound_manager.play_sfx("skilled")
					skill_sfx_playing = true
			else: # not skilled
				modulate.a = modulate.a
				if skill_sfx_playing: # to je zato da FP ne klie na vsak frejm
					Global.sound_manager.stop_sfx("skilled")
					skill_sfx_playing = false
				
			# toggle energy_speed mode
			if Profiles.game_rules["energy_speed_mode"]:
				var slow_trim_size: float = max_step_time * max_player_energy
				var energy_factor: float = (max_player_energy - slow_trim_size) / player_energy
				var energy_step_time = energy_factor / 10 # ta variabla je zato, da se vedno seta nova in potem ne raste s FP
				# omejim najbolj počasno
				step_time = clamp(energy_step_time, min_step_time, max_step_time)
			else:
				step_time = min_step_time
					
			idle_inputs()
							
		States.STEPPING:
			animation_player.stop() # stop dihanje
		
		States.SKILLING: # stanje ko se skill izvaja
			animation_player.stop() # stop dihanje
			modulate.a = skilled_alpha
			
		States.BURSTING: 
			animation_player.stop() # stop dihanje
			burst_inputs()
			var velocity = direction * burst_speed
			collision = move_and_collide(velocity) 
			if collision:
				on_collision()
		
	
func on_collision(): 
	
	# shake calc
	var added_shake_power = hit_stray_shake_power + burst_power_shake_adon * burst_power
	var added_shake_time = hit_stray_shake_time + burst_power_shake_adon * burst_power
	
	if collision.collider.is_in_group(Global.group_tilemap):
		die(Global.reason_wall)
		spawn_collision_particles()
		spawn_dizzy_particles()
		Global.main_camera.shake_camera(added_shake_power, added_shake_time, hit_stray_shake_decay)
		Global.sound_manager.stop_sfx("burst")
		Global.sound_manager.play_sfx("hit_wall")
		
	elif collision.collider.is_in_group(Global.group_strays):
		pixel_color = collision.collider.pixel_color
		spawn_collision_particles()
		Global.main_camera.shake_camera(added_shake_power, added_shake_time, hit_stray_shake_decay)
		Global.sound_manager.stop_sfx("burst")
		Global.sound_manager.play_sfx("hit_stray")
			
		# pick neighbour color
		if Profiles.game_rules["pick_neighbour_mode"]:
			# če je sosed določen, in če pobrana barva ni enaka barvi soseda na spektru
			if Global.game_manager.colors_to_pick and not Global.game_manager.colors_to_pick.has(collision.collider.pixel_color):
				end_move()
				return
		
		# multikill
		var all_neighbouring_pixels: Array = []
		var neighbours_checked: Array = []
		
		# prva runda ... sosede pixla v katerega sem se zaletel
		for neighbour in collision.collider.neighbouring_cells:
			# trenutne sosede dodam v vse sosede ... če je še ni notri
			if not all_neighbouring_pixels.has(neighbour):
				all_neighbouring_pixels.append(neighbour)
		neighbours_checked.append(collision.collider)
		
		# druga runda ... sosede od pixlov v arrayu vseh sosed (ki še niso med čekiranimi pixli)
		for neighbour_pixel in all_neighbouring_pixels:
			# preverim če sosed ni tudi v "checked" arrayu, preveri in poberi še njegove sosede
			if not neighbours_checked.has(neighbour_pixel):
				# vsak od sosedov soseda se doda v med vse sosede
				for np in neighbour_pixel.neighbouring_cells:
					if not all_neighbouring_pixels.has(np):
						all_neighbouring_pixels.append(np)
				# po nabirki ga dodam med preverjene sosede
				neighbours_checked.append(neighbour_pixel)
		
		# destroj hud indikatorja od kolajderja
		Global.hud.color_picked(collision.collider.pixel_color)

		var stray_in_row: int = 1 # to pomeni, da je prvi od sosednjih
		collision.collider.die(stray_in_row)
		
		# odstranim kolajderja iz sosed, če je bil sosed nekomu
		if all_neighbouring_pixels.has(collision.collider):
			all_neighbouring_pixels.erase(collision.collider)
		
		# destroj soseda in sosedov
		var loop_index = 1
		for neighbouring_pixel in all_neighbouring_pixels:
			if loop_index < burst_power: 
				# zbrišeš indikator
				Global.hud.color_picked(neighbouring_pixel.pixel_color)
				stray_in_row = loop_index + 1
				neighbouring_pixel.die(stray_in_row)
			loop_index += 1

	end_move() # more bit tukaj spoadaj, da lahko pogreba podatke v svoji smeri
	

func idle_inputs():
	
	if Input.is_action_pressed("ui_up") and player_energy > 1: # ne koraka z 1 energijo
		direction = Vector2.UP
		step()
	elif Input.is_action_pressed("ui_down") and player_energy > 1:
		direction = Vector2.DOWN
		step()
	elif Input.is_action_pressed("ui_left") and player_energy > 1:
		direction = Vector2.LEFT
		step()
	elif Input.is_action_pressed("ui_right") and player_energy > 1:
		direction = Vector2.RIGHT
		step()
			
	if Input.is_action_just_pressed("space") and current_state == States.IDLE: # brez "just" dela po stisku smeri ... ni ok
		current_state = States.BURSTING


func burst_inputs():

	if Input.is_action_pressed("ui_up"):
		if not burst_direction_set:
			direction = Vector2.DOWN
			burst_direction_set = true
		else:
			cock_burst()
	if Input.is_action_pressed("ui_down"):
		if not burst_direction_set:
			direction = Vector2.UP
			burst_direction_set = true
		else:
			cock_burst()
	if Input.is_action_pressed("ui_left"):
		if not burst_direction_set:
			direction = Vector2.RIGHT
			burst_direction_set = true
		else:
			cock_burst()
	if Input.is_action_pressed("ui_right"):
		if not burst_direction_set:
			direction = Vector2.LEFT
			burst_direction_set = true
		else:
			cock_burst()
			
	if Input.is_action_just_released("space"):
		if burst_direction_set:
			
			release_burst()
		else:
			end_move()

	
func skill_inputs():
	
	var new_direction # nova smer, deluje samo, če ni enaka smeri kolizije
	
	# s tem inputom prekinem "is_pressed" input
	if Input.is_action_just_pressed("ui_up"):
		new_direction = Vector2.UP
	elif Input.is_action_just_pressed("ui_down"):
		new_direction = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_left"):
		new_direction = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		new_direction = Vector2.RIGHT
	
	# select skill, če ga še nima 
	if current_state != States.SKILLING and player_energy > 1:
		
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


func die(die_reason: String):
	end_move()
	
	match die_reason:
		Global.reason_wall:
			emit_signal("stat_changed", self, "wall_hit", 1)
		Global.reason_energy:
			emit_signal("stat_changed", self, "out_of_breath", 1)
			Global.sound_manager.stop_sfx("last_breath")
			last_breath_active = false
			animation_player.stop()
	
	Global.main_camera.shake_camera(die_shake_power, die_shake_time, die_shake_decay)
	
	set_physics_process(false) # aktivira ga revive(), ki se sproži iz animacije
#	animation_player.play("die_player")
	animation_player.play("die_player_unique")


func revive():
	modulate.a = 0
	animation_player.play("revive") # kvefrija se v animaciji

		
func play_blinking_sound():
	Global.sound_manager.play_sfx("blinking")

	
# MOVEMENT ______________________________________________________________________________________________________________


func step():

	var step_direction = direction
	
	# če kolajda izbrani smeri gibanja prenesem kontrole na skill
	if not Global.detect_collision_in_direction(vision_ray, step_direction):
		current_state = States.STEPPING
		
		global_position = Global.snap_to_nearest_grid(global_position)
		
		spawn_trail_ghost()
		
		var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		step_tween.tween_property(self, "position", global_position + direction * cell_size_x, step_time)
		step_tween.tween_callback(self, "end_move")

		# pošljem signal, da odštejem točko
		emit_signal("stat_changed", self, "cells_travelled", 1)
		
#		Global.sound_manager.play_sfx("stepping")
		Global.sound_manager.play_stepping_sfx(current_player_energy_part)


func end_move():
	
	current_state = States.IDLE
	
	burst_direction_set = false
	burst_speed = 0 # more bit tukaj pred _change state, če ne uničuje tudi sam sebe
	
	# reset direction
	modulate = pixel_color
	global_position = Global.snap_to_nearest_grid(global_position)
	
	# reset ray dir
	direction = Vector2.ZERO


# BURST ______________________________________________________________________________________________________________


func cock_burst():

	var burst_direction = direction
	var cock_direction = - burst_direction
	
	Global.sound_manager.play_sfx("burst_cocking")
	
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
				burst_speed_max += burst_speed_max_addon
				# spawnaj cock celico
				spawn_cock_ghost(cock_direction, cocked_ghosts.size() + 1) # + 1 zato, da se prvi ne spawna direktno nad pixlom
	
	
func spawn_cock_ghost(cocking_direction, cocked_ghosts_count):
	
	# spawn ghosta pod manom
	var new_cock_ghost = spawn_ghost(global_position + cocking_direction * cell_size_x * cocked_ghosts_count)
	new_cock_ghost.global_position -= cocking_direction * cell_size_x/2
	new_cock_ghost.modulate.a = cocked_ghost_alpha - (cocked_ghosts_count / cocked_ghost_alpha_factor)
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


func release_burst():
	
	Global.sound_manager.play_sfx("burst_cocked")
	
	# napeti ghosti animirajo do alfa 1
	for ghost in cocked_ghosts:
		var get_set_tween = get_tree().create_tween()
		get_set_tween.tween_property(ghost, "modulate:a", 1, cocked_ghost_fill_time)
		yield(get_tree().create_timer(cocked_ghost_fill_time),"timeout")
	
	# pavza pred strelom	
	yield(get_tree().create_timer(cocked_pause_time), "timeout")
	
	burst(cocked_ghosts.size())
		

func burst(ghosts_count):
	
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
	var release_tween = get_tree().create_tween()
	release_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	# release pixel
	release_tween.tween_callback(new_stretch_ghost, "queue_free")
	release_tween.parallel().tween_property(self, "burst_speed", burst_speed_max, 0.01).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	# resetiram max spid
	burst_speed_max = 0
	cocking_room = true
				
	# za hud  ... premaknjen v on_collision
	emit_signal("stat_changed", self, "burst_released", burst_power)
	
	# zaključek .. tudi signal za pobiranje barv ... v on_collision()
	
	
# SKILLS ______________________________________________________________________________________________________________

		
func push():
	
			
	var push_direction = direction
	var backup_direction = - push_direction
	
	var ray_collider = vision_ray.get_collider() # ! more bit za detect_wall() ... ta ga šele pogreba?
	
	# prostor za zalet?
	if Global.detect_collision_in_direction(vision_ray, backup_direction):
		Global.sound_manager.play_sfx("skill_fail")
		return
	
	current_state = States.SKILLING
		
	# spawn ghosta pod mano
	var new_push_ghost = spawn_ghost(global_position + push_direction * cell_size_x)
	new_push_ghost.modulate.a = modulate.a
	
	if ray_collider.is_in_group(Global.group_strays):
		# prostor pred kolajderjem
		if Global.detect_collision_in_direction(ray_collider.vision_ray, push_direction):
			
			Global.sound_manager.play_sfx("push")
			
			var empty_push_tween = get_tree().create_tween()
			empty_push_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			empty_push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost.global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
			empty_push_tween.tween_property(self, "position", global_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
			empty_push_tween.tween_callback(Global.sound_manager, "play_sfx", ["skill_fail"])
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
			push_tween.tween_callback(Global.sound_manager, "play_sfx", ["pushed"])
			push_tween.tween_property(ray_collider, "position", ray_collider.global_position + push_direction * cell_size_x * push_cell_count, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.05)
			push_tween.tween_callback(self, "end_move")
			push_tween.tween_callback(Global.sound_manager, "play_sfx", ["skill_success"])
			push_tween.parallel().tween_callback(new_push_ghost, "queue_free")
			
		# za hud
		emit_signal("stat_changed", self, "skills_used", 1)


func pull():
	
	var target_direction = direction
	var pull_direction = - target_direction
	
	var target_pixel = vision_ray.get_collider()
	
	# preverjam če ma prostor v smeri premika
	if Global.detect_collision_in_direction(vision_ray, pull_direction): 
		Global.sound_manager.play_sfx("skill_fail")
		return	
		
	current_state = States.SKILLING
	
	Global.sound_manager.play_sfx("pull")
	
	# spawn ghosta pod mano
	var new_pull_ghost = spawn_ghost(global_position + target_direction * cell_size_x)
	new_pull_ghost.modulate.a = modulate.a

	var pull_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	pull_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.parallel().tween_property(new_pull_ghost, "position", new_pull_ghost.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.tween_property(target_pixel, "position", target_pixel.global_position + pull_direction * cell_size_x * pull_cell_count, pull_time)
	pull_tween.parallel().tween_callback(Global.sound_manager, "play_sfx", ["pulled"])
	pull_tween.tween_callback(self, "end_move")
	pull_tween.tween_callback(Global.sound_manager, "play_sfx", ["skill_success"])
	pull_tween.parallel().tween_callback(new_pull_ghost, "queue_free")
	
	# za hud
	emit_signal("stat_changed", self, "skills_used", 1)
	

func teleport():
		
	var teleport_direction = direction
	
	current_state = States.SKILLING
	
	Global.sound_manager.play_sfx("teleport")
	
	# spawn ghost
	var new_teleport_ghost = spawn_ghost(global_position)
	new_teleport_ghost.direction = teleport_direction
	new_teleport_ghost.max_speed = ghost_max_speed
	new_teleport_ghost.modulate.a = 0.5
	new_teleport_ghost.floor_cells = floor_cells
	new_teleport_ghost.cell_size_x = cell_size_x
	new_teleport_ghost.connect("ghost_target_reached", self, "_on_ghost_target_reached")
	
	Global.camera_target = new_teleport_ghost
	
	# zaključek v signalu _on_ghost_target_reached
	

# UTIL ________________________________________________________________________________________________________________


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
	
	# trail ghosts
	var new_pixel_ghost = Ghost.instance()
	new_pixel_ghost.global_position = current_pixel_position
	new_pixel_ghost.modulate = pixel_color
	Global.node_creation_parent.add_child(new_pixel_ghost)
	new_pixel_ghost.poly_pixel.modulate.a = poly_pixel.modulate.a

	return new_pixel_ghost


func random_blink():

	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	return random_animation_name


# SIGNALI ______________________________________________________________________________________________________________
	
		
func _on_ghost_target_reached(ghost_body, ghost_position):
	
	var teleport_tween = get_tree().create_tween()
	teleport_tween.tween_property(self, "modulate:a", 0, ghost_fade_time)
	teleport_tween.tween_property(self, "global_position", ghost_position, 0.01)
	
	# camera follow reset
	teleport_tween.parallel().tween_property(Global, "camera_target", self, 0.01)
	teleport_tween.tween_callback(self, "end_move")
	teleport_tween.tween_property(self, "modulate:a", 1, ghost_fade_time)
	teleport_tween.tween_callback(ghost_body, "fade_out")
	
	Global.sound_manager.stop_sfx("teleport")
			
	# za hud
	# skills_used_count += 1
	emit_signal("stat_changed", self, "skills_used", 1)
	

func _on_ghost_detected_body(body):
	
	if body != self:
		cocking_room = false

		Global.sound_manager.play_sfx("burst_limit")
		

func _on_LastBreathTimer_timeout() -> void:
	die(Global.reason_energy)


