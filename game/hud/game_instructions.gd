extends Control


onready var title: Label = $GameInstructions/Title
onready var description: Label = $GameInstructions/Description
onready var record_label: Label = $GameInstructions/Outline/RecordLabel
onready var record_title: Label = $GameInstructions/Outline/RecordLabel/RecordTitle
onready var outline: VBoxContainer = $GameInstructions/Outline
onready var controls: Control = $Controls
onready var controls_duel: Control = $ControlsDuel


func get_instructions_content(current_highscore, current_highscore_owner):
		
	var current_game_data: Dictionary = Global.game_manager.game_data
	
	# obvezne alineje
	if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA: # samo enigam ima številko levela
		title.text = current_game_data["game_name"] + " %02d" % current_game_data["level"]
	else:
		title.text = current_game_data["game_name"]
		
	description.text = current_game_data["description"]
	
	# hajskor glede na tip
	if current_game_data["highscore_type"] == Profiles.HighscoreTypes.NO_HS:
		record_label.hide()
	else:
		if current_game_data["highscore_type"] == Profiles.HighscoreTypes.HS_POINTS:
			record_title.text = "Current record:"
			if current_highscore == 0:
				record_label.self_modulate = Global.color_gui_gray
				record_label.text = "No record points set yet."
			else:
#				record_label.modulate = Global.color_green
				record_label.text = str(current_highscore) + " points by " + str(current_highscore_owner)
		elif current_game_data["highscore_type"] == Profiles.HighscoreTypes.HS_COLORS:
			record_title.text = "Current record:"
			if current_highscore == 0:
				record_label.self_modulate = Global.color_gui_gray
				record_label.text = "No record colors count set yet."
			else:
#				record_label.modulate = Global.color_green
				record_label.text = str(current_highscore) + " colors picked by " + str(current_highscore_owner)
		else: # TIME HIGH and LOW
			record_title.text = "Current record:"
			if current_highscore == 0:
				record_label.self_modulate = Global.color_gui_gray
				record_label.text = "No record time set yet."
			else:
#				record_label.modulate = Global.color_green
				record_label.text = str(current_highscore) + " seconds by " + str(current_highscore_owner)

	# poljubne alineje
	for label in outline.get_children():
		if not label == record_label:
			if current_game_data.has(str(label.name)): # če ima slovar igre to postavko ...
				label.show()
				label.text = current_game_data["%s" % label.name] # ... jo napolni z njeno vsebino
			else:
				label.hide() # ali pa jo skrij
	
	# controls slikca			
	if current_game_data["game"] == Profiles.Games.THE_DUEL:
		controls.hide()
		controls_duel.show()
	else:
		controls.show()
		controls_duel.hide()
