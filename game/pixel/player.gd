extends KinematicBody2D
class_name Player


signal stat_changed # spremenjeno statistiko javi v hud
signal rewarded_on_cleaned # da je dobil nagrado ob cleaned javi v GM
signal player_pixel_set # player je pripravljen

enum STATES {IDLE, STEPPING, SKILLED, SKILLING, COCKING, RELEASING, BURSTING}
var current_state: int = STATES.IDLE

var direction = Vector2.ZERO # prenosna
var player_camera: Node
var player_stats: Dictionary # se aplicira ob spawnanju
var collision: KinematicCollision2D
var player_max_energy: float = 192

# colors
var pixel_color: Color = Global.game_manager.game_settings["player_start_color"]
var change_color_tween: SceneTreeTween # če cockam pred končanjem tweena, vzamem to barvo
var change_to_color: Color

# skills and steps
var step_time: float = Global.game_manager.game_settings["player_step_time"]
var teleporting_wall_tile_id: int = 3
var first_skill_use = true # beležim, da lahko določen skill izvajam zvezno
var still_time: float = 0

# bursting
var cocking_room: bool = true
var cocking_loop_pause: float = 1
var cocked_ghost_max_count: int = 5
var cock_ghost_speed_addon: float = 14
var cocked_ghosts: Array
var burst_speed: float = 0 # trenutna hitrost
var burst_velocity: Vector2

# rebursting
var sweep_started: bool = false # začne se na first hit in konča na close_reburst_window
var is_in_reburst: bool = false # ko je v samem reburstu
var reburst_window_open: bool = false #
var reburst_speed_units_count: float = 0 # za prenos original hitrosti v naslednje rebursta
var reburst_cock_ghosts_to_show: int = 1 # za kolk se nakoka (samo vizualni efekt)
var strays_on_start_count: int = -1 setget _change_strays_on_start# SWEEPER, da lahko hitro zabeležim uspeh pleyerja

# touch
var is_surrounded: bool
var surrounded_player_strays: Array # za preverjanje prek večih preverjanj

# controls
var key_left: String
var key_right: String
var key_up: String
var key_down: String
var key_burst: String

# time
var step_time_slow: float = 0.15
var step_slowdown_rate: float = 18
var detect_touch_pause_time: float = 1
var is_surrounded_time: float = 2 # ker merim, kdaj si obkoljen za vedno, je to tudi čas pavze do GO klica ... more bit večje od časa stepanja
var cock_ghost_cocking_time: float = 0.06 # čas nastajanja ghosta in njegova animacija ... original 0.12
var current_ghost_cocking_time: float = 0 # trenuten čas nastajanja ghosta ... tukaj, da ga ne nulira z vsakim frejmom

# free position management
var burst_removed_free_positions: Array = [] # free pozicije, ki se zasedejo me brustom
var previous_position: Vector2 = Vector2.ZERO # pozicija pred zadnjo akcijo ... za vračanje med na-voljo

onready var game_settings: Dictionary = Global.game_manager.game_settings
onready var game_data: Dictionary = Global.game_manager.game_data
onready var cell_size_x: int = Global.current_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa

onready var vision_ray: RayCast2D = $VisionRay
onready var skilling_start_timer: Timer = $SkillingStartTimer
onready var rebursting_timer: Timer = $ReburstingTimer
onready var touch_timer: Timer = $TouchTimer
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var color_poly: Polygon2D = $ColorPoly # on daje barvo celemu pixlu
onready var burst_light: Light2D = $BurstLight
onready var skill_light: Light2D = $SkillLight
onready var glow_light: Light2D = $GlowLight
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var touch_detect_areas: Node2D = $Touch
onready var bursting_ray: RayCast2D = $BurstingRay

onready var Ghost: PackedScene = preload("res://game/pixel/ghost.tscn")
onready var PixelCollisionParticles: PackedScene = preload("res://game/pixel/pixel_collision_particles.tscn")
onready var PixelDizzyParticles: PackedScene = preload("res://game/pixel/pixel_dizzy_particles.tscn")
onready var FloatingTag: PackedScene = preload("res://game/gui/floating_tag.tscn")


func _ready() -> void:

	add_to_group(Global.group_players)
	randomize() # za random blink animacije

	# controler setup
	if Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
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

	skill_light.enabled = false
	burst_light.enabled = false

	current_state = STATES.IDLE

	# vision ray
	vision_ray.enabled = false # uporabljam ga z force raycast, ki ne rabi enabled
	for area in touch_detect_areas.get_children():
		vision_ray.add_exception(area)


func _physics_process(delta: float) -> void:

	# ob štartu igre preveri količino strajsov
	if strays_on_start_count == -1 and Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		strays_on_start_count = get_tree().get_nodes_in_group(Global.group_strays).size()

	color_poly.modulate = pixel_color # povezava med variablo in barvo mora obstajati non-stop

	# glow light setup
	if pixel_color == Global.game_manager.game_settings["player_start_color"]:
		glow_light.color = Color.white
		glow_light.energy = 1.7
	else:
		glow_light.color = pixel_color
		glow_light.energy = 1.5 # če spremeniš, je treba spremenit tudi v animacijah

	# na SKILLED timer štartam, drugače ga ustavim
	if current_state == STATES.SKILLED:
		if skilling_start_timer.is_stopped() and first_skill_use:
			skilling_start_timer.start() # wait time je določen na nodetu
	else:
		if not skilling_start_timer.is_stopped():
			skilling_start_timer.stop()

	state_machine(delta)


func state_machine(delta: float):

	match current_state:
		STATES.IDLE:
			still_time += delta
			stop_sound("burst_cocking")
			burst_light_off() # zazih
			idle_inputs()
			bursting_ray.enabled = false
		STATES.STEPPING:
			still_time = 0
			bursting_ray.enabled = false
		STATES.SKILLED:
			still_time = 0
			stop_sound("burst_cocking")
			skill_inputs()
			bursting_ray.enabled = false
		STATES.COCKING:
			still_time = 0
			cocking_inputs()
			bursting_ray.enabled = false
		STATES.BURSTING:
			still_time = 0
			stop_sound("burst_cocking")
			burst_velocity = direction * burst_speed
			collision = move_and_collide(burst_velocity)
			if not bursting_ray.enabled:
				bursting_ray.enabled = true

			var bursting_vision_collider: Node2D = Global.detect_collision_in_direction(direction, vision_ray)#, 100)
			var bursting_collider: Node2D = Global.detect_collision_in_direction(direction, bursting_ray, 1000)#, 100)
			if bursting_collider and bursting_collider.is_in_group(Global.group_strays):
				var distance_to_target: float = 0
				if bursting_collider.global_position.x == global_position.x:
					distance_to_target = abs(bursting_collider.global_position.y - global_position.y)
				elif bursting_collider.global_position.y == global_position.y:
					distance_to_target = abs(bursting_collider.global_position.x - global_position.x)
				if not distance_to_target > cell_size_x + 80: # ta 80 ne vpliva čist kot bi si mislil
					printt("bursting_collider", distance_to_target, bursting_collider.global_position, global_position)
					color_poly.modulate = Color.white
					_on_stray_collision(bursting_collider)
			# vision koližn
			elif bursting_vision_collider and bursting_vision_collider.is_in_group(Global.group_strays): # zazih ... nisem še opazu
				_on_stray_collision(bursting_vision_collider)
				printt("bursting_vision_collider", bursting_vision_collider, bursting_vision_collider.global_position, global_position)
				# kinematic koližn
			elif collision:
				on_collision()
				printt("collision", collision)
			else:
				bursting_inputs() # če je koližn, ne morš več ustavlat

			# med burstanjem pucam available pozicije za dve poziciji naprej
			# ampak samo, če so še available (da ne puca greba unih, kjer je hitan stray)
			var current_position_snapped = Global.snap_to_nearest_grid(global_position)
			var front_current_position_snapped = current_position_snapped + direction * cell_size_x
			var front_current_position_snapped_2 = current_position_snapped + direction * cell_size_x * 2
			# vse pozicije, ki so na poti in so na-voljo, odstranim iz na-voljo
			for pos in [current_position_snapped, front_current_position_snapped, front_current_position_snapped_2]:
				if Global.game_manager.is_floor_position_free(pos) and not burst_removed_free_positions.has(pos): # da se ne podvajajo:
					burst_removed_free_positions.append(pos)
					Global.game_manager.remove_from_free_floor_positions(pos)

	if not first_skill_use: # resetiram first_skill_use ... samo tukaj dobro dela
		if Input.is_action_just_released(key_up):
			first_skill_use = true
			skill_light_off()
		elif Input.is_action_just_released(key_down):
			first_skill_use = true
			skill_light_off()
		elif Input.is_action_just_released(key_left):
			first_skill_use = true
			skill_light_off()
		elif Input.is_action_just_released(key_right):
			first_skill_use = true
			skill_light_off()


func _on_stray_collision(collider_stray: Node2D):

	var on_hit_positon: Vector2 = collider_stray.global_position - cell_size_x * direction
	global_position = Global.snap_to_nearest_grid(on_hit_positon)

	# reakcija na vrsto hita
	if collider_stray.current_state == collider_stray.STATES.WHITE:
		collider_stray.manage_expressions(true)
		on_hit_wall()
	else:
		on_hit_stray(collider_stray)


func on_collision():

	stop_sound("burst")

	# reakcija na vrsto hita
	if collision.collider.is_in_group(Global.group_tilemap):
		on_hit_wall()
	elif collision.collider is StaticBody2D: # top screen limit
		on_hit_wall()
	elif collision.collider.is_in_group(Global.group_players):
		on_hit_player(collision.collider)


# INPUTS ------------------------------------------------------------------------------------------


func idle_inputs():

	var current_collider: Object = Global.detect_collision_in_direction(direction, vision_ray)

	# dokler ne zazna kolizije se premika zvezno ... is_action_pressed, potem pa se ustavi ali postane SKILLED
	if not current_collider:
		if reburst_window_open:
			rebursting_inputs()
		else:
			if Input.is_action_pressed(key_up):
				direction = Vector2.UP
				step()
			elif Input.is_action_pressed(key_down):
				direction = Vector2.DOWN
				step()
			elif Input.is_action_pressed(key_left):
				direction = Vector2.LEFT
				step()
			elif Input.is_action_pressed(key_right):
				direction = Vector2.RIGHT
				step()
	else:
		# reburst ali navaden pritisk smeri
		if sweep_started:
			rebursting_inputs()
		else:
			# če je SKILLED, kontrole prevzame skilled_input, če ne end move()
			if current_collider.is_in_group(Global.group_strays) and not current_collider.current_state == current_collider.STATES.DYING:
				current_state = STATES.SKILLED
			elif current_collider.is_in_group(Global.group_tilemap):
				if current_collider.get_collision_tile_id(self, direction) == teleporting_wall_tile_id:
					current_state = STATES.SKILLED
				else:
					end_move()
			elif current_collider.is_in_group(Global.group_players):
				end_move()
			elif current_collider is StaticBody2D: # static body,
				end_move()


	if Input.is_action_just_pressed(key_burst): # brez "just" dela po stisku smeri ... ni ok
		# če je burstanje omejeno in je velje od limite ne sprožim kokanja
		if sweep_started:
			close_reburst_window(true)
		else:
			current_state = STATES.COCKING
			if change_color_tween and change_color_tween.is_running(): # če sprememba barve še poteka, jo spremenim takoj
				change_color_tween.kill()
				pixel_color = change_to_color
			burst_light_on()



func skill_inputs():

	skill_light_on()

	var new_direction: Vector2 # nova smer, ker pritisnem še enkrat
	if first_skill_use: # frist skill use se ugasne, ko naredim prvi skill in prižge, ko spustim smerno tipko
		if Input.is_action_just_pressed(key_up):
			first_skill_use = false
			new_direction = Vector2.UP
		elif Input.is_action_just_pressed(key_down):
			first_skill_use = false
			new_direction = Vector2.DOWN
		elif Input.is_action_just_pressed(key_left):
			first_skill_use = false
			new_direction = Vector2.LEFT
		elif Input.is_action_just_pressed(key_right):
			first_skill_use = false
			new_direction = Vector2.RIGHT
	else: # zvezni push in pull (pull ima na koncu spet preverjanje tipke)
		if Input.is_action_pressed(key_up):
			new_direction = Vector2.UP
		elif Input.is_action_pressed(key_down):
			new_direction = Vector2.DOWN
		elif Input.is_action_pressed(key_left):
			new_direction = Vector2.LEFT
		elif Input.is_action_pressed(key_right):
			new_direction = Vector2.RIGHT

	# prehod v cocking stanje
	if Input.is_action_just_pressed(key_burst): # brez "just" dela po stisku smeri ... ni ok
		current_state = STATES.COCKING
		skill_light_off()
		burst_light_on()


	# izbor skila v novi smeri
	var current_collider: Object = Global.detect_collision_in_direction(direction, vision_ray)
	if current_collider: # zaščita, če se povežeš in ti potem pobegne
		if new_direction:
			if new_direction == direction: # naprej
				if current_collider.is_in_group(Global.group_tilemap):
					teleport()
				elif current_collider.is_in_group(Global.group_strays) and not current_collider.current_state == current_collider.STATES.MOVING:
					if current_collider.current_state == current_collider.STATES.WHITE:
						teleport()
					else:
						push(current_collider)
			elif new_direction == - direction: # nazaj
				if current_collider.is_in_group(Global.group_strays) and not current_collider.current_state == current_collider.STATES.MOVING:
					if current_collider.current_state == current_collider.STATES.WHITE:
						end_move()
					else:
						pull(current_collider)
				elif current_collider.is_in_group(Global.group_tilemap):
					end_move() # nazaj ... izhod iz skilla, če gre za steno
			else: # levo/desno ... izhod iz skilla
				end_move()
				if current_collider.is_in_group(Global.group_strays) and not current_collider.current_state == current_collider.STATES.WHITE:
					current_collider.current_state = current_collider.STATES.IDLE
	else:
		end_move()


func cocking_inputs():

	# cocking
	if Input.is_action_pressed(key_up):
		if cocked_ghosts.empty(): # če je smer setana, ni pa potrjena
			direction = Vector2.DOWN
		if direction == Vector2.DOWN: # če je smer setana (ista)
			cock_burst()
	elif Input.is_action_pressed(key_down):
		if cocked_ghosts.empty():
			direction = Vector2.UP
		if direction == Vector2.UP:
			cock_burst()
	elif Input.is_action_pressed(key_left):
		if cocked_ghosts.empty():
			direction = Vector2.RIGHT
		if direction == Vector2.RIGHT:
			cock_burst()
	elif Input.is_action_pressed(key_right):
		if cocked_ghosts.empty():
			direction = Vector2.LEFT
		if direction == Vector2.LEFT:
			cock_burst()

	# releasing
	if Input.is_action_just_released(key_burst):
		if cocked_ghosts.empty():
			end_move()
		else:
			release_burst()
		burst_light_off()


func bursting_inputs():

	# stop burst
	if Input.is_action_just_pressed(key_burst):
		stop_burst()


func rebursting_inputs():

	# cocking
	if Input.is_action_just_pressed(key_up):
		direction = Vector2.UP
		cock_reburst()
	elif Input.is_action_just_pressed(key_down):
		direction = Vector2.DOWN
		cock_reburst()
	elif Input.is_action_just_pressed(key_left):
		direction = Vector2.LEFT
		cock_reburst()
	elif Input.is_action_just_pressed(key_right):
		direction = Vector2.RIGHT
		cock_reburst()



# MOVEMENT ------------------------------------------------------------------------------------------


func step():
	# step koda se ob držanju tipke v smeri izvaja stalno

	var step_direction = direction
	var intended_position: Vector2 = global_position + direction * cell_size_x

	if Global.game_manager.is_floor_position_free(intended_position):

		if not Global.detect_collision_in_direction(step_direction, vision_ray): # zazih in za defender tip roba

			current_state = STATES.STEPPING
			previous_position = global_position
			Global.game_manager.remove_from_free_floor_positions(intended_position)

			spawn_trail_ghost()
			play_stepping_sound(player_stats["player_energy"] / player_max_energy) # ulomek je za pitch zvoka

			var current_step_time = get_step_time()
			var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			step_tween.tween_property(self, "position", intended_position, current_step_time)
			step_tween.tween_callback(self, "end_move")
			step_tween.tween_callback(self, "_change_stat", ["cells_traveled", 1]) # točke in energija kot je določeno v settingsih


func end_move(end_position: Vector2 = global_position):

	if is_in_reburst:
		is_in_reburst = false

	# reset burst
	burst_speed = 0
	cocking_room = true
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()

	# ugasnem lučke
	if first_skill_use: # ugasne samo, če je bil ni bilo zveznega porivanja
		skill_light_off()

	# reset ključnih vrednosti (če je v skill tweenu, se poštima)
	direction = Vector2.ZERO

	# če je "out of bounds" gre po drugi poti in tam faše end_move()
	if not Global.current_tilemap.tilemap_edge_rectangle.has_point(global_position):
		on_out_of_bounds() # ga premakne znotraj igrišča in potem sproži end_move()
	else:
		global_position = Global.snap_to_nearest_grid(global_position)
		# after snaping
		current_state = STATES.IDLE # more bit za snapanjem ... ne vem zakaj

		# prejšnja pozicija je spet free
		if not previous_position == Vector2.ZERO:
			Global.game_manager.add_to_free_floor_positions(previous_position)
		# v burstu odstranjene floor_pozicije so spet free
		for floor_position in burst_removed_free_positions:
			Global.game_manager.add_to_free_floor_positions(floor_position)
		burst_removed_free_positions.clear()

		# na koncu trenutna pozicija ni več free
		if Global.game_manager.is_floor_position_free(global_position):
			Global.game_manager.remove_from_free_floor_positions(global_position)


# BURST ------------------------------------------------------------------------------------------


func cock_burst():

	var burst_direction = direction
	var cock_direction = - burst_direction

	# prostor za začetek napenjanja preverja pixel
	if Global.detect_collision_in_direction(cock_direction, vision_ray):
		end_move()
	else:
		if cocked_ghosts.size() < cocked_ghost_max_count and cocking_room: # prostor za napenjanje preverja ghost
			play_sound("burst_cocking")
			current_ghost_cocking_time += 1 / 60.0 # čas držanja tipke (znotraj nastajanja ene cock celice) ... fejk delta
			if current_ghost_cocking_time > cock_ghost_cocking_time: # ko je čas za eno celico mimo, jo spawnam
				current_ghost_cocking_time = 0
				var new_cock_ghost = spawn_cock_ghost(cock_direction)
				cocked_ghosts.append(new_cock_ghost)
		# auto-release
		#	elif cocked_ghosts.size() == cocked_ghost_max_count:
		#		current_ghost_cocking_time += 1 / 60.0 # čas držanja tipke (znotraj nastajanja ene cock celice) ... fejk delta
		#		if current_ghost_cocking_time > 6 * cock_ghost_cocking_time: # auto burst
		#			release_burst()
		#			burst_light_off()


func release_burst():

	current_state = STATES.RELEASING

	play_sound("burst_cocked")

	# napeti ghosti animirajo do alfa 1
	var cocked_ghost_fill_time: float = 0.015 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
	for ghost in cocked_ghosts:
		var get_set_tween = get_tree().create_tween()
		get_set_tween.tween_property(ghost, "modulate:a", 1, cocked_ghost_fill_time)
		yield(get_set_tween,"finished")
	var cocked_pause_time: float = 0.03 # pavza pred strelom
	yield(get_tree().create_timer(cocked_pause_time), "timeout")

	burst()


func burst():

	var burst_direction = direction
	var backup_direction = - burst_direction
	var current_ghost_count = cocked_ghosts.size()

	# spawn stretch ghost
	var new_stretch_ghost = spawn_ghost(global_position)
	new_stretch_ghost.color_poly.hide()
	new_stretch_ghost.color_poly_alt.show()
	if burst_direction.y == 0: # če je smer hor
		new_stretch_ghost.scale = Vector2(current_ghost_count, 1)
	elif burst_direction.x == 0: # če je smer ver
		new_stretch_ghost.scale = Vector2(1, current_ghost_count)
	new_stretch_ghost.position = global_position - (burst_direction * cell_size_x * current_ghost_count)/2 - burst_direction * cell_size_x/2

	# release cocked ghosts ... zazih
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()

	play_sound("burst")

	# release ghost
	var strech_ghost_shrink_time: float = 0.1
	var release_tween = get_tree().create_tween()
	release_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.tween_callback(new_stretch_ghost, "queue_free")
	yield(release_tween, "finished")

	# release pixel
	current_state = STATES.BURSTING
	previous_position = global_position

	if Global.game_manager.game_settings["full_power_mode"]:
		burst_speed = cocked_ghost_max_count * cock_ghost_speed_addon # maximalna možna hitrost
	else:
		burst_speed = current_ghost_count * cock_ghost_speed_addon

	_change_stat("burst_count", 1)

	# če je sosed, takoj izvede karambol (drugače ga sploh ne dojame)
	for area in touch_detect_areas.get_children():
		# preverjam areo v smeri bursta (dot produkt), če se česa dotika
		if area.position.dot(direction) > 0 and not area.get_overlapping_areas().empty():
			# da dobim zazih pravi rezultat preverjam z vision ray, če je stray
			var bursting_vision_collider: Node2D = Global.detect_collision_in_direction(direction, vision_ray)
			if bursting_vision_collider and bursting_vision_collider.is_in_group(Global.group_strays):
				_on_stray_collision(bursting_vision_collider)
				break


func stop_burst():

	end_move()
	Input.start_joy_vibration(0, 0.6, 0.2, 0.2)
	play_sound("burst_stop")

	if sweep_started:
		close_reburst_window(true)


# REBURST ------------------------------------------------------------------


func cock_reburst():

	close_reburst_window()

	# prenos iz burst tipke ... ker tudi kao cocka
	if change_color_tween and change_color_tween.is_running(): # če sprememba barve še poteka, jo spremenim takoj
		change_color_tween.kill()
		pixel_color = change_to_color

	var burst_direction = direction
	var cock_direction = - burst_direction

	# če ni prostora, ne dela cockinga
	if Global.detect_collision_in_direction(cock_direction, vision_ray):
		release_reburst()
	else: # če je prostor cocka
		for cock in reburst_cock_ghosts_to_show:
			var new_cock_ghost = spawn_cock_ghost(cock_direction)
			#new_cock_ghost.modulate.a = 0.5
			cocked_ghosts.append(new_cock_ghost)
			if not cocking_room:
				break
		release_reburst()


func release_reburst():
	# drugače glede na burst: cock ghost izgled

	current_state = STATES.RELEASING
	play_sound("burst_cocked")
	var cocked_ghost_fill_time: float = 0.07 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
	# napeti ghosti animirajo do alfa 1
	for ghost in cocked_ghosts:
		var get_set_tween = get_tree().create_tween()
		get_set_tween.tween_property(ghost, "modulate:a", 0.5, cocked_ghost_fill_time)
		yield(get_set_tween,"finished")
	var cocked_pause_time: float = 0.1 # pavza pred strelom
	yield(get_tree().create_timer(cocked_pause_time), "timeout")
	reburst()


func reburst():
	# drugače glede na burst: ni strech ghopsa

	is_in_reburst = true

	var burst_direction = direction
	var backup_direction = - burst_direction
	var current_ghost_count = cocked_ghosts.size()

	# release cocked ghosts
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()

	play_sound("burst")

	# release pixel
	current_state = STATES.BURSTING
	burst_speed = reburst_speed_units_count * cock_ghost_speed_addon


func close_reburst_window(finish_sweep: bool = false):
	# se resetira na vsak reburst in drugo

	reburst_window_open = false
	rebursting_timer.stop()
	burst_light_off()

	if finish_sweep:
		sweep_started = false
		if strays_on_start_count > 0: # -1 je kul
			Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)


# SKILLS ------------------------------------------------------------------------------------------


func push(stray_to_move: Node2D):

	var push_direction: Vector2 = direction
	var backup_direction: Vector2 = - push_direction

	# prostor za zalet?
	if Global.detect_collision_in_direction(backup_direction, vision_ray):
		end_move()
	else:
		current_state = STATES.SKILLING

		# vzamem vse, ki ji rabim: trenutno pozicijo, backup backup ... intended ne rabiš, ker je zasedena ne glede na uspeh
		var backup_position: Vector2 = global_position + backup_direction * cell_size_x
		var current_position: Vector2 = global_position
		previous_position = backup_position
		Global.game_manager.remove_from_free_floor_positions(backup_position) # vrnem na end_move() ... ne glede na uspeh porivanja
		Global.game_manager.remove_from_free_floor_positions(current_position) # vrnem na koncu uspelega porivanja, ker bo prazna

		# naberi sosede na liniji in preveri prostor za porivanje
		var room_for_push: bool = true
		var strays_to_move: Array = [stray_to_move]
		for stray in strays_to_move:
			# preverja IDLE vse za katere preverja sosede (tudi prvega, ki je dodan pred loopom)
			if not stray_to_move.current_state == stray_to_move.STATES.IDLE:
				room_for_push =  false
				break
			else:
				var stray_neighbor = Global.detect_collision_in_direction(push_direction, stray.neighbor_ray)
				if stray_neighbor:
					# preverja IDLE vse za, ki imajo status soseda
					if stray_neighbor.is_in_group(Global.group_strays) and stray_neighbor.current_state == stray_neighbor.STATES.IDLE:
						strays_to_move.append(stray_neighbor)
					else:
						room_for_push =  false
						break


		play_sound("pushpull_start")

		var push_cocktime: float = 0.3
		var push_time: float = 0.2
		var new_push_ghost_position = global_position + push_direction * cell_size_x
		var new_push_ghost = spawn_ghost(new_push_ghost_position)

		if room_for_push: # če je prostor gre dlje, kot če ga ni
			var push_tween = get_tree().create_tween()
			push_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x, push_cocktime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			push_tween.parallel().tween_property(skill_light, "energy", 0.5, push_cocktime)
			push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost.global_position + backup_direction * cell_size_x, push_cocktime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			# lučko zapeljem na začetek ghosta (ostane ob strayu)
			push_tween.parallel().tween_property(skill_light, "position", skill_light.position - backup_direction * cell_size_x, push_cocktime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			# release
			push_tween.tween_callback(self, "play_sound", ["pushpull_end"])
#			push_tween.tween_callback(self, "skill_light_off") # lučko dam v proces ugašanja
			push_tween.tween_property(self, "position", global_position + push_direction * cell_size_x, push_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			push_tween.parallel().tween_property(skill_light, "position", Vector2.ZERO, push_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN) # lučko zapeljem nazaj na začetno lokacijo
			push_tween.tween_callback(new_push_ghost, "hide") # skrijem ga ko ga pixel pokrije
			# porinem vse strayse v vrsti
			for stray_to_move in strays_to_move:
				push_tween.tween_callback(stray_to_move, "push_stray", [push_direction, push_time])
			push_tween.tween_callback(self, "play_sound", ["pushed"]).set_delay(0.07)
			push_tween.tween_callback(new_push_ghost, "queue_free")
			yield(push_tween, "finished")
			Global.game_manager.add_to_free_floor_positions(current_position)
		else:
			var push_tween = get_tree().create_tween()
			# cock
			push_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x, push_cocktime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			push_tween.parallel().tween_property(skill_light, "energy", 0.5, push_cocktime)
			push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost.global_position + backup_direction * cell_size_x, push_cocktime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			# lučko zapeljem na začetek ghosta (ostane ob strayu)
			push_tween.parallel().tween_property(skill_light, "position", skill_light.position - backup_direction * cell_size_x, push_cocktime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			# release
			push_tween.tween_callback(self, "play_sound", ["pushpull_end"])
			push_tween.tween_callback(self, "skill_light_off") # lučko dam v proces ugašanja
			push_tween.tween_property(self, "position", global_position, push_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			push_tween.parallel().tween_property(skill_light, "position", Vector2.ZERO, push_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN) # lučko zapeljem nazaj na začetno lokacijo
			push_tween.tween_callback(new_push_ghost, "queue_free")
			yield(push_tween, "finished")

		end_move()

		_change_stat("skill_used", 1)


func pull(stray_to_move: Node2D):

	var target_direction: Vector2 = direction
	var pull_direction: Vector2 = - target_direction
	var intended_position: Vector2 = global_position + pull_direction * cell_size_x

	# je prostor v smeri premika?
	if Global.detect_collision_in_direction(pull_direction, vision_ray):
		end_move()
	else:
#		skill_light.energy = 0.5
#		skill_light_off()

		current_state = STATES.SKILLING

		previous_position = Vector2.ZERO # nestandardno, ker sem pride pulan stray in ne rabim konfliktov
		Global.game_manager.remove_from_free_floor_positions(intended_position)

		play_sound("pushpull_start")

		var pull_cocktime: float = 0.3
		var pull_time: float = 0.2
		var pull_end_delay: float = 0.1 # zaradi LNF

		var pull_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		pull_tween.tween_property(self, "position", intended_position, pull_cocktime)
		pull_tween.parallel().tween_property(skill_light, "energy", 0.5, pull_cocktime/2)
		pull_tween.parallel().tween_callback(stray_to_move, "pull_stray", [pull_direction, pull_time]) # kličem tukaj, da animiram njegov collision_ext
		pull_tween.parallel().tween_callback(self, "play_sound", ["pulled"])
		pull_tween.tween_property(skill_light, "position", Vector2.ZERO, pull_time) # lučko zapeljem nazaj na začetno lokacijo
		yield(pull_tween, "finished")
#		skill_light.energy = 1

		# če še drži tipko ponovno povleči, če ne end_move
		if not first_skill_use: # še drži tipko
			skill_light_on()
			pull(stray_to_move)
		else:
			end_move()

		_change_stat("skill_used", 2)


func teleport():

	var teleport_direction = direction

	current_state = STATES.SKILLING

	previous_position = global_position

	# teleporting ghost
	var new_teleport_ghost = spawn_ghost(global_position)
	new_teleport_ghost.direction = teleport_direction
	new_teleport_ghost.modulate.a = new_teleport_ghost.teleporting_alpha
	new_teleport_ghost.z_index = 3
	new_teleport_ghost.connect("ghost_target_reached", self, "_on_ghost_target_reached")

	# kamera target
	if player_camera and not Global.game_manager.game_settings ["zoom_to_level_size"]:
		player_camera.camera_target = new_teleport_ghost
	collision_shape.set_deferred("disabled", true)

	#	yield(get_tree().create_timer(teleporting_start_delay), "timeout")
	skill_light_off()
	Input.start_joy_vibration(0, 0.3, 0, 0)
	play_sound("teleport")
	modulate.a = 0

	# zaključek v signalu _on_ghost_target_reached


# ON HIT ------------------------------------------------------------------------------------------


func on_hit_stray(hit_stray: Node2D):

	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("hit_stray")
	spawn_collision_particles()
	shake_player_camera(burst_speed)

	# start sweeper move
	if Global.game_manager.game_settings["reburst_mode"] and not sweep_started:
		sweep_started = true

	if hit_stray.current_state == hit_stray.STATES.DYING: # če je že v umiranju, samo kolajdaš
		end_move()
	elif hit_stray.current_state == hit_stray.STATES.WHITE:
		end_move()
	else:
		# izklopim če začne bel
		tween_color_change(hit_stray.stray_color)
		var burst_speed_units_count: int = int(burst_speed / cock_ghost_speed_addon)
		# sweeper  ... prvi burst poda hitrost za vse sledeči reburste
		if is_in_reburst:
			# upoštevam prvi burst
			if Global.game_manager.game_settings["reburst_hit_power"] == 0:
				burst_speed_units_count = reburst_speed_units_count
			# upoštevam presetano moč
			else:
				burst_speed_units_count = Global.game_manager.game_settings["reburst_hit_power"]
		else:
			reburst_speed_units_count = burst_speed_units_count

		# preverim sosede
		var hit_stray_neighbors: Array = check_strays_neighbors(hit_stray)
		var all_neighboring_strays: Array = hit_stray_neighbors[0]
		var white_strays_in_stack: Array = hit_stray_neighbors[1]

		# naberem strayse za destrojat
		var strays_to_destroy: Array = []
		strays_to_destroy.append(hit_stray)
		if not all_neighboring_strays.empty():
			for neighboring_stray in all_neighboring_strays: # še sosedi glede na moč bursta
				if strays_to_destroy.size() < burst_speed_units_count or burst_speed_units_count == cocked_ghost_max_count:
					strays_to_destroy.append(neighboring_stray)
				else: break

		self.strays_on_start_count -= strays_to_destroy.size() # za sweeper za hitro zabeležim uspeh pleyerja

		# jih destrojam
		var throttler_start_msec = Time.get_ticks_msec()
		for stray in strays_to_destroy:

			# netrotlano
			var stray_index = strays_to_destroy.find(stray)
			stray.call_deferred("die", stray_index, strays_to_destroy.size()) # podatek o velikosti rabi za izbor animacije
			#			stray.die(stray_index, strays_to_destroy.size()) # podatek o velikosti rabi za izbor animacije
			var msec_taken = Time.get_ticks_msec() - throttler_start_msec
			# trotled
			#			if msec_taken < (round(1000 / Engine.get_frames_per_second()) - Global.throttler_msec_threshold): # msec_per_frame - ...
			#				print ("ne-trotlam - multi stray destroy")
			#				var stray_index = strays_to_destroy.find(stray)
			#				stray.die(stray_index, strays_to_destroy.size()) # podatek o velikosti rabi za izbor animacije
			#			else:
			#				print ("re-trotlam - multi stray destroy")
			#				var msec_to_next_frame: float = Global.throttler_msec_threshold + 1
			#				var sec_to_next_frame: float = msec_to_next_frame / 1000.0
			#				yield(get_tree().create_timer(sec_to_next_frame), "timeout") # da se vsi straysi spawnajo
			#				throttler_start_msec = Time.get_ticks_msec()

		# stats
		var strays_not_walls_count: int = strays_to_destroy.size() - white_strays_in_stack.size()
		_change_stat("hit_stray", [strays_not_walls_count, white_strays_in_stack.size()])

		end_move()

		if sweep_started:
			reburst_window_open = true
			burst_light_on()
			rebursting_timer.stop() # ... reset zazih
			rebursting_timer.call_deferred("start", Global.game_manager.game_settings["reburst_window_time"])


func on_hit_player(hit_player: KinematicBody2D):

	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("hit_stray")
	spawn_collision_particles()
	shake_player_camera(burst_speed)

	# korekcija pozicije
	var player_direction = direction # za korekcijo
	global_position = hit_player.global_position + (cell_size_x * (- player_direction)) # plejer eno polje ob zadetem

	# opredeli zmagovalca
	if burst_speed == hit_player.burst_speed: # neodločeno
		end_move()
		hit_player.end_move() # plejer, ki prvi zazna kontakt ukaže naprej, da je zaporedje pod kontrolo

	elif burst_speed > hit_player.burst_speed: # zmaga
		if not hit_player.pixel_color == Global.game_manager.game_settings["player_start_color"]: # če nima nobene barve mu je ne prevzamem
			tween_color_change(hit_player.pixel_color)
		end_move()
		_change_stat("hit_player", hit_player.player_stats["player_points"]) # točke glede na delež loserjevih točk, energija se resetira na 100%
		hit_player.on_get_hit(burst_speed) # po statistiki, da winer pobere od luserja, ko so točke še polne


func on_hit_wall():

	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	play_sound("hit_wall")
	spawn_dizzy_particles()
	spawn_collision_particles()
	shake_player_camera(burst_speed)

	_change_stat("hit_wall", 1)
	end_move()


func on_get_hit(hit_burst_speed: float):

	# efekti
	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	play_sound("hit_wall")
	spawn_dizzy_particles()
	shake_player_camera(hit_burst_speed)

	pixel_color = Global.game_manager.game_settings["player_start_color"] # postane začetne barve
	_change_stat("get_hit", 1)
	end_move()

	collision_shape.set_deferred("disabled", true)


# LIFE LOOP ----------------------------------------------------------------------------------------


func die(): # kliče statistika

	end_move()

#	set_process(false)
	set_physics_process(false)
	animation_player.stop()
	animation_player.play("die_player")


func revive(off_time: float = 0):

	if off_time > 0:
		yield(get_tree().create_timer(off_time), "timeout")
	animation_player.play("revive")


# SPAWNING ------------------------------------------------------------------------------------------


func spawn_dizzy_particles():

	var new_dizzy_pixels = PixelDizzyParticles.instance()
	new_dizzy_pixels.global_position = global_position
	if pixel_color == Global.game_manager.game_settings["player_start_color"]:
		new_dizzy_pixels.modulate = Color.white
	else:
		new_dizzy_pixels.modulate = pixel_color
	Global.game_arena.add_child(new_dizzy_pixels)


func spawn_collision_particles():

	var new_collision_pixels = PixelCollisionParticles.instance()
	new_collision_pixels.global_position = global_position
	if pixel_color == Global.game_manager.game_settings["player_start_color"]:
		new_collision_pixels.modulate = Color.white
	else:
		new_collision_pixels.modulate = pixel_color
	match direction:
		Vector2.UP: new_collision_pixels.rotate(deg2rad(-90))
		Vector2.DOWN: new_collision_pixels.rotate(deg2rad(90))
		Vector2.LEFT: new_collision_pixels.rotate(deg2rad(180))
		Vector2.RIGHT:new_collision_pixels.rotate(deg2rad(0))
	Global.game_arena.add_child(new_collision_pixels)


func spawn_cock_ghost(cocking_direction: Vector2):

	var cocked_ghost_alpha: float = 0.7 # najnižji alfa za ghoste ... old 0.55
	var cocked_ghost_alpha_divider: float = 5 # faktor nižanja po zaporedju (manjši je bolj oster) ... old 14

	# spawn ghosta pod manom
	var cock_ghost_position = (global_position - cocking_direction * cell_size_x/2) + (cocking_direction * cell_size_x * (cocked_ghosts.size() + 1)) # +1, da se ne začne na pixlu
	var new_cock_ghost = spawn_ghost(cock_ghost_position)
	new_cock_ghost.z_index = 3 # nad straysi in playerjem
	new_cock_ghost.modulate.a  = cocked_ghost_alpha - ((cocked_ghosts.size()) / cocked_ghost_alpha_divider)
	new_cock_ghost.direction = cocking_direction

	# v kateri smeri je scale
	if direction.y == 0: # smer horiz
		new_cock_ghost.scale.x = 0
	elif direction.x == 0: # smer ver
		new_cock_ghost.scale.y = 0

	# animiram cock celico
	var cock_cell_tween = get_tree().create_tween()
	cock_cell_tween.tween_property(new_cock_ghost, "scale", Vector2.ONE, cock_ghost_cocking_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cock_cell_tween.parallel().tween_property(new_cock_ghost, "position", global_position + cocking_direction * cell_size_x * (cocked_ghosts.size() + 1), cock_ghost_cocking_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# ray detect velikost je velikost napenjanja
	new_cock_ghost.cocking_ray.cast_to = direction * cell_size_x
	new_cock_ghost.connect("ghost_detected_body", self, "_on_ghost_detected_body")

	return new_cock_ghost


func spawn_trail_ghost():

	var trail_alpha: float = 0.25
	var trail_ghost_fade_time: float = 0.4
	var new_trail_ghost = spawn_ghost(global_position)
	new_trail_ghost.modulate = pixel_color
	new_trail_ghost.modulate.a = trail_alpha

	# fadeout
	var trail_fade_tween = get_tree().create_tween()
	trail_fade_tween.tween_property(new_trail_ghost, "modulate:a", 0, trail_ghost_fade_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	trail_fade_tween.tween_callback(new_trail_ghost, "queue_free")


func spawn_ghost(ghost_spawn_position: Vector2):

	var new_pixel_ghost = Ghost.instance()
	new_pixel_ghost.global_position = ghost_spawn_position
	new_pixel_ghost.modulate = pixel_color
	new_pixel_ghost.ghost_owner = self # da "sebe" ne čekira
	Global.game_arena.add_child(new_pixel_ghost)

	return new_pixel_ghost


func spawn_floating_tag(value: int):

	var text_to_show: String = ""
	var text_color: Color = Color.white
	if value == 0:
		if game_data["game"] == Profiles.Games.DEFENDER: # 1 točka ni nikoli
			text_to_show = "HERE I AM"
		else:
			return
	elif value == 1:
		text_to_show = "YEAH!"
	elif value < 0:
		text_color = Global.color_red
		text_to_show = str(value)
	elif value > 0:
		text_to_show = "+" + str(value)

	var new_floating_tag = FloatingTag.instance()
	new_floating_tag.z_index = 4 # višje od straysa in playerja
	new_floating_tag.global_position = global_position
	new_floating_tag.tag_owner = self
	new_floating_tag.modulate = text_color
	Global.game_arena.add_child(new_floating_tag)

	new_floating_tag.label.text = text_to_show

	return new_floating_tag


# UTIL --------------------------------------------------------------------------------------------


func on_out_of_bounds():

	# ugasnem plejerja
	hide()
#	set_process(false)
	set_physics_process(false)

	# izžrebam novo pozicijo
	var random_index: int = randi() % Global.game_manager.free_floor_positions.size()
	var new_random_position: Vector2 = Global.game_manager.free_floor_positions[random_index]
	yield(get_tree().create_timer(0.1), "timeout")

	# premaknem plejerja
	global_position = new_random_position + Vector2(cell_size_x/2, cell_size_x/2)

	# ga prikažem (od bele do pixel barve)
	var current_color: Color = pixel_color
	pixel_color = Color.white
	modulate.a = 0
	show()

	var fade_in = get_tree().create_tween()
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	fade_in.tween_property(self, "pixel_color", current_color, 0.5).set_ease(Tween.EASE_IN).set_delay(0.5)
	fade_in.parallel().tween_callback(self, "burst_light_on")
	fade_in.tween_callback(self, "burst_light_off")#.set_delay(0.2)

	# spawn_floating_tag(0) # KUKU! ... neki ne dela
#	set_process(true)
	set_physics_process(true)
	end_move()


func _detect_touching_objects():

	var current_player_neighbors: Array # sosedi v tem koraku

	# preverim vsako areo, če ima straysa ali kak drug objekt, ki omejuje gibanje
	var areas_touching: Array = []

	for area in touch_detect_areas.get_children():
		var objects_touched: Array = area.get_overlapping_bodies()
		objects_touched.append_array(area.get_overlapping_areas())
		if not objects_touched.empty():
			for body in objects_touched:
				if body.is_in_group(Global.group_strays) or body.is_in_group(Global.group_tilemap):
					current_player_neighbors.append_array(objects_touched)
					areas_touching.append(area)
					break

	return [areas_touching, current_player_neighbors]


func _check_for_surrounded(surrounding_objects: Array):

	# surrounded
	var areas_touching: Array = surrounding_objects[0]
	var current_player_neighbors: Array = surrounding_objects[1]

	if areas_touching.size() == touch_detect_areas.get_child_count():
		# če je še vedno obkoljen, preverim še istost sosedov > GO
		if is_surrounded:
			# če so sosedi isti je GO
			if surrounded_player_strays == current_player_neighbors:
				Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)
			# če niso isti, restiram sosede in potem normalno naprej
			else:
				surrounded_player_strays = []
				is_surrounded = false
				touch_timer.start(detect_touch_pause_time)
		# če je prvič obkoljen, ga označim za obkoljenega in zapišem sosede
		else:
			is_surrounded = true
			surrounded_player_strays = current_player_neighbors
			touch_timer.start(is_surrounded_time) # daljši čas

	# not surrounded
	else:
		surrounded_player_strays = []
		is_surrounded = false # resetiram
		touch_timer.start(detect_touch_pause_time)

#	print("areas_touching", areas_touching)



#func detect_touch():
#
#	var current_player_strays: Array # sosedi v tem koraku
#
#	# preverim vsako areo, če ima straysa ali kak drug objekt, ki omejuje gibanje
#	var areas_touching: Array = []
#
#	for area in touch_detect_areas.get_children():
#		var objects_touched: Array = area.get_overlapping_bodies()
#		objects_touched.append_array(area.get_overlapping_areas())
#		if not objects_touched.empty():
#			for body in objects_touched:
#				if body.is_in_group(Global.group_strays) or body.is_in_group(Global.group_tilemap):
#					current_player_strays.append_array(objects_touched)
#					areas_touching.append(area)
#					break
#
#	# surrounded
#	if areas_touching.size() == touch_detect_areas.get_child_count():
#		# če je še vedno obkoljen, preverim še istost sosedov > GO
#		if is_surrounded:
#			# če so sosedi isti je GO
#			if surrounded_player_strays == current_player_strays:
#				Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)
#			# če niso isti, restiram sosede in potem normalno naprej
#			else:
#				surrounded_player_strays = []
#				is_surrounded = false
#				touch_timer.start(detect_touch_pause_time)
#		# če je prvič obkoljen, ga označim za obkoljenega in zapišem sosede
#		else:
#			is_surrounded = true
#			surrounded_player_strays = current_player_strays
#			touch_timer.start(is_surrounded_time) # daljši čas
#	# not surrounded
#	else:
#		surrounded_player_strays = []
#		is_surrounded = false # resetiram
#		touch_timer.start(detect_touch_pause_time)
#
##	print("areas_touching", areas_touching)

func get_step_time():

	if Global.game_manager.game_settings["step_slowdown_mode"]:
		var slow_trim_size: float = step_time_slow * player_max_energy
		var energy_factor: float = (player_max_energy - slow_trim_size) / player_stats["player_energy"]
		var energy_step_time = energy_factor / step_slowdown_rate # variabla, da FP ne kliče na vsak frejm
		return clamp(energy_step_time, step_time, step_time_slow) # omejim najbolj počasno korakanje
	else:
		return step_time


func shake_player_camera(current_burst_speed: float):

	var shake_multiplier: float = current_burst_speed / cock_ghost_speed_addon
	var shake_multiplier_factor: float = 0.03

	var shake_power: float = 0.15
	var shake_power_multiplied: float = shake_power + shake_multiplier_factor * shake_multiplier
	var shake_time: float = 0.2
	var shake_time_multiplied: float = shake_time + shake_multiplier_factor * shake_multiplier
	var shake_decay: float = 0.7

	player_camera.shake_camera(shake_power_multiplied, shake_time_multiplied, shake_decay)


func check_strays_neighbors(hit_stray: Node2D):

		var all_neighboring_strays: Array = [] # vsi nabrani sosedi
		var neighbors_checked: Array = [] # vsi sosedi, katerih sosede sem že preveril
		var white_neighbours: Array
		var hit_direction = direction

		# sosedi zadetega straya
		var first_neighbors: Array = hit_stray.get_neighbor_strays_on_hit() # hit direction je zato da opredelim smer preverjanja sosedov
		for first_neighbor in first_neighbors:
			# zaznam belega
			if first_neighbor.current_state == first_neighbor.STATES.WHITE:
				if not white_neighbours.has(first_neighbor):
					white_neighbours.append(first_neighbor)
			# če še ni dodan med vse sosede ... ga dodam
			if not all_neighboring_strays.has(first_neighbor):
				all_neighboring_strays.append(first_neighbor)
		# zadeti stray je ravno preverjen
		neighbors_checked.append(hit_stray)

		# sosedi vseh sosed (svi goli pa ko šta voli)
		for neighbor in all_neighboring_strays:
			# iz preverke izločim že preverjane in bele pixle
			if not neighbors_checked.has(neighbor) and not white_neighbours.has(neighbor):
				# naberem sosede
				var extra_neighbors: Array = neighbor.get_neighbor_strays_on_hit()
				# in jih preverim preverim še te sosede
				for extra_neighbor in extra_neighbors:
					# zaznam belega
					if neighbor.current_state == neighbor.STATES.WHITE:
						if not white_neighbours.has(neighbor):
							white_neighbours.append(neighbor)
					# če še ni dodan med vse sosede ... ga dodam
					if not all_neighboring_strays.has(extra_neighbor):
						all_neighboring_strays.append(extra_neighbor)
				# sosed je preverjen
				neighbors_checked.append(neighbor)

		# hit stray izbrišem iz sosed, ker bo uničen posebej
		if all_neighboring_strays.has(hit_stray):
			all_neighboring_strays.erase(hit_stray)

		return [all_neighboring_strays, white_neighbours]


func tween_color_change (new_color: Color):

	change_to_color = new_color # če kokam pred končanjem tweena, vzamem to barvo

	change_color_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	change_color_tween.tween_property(self, "pixel_color", new_color, 0.5).set_ease(Tween.EASE_IN) #.set_trans(Tween.TRANS_CIRC)


func burst_light_on():

	if not burst_light.enabled:

		burst_light.enabled = true

	var burst_light_base_energy: float = 0.6
	var burst_light_energy: float = burst_light_base_energy / pixel_color.v
	burst_light_energy = clamp(burst_light_energy, 0.5, 1.4) # klempam za dark pixel

	var light_fade_in = get_tree().create_tween()
	light_fade_in.tween_property(burst_light, "energy", burst_light_energy, 0.2).set_ease(Tween.EASE_IN)


func burst_light_off():

	if burst_light.enabled:
		var light_fade_out = get_tree().create_tween()
		light_fade_out.tween_property(burst_light, "energy", 0, 0.3).set_ease(Tween.EASE_IN)
		light_fade_out.tween_callback(burst_light, "set_enabled", [false])


func skill_light_on():
#	return
	if not skill_light.enabled:

		# setam smer glede na smer vision raya
		var light_rotation_degrees: float
		if vision_ray.cast_to.x > 0 and vision_ray.cast_to.y == 0:
			light_rotation_degrees = 0
		elif vision_ray.cast_to.x < 0 and vision_ray.cast_to.y == 0:
			light_rotation_degrees = 180
		elif vision_ray.cast_to.y > 0 and vision_ray.cast_to.x == 0:
			light_rotation_degrees = 90
		elif vision_ray.cast_to.y < 0 and vision_ray.cast_to.x == 0:
			light_rotation_degrees = -90
		skill_light.rotation_degrees = light_rotation_degrees

		var skilled_light_base_energy: float = 0.7
		var skilled_light_energy: float = skilled_light_base_energy / pixel_color.v
		skilled_light_energy = clamp(skilled_light_energy, 0.5, 1.3) # klempam za dark pixel

		var light_fade_in = get_tree().create_tween()
		light_fade_in.tween_callback(skill_light, "set_enabled", [true])
		light_fade_in.tween_property(skill_light, "energy", skilled_light_energy, 0.2).set_ease(Tween.EASE_IN)


func skill_light_off():

	if skill_light.enabled:
		var light_fade_out = get_tree().create_tween()
		light_fade_out.tween_property(skill_light, "energy", 0, 0.3).set_ease(Tween.EASE_IN)
		light_fade_out.tween_callback(skill_light, "set_enabled", [false])


func on_screen_cleaned(): # kliče GM

	close_reburst_window()
	animation_player.play("become_white")
	_change_stat("all_cleaned", 1) # nagrada je določena v settingsih
	emit_signal("rewarded_on_cleaned") # javi v GM ... signal pošljem tudi na koncu animacije, za tiste igre, ki tega zgrešijo


# SOUNDS ------------------------------------------------------------------------------------------


func play_stepping_sound(current_player_energy_part: float):

	if not Global.sound_manager.game_sfx_set_to_off:
		var random_step_index = randi() % $Sounds/Stepping.get_child_count()
		var selected_step_sound = $Sounds/Stepping.get_child(random_step_index)
		selected_step_sound.pitch_scale = clamp(current_player_energy_part, 0.6, 1)
		selected_step_sound.play()


func play_sound(effect_for: String):

	if not Global.sound_manager.game_sfx_set_to_off:

		match effect_for:
			"blinking":
				var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
				$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
				var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
				$Sounds/BlinkingStatic.get_child(random_static_index).play()
			# bursting
			"hit_stray":
				$Sounds/Burst/HitStray.play()
			"hit_wall":
				$Sounds/Burst/HitWall.play()
				$Sounds/Burst/HitDizzy.play()
			"burst":
				yield(get_tree().create_timer(0.1), "timeout")
				$Sounds/Burst/Burst.play()
				$Sounds/Burst/BurstLaser.play()
			"burst_cocking":
				if not $Sounds/Burst/BurstCocking.is_playing():
					$Sounds/Burst/BurstCocking.play()
			"burst_uncocking":
				if not $Sounds/Burst/BurstUncocking.is_playing():
					$Sounds/Burst/BurstUncocking.play()
			"burst_stop":
				$Sounds/Burst/BurstStop.play()
			# skills
			"pushpull_start":
				$Sounds/Skills/PushPull.play()
			"pushpull_end":
				$Sounds/Skills/PushedPulled.play()
			"pulled":
				$Sounds/Skills/StoneSlide.play()
			"pushed":
				$Sounds/Skills/StoneSlide.play()
			"teleport":
				$Sounds/Skills/TeleportIn.play()


func stop_sound(stop_effect_for: String):

	match stop_effect_for:
		"teleport":
			if $Sounds/Skills/TeleportLoop.is_playing(): # konec teleportanja
				$Sounds/Skills/TeleportLoop.stop()
				$Sounds/Skills/TeleportOut.play()
			else: # zazih ob koncu igre
				$Sounds/Skills/TeleportLoop.stop()
		"burst_cocking":
			if $Sounds/Burst/BurstCocking.is_playing():
				$Sounds/Burst/BurstCocking.stop()
		"burst_uncocking":
			$Sounds/Burst/BurstUncocking.stop()


# SIGNALI ---------------------------------------------------------------------------------------------


func _change_strays_on_start(new_count):
	#	print("artificial stray count ", strays_on_start_count)

	strays_on_start_count = new_count
	if strays_on_start_count == 0:
		end_move()
#		set_process(false)
		set_physics_process(false)


func _on_SkilledTimer_timeout() -> void:

	first_skill_use = false # idle input postane "on_pressed", kar povzroči, da player postan SKILLED


func _on_ReburstingTimer_timeout() -> void:

	if Global.game_manager.game_settings["reburst_window_time"] > 0:
		# čas zamujen ... ne moreš več reburstat
		close_reburst_window(true)


func _on_TouchTimer_timeout() -> void:


	var curr_touching_objects: Array = _detect_touching_objects()
	_check_for_surrounded(curr_touching_objects)
#	detect_touch() # za GO


func _on_ghost_target_reached(ghost_body: Area2D, ghost_position: Vector2):

	stop_sound("teleport")
	Input.stop_joy_vibration(0)


	# premaknem plejerja in ga setam
	var intended_position: Vector2 = ghost_position
	Global.game_manager.remove_from_free_floor_positions(intended_position)
	global_position = intended_position

	# after premik
	modulate.a = 1
	if player_camera and not Global.game_manager.game_settings ["zoom_to_level_size"]:
		player_camera.camera_target = self
	glow_light.enabled = true
	collision_shape.set_deferred("disabled", false)
	ghost_body.queue_free()
	end_move()

	_change_stat("skill_used", 3)


func _on_ghost_detected_body(body: Node2D):
#	print ("COL", body)
	if body != self:
		cocking_room = false


func _on_TeleportIn_finished() -> void:

	$Sounds/Skills/TeleportLoop.play()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:

	match anim_name:
		"lose_white_on_start":
			# setam looknfeel playerja ob štartu FP
			color_poly.modulate = pixel_color
			var player_fade_in = get_tree().create_tween()
			player_fade_in.tween_property(self, "modulate:a", 1, 0.2)
			player_fade_in.parallel().tween_property(glow_light, "energy", 1.5, 0.5)
			emit_signal("player_pixel_set")
			Global.game_manager.remove_from_free_floor_positions(global_position) # zazih, če ni spucal ob spawnanju
		"die_player":
			if player_stats["player_life"] > 0:
				var dead_time: float = 0.3
				revive(dead_time)
			else:
				Global.game_manager.game_over(Global.game_manager.GameoverReason.LIFE)
		"revive":
#			set_process(true)
			set_physics_process(true)
			_change_stat("revive", 1) # če energija = 0 (izguba lajfa), resetira energijo
		"become_white":
			emit_signal("rewarded_on_cleaned") # javi v GM


func _on_Player_tree_entered() -> void:

	Global.game_manager.remove_from_free_floor_positions(global_position)


func _on_Player_tree_exiting() -> void:

	Global.game_manager.add_to_free_floor_positions(global_position)


# STATS ----------------------------------------------------------------------------------------------


func _change_stat(stat_event: String, stat_value):

	if Global.game_manager.game_on or stat_event == "all_cleaned": # statistika se ne beleži več, razen "all_cleaned"

		match stat_event:

			# SKILL & BURST ---------------------------------------------------------------------------------------------------------------
			"cells_traveled": # štetje, točke in energija kot je določeno v settingsih
				player_stats["cells_traveled"] += 1
				player_stats["player_energy"] += game_settings["cell_traveled_energy"]
			"skill_used": # štetje, točke in energija kot je določeno v settingsih
				player_stats["skill_count"] += 1
				if Global.tutorial_gui.tutorial_on:
					Global.tutorial_gui.on_skill_used(stat_value)
			"burst_count": # štetje, točke in energija kot je določeno v settingsih
				player_stats["burst_count"] += stat_value
			# HITS ------------------------------------------------------------------------------------------------------------------
			"hit_stray": # štetje, točke in energija glede na število uničenih straysov
				var points_to_gain: int = 0
				var energy_to_gain: int = 0
				# colored
				var stack_strays_cleaned_count: int = stat_value[0]
				for stray_in_row in stack_strays_cleaned_count:
					energy_to_gain += game_settings["color_picked_energy"] * (stray_in_row + 1)
					points_to_gain += game_settings["color_picked_points"] * (stray_in_row + 1) # + 1 je da se izognem nuli
				player_stats["player_energy"] += energy_to_gain
				player_stats["colors_collected"] += stack_strays_cleaned_count
				# whites
				var whites_eliminated_count: int = stat_value[1]
				if whites_eliminated_count > 0:
					player_stats["player_energy"] = player_max_energy
					points_to_gain += whites_eliminated_count * game_settings["white_eliminated_points"]
				# vse skupaj
				player_stats["player_points"] += points_to_gain
				spawn_floating_tag(points_to_gain)
				if Global.tutorial_gui.tutorial_on:
					Global.tutorial_gui.on_hit_stray(stack_strays_cleaned_count)
			"white_eliminated":
				player_stats["player_energy"] = player_max_energy
				var points_to_gain: int = game_settings["white_eliminated_points"]
				player_stats["player_points"] += points_to_gain
				spawn_floating_tag(points_to_gain)
			"hit_player": # točke glede na delež loserjevih točk, energija se resetira na 100%
				var hit_player_current_points: int = stat_value
				player_stats["player_energy"] = player_max_energy
				var on_get_hit_points_part: float = 0.5
				var points_to_gain: int = round(hit_player_current_points * on_get_hit_points_part)
				player_stats["player_points"] += points_to_gain
				spawn_floating_tag(points_to_gain)
			"hit_wall":
				player_stats["player_energy"] *= Global.game_manager.game_settings["on_hit_wall_energy_factor"]
				if player_stats["player_energy"] > 0:
#					set_process(false)
					set_physics_process(false)
					revive()
			"get_hit":
				# izgubi vso energijo in lajf, ter pol točk
				player_stats["player_energy"] *= Global.game_manager.game_settings["on_get_hit_energy_factor"]
				if player_stats["player_energy"] > 0:
#					set_process(false)
					set_physics_process(false)
					revive()
				# points
				var on_get_hit_points_part: float = 0.5
				var points_to_lose = round(player_stats["player_points"] * on_get_hit_points_part)
				player_stats["player_points"] -= points_to_lose
				spawn_floating_tag(- points_to_lose)

			# LIFE LOOP ------------------------------------------------------------------------------------------------------------

			"revive": # resetiranje energije, če je izgubil lajfa (energija = 0)
				if player_stats["player_energy"] == 0:
					player_stats["player_energy"] = player_max_energy
			"all_cleaned": # nagrada je določena v settingsih
				var cleaned_reward: int = game_settings["cleaned_reward_points"]
				if cleaned_reward > 1:
					cleaned_reward = player_stats["player_points"] # ker je v tem trenutku že naslednji level
					player_stats["player_points"] += cleaned_reward
				var reward_tag: Node = spawn_floating_tag(cleaned_reward)

		# pošiljanje
		player_stats["player_energy"] = round(player_stats["player_energy"])
		player_stats["player_energy"] = clamp(player_stats["player_energy"], 0, player_max_energy)
		player_stats["player_points"] = clamp(player_stats["player_points"], 0, player_stats["player_points"])

		# die zaradi 0 energije
		if player_stats["player_energy"] == 0:
			player_stats["player_life"] -= 1
			die()

		emit_signal("stat_changed", self, player_stats) # javi v hud
