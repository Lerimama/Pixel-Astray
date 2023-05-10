extends KinematicBody2D

var decelaration
var force

var acceleration: Vector2 # = Vector2.ONE
var speed = 0
var velocity: Vector2

var direction = Vector2.ZERO

var faktor
var collision: KinematicCollision2D
var available_positions: Array = [0,0]

#var tile_size = 32

enum action_moves {BUMP}
var action_moves_inputs = {
	"space": 1, # bump
	} 
var step_inputs = {
	"ui_right": Vector2.RIGHT,
	"ui_left": Vector2.LEFT,
	"ui_up": Vector2.UP,
	"ui_down": Vector2.DOWN,
	} 
	
var speed_grow = 5
		
			
var cell_size: int = 32
onready var polygon_2d: Polygon2D = $Polygon2D
#onready var explosion_particles: Particles2D = $ExplosionParticles
onready var explosion_particles: Particles2D = $"../ExplosionParticles"
onready var pixel_2: KinematicBody2D = $"../Pixel2"
onready var explosion_particles_2: Particles2D = $"../ExplosionParticles2"
onready var animation_player: AnimationPlayer = $AnimationPlayer

	
		
func _ready() -> void:
	print("Jest sem ... ", name, global_position)
	position = position.snapped(Vector2.ONE * cell_size)
	position += Vector2.ONE * cell_size/2	
	pass
	
func _unhandled_input(event):
	for step_direction in step_inputs.keys():
#		if event.is_action_pressed(step_direction):
#			step(step_direction)
		if event.get_action_strength(step_direction):
			step(step_direction)
	for action_move in action_moves_inputs.keys():
#		if event.is_action_pressed(step_direction):
#			step(step_direction)
		if event.is_action_pressed(action_move):
			action_move(action_move)
		else:
			action_on = false
			
	
func step(direction):
	position += step_inputs[direction] * cell_size	

var action_on = false
func action_move(action):	
#	printt("action", action_moves_inputs[action])
	match action_moves_inputs[action]:
		1: 
			action_on = true
#			speed = 50
			direction = Vector2.RIGHT
			
			printt("Bump", action)
#			var current_position: Vector2 = global_position
#			var goal_position: Vector2 = Vector2(current_position.x + cell_size * 5, current_position.y )
#
			var bump_tween = get_tree().create_tween()
			bump_tween.tween_property(self,"speed", 100, 1)
			bump_tween.tween_property(self,"speed", 0, 1)
			


func _physics_process(delta: float) -> void:
	

	if action_on:
#		velocity = direction * delta * speed
#		move_and_collide(velocity) 
		position = position.snapped(Vector2.ONE * cell_size)
		position += Vector2.RIGHT * cell_size/2	
	else:
		
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
##	if collision:
##		velocity = velocity.bounce(collision.normal)
##		explosion_particles.emitting = true
##		explosion_particles_2.emitting = true
##		polygon_2d.visible = false
##		pixel_2.visible = false
	pass
