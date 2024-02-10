extends GameHud

	
func set_hud(players_count: int): # kliče main na game-in
	# namen: ikone v player statline, samo 1 player, ni lajfov, ni energije, level data je vis tudi če je prazen, energy counter

	# players
	p1_label.visible = false
	p2_statsline.visible = false
#	strays_counters_holder.visible = false
	
	# if Global.game_manager.game_data["game"] == Profiles.Games.SIDEWINDER:
#	p1_color_holder.visible = false	

	# popups
	p1_energy_warning_popup = $Popups/EnergyWarning/Solo	

	# lajf counter
	if Global.game_manager.game_settings["player_start_life"] == 1:
		p1_life_counter.visible = false
	else:
		p1_life_counter.visible = true

	# energy counter
	if Global.game_manager.game_data["game"] == Profiles.Games.AMAZE:
		p1_energy_counter.visible = true
#	if Global.game_manager.game_data["game"] == Profiles.Games.SIDEWINDER:
#		p1_energy_counter.visible = false

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
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_COLORS:
		p1_points_holder.visible = false
		p1_color_holder.visible = true
		highscore_label.visible = true
		set_current_highscore()
	
	
func slide_in(players_count: int): # kliče GM set_game()
	# namen: indikatorji ostanejo alpha 1
	
	set_hud(players_count)
	
	get_tree().call_group(Global.group_player_cameras, "zoom_in", hud_in_out_time, players_count)
	
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	fade_in.tween_property(header, "rect_position:y", 0, hud_in_out_time)
	fade_in.parallel().tween_property(footer, "rect_position:y", screen_height - header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", Global.hud.header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", Global.hud.header_height, hud_in_out_time)
	
	yield(Global.player1_camera, "zoomed_in")
	
#	for indicator in active_color_indicators:
#		var indicator_fade_in = get_tree().create_tween()
#		indicator_fade_in.tween_property(indicator, "modulate:a", unpicked_indicator_alpha, 0.3).set_ease(Tween.EASE_IN)
#
#	if players_count == 2:
#		fade_splitscreen_popup()
#		fade_splitscreen_popup()
#	else:
#		Global.start_countdown.start_countdown() # GM yielda za njegov signal
#	fade_splitscreen_popup()
	Global.start_countdown.start_countdown() # GM yielda za njegov signal
	
	
func show_color_indicator(picked_color: Color):
	# namen: pobrani indikatorji potemnijo

	picked_indicator_alpha = 0.3

	var current_indicator_index: int
	for indicator in active_color_indicators:
		# pobrana barva
		if indicator.color == picked_color:
			current_indicator_index = active_color_indicators.find(indicator)
			indicator.modulate.a = picked_indicator_alpha
			break

	# izbris iz aktivnih indikatorjev
	if not active_color_indicators.empty():
		active_color_indicators.erase(active_color_indicators[current_indicator_index])


func deactivate_all_indicators():
	
	picked_indicator_alpha = 0.3
	
	for indicator in active_color_indicators:
		indicator.modulate.a = picked_indicator_alpha
		# animacija deaktivacije
		var current_indicator_index: int = active_color_indicators.find(indicator)
		if current_indicator_index % 20 == 0:
			yield(get_tree().create_timer(0.05), "timeout")

	# izbris aktivnih indikatorjev
	if not active_color_indicators.empty():
		active_color_indicators.clear()
