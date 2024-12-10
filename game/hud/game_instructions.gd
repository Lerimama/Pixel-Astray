extends Control


signal players_ready # za splitscreen popup

onready var title: Label = $Title
onready var description: Label = $Description
onready var outline: = $Outline
onready var record_panel: Panel = $Outline/Record

onready var shortcuts: Panel = $Outline/Shortcuts
onready var controls: Control = $Outline/Controls
onready var record_panel_mobile: Panel = $Outline/RecordMobile
onready var action_hint_press: Node2D = $ActionHintPress
onready var hint_btn: Button = $ActionHintPress/HintBtn


func _ready() -> void:

	action_hint_press.hide() # zaradi pavze


func open(): # kliče GM set game

#	ready_btn.show() # zaradi pavze
	get_instructions_content()
	action_hint_press.show()
	hint_btn.grab_focus()
	show() # fade-in se zgodi zaradi game scene

	get_tree().set_pause(true)


func get_instructions_content(): # kliče tudi pavza na ready

	var current_game_data: Dictionary = Global.game_manager.game_data
	var current_hs_line: Array = Data.get_top_highscore(current_game_data)
	var current_highscore: float = current_hs_line[0]
	var current_highscore_owner: String = current_hs_line[1]

	# game title
	if current_game_data["game"] == Profiles.Games.SWEEPER: # samo enigam ima številko levela
		title.text = current_game_data["game_name"] + " %02d" % current_game_data["level"]
	else:
		title.text = current_game_data["game_name"]

	# description
	description.text = current_game_data["description"]

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

		var record_title: Label = record_holder_to_fill.get_node("VBoxContainer/RecordTitle")
		var record_label: Label = record_holder_to_fill.get_node("VBoxContainer/RecordLabel")
		var record_owner: Label = record_holder_to_fill.get_node("VBoxContainer/RecordOwner")

		record_title.text = "Current record"
		# no record
		if current_highscore == 0:
			record_owner.text = "No record yet ..."
			record_label.hide()
		# time
		elif current_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME:
			var clock_record: String = Global.get_clock_time(current_highscore)
			record_label.text = clock_record
			record_label.show()
			record_owner.text = "by " + str(current_highscore_owner)
		# points
		else:
			record_label.text = str(current_highscore) + " points"
			record_label.show()
			record_owner.text = "by " + str(current_highscore_owner)

	# shorts
	if Profiles.touch_available and not Profiles.set_touch_controller == Profiles.TOUCH_CONTROLLER.DISABLED:
		shortcuts.hide()
	else:
		shortcuts.show()
		var hint_shortie: Control = shortcuts.get_node("Shortcuts").get_child(shortcuts.get_node("Shortcuts").get_child_count() - 1)
		if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
			hint_shortie.show()
		else:
			hint_shortie.hide()

		# game props (koda za več njih)
		for prop in outline.get_children():
			if prop.get_child(0).name == "PropLabel":
				var prop_label: Label = prop.get_node("PropLabel")
				if current_game_data.has(str(prop.name)): # če ima slovar igre to postavko ...
					prop.show()
					prop_label.text = current_game_data["%s" % prop.name] # ... jo napolni z njeno vsebino
					if not Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
						shortcuts.hide()
				else:
					prop.hide()

	# player controls
	var def_min_y: float = 168
	var touch_min_y: float = 288
	var ctrls_wide: Control = controls.get_child(0)
	for ctrl_node in ctrls_wide.get_children():
		ctrl_node.hide()
	if Profiles.touch_available and not Profiles.set_touch_controller == Profiles.TOUCH_CONTROLLER.DISABLED:
		controls.rect_min_size.y = touch_min_y
		var touch_ctrl_name: String
		match Profiles.set_touch_controller:
			Profiles.TOUCH_CONTROLLER.BUTTONS_LEFT: touch_ctrl_name = "Buttons_L"
			Profiles.TOUCH_CONTROLLER.BUTTONS_RIGHT: touch_ctrl_name = "Buttons_R"
			Profiles.TOUCH_CONTROLLER.SCREEN_LEFT: touch_ctrl_name = "Sliding_L"
			Profiles.TOUCH_CONTROLLER.SCREEN_RIGHT: touch_ctrl_name = "Sliding_R"
		ctrls_wide.get_node(touch_ctrl_name).show()
	else:
		controls.rect_min_size.y = def_min_y
		if Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
			ctrls_wide.get_node("2P").show()
		else:
			ctrls_wide.get_node("1P").show()
	controls.show()


func confirm_players_ready():

	get_tree().set_pause(false)

	yield(get_tree().create_timer(0.5), "timeout") # da se kamera centrira

	var out_time: float = 0.5
	var hide_instructions_popup = get_tree().create_tween()
	hide_instructions_popup.tween_property(self, "modulate:a", 0, out_time)#.set_ease(Tween.EASE_IN)
	yield(hide_instructions_popup, "finished")

	emit_signal("players_ready")
	hide()



func _on_HintBtn_pressed() -> void:

	hint_btn.disabled = true
	confirm_players_ready()
	Analytics.save_ui_click("ReadyBtn")
