extends Area2D


signal ghost_target_reached(global_position)
signal ghost_detected_body (body)

var speed: float = 0
var max_speed: float = 0
var direction = Vector2.UP

var floor_cells: Array = []
var cell_size_x: float
var target_reached: float = false
var fade_out_time: float = 0.2

onready var poly_pixel: Polygon2D = $PolyPixel
onready var ghost_ray: RayCast2D = $RayCast2D
var ghost_ray_collider


func _ready() -> void:
	
	Global.print_id(self)
	add_to_group(Config.group_ghosts)
	
	# snap it
	cell_size_x = Global.game_manager.grid_cell_size.x # get cell size
	global_position = global_position.snapped(Vector2.ONE * cell_size_x/2)
#	global_position += Vector2.ONE * cell_size_x/2 # zamik centra
	
	pass

func _physics_process(delta: float) -> void:
	
	
	global_position += direction * speed
#	speed = max_speed
	speed = lerp(speed, max_speed, 0.015)
	ghost_ray.cast_to = direction * cell_size_x
	if target_reached:
		speed = 0
		snap_to_nearest_grid()
	
	if ghost_ray.is_colliding():
		ghost_ray.get_collider() 
		emit_signal("ghost_detected_body", ghost_ray.get_collider() )
	
	
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


func fade_out(): # kličem iz pixla
	
	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.tween_property(self, "modulate:a", 0, fade_out_time)
	fade_out_tween.tween_callback(self, "queue_free")
	

func _on_PixelGhost_body_exited(body: Node) -> void:
	
	if body.is_in_group(Config.group_tilemap):
		speed = 0 # tukaj je zato ker se lepše ustavi
		target_reached = true
		emit_signal("ghost_target_reached", self, global_position)
	


func _on_PixelGhost_body_entered(body: Node) -> void:
#	emit_signal("ghost_detected_body", body)
	pass
