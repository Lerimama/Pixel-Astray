extends Node2D


# kadar je hover, je tudi fokus
# sounds + omejitve > focus, confirm, cancel, toggle
# colors > non-btn focus, confirm, cancel, toggle
## first screen focus sfx off:
# - ko klikne "kritični" gumb > se soundi ugasnejo
# - ko se fokusira kontrola, če so soundi ugasnjeni, se po fokusu spet prižgejo soundi
# - grab_focus_nofx() je za izredne primere
## direct-call play_gui_sfx("btn_confirm")
# - confirm popup selection
# - name_input key confirm / cancel
## direct-call grab_focus_nofx direct()
# - HOF on update or publish finished
# - name_input on open ... confirm
# - publish popup open ... publish
# - pauza ... play resume btn


var allow_ui_sfx: bool = false
var group_critical_btns = "Critical btns" # input off group
# select game main btns
# select level btns
# game over quit, replay
# pause quit, restart
var group_cancel_btns = "Cancel btns" # cancel sound group
# home sceeens esc
# home exit game
# game-over exit, quit
# pause restart, quit
# publish popup cancel btn
# name_input cancel btn


func _ready():

	# na ready se povežem z vsemi interaktivnimmi kontorlami, ki že obstajajo
	for child in get_tree().root.get_children():
		if child is BaseButton or child is HSlider:
			_connect_interactive_control(child)

	# signal iz drevesa na vsak node, ki pride v igro
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")


func grab_focus_nofx(control_to_focus: Control):

	# reseta na fokus
	allow_ui_sfx = false
	control_to_focus.grab_focus()
	set_deferred("allow_ui_sfx", true)


func _on_SceneTree_node_added(node: Control): # na ready

	if node is BaseButton or node is HSlider:
		_connect_interactive_control(node)



func _connect_interactive_control(node: Control):

	if node is Button:
		# hover
		node.connect("mouse_entered", self, "_on_mouse_entered", [node])
		# (de)focus
		node.connect("focus_entered", self, "_on_focus_entered", [node])
		node.connect("focus_exited", self, "_on_focus_exited", [node])

		if node is CheckButton:
			# toggle
			node.connect("toggled", self, "_on_btn_toggled")
		else:
			# press
			node.connect("pressed", self, "_on_btn_pressed", [node])
	elif node is HSlider:
		# hover
		node.connect("mouse_entered", self, "_on_mouse_entered", [node])
		# (de)focus
		node.connect("focus_entered", self, "_on_focus_entered", [node])
		node.connect("focus_exited", self, "_on_focus_exited", [node])


# SIGNALS ---------------------------------------------------------------------------------------------------------


func _on_mouse_entered(control: Control):

	#	printt("control hovered", control)
	if not control.has_focus():# and not control is ColorRect
		#		allow_ui_sfx = true # mouse focus je zmeraj s sonundom
		#	control.call_deferred("grab_focus")
		control.grab_focus()


func _on_focus_entered(control: Control):

	#	printt("control focused", control)
	if allow_ui_sfx:
		Global.sound_manager.play_gui_sfx("btn_focus_change")
	else:
		set_deferred("allow_ui_sfx", true)

	# color fix - non-regular-btn
	if control is CheckButton or control is HSlider or control.name == "RandomizeBtn" or control.name == "ResetBtn":
		control.modulate = Color.white


func _on_focus_exited(control: Control):

	#	printt("control unfocused", control)
	# settings gumbi - barvanje
	if control is CheckButton or control is HSlider or control.name == "RandomizeBtn" or control.name == "ResetBtn":
		control.modulate = Global.color_gui_gray # Color.white


func _on_btn_pressed(button: BaseButton):

	#	printt("btn pressed", button)
	Analytics.save_ui_click(button)

	if button.is_in_group(group_cancel_btns):
		Global.sound_manager.play_gui_sfx("btn_cancel")
	else:
		Global.sound_manager.play_gui_sfx("btn_confirm")

	if button.is_in_group(group_critical_btns):
		allow_ui_sfx = false
		get_viewport().set_disable_input(true)


func _on_btn_toggled(button_pressed: bool, button: Button) -> void:

	#	printt("btn toggled",button_pressed, button)
	if not str(button) == "[Deleted Object]": # anti home_out nek toggle btn
		if button_pressed:
			Global.sound_manager.play_gui_sfx("btn_confirm")
		else:
			Global.sound_manager.play_gui_sfx("btn_cancel")

		Analytics.save_ui_click([button, button_pressed])
