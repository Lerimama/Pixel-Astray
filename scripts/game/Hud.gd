extends Control

# ta node more bit na vrhu zaradi zaporedja nalaganja

var player_stats: Dictionary
var game_stats: Dictionary

var fade_time: float = 1

onready var player_life: Label = $Life # _temp, pravi je na samih ikonah
onready var player_energy: Label = $Energy # temp

#onready var player_points: Label = $Points
onready var player_points: Label = $HudLine_TL/PointsCounter/Points
onready var cells_travelled: Label = $HudLine_TL/CellCounter/CellsTravelled
onready var skills_used: Label = $HudLine_TL/SkillCounter/SkillsUsed

onready var picked_color_rect: ColorRect = $PickedColor/ColorBox/ColorRect
onready var picked_color_label: Label = $PickedColor/Value

# game hud
onready var pixels_off: Label = $HudLine_TR/OffedCounter/PixelsOff
onready var stray_pixels: Label = $HudLine_TR/StrayCounter/PixelsStray
onready var level: Label = $Level

# spectrum indicators
#var color_indicator_width: float = 12 # ročno setaj pravilno
var active_color_indicators: Array = []
onready var color_spectrum: VBoxContainer = $ColorSpectrum
onready var ColorIndicator: PackedScene = preload("res://scenes/game/HudColorIndicator.tscn")
onready var indicator_holder: HBoxContainer = $ColorSpectrumLite/IndicatorHolder

# štopanje
#onready var timer_on: bool = false setget _start_timer
onready var game_time: Control = $GameTime


func _ready() -> void:
	
	Global.hud = self
	
	# skrij statistiko
	visible = false
	color_spectrum = Global.color_indicator_parent
	

func _process(delta: float) -> void:
		
	player_stats = Global.game_manager.player_stats
	game_stats = Global.game_manager.game_stats
	
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
	
	# life  ikone
#	var loop_index: int		
#	for icon in life_icons:
#		loop_index += 1
#		if loop_index >= player_stats["player_life"] + 1: # če je ena preveč
#			icon.get_node("OnIcon").modulate.a = 0
#		else:
#			icon.get_node("OnIcon").modulate.a = 1


#	# pixel stats
#	player_life.text = "LIFE: %01d" % player_stats["player_life"]
#	player_points.text = "POINTS: %04d" % player_stats["player_points"]
#	cells_travelled.text = "TRAVELING: %04d" % player_stats["cells_travelled"]
#	skills_used.text = "SKILLS USED: %04d" % player_stats["skills_used"]
#	# game stats
#	level.text = "LEVEL %02d" % game_stats["level_no"]
#	stray_pixels.text = "PIXELS ASTRAY: %02d" % game_stats["stray_pixels_count"]
#	pixels_off.text = "%02d /" % game_stats["off_pixels_count"]
	

func fade_in():
	
	modulate.a = 0
	visible = true
	
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1, fade_time)
	
	
func start_timer():
	
	game_time.restart_timer(Profiles.default_game_stats["game_time"])


# colors

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
	picked_color_rect.color = picked_pixel_color
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	
	
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
	

#func erase_all_indicators(): ... zaenkrat ne rabim nikjer
#	if not active_color_indicators.empty():
#		for indicator in active_color_indicators:
#			indicator.queue_free()
#		active_color_indicators = []
	
	
# deathmode

func _on_GameTime_deathmode_on() -> void:
	Global.game_manager.deathmode_on = true


func _on_GameTime_gametime_is_up() -> void:
	Global.game_manager.game_over()
