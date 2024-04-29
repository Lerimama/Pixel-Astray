extends GameHud


onready var level_up_popup: Control = $Popups/LevelUp # za eternal
onready var level_limit_holder: HBoxContainer = $Footer/FooterLine/LevelLimitHolder
onready var level_limit_label_1: Label = $Footer/FooterLine/LevelLimitHolder/Label
onready var level_limit_label_2: Label = $Footer/FooterLine/LevelLimitHolder/Label2
onready var pixel_picked_holder: HBoxContainer = $Footer/FooterLine/StraysLine/PickedHolder
onready var pixel_astray_holder: HBoxContainer = $Footer/FooterLine/StraysLine/AstrayHolder


func _process(delta: float) -> void:
	# namen: dodam čekiranje levela in limite level točk
	
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game_count
	picked_counter.text = "%03d" % Global.game_manager.strays_cleaned_count

	# level label show on fill
	if Global.game_manager.game_data.has("level") and not level_label.visible:
		level_label.visible = true	
			
	# zapis točk do rekorda
	if Global.game_manager.game_settings["eternal_mode"]:
		level_label.text = "%02d" % Global.game_manager.game_data["level"]
		# kateri ima višji score
		var current_biggest_score: int = 0
		for player in get_tree().get_nodes_in_group(Global.group_players):
			if player.player_stats["player_points"] > current_biggest_score:
				current_biggest_score = player.player_stats["player_points"]
		# razlika med limito in višjim skorom
		level_limit_label_1.text = "%d" % (Global.game_manager.level_points_limit - current_biggest_score) 
		level_limit_label_2.text = "POINTS TO LEVEL UP"
	# zapis straysov na mizi
	elif Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:
#		if Global.game_manager.game_data.has("level"):
#		level_label.text = "%s" % Global.game_manager.game_data["level_name"] 
#		level_label.text = "%s" % Global.game_manager.game_data["level"] 
		level_limit_label_1.text = "%d" % Global.game_manager.strays_in_game_count
		level_limit_label_2.text = "COLORS TO PICK"


func set_hud(players_count: int): # kliče main na game-in
	# namen: dodam level points limit counter za eternal in setam hud za enigmo 
	
	if players_count == 1:
		# players
		p1_label.visible = false
		p2_statsline.visible = false
		# popups
		p1_energy_warning_popup = $Popups/EnergyWarning/Solo
	elif players_count == 2:
		# players
		p1_label.visible = true
		p1_color_holder.visible = false
		p2_statsline.visible = true
		p2_color_holder.visible = false
		# popups
		p1_energy_warning_popup = $Popups/EnergyWarning/DuelP1
		p2_energy_warning_popup = $Popups/EnergyWarning/DuelP2
		# hs		
		highscore_label.visible = false
	
	# lajf counter
	if Global.game_manager.game_settings["player_start_life"] == 1:
		p1_life_counter.visible = false
		p2_life_counter.visible = false
	else:
		p1_life_counter.visible = true
		p2_life_counter.visible = true
		
	# level label
	if not Global.game_manager.game_data.has("level"):
		level_label.visible = false
	
	# eternal		
	if Global.game_manager.game_settings["eternal_mode"]:
		p1_energy_counter.visible = false
		p2_energy_counter.visible = false	
		level_limit_holder.visible = true
		strays_counters_holder.visible = false
	
	if Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:
		p1_energy_counter.visible = false
		p1_points_counter.visible = false
		highscore_label.visible = true
		strays_counters_holder.visible = false
		level_limit_holder.visible = true
	
	# glede na to kaj šteje ...
	if current_gamed_hs_type == Profiles.HighscoreTypes.NO_HS:
		if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
			highscore_label.visible = true
		else:
			highscore_label.visible = false
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH or Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW:
		p1_points_holder.visible = false
		p2_points_holder.visible = false
		highscore_label.visible = true
		set_current_highscore()
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_POINTS:
		p1_points_holder.visible = true
		p2_points_holder.visible = true
		highscore_label.visible = true
		set_current_highscore()


func fade_in_instructions_popup(in_time: float):
	# namen: za to igro prilagojena navodila

	if Global.game_manager.game_settings["eternal_mode"]:
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		title.text = Global.game_manager.game_data["game_name"]
		win_label.text = "Collect colors and beat the highscore."
		instructions_label.text = "Game is over when you are out of energy, life or the screen is full of colors."
		instructions_label_2.text = "Energy depletes with travelling."
		instructions_label_3.text = "Bursting power affects the amount of collected colors in stack."
		instructions_label_4.text = "No time limit. Pixels never stop appearing."
		instructions_label_5.text = "Highscore is the highest points total"
		instructions_label_6.text = "Don't try to beat the game. It's useless."
	elif Global.game_manager.game_data["game"] == Profiles.Games.ENIGMA:
		title.text = Global.game_manager.game_data["game_name"]  + " " + Global.game_manager.game_data["level_name"]
		if current_highscore > 0:
			win_label.text = "Current record by " + str(current_highscore_owner) + " is " + str(current_highscore) + " seconds"
		else:
			win_label.text = "This enigma is still unsolved."
		instructions_label.text = ""
		instructions_label_2.text = "Collect all colors with a single burst."
		instructions_label_3.text = Global.game_manager.game_data["level_description"]
		instructions_label_4.text = "Bursting collects all colors in stack, reburst collects one."
		instructions_label_5.text = "No time limit. Highscore is the fastest time."
		instructions_label_6.text = ""
	elif Global.game_manager.game_data["game"] == Profiles.Games.CLEANER:
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		title.text = Global.game_manager.game_data["game_name"]
		win_label.text = "Collect colors and beat the highscore."
		instructions_label.text = "Game is over when you are out of energy or time runs out."
		instructions_label_2.text = "Energy depletes with travelling or hitting a wall."
		instructions_label_3.text = "Bursting power affects the amount of collected colors in stack."
		instructions_label_4.text = "Time is limited."
		instructions_label_5.text = "Highscore is the highest points total."
		instructions_label_6.text = ""
	elif Global.game_manager.game_data["game"] == Profiles.Games.CLEANER_DUEL:
		$Popups/Instructions/Controls.hide()
		$Popups/Instructions/ControlsDuel.show()
		title.text = Global.game_manager.game_data["game_name"]
		win_label.text = "Surviving player or player with higher points total wins."
		instructions_label.text = "Game is over when a player loses all lives or time runs out."
		instructions_label_2.text = "Energy depletes with travelling or hitting a wall."
		instructions_label_3.text = "Bursting power affects the amount of collected colors in stack."
		instructions_label_4.text = "Time is limited."
		instructions_label_5.text = "No highscores."
		instructions_label_6.text = ""
	else: # ERASERji
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		title.text = Global.game_manager.game_data["game_name"]
		win_label.text = "Collect all available colors."
		instructions_label.text = "Game is over when you are out of energy."
		instructions_label_2.text = "Energy depletes with travelling or hitting a wall."
		instructions_label_3.text = "Bursting power affects the amount of collected colors in stack."
		instructions_label_4.text = "Time is unlimited."
		instructions_label_5.text = "Highscore is the fastest time."
		instructions_label_6.text = ""

	var show_instructions_popup = get_tree().create_tween()
	show_instructions_popup.tween_callback(instructions_popup, "show")
	show_instructions_popup.tween_property(instructions_popup, "modulate:a", 1, in_time).from(0.0).set_ease(Tween.EASE_IN)

	
func level_up_popup_in(level_reached: int): 
	# za eternal
	
	level_up_popup.modulate.a = 0
	level_up_popup.get_node("Label").text = "LEVEL UP"
	#	level_up_popup.get_node("Label").text = "LEVEL %s" % str(level_reached)
	level_up_popup.show()
	
	var popup_in = get_tree().create_tween()
	popup_in.tween_property(level_up_popup, "modulate:a", 1, 0.3)


func level_up_popup_out(): # za eternal
	
	var popup_in = get_tree().create_tween()
	popup_in.tween_property(level_up_popup, "modulate:a", 0, 0.3)
	popup_in.tween_callback(level_up_popup, "hide")


func empty_color_indicators(): # za eternal
	
	# zbrišem trenutne indikatorje
	for child in spectrum.get_children():
		child.queue_free()
	active_color_indicators.clear()


func update_stats(stat_owner: Node, player_stats: Dictionary): # za eternal
	# namen: preverjanje števila točk in klic next level v GM (na koncu)	
	
	# player stats
	match stat_owner.name:
		"p1":
			p1_life_counter.life_count = player_stats["player_life"]
			p1_energy_counter.energy = player_stats["player_energy"]
			p1_points_counter.text = "%d" % player_stats["player_points"]
			p1_color_counter.text = "%d" % player_stats["colors_collected"]
			p1_burst_counter.text = "%d" % player_stats["burst_count"]
			p1_skill_counter.text = "%d" % player_stats["skill_count"]
			p1_steps_counter.text = "%d" % player_stats["cells_traveled"]
			check_for_warning(player_stats, p1_energy_warning_popup)
		"p2":
			p2_life_counter.life_count = player_stats["player_life"]
			p2_energy_counter.energy = player_stats["player_energy"]
			p2_points_counter.text = "%d" % player_stats["player_points"]
			p2_color_counter.text = "%d" % player_stats["colors_collected"]
			p2_burst_counter.text = "%d" % player_stats["burst_count"]
			p2_skill_counter.text = "%d" % player_stats["skill_count"]
			p2_steps_counter.text = "%d" % player_stats["cells_traveled"]
			check_for_warning(player_stats, p2_energy_warning_popup)

	# debug
	player_life.text = "LIFE: %d" % player_stats["player_life"]
	player_energy.text = "E: %d" % player_stats["player_energy"]

	if not Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.NO_HS:
		check_for_hs(player_stats)
	
	if Global.game_manager.game_settings["eternal_mode"]:
		if player_stats["player_points"] >= Global.game_manager.level_points_limit:
			Global.game_manager.upgrade_level()
