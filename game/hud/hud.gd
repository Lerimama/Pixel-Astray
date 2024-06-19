extends Control
class_name GameHud


signal players_ready # za splitscreen popup

var tired_energy_limit: float = 20

# spectrum
var stray_in_indicator_alpha: float = 1 # alfa obračam, če ima igra goal
var stray_out_indicator_alpha: float = 0.2
var all_color_indicators: Array = [] # indikatorji spawnani že ob spawnanju pixlov ... nima veze, če je ugasnjen ali prižgan

# hs
var current_highscore: float
var current_highscore_clock: String
var current_highscore_owner: String

# in/out
var hud_in_out_time: int = 2
var screen_height:int = 720
onready var header: Control = $Header # kontrole iz kamere
onready var header_height: int = header.rect_size.y
onready var viewport_header: ColorRect = $"%ViewHeder"
onready var viewport_footer: ColorRect = $"%ViewFuter"

# popups 
onready var energy_warning_popup: Control = $Popups/EnergyWarning
onready var instructions_popup: Control = $Popups/Instructions
onready var level_popup: Control = $Popups/LevelUp

# header
onready var game_timer: HBoxContainer = $Header/GameTimerHunds
onready var highscore_label: Label = $Header/TopLineR/HighscoreLabel
onready var music_track_label: Label = $Header/TopLineR/MusicPlayer/TrackLabel # za pedeneanje imena iz SM in na ready
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

onready var pixel_astray_holder: HBoxContainer = $Footer/FooterLine/StraysLine/AstrayHolder
onready var astray_counter: Label = $Footer/FooterLine/StraysLine/AstrayHolder/Count
onready var pixel_picked_holder: HBoxContainer = $Footer/FooterLine/StraysLine/PickedHolder # trenutno ne rabim
onready var picked_counter: Label = $Footer/FooterLine/StraysLine/PickedHolder/Label # trenutno ne rabim
onready var astray_label: Label = $Footer/FooterLine/StraysLine/AstrayHolder/Label
onready var spectrum: HBoxContainer = $Footer/FooterLine/SpectrumHolder/ColorSpectrum
onready var ColorIndicator: PackedScene = preload("res://game/hud/hud_color_indicator.tscn")
onready var current_gamed_hs_type: int = Global.game_manager.game_data["highscore_type"]

# debug
onready var player_life: Label = $Life
onready var player_energy: Label = $Energy

	
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
		level_label.show()
	else:
		level_label.hide()
	
	if not current_gamed_hs_type == Profiles.HighscoreTypes.NO_HS:
		set_current_highscore()
	
	if Global.game_manager.game_settings["show_game_instructions"]:
		instructions_popup.get_instructions_content(current_highscore, current_highscore_owner)
		yield(get_tree().create_timer(0.2), "timeout")		
		instructions_popup.show()
	else:
		instructions_popup.hide()
		
	# ime komada na vrsti
	var game_music_track_index: int = Global.game_manager.game_settings["game_music_track_index"]
	music_track_label.text = Global.sound_manager.game_music_node.get_children()[game_music_track_index].name
	
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
	nodes_to_modulate.append_array([$Header/TopLineR/MusicPlayer/SpeakerIcon,
					$Footer/FooterLine/StraysLine/AstrayHolder/TextureRect3, 
					$Footer/FooterLine/StraysLine/PickedHolder/TextureRect2])
	for node in nodes_to_modulate:
		node.modulate = Global.color_hud_text	

	
func _process(delta: float) -> void:
	
	astray_counter.text = "%0d" % Global.game_manager.strays_in_game_count

	if level_label.visible: # Global.game_manager.game_data.has("level"):
		level_label.text = "%02d" % Global.game_manager.game_data["level"]
			
			
func set_hud(): # kliče main na game-in
	
	energy_warning_popup.hide()
	astray_label.text = "PIXELS ASTRAY"
	
	if Global.game_manager.start_players_count == 1:
		p1_label.visible = false
		p2_statsline.visible = false
	elif Global.game_manager.start_players_count == 2:
		p1_label.visible = true
		p2_statsline.visible = true
		
	# lajf
	if Global.game_manager.game_settings["player_start_life"] > 1:
		p1_life_counter.visible = true
		p2_life_counter.visible = true
	else:
		p1_life_counter.visible = false
		p2_life_counter.visible = false
	
	# energy
	if Global.game_manager.game_settings["cell_traveled_energy"] == 0:
		p1_energy_counter.visible = false
		p2_energy_counter.visible = false	
	
	# glede na to kaj šteje ...
	if current_gamed_hs_type == Profiles.HighscoreTypes.NO_HS:
		highscore_label.visible = false
	else:
		highscore_label.visible = true
	
	# stotinke na timerju
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		game_timer.get_node("Dots2").show()
		game_timer.get_node("Hunds").show()
		

func set_current_highscore():
	
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(Global.game_manager.game_data)
	current_highscore = current_highscore_line[0]
	current_highscore_clock = Global.get_clock_time(current_highscore)
	current_highscore_owner = current_highscore_line[1]
	
	if current_gamed_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH or Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW:
		highscore_label.text = "HS " + current_highscore_clock
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_POINTS:
		highscore_label.text = "HS " + str(current_highscore)


func slide_in(): # kliče GM set_game()
	
	set_hud()
	
	var solution_line: Line2D
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		solution_line = Global.current_tilemap.get_node("SolutionLine")
		solution_line.hide()
		solution_line.modulate.a = 0.1
		
	Global.game_camera.zoom_in(hud_in_out_time)
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	if Profiles.solution_hint_on:
		fade_in.tween_callback(solution_line, "show")
		fade_in.tween_property(solution_line, "modulate:a", 0.1, hud_in_out_time).from(0.0)
	fade_in.parallel().tween_property(header, "rect_position:y", 0, hud_in_out_time)
	fade_in.parallel().tween_property(footer, "rect_position:y", screen_height - header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", header_height, hud_in_out_time)
	
	if not Global.game_manager.level_goal_mode:
		for indicator in all_color_indicators:
			var indicator_fade_in = get_tree().create_tween()
			indicator_fade_in.tween_property(indicator, "modulate:a", stray_in_indicator_alpha, 0.3).set_ease(Tween.EASE_IN)
	

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
	
	
func confirm_players_ready():
	
	get_viewport().set_disable_input(true) # anti dablklik
	Global.sound_manager.play_gui_sfx("btn_confirm")
	
	var out_time: float = 0.7
	var hide_instructions_popup = get_tree().create_tween()
	hide_instructions_popup.tween_property(instructions_popup, "modulate:a", 0, out_time).set_ease(Tween.EASE_IN)
	hide_instructions_popup.tween_callback(instructions_popup, "hide")
	hide_instructions_popup.tween_callback(get_viewport(), "set_disable_input", [false]) # anti dablklik
	yield(hide_instructions_popup, "finished")
	emit_signal("players_ready")
	

# COLOR INDICATORS ---------------------------------------------------------------------------------------------------------------------------

	
func spawn_color_indicators(spawn_colors: Array): # kliče GM
	
	empty_color_indicators()

	var indicator_index = 0 # za fiksirano zaporedje
	var indicator_to_move_under_index: int
	
	for spawn_color in spawn_colors:
		
		indicator_index += 1 
		
		# spawn indicator
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = spawn_color
		new_color_indicator.modulate.a = stray_out_indicator_alpha # prikažem jih na slide in
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
		all_color_indicators.append(new_color_indicator)


func indicate_color_collected(collected_color: Color):
	
	var current_indicator_index: int
	for indicator in all_color_indicators:
		# pobrana barva
		if indicator.color == collected_color:
			current_indicator_index = all_color_indicators.find(indicator)
			if Global.game_manager.level_goal_mode:
				indicator.modulate.a = stray_in_indicator_alpha
			else: 	
				indicator.modulate.a = stray_out_indicator_alpha
			break


func empty_color_indicators():
	
	# zbrišem trenutne indikatorje
	for child in spectrum.get_children():
		child.queue_free()
	all_color_indicators.clear()


# POPUPS ----------------------------------------------------------------------------------------------------------------------------


func level_popup_fade(level_reached: int):
	
	level_popup.modulate.a = 0
	level_popup.get_node("Label").text = "LEVEL UP" # "LEVEL %s" % str(level_reached)
	level_popup.show()
	
	var popup_in = get_tree().create_tween()
	popup_in.tween_property(level_popup, "rect_scale", Vector2.ONE * 1.2, 1.5).from(Vector2.ONE * 0.8).set_ease(Tween.EASE_IN_OUT)
	popup_in.parallel().tween_property(level_popup, "modulate:a", 1, 0.5)
	popup_in.parallel().tween_property(level_popup, "modulate:a", 0, 0.5).from(1.0).set_delay(0.6)

		
func check_for_warning(player_stats: Dictionary):
	
	var steps_remaining_label: Label
	steps_remaining_label = energy_warning_popup.get_node("StepsRemaining")

	if player_stats["player_energy"] <= 0:
		if energy_warning_popup.visible == true:
			warning_out()		
	elif player_stats["player_energy"] == 1:
		steps_remaining_label.text = "NO ENERGY! Collect a color to revitalize."
	elif player_stats["player_energy"] == 2: # pomeni samo še en korak in rabim ednino
		steps_remaining_label.text = "ENERGY WARNING! Only 1 step remaining."
		if energy_warning_popup.visible == false:
			warning_in()
	elif player_stats["player_energy"] <= tired_energy_limit:
		steps_remaining_label.text = "ENERGY WARNING! Only %s steps remaining." % str(player_stats["player_energy"] - 1)
		if energy_warning_popup.visible == false:
			warning_in()
	elif player_stats["player_energy"] > tired_energy_limit:
		if energy_warning_popup.visible == true:
			warning_out()


func warning_in():
	
	var warning_in = get_tree().create_tween()
	warning_in.tween_callback(energy_warning_popup, "show")
	warning_in.tween_property(energy_warning_popup, "modulate:a", 1, 0.3)#.from(0.0)


func warning_out():
	
	var warning_out = get_tree().create_tween()
	warning_out.tween_property(energy_warning_popup, "modulate:a", 0, 0.5)
	warning_out.tween_callback(energy_warning_popup, "hide")


func popups_out(): # kliče GM na gameover
	
	var popups_out = get_tree().create_tween()
	popups_out.tween_property($Popups, "modulate:a", 0, 0.5)
	popups_out.tween_callback($Popups, "hide")

	
# INTERNAL ---------------------------------------------------------------------------------------------------------------------------


func _check_for_highscore(player_stats: Dictionary):
	
	match current_gamed_hs_type:
		Profiles.HighscoreTypes.HS_POINTS:
			if player_stats["player_points"] > current_highscore:
				highscore_label.text = "New HS " + str(player_stats["player_points"])
				highscore_label.modulate = Global.color_green
			else:				
				highscore_label.text = "HS " + str(current_highscore)
				highscore_label.modulate = Global.color_hud_text
		Profiles.HighscoreTypes.HS_TIME_LOW: # logika je tu malo drugačna kot pri drugih dveh
			highscore_label.text = "HS " + current_highscore_clock
			highscore_label.modulate = Global.color_hud_text
		Profiles.HighscoreTypes.HS_TIME_HIGH:
			if game_timer.absolute_game_time > current_highscore:
				highscore_label.text = "HS " +  str(game_timer.absolute_game_time) + "s"
				highscore_label.modulate = Global.color_green
			else:				
				highscore_label.text = "HS " +  str(current_highscore) + "s"
				highscore_label.modulate = Global.color_hud_text


func _on_stat_changed(stat_owner: Node, player_stats: Dictionary):
	# update_stats(stat_owner, current_player_stats)

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
		"p2":
			p2_life_counter.life_count = player_stats["player_life"]
			p2_energy_counter.energy = player_stats["player_energy"]
			p2_points_counter.text = "%d" % player_stats["player_points"]
			p2_color_counter.text = "%d" % player_stats["colors_collected"]
			p2_burst_counter.text = "%d" % player_stats["burst_count"]
			p2_skill_counter.text = "%d" % player_stats["skill_count"]
			p2_steps_counter.text = "%d" % player_stats["cells_traveled"]

	# debug
	player_life.text = "LIFE: %d" % player_stats["player_life"]
	player_energy.text = "E: %d" % player_stats["player_energy"]

	if not Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.NO_HS:
		_check_for_highscore(player_stats)
	

func _on_GameTimer_gametime_is_up() -> void: # signal iz tajmerja
	
	Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)
