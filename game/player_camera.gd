extends Camera2D


signal zoomed_in
signal zoomed_out

export (OpenSimplexNoise) var noise # tekstura za vizualizacijo ma kopijo tega noisa

var camera_target: Node2D
var tile_align_correction: Vector2 = Vector2.ZERO # za poravnavo kamere s tileti
var final_zoom = Vector2.ONE
var start_zoom = Vector2(2, 2)

# limits
var corner_TL: float
var corner_TR: float
var corner_BL: float
var corner_BR: float

# noise setup
var noise_seed: float = 8
var noise_octaves: float = 1
var noise_period: float = 5
var noise_persistence: float = 0
var noise_lacunarity: float = 3.2

# shake
var trauma_strength = 0 # na začetku vedno 0, pride iz šejk klica
var time: float = 0 # za offset noise
var time_speed: float = 150 # za offset noise
var decay_rate: float # enačba na kakšen način gre šejk do nule
var trauma_time: float
var decay_speed: float
var max_horizontal = 150
var max_vertical = 150
var max_rotation = 5


func _ready():
	
	add_to_group(Global.group_player_cameras)
	
	if Global.player1_camera == null:
		Global.player1_camera = self
	else:
		Global.player2_camera = self
	
	# start setup
	zoom = start_zoom
	
	# testhud
	set_ui_focus()	
	update_ui()


func _process(delta):
	
	time += delta
	
	# SHAKE KODA
	# camera noise setup 
	noise.seed = noise_seed
	noise.octaves = noise_octaves
	noise.period = noise_period
	noise.persistence = noise_persistence
	noise.lacunarity = noise_lacunarity

	# start decay
	decay_rate = pow(trauma_strength, 2) # pada s kvadratno funkcijo
	# decay_rate = trauma_strength ... pada linerano
	offset.x = noise.get_noise_3d(time * time_speed, 0, 0) * max_horizontal * decay_rate
	offset.y = noise.get_noise_3d(0, time * time_speed, 0) * max_vertical * decay_rate
	rotation_degrees = noise.get_noise_3d(0, 0, time * time_speed) * max_rotation * decay_rate

	# start decay
	if trauma_strength > 0:
		yield(get_tree().create_timer(trauma_time), "timeout")
		trauma_strength = clamp(trauma_strength - (delta * decay_speed), 0, 1)
	
	# testhud
	update_ui()
	if drag_on:
		position += mouse_position_on_drag_start - get_global_mouse_position()


func _physics_process(delta: float) -> void:
	
	if camera_target:
		position = camera_target.position + tile_align_correction
	

func zoom_in(hud_in_out_time: float, players_count: int): # kliče hud
	
	if players_count == 2:
		final_zoom *= 1.5
	
	get_camera_limits()	
	
	var zoom_in_tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	zoom_in_tween.tween_property(self, "zoom", final_zoom, hud_in_out_time)
	zoom_in_tween.parallel().tween_property(self, "limit_left", corner_TL, hud_in_out_time)
	zoom_in_tween.parallel().tween_property(self, "limit_right", corner_TR, hud_in_out_time)
	zoom_in_tween.parallel().tween_property(self, "limit_top", corner_BL, hud_in_out_time)
	zoom_in_tween.parallel().tween_property(self, "limit_bottom", corner_BR, hud_in_out_time)
	zoom_in_tween.parallel().tween_property(self, "tile_align_correction", Global.game_tilemap.cell_size/2, hud_in_out_time)
	zoom_in_tween.tween_callback(self, "emit_signal", ["zoomed_in"]) # pošlje na hud, ki sproži countdown
	
	
func zoom_out(hud_in_out_time): # kliče hud

	var zoom_out_tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	zoom_out_tween.tween_property(self, "zoom", start_zoom, hud_in_out_time)
	zoom_out_tween.parallel().tween_property(self, "limit_left", -10000000, hud_in_out_time)
	zoom_out_tween.parallel().tween_property(self, "limit_right", 10000000, hud_in_out_time)
	zoom_out_tween.parallel().tween_property(self, "limit_top", -10000000, hud_in_out_time)
	zoom_out_tween.parallel().tween_property(self, "limit_bottom", 10000000, hud_in_out_time)
	zoom_out_tween.parallel().tween_property(self, "tile_align_correction", Vector2.ZERO, hud_in_out_time)
	zoom_out_tween.tween_callback(self, "emit_signal", ["zoomed_out"]) # pošlje na GO, ki pokaže meni
	

func shake_camera(shake_power, shake_time, shake_decay): 
	
	if not Global.main_node.camera_shake_on:
		return
	
	# fixed
	trauma_strength = shake_power
	trauma_time = shake_time
	decay_speed = shake_decay
	
	# apply shake
	trauma_strength = clamp(trauma_strength, 0, 1)

	
func get_camera_limits():
	
	var tilemap_edge: Rect2 = Global.game_tilemap.get_used_rect()
	var tilemap_cell_size: Vector2 = Global.game_tilemap.cell_size
	
	corner_TL = tilemap_edge.position.x * tilemap_cell_size.x + tilemap_cell_size.x # k mejam prištejem edge debelino
	corner_TR = tilemap_edge.end.x * tilemap_cell_size.x - tilemap_cell_size.x
	corner_BL = tilemap_edge.position.y * tilemap_cell_size.y + tilemap_cell_size.y
	corner_BR = tilemap_edge.end.y * tilemap_cell_size.y - tilemap_cell_size.y
	

# ZOOM, LIMITS OLD WAY -------------------------------------------------------------------------------------------------------------


func zoom_in_no_limits(hud_in_out_time: float, players_count: int): # kliče hud
	
	if players_count == 2:
		final_zoom *= 1.5
		
	var zoom_in_tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	zoom_in_tween.tween_property(self, "zoom", final_zoom, hud_in_out_time)
	zoom_in_tween.parallel().tween_property(self, "tile_align_correction", Global.game_tilemap.cell_size/2, hud_in_out_time)
	zoom_in_tween.tween_callback(self, "emit_signal", ["zoomed_in"])
	
	
func zoom_out_no_limits(hud_in_out_time): # kliče hud

	var zoom_out_tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	zoom_out_tween.tween_property(self, "zoom", start_zoom, hud_in_out_time)
	zoom_out_tween.parallel().tween_property(self, "camera_target_vert_adapt", 0, hud_in_out_time)

	
func set_camera_limits(tilemap_edge: Rect2, tilemap_cell_size: Vector2):

	var corner_TL: float = tilemap_edge.position.x * tilemap_cell_size.x + tilemap_cell_size.x # k mejam prištejem edge debelino
	var corner_TR: float = tilemap_edge.end.x * tilemap_cell_size.x - tilemap_cell_size.x
	var corner_BL: float = tilemap_edge.position.y * tilemap_cell_size.y + tilemap_cell_size.y
	var corner_BR: float = tilemap_edge.end.y * tilemap_cell_size.y - tilemap_cell_size.y

	limit_left = corner_TL
	limit_right = corner_TR
	limit_top = corner_BL
	limit_bottom = corner_BR


func release_camera_limits():
	
	limit_left = -10000000
	limit_right = 10000000
	limit_top = -10000000
	limit_bottom = 10000000		


# TESTHUD ------------------------------------------------------------------------------------------------------------------------


var test_view_on = false

# test shake setup ... se ne meša z nastavitvami za igro
export var test_trauma_strength = 0.1 # šejk sajz na testnem gumbu ... se multiplicira s prtiskanjem
export var test_trauma_time = 0.2 # decay delay
export var test_decay_speed = 0.7 # krajši je 

# mouse drag 
var mouse_used: bool = false # če je miška ni redi za dreganje ekrana
var camera_center = Vector2(320, 180)
var mouse_position_on_drag_start: Vector2 # zamik pozicije miške ob kliku
var drag_on: bool = false

onready var trauma_time_slider: HSlider = $UILayer/TestHud/TraumaControl/TraumaTime
onready var trauma_strength_slider: HSlider = $UILayer/TestHud/TraumaControl/TraumaStrength
onready var decay_slider: HSlider = $UILayer/TestHud/TraumaControl/ShakeDecay
onready var trauma_bar = $UILayer/TestHud/TraumaBar
onready var shake_bar = $UILayer/TestHud/ShakeBar
onready var trauma_btn = $UILayer/TestHud/AddTraumaBtn
onready var zoom_label: Label = $UILayer/TestHud/ZoomLabel
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


func _input(_event: InputEvent) -> void: # testview inputs

	if Input.is_action_just_pressed("left_click") and test_view_on and not mouse_used:
		multi_shake_camera(test_trauma_strength, test_trauma_time, test_decay_speed)
		
	if Input.is_mouse_button_pressed(BUTTON_WHEEL_UP) and test_view_on:
		zoom -= Vector2(0.1, 0.1)
		zoom_label.text = "Zoom Level: " + str(round(zoom.x * 100)) + "%"

	if Input.is_mouse_button_pressed(BUTTON_WHEEL_DOWN) and test_view_on:
		zoom += Vector2(0.1, 0.1)
		drag_on = false
		zoom_label.text = "Zoom Level: " + str(round(zoom.x * 100)) + "%"


func set_ui_focus():
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

	
func update_ui():
	
	seed_slider.value = noise.seed
	octaves_slider.value = noise.octaves
	period_slider.value = noise.period 
	persistence_slider.value = noise.persistence
	lacunarity_slider.value = noise.lacunarity 
	trauma_time_slider.value = trauma_time
	trauma_strength_slider.value = test_trauma_strength

	trauma_bar.value = trauma_strength
	shake_bar.value = decay_rate
	decay_slider.value = decay_speed


func multi_shake_camera(shake_power, shake_time, shake_decay): 
	
	trauma_strength += shake_power
	trauma_time = shake_time
	decay_speed = shake_decay
	
	# apply shake
	trauma_strength = clamp(trauma_strength, 0, 1)
	
	
# toggle testhud

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

# shake btn

func _on_AddTraumaBtn_pressed() -> void:
	mouse_used = true
	multi_shake_camera(test_trauma_strength, test_trauma_time, test_decay_speed)
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
	test_trauma_strength = value
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