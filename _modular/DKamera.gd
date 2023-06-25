extends Camera2D


export (OpenSimplexNoise) var noise # tekstura za vizualizacijo ma kopijo tega noisa


# šejk setup
export(float, 0, 1) var trauma_strength_addon = 0.1 # na testnem gumbu
export(float, 0, 10) var trauma_time = 0.2 # decay delay
export(float, 0, 1) var decay_speed = 0.7 # krajši je 

export var max_horizontal = 150
export var max_vertical = 150
export var max_rotation = 5
export var time_speed: float = 150 # za offset noise
var trauma_strength = 0 # na začetku vedno 0
var time: float = 0 # za offset noise

# game šejk
#var shake_on: bool = false
export (float, 0, 1) var stray_hit_strength = 0.1 # bullet add_trauma
export (float, 0, 1) var wall_hit_strength = 0.35 # bullet add_trauma
export (float, 0, 1) var player_die_strength = 0.25 # bullet add_trauma
export (float, 0, 1) var stray_die_strength = 0.25 # bullet add_trauma

# test hud
var test_view_on = false

# mouse drag 
var mouse_used: bool = false # če je miška ni redi za dreganje ekrana
var camera_center = Vector2(320, 180)
var mouse_position_on_drag_start: Vector2 # zamik pozicije miške ob kliku
var drag_on: bool = false

# ui
onready var trauma_time_slider: HSlider = $UILayer/TestHud/TraumaControl/TraumaTime
onready var trauma_strength_slider: HSlider = $UILayer/TestHud/TraumaControl/TraumaStrength
onready var decay_slider: HSlider = $UILayer/TestHud/TraumaControl/ShakeDecay

onready var trauma_bar = $UILayer/TestHud/TraumaBar
onready var shake_bar = $UILayer/TestHud/ShakeBar
onready var trauma_btn = $UILayer/TestHud/AddTraumaBtn

onready var zoom_slider = $UILayer/TestHud/ZoomSlider
onready var time_slider = $UILayer/TestHud/TimeSlider
onready var reset_view_btn = $UILayer/TestHud/ResetViewBtn

onready var seed_slider = $UILayer/TestHud/NoiseControl/Seed
onready var octaves_slider = $UILayer/TestHud/NoiseControl/Octaves
onready var period_slider = $UILayer/TestHud/NoiseControl/Period
onready var persistence_slider = $UILayer/TestHud/NoiseControl/Persistence
onready var lacunarity_slider = $UILayer/TestHud/NoiseControl/Lacunarity

onready var testhud_node = $UILayer/TestHud
onready var test_toggle_btn = $UILayer/TestToggle


func _ready():

	Global.print_id(name)
	Global.main_camera = self
	Global.camera_target = null # da se nulira (pri quit game) in je naslednji play brez errorja ... seta se ob spawnanju plejerja

	# base šejk setup ... specialne nastavitve so v metodah
	noise.seed = 8
	noise.octaves = 1
	noise.period = 5
	noise.persistence = 0
	noise.lacunarity = 3.2
	
	
	# UI
	
	seed_slider.value = noise.seed
	octaves_slider.value = noise.octaves
	period_slider.value = noise.period 
	persistence_slider.value = noise.persistence
	lacunarity_slider.value = noise.lacunarity 

	trauma_time_slider.value = trauma_time
	trauma_strength_slider.value = trauma_strength_addon
	
	testhud_node.hide()
	test_toggle_btn.set_focus_mode(0)

	trauma_btn.set_focus_mode(0)
	trauma_time_slider.set_focus_mode(0)
	trauma_strength_slider.set_focus_mode(0)
	
	seed_slider.set_focus_mode(0)
	octaves_slider.set_focus_mode(0)
	period_slider.set_focus_mode(0)
	persistence_slider.set_focus_mode(0)
	lacunarity_slider.set_focus_mode(0)

	reset_view_btn.set_focus_mode(0)
	zoom_slider.set_focus_mode(0)
	time_slider.set_focus_mode(0)
	zoom_slider.hide()


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("left_click") and test_view_on and not mouse_used:
		drag_on = true
		mouse_position_on_drag_start = get_global_mouse_position() # definiraj zamik pozicije miške napram centru

	if Input.is_action_just_released("left_click"):
		drag_on = false

	if Input.is_mouse_button_pressed(BUTTON_WHEEL_UP) and test_view_on:
		zoom -= Vector2(0.1, 0.1)

	if Input.is_mouse_button_pressed(BUTTON_WHEEL_DOWN) and test_view_on:
		zoom += Vector2(0.1, 0.1)
		drag_on = false


func _process(delta):
	
	time += delta

	# start decay
	var shake = pow(trauma_strength, 2) # narašča s kvadratno funkcijo 
#	var shake = trauma_strength
	offset.x = noise.get_noise_3d(time * time_speed, 0, 0) * max_horizontal * shake
	offset.y = noise.get_noise_3d(0, time * time_speed, 0) * max_vertical * shake
	rotation_degrees = noise.get_noise_3d(0, 0, time * time_speed) * max_rotation * shake

	# start decay
	if trauma_strength > 0:
		yield(get_tree().create_timer(trauma_time), "timeout")
		trauma_strength = clamp(trauma_strength - (delta * decay_speed), 0, 1)

	# UI
	seed_slider.value = noise.seed
	octaves_slider.value = noise.octaves
	period_slider.value = noise.period 
	persistence_slider.value = noise.persistence
	lacunarity_slider.value = noise.lacunarity 

	trauma_time_slider.value = trauma_time
	trauma_strength_slider.value = trauma_strength_addon
	decay_slider.value = decay_speed
	trauma_bar.value = trauma_strength
	shake_bar.value = shake
	
	
	# mouse drag
	if drag_on:
		position += mouse_position_on_drag_start - get_global_mouse_position()


func _physics_process(delta: float) -> void:

#	if camera_target:
#		position = camera_target.position
	if Global.camera_target:
		position = Global.camera_target.position


# ŠEJK ------------------------------------------------------------------------------------------------------------------------

# on btn
func shake_camera(shake_strength): 
	
	trauma_strength = shake_strength
	trauma_strength = clamp(trauma_strength, 0, 1)


func stray_hit_shake():
	
	stray_hit_strength = 0.2
	trauma_time = 0.3
	decay_speed = 0.7
	
	shake_camera(stray_hit_strength)


func wall_hit_shake():
	
	wall_hit_strength = 0.25
	trauma_time = 0.5
	decay_speed = 0.2
	
	shake_camera(wall_hit_strength)


func stray_die_shake():
	
	return
	stray_die_strength = 0
	trauma_time = 0.2
	decay_speed = 0.7
	
	shake_camera(stray_die_strength)


func player_die_shake():
	
	player_die_strength = 0.2
	trauma_time = 0.7
	decay_speed = 0.1
	
	shake_camera(player_die_strength)


# FOLLOW ------------------------------------------------------------------------------------------------------------------------

func reset_camera_position():
	
	drag_margin_top = 0
	drag_margin_bottom = 0
	drag_margin_left = 0
	drag_margin_right = 0
	
	# position = Global.level_start_position.global_position

	yield(get_tree().create_timer(1), "timeout")

	drag_margin_top = 0.2
	drag_margin_bottom = 0.2
	drag_margin_left = 0.3
	drag_margin_right = 0.3


# TESTHUD ------------------------------------------------------------------------------------------------------------------------

func _on_CheckBox_toggled(button_pressed: bool) -> void:

	if test_view_on:
		test_view_on = false
		testhud_node.hide()
	else:
		testhud_node.show()
		test_view_on = true
func _on_CheckBox_mouse_entered() -> void:
	mouse_used = true
func _on_CheckBox_mouse_exited() -> void:
	mouse_used = false

func _on_AddTraumaBtn_pressed() -> void:
	mouse_used = true
	shake_camera(trauma_strength_addon)
func _on_AddTraumaBtn_mouse_entered() -> void:
	mouse_used = true
func _on_AddTraumaBtn_mouse_exited() -> void:
	mouse_used = false

# noise

func _on_Control_mouse_entered() -> void:
	mouse_used = true
func _on_Control_mouse_exited() -> void:
	mouse_used = false

func _on_Seed_value_changed(value: float) -> void:
	noise.seed = value
func _on_SeedSlider_mouse_entered() -> void:
	mouse_used = true
func _on_SeedSlider_mouse_exited() -> void:
	mouse_used = false

func _on_Octaves_value_changed(value: float) -> void:
	noise.octaves = value
func _on_Octaves_mouse_entered() -> void:
	mouse_used = true
func _on_Octaves_mouse_exited() -> void:
	mouse_used = false

func _on_Period_value_changed(value: float) -> void:
	noise.period = value
func _on_Period_mouse_entered() -> void:
	mouse_used = true
func _on_Period_mouse_exited() -> void:
	mouse_used = false

func _on_Persistence_value_changed(value: float) -> void:
	noise.persistence = value
func _on_Persistance_mouse_entered() -> void:
	mouse_used = true
func _on_Persistance_mouse_exited() -> void:
	mouse_used = false

func _on_Lacunarity_value_changed(value: float) -> void:
	noise.lacunarity = value
func _on_Lacunarity_mouse_entered() -> void:
	mouse_used = true
func _on_Lacunarity_mouse_exited() -> void:
	mouse_used = false

# shake props

func _on_TraumaTime_value_changed(value: float) -> void:
	trauma_time = value
func _on_TraumaTime_mouse_entered() -> void:
	mouse_used = true
func _on_TraumaTime_mouse_exited() -> void:
	mouse_used = false

func _on_TraumaStrength_value_changed(value: float) -> void:
	trauma_strength_addon = value
func _on_TraumaStrength_mouse_entered() -> void:
	mouse_used = true
func _on_TraumaStrength_mouse_exited() -> void:
	mouse_used = false

func _on_ShakeDecay_value_changed(value: float) -> void:
	decay_speed = value
func _on_ShakeDecay_mouse_exited() -> void:
	mouse_used = false
func _on_ShakeDecay_mouse_entered() -> void:
	mouse_used = true

# os time

func _on_TimeSlider_value_changed(value: float) -> void:
	Engine.time_scale = value
func _on_TimeSlider_mouse_entered() -> void:
	mouse_used = true
func _on_TimeSlider_mouse_exited() -> void:
	mouse_used = false

# zoom

func _on_ResetView_mouse_entered() -> void:
	mouse_used = true
func _on_ResetView_mouse_exited() -> void:
	mouse_used = false
func _on_ResetView_pressed() -> void:
	position = Vector2.ZERO + camera_center 
	zoom = Vector2.ONE

func _on_ZoomSlider_mouse_entered() -> void:
	mouse_used = true
func _on_ZoomSlider_mouse_exited() -> void:
	mouse_used = false
func _on_ZoomSlider_value_changed(value: float) -> void:
	zoom = Vector2(value, value)
