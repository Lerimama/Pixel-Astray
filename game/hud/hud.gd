extends Control
class_name GameHud


signal players_ready # za splitscreen popup

var tired_energy_limit: float = 20

# spectrum
var picked_indicator_alpha: float = 1
var unpicked_indicator_alpha: float = 0.2
var neighbor_indicator_alpha: float = 0.4
var active_color_indicators: Array = [] # indikatorji spawnani že ob spawnanju pixlov

# hs
var current_highscore: float
var current_highscore_owner: String

# in/out
var hud_in_out_time: int = 2
var screen_height:int = 720
onready var header: Control = $Header # kontrole iz kamere
onready var header_height: int = header.rect_size.y
onready var viewport_header: ColorRect = $"%ViewHeder"
onready var viewport_footer: ColorRect = $"%ViewFuter"

# popups 
var p1_energy_warning_popup: Control
var p2_energy_warning_popup: Control
onready var energy_warning_holder: Control = $Popups/EnergyWarning
onready var instructions_popup: Control = $Popups/Instructions

# header
onready var game_timer: HBoxContainer = $Header/GameTimerHunds
onready var highscore_label: Label = $Header/TopLineR/HighscoreLabel
onready var music_player: Label = $Header/TopLineR/MusicPlayer
# p1
onready var p1_label: Label = $Header/TopLineL/PlayerLabel
onready var p1_life_counter: HBoxContainer = $Header/TopLineL/LifeIcons
onready var p1_energy_counter: HBoxContainer = $Header/TopLineL/EnergyBar
onready var p1_points_holder: HBoxContainer = $Header/TopLineL/PointsHolder
onready var p1_points_counter: Label = $Header/TopLineL/PointsHolder/Points
onready var p1_color_holder: HBoxContainer = $Header/TopLineL/ColorHolder
onready var p1_color_counter: Label = $Header/TopLineL/ColorHolder/Label
onready var p1_skill_counter: Label = $Header/TopLineL/SkillHolder/Label
onready var p1_burst_counter: Label = $Header/TopLineL/BurstHolder/Label
onready var p1_steps_holder: HBoxContainer = $Header/TopLineL/StepsHolder
onready var p1_steps_counter: Label = $Header/TopLineL/StepsHolder/Label
# p2
onready var p2_statsline: HBoxContainer = $Header/TopLineR/PlayerLineR
onready var p2_life_counter: HBoxContainer = $Header/TopLineR/PlayerLineR/LifeIcons
onready var p2_energy_counter: HBoxContainer = $Header/TopLineR/PlayerLineR/EnergyBar
onready var p2_points_holder: HBoxContainer = $Header/TopLineR/PlayerLineR/PointsHolder
onready var p2_points_counter: Label = $Header/TopLineR/PlayerLineR/PointsHolder/Points
onready var p2_color_holder: HBoxContainer = $Header/TopLineR/PlayerLineR/ColorHolder
onready var p2_color_counter: Label = $Header/TopLineR/PlayerLineR/ColorHolder/Label
onready var p2_skill_counter: Label = $Header/TopLineR/PlayerLineR/SkillHolder/Label
onready var p2_burst_counter: Label = $Header/TopLineR/PlayerLineR/BurstHolder/Label
onready var p2_steps_holder: HBoxContainer = $Header/TopLineR/PlayerLineR/StepsHolder
onready var p2_steps_counter: Label = $Header/TopLineR/PlayerLineR/StepsHolder/Label

# futer
onready var footer: Control = $Footer # kontrole iz kamere
onready var game_label: Label = $Footer/FooterLine/GameLine/Game
onready var level_label: Label = $Footer/FooterLine/GameLine/Level
onready var strays_counters_holder: HBoxContainer = $Footer/FooterLine/StraysLine
onready var astray_counter: Label = $Footer/FooterLine/StraysLine/AstrayHolder/Label
onready var picked_counter: Label = $Footer/FooterLine/StraysLine/PickedHolder/Label
onready var spectrum: HBoxContainer = $Footer/FooterLine/SpectrumHolder/ColorSpectrum
onready var ColorIndicator: PackedScene = preload("res://game/hud/hud_color_indicator.tscn")
onready var current_gamed_hs_type: int = Global.game_manager.game_data["highscore_type"]

# debug
onready var player_life: Label = $Life
onready var player_energy: Label = $Energy

# neu
onready var level_up_popup: Control = $Popups/LevelUp
onready var level_limit_holder: HBoxContainer = $Footer/FooterLine/LevelLimitHolder
onready var level_limit_label_1: Label = $Footer/FooterLine/LevelLimitHolder/Label
onready var level_limit_label_2: Label = $Footer/FooterLine/LevelLimitHolder/Label2
onready var pixel_picked_holder: HBoxContainer = $Footer/FooterLine/StraysLine/PickedHolder
onready var pixel_astray_holder: HBoxContainer = $Footer/FooterLine/StraysLine/AstrayHolder

	
func _input(event: InputEvent) -> void:
	
	if instructions_popup.visible and Input.is_action_just_pressed("ui_accept"):
		confirm_players_ready()

	
func _ready() -> void:
	
	Global.hud = self
	
	header.rect_position.y = - header_height
	footer.rect_position.y = screen_height
		
	game_label.text = Global.game_manager.game_data["game_name"]
	if Global.game_manager.game_data.has("level"):
		level_label.text = "%02d" % Global.game_manager.game_data["level"]
	
	# setam transparenco barva indikatorja ... če želim obratno, samo tukaj obrnem
	picked_indicator_alpha = 0.2
	unpicked_indicator_alpha = 1

	
	# hud barva vseh elementov, razen tisih, ki modulirajo sami sebe in P oznake
	# p1 stats
#	var nodes_to_modulate: Array = [$Header/TopLineL/ColorHolder, 
#					$Header/TopLineL/StepsHolder, 
#					$Header/TopLineL/SkillHolder, 
#					$Header/TopLineL/BurstHolder, 
#					$Header/TopLineL/PointsHolder]
#	# p2 stats
#	nodes_to_modulate.append_array([$Header/TopLineR/PlayerLineR/ColorHolder, 
#					$Header/TopLineR/PlayerLineR/StepsHolder, 
#					$Header/TopLineR/PlayerLineR/SkillHolder, 
#					$Header/TopLineR/PlayerLineR/BurstHolder, 
#					$Header/TopLineR/PlayerLineR/PointsHolder])
#	# game stats
#	nodes_to_modulate.append_array([$Header/TopLineR/MusicPlayer,
#					$Header/TopLineR/HighscoreLabel,
#					$Footer/FooterLine/GameLine,
#					$Footer/FooterLine/StraysLine,
#					$Footer/FooterLine/LevelLimitHolder])
#	for node in nodes_to_modulate:
#		node.modulate = Color.white
	
	# hud barva elementov, ki ne modulirajo sami sebe in niso label (v glavnem ikone)
	# timer in hs sta label, moduliran med igro, zato imata na nodetu setano font color override na belo
	# p1 stats
	var nodes_to_modulate: Array = [$Header/TopLineL/ColorHolder/TextureRect5, 
					$Header/TopLineL/StepsHolder/TextureRect5, 
					$Header/TopLineL/SkillHolder/TextureRect5, 
					$Header/TopLineL/BurstHolder/TextureRect6, 
					$Header/TopLineL/PointsHolder/TextureRect4]
	# p2 stats
	nodes_to_modulate.append_array([$Header/TopLineR/PlayerLineR/PointsHolder/TextureRect4, 
					$Header/TopLineR/PlayerLineR/ColorHolder/TextureRect5, 
					$Header/TopLineR/PlayerLineR/StepsHolder/TextureRect5, 
					$Header/TopLineR/PlayerLineR/SkillHolder/TextureRect5, 
					$Header/TopLineR/PlayerLineR/BurstHolder/TextureRect6])
	# game stats
	nodes_to_modulate.append_array([$Header/TopLineR/MusicPlayer/OnIcon, 
					$Header/TopLineR/MusicPlayer/OffIcon,
					$Footer/FooterLine/StraysLine/AstrayHolder/TextureRect3, 
					$Footer/FooterLine/StraysLine/PickedHolder/TextureRect2])
	for node in nodes_to_modulate:
		node.modulate = Global.color_hud_text	


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
	if Global.game_manager.game_settings["lose_life_on_hit"] and Global.game_manager.game_settings["player_start_life"] > 1:
		p1_life_counter.visible = true
		p2_life_counter.visible = true
	else:
		p1_life_counter.visible = false
		p2_life_counter.visible = false
		
	# level label
	if not Global.game_manager.game_data.has("level"):
		level_label.visible = false
	
	# eternal	
	if Global.game_manager.game_data.has("level"): # multilevel game
		p1_energy_counter.visible = false
		p2_energy_counter.visible = false	
		level_limit_holder.visible = true
		strays_counters_holder.visible = false
	
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		p1_energy_counter.visible = false
		p1_points_counter.visible = false
		highscore_label.visible = true
		strays_counters_holder.visible = false
		level_limit_holder.visible = true
	
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

	
func level_up_popup_in(level_reached: int): 
	
	level_up_popup.modulate.a = 0
	level_up_popup.get_node("Label").text = "LEVEL UP" # "LEVEL %s" % str(level_reached)
	level_up_popup.show()
	
	var popup_in = get_tree().create_tween()
	popup_in.tween_property(level_up_popup, "modulate:a", 1, 0.3)


func level_up_popup_out():
	
	var popup_in = get_tree().create_tween()
	popup_in.tween_property(level_up_popup, "modulate:a", 0, 0.3)
	popup_in.tween_callback(level_up_popup, "hide")


func empty_color_indicators():
	
	# zbrišem trenutne indikatorje
	for child in spectrum.get_children():
		child.queue_free()
	active_color_indicators.clear()


func update_stats(stat_owner: Node, player_stats: Dictionary):
	
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
		check_for_highscore(player_stats)
	
	if Global.game_manager.game_data.has("level_goal_count") and player_stats["player_points"] >= Global.game_manager.game_data["level_goal_count"]:
		Global.game_manager.upgrade_level("regular")

		
func set_current_highscore():
	
#	var current_game_name = Global.game_manager.game_data["game_name"]
#	var current_game_name = Profiles.Games.keys()[Global.game_manager.game_data["game"]]
#	var current_game_level = Global.game_manager.game_data["level"]
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(Global.game_manager.game_data)
	current_highscore = current_highscore_line[0]
	current_highscore_owner = current_highscore_line[1]
	
	if current_gamed_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH or Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW:
		highscore_label.text = "HS " + str(current_highscore) + "s"
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_POINTS:
		highscore_label.text = "HS " + str(current_highscore)


func check_for_highscore(player_stats: Dictionary):
	
	match current_gamed_hs_type:
		Profiles.HighscoreTypes.HS_POINTS:
			if player_stats["player_points"] > current_highscore:
				highscore_label.text = "New HS " + str(player_stats["player_points"])
				highscore_label.modulate = Global.color_green
			else:				
				highscore_label.text = "HS " + str(current_highscore)
				highscore_label.modulate = Global.color_hud_text
		Profiles.HighscoreTypes.HS_TIME_LOW: # logika je tu malo drugačna kot pri drugih dveh
			highscore_label.text = "HS " + str(current_highscore) + "s"
			highscore_label.modulate = Global.color_hud_text
		Profiles.HighscoreTypes.HS_TIME_HIGH:
			if game_timer.absolute_game_time > current_highscore:
				highscore_label.text = "HS " +  str(game_timer.absolute_game_time) + "s"
				highscore_label.modulate = Global.color_green
			else:				
				highscore_label.text = "HS " +  str(current_highscore) + "s"
				highscore_label.modulate = Global.color_hud_text
		
		
func check_for_warning(player_stats: Dictionary, warning_popup: Control):
	
	if warning_popup:
		var steps_remaining_label: Label
		steps_remaining_label = warning_popup.get_node("StepsRemaining")
	
		if player_stats["player_energy"] <= 0:
			if warning_popup.visible == true:
				warning_out(warning_popup)		
		elif player_stats["player_energy"] == 1:
			steps_remaining_label.text = "NO ENERGY! Collect a color to revitalize."
		elif player_stats["player_energy"] == 2: # pomeni samo še en korak in rabim ednino
			steps_remaining_label.text = "ENERGY WARNING! Only 1 step remaining."
			if warning_popup.visible == false:
				warning_in(warning_popup)
		elif player_stats["player_energy"] <= tired_energy_limit:
			steps_remaining_label.text = "ENERGY WARNING! Only %s steps remaining." % str(player_stats["player_energy"] - 1)
			if warning_popup.visible == false:
				warning_in(warning_popup)
		elif player_stats["player_energy"] > tired_energy_limit:
			if warning_popup.visible == true:
				warning_out(warning_popup)


func warning_in(warning_popup: Control):
	
	var warning_in = get_tree().create_tween()
	warning_in.tween_callback(energy_warning_holder, "show")
	warning_in.tween_callback(warning_popup, "show")
	warning_in.tween_property(warning_popup, "modulate:a", 1, 0.3) #.from(0.0)


func warning_out(warning_popup: Control):
	
	var warning_out = get_tree().create_tween()
	warning_out.tween_property(warning_popup, "modulate:a", 0, 0.5)
	warning_out.tween_callback(warning_popup, "hide")
	warning_out.tween_callback(energy_warning_holder, "hide")


func popups_out(): # kliče GM na gameover
	
	var popups_out = get_tree().create_tween()
	popups_out.tween_property($Popups, "modulate:a", 0, 0.5)
	popups_out.tween_callback($Popups, "hide")

	
func slide_in(players_count: int): # kliče GM set_game()
	
	set_hud(players_count)
	
	# instructions popup
	if Global.game_manager.game_settings["show_game_instructions"]:
		var instructions_popup_time: float = 0.7
		fade_in_instructions_popup(instructions_popup_time)
		yield(self, "players_ready")
		fade_out_instructions_popup(instructions_popup_time)
		yield(get_tree().create_timer(instructions_popup_time), "timeout")
	
	Global.start_countdown.start_countdown() # GM yielda za njegov signal
	
	var solution_line: Line2D
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		solution_line = Global.current_tilemap.get_node("SolutionLine")
		solution_line.hide()
		solution_line.modulate.a = 0.1
		
	Global.game_camera.zoom_in(hud_in_out_time, players_count)
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	if Global.game_manager.game_settings["show_solution_hint"]:
		fade_in.tween_callback(solution_line, "show")
		fade_in.tween_property(solution_line, "modulate:a", 0.1, hud_in_out_time).from(0.0)
	fade_in.parallel().tween_property(header, "rect_position:y", 0, hud_in_out_time)
	fade_in.parallel().tween_property(footer, "rect_position:y", screen_height - header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", header_height, hud_in_out_time)
	
	for indicator in active_color_indicators:
		var indicator_fade_in = get_tree().create_tween()
		indicator_fade_in.tween_property(indicator, "modulate:a", unpicked_indicator_alpha, 0.3).set_ease(Tween.EASE_IN)
	

func slide_out(): # kliče GM na game over
	
	Global.game_camera.zoom_out(hud_in_out_time)
	
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	fade_in.tween_property(header, "rect_position:y", 0 - header_height, hud_in_out_time)
	fade_in.parallel().tween_property(footer, "rect_position:y", screen_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", 0, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", 0, hud_in_out_time)
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		var solution_line: Line2D = Global.current_tilemap.get_node("SolutionLine")
		fade_in.parallel().tween_property(solution_line, "modulate:a", 0, hud_in_out_time)
		fade_in.tween_callback(solution_line, "hide")
	fade_in.tween_callback(self, "hide")
	
	
func fade_in_instructions_popup(in_time: float):

	instructions_popup.get_instructions_content(current_highscore, current_highscore_owner)
	var show_instructions_popup = get_tree().create_tween()
	show_instructions_popup.tween_callback(instructions_popup, "show")
	show_instructions_popup.tween_property(instructions_popup, "modulate:a", 1, in_time).from(0.0).set_ease(Tween.EASE_IN)

	
func fade_out_instructions_popup(out_time: float):
	
	var hide_instructions_popup = get_tree().create_tween()
	hide_instructions_popup.tween_property(instructions_popup, "modulate:a", 0, out_time).set_ease(Tween.EASE_IN)
	hide_instructions_popup.tween_callback(instructions_popup, "hide")
	hide_instructions_popup.tween_callback(get_viewport(), "set_disable_input", [false]) # anti dablklik


func confirm_players_ready():
	get_viewport().set_disable_input(true) # anti dablklik
	Global.sound_manager.play_gui_sfx("btn_confirm")
	emit_signal("players_ready")
	

# SPECTRUM ---------------------------------------------------------------------------------------------------------------------------

	
func spawn_color_indicators(spawn_colors: Array): # kliče GM
	
	var indicator_index = 0 # za fiksirano zaporedje
	var indicator_to_move_under_index: int
	
	for spawn_color in spawn_colors:
		indicator_index += 1 
		# spawn indicator
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = spawn_color
		new_color_indicator.modulate.a = 1 # na fade-in se odfejda do unpicked_indicator_alpha
		spectrum.add_child(new_color_indicator)
		# preverim, če je ista barva že v spektrumu
		for indicator in spectrum.get_children():
			if indicator.color == spawn_color:
				indicator_to_move_under_index = spectrum.get_children().find(indicator)
				break
		# premaknem ga pod obstoječo barvo				
		if indicator_to_move_under_index:
			spectrum.move_child(new_color_indicator, indicator_to_move_under_index)
		# new_color_indicator.get_node("IndicatorCount").text = str(indicator_index) # debug ... zapis indexa
		active_color_indicators.append(new_color_indicator)


func show_color_indicator(picked_color: Color):
	
	# preverim, če je to edina taka barva na igrišču
	var same_color_stray_count: int = 0
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		if stray.stray_color == picked_color:
			same_color_stray_count += 1
			if same_color_stray_count > 1:
				return
		
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


func _on_stat_changed(stat_owner: Node, current_player_stats: Dictionary):
	
	update_stats(stat_owner, current_player_stats)
	

# SIGNALS ---------------------------------------------------------------------------------------------------------------------------


func _on_GameTimer_gametime_is_up() -> void: # signal iz tajmerja
	
	Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)
