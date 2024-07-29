extends Control


onready var title: Label = $Title
onready var description: Label = $Description
onready var record_label_holder: Panel = $Outline/Record
onready var record_title: Label = $Outline/Record/VBoxContainer/RecordTitle
onready var record_label: Label = $Outline/Record/VBoxContainer/RecordLabel
onready var record_owner: Label = $Outline/Record/VBoxContainer/RecordOwner
onready var outline: = $Outline
onready var shortcuts: Panel = $Outline/Shortcuts
onready var controls: Control = $Outline/Controls
onready var controls_duel_p1: Control = $Outline/ControlsDuelP1
onready var controls_duel_p2: Control = $Outline/ControlsDuelP2


func get_instructions_content(current_highscore: int = 0, current_highscore_owner: String = "Nobody"):
	
	var current_game_data: Dictionary = Global.game_manager.game_data
	
	# game title
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER: # samo enigam ima številko levela
		title.text = current_game_data["game_name"] + " %02d" % current_game_data["level"]
	else:
		title.text = current_game_data["game_name"]
	
	# description		
	description.text = current_game_data["description"]
	
	# highscore
	if current_game_data["highscore_type"] == Profiles.HighscoreTypes.NONE:# or current_highscore == 0:
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
	if Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
		controls.hide()
		controls_duel_p1.show()
		controls_duel_p2.show()
	else:
		controls.show()
		controls_duel_p1.hide()
		controls_duel_p2.hide()
		
	# game props
	for prop in outline.get_children():
		if prop.get_child(0).name == "PropLabel":
			var prop_label: Label = prop.get_node("PropLabel")
			if current_game_data.has(str(prop.name)): # če ima slovar igre to postavko ...
				prop.show()
				prop_label.text = current_game_data["%s" % prop.name] # ... jo napolni z njeno vsebino
			else:
				prop.hide()
