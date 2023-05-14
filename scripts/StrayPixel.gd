extends KinematicBody2D


signal stat_changed (stat_owner, stat, stat_change) # owner je v tem primeru nepomemben ... zato ga ni

var speed: float = 0
var max_speed: float = 10
var velocity: Vector2
var direction = Vector2.ZERO
var collision: KinematicCollision2D
var accelaration: float = 500

var pixel_color: Color # = state_colors[current_state]
var pixel_break_time: float = 0.3

# states
var current_state : int = States.RED setget _change_state # tole je int ker je rezultat številka
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

# snepanje
var cell_size_x: int # pogreba od arene, ki jo dobi od tilemapa
var floor_cells: Array = []

var new_tween: SceneTreeTween
onready var poly_broken: Polygon2D = $PolyBroken
onready var detect_area: Area2D = $DetectArea


func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Config.group_strays)
	
	# snap it ... ne dela vredu, zato jo snapam v spawnanju
#	cell_size_x = Global.game_manager.grid_cell_size.x # get cell size
#	global_position = global_position.snapped(Vector2.ONE * cell_size_x)
#	global_position += Vector2.ONE * cell_size_x/2 # zamik centra
	
	pass
	

func _physics_process(delta: float) -> void:

	state_machine()
	
	speed += delta * accelaration
	velocity = direction * speed
		
	collision = move_and_collide(velocity * delta, false)


func state_machine():
	
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
	
	# new state
	current_state = new_state_id
	modulate = state_colors[current_state]
		
		
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


func turn_off():
	
	new_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
	new_tween.tween_property(self, "modulate:a", 0, 3)
	new_tween.tween_callback(self, "die")

	
func die():
	# pošljem barvo
#	emit_signal("stat_changed", "black_pixels", 1) 
	
	# pošljem turnoff
	emit_signal("stat_changed", self, "black_pixels", 1) # owner je v tem primeru nepomemben ... zato ga ni
	print("strey kvfrid")
	queue_free()


func _on_DetectArea_body_entered(body: Node) -> void:
#	explode_pixel()
	pass # Replace with function body.
