extends Control


signal hud_is_set
signal players_ready

# spectrum
var picked_indicator_alpha: float = 1
var unpicked_indicator_alpha: float = 0.2
var neighbor_indicator_alpha: float = 0.4
var active_color_indicators: Array = [] # indikatorji spawnani že ob spawnanju pixlov

# hs
var current_highscore: int
var current_highscore_owner: String

# in/out
var hud_in_out_time: int = 2
var screen_height:int = 720

# popups 
onready var popups: Control = $Popups # skoz vidno, skrije se na gameover
onready var highscore_broken_popup: Control = $Popups/HSBroken
onready var energy_warning_popup: Control = $Popups/EnergyWarning
onready var steps_remaining_label: Label = $Popups/EnergyWarning/StepsRemaining
onready var splitscreen_popup: Control = $Popups/SplitScreens
# header
onready var header: Control = $Header # kontrole iz kamere
onready var game_timer: HBoxContainer = $Header/GameTimer
onready var highscore_label: Label = $Header/HighscoreLabel
onready var header_height: int = header.rect_size.y
onready var viewport_header: ColorRect = $"%ViewHeder"
# p1
onready var p1_statsline: HBoxContainer = $Header/PlayerLineL # neuporabljeno
onready var p1_label: Label = $Header/PlayerLineL/PlayerLabel
onready var p1_life_counter: HBoxContainer = $Header/PlayerLineL/LifeIcons
onready var p1_energy_counter: HBoxContainer = $Header/PlayerLineL/EnergyBar
onready var p1_points_holder: HBoxContainer = $Header/PlayerLineL/PointsHolder
onready var p1_points_counter: Label = $Header/PlayerLineL/PointsHolder/Points
onready var p1_color_holder: HBoxContainer = $Header/PlayerLineL/ColorHolder
onready var p1_color_counter: Label = $Header/PlayerLineL/ColorHolder/Label
onready var p1_skill_holder: HBoxContainer = $Header/PlayerLineL/SkillHolder # neuporabljeno
onready var p1_skill_counter: Label = $Header/PlayerLineL/SkillHolder/Label
onready var p1_burst_holder: HBoxContainer = $Header/PlayerLineL/BurstHolder # neuporabljeno
onready var p1_burst_counter: Label = $Header/PlayerLineL/BurstHolder/Label
# p2
onready var p2_statsline: HBoxContainer = $Header/PlayerLineR
onready var p2_label: Label = $Header/PlayerLineR/PlayerLabel # neuporabljeno
onready var p2_life_counter: HBoxContainer = $Header/PlayerLineR/LifeIcons
onready var p2_energy_counter: HBoxContainer = $Header/PlayerLineR/EnergyBar
onready var p2_points_holder: HBoxContainer = $Header/PlayerLineR/PointsHolder # neuporabljeno
onready var p2_points_counter: Label = $Header/PlayerLineR/PointsHolder/Points # neuporabljeno
onready var p2_color_holder: HBoxContainer = $Header/PlayerLineR/ColorHolder # neuporabljeno
onready var p2_color_counter: Label = $Header/PlayerLineR/ColorHolder/Label
onready var p2_skill_holder: HBoxContainer = $Header/PlayerLineR/SkillHolder # neuporabljeno
onready var p2_skill_counter: Label = $Header/PlayerLineR/SkillHolder/Label
onready var p2_burst_holder: HBoxContainer = $Header/PlayerLineR/BurstHolder # neuporabljeno
onready var p2_burst_counter: Label = $Header/PlayerLineR/BurstHolder/Label
# futer
onready var footer: Control = $Footer # kontrole iz kamere
onready var game_label: Label = $Footer/FooterLine/GameLine/Game
onready var level_label: Label = $Footer/FooterLine/GameLine/Level
onready var spectrum: HBoxContainer = $Footer/FooterLine/SpectrumHolder/ColorSpectrum
onready var ColorIndicator: PackedScene = preload("res://game/hud/hud_color_indicator.tscn")
onready var astray_counter: Label = $Footer/FooterLine/StraysLine/AstrayHolder/Label
onready var picked_counter: Label = $Footer/FooterLine/StraysLine/PickedHolder/Label
onready var viewport_footer: ColorRect = $"%ViewFuter"
# debug
onready var player_life: Label = $Life
onready var player_energy: Label = $Energy
onready var picked_color_rect: ColorRect = $PickedColor/ColorRect
onready var picked_color_label: Label = $PickedColor/Value


func _input(event: InputEvent) -> void:
	
	# splitscreen popup
	if Input.is_action_just_pressed("ui_accept") and splitscreen_popup.visible:
		Global.sound_manager.play_gui_sfx("btn_confirm")
		emit_signal("players_ready")
	
	
func _ready() -> void:
	
	Global.hud = self
	
	# pred hud in pozicije
	header.rect_position.y = - header_height
	footer.rect_position.y = screen_height	

	if Global.game_manager.game_settings["start_players_count"] == 2:
		set_two_players_hud()
	else:
		set_one_player_hud()

	if Global.game_manager.game_settings["manage_highscores"]:
		set_current_highscore()
	
		
func set_two_players_hud():
	
	# hide
	highscore_label.visible = false
	level_label.visible = false
	p1_points_holder.visible = false
	# show
	p1_label.visible = true
	p1_color_holder.visible = true
	p2_statsline.visible = true
#	splitscreen_popup.visible = true
#	splitscreen_popup.modulate.a = 0
	
	# samo 1 lajf
	if Global.game_manager.game_settings["start_players_count"] == 2:
		p1_life_counter.visible = true
		p2_life_counter.visible = true		
	else:
		p1_life_counter.visible = false
		p2_life_counter.visible = false


func set_one_player_hud():
	
	# hide
	p1_label.visible = false
	p2_statsline.visible = false
	# show
	highscore_label.visible = true
	if Global.game_manager.game_data["level"].empty():
		level_label.visible = false
	
	# samo 1 lajf
	if Global.game_manager.game_settings["player_start_life"] == 1:
		p1_life_counter.visible = false
	else:
		p1_life_counter.visible = true
	

func set_current_highscore():
	
	var current_game = Global.game_manager.game_data["game"]
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(current_game)
	
	current_highscore = current_highscore_line[0]
	current_highscore_owner = current_highscore_line[1]
	
	highscore_label.text = "Highscore " + str(current_highscore) # se apdejta ob signalu iz plejerja (ob konektanju na začetku?)


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
		"p2":
			p2_life_counter.life_count = player_stats["player_life"]
			p2_energy_counter.energy = player_stats["player_energy"]
			p2_points_counter.text = "%d" % player_stats["player_points"]
			p2_color_counter.text = "%d" % player_stats["colors_collected"]
			p2_burst_counter.text = "%d" % player_stats["burst_count"]
			p2_skill_counter.text = "%d" % player_stats["skill_count"]
				
	# game stats
	game_label.text = Global.game_manager.game_data["game_name"]
	level_label.text = Global.game_manager.game_data["level"]
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game.size()
	picked_counter.text = "%03d" % (Global.game_manager.strays_start_count - Global.game_manager.strays_in_game.size())
	
	# debug
	player_life.text = "LIFE: %d" % player_stats["player_life"]
	player_energy.text = "E: %d" % player_stats["player_energy"]
	
	if Global.game_manager.game_settings["manage_highscores"]:
		check_for_hs(player_stats)
	
	if Global.game_manager.game_settings["start_players_count"] == 1:
		check_for_warning(player_stats)
		
		
func check_for_hs(player_stats):
	
	if player_stats["player_points"] > Global.game_manager.game_data["highscore"]:
		highscore_label.text = "New highscore " + str(player_stats["player_points"])
		highscore_label.modulate = Global.color_green
	else:
		highscore_label.text = "Highscore " + str(current_highscore)
		highscore_label.modulate = Global.hud_text_color

		
func check_for_warning(player_stats):
	
	if player_stats["player_energy"] < 1: # ko zgubi lajf
		if energy_warning_popup.visible == true:
			warning_out()
	elif player_stats["player_energy"] < 2:
		if energy_warning_popup.visible == false:
			warning_in()
		steps_remaining_label.text = "NO ENERGY! Collect a color to revitalize."
	elif player_stats["player_energy"] == 2: # pomeni samo še en korak in rabim ednino
		if energy_warning_popup.visible == false:
			warning_in()
		steps_remaining_label.text = "ENERGY WARNING! Only 1 step remaining."
	elif player_stats["player_energy"] <= Global.game_manager.game_settings["player_tired_energy"]:
		if energy_warning_popup.visible == false:
			warning_in()
		steps_remaining_label.text = "ENERGY WARNING! Only %s steps remaining." % str(player_stats["player_energy"] - 1)
	elif player_stats["player_energy"] > Global.game_manager.game_settings["player_tired_energy"]:
		if energy_warning_popup.visible == true:
			warning_out()


# IN / OUT ---------------------------------------------------------------------------------------------------------------------------

	
func fade_in(): # kliče GM set_game()
	
	# zoom-in kamere
	var player_cameras: Array = [Global.p1_camera]
	if Global.game_manager.game_settings["start_players_count"] == 2:
		player_cameras.append(Global.p2_camera)
	
	for camera in player_cameras:
		camera.zoom_in(hud_in_out_time)
	
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	fade_in.tween_property(header, "rect_position:y", 0, hud_in_out_time)
	fade_in.parallel().tween_property(footer, "rect_position:y", screen_height - header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", Global.hud.header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", Global.hud.header_height, hud_in_out_time)
	
	yield(Global.p1_camera, "zoomed_in")
	
	for indicator in active_color_indicators:
		var indicator_fade_in = get_tree().create_tween()
		indicator_fade_in.tween_property(indicator, "modulate:a", unpicked_indicator_alpha, 0.3).set_ease(Tween.EASE_IN)
	
	if Global.game_manager.game_settings["start_players_count"] == 2:
		fade_splitscreen_popup()
	else:
		emit_signal("hud_is_set")


func fade_out(): # kliče GM game_over()
	
	# zoom-out kamere
	var player_cameras: Array = [Global.p1_camera]
	if Global.game_manager.game_settings["start_players_count"] == 2:
		player_cameras.append(Global.p2_camera)
	
	for camera in player_cameras:
		camera.zoom_out(hud_in_out_time)
		
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	fade_in.tween_property(header, "rect_position:y", 0 - header_height, hud_in_out_time)
	fade_in.parallel().tween_property(footer, "rect_position:y", screen_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", 0, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", 0, hud_in_out_time)
	fade_in.tween_callback(self, "set_visible", [false])
	

func warning_in():
	var warning_in = get_tree().create_tween()
	warning_in.tween_callback(energy_warning_popup, "set_visible", [true])
	warning_in.tween_property(energy_warning_popup, "modulate:a", 1, 0.3) #.from(0.0)


func warning_out():
	var warning_out = get_tree().create_tween()
	warning_out.tween_property(energy_warning_popup, "modulate:a", 0, 0.5)
	warning_out.tween_callback(energy_warning_popup, "set_visible", [false])


func fade_splitscreen_popup():
	
	var show_splitscreen_popup = get_tree().create_tween()
	show_splitscreen_popup.tween_callback(splitscreen_popup, "set_visible", [true])
	show_splitscreen_popup.tween_property(splitscreen_popup, "modulate:a", 1, 1).from(0.0).set_ease(Tween.EASE_IN)

	yield(self, "players_ready")
	
	var hide_splitscreen_popup = get_tree().create_tween()
	hide_splitscreen_popup.tween_property(splitscreen_popup, "modulate:a", 0, 1).set_ease(Tween.EASE_IN)
	hide_splitscreen_popup.tween_callback(splitscreen_popup, "set_visible", [false])
	hide_splitscreen_popup.parallel().tween_callback(self, "emit_signal", ["hud_is_set"])	
	
		
# SPECTRUM ---------------------------------------------------------------------------------------------------------------------------


func spawn_color_indicators(available_colors): # kliče GM
	
	var indicator_index = 0 # za fiksirano zaporedje
	
	for color in available_colors:
		indicator_index += 1 
		# spawn indicator
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = color
		new_color_indicator.modulate.a = 1 # na fade-in se odfejda do unpicked_indicator_alpha
		spectrum.add_child(new_color_indicator)
		active_color_indicators.append(new_color_indicator)

		# debug ... zapis indexa
		# new_color_indicator.get_node("IndicatorCount").text = str(indicator_index) 
	
	
func show_picked_color(picked_pixel_color):
	
	# picked color statline
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	picked_color_rect.color = picked_pixel_color

	show_color_indicator(picked_pixel_color)

					
func show_color_indicator(picked_color):
	
	var current_indicator_index: int
	for indicator in active_color_indicators:
		# pobrana barva
		if indicator.color == picked_color:
			current_indicator_index = active_color_indicators.find(indicator)
			indicator.modulate.a = picked_indicator_alpha
			break
		# preostale barve	
		elif Global.game_manager.game_settings["pick_neighbor_mode"]: # efekt na preostalih barvah 
			indicator.modulate.a = unpicked_indicator_alpha
			
	if Global.game_manager.game_settings["pick_neighbor_mode"]:	# opredelitev sosedov glede na položaj pobrane barve
		
		if active_color_indicators.size() == 1: # če je samo še en indikator, nima sosedov	
			return

		var next_indicator_index: int = current_indicator_index + 1
		var prev_indicator_index: int = current_indicator_index - 1
		
		# na začetku holderja indikatorjev 
		if current_indicator_index == 0:		
			active_color_indicators[next_indicator_index].modulate.a = neighbor_indicator_alpha
			Global.game_manager.colors_to_pick = [active_color_indicators[next_indicator_index].color] # pošljem sosednje barve v GM
		# na koncu holderja indikatorjev
		elif current_indicator_index == active_color_indicators.size() - 1: # ker je index vedno eno manjši	
			active_color_indicators[prev_indicator_index].modulate.a = neighbor_indicator_alpha
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color] # pošljem sosednje barve v GM
		# povsod vmes med živimi indikatorji
		elif current_indicator_index > 0 and current_indicator_index < (active_color_indicators.size() - 1):
			active_color_indicators[next_indicator_index].modulate.a = neighbor_indicator_alpha
			active_color_indicators[prev_indicator_index].modulate.a = neighbor_indicator_alpha
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color, active_color_indicators[next_indicator_index].color] # pošljem sosednje barve v GM
		
	# izbris iz aktivnih indikatorjev
	if not active_color_indicators.empty():
		active_color_indicators.erase(active_color_indicators[current_indicator_index])


# SIGNALS ---------------------------------------------------------------------------------------------------------------------------


func _on_GameTimer_sudden_death_active() -> void:
	pass


func _on_GameTimer_gametime_is_up() -> void:
	
	Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)


func _on_stat_changed(stat_owner: Node, current_player_stats: Dictionary):
	
	update_stats(stat_owner, current_player_stats)
