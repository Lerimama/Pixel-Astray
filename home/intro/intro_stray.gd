extends KinematicBody2D
# optimizirana stray koda

enum States {IDLE, MOVING, STATIC, DYING}
var current_state

var stray_color: Color
var step_attempt: int = 1 # če nima prostora, proba v drugo smer (največ 4krat)

onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var collision_shape_ext: CollisionShape2D = $CollisionShapeExt
onready var vision_rays: Array = [$Vision/VisionRay1, $Vision/VisionRay2, $Vision/VisionRay3]
onready var vision: Node2D = $Vision
onready var color_poly: Polygon2D = $ColorPoly
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var count_label: Label = $CountLabel # debug
onready var position_indicator: Node2D = $PositionIndicator
onready var visibility_notifier_2d: VisibilityNotifier2D = $VisibilityNotifier2D
onready var cell_size_x: int = Global.current_tilemap.cell_size.x


func _ready() -> void:
	
	add_to_group(Global.group_strays)

	randomize() # za random die animacije
	
	current_state = States.IDLE
	
	color_poly.modulate = stray_color
	position_indicator.get_node("PositionPoly").color = stray_color
	count_label.text = name
	position_indicator.visible = false
	
	yield(get_tree().create_timer(0.5), "timeout") # da ima čas registrirat	
	$OverspawnDetect.monitoring = false
	$OverspawnDetect.monitorable = false

	
func step(step_direction: Vector2):

	# preverjam state		
	if not current_state == States.IDLE:
		return
			
	var current_collider = detect_collision_in_direction(step_direction)
	if current_collider:
		# če kolajda izbrani smeri gibanja zarotira smer za 90 in poskusi znova
		step_attempt += 1
		if step_attempt < 5:
			var new_direction = step_direction.rotated(deg2rad(90))
			step(new_direction)
		return
	
	current_state = States.MOVING
	
	collision_shape_ext.position = step_direction * cell_size_x # vržem koližn v smer premika

	var step_time: float = 0.2
	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
	step_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, step_time)
	step_tween.tween_callback(self, "end_move")
	

func end_move():
	
	if current_state == States.MOVING: # zakaj že rabim ta pogoj?
		current_state = States.IDLE
	global_position = Global.snap_to_nearest_grid(self)
	
		
#func play_blinking_sound():
#	Global.sound_manager.play_sfx("blinking")
##	var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
##	$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
##	var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
##	$Sounds/BlinkingStatic.get_child(random_static_index).play()
	
	
func play_sound(effect_for: String):

	if Global.sound_manager.game_sfx_set_to_off:
		return

	match effect_for:
		"blinking":
			Global.sound_manager.play_sfx("blinking")
		#			var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
		#			$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
		#			var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
		#			$Sounds/BlinkingStatic.get_child(random_static_index).play()
		"stepping":
			var random_step_index = randi() % $Sounds/Stepping.get_child_count()
			var selected_step_sound = $Sounds/Stepping.get_child(random_step_index).play()


func check_for_neighbors(): # kliče player on hit
	
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbors: Array
	
	for direction in directions_to_check:
		var neighbor = detect_collision_in_direction(direction)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			current_cell_neighbors.append(neighbor)
				
	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov

	
func detect_collision_in_direction(direction_to_check):
	
	# obrnem vision grupo v smeri...
	vision.look_at(global_position + direction_to_check)
	
	# vsi ray gledajo naravnost
	for ray in vision_rays:
		ray.cast_to = Vector2(47.5, 0) # en pixel manj kot 48, da ne seže preko celice
	
	# grebanje kolajderja	
	var first_collider: Node2D
	for ray in vision_rays:
		ray.add_exception(self)
		ray.force_raycast_update()
		if ray.is_colliding():
			first_collider = ray.get_collider()
			break # ko je kolajder neham čekirat
	
	return first_collider


# SIGNALI ------------------------------------------------------------------------------------------------------


func _on_VisibilityNotifier2D_viewport_entered(viewport: Viewport) -> void:
	# namen: ne rabm
	pass
		
		
func _on_VisibilityNotifier2D_viewport_exited(viewport: Viewport) -> void:
	# namen: ne rabm
	pass


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	# name: samo normalen die
	
	var die_animations: Array = ["die_stray", "die_stray_1", "die_stray_2", "die_stray_3", "die_stray_4", "die_stray_5", ]
	
	if die_animations.has(anim_name):
		collision_shape.set_deferred("disabled", true)
		collision_shape_ext.set_deferred("disabled", true)
		# odstrani barve iz huda in igre
		#		Global.game_manager.on_stray_die(self)
		call_deferred("queue_free")


func _on_Stray_child_entered_tree(node: Node) -> void: # varovalka overspawn II ... glede na "isto pozicijo"
	# namen: ne preverjam plejerja
	
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		if stray.global_position == global_position:
			# printt ("overspawn II", self) 
			call_deferred("queue_free")


func _on_OverspawnDetect_body_entered(body: Node) -> void: # varovalka overspawn III ... če detect area zazna kolizijo
	# namen: ne preverjam plejerja
	
	# samo na štartu ... ob prikazu jo izklopim
	if body.is_in_group(Global.group_strays) and not body == self:
		# printt ("overspawn III", self)
		call_deferred("queue_free")


func _on_Stray_tree_exiting() -> void:
	# namen: ne rabm
	pass
