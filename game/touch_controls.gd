extends CanvasLayer


enum TOUCH_CONTROLLER {BUTTONS, SCREEN}
var current_touch_controller: int = TOUCH_CONTROLLER.BUTTONS

# controls
var key_up: String = "ui_up"
var key_down: String = "ui_down"
var key_left: String = "ui_left"
var key_right: String = "ui_right"
var key_burst: String = "burst"

var cont_mode: bool = true
var screen_btn_pressed: bool = false

var btn_pressed_skip_time: float = 0.2 # touch sensitiviy
var btn_pressed_time: float = 0

var last_dir_key_imitated: String # za screen release
var last_screen_touch_location: Vector2 = Vector2.ZERO

onready var direction_btns: Node2D = $DirectionBtns
onready var touch_btn_burst: TouchScreenButton = $TouchBtn_Burst
onready var touch_btn_screen: TouchScreenButton = $TouchBtnScreen
onready var touch_btn_pause: TouchScreenButton = $TouchBtnPause
onready var touch_btn_skip: TouchScreenButton = $TouchBtnSkip

# debug
var touch_direction_line: Line2D


func _ready() -> void:

	if OS.has_touchscreen_ui_hint():
		if current_touch_controller == TOUCH_CONTROLLER.BUTTONS:
			for btn in direction_btns.get_children():
				btn.connect("pressed", self, "_on_dir_btn_pressed", [btn])
				btn.connect("released", self, "_on_dir_btn_released", [btn])
		else:
			touch_btn_screen.connect("pressed", self, "_on_screen_btn_pressed", [touch_btn_screen])
			touch_btn_screen.connect("released", self, "_on_screen_btn_released", [touch_btn_screen])
		# burst
		touch_btn_burst.connect("pressed", self, "_on_dir_btn_pressed", [touch_btn_burst])
		touch_btn_burst.connect("released", self, "_on_dir_btn_released", [touch_btn_burst])
		# pause
		touch_btn_pause.connect("pressed", self, "_on_pause_btn_pressed", [touch_btn_pause])
		# music
		touch_btn_skip.connect("pressed", self, "_on_skip_btn_pressed", [touch_btn_skip])


func _process(delta: float) -> void:

	Profiles.screen_touch_sensitivity = 0.2
	if current_touch_controller == TOUCH_CONTROLLER.SCREEN:
		if screen_btn_pressed:
			btn_pressed_time += delta
			if btn_pressed_time > Profiles.screen_touch_sensitivity:
				get_screen_btn_direction_key()
				btn_pressed_skip_time = 0


func _on_screen_btn_released(released_btn: TouchScreenButton):

	imitate_input(last_dir_key_imitated, false)
	screen_btn_pressed = false
	last_screen_touch_location = Vector2.ZERO

	# debug
	if touch_direction_line:
		touch_direction_line.queue_free()
		touch_direction_line = null


func get_screen_btn_direction_key():

	var curr_point: Vector2 = touch_btn_screen.get_global_mouse_position()
	var prev_point: Vector2 = last_screen_touch_location

	# linija
	if OS.is_debug_build(): # debug build
		if not touch_direction_line:
			touch_direction_line = Line2D.new()
			add_child(touch_direction_line)
		touch_direction_line.add_point(curr_point)

	# glede na večjo razliko v spremembi določim premik po x ali y osi
	var x_delta: float = curr_point.x - prev_point.x
	var y_delta: float = curr_point.y - prev_point.y
	# direction > input name
	var input_name: String
	# left / right ... up / down
	if abs(x_delta) > abs(y_delta):
		if curr_point.x < prev_point.x:
			input_name = key_left
		else:
			input_name = key_right
	elif abs(x_delta) < abs(y_delta):
		if curr_point.y < prev_point.y:

			input_name = key_up
		else:
			input_name = key_down

	# izločim primerjanje prve pike ob novem kliku
	if not last_screen_touch_location == Vector2.ZERO:
		# imitate
		if input_name == last_dir_key_imitated:
			imitate_input(input_name)
		else:
			imitate_input(last_dir_key_imitated, false)
			call_deferred("imitate_input", input_name)

	# na koncu setam nov last location
	last_screen_touch_location = curr_point


func imitate_input(key_name: String, imitate_pressed: bool = true):

	#	print("pressed ", imitate_pressed, last_dir_key_imitated)

	var new_event = InputEventAction.new()
	new_event.action = key_name
	new_event.pressed = imitate_pressed
	Input.parse_input_event(new_event)

	# po pritisku ga označim za zadnjega pritisnjenega
	if imitate_pressed and not key_name == key_burst:
		last_dir_key_imitated = key_name


# BTN --------------------------------------------------------------------------------------------------------


func _on_screen_btn_pressed(btn_pressed: TouchScreenButton):

	screen_btn_pressed = true


func _on_dir_btn_pressed(btn_pressed: TouchScreenButton):

	var input_name: String
	# dir
	if btn_pressed == $DirectionBtns/TouchBtn_U:
		input_name = key_up
	elif btn_pressed == $DirectionBtns/TouchBtn_D:
		input_name = key_down
	elif btn_pressed == $DirectionBtns/TouchBtn_L:
		input_name = key_left
	elif btn_pressed == $DirectionBtns/TouchBtn_R:
		input_name = key_right
	# burst
	if btn_pressed == touch_btn_burst:
		input_name = key_burst

	imitate_input(input_name)


func _on_dir_btn_released(btn_released: TouchScreenButton):

	var input_name: String
	# dir
	if btn_released == $DirectionBtns/TouchBtn_U:
		input_name = key_up
	if btn_released == $DirectionBtns/TouchBtn_D:
		input_name = key_down
	if btn_released == $DirectionBtns/TouchBtn_L:
		input_name = key_left
	if btn_released == $DirectionBtns/TouchBtn_R:
		input_name = key_right
	# burst
	if btn_released == touch_btn_burst:
		input_name = key_burst
	# imitate
	imitate_input(input_name, false)


func _on_pause_btn_pressed(btn_pressed: TouchScreenButton):
	print("preload")
	var new_event = InputEventAction.new()
	new_event.action = "pause"
	new_event.pressed = true
	Input.parse_input_event(new_event)

func _on_skip_btn_pressed(btn_pressed: TouchScreenButton):
	print("skip")
	var new_event = InputEventAction.new()
	new_event.action = "next_track"
	new_event.pressed = true
	Input.parse_input_event(new_event)
