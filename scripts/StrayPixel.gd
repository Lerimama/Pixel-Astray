extends KinematicBody2D


#signal collision_detected(global_position)
#signal target_reached(global_position) # 

# VSI PIXLI
signal stat_changed (stat_owner, stat, stat_change)

var speed: float = 0
var max_speed: float = 10
var velocity: Vector2
var direction = Vector2.ZERO
var collision: KinematicCollision2D
var accelaration: float = 500

# states
enum States {
	BLUE = 1, # ?
	GREEN, # ? 
	RED, 
	YELLOW,
	WHITE, # ?
	BLACK, 
} 
var state_colors: Dictionary = {
	1: Config.color_blue, 
	2: Config.color_green, 
	3: Config.color_red, 
	4: Config.color_yellow, 
	5: Config.color_white,
	6: Config.color_black,
}	
var skill_activated: bool = false
var current_state : int = States.RED setget _change_state # tole je int ker je rezultat številka
var pixel_color = state_colors[current_state]



# arena
var cell_size_x: int # pogreba od arene, ki jo dobi od tilemapa
var floor_cells: Array = []

# VSI STRAY PIXLI
# tricks
#var burst_speed = 50
#var burst_time = 0.3
#var ghost_fade_time = 0.2

var target_reached: bool = false

onready var poly_pixel: Polygon2D = $PolyPixel

onready var PixelExplosion = preload("res://scenes/PixelExplosion.tscn")


func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Config.group_strays)
#	modulate = pixel_color

	
	# snap it ... ne dela vredu, zato jo snapam v spawnanju
#	cell_size_x = Global.game_manager.grid_cell_size.x # get cell size
#	global_position = global_position.snapped(Vector2.ONE * cell_size_x)
#	global_position += Vector2.ONE * cell_size_x/2 # zamik centra

	
func _physics_process(delta: float) -> void:

	state_machine()
	modulate = state_colors[current_state]
	# ghost
	# global_position += direction * speed
	# speed = lerp(speed, max_speed, 0.015)
	
	speed += delta * accelaration
	velocity = direction * speed
		
	collision = move_and_collide(velocity * delta, false)

#	if target_reached:
#		speed = 0
#		snap_to_nearest_grid()


#	if collision:
#		queue_free()
#		print("collision")	

	
func state_machine():
	
	# ne manjaj stanj sredi akcije
	if skill_activated:
		return
#	if skill_tween != null:
#		if skill_tween.is_running():
#			return
		
	match current_state: 
		States.WHITE:
			pass
		States.BLUE:
			pass
		States.GREEN: 
			pass
		States.RED:
			pass
		States.YELLOW:
			pass
		States.BLACK:
			pass
			
	# change state
	if Input.is_action_just_pressed("ctrl"):
		select_next_state()	
		
func select_next_state():
		# spreminjanje v zaporedju state v zaporedju
		if current_state < States.size():
			self.current_state = current_state + 1 
		else:		
			self.current_state = 1	

	
func _change_state(new_state_id):
	
	# transition
#	direction = Vector2.ZERO
#	snap_to_nearest_grid()
	
	# statistika
	emit_signal("stat_changed", Global.game_manager.P1, "points", 1)	
	
	# new state
	current_state = new_state_id
		
		
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



onready var poly_broken: Polygon2D = $PolyBroken
var pixel_break_time: float = 0.3

	
var new_tween: SceneTreeTween
onready var detect_area: Area2D = $DetectArea

func explode_pixel():
	
	self
	# breaking
	poly_broken.visible = true
#	poly_broken.modulate = state_colors[current_state]
	new_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	new_tween.tween_property(poly_pixel, "position", Vector2.ZERO, pixel_break_time)
	new_tween.parallel().tween_property(poly_pixel, "scale", Vector2.ZERO, pixel_break_time)
	yield(get_tree().create_timer(pixel_break_time),"timeout")
	yield(get_tree().create_timer(0.1),"timeout")

	# spawn delaunay and explode
	var new_exploding_pixel = PixelExplosion.instance()
	new_exploding_pixel.modulate = state_colors[current_state]
	new_exploding_pixel.global_position = global_position - Vector2.ONE * cell_size_x / 2
	Global.node_creation_parent.add_child(new_exploding_pixel)

	poly_pixel.visible = false
	poly_broken.visible = false

	die()


func die():
	emit_signal("stat_changed", self, "life", 1)
#	visible = false
	queue_free()


func _on_DetectArea_body_entered() -> void:
#	explode_pixel()
	pass # Replace with function body.
