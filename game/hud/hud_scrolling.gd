#extends Control
extends GameHud


func _process(delta: float) -> void:
	
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game_count
	picked_counter.text = "%03d" % Global.game_manager.strays_cleaned_count
	level_label.text = "%02d" % Global.game_manager.current_level 
	
	
func set_hud(players_count: int): # kliče main na game-in
	# namen: ikone v player statline
	if players_count == 1:
		# players
		p1_label.visible = false
		p2_statsline.visible = false
		# strays count off
		p1_color_holder.visible = false
		# popups
		p1_energy_warning_popup = $Popups/EnergyWarning/Solo
	elif players_count == 2:
		# players
		p1_label.visible = true
		p2_statsline.visible = true
		# strays count off
		p1_color_holder.visible = false
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

	# energy counter
	if Global.game_manager.game_settings["cell_traveled_energy"] == 0: 
		p1_energy_counter.visible = false
		p2_energy_counter.visible = false

	# level label
	if Global.game_manager.game_data["level"].empty():
		level_label.visible = false

	# glede na to kaj šteje ...
	if current_gamed_hs_type == Profiles.HighscoreTypes.NO_HS:
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


#func set_current_highscore():
#
#	var current_game = Global.game_manager.game_data["game"]
#	var current_highscore_line: Array = Global.data_manager.get_top_highscore(current_game)
#
#	current_highscore = current_highscore_line[0]
#	current_highscore_owner = current_highscore_line[1]
#
#	if current_gamed_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH or Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW:
#		highscore_label.text = "Highscore " + str(current_highscore) + "s"
#	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_POINTS:
#		highscore_label.text = "Highscore " + str(current_highscore)
#
#
#
		
func fade_splitscreen_popup():
	
	var show_splitscreen_popup = get_tree().create_tween()
	show_splitscreen_popup.tween_callback(splitscreen_popup, "show")
	show_splitscreen_popup.tween_property(splitscreen_popup, "modulate:a", 1, 1).from(0.0).set_ease(Tween.EASE_IN)

	yield(self, "players_ready")
	
	var hide_splitscreen_popup = get_tree().create_tween()
	hide_splitscreen_popup.tween_property(splitscreen_popup, "modulate:a", 0, 1).set_ease(Tween.EASE_IN)
	hide_splitscreen_popup.tween_callback(splitscreen_popup, "hide")
	hide_splitscreen_popup.tween_callback(get_viewport(), "set_disable_input", [false]) # anti dablklik
	hide_splitscreen_popup.tween_callback(Global.start_countdown, "start_countdown")	


# SPECTRUM ---------------------------------------------------------------------------------------------------------------------------


func spawn_color_indicators(available_colors: Array): # kliče GM
	
	var indicator_index = 0 # za fiksirano zaporedje
	
	for color in available_colors:
		indicator_index += 1 
		# spawn indicator
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = color
		
		# SCROLLER
#		if not Global.game_manager.game_data["game"] == Profiles.Games.SCROLLER:
#			new_color_indicator.modulate.a = 1 # na fade-in se odfejda do unpicked_indicator_alpha
#		else:
		if Global.game_manager.current_progress_type == Global.game_manager.LevelProgressType.FLOOR_CLEARED:
			new_color_indicator.modulate.a = 1
		else:
			new_color_indicator.modulate.a = 0.3
		spectrum.add_child(new_color_indicator)
		active_color_indicators.append(new_color_indicator)


func empty_color_indicators():
#func update_indicator_on_level_up(current_level: int):
	
	# izberem barvno shemo
#	var color_scheme_name: String = "color_scheme_%s" % current_level
#	Profiles.current_color_scheme = Profiles.game_color_schemes[color_scheme_name]
	
	# zbrišem trenutne indikatorje
	for child in spectrum.get_children():
		child.queue_free()
	active_color_indicators.clear()
	
	# naštimam nove indikatorje
#	Global.game_manager.set_level_colors() 	
	
	
func update_indicator_on_stage_up(current_stage: int): 
	
	# current stage ni pomemben, ker zmeraj obarvam prvega v aktivnih
	# obarvam indikator
	if not active_color_indicators.empty(): # zazih
		var current_indicator = active_color_indicators.front()
		current_indicator.modulate.a = 1
		# izbris iz aktivnih indikatorjev
		active_color_indicators.pop_front()

					
func show_color_indicator(picked_color: Color):

	return # player kliče, ampak v scrollerju se nič ne zgodi

