extends KinematicBody2D


signal stat_changed (stat_owner, event, stat_change)

enum States {IDLE, STEPPING, SKILLING, COCKING, BURSTING}
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
var cocked_ghost_alpha_factor: float = 14 # faktor nižanja po zaporedju (manjši je bolj oster
var ghost_cocking_time: float = 0 # trenuten čas nastajanja cocking ghosta
var ghost_cocking_time_limit: float = 0.12 # max čas nastajanja cocking ghosta (tudi animacija)
var cocked_ghost_fill_time: float = 0.04 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
var cocked_pause_time: float = 0.05 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)

# bursting
var burst_speed: float = 0 # glavna (trenutna) hitrost
var burst_speed_max: float = 0 # maximalna hitrost v tweenu (določena med kokanjem)
var strech_ghost_shrink_time: float = 0.2
var burst_direction_set: bool = false
var burst_power: int # moč v številu ghosts_count
var burst_is_releasing: bool = false # uporaba prekinitev delovavnja inputa v stanju od release do potiska plejerja

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
var slowdown_rate: int = 18 # višja je, počasneje se manjša
var current_player_energy_part: float # 
var player_energy: float = Global.game_manager.player_stats["player_energy"] # energija je edini stat, ki gamore plejer poznat ... greba se iz globalnih statsov
onready var max_player_energy: float = Profiles.game_rules["player_max_energy"]
onready var max_step_time: float = Profiles.game_rules["max_step_time"]
onready var min_step_time: float = Profiles.game_rules["min_step_time"]

# dihanje
var last_breath_active: bool = false 
var last_breath_loop: int = 0
onready var last_breath_loop_limit: int = Profiles.game_rules["last_breath_loop_limit"]

# transparenca energije
onready var poly_pixel: Polygon2D = $PolyPixel
var skill_sfx_playing: bool = false # da lahko kličem is procesne funkcije

onready var pixel_color: Color = Profiles.game_rules["pixel_start_color"]
onready var cell_size_x: int = Global.level_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay
onready var floor_cells: Array = Global.game_manager.floor_positions
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var Ghost: PackedScene = preload("res://game/pixel/ghost.tscn")
onready var PixelCollisionParticles: PackedScene = preload("res://game/pixel/pixel_collision_particles.tscn")
onready var PixelDizzyParticles: PackedScene = preload("res://game/pixel/pixel_dizzy_particles.tscn")
onready var light_2d: Light2D = $Light2D


func _ready() -> void:
	
	randomize() # za random blink animacije
	
	add_to_group(Global.group_players)
	light_2d.enabled = false
	modulate = pixel_color
	poly_pixel.modulate.a = 1
	
	global_position = Global.snap_to_nearest_grid(global_position, Global.level_tilemap.floor_cells_global_positions)
	current_state = States.IDLE
	
	
func _physics_process(delta: float) -> void:
	
	# print("current_state, ", current_state)
	player_energy = Global.game_manager.player_stats["player_energy"] # stalni apdejt energije iz GMja
	current_player_energy_part = player_energy / max_player_energy # delež celotne energije
#	poly_pixel.modulate.a = 1
			
	if Global.detect_collision_in_direction(vision_ray, direction): # more bit neodvisno od stateta, da pull dela
		skill_inputs()
	
	last_breath()
	state_machine()
	light_2d.color = pixel_color


func state_machine():
	
	match current_state:
		States.IDLE:
			
			# skilled
			if Global.detect_collision_in_direction(vision_ray, direction) and player_energy > 1: # koda je tukaj, da ne blinkne ob kontaktu s sosedo
				animation_player.stop() # stop dihanje
				light_2d.enabled = true
				if Global.detect_collision_in_direction(vision_ray, direction).is_in_group(Global.group_strays):
					emit_signal("stat_changed", self, "skilled",1) # signal, da je skilled (kaj se zgodi je na GMju)
					if not skill_sfx_playing: # to je zato da FP ne klie na vsak frejm
						Global.sound_manager.play_sfx("skilled")
						skill_sfx_playing = true
			else: # not skilled
				light_2d.enabled = false		
				if skill_sfx_playing: # to je zato da FP ne klie na vsak frejm
					Global.sound_manager.stop_sfx("skilled")
					skill_sfx_playing = false
			# toggle energy_speed mode
			if Profiles.game_rules["energy_speed_mode"]:
				var slow_trim_size: float = max_step_time * max_player_energy
				var energy_factor: float = (max_player_energy - slow_trim_size) / player_energy
				var energy_step_time = energy_factor / slowdown_rate # ta variabla je zato, da se vedno seta nova in potem ne raste s FP
				# omejim najbolj počasno
				step_time = clamp(energy_step_time, min_step_time, max_step_time)
			else:
				step_time = min_step_time
			idle_inputs()
		States.STEPPING:
#			animation_player.stop() # stop dihanje
			pass
		States.SKILLING: # stanje ko se skill izvaja
			animation_player.stop() # stop dihanje
		States.COCKING: 
			light_2d.enabled = true
			animation_player.stop() # stop dihanje
			cocking_inputs()
		States.BURSTING: # se prižge na štartu releasa bursta
			var velocity = direction * burst_speed
			collision = move_and_collide(velocity) 
			if collision:
				on_collision()
			bursting_inputs()


func last_breath(): # zadnji izdihljaji
	
	if player_energy == 1 and not last_breath_active: # to se zgodi ob prehodu v stanje
		last_breath_active = true
		last_breath_loop = 0
		animation_player.play("last_breath")		
	# elif player_energy == 1: # to se dogaja, ko je v tem stanju
	#	modulate = Global.color_red
	elif player_energy > 1:
		# modulate = pixel_color
		last_breath_active = false
		animation_player.stop()
	
	
func on_collision(): 
	
	# shake calc
	var added_shake_power = hit_stray_shake_power + burst_power_shake_addon * burst_power
	var added_shake_time = hit_stray_shake_time + burst_power_shake_addon * burst_power
	
	if collision.collider.is_in_group(Global.group_tilemap):
		
		Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
		
		# efekt trka s steno
		emit_signal("stat_changed", self, "skilled",1) # signal, da je skilled (kaj se zgodi je na GMju)
		
		die(Global.reason_wall)
		spawn_collision_particles()
		spawn_dizzy_particles()
		Global.main_camera.shake_camera(added_shake_power, added_shake_time, hit_stray_shake_decay)
		Global.sound_manager.stop_sfx("burst")
		Global.sound_manager.play_sfx("hit_wall")

	elif collision.collider.is_in_group(Global.group_strays):
		
		Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
		Global.main_camera.shake_camera(added_shake_power, added_shake_time, hit_stray_shake_decay)
		Global.sound_manager.stop_sfx("burst")
		Global.sound_manager.play_sfx("hit_stray")
			
		if Profiles.game_rules["pick_neighbour_mode"]:
			if Global.game_manager.colors_to_pick and not Global.game_manager.colors_to_pick.has(collision.collider.pixel_color): # če pobrana barva ni enaka barvi soseda
				end_move()
				return # v tem primeru se spodnjidve vrstici ne izvedeta in pixel se ne obarva
		
		# destroj kolajderja ... prvega pixla
		pixel_color = collision.collider.pixel_color
		spawn_collision_particles()
		Global.hud.color_picked(collision.collider.pixel_color)
#		collision.collider.die(1) # edini oziroma prvi v vrsti
		
		if Profiles.game_rules["pick_neighbour_mode"]: # pick_neighbour ne podpira multikilla
			collision.collider.die(1) # edini oziroma prvi v vrsti
			end_move()
			return 
		else:
			multikill()

	end_move() # more bit tukaj spodaj, da lahko pogreba podatke v svoji smeri

	
func multikill():

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
		
		# odstranim kolajderja iz sosed, če je bil sosed nekomu
		if all_neighbouring_pixels.has(collision.collider):
			all_neighbouring_pixels.erase(collision.collider)
		
		
		# destroj soseda in sosedov
		var stray_in_row = 1 # 2 ker je 1 distrojan po defoltu
		collision.collider.die(stray_in_row) # edini oziroma prvi v vrsti
		for neighbouring_pixel in all_neighbouring_pixels:
			if stray_in_row < burst_power or burst_power == cocked_ghost_count_max: 
				# zbrišeš indikator
				Global.hud.color_picked(neighbouring_pixel.pixel_color)
				neighbouring_pixel.die(stray_in_row + 1)
			stray_in_row += 1
	

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
	
	# optimizacija za istočasni klik
#	if Input.is_action_just_pressed("space") and current_state == States.IDLE:
#		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_down"):
#			current_state = States.COCKING
	# normalno
	if Input.is_action_pressed("space") and current_state == States.IDLE: # brez "just" dela po stisku smeri ... ni ok
		if Profiles.game_rules["burst_limit_mode"] and Global.game_manager.player_stats["burst_count"] >= Profiles.game_rules["burst_limit_count"]:
			return	
		current_state = States.COCKING


func cocking_inputs():

	# cocking
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
	
	# releasing		
	if Input.is_action_just_released("space"):
		release_burst()


func bursting_inputs():

	if Input.is_action_just_pressed("space") and not burst_is_releasing:
		stop_burst()


func skill_inputs():
	
	if Profiles.game_rules["skill_limit_mode"] and Global.game_manager.player_stats["skill_count"] >= Profiles.game_rules["skill_limit_count"]:
		return
	if player_energy <= 1:
		return
		
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
	if current_state != States.SKILLING: # and player_energy > 1:
		
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
			
	Global.main_camera.shake_camera(die_shake_power, die_shake_time, die_shake_decay)
	set_physics_process(false) # aktivira ga revive(), ki se sproži iz animacije
	animation_player.play("die_player")


func revive():
	modulate.a = 0
	yield(get_tree().create_timer(Profiles.game_rules["dead_time"]), "timeout")
	animation_player.play("revive")
	# animation_player.play("stil_alive_poly") ... če bodo težave s transparenco

	
# MOVEMENT ______________________________________________________________________________________________________________


func step():

	var step_direction = direction
	
	# če kolajda izbrani smeri gibanja prenesem kontrole na skill
	if not Global.detect_collision_in_direction(vision_ray, step_direction):
		current_state = States.STEPPING
		global_position = Global.snap_to_nearest_grid(global_position, Global.level_tilemap.floor_cells_global_positions)
		spawn_trail_ghost()
		var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		step_tween.tween_property(self, "position", global_position + direction * cell_size_x, step_time)
		step_tween.tween_callback(self, "end_move")
		Global.sound_manager.play_stepping_sfx(current_player_energy_part)

		# pošljem signal, da odštejem točko
		emit_signal("stat_changed", self, "cells_travelled", 1)
		

func end_move():
	
	current_state = States.IDLE
	light_2d.enabled = false # da ne blinka ob zaključku
	burst_direction_set = false
	burst_speed = 0 # more bit tukaj pred _change state, če ne uničuje tudi sam sebe ... trenutno ni treba?
	modulate = pixel_color
	# reset dir
	global_position = Global.snap_to_nearest_grid(global_position, Global.level_tilemap.floor_cells_global_positions)
	# reset ray dir
	direction = Vector2.ZERO


# BURST ______________________________________________________________________________________________________________


func cock_burst():

	var burst_direction = direction
	var cock_direction = - burst_direction
	
	
	# prostor za začetek napenjanja preverja pixel
	if Global.detect_collision_in_direction(vision_ray, cock_direction): 
		end_move()
		Global.sound_manager.stop_sfx("burst_cocking")
		return	# dobra praksa ... zazih
	Global.sound_manager.play_sfx("burst_cocking")
		
	# prostor nadaljevanje napenjanja preverja ghost
	if cocked_ghosts.size() < cocked_ghost_count_max and cocking_room:
			# čas držanja tipke (znotraj nastajanja ene cock celice)
			ghost_cocking_time += 1 / 60.0 # fejk delta
			# ko poteče čas za eno celico mimo, jo spawnam
			if ghost_cocking_time > ghost_cocking_time_limit:
				ghost_cocking_time = 0
				# prištejem hitrost bursta
				burst_speed_max += Profiles.game_rules["burst_speed_addon"]
				# spawnaj cock celico
				spawn_cock_ghost(cock_direction, cocked_ghosts.size() + 1) # + 1 zato, da se prvi ne spawna direktno nad pixlom


func release_burst(): # delo os release do potiska pleyerjevega pixla
	
	if not burst_direction_set:
		end_move()
		return
	
	burst_is_releasing = true
	current_state = States.BURSTING
	
	Global.sound_manager.play_sfx("burst_cocked")
	# napeti ghosti animirajo do alfa 1
	for ghost in cocked_ghosts:
		var get_set_tween = get_tree().create_tween()
		get_set_tween.tween_property(ghost.poly_pixel, "modulate:a", 1, cocked_ghost_fill_time)
		yield(get_tree().create_timer(cocked_ghost_fill_time),"timeout")
	# pavza pred strelom	
	yield(get_tree().create_timer(cocked_pause_time), "timeout")
	burst(cocked_ghosts.size())
	burst_is_releasing = false
		

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
	var release_tween = get_tree().create_tween()
	release_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	# release pixel
	release_tween.tween_callback(new_stretch_ghost, "queue_free")
	release_tween.parallel().tween_property(self, "burst_speed", burst_speed_max, 0.01).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	# resetiram max spid
	burst_speed_max = 0
	cocking_room = true
				
	# zaključek .. tudi signal za pobiranje barv ... v on_collision()


func stop_burst():
	
	# je vklopljeno?
	if not Profiles.game_rules["stop_burst_mode"]:
		return 
	Input.start_joy_vibration(0, 0.6, 0.2, 0.2)
	Global.sound_manager.play_sfx("burst_stop")
	# če je hitrost večja od ene enote ne rabim overšuta
	if burst_speed <= Profiles.game_rules["burst_speed_addon"]:
		end_move()
	else:
		var burst_direction = direction # smer moram pobrat pred "end_move"
		end_move()
		# spawn and animate
		var new_overshoot_ghost = spawn_ghost(global_position)
		new_overshoot_ghost.position = global_position
		new_overshoot_ghost.modulate.a = 0.8
		var overshoot_tween = get_tree().create_tween()
		overshoot_tween.tween_property(new_overshoot_ghost, "position", new_overshoot_ghost.position + burst_direction * cell_size_x, 0.05)
		overshoot_tween.tween_property(new_overshoot_ghost, "modulate:a", 0, 0.1)
	
	
# SKILLS ______________________________________________________________________________________________________________

		
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
			push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
			push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
			push_tween.tween_callback(Global.sound_manager, "play_sfx", ["pushed"])
			push_tween.parallel().tween_callback(new_push_ghost, "queue_free")
			push_tween.tween_property(ray_collider, "position", ray_collider.global_position + push_direction * cell_size_x * push_cell_count, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.05)
			push_tween.tween_callback(self, "end_move")
			push_tween.tween_callback(Global.sound_manager, "play_sfx", ["skill_success"])
			
		# za hud
		emit_signal("stat_changed", self, "skill_used", 1)


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
	pull_tween.tween_callback(self, "end_move")
	pull_tween.tween_callback(Global.sound_manager, "play_sfx", ["skill_success"])
	pull_tween.parallel().tween_callback(new_pull_ghost, "queue_free")
	
	# za hud
	emit_signal("stat_changed", self, "skill_used", 1)
	

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
	

func spawn_cock_ghost(cocking_direction, cocked_ghosts_count):
	
	# spawn ghosta pod manom
	var new_cock_ghost = spawn_ghost(global_position + cocking_direction * cell_size_x * cocked_ghosts_count)
	new_cock_ghost.global_position -= cocking_direction * cell_size_x/2
	# alfa ghosta je enaka alfi polipixla
	new_cock_ghost.modulate.a  = poly_pixel.modulate.a
	new_cock_ghost.poly_pixel.modulate.a  = cocked_ghost_alpha - (cocked_ghosts_count / cocked_ghost_alpha_factor)
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


func random_blink():

	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	return random_animation_name


func play_blinking_sound(): 
	# more bit metoda, da jo lahko kličem iz animacije
	Global.sound_manager.play_sfx("blinking")


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
	emit_signal("stat_changed", self, "skill_used", 1)
	
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
				die(Global.reason_energy)
			else:
				animation_player.play("last_breath")
				Global.sound_manager.play_sfx("last_breath")
		
