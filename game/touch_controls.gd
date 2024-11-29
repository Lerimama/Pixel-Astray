extends Node2D


var fade_inout_time: float = 0.5

# controls
var key_up: String = "ui_up"
var key_down: String = "ui_down"
var key_left: String = "ui_left"
var key_right: String = "ui_right"
var key_burst: String = "burst"

# screen direction btn
var screen_dir_is_pressed: bool = false
var last_direction_imitated: String # za screen release
var last_screen_touch_location: Vector2 = Vector2.ZERO

onready var direction_btns: Node2D = $DirectionBtns
onready var burst_btn: TouchScreenButton = $BurstBtn
onready var screen_btn: TouchScreenButton = $ScreenBtn
onready var pause_btn: TouchScreenButton = $PauseBtn
onready var next_track_btn: TouchScreenButton = $NextTrackBtn
onready var skip_tut_btn: TouchScreenButton = $SkipTutBtn
onready var current_touch_controller: int = Profiles.set_touch_controller setget _change_current_controller
onready var tutorial_elements: Array = [skip_tut_btn, $DirectionBtns/TouchBtn_L/TextureRect2, $DirectionBtns/TouchBtn_U/TextureRect2, $DirectionBtns/TouchBtn_R/TextureRect, $DirectionBtns/TouchBtn_D/TextureRect2, $BurstBtn/Label]

# _temp hint btn
onready var sweeper_hint_btn: TouchScreenButton = $SweeperHintBtn

# debug
var touch_direction_line: Line2D

# full screen mode
var screen_burst_is_pressed: bool = false
var screen_touch_is_moving: bool = false


func _ready() -> void:

	hide() # odprem ga ob zagonu igre iz GM

	for element in tutorial_elements: # kontrolirajo se iz tutoriala
		element.hide()

func open():

	show()
	set_current_controller() # more bit za show, ker se v show
	var fade = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(self, "modulate:a", 1, fade_inout_time)


func close():

	var fade = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(self, "modulate:a", 0, fade_inout_time)
	fade.tween_callback(self, "hide")


func set_current_controller():

	disconnect_all_btns()
	# reset
	direction_btns.hide()
	burst_btn.hide()
	screen_btn.hide()
	screen_dir_is_pressed = false

	match current_touch_controller:
		Profiles.TOUCH_CONTROLLER.BUTTONS:
			if not visible:
				open()
			direction_btns.show()
			burst_btn.show()
			# dir - btn
			for btn in direction_btns.get_children():
				btn.connect("pressed", self, "_on_dir_btn_pressed", [btn])
				btn.connect("released", self, "_on_dir_btn_released", [btn])
			# burst - btn
			burst_btn.connect("pressed", self, "_on_dir_btn_pressed", [burst_btn])
			burst_btn.connect("released", self, "_on_dir_btn_released", [burst_btn])
		#		Profiles.TOUCH_CONTROLLER.SCREEN:
		#			screen_btn.show()
		#			# dir - screen
		#			screen_btn.connect("pressed", self, "_on_screen_btn_pressed", [screen_btn])
		#			screen_btn.connect("released", self, "_on_screen_btn_released", [screen_btn])
		Profiles.TOUCH_CONTROLLER.COMBO:
			if not visible:
				open()
			burst_btn.show()
			screen_btn.show()
			# dir - screen
			screen_btn.connect("pressed", self, "_on_screen_btn_pressed", [screen_btn])
			screen_btn.connect("released", self, "_on_screen_btn_released", [screen_btn])
			# burst - btn
			burst_btn.connect("pressed", self, "_on_dir_btn_pressed", [burst_btn])
			burst_btn.connect("released", self, "_on_dir_btn_released", [burst_btn])
		Profiles.TOUCH_CONTROLLER.OFF:
			close()
			return # da se pavza ne seta

	# pause
	pause_btn.connect("pressed", self, "_on_pause_btn_pressed")#, [pause_btn])
	# music
	next_track_btn.connect("pressed", self, "_on_skip_btn_pressed")#, [next_track_btn])
	# skip tut
	skip_tut_btn.connect("pressed", self, "_on_skip_tut_btn_pressed")
	# sweeper hint
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		sweeper_hint_btn.connect("pressed", self, "_on_sweeeper_hint_btn_pressed")


# SCREEN --------------------------------------------------------------------------------------------------------


func _process(delta: float) -> void:

	if screen_dir_is_pressed:
		get_screen_btn_direction_key()


func imitate_input(key_name: String, imitate_pressed: bool = true):

	var new_event = InputEventAction.new()
	new_event.action = key_name
	new_event.pressed = imitate_pressed
	Input.parse_input_event(new_event)

#	# po pritisku ga označim za zadnjega pritisnjenega
	if imitate_pressed and not key_name == key_burst:
		last_direction_imitated = key_name


func get_screen_btn_direction_key():

	#	var curr_point: Vector2 = screen_btn.get_global_mouse_position()
	var curr_point: Vector2 = get_global_mouse_position()
	var prev_point: Vector2 = last_screen_touch_location

	var distance_delta: float = (prev_point - curr_point).length()

	if distance_delta > Profiles.screen_touch_sensitivity:
		last_screen_touch_location = curr_point
		screen_touch_is_moving = true

		# glede na večjo razliko v spremembi določim premik po x ali y osi
		var x_delta: float = curr_point.x - prev_point.x
		var y_delta: float = curr_point.y - prev_point.y

		# linija
		if OS.is_debug_build(): # debug build
			if not touch_direction_line:
				touch_direction_line = Line2D.new()
				add_child(touch_direction_line)
		touch_direction_line.add_point(curr_point)

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

		if not prev_point == Vector2.ZERO: # če je nula ne doda nove pike ampak začne šele z drugo
			# če je ista smer
			if input_name == last_direction_imitated:
				imitate_input(input_name)
			# če je zavil, prekinem in nadaljujem v novi smeri
			else:
				imitate_input(last_direction_imitated, false)
				call_deferred("imitate_input", input_name) # buggi zavijanje

			# na koncu setam nov last location ... trenutno v imitate_input()
			#			last_direction_imitated = input_name

	else:
		screen_touch_is_moving = false
		imitate_input(last_direction_imitated, false)

#	print (screen_touch_is_moving)

func _on_screen_btn_pressed(btn_pressed: TouchScreenButton):
	print("Screen pressed")
#	var input_name: String
#	# če je dir že prtisnjen imitiram burst klik
#	if screen_dir_is_pressed:
#		screen_burst_is_pressed = true
#		imitate_input(key_burst)
#	else:
#		screen_dir_is_pressed = true

	screen_dir_is_pressed = true
	# premikanje je f _P

func _on_screen_btn_released(released_btn: TouchScreenButton):

	#	var input_name: String
	#	# dir
	#	if screen_burst_is_pressed:
	#		screen_burst_is_pressed = false
	#		imitate_input(key_burst, false)
	#	elif screen_dir_is_pressed:
	#		screen_dir_is_pressed = false
	#		imitate_input(key_, false)
	#		last_screen_touch_location = Vector2.ZERO
	#		# debug
	#		if touch_direction_line:
	#			touch_direction_line.queue_free()
	#			touch_direction_line = null
	#	if screen_dir_is_pressed:

	screen_dir_is_pressed = false
	last_screen_touch_location = Vector2.ZERO

	# debug
	if touch_direction_line:
		touch_direction_line.queue_free()
		touch_direction_line = null


# BUTTONS -----------------------------------------------------------------------------------------------------


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
	elif btn_pressed == burst_btn:
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
	elif btn_released == burst_btn:
		input_name = key_burst
	# imitate
	imitate_input(input_name, false)


# CONTROLER SETUP --------------------------------------------------------------------------------------------------------


func disconnect_all_btns():

	# pause
	if pause_btn.is_connected("pressed", self, "_on_pause_btn_pressed"):
		pause_btn.disconnect("pressed", self, "_on_pause_btn_pressed")
	# music
	if next_track_btn.is_connected("pressed", self, "_on_skip_btn_pressed"):
		next_track_btn.disconnect("pressed", self, "_on_skip_btn_pressed")
	# hint
	if sweeper_hint_btn.is_connected("pressed", self, "_on_sweeeper_hint_btn_pressed"):
		sweeper_hint_btn.disconnect("pressed", self, "_on_sweeeper_hint_btn_pressed")
	# skip tut
	if skip_tut_btn.is_connected("pressed", self, "_on_skip_tut_btn_pressed"):
		skip_tut_btn.disconnect("pressed", self, "_on_skip_tut_btn_pressed")

	# dir - btn
	for btn in direction_btns.get_children():
		if btn.is_connected("pressed", self, "_on_dir_btn_pressed"):
			btn.disconnect("pressed", self, "_on_dir_btn_pressed")
		if btn.is_connected("released", self, "_on_dir_btn_released"):
			btn.disconnect("released", self, "_on_dir_btn_released")
	# burst - btn
	if burst_btn.is_connected("pressed", self, "_on_dir_btn_pressed"):
		burst_btn.disconnect("pressed", self, "_on_dir_btn_pressed")
	if burst_btn.is_connected("released", self, "_on_dir_btn_released"):
		burst_btn.disconnect("released", self, "_on_dir_btn_released")
	# dir - screen
	if screen_btn.is_connected("pressed", self, "_on_screen_btn_pressed"):
		screen_btn.disconnect("pressed", self, "_on_screen_btn_pressed")
	if screen_btn.is_connected("released", self, "_on_screen_btn_released"):
		screen_btn.disconnect("released", self, "_on_screen_btn_released")


func _change_current_controller(new_touch_controller: int):

	Profiles.set_touch_controller = new_touch_controller
	current_touch_controller = Profiles.set_touch_controller

	set_current_controller()


# UI --------------------------------------------------------------------------------------------------------


func _on_pause_btn_pressed():
#func _on_pause_btn_pressed(btn_pressed: TouchScreenButton):

	var new_event = InputEventAction.new()
	new_event.action = "pause"
	new_event.pressed = true
	Input.parse_input_event(new_event)


func _on_skip_btn_pressed():
#func _on_skip_btn_pressed(btn_pressed: TouchScreenButton):

	var new_event = InputEventAction.new()
	new_event.action = "next"
	new_event.pressed = true
	Input.parse_input_event(new_event)



func _on_skip_tut_btn_pressed():
	print("skip pressed")
	var new_event = InputEventAction.new()
	new_event.action = "next"
	new_event.pressed = true
	Input.parse_input_event(new_event)
	#	sweeper_hint_btn.hide()
	#	yield(get_tree().create_timer(1),"timeout")
	#	sweeper_hint_btn.call_deferred("show")
#	get_tree().set_input_as_handled()


func _on_sweeeper_hint_btn_pressed():
	return # _temp ... sweeper hint btn samo prižge zato je off
	print("hint pressed")
	var new_event = InputEventAction.new()
	new_event.action = "hint"
	new_event.pressed = true
	Input.parse_input_event(new_event)
	#	sweeper_hint_btn.hide()
	#	yield(get_tree().create_timer(1),"timeout")
	#	sweeper_hint_btn.call_deferred("show")
#	get_tree().set_input_as_handled()
