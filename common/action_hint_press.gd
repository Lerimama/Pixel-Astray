extends Node2D


func _ready() -> void:

	# hint text
	for child in $Hint.get_children():
		child.hide()
	$Hint/action.show()
	if Profiles.touch_available:
		$Hint/TOUCH.show()
	else:
		$Hint/KEYBOARD.show()
		$Hint/JOYPAD.show()
		$Hint/and_or.show()

