extends Control


# ta node more bit na vrhu zaradi zaporedja nalaganja
var player_stats: Dictionary
var game_stats: Dictionary

var fade_time: float = 1
var default_hud_color: Color = Color.white

# spectrum indicators
var active_color_indicators: Array = []
onready var ColorIndicator: PackedScene = preload("res://game/hud/HudColorIndicator.tscn")
onready var indicator_holder: HBoxContainer = $Footer/ColorSpectrumLite/IndicatorHolder

#header
onready var header: Control = $Header
onready var player_life: Label = $Life # _temp, pravi je na samih ikonah
onready var player_energy: Label = $Energy # temp
onready var player_points: Label = $Header/HudLine_TL/PointsCounter/Points
onready var cells_travelled: Label = $Header/HudLine_TL/CellCounter/CellsTravelled
onready var skills_used: Label = $Header/HudLine_TL/SkillCounter/SkillsUsed
onready var game_timer: HBoxContainer = $Header/GameTimer
onready var music_label: Label = $Header/MusicLabel
onready var level: Label = $Header/Level
onready var highscore_label: Label = $Header/Highscore


#futer
onready var footer: Control = $Footer
onready var picked_color_rect: ColorRect = $Footer/PickedColor/ColorRect
onready var picked_color_label: Label = $Footer/PickedColor/Value
onready var pixels_off_counter = $Footer/HudLine_TR/OffedCounter
onready var pixels_off: Label = $Footer/HudLine_TR/OffedCounter/PixelsOff
onready var stray_pixels_counter = $Footer/HudLine_TR/StrayCounter
onready var stray_pixels: Label = $Footer/HudLine_TR/StrayCounter/PixelsStray


# hs popup 
var close_to_highscore_part = 0.85 # procent HS vrednosti
var highscore_broken: bool =  false
var highscore_broken_popup_time: float = 2
onready var highscore_close_popup: Label = $Popups/HSClose
onready var highscore_broken_popup: Control = $Popups/HSBroken


func _ready() -> void:
	
	Global.hud = self
	
	# skrij statistiko in popupe
	visible = false
	highscore_close_popup.visible = false
	highscore_broken_popup.visible = false
#	color_spectrum = Global.color_indicator_parent
	

func _process(delta: float) -> void:
	
	
	player_stats = Global.game_manager.player_stats
	game_stats = Global.game_manager.game_stats
	
	writing_stats()
	
	if not highscore_broken and Global.game_manager.game_on:
		checking_highscore()
		
			
func writing_stats():	
	# pixel stats
	
	player_points.text = "%04d" % player_stats["player_points"]
	cells_travelled.text = "%04d" % player_stats["cells_travelled"]
	skills_used.text = "%04d" % player_stats["skills_used"]
	
	# game stats
	level.text = "LEVEL %02d" % game_stats["level_no"]
	stray_pixels.text = "%03d" % game_stats["stray_pixels_count"]
	pixels_off.text = "%03d" % game_stats["off_pixels_count"]
	
	# _temp
	player_life.text = "LIFE: %01d" % player_stats["player_life"]
	player_energy.text = "E: %04d" % player_stats["player_energy"]
	
	if not highscore_broken:
		highscore_label.text = "HIGHSCORE %04d" % game_stats["highscore"]
	else:
		highscore_label.text = "HIGHSCORE %04d" % player_stats["player_points"]


func checking_highscore():
	
	var current_highscore = game_stats["highscore"]
	var current_points = player_stats["player_points"]
	var close_to_highscore_limit: float = abs(current_highscore * close_to_highscore_part)
	
	
	# rekord!!! ... zaporedje ifov je pomembno zaradi načina setanja pogojev
	if current_points > current_highscore:
		Global.sound_manager.play_sfx("record_cheers")
		highscore_broken = true
		highscore_label.modulate = Global.color_green
		
		highscore_close_popup.visible = false
		highscore_broken_popup.visible = true
		yield(get_tree().create_timer(highscore_broken_popup_time), "timeout")
		highscore_broken_popup.visible = false
	
	# blizu rekorda
	elif current_points >= close_to_highscore_limit or current_points == current_highscore:
		highscore_label.modulate = Global.color_blue
		highscore_close_popup.visible = true
	
	# blah ... še ni uspeha
	elif current_points < close_to_highscore_limit:
		highscore_close_popup.visible = false
		highscore_broken_popup.visible = false
		highscore_label.modulate = default_hud_color
		

func fade_in():
	
	modulate.a = 0
	visible = true
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, fade_time)

	
		
func start_timer():
	game_timer.start_timer(Profiles.default_level_stats["game_time_limit"])
	
#	game_time.restart_timer(Profiles.default_level_stats["game_time"])

func stop_timer():
	game_timer.stop_timer()
#	game_time.timing_on = false


# COLORS ---------------------------------------------------------------------------------------------------------------------------

func spawn_color_indicators(colors): 
# ukaz pride iz GM

	for color in colors:

		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = color
		indicator_holder.add_child(new_color_indicator)
		
		# zapis indexa ... invisible ... za debug
		var indicator_index = active_color_indicators.find(new_color_indicator)
		new_color_indicator.get_node("Label").text = str(indicator_index)
	
		active_color_indicators.append(new_color_indicator)
	
	
func color_picked(picked_pixel_color):
	
	erase_color_indicator(picked_pixel_color)
	
	# picked color stats
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	
	# color effects
	picked_color_rect.color = picked_pixel_color
	
	picked_color_label.modulate = picked_pixel_color
	pixels_off_counter.modulate = picked_pixel_color
	stray_pixels_counter.modulate = picked_pixel_color
	yield(get_tree().create_timer(0.5), "timeout")
	picked_color_label.modulate = default_hud_color
	pixels_off_counter.modulate = default_hud_color
	stray_pixels_counter.modulate = default_hud_color
	
	
func erase_color_indicator(erase_color):
	
	# index indikatorja pobrane barve (prepoznan po enaki barvi)
	var current_indicator_index: int
	for indicator in active_color_indicators:
		if indicator.color == erase_color:
			current_indicator_index = active_color_indicators.find(indicator)
			if Global.game_manager.pick_neighbour_mode:
				indicator.modulate.a = 0
			else:
				indicator.modulate.a = 0.3
				break
		else:
			if Global.game_manager.pick_neighbour_mode:
				indicator.modulate.a = 0.5
			
	if Global.game_manager.pick_neighbour_mode:	
		# opredelitev sosedov glede na položaj pobrane barve
		if active_color_indicators.size() == 1: # če je samo še en indikator, nima sosedov	
			return

		# indexi onbeh sosednjih indikatorjev
		var next_indicator_index: int = current_indicator_index + 1
		var prev_indicator_index: int = current_indicator_index - 1
		
	#	for indicator in active_color_indicators:
			
		# na začetku živih indikatorjev 
		if current_indicator_index == 0:		
	#		active_color_indicators[next_indicator_index].get_node("Line").visible = true
			active_color_indicators[next_indicator_index].modulate.a = 1
			# pošljem sosednje barve v GM
			Global.game_manager.colors_to_pick = [active_color_indicators[next_indicator_index].color]
		# na koncu živih indikatorjev
		elif current_indicator_index == active_color_indicators.size() - 1: # ker je index vedno eno manjši	
	#		active_color_indicators[prev_indicator_index].get_node("Line").visible = true
			active_color_indicators[prev_indicator_index].modulate.a = 1
			# pošljem sosednje barve v GM
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color]
		# povsod vmes med živimi indikatorji
		elif current_indicator_index > 0 and current_indicator_index < (active_color_indicators.size() - 1):
	#		active_color_indicators[next_indicator_index].get_node("Line").visible = true
	#		active_color_indicators[prev_indicator_index].get_node("Line").visible = true
			active_color_indicators[next_indicator_index].modulate.a = 1
			active_color_indicators[prev_indicator_index].modulate.a = 1
			# pošljem sosednje barve v GM
			Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color, active_color_indicators[next_indicator_index].color]
		
	# izbris iz arraya živih indikatorjev
	if not active_color_indicators.empty():
		active_color_indicators.erase(active_color_indicators[current_indicator_index])
	

# SIGNALS ---------------------------------------------------------------------------------------------------------------------------


func _on_GameTime_deathmode_on() -> void:
	Global.game_manager.deathmode_on = true
	pass

func _on_GameTimer_gametime_is_up() -> void:
#	print("ASGNALAASGNALAASGNALAASGNALAASGNALAASGNALAASGNALA")
	Global.game_manager.game_over(Global.game_over_reason_time)
	pass

#func erase_all_indicators(): ... zaenkrat ne rabim nikjer
#	
#	if not active_color_indicators.empty():
#		for indicator in active_color_indicators:
#			indicator.queue_free()
#		active_color_indicators = []
#	pass


