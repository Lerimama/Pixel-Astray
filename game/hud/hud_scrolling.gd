#extends Control
extends GameHud


onready var level_up_popup: Control = $Popups/LevelUp



func _process(delta: float) -> void:
	
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game_count
	picked_counter.text = "%03d" % Global.game_manager.strays_cleaned_count
	level_label.text = "%02d" % Global.game_manager.current_level 
	
	
func set_hud(players_count: int): # kliče main na game-in
	# namen: ikone v player statline, samo 1 player, ni lajfov, ni energije, level data je vis tudi če je prazen

	# players
	p1_label.visible = false
	p2_statsline.visible = false
	# strays count off
	p1_color_holder.visible = false
	# popups
	p1_energy_warning_popup = $Popups/EnergyWarning/Solo	

	# lajf counter
	if Global.game_manager.game_settings["player_start_life"] == 1:
		p1_life_counter.visible = false
	else:
		p1_life_counter.visible = true

	# energy counter
	if Global.game_manager.game_settings["cell_traveled_energy"] == 0: 
		p1_energy_counter.visible = false

	# level label
	if Global.game_manager.game_data["level"].empty():
		level_label.visible = false

	# glede na to kaj šteje ...
	if current_gamed_hs_type == Profiles.HighscoreTypes.NO_HS:
		highscore_label.visible = false
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH or Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW:
		p1_points_holder.visible = false
		highscore_label.visible = true
		set_current_highscore()
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_POINTS:
		p1_points_holder.visible = true
		highscore_label.visible = true
		set_current_highscore()


func level_up_popup_in(level_reached: int):
	
	level_up_popup.get_node("Label").text = "BRAVO! You have reached Level %s." % str(level_reached)
	level_up_popup.show()
	level_up_popup.modulate.a = 0
	
	var popup_in = get_tree().create_tween()
	popup_in.tween_property(level_up_popup, "modulate:a", 1, 0.3)


func level_up_popup_out():
	
	var popup_in = get_tree().create_tween()
	popup_in.tween_property(level_up_popup, "modulate:a", 0, 0.3)
	popup_in.tween_callback(level_up_popup, "hide")
				
						
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


func check_for_warning(player_stats: Dictionary, warning_popup: Control):
	# namen drugače prikaže in čekira
	
	if warning_popup:
		var steps_remaining_label: Label
		steps_remaining_label = warning_popup.get_node("StepsRemaining")
		if player_stats["player_energy"] < Global.game_manager.game_settings["player_tired_energy"]:
			steps_remaining_label.text = "LOW ENERGY WARNING!"
#			steps_remaining_label.text = "ENERGY WARNING! Only %s steps remaining." % str(player_stats["player_energy"] - 1)
			if warning_popup.visible == false:
				warning_in(warning_popup)
		elif player_stats["player_energy"] > Global.game_manager.game_settings["player_tired_energy"]:
			if warning_popup.visible == true:
				warning_out(warning_popup)
		elif player_stats["player_energy"] <= 0:
			if warning_popup.visible == true:
				warning_out(warning_popup)		
	
#		if player_stats["player_energy"] == 0:
#			if warning_popup.visible == true:
#				warning_out(warning_popup)		
#		elif player_stats["player_energy"] == 1:
#			steps_remaining_label.text = "NO ENERGY! Collect a color to revitalize."
#		elif player_stats["player_energy"] == 2: # pomeni samo še en korak in rabim ednino
#			steps_remaining_label.text = "ENERGY WARNING! Only 1 step remaining."
#			if warning_popup.visible == false:
#				warning_in(warning_popup)
#		elif player_stats["player_energy"] <= Global.game_manager.game_settings["player_tired_energy"]:
#			steps_remaining_label.text = "ENERGY WARNING! Only %s steps remaining." % str(player_stats["player_energy"] - 1)
#			if warning_popup.visible == false:
#				warning_in(warning_popup)
#		elif player_stats["player_energy"] > Global.game_manager.game_settings["player_tired_energy"]:
#			if warning_popup.visible == true:
#				warning_out(warning_popup)