extends Area2D


signal ghost_target_reached(global_position)
signal ghost_detected_body (body)

var speed: float = 0
var max_speed: float = 0
var direction = Vector2.UP

var floor_cells: Array = []
var target_reached: float = false
var fade_out_time: float = 0.2

onready var cell_size_x: float = Global.level_tilemap.cell_size.x
onready var poly_pixel: Polygon2D = $PolyPixel # za transparenco gled na energijo ... sam pixel je skos alfa 1, 
onready var ghost_ray: RayCast2D = $RayCast2D

var colliding_with_pixel :bool = false
var colliding_with_tilemap :bool = false


func _ready() -> void:
	
	Global.print_id(self)
#	add_to_group(Global.group_ghosts)
	

func _physics_process(delta: float) -> void:
	
	
	global_position += direction * speed
	speed = lerp(speed, max_speed, 0.015)
	ghost_ray.cast_to = direction * cell_size_x
	if target_reached:
		speed = 0
		global_position = Global.snap_to_nearest_grid(global_position, Global.level_tilemap.floor_cells_global_positions)
	
	if ghost_ray.is_colliding():
		ghost_ray.get_collider() 
		emit_signal("ghost_detected_body", ghost_ray.get_collider() )


func fade_out(): # kličem iz pixla
	
	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.tween_property(self, "modulate:a", 0, fade_out_time)
	fade_out_tween.tween_callback(self, "queue_free")
	

func _on_PixelGhost_body_exited(body: Node) -> void:
	
	if body.is_in_group(Global.group_strays):
		colliding_with_pixel = false
	if body.is_in_group(Global.group_tilemap):
		colliding_with_tilemap = false
	if body.is_in_group(Global.group_tilemap) or body.is_in_group(Global.group_strays):
		if not colliding_with_pixel and not colliding_with_tilemap:
			speed = 0 # tukaj je zato ker se lepše ustavi
			target_reached = true
			emit_signal("ghost_target_reached", self, global_position)


func _on_PixelGhost_body_entered(body: Node) -> void:
	
	if body.is_in_group(Global.group_strays):
		colliding_with_pixel = true
	if body.is_in_group(Global.group_tilemap):
		colliding_with_tilemap = true
