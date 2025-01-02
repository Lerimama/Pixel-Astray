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

# full screen mode
var screen_burst_is_pressed: bool = false
var screen_touch_is_moving: bool = false

onready var direction_btns: Node2D = $DirectionBtns
onready var burst_btn: TouchScreenButton = $BurstBtn
onready var screen_btn: TouchScreenButton = $ScreenBtn
onready var pause_btn: TouchScreenButton = $PauseBtn
onready var next_track_btn: TouchScreenButton = $NextTrackBtn
onready var mute_btn: TouchScreenButton = $MuteBtn
onready var current_touch_controller: int = Profiles.set_touch_controller setget _change_current_controller
onready var hint_btn: TouchScreenButton = $HintBtn
onready var tutorial_elements: Array = [
	$DirectionBtns/TouchBtn_L/Arrow,
	$DirectionBtns/TouchBtn_U/Arrow,
	$DirectionBtns/TouchBtn_R/Arrow,
	$DirectionBtns/TouchBtn_D/Arrow,
	$ScreenBtn/Label,
	$BurstBtn/Label
	]

# debug
var touch_direction_line: Line2D



func _ready() -> void:

	hide() # odprem ga ob zagonu igre iz GM

	for element in tutorial_elements: # kontrolirajo se iz tutoriala
		element.hide()

	pause_btn.add_to_group(Batnz.group_touch_sound_btns)
	mute_btn.add_to_group(Batnz.group_touch_sound_btns)
	next_track_btn.add_to_group(Batnz.group_touch_sound_btns)


func open():

	modulate.a = 0
	show()
	_set_current_controller() # more bit za show, ker se v show
	var fade = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(self, "modulate:a", 1, fade_inout_time)

	var music_player_position_x: float = Global.hud.music_player.rect_global_position.x
	mute_btn.global_position.x = music_player_position_x# + 50 # izmerjeno


func close():

	var fade = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(self, "modulate:a", 0, fade_inout_time)
	fade.tween_callback(self, "hide")
	print("hide")


func toggle_tutorial_elements(show_it: bool):

	var fade_time: float = 0.3
	var fade = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	if show_it:
		for element in tutorial_elements:
			fade.parallel().tween_callback(element, "show")
			fade.parallel().tween_property(element, "modulate:a", 1, fade_time).from(0.0).set_ease(Tween.EASE_IN)
	else:
		for element in tutorial_elements:
			fade.parallel().tween_property(element, "modulate:a", 0, fade_time).set_ease(Tween.EASE_IN)
		yield(fade, "finished")
		for element in tutorial_elements:
			element.hide()


func _set_current_controller():

	# reset
	_disconnect_all_btns()
	direction_btns.hide()
	burst_btn.hide()
	screen_btn.hide()
	screen_dir_is_pressed = false

	var left_position: Vector2 = $PositionL.position
	var right_position: Vector2 = $PositionR.position
	var poly_shape_l: Polygon2D = $ScreenBtn/PolyShapeL
	var poly_shape_r: Polygon2D = $ScreenBtn/PolyShapeR

	match current_touch_controller:
		Profiles.TOUCH_CONTROLLER.BUTTONS_RIGHT:
			if not visible:
				open()
			direction_btns.position = left_position
			burst_btn.position = right_position
			direction_btns.show()
			burst_btn.show()
			for btn in direction_btns.get_children():
				btn.connect("pressed", self, "_on_dir_btn_pressed", [btn])
				btn.connect("released", self, "_on_dir_btn_released", [btn])
			burst_btn.connect("pressed", self, "_on_dir_btn_pressed", [burst_btn])
			burst_btn.connect("released", self, "_on_dir_btn_released", [burst_btn])
		Profiles.TOUCH_CONTROLLER.BUTTONS_LEFT:
			direction_btns.position = right_position
			burst_btn.position = left_position
			if not visible:
				open()
			direction_btns.show()
			burst_btn.show()
			for btn in direction_btns.get_children():
				btn.connect("pressed", self, "_on_dir_btn_pressed", [btn])
				btn.connect("released", self, "_on_dir_btn_released", [btn])
			burst_btn.connect("pressed", self, "_on_dir_btn_pressed", [burst_btn])
			burst_btn.connect("released", self, "_on_dir_btn_released", [burst_btn])
		Profiles.TOUCH_CONTROLLER.SCREEN_RIGHT:
			if not visible:
				open()
			burst_btn.position = right_position
			screen_btn.shape.points = poly_shape_l.polygon
			burst_btn.show()
			screen_btn.show()
			screen_btn.connect("pressed", self, "_on_screen_btn_pressed", [screen_btn])
			screen_btn.connect("released", self, "_on_screen_btn_released", [screen_btn])
			burst_btn.connect("pressed", self, "_on_dir_btn_pressed", [burst_btn])
			burst_btn.connect("released", self, "_on_dir_btn_released", [burst_btn])
		Profiles.TOUCH_CONTROLLER.SCREEN_LEFT:
			if not visible:
				open()
			burst_btn.position = left_position
			screen_btn.shape.points = poly_shape_r.polygon
			burst_btn.show()
			screen_btn.show()
			screen_btn.connect("pressed", self, "_on_screen_btn_pressed", [screen_btn])
			screen_btn.connect("released", self, "_on_screen_btn_released", [screen_btn])
			burst_btn.connect("pressed", self, "_on_dir_btn_pressed", [burst_btn])
			burst_btn.connect("released", self, "_on_dir_btn_released", [burst_btn])
		Profiles.TOUCH_CONTROLLER.DISABLED:
			close()
			return # da se pavza ne seta

	# pause
	pause_btn.connect("pressed", self, "_on_pause_btn_pressed")
	# next track
	next_track_btn.connect("pressed", self, "_on_skip_btn_pressed")
	# mute
	mute_btn.connect("pressed", self, "_on_mute_btn_pressed")


# SCREEN --------------------------------------------------------------------------------------------------------


func _process(delta: float) -> void:

	if screen_dir_is_pressed:
		_get_screen_btn_direction_key()


func _imitate_input(key_name: String, imitate_pressed: bool = true):

	var new_event = InputEventAction.new()
	new_event.action = key_name
	new_event.pressed = imitate_pressed
	Input.parse_input_event(new_event)

	# po pritisku ga označim za zadnjega pritisnjenega
	if imitate_pressed and not key_name == key_burst:
		last_direction_imitated = key_name


func _get_screen_btn_direction_key():

	#	var curr_point: Vector2 = screen_btn.get_global_mouse_position()
	var curr_point: Vector2 = get_global_mouse_position()
	var prev_point: Vector2 = last_screen_touch_location

	var distance_delta: float = (prev_point - curr_point).length()
	if distance_delta > Profiles.screen_touch_sensitivity * (get_viewport_rect().size.x / 2): # /2 ker touch button meri drugače
		last_screen_touch_location = curr_point
		screen_touch_is_moving = true

		# glede na večjo razliko v spremembi določim premik po x ali y osi
		var x_delta: float = curr_point.x - prev_point.x
		var y_delta: float = curr_point.y - prev_point.y

		# linija
		if Profiles.debug_mode: # debug build
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
				_imitate_input(input_name)
			# če je zavil, prekinem in nadaljujem v novi smeri
			else:
				_imitate_input(last_direction_imitated, false)
				call_deferred("_imitate_input", input_name) # buggi zavijanje

			# na koncu setam nov last location ... trenutno v _imitate_input()
			#			last_direction_imitated = input_name

	else:
		screen_touch_is_moving = false
		_imitate_input(last_direction_imitated, false)

	#	print (screen_touch_is_moving)


func _on_screen_btn_pressed(btn_pressed: TouchScreenButton):
	print("Screen pressed ", self)
#	var input_name: String
#	# če je dir že prtisnjen imitiram burst klik
#	if screen_dir_is_pressed:
#		screen_burst_is_pressed = true
#		_imitate_input(key_burst)
#	else:
#		screen_dir_is_pressed = true

	screen_dir_is_pressed = true
	# premikanje je f _P


func _on_screen_btn_released(released_btn: TouchScreenButton):

	#	var input_name: String
	#	# dir
	#	if screen_burst_is_pressed:
	#		screen_burst_is_pressed = false
	#		_imitate_input(key_burst, false)
	#	elif screen_dir_is_pressed:
	#		screen_dir_is_pressed = false
	#		_imitate_input(key_, false)
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

	_imitate_input(input_name)


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
	_imitate_input(input_name, false)


# CONTROLER SETUP --------------------------------------------------------------------------------------------------------


func _disconnect_all_btns():

	# pause
	if pause_btn.is_connected("pressed", self, "_on_pause_btn_pressed"):
		pause_btn.disconnect("pressed", self, "_on_pause_btn_pressed")
	# next strack
	if next_track_btn.is_connected("pressed", self, "_on_skip_btn_pressed"):
		next_track_btn.disconnect("pressed", self, "_on_skip_btn_pressed")
	# mute
	if mute_btn.is_connected("pressed", self, "_on_mute_btn_pressed"):
		mute_btn.disconnect("pressed", self, "_on_mute_btn_pressed")
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

	_set_current_controller()


# UI --------------------------------------------------------------------------------------------------------


func _on_pause_btn_pressed():

	var new_event = InputEventAction.new()
	new_event.action = "pause"
	new_event.pressed = true
	Input.parse_input_event(new_event)


func _on_skip_btn_pressed():

	if Global.game_manager.game_on: # and not Global.tutorial_gui.visible: ... ne rabim za touch
		Global.hud.music_player._on_TrackBtn_pressed()


func _on_mute_btn_pressed():

	if Global.game_manager.game_on:
		Global.hud.music_player.toggle_mute()

	#	var new_event = InputEventAction.new()
	#	new_event.action = "mute"
	#	new_event.pressed = true
	#	Input.parse_input_event(new_event)


func _on_HintBtn_pressed() -> void:
	# ker hint btn na klik ne dela, more za touch bit posebej gumb
	# sweepr hint dela že v normanem gumbu

	if Global.tutorial_gui.tutorial_on:
		Global.tutorial_gui.skip_step()
	else:
		hint_btn.hide()


