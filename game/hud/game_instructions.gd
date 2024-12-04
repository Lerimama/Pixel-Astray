extends Control


signal players_ready # za splitscreen popup

onready var title: Label = $Title
onready var description: Label = $Description
onready var outline: = $Outline
onready var record_label_holder: Panel = $Outline/Record
onready var record_title: Label = $Outline/Record/VBoxContainer/RecordTitle
onready var record_label: Label = $Outline/Record/VBoxContainer/RecordLabel
onready var record_owner: Label = $Outline/Record/VBoxContainer/RecordOwner
onready var shortcuts: Panel = $Outline/Shortcuts
onready var controls: Control = $Outline/Controls
onready var controls_duel_p1: Control = $Outline/ControlsDuelP1
onready var controls_duel_p2: Control = $Outline/ControlsDuelP2
onready var ready_btn: Button = $ReadyBtn
onready var ready_action_hint: HBoxContainer = $ActionHint


func _ready() -> void:

	ready_btn.hide() # zaradi pavze


func open(): # kliče GM set game

	ready_btn.show() # zaradi pavze
	ready_action_hint.show()

	get_instructions_content()
	show() # fade-in se zgodi zaradi game scene

	get_tree().set_pause(true)

	ready_btn.set_focus_mode(FOCUS_ALL) # edino tako dela
	$ReadyBtn.grab_focus() # ne dela?


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

	# highscore
	if current_game_data["highscore_type"] == Profiles.HighscoreTypes.NONE:
		record_label_holder.hide()
	else:
		record_label_holder.show()
		record_title.text = "Current record"
		# no record
		if current_highscore == 0:
			record_owner.text = "No record yet ..."
			record_label.hide()
		# time
		elif current_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME:
			var clock_record: String = Global.get_clock_time(current_highscore)
			record_label.text = clock_record
			record_owner.text = "by " + str(current_highscore_owner)
		# points
		else:
			record_label.text = str(current_highscore) + " points"
			record_owner.text = "by " + str(current_highscore_owner)

	# player controls
	var hint_shortie: Control = shortcuts.get_node("Shortcuts").get_child(shortcuts.get_node("Shortcuts").get_child_count() - 1)
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		hint_shortie.show()
	else:
		hint_shortie.hide()

	if Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
		controls.hide()
		controls_duel_p1.show()
		controls_duel_p2.show()
	else:
		controls.show()
		controls_duel_p1.hide()
		controls_duel_p2.hide()

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


func confirm_players_ready():

	get_tree().set_pause(false)

	yield(get_tree().create_timer(0.5), "timeout") # da se kamera centrira

	var out_time: float = 0.5
	var hide_instructions_popup = get_tree().create_tween()
	hide_instructions_popup.tween_property(self, "modulate:a", 0, out_time)#.set_ease(Tween.EASE_IN)
	yield(hide_instructions_popup, "finished")

	emit_signal("players_ready")
	hide()


func _on_ReadyBtnButton_pressed() -> void:
	$ReadyBtn.grab_focus()
	printt("SDOSOs", get_focus_owner(), ready_btn.disabled, $ReadyBtn.grab_focus())
	Analytics.save_ui_click("ReadyBtn")
	confirm_players_ready()

	ready_btn.hide()
