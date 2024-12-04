extends Area2D


signal ghost_target_reached (global_position) # teleporting
signal ghost_detected_body (krneki) # cocking

var speed: float = 0
var max_speed: float# = 10
var direction = Vector2.ZERO
var target_reached: float = false
var ghost_owner: KinematicBody2D
var teleporting_over_objects: Array = []
var teleporting_alpha: float = 1 # aplicira player ob spawnu

onready var cocking_ray: RayCast2D = $CockingRay # za cockanje
onready var glow_light: Light2D = $GlowLight
onready var cell_size_x: float = Global.current_tilemap.cell_size.x

onready var color_poly: Polygon2D = $ColorPoly
onready var color_poly_alt: Polygon2D = $ColorPolyAlt


func _ready() -> void:

	add_to_group(Global.group_ghosts)


func _physics_process(delta: float) -> void:

	match ghost_owner.current_state:
		ghost_owner.STATES.SKILLING: # teleporting
			global_position += direction * speed
			if not target_reached:
				speed = lerp(speed, 10, 0.015)
			glow_light.color = modulate

		ghost_owner.STATES.COCKING:
			var cocking_collider: Object = Global.detect_collision_in_direction(direction, cocking_ray, cell_size_x)
			if cocking_collider and not cocking_collider.is_in_group(Global.group_ghosts):
				emit_signal("ghost_detected_body", cocking_ray.get_collider() )


func finish_teleporting():

	target_reached = true
	speed = 0
	global_position = Global.snap_to_nearest_grid(global_position)
	emit_signal("ghost_target_reached", self, global_position)


func _on_Ghost_area_entered(area: Area2D) -> void:

	if area.is_in_group(Global.group_strays):
		teleporting_over_objects.append(area)


func _on_Ghost_area_exited(area: Area2D) -> void:

	if teleporting_over_objects.has(area):
		teleporting_over_objects.erase(area)

		# ko je prazno, zaključi teleporting
		if teleporting_over_objects.empty():
			finish_teleporting()


func _on_Ghost_body_entered(body: Node) -> void:

	if body.is_in_group(Global.group_players) and not ghost_owner:
		teleporting_over_objects.append(body)
	elif body.is_in_group(Global.group_tilemap):
		teleporting_over_objects.append(body)



func _on_Ghost_body_exited(body: Node) -> void:

	if teleporting_over_objects.has(body):
		teleporting_over_objects.erase(body)

		# ko je prazno, zaključi teleporting
		if teleporting_over_objects.empty():
			finish_teleporting()
