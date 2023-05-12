extends Area2D


signal ghost_arrived(global_position)

var speed: float = 0
var max_speed: float = 10
var direction = Vector2.ZERO

var floor_cells: Array = []
var cell_size_x: float
var ghost_arrived: float = false
var fade_out_time: float = 0.2

onready var poly_pixel: Polygon2D = $PolyPixel


func _ready() -> void:
#	print(global_position)
	pass

func _physics_process(delta: float) -> void:
	
	
	global_position += direction * speed
	speed = lerp(speed, max_speed, 0.015)
	
	if ghost_arrived:
		speed = 0
		snap_to_nearest_grid()
		
	
func snap_to_nearest_grid():
	
	floor_cells = get_parent().available_positions
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
	if body == Global.level_tilemap: # or body == KinematicBody2D:
		speed = 0 # tukaj je zato ker se lepše ustavi
		ghost_arrived = true
		emit_signal("ghost_arrived", global_position)
		print(global_position)
	
