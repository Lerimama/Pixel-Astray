extends KinematicBody2D

var decelaration
var force

var acceleration: Vector2 # = Vector2.ONE
var speed = 50
var velocity: Vector2
#onready var explosion_particles: Particles2D = $ExplosionParticles
onready var explosion_particles: Particles2D = $"../ExplosionParticles"

func _ready() -> void:

#	print("Žiu!. Moje ime je, ", name, "Moja identifikacija je: ", bolt_id)
#
#	# bolt 
##	bolt_sprite.self_mod1ulate = bolt_color
#	bolt_sprite.texture = bolt_sprite_texture
#	add_to_group(Config.group_bolts)	
#	axis_distance = bolt_sprite_texture.get_width()
##	bolt_index ... se določi iz spawnerja
#
#	engines_setup() # postavi partikle za pogon
#
#	# shield
#	shield.modulate.a = 0 
#	shield_collision.disabled = true 
#	shield.self_modulate = bolt_color 
#
#	# bolt wiggle šejder
#	bolt_sprite.material.set_shader_param("noise_factor", 0)
	
	pass
onready var polygon_2d: Polygon2D = $Polygon2D

var faktor
var collision: KinematicCollision2D
func _physics_process(delta: float) -> void:
	
	acceleration = transform.x * speed # transform.x je (-1, 0)
	velocity += acceleration * delta	
	
	collision = move_and_collide(velocity, false)
	
	if collision:
		velocity = velocity.bounce(collision.normal)
		explosion_particles.emitting = true
		polygon_2d.visible = false
		

#
#	faktor = +1 
#	transform.x *= 1.1
#	print(transform.x)
#	print(transform)
#	print("------------------")
	# fwd motion se seta v kontrolerjih
	# aktivacija pospeška je setana na kotrolerju
	# plejer ... acceleration = transform.x * engine_power # transform.x je (-1, 0)
	# enemi ... acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power
	
	
#	# pospešek omejim z uporom
#	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja ... 100 je za dapatacijo višine inputa
#	acceleration -= drag_force
#
#	if nitro_active and fwd_motion: # se seta ob prevozu bonusa
#		engine_power = nitro_power
#
#	# "hitrost" je pospešek s časom
#	velocity += acceleration * delta	
#
#	rotation_angle = rotation_dir * deg2rad(turn_angle)
##	if velocity.length() < stop_speed: 
##		rotate(delta * rotation_angle * free_rotation_multiplier)
##	else: 
##		rotate(delta * rotation_angle)
#
#	rotate(delta * rotation_angle)
#	steering(delta)	# vpliva na ai !!!
#
#	collision = move_and_collide(velocity * delta, false)
#
#	if collision:
#		on_collision()	
#
#	motion_fx()
#	update_energy_bar()
