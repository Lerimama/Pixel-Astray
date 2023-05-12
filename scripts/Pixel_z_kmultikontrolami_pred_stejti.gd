#class_name Pixel_old
extends KinematicBody2D



# motion
var acceleration: Vector2 # = Vector2.ONE
var speed = 0
var velocity: Vector2
var collision: KinematicCollision2D
var direction = Vector2.ZERO

var pixel_color: Color = Color.white
var action_color_index = 1
var action_colors: Dictionary = {
	1: Config.color_blue, 
	2: Config.color_green, 
	3: Config.color_red, 
	4: Config.color_yellow,
	}

# floor
var cell_size_x: int # = 32 # pogreba od arene, ki jo dobi od tilemapa
var floor_cells: Array = [0,0]

# inputs
var action_moves_inputs = {
	"space": 0, # bump
	"ctrl": 2, 
	"shift": 3,
	"alt": 4,
	} 
var step_inputs = {
	"ui_right": Vector2.RIGHT,
	"ui_left": Vector2.LEFT,
	"ui_up": Vector2.UP,
	"ui_down": Vector2.DOWN,
	} 
	
onready var poly_sprite: Polygon2D = $Polygon2D
onready var collision_ray: RayCast2D = $RayCast2D
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var step_tween: Tween = $StepTween

var burst_frame_skip: float = 0.05 # za kotrolo hitrosti snapnega premikanja
var time: float 
	
# states
var action_on = false # ko izvajam uničevalno akcijo
var step_burst_on = false # ko izvajam uničevalno akcijo
var selected_action_index = 0

# STATES

enum States {WHITE = 1, BLUE, GREEN, RED, YELLOW }
enum Skills {BUMP = 1, BURST, PULL, GHOST}
enum Tricks {TELEPORT = 1, GHOST}
# kako deluje? Rezultat int, kličeš pa po imenu

# With a variable that keeps track of the current state, we don't need to add more booleans.
var current_state : int = States.WHITE # tole je int ker je rezultat šteivlka



func _ready() -> void:
	
	
	Global.print_id(self)
	modulate = action_colors[action_color_index]
	
	# get cell size
	cell_size_x = get_parent().grid_cell_size.x
	
	# snap
	position = position.snapped(Vector2.ONE * cell_size_x)
	position += Vector2.ONE * cell_size_x/2 # zamik centra

func get_input():

	#...
	# Instead of using different functions and variables, we can now use a single variable 
	# to manage the current state.
	# Our character is jumping if they're on the ground and the player presses "move_up"
	# If both conditions are met, the expression below will evaluate to `true`.
	var is_jumping: bool = _state == States.ON_GROUND and Input.is_action_just_pressed("move_up")

	# To change state, we change the value of the `_state` variable
	if Input.is_action_just_pressed("glide") and _state == States.IN_AIR:
		_state = States.GLIDING

	# Canceling gliding.
	if _state == States.GLIDING and Input.is_action_just_pressed("move_up"):
		_state = States.IN_AIR

	# Calculating horizontal velocity.
	if _state == States.GLIDING:
		_velocity.x += input_direction_x * glide_acceleration * delta
		_velocity.x = min(_velocity.x, glide_max_speed)
	else:
		_velocity.x = input_direction_x * speed

	# Calculating vertical velocity.
	var gravity := glide_gravity if _state == States.GLIDING else base_gravity
	_velocity.y += gravity * delta
	if is_jumping:
		var impulse = glide_jump_impulse if _state == States.GLIDING else jump_impulse
		_velocity.y = -jump_impulse
		_state = States.IN_AIR

	# Moving the character.
	_velocity = move_and_slide(_velocity, Vector2.UP)

	# If we're gliding and we collide with something, we turn gliding off and the character falls.
	if _state == States.GLIDING and get_slide_count() > 0:
		_state = States.IN_AIR

	if is_on_floor():
		_state = States.ON_GROUND


func _unhandled_input(event: InputEvent) -> void:
#func _input(event: InputEvent) -> void: # ta skos beleži miško
	
	if step_tween.is_active():
		return

	
	# step by step
	for step_action in step_inputs.keys():
#		if event.is_action_pressed(step_action):
		if event.get_action_strength(step_action):
			direction = step_inputs[step_action]
			step(direction)
		elif event.is_action_released(step_action):
			direction = Vector2.ZERO
			print ("direction", direction)
			collision_ray.cast_to = direction * cell_size_x

	# steps burst s smerjo ... v FP
	if event.get_action_strength("space"):
		step_burst_on = true
	elif event.is_action_released("space"):
		step_burst_on = false
	
	# bump ... v FP
	if event.get_action_strength("ctrl"):
		step_burst_on = true
	elif event.is_action_released("ctrl"):
		step_burst_on = false
	
	# action control	
#	for action_move in action_moves_inputs.keys():
#		if event.is_action_pressed(action_move):
##		if event.get_action_strength(action_move):
#			action_move(action_move)
#		elif event.is_action_released(action_move):
#			action_on = false
	# menjava barve
	if event.is_action_pressed("left_click") or event.is_action_pressed("ui_accept"):
		set_mode()


var selected_action

func _physics_process(delta: float) -> void:
	time += delta
#	print(time)
#	print(direction)
#	print(action_on)
	
	# speed burst v smeri
	if step_burst_on and time > burst_frame_skip:
		step(direction)
#		position += direction * cell_size_x # če je tukaj namesto v inputu se hitreje odziv
#		position = position.snapped(Vector2.ONE * cell_size_x)
		time = 0
	
	# bump v smeri
#	if selected_action == 1:
#		velocity = direction * delta * 5
#		move_and_collide(velocity) 
	
	else:
#		position = position.snapped(Vector2.ONE * cell_size_x)
		
		velocity = Vector2.ZERO
#	
#	print(available_positions)
	
##	direction = Vector2.ZERO
#	transform.x = direction
#	acceleration = transform.x * speed # transform.x je (-1, 0)
#	velocity += acceleration * delta	
#
#	collision = move_and_collide(velocity, false)
#	print(speed)
	if collision:
		velocity = velocity.bounce(collision.normal)
##		explosion_particles.emitting = true
##		explosion_particles_2.emitting = true
##		polygon_2d.visible = false
##		pixel_2.visible = false
	pass

func set_mode():
	action_color_index += 1
	if action_color_index > 4:
		action_color_index = 1	
	
#	selected_action = action_moves[action_color_index]
	modulate = action_colors[action_color_index]	
	
	

func set_direction(step_action):	 
	direction = step_inputs[step_action]
	step(direction)
	
	
func step(step_direction):
	
	# če ni stena naredi korak
	collision_ray.cast_to = direction * cell_size_x # ray kaže na naslednjo pozicijo 
	collision_ray.force_raycast_update()
	if not collision_ray.is_colliding():
		
		if step_burst_on:# brez animacije, kler mora bit natančen
			position += direction * cell_size_x # premik za velikost celice
		else:
			step_tween.interpolate_property(self, "position", position, position + direction * cell_size_x, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			step_tween.start()
	
	
func action_move(action_move_id):	
#	printt("action", action_moves_inputs[action])

#	match action_moves_inputs[action_move_id]:
	match action_move_id:
		1: 
			action_on = true
#			speed = 50
#			direction = Vector2.RIGHT
			
			printt("Bump", action_move_id)
			modulate = Color.red
#			var current_position: Vector2 = global_position
#			var goal_position: Vector2 = Vector2(current_position.x + cell_size * 5, current_position.y )
#
			var bump_tween = get_tree().create_tween()
			bump_tween.tween_property(self,"speed", 100, 1)
			bump_tween.tween_property(self,"speed", 0, 1)
		2:
			pass
		3:
			pass
		4: 
			pass
			
	#twin it
#	tween.interpolate_property(self, "position",
#	position, position + dir * tile_size,
#	1.0/speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
#	tween.start()

func _on_Button_pressed() -> void:
	action_colors
	pass # Replace with function body.
