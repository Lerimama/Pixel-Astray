extends Control
class_name GameHud


signal players_ready # za splitscreen popup

var tired_energy_limit: float = 20
var stray_in_indicator_alpha: float = 1 # alfa obračam, če ima igra goal
var stray_out_indicator_alpha: float = 0.2
var all_color_indicators: Array = [] # indikatorji spawnani že ob spawnanju pixlov ... nima veze, če je ugasnjen ali prižgan
var highscore_on_start: float
var new_record_set: bool = false

# in/out
var hud_in_out_time: int = 2
var screen_height:int = 720
onready var header: Control = $Header # kontrole iz kamere
onready var header_height: int = header.rect_size.y
onready var viewport_header: ColorRect = $"%ViewHeder"
onready var viewport_footer: ColorRect = $"%ViewFuter"

# header
onready var game_timer: HBoxContainer = $Header/TopLineR/GameTimerHunds
onready var music_player: HBoxContainer = $Header/TopLineR/MusicPlayer
onready var music_track_btn: Button = $Header/TopLineR/MusicPlayer/TrackBtn # TrackLabel # za pedeneanje imena iz SM in na ready
onready var highscore_holder: HBoxContainer = $Header/TopLineR/HighscoreHolder
onready var highscore_label: Label = $Header/TopLineR/HighscoreHolder/HighscoreLabel

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

# pins
onready var instructions_popup: Control = $Popups/Instructions
onready var level_popup: Control = $Popups/LevelUp
onready var start_countdown: Control = $Popups/StartCountdown
onready var touch_controls: Node2D = $"../TouchControls"
onready var sweeper_action_hint: Node2D = $"../SweeperHintPress"


func _unhandled_input(event: InputEvent) -> void:

	if sweeper_action_hint.visible and Input.is_action_just_pressed("hint"):
		# nočem sounda za hint ... Global.sound_manager.play_gui_sfx("btn_confirm") # ker ga ne fokusiram se ne pleja sam
		_on_HintBtn_pressed()


func _ready() -> void:

	Global.hud = self
	header.rect_position.y = - header_height
	footer.rect_position.y = screen_height
	start_countdown.hide()
	level_popup.hide()
	sweeper_action_hint.modulate.a = 0
	sweeper_action_hint.hide() # prifejdam na slide in

	if Global.game_manager.game_settings["always_zoomed_in"]:
		header.rect_position.y = 0
		footer.rect_position.y = screen_height - header_height
		viewport_header.rect_min_size.y = header_height
		viewport_footer.rect_min_size.y = header_height

	# hud barva elementov, ki ne modulirajo sami sebe in niso label (v glavnem ikone)
	# timer in hs sta label, moduliran med igro, zato imata na nodetu setano font color override na belo
	# p1 stats + p2 stats + game stats
	var nodes_to_modulate: Array = [$Header/TopLineL/ColorHolder/TextureRect5, $Header/TopLineL/StepsHolder/TextureRect5, $Header/TopLineL/SkillHolder/TextureRect5, $Header/TopLineL/BurstHolder/TextureRect6, $Header/TopLineL/PointsHolder/TextureRect4]
	nodes_to_modulate.append_array([$Header/TopLineR/PlayerLineR/PointsHolder/TextureRect4, $Header/TopLineR/PlayerLineR/ColorHolder/TextureRect5, $Header/TopLineR/PlayerLineR/StepsHolder/TextureRect5, $Header/TopLineR/PlayerLineR/SkillHolder/TextureRect5, $Header/TopLineR/PlayerLineR/BurstHolder/TextureRect6])
	nodes_to_modulate.append_array([$Footer/FooterLine/StraysLine/AstrayHolder/TextureRect3, $Footer/FooterLine/StraysLine/PickedHolder/TextureRect2])
	for node in nodes_to_modulate:
		node.modulate = Global.color_hud_text

	_set_hud_elements() # vse kar se lahko razlikuje "per game"


func _process(delta: float) -> void:


#	set_process_input(true)
	astray_counter.text = "%0d" % Global.game_manager.strays_in_game_count

	if level_label.visible: # Global.game_manager.game_data.has("level"):
		level_label.text = "L%02d" % Global.game_manager.game_data["level"]


func _set_hud_elements():

	# game name and level
	game_label.text = Global.game_manager.game_data["game_name"]
	if Global.game_manager.game_data.has("level"):
		level_label.text = "L%02d" % Global.game_manager.game_data["level"]
		level_label.show()
	else:
		level_label.hide()

	# player statlines
	if Global.game_manager.game_data["game"] == Profiles.Games.THE_DUEL:
		p1_label.show()
		p2_statsline.show()
	else:
		p1_label.hide()
		p2_statsline.hide()

	# lajf
	if Global.game_manager.game_settings["player_start_life"] > 1:
		p1_life_counter.show()
		p2_life_counter.show()
	else:
		p1_life_counter.hide()
		p2_life_counter.hide()

	# energy
	if Global.game_manager.game_settings["cell_traveled_energy"] == 0:
		p1_energy_counter.hide()
		p2_energy_counter.hide()

	# pre-game
	if Global.game_manager.game_settings["pregame_screen_on"]:
		instructions_popup.open()
	else:
		instructions_popup.hide()

	# HS
	if Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.NONE:
		highscore_holder.hide()
	else:
		_get_highscore_on_start()
		highscore_holder.show()

	# timer
	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
	#	if Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.TIME:
		game_timer.display_hunds = true


func slide_in(): # kliče GM set_game()

	if Global.game_manager.game_settings["start_countdown"]:
		start_countdown.modulate.a = 0
		start_countdown.show()
		var fade_in_tween = get_tree().create_tween()
		fade_in_tween.tween_property(start_countdown, "modulate:a", 1, 0.3).set_ease(Tween.EASE_IN)

	if Global.game_manager.game_settings["always_zoomed_in"]:
		yield(get_tree().create_timer(Global.get_it_time), "timeout")
	else:
		Global.game_camera.zoom_in(hud_in_out_time)

		var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS) # trans je ista kot tween na kameri
		fade_in.tween_property(header, "rect_position:y", 0, hud_in_out_time)
		fade_in.parallel().tween_property(footer, "rect_position:y", screen_height - header_height, hud_in_out_time)
		fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", header_height, hud_in_out_time)
		fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", header_height, hud_in_out_time)
		fade_in.parallel().tween_property(Global.current_tilemap.background_room, "modulate:a", 0, hud_in_out_time)
		yield(fade_in, "finished")

	if not Global.game_manager.level_goal_mode:
		for indicator in all_color_indicators:
			var indicator_fade_in = get_tree().create_tween()
			indicator_fade_in.tween_property(indicator, "modulate:a", stray_in_indicator_alpha, 0.3).set_ease(Tween.EASE_IN)

	if Global.game_manager.game_data["game"] == Profiles.Games.SWEEPER:
		var fade_in = get_tree().create_tween()
		fade_in.tween_callback(sweeper_action_hint, "show").set_delay(0.3) # delay za usklajenost s tutorial fade in
		fade_in.tween_property(sweeper_action_hint, "modulate:a", 1, 0.5).set_ease(Tween.EASE_IN)

	if Profiles.touch_available:# and not touch_controls.visible:
		touch_controls.open()

	if Profiles.tutorial_mode:
		Global.tutorial_gui.open_tutorial()


func slide_out(gameover_reason: int): # kliče GM na game over

	if Global.tutorial_gui.tutorial_on:
		Global.tutorial_gui.close_tutorial()
	if touch_controls.visible:
		touch_controls.close()
	_popups_out()
	_check_for_new_highscore(game_timer.game_time_hunds, gameover_reason)

	if sweeper_action_hint.visible:
		var fade_in = get_tree().create_tween()
		fade_in.tween_property(sweeper_action_hint, "modulate:a", 1, 0.5).from(0.0).set_ease(Tween.EASE_IN)
		fade_in.tween_callback(sweeper_action_hint, "hide")


	if Global.game_manager.game_settings["always_zoomed_in"]:
		yield(get_tree().create_timer(Global.get_it_time), "timeout")
	else:
		Global.game_camera.zoom_out(hud_in_out_time)

		var fade = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS) # trans je ista kot tween na kameri
		fade.tween_property(header, "rect_position:y", 0 - header_height, hud_in_out_time)
		fade.parallel().tween_property(footer, "rect_position:y", screen_height, hud_in_out_time)
		fade.parallel().tween_property(viewport_header, "rect_min_size:y", 0, hud_in_out_time)
		fade.parallel().tween_property(viewport_footer, "rect_min_size:y", 0, hud_in_out_time)
		fade.parallel().tween_property(Global.current_tilemap.background_room, "modulate:a", 1, hud_in_out_time)
		fade.tween_callback(self, "hide")


# COLOR INDICATORS ---------------------------------------------------------------------------------------------------------------------------


func spawn_color_indicators(spawn_colors: Array): # kliče GM

	_empty_color_indicators()

	var indicator_index = 0 # za fiksirano zaporedje
	var indicator_to_move_under_index: int

	for spawn_color in spawn_colors:

		indicator_index += 1

		# spawn indicator
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = spawn_color
		if Global.game_manager.level_goal_mode:
			new_color_indicator.modulate.a = stray_out_indicator_alpha # prikažem jih na slide in
		else:
			new_color_indicator.modulate.a = stray_in_indicator_alpha # prikažem jih na slide in

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


func _empty_color_indicators():

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


func _popups_out(): # kliče GM na gameover

	var popups_out = get_tree().create_tween()
	popups_out.tween_property($Popups, "modulate:a", 0, 0.5)
	popups_out.tween_callback($Popups, "hide")

	for popup in $Popups.get_children():
		popup.hide()


# INTERNAL ---------------------------------------------------------------------------------------------------------------------------



func _get_highscore_on_start():

	var start_highscore_line: Array = Data.get_top_highscore(Global.game_manager.game_data)

	highscore_on_start = start_highscore_line[0]
	var highscore_clock: String = Global.get_clock_time(highscore_on_start)
	var highscore_owner: String = start_highscore_line[1]

	# brez rekorda ... current_highscore == 0
	if highscore_on_start == 0:
		highscore_label.text = "No higscore yet"
	elif Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS:
		highscore_label.text = str(highscore_on_start) + " by %s" % highscore_owner
		highscore_holder.modulate = Global.color_hud_text
	elif Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.TIME:
		highscore_label.text = highscore_clock + " by %s" % highscore_owner
		highscore_holder.modulate = Global.color_hud_text


func _check_for_new_highscore(current_player_score: int, gameover_reason: int = -1):

	# točkovni rekord preverjam sproti, tudi, če je trenutni 0
	if Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS:
		if current_player_score > highscore_on_start:
			new_record_set = true
			highscore_label.text = str(current_player_score) + " by You"
			highscore_holder.modulate = Global.color_green
	elif Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.TIME and gameover_reason == Global.game_manager.GameoverReason.CLEANED: #
		if current_player_score < highscore_on_start or highscore_on_start == 0:
			new_record_set = true
			highscore_label.text = Global.get_clock_time(current_player_score) + " by You"
			highscore_holder.modulate = Global.color_green


func _on_stat_changed(stat_owner: Node, player_stats: Dictionary):
	# update_stats(stat_owner, current_player_stats)

	# player stats
	match stat_owner.name:
		"p1":
			p1_life_counter.life_count = player_stats["player_life"]
#			p1_energy_counter.energy = player_stats["player_energy"]
			p1_points_counter.text = "%d" % player_stats["player_points"]
			#			p1_color_counter.text = "%d" % player_stats["colors_collected"]
			#			p1_burst_counter.text = "%d" % player_stats["burst_count"]
			#			p1_skill_counter.text = "%d" % player_stats["skill_count"]
			#			p1_steps_counter.text = "%d" % player_stats["cells_traveled"]
		"p2":
			p2_life_counter.life_count = player_stats["player_life"]
#			p2_energy_counter.energy = player_stats["player_energy"]
			p2_points_counter.text = "%d" % player_stats["player_points"]
			#			p2_color_counter.text = "%d" % player_stats["colors_collected"]
			#			p2_burst_counter.text = "%d" % player_stats["burst_count"]
			#			p2_skill_counter.text = "%d" % player_stats["skill_count"]
			#			p2_steps_counter.text = "%d" % player_stats["cells_traveled"]

	if Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS:
		_check_for_new_highscore(player_stats["player_points"])


func _on_GameTimer_gametime_is_up() -> void: # signal iz tajmerja

	Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)



func _on_HintBtn_pressed() -> void:

	Global.current_tilemap.solution_line.visible = not Global.current_tilemap.solution_line.visible
