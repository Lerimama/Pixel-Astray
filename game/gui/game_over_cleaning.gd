extends GameOver


onready var timeup_label: Label = $GameoverTitle/ReasonTime/TimeupLabel


func set_game_gameover_title():
	# namen: sprememba teksta v GO - TIME komentarju glede na to katera igra je
	
	if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		var gameover_title_tutorial: Control = $GameoverTitle/Tutorial
		match current_gameover_reason:
			Global.game_manager.GameoverReason.CLEANED:
				gameover_title_tutorial.get_node("Finished").show()
				selected_gameover_title = gameover_title_tutorial
				selected_gameover_jingle = "win_jingle"
			Global.game_manager.GameoverReason.LIFE:
				gameover_title_tutorial.get_node("NotFinished").show()
				selected_gameover_title = gameover_title_tutorial
				selected_gameover_jingle = "lose_jingle"
		selected_gameover_menu = selected_gameover_title.get_node("Menu")
		focus_btn = selected_gameover_menu.get_node("QuitBtn")
	else:
		match current_gameover_reason:
			Global.game_manager.GameoverReason.CLEANED:
				selected_gameover_title = gameover_title_cleaned
				selected_gameover_jingle = "win_jingle"
				name_input_label.text = "Great work!"
			Global.game_manager.GameoverReason.LIFE:
				selected_gameover_title = gameover_title_life
				selected_gameover_jingle = "lose_jingle"
				name_input_label.text = "But still ... "
			Global.game_manager.GameoverReason.TIME:
				if Global.game_manager.game_data["game"] == Profiles.Games.ETERNAL:
					timeup_label.text = "Too colorful?"
				else:
					timeup_label.text = "You are out of time!"
				selected_gameover_title = gameover_title_time
				selected_gameover_jingle = "lose_jingle"
				name_input_label.text = "But still ... "
