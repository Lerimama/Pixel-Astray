extends TouchScreenButton


enum SWIPE_DIRECTION {NONE, LEFT, UP, RIGHT, DOWN}
var current_swipe_direction: int = SWIPE_DIRECTION.NONE

var swipe_length_factor: float = 0.1 # procent dolžine ekrana
var screen_pressed_position: Vector2 = Vector2.ZERO

# debug ... line2d
var touch_direction_line: Line2D

func _ready() -> void:

	hide()


func imitate_input(direction_key: int, imitate_pressed: bool = true):
	# svajpanje imitiram glede na to v kateri fazi je

	var parent_node = get_parent()

	# če je swipe in ni intro se namig skrije
	if not parent_node.current_screen == parent_node.Screens.INTRO:
		parent_node.navigation_hint.hide()

	match parent_node.current_screen:
		parent_node.Screens.INTRO:
			match direction_key:
				SWIPE_DIRECTION.LEFT:
					parent_node.intro._on_SkipButton_pressed()
				SWIPE_DIRECTION.RIGHT:
					parent_node.intro._on_SkipButton_pressed()
		parent_node.Screens.MAIN_MENU:
			match direction_key:
				SWIPE_DIRECTION.LEFT:
					parent_node._on_SelectGameBtn_pressed()
				SWIPE_DIRECTION.UP:
					parent_node._on_AboutBtn_pressed()
				SWIPE_DIRECTION.RIGHT:
					parent_node._on_SettingsBtn_pressed()
				SWIPE_DIRECTION.DOWN:
					parent_node._on_HighscoresBtn_pressed()
		parent_node.Screens.SELECT_GAME:
			if direction_key == SWIPE_DIRECTION.LEFT or direction_key == SWIPE_DIRECTION.UP:
				parent_node.get_node("SelectGame")._on_SweeperBtn_pressed()
			elif direction_key == SWIPE_DIRECTION.RIGHT:
				parent_node.get_node("SelectGame").call_deferred("_on_BackBtn_pressed")
		parent_node.Screens.ABOUT:
			if direction_key == SWIPE_DIRECTION.DOWN:
				parent_node.get_node("About").call_deferred("_on_BackBtn_pressed")
		parent_node.Screens.SETTINGS:
			if direction_key == SWIPE_DIRECTION.LEFT:
				parent_node.get_node("Settings").call_deferred("_on_BackBtn_pressed")
		parent_node.Screens.HIGHSCORES:
			if direction_key == SWIPE_DIRECTION.UP:
				parent_node.get_node("Highscores").call_deferred("_on_BackBtn_pressed")
		parent_node.Screens.SELECT_LEVEL:
			if direction_key == SWIPE_DIRECTION.RIGHT or direction_key == SWIPE_DIRECTION.DOWN:
				parent_node.get_node("SelectLevel").call_deferred("_on_BackBtn_pressed")


func get_swipe_direction():

	var curr_point: Vector2 = get_global_mouse_position()
	var prev_point: Vector2 = screen_pressed_position

	var distance_delta: float = (prev_point - curr_point).length()

	if distance_delta < OS.get_screen_size().x * swipe_length_factor:
		current_swipe_direction = SWIPE_DIRECTION.NONE
	else:
		# glede na večjo razliko v spremembi določim premik po x ali y osi
		var x_delta: float = curr_point.x - prev_point.x
		var y_delta: float = curr_point.y - prev_point.y

		if abs(x_delta) > abs(y_delta):
			if curr_point.x < prev_point.x:
				current_swipe_direction = SWIPE_DIRECTION.LEFT
			else:
				current_swipe_direction = SWIPE_DIRECTION.RIGHT
		elif abs(x_delta) < abs(y_delta):
			if curr_point.y < prev_point.y:
				current_swipe_direction = SWIPE_DIRECTION.UP
			else:
				current_swipe_direction = SWIPE_DIRECTION.DOWN
#		if get_parent().navigation_hint.visible:
#			var hint_fade = get_tree().create_tween()
#			hint_fade.tween_property(swipe_hint, "modulate:a", 0, 0.5)
#			hint_fade.tween_callback(swipe_hint, "hide")
		# linija
		#		if OS.is_debug_build(): # debug build
		#			if not touch_direction_line:
		#				touch_direction_line = Line2D.new()
		#				add_child(touch_direction_line)
		#			else:
		#				touch_direction_line.clear_points()
		#			touch_direction_line.add_point(curr_point)


func _on_SwipeBtn_pressed() -> void:

	screen_pressed_position = get_global_mouse_position()


func _on_SwipeBtn_released() -> void:

	get_swipe_direction()
	if not current_swipe_direction == SWIPE_DIRECTION.NONE:
		imitate_input(current_swipe_direction)
		screen_pressed_position = Vector2.ZERO
		#		touch_direction_line.add_point(get_global_mouse_position())
