extends Control


onready var title: Label = $Title
onready var description: Label = $GameInstructions/Description
onready var record_label_holder: Panel = $GameInstructions/Outline/Record
onready var record_owner: Label = $GameInstructions/Outline/Record/RecordOwner
onready var record_label: Label = $GameInstructions/Outline/Record/RecordLabel
onready var outline: FlowContainer = $GameInstructions/Outline
onready var shortcuts: Panel = $GameInstructions/Outline/Shortcuts
onready var controls: Control = $GameInstructions/Outline/Controls
onready var controls_duel: Control = $GameInstructions/Outline/ControlsDuel


func get_instructions_content(current_highscore, current_highscore_owner):
	
	var current_game_data: Dictionary = Global.game_manager.game_data
	
	# game title
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER: # samo enigam ima številko levela
		title.text = current_game_data["game_name"] + " %02d" % current_game_data["level"]
	else:
		title.text = current_game_data["game_name"]
	# description		
	description.text = current_game_data["description"]
	
	# highscore
	if current_game_data["highscore_type"] == Profiles.HighscoreTypes.NO_HS or current_highscore == 0:
		record_label_holder.hide()
	else:	
		record_label_holder.show()
		if current_game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_HIGH or current_game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW:
			var clock_record: String = Global.get_clock_time(current_highscore)
			record_label.text = clock_record#  + " seconds"
			record_owner.text = "by " + str(current_highscore_owner)
		else: # standard
			record_label.text = str(current_highscore)
			record_owner.text = "by " + str(current_highscore_owner)

	# player controls 			
	if Global.game_manager.start_players_count == 1:
		controls.show()
		controls_duel.hide()
	else:
		controls.hide()
		controls_duel.show()
		
	# game props
	var props_count: int
	var props_count_limit: int = 4
	if record_label_holder.visible: # znižam mejo, če je rekord prisoten
		props_count_limit -= 1
	if controls_duel.visible: # znižam mejo, če je rekord prisoten, če sta dva plejerja
		props_count_limit -= 1
	for prop in outline.get_children():
		if prop.get_child(0).name == "PropLabel":
			props_count += 1
			var prop_label: RichTextLabel = prop.get_node("PropLabel")
			if current_game_data.has(str(prop.name)) and props_count <= props_count_limit: # če ima slovar igre to postavko ...
				prop.show()
				prop_label.bbcode_text = current_game_data["%s" % prop.name] # ... jo napolni z njeno vsebino
			else:
				props_count -= 1
				prop.hide()
	
	# shortcuts
	if record_label_holder.visible and props_count > 2:
		shortcuts.hide()
	elif controls_duel.visible:
		shortcuts.hide()
	else:
		if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
			shortcuts.get_node("Shortcuts/Hint").show()
		else:
			shortcuts.get_node("Shortcuts/Hint").hide()
		shortcuts.show()


