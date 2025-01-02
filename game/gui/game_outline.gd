extends HFlowContainer


onready var prop: Panel = $Prop
onready var record_panel: Panel = $Record
onready var record_panel_mobile: Panel = $RecordMobile
onready var shortcuts: Panel = $Shortcuts
onready var controls: Control = $Controls


func get_instructions_content():

	var current_game_data: Dictionary = Global.game_manager.game_data
	var current_hs_line: Array = Data.get_saved_highscore(current_game_data)
	var current_highscore: float = current_hs_line[0]
	var current_highscore_owner: String = current_hs_line[1]

	# record
	if current_game_data["highscore_type"] == Profiles.HighscoreTypes.NONE:
		record_panel.hide()
		record_panel_mobile.hide()
	else:
		var record_holder_to_fill: Control
		if Profiles.touch_available and not Profiles.set_touch_controller == Profiles.TOUCH_CONTROLLER.DISABLED:
			record_panel.hide()
			record_panel_mobile.show()
			record_holder_to_fill = record_panel_mobile
		else:
			record_holder_to_fill = record_panel
			record_panel.show()
			record_panel_mobile.hide()

		var record_icon: TextureRect = record_holder_to_fill.get_node("VBoxContainer/CupIcon")
		var record_label: Label = record_holder_to_fill.get_node("VBoxContainer/RecordLabel")
		var record_owner: Label = record_holder_to_fill.get_node("VBoxContainer/RecordOwner")
		record_label.show()
		record_icon.show()
		record_owner.show()

		# record
		if current_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME:
			if current_highscore == 0:
				record_owner.text = Profiles.game_text["outline_record_TIME"]
				record_label.hide()
			else:
				var clock_record: String = Global.get_clock_time(current_highscore)
				record_owner.text = "by " + str(current_highscore_owner)
				record_label.text = clock_record
		# points
		elif current_game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS:
			if current_highscore == 0:
				record_owner.text = Profiles.game_text["outline_record_POINTS"]
				record_label.hide()
			else:
				record_label.text = str(current_highscore) + " points"
				record_owner.text = "by " + str(current_highscore_owner)

	# touch spec
	if Profiles.touch_available and not Profiles.set_touch_controller == Profiles.TOUCH_CONTROLLER.DISABLED:
		shortcuts.hide()
		prop.hide()
	else:
		# shorts
		var hint_shortie: Control = shortcuts.get_node("Shortcuts").get_child(shortcuts.get_node("Shortcuts").get_child_count() - 1)
		if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
			shortcuts.hide()
			hint_shortie.show()
		else:
			shortcuts.show()
			hint_shortie.hide()
		# prop
		if current_game_data.has(prop.name): # če ima slovar igre to postavko ...
			prop.show()
			prop.get_node("PropLabel").text = current_game_data["%s" % prop.name] # ... jo napolni z njeno vsebino
		else:
			prop.hide()

	# player controls
	var def_min_y: float = 184 #168
	var touch_min_y: float = 280 # 288
	var ctrls_display: Control = controls.get_child(0)
	for ctrl_node in ctrls_display.get_children():
		ctrl_node.hide()
	if Profiles.touch_available and not Profiles.set_touch_controller == Profiles.TOUCH_CONTROLLER.DISABLED:
		controls.rect_min_size.y = touch_min_y
		var touch_ctrl_name: String
		match Profiles.set_touch_controller:
			Profiles.TOUCH_CONTROLLER.BUTTONS_LEFT: touch_ctrl_name = "Buttons_Burst_L"
			Profiles.TOUCH_CONTROLLER.BUTTONS_RIGHT: touch_ctrl_name = "Buttons_Burst_R"
			Profiles.TOUCH_CONTROLLER.SCREEN_LEFT: touch_ctrl_name = "Sliding_Burst_L"
			Profiles.TOUCH_CONTROLLER.SCREEN_RIGHT: touch_ctrl_name = "Sliding_Burst_R"
		ctrls_display.get_node(touch_ctrl_name).show()
	else:
		controls.rect_min_size.y = def_min_y
		if Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
			ctrls_display.get_node("2P").show()
		else:
			ctrls_display.get_node("1P").show()
	controls.show()
