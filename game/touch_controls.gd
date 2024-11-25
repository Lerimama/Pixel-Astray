extends Node2D


#enum TOUCH_CONTROLLER {BUTTONS, SCREEN, COMBO}
#var current_touch_controller: int = TOUCH_CONTROLLER.BUTTONS
onready var curr_touch_controller: int = Profiles.set_touch_controller setget _change_touch_controller

# controls
var key_up: String = "ui_up"
var key_down: String = "ui_down"
var key_left: String = "ui_left"
var key_right: String = "ui_right"
var key_burst: String = "burst"

var screen_btn_pressed: bool = false
var btn_pressed_time: float = 0
var last_dir_key_imitated: String # za screen release
var last_screen_touch_location: Vector2 = Vector2.ZERO

onready var direction_btns: Node2D = $DirectionBtns
onready var touch_btn_burst: TouchScreenButton = $TouchBtnBurst
onready var screen_btn_dir: TouchScreenButton = $ScreenBtnDir
onready var screen_btn_burst: TouchScreenButton = $ScreenBtnBurst

onready var touch_btn_pause: TouchScreenButton = $TouchBtnPause
onready var touch_btn_skip: TouchScreenButton = $TouchBtnSkip
onready var viewport_container: ViewportContainer = $"%ViewportContainer"

# debug
var touch_direction_line: Line2D


func _change_touch_controller(new_touch_controller: int):

	Profiles.set_touch_controller = new_touch_controller
	match Profiles.set_touch_controller:
		Profiles.TOUCH_CONTROLLER.BUTTONS:
			activate_buttons_touchscreen()
		Profiles.TOUCH_CONTROLLER.SCREEN:
			activate_screen_touchscreen()
			direction_btns.hide()
			touch_btn_burst.hide()
		Profiles.TOUCH_CONTROLLER.COMBO:
			activate_combo_touchscreen()
			screen_btn_burst.hide()
			direction_btns.hide()



func _ready() -> void:

	if OS.has_touchscreen_ui_hint() and not Profiles.set_touch_controller == Profiles.TOUCH_CONTROLLER.OFF:
		match Profiles.set_touch_controller:
			Profiles.TOUCH_CONTROLLER.BUTTONS:
				activate_buttons_touchscreen()
			Profiles.TOUCH_CONTROLLER.SCREEN:
				activate_screen_touchscreen()
				direction_btns.hide()
				touch_btn_burst.hide()
			Profiles.TOUCH_CONTROLLER.COMBO:
				activate_combo_touchscreen()
				screen_btn_burst.hide()
				direction_btns.hide()
		# pause
		touch_btn_pause.connect("pressed", self, "_on_pause_btn_pressed", [touch_btn_pause])
		# music
		touch_btn_skip.connect("pressed", self, "_on_skip_btn_pressed", [touch_btn_skip])
	else:
		hide()



func activate_buttons_touchscreen():

	# dir
	for btn in direction_btns.get_children():
		btn.connect("pressed", self, "_on_dir_btn_pressed", [btn])
		btn.connect("released", self, "_on_dir_btn_released", [btn])
	# burst
	touch_btn_burst.connect("pressed", self, "_on_dir_btn_pressed", [touch_btn_burst])
	touch_btn_burst.connect("released", self, "_on_dir_btn_released", [touch_btn_burst])


func activate_screen_touchscreen():

	#	screen_btn_dir.shape.extents = viewport_container.rect_size/2
	#	screen_btn_burst.shape.extents = viewport_container.rect_size/2
	# dir
	screen_btn_dir.connect("pressed", self, "_on_screen_btn_pressed", [screen_btn_dir])
	screen_btn_dir.connect("released", self, "_on_screen_btn_released", [screen_btn_dir])
	# burst
	screen_btn_burst.connect("pressed", self, "_on_screen_btn_pressed", [screen_btn_burst])
	screen_btn_burst.connect("released", self, "_on_screen_btn_released", [screen_btn_burst])


func activate_combo_touchscreen():

	#	screen_btn_dir.shape.extents = viewport_container.rect_size/2
	# dir
	screen_btn_dir.connect("pressed", self, "_on_screen_btn_pressed", [screen_btn_dir])
	screen_btn_dir.connect("released", self, "_on_screen_btn_released", [screen_btn_dir])
	# burst
	touch_btn_burst.connect("pressed", self, "_on_dir_btn_pressed", [touch_btn_burst])
	touch_btn_burst.connect("released", self, "_on_dir_btn_released", [touch_btn_burst])


func _process(delta: float) -> void:

	if not Profiles.set_touch_controller == Profiles.TOUCH_CONTROLLER.BUTTONS:
		if screen_btn_pressed:
			btn_pressed_time += delta
			if btn_pressed_time > Profiles.screen_touch_sensitivity:
				get_screen_btn_direction_key()
				btn_pressed_time = 0


func get_screen_btn_direction_key():

	var curr_point: Vector2 = screen_btn_dir.get_global_mouse_position()
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
			btn_pressed_time = 0
			call_deferred("imitate_input", input_name)

	# na koncu setam nov last location
	last_screen_touch_location = curr_point


func imitate_input(key_name: String, imitate_pressed: bool = true):

	var new_event = InputEventAction.new()
	new_event.action = key_name
	new_event.pressed = imitate_pressed
	Input.parse_input_event(new_event)

	# po pritisku ga označim za zadnjega pritisnjenega
	if imitate_pressed and not key_name == key_burst:
		last_dir_key_imitated = key_name


# BTN --------------------------------------------------------------------------------------------------------


func _on_screen_btn_pressed(btn_pressed: TouchScreenButton):

	var input_name: String
	# dir
	if btn_pressed == screen_btn_dir:
		screen_btn_pressed = true
	elif btn_pressed == screen_btn_burst and screen_btn_dir.is_pressed():
		input_name = key_burst
		imitate_input(input_name)


func _on_screen_btn_released(released_btn: TouchScreenButton):

	var input_name: String
	# dir
	if released_btn == screen_btn_dir:
		imitate_input(last_dir_key_imitated, false)
		screen_btn_pressed = false
		last_screen_touch_location = Vector2.ZERO

		# debug
		if touch_direction_line:
			touch_direction_line.queue_free()
			touch_direction_line = null

	elif released_btn == screen_btn_burst:
		imitate_input(key_burst, false)


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
	elif btn_pressed == touch_btn_burst:
		input_name = key_burst

	imitate_input(input_name)


func _on_dir_btn_released(btn_released: TouchScreenButton):

	var input_name: String
	# dir
	if btn_released == $DirectionBtns/TouchBtn_U:
		input_name = key_up
	elif btn_released == $DirectionBtns/TouchBtn_D:
		input_name = key_down
	elif btn_released == $DirectionBtns/TouchBtn_L:
		input_name = key_left
	elif btn_released == $DirectionBtns/TouchBtn_R:
		input_name = key_right
	# burst
	elif btn_released == touch_btn_burst:
		input_name = key_burst
	# imitate
	imitate_input(input_name, false)


func _on_pause_btn_pressed(btn_pressed: TouchScreenButton):

	print("pause")
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
