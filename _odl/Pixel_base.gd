extends KinematicBody2D
class_name Pixel


signal stat_changed (stat_owner, stat, stat_change)

export var pixel_is_player: = false # tukaj setam al ma kontrole al ne
export var energy_speed_mode: bool = true

# steping
export var step_time: float # = 0.15
export var walk_time: float = 0.15
export var run_time: float = 0.05
export var max_step_time: float = 0.25 # najpočasnejši
export var min_step_time: float = 0.1 # najhitrejši ... v trenutni kodi je irelevanten

enum States {IDLE, STEPPING, SKILLED, BURSTING}
var current_state = States.IDLE

var pixel_color: Color
var direction = Vector2.ZERO # prenosna

# push & pull
var pull_time: float = 0.3
var pull_cell_count: int = 1
var push_time: float = 0.3
var push_cell_count: int = 1

# teleport
var ghost_fade_time: float = 0.2
var backup_time: float = 0.32
var ghost_max_speed: float = 10

# cocking
var cocked_ghosts: Array
var cocking_room: bool = true
var cocked_ghost_count_max: int = 7
var cocked_ghost_alpha: float = 0.3
var cocked_ghost_alpha_factor: float = 25
var ghost_cocking_time: float = 0 # trenuten čas nastajanja cocking ghosta
var ghost_cocking_time_limit: float = 0.16 # max čas nastajanja cocking ghosta (tudi animacija)
var cocked_ghost_fill_time: float = 0.04 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
var cocked_pause_time: float = 0.05 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)

# bursting
var burst_speed: float = 0
var burst_speed_max: float = 0 # maximalna hitrost v tweenu
var burst_speed_max_addon: float = 10
var strech_ghost_shrink_time: float = 0.2
var burst_direction_set: bool = false
var burst_power: int # moč v številu ghosts_count

# stray
var current_neighbouring_cells: Array = [] # stray stalno čekira sosede

var new_tween: SceneTreeTween
var collision: KinematicCollision2D

onready var cell_size_x: int = Global.level_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var vision_ray: RayCast2D = $VisionRay
onready var floor_cells: Array = Global.game_manager.floor_positions
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var PixelGhost: PackedScene = preload("res://game/arena/PixelGhost.tscn")
onready var PixelCollisionParticles: PackedScene = preload("res://game/arena/PixelCollisionParticles.tscn")

# glow in dihanje
var skill_connect_alpha: float = 1.2
var breath_speed: float = 1.2
var tired_breath_speed: float = 2.4

onready var player_energy: float # energija je edini stat, ki gamore plejer poznat
onready var tired_energy_level: float = 0.1 # del energije pri kateri velja, da je utrujen (diha hitreje
onready var default_player_energy: float = Profiles.default_player_stats["player_energy"]

# ALL

func _ready() -> void:
	
	Global.print_id(self)
	
	modulate = pixel_color
	randomize() # za random die animacije
	snap_to_nearest_grid()
	


func die():
#	 animacije in kvefri
	pass



# ALL
func spawn_collision_particles():
	
	var new_collision_pixels = PixelCollisionParticles.instance()
	new_collision_pixels.global_position = global_position
	new_collision_pixels.modulate = pixel_color
	match direction:
		Vector2.UP: new_collision_pixels.rotate(deg2rad(-90))
		Vector2.DOWN: new_collision_pixels.rotate(deg2rad(90))
		Vector2.LEFT: new_collision_pixels.rotate(deg2rad(180))
		Vector2.RIGHT:new_collision_pixels.rotate(deg2rad(0))
	Global.node_creation_parent.add_child(new_collision_pixels)
			

func check_for_neighbours(): 
# samo če je stray
	
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbours: Array
	
	for dir in directions_to_check:
		
		if detect_collision_in_direction(vision_ray, dir):
			# če je kolajder stray in ni self
			var neighbour = detect_collision_in_direction(vision_ray, dir)
			if neighbour.is_in_group(Global.group_strays) and neighbour != self:
				current_cell_neighbours.append(neighbour)
				
	return current_cell_neighbours # uporaba v stalnem čekiranj sosedov
	
	
func detect_collision_in_direction(ray, direction_to_check):
	
	ray.cast_to = direction_to_check * cell_size_x # ray kaže na naslednjo pozicijo 
	ray.force_raycast_update()	
	
	if ray.is_colliding():
		var ray_collider = ray.get_collider()
		return ray_collider


func random_blink():

	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	return random_animation_name


func snap_to_nearest_grid():
	
	var current_position = Vector2(global_position.x - cell_size_x/2, global_position.y - cell_size_x/2)

	# če ni že snepano
	if not floor_cells.has(current_position): 
		# določimo distanco znotraj katere preverjamo bližino točke
		var distance_to_position: float = cell_size_x # začetna distanca je velikosti celice, ker na koncu je itak bližja
		var nearest_cell: Vector2
		for cell in floor_cells:
			if cell.distance_to(current_position) < distance_to_position:
				distance_to_position = cell.distance_to(current_position)
				nearest_cell = cell

		# snap it
		global_position = Vector2(nearest_cell.x + cell_size_x/2, nearest_cell.y + cell_size_x/2)

