extends LineEdit


var set_position: bool = true
var line_edit_global_position: Vector2

onready var screen_height: float = ProjectSettings.get_setting("display/window/size/height")
onready var actual_resolution: Vector2 = OS.get_window_size()


func _process(_delta):

	if not Global.game_manager.game_on:
		#	if OS.get_name() == "Android":
		if Profiles.touch_available and not Profiles.set_touch_controller == Profiles.TOUCH_CONTROLLER.DISABLED:
			if not virtual_keyboard_enabled: # zazih
				set_virtual_keyboard_enabled(true)

			if set_position:
				#				printt("POS", line_edit_global_position, OS.get_virtual_keyboard_height())
				line_edit_global_position = get_global_position()
				set_position = false

			_reposition()


func _reposition():

	var target_position_y: float

	if has_focus():
		var ratio: float = screen_height / actual_resolution.y
		target_position_y = min(line_edit_global_position.y, screen_height - get_size().y - (OS.get_virtual_keyboard_height() * ratio))
	else:
		target_position_y = line_edit_global_position.y

	set_global_position(Vector2(line_edit_global_position.x, target_position_y))


func _on_NameInput_visibility_changed() -> void:

	if visible:
		# select all the text in the LineEdit, so that whatever you type on the virtual keyboard replaces all text
		select_all()
