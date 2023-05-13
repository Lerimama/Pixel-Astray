class_name Pixel
extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change)

# states
enum States {
	WHITE = 1, # steping
	BLUE, # burst 
	GREEN, # bump 
	RED, 
	YELLOW,
} 
var state_colors: Dictionary = {
	1: Config.color_white, 
	2: Config.color_blue, 
	3: Config.color_green, 
	4: Config.color_red, 
	5: Config.color_yellow,
}	
var skill_activated: bool = false
var current_state : int = States.WHITE setget _change_state # tole je int ker je rezultat številka
var pixel_color = state_colors[current_state]

# testing modes
export var slide_mode: bool = false # slajdanje če držiš smerno tipko
export var dir_memory_mode: bool = false# reset direction

# arena
var cell_size_x: int # pogreba od arene, ki jo dobi od tilemapa
var floor_cells: Array = []

# steping
var running_frame_skip: int = 2 # za kontrolo hitrosti
var frame_counter: int # pseudo time 
var step_time: float = 0.15 # tween time
var step_cell_count: int = 1 # je naslednja

# motiion
var speed: float = 0
#var max_speed: float = 10 # ker je na vseh pixlih, ampak tu ne rabim
#var accelaration: float = 500 # ne rabim ... ampak je na vseh pixlih
var velocity: Vector2
var direction = Vector2.ZERO
var collision: KinematicCollision2D
	
# skills
var burst_speed = 50
var burst_time = 0.3
var ghost_fade_time = 0.2
var pull_time: float = 0.6
var pull_cell_count: int = 1

var new_tween: SceneTreeTween
	
onready var poly_pixel: Polygon2D = $PolyPixel
onready var collision_ray: RayCast2D = $RayCast2D
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var collision_shape: CollisionShape2D = $CollisionShape2D

onready var PixelGhost = preload("res://scenes/PixelGhost.tscn")


# player stats
var color_change_count = 0

var push_time = 0.5
var push_cell_count = 1

func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Config.group_players)
	
	# snap it
	cell_size_x = Global.game_manager.grid_cell_size.x # get cell size
	global_position = global_position.snapped(Vector2.ONE * cell_size_x)
	global_position += Vector2.ONE * cell_size_x/2 # zamik centra


func _physics_process(delta: float) -> void:
	
	state_machine()
	modulate = state_colors[current_state]
			
	frame_counter += 1
	
	# dokler je speed 0, je velocity tudi 0 v tweenih speed se regulira v tweenu
	velocity = direction * speed # 
	move_and_collide(velocity) 
	
	if collision:
#		velocity = velocity.bounce(collision.normal)
		print("KOLIZIJA")

	
func state_machine():
	
	# ne manjaj stanj sredi akcije
	if skill_activated:
		return
#	if skill_tween != null:
#		if skill_tween.is_running():
#			return
		
	match current_state: 
		States.WHITE:
			if slide_mode:
				slide_inputs()
			else:
				step_inputs()
		States.BLUE:
			push_control()
		States.GREEN: 
			pull_control()
		States.RED:
			burst_control()
		States.YELLOW:
			teleport_control()
	
	# change state
	if Input.is_action_just_pressed("shift"):
		select_next_state()	
		
		
func select_next_state():
		# cilkanje v zaporedju
		
		if current_state < States.size():
			self.current_state = current_state + 1 
		else:		
			self.current_state = 1	


func _change_state(new_state_id):
	
	# set normal mode
	skill_activated = false
	direction = Vector2.ZERO
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
	collision_ray.force_raycast_update()	
	snap_to_nearest_grid()

	# transition
	
	# statistika
	color_change_count += 1
	emit_signal("stat_changed", self, "color_change_count", 1)
	print("Ppppppppppppppppppppppppp")
	# new state
	current_state = new_state_id


func step_inputs():
	
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.UP
		step(direction)
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.DOWN
		step(direction)
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.LEFT
		step(direction)
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.RIGHT
		step(direction)
	else:
		if not dir_memory_mode:
			direction = Vector2.ZERO
			# reset ray
			collision_ray.cast_to = direction * cell_size_x 
	
	if Input.is_action_pressed("space"):
		run()


func slide_inputs():

#	if event.get_action_strength("ui_right"): 
	
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
	else:
		if not dir_memory_mode:
			direction = Vector2.ZERO
			# reset ray
			collision_ray.cast_to = direction * cell_size_x 

	if Input.is_action_pressed("space"):
		run()


func step(step_direction): 
	
	# če vidi steno v planirani smeri
	if detect_wall(step_direction): # or skill_activated: ... nepotrebno, ker akcija se ne kliče avtmatično, če ni bela
		return	
		
	new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "position", global_position + step_direction * cell_size_x * step_cell_count, step_time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)	

		
func run(): 
	# premik samo, če je smerna tipka stisnjena
		
	# če vidi steno v planirani smeri
	if detect_wall(direction) or skill_activated: 
		return	
		
	if frame_counter % running_frame_skip == 0:
		global_position += direction * cell_size_x # premik za velikost celice


# SKILLS SEKCIJA ______________________________________________________________________________________________________________


func burst_control():
	
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.UP
		burst(direction)
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.DOWN
		burst(direction)
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.LEFT
		burst(direction)
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.RIGHT
		burst(direction)
	
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 


func burst(burst_direction):
	
	if detect_wall(burst_direction): 
		return	
	skill_activated = true
	
	new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "speed", burst_speed, burst_time * 2/3).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	new_tween.tween_property(self, "speed", 0, burst_time/3).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	new_tween.tween_property(poly_pixel, "position", poly_pixel.position + burst_direction * cell_size_x, 0.1)
	new_tween.tween_property(poly_pixel, "position", poly_pixel.position, 0.1)
	new_tween.tween_callback(self, "_change_state", [States.WHITE])
	new_tween.tween_property(self, "skill_activated", false, 0.01)

	
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
	
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 


func push(push_direction):
	
	if not detect_wall(push_direction) or skill_activated: # preverjam obstoj kolizijo s pixlom ... if collision_ray.is_colliding(): .. ne rabim
		return	
	skill_activated = true

	var backup_direction = - push_direction

	var ray_collider = collision_ray.get_collider()
	if not ray_collider.is_in_group(Config.group_strays):
		return
		
	# spawn ghost pod mano
	var new_pixel_ghost = PixelGhost.instance()
	new_pixel_ghost.global_position = global_position
	new_pixel_ghost.modulate = state_colors[current_state]
	Global.node_creation_parent.add_child(new_pixel_ghost)

	modulate.a = 0.5

	# premik vsega
	new_tween = get_tree().create_tween()
	# napnem
	new_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x * push_cell_count, push_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
	# spustim
	new_tween.tween_property(self, "position", global_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)	
	new_tween.tween_property(ray_collider, "position", ray_collider.global_position + push_direction * cell_size_x * push_cell_count, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
#	new_tween.parallel().tween_property(ray_collider, "position", ray_collider.global_position + push_direction * cell_size_x * push_cell_count, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(0.17)
#	new_tween.parallel().tween_property(new_pixel_ghost, "position", new_pixel_ghost.global_position + push_direction * cell_size_x * push_cell_count, push_time)
	new_tween.tween_callback(self, "_change_state", [States.WHITE])
#	new_tween.tween_callback(ray_collider, "select_next_state")
	new_tween.parallel().tween_callback(new_pixel_ghost, "queue_free")
	
	
func pull_control():
	
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.UP
		pull(direction)
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.DOWN
		pull(direction)
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.LEFT
		pull(direction)
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.RIGHT
		pull(direction)
	
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 


func pull(target_direction):
	# ray je usmerjen v smer 
	# če je tam tarča, spelje step()
	# če je prostor (preverja c stepu) se premakne stran od tarče
	# tarčina pozicija sledi pixlu
	# če je s se premakne v smer stran od nje
	
	if not detect_wall(target_direction) or skill_activated: # preverjam obstoj kolizijo s pixlom ... if collision_ray.is_colliding(): .. ne rabim
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
	
	modulate.a = 0.5
	
	# premik vsega
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
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 


func teleport(teleport_direction):
	
	# preverim če kolajda s steno
	if not detect_wall(teleport_direction) or skill_activated:
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
#	new_pixel_ghost.connect("ghost_target_reached", self, "_on_ghost_target_reached", [new_pixel_ghost])
	new_pixel_ghost.connect("ghost_target_reached", self, "_on_ghost_target_reached")


# UTILITI SEKCIJA ______________________________________________________________________________________________________________


func detect_wall(next_direction):
	
	collision_ray.cast_to = next_direction * cell_size_x # ray kaže na naslednjo pozicijo 
	collision_ray.force_raycast_update()	
	
	if collision_ray.is_colliding():
		return true


func snap_to_nearest_grid():
	
	floor_cells = Global.game_manager.available_positions
	var current_position = Vector2(global_position.x - cell_size_x/2, global_position.y - cell_size_x/2)
	
	# če ni že snepano
	if not floor_cells.has(current_position): 
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
	
	new_tween = get_tree().create_tween()
	new_tween.tween_property(self, "modulate:a", 0, ghost_fade_time)
	new_tween.tween_property(self, "global_position", ghost_position, 0.1)
	new_tween.tween_callback(self, "_change_state", [States.WHITE])
	new_tween.parallel().tween_callback(ghost_body, "fade_out")
	# deactivate skill
	new_tween.tween_property(self, "skill_activated", false, 0.01)

# SETGET ------------------------------------------------------------------------------------------------------------------------
		
#	#...
#	# Instead of using different functions and variables, we can now use a single variable 
#	# to manage the current state.
#	# Our character is jumping if they're on the ground and the player presses "move_up"
#	# If both conditions are met, the expression below will evaluate to `true`.
#	var is_jumping: bool = _state == States.ON_GROUND and Input.is_action_just_pressed("move_up")
#
#	# To change state, we change the value of the `_state` variable
#	if Input.is_action_just_pressed("glide") and _state == States.IN_AIR:
#		_state = States.GLIDING
#
#	# Canceling gliding.
#	if _state == States.GLIDING and Input.is_action_just_pressed("move_up"):
#		_state = States.IN_AIR
#
#	# Calculating horizontal velocity.
#	if _state == States.GLIDING:
#		_velocity.x += input_direction_x * glide_acceleration * delta
#		_velocity.x = min(_velocity.x, glide_max_speed)
#	else:
#		_velocity.x = input_direction_x * speed
#
#	# Calculating vertical velocity.
#	var gravity := glide_gravity if _state == States.GLIDING else base_gravity
#	_velocity.y += gravity * delta
#	if is_jumping:
#		var impulse = glide_jump_impulse if _state == States.GLIDING else jump_impulse
#		_velocity.y = -jump_impulse
#		_state = States.IN_AIR
#
#	# Moving the character.
#	_velocity = move_and_slide(_velocity, Vector2.UP)
#
#	# If we're gliding and we collide with something, we turn gliding off and the character falls.
#	if _state == States.GLIDING and get_slide_count() > 0:
#		_state = States.IN_AIR
#
#	if is_on_floor():
#		_state = States.ON_GROUND
	
