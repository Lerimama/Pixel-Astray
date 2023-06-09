extends Control

# ta node more bit na vrhu zaradi zaporedja nalaganja

var player_stats: Dictionary
var game_stats: Dictionary

# player hud
onready var player_life: Label = $Life
onready var player_points: Label = $Points
onready var skill_change_count: Label = $SkilChangeCount
onready var cells_travelled: Label = $CellsTravelled
onready var color_sum: Label = $ColorSum/Value

# pixli
onready var stray_pixels: Label = $PixelsStray
onready var black_pixels: Label = $PixelsHome

# pobrana barva pixla
var new_picked_color: Color = Color.black setget _new_color_picked
onready var picked_color_rect: ColorRect = $PickedColor/ColorBox/ColorRect
onready var picked_color_label: Label = $PickedColor/Value

# spektrum
onready var color_spectrum: VBoxContainer = $ColorSpectrum
var color_indicator_width: float = 12 # ročno setaj pravilno
var active_color_indicators: Array = []
onready var ColorIndicator: PackedScene = preload("res://scenes/ColorIndicator.tscn")
onready var indicator_holder: HBoxContainer = $ColorSpectrumLite/IndicatorHolder

# štopanje
onready var start_game_time setget _start_timing
onready var game_time: Control = $GameTime



func _ready() -> void:
	
	Global.hud = self
	
	# skrij statistiko
#	visible = false
	color_spectrum = Global.color_indicator_parent


func _process(delta: float) -> void:
	
	if Global.game_manager.game_is_on:
		
		if not visible:
			visible = true
		
		player_stats = Global.game_manager.new_player_stats
		game_stats = Global.game_manager.new_game_stats
		
		# pixel stats
		skill_change_count.text = "SKILL CHANGES: %04d" % player_stats["skill_change_count"]
		cells_travelled.text = "CELLS TRAVELLED: %04d" % player_stats["cells_travelled"]
		
		# game stats
		player_life.text = "LIFE: %s" % game_stats["player_life"]
		player_points.text = "POINTS: %04d" % game_stats["player_points"]
		
#		color_sum.text = str(Global.game_manager.player_color_sum_r) + " " + str(Global.game_manager.player_color_sum_g3) + " " + str(Global.game_manager.player_color_sum_b)
		
		stray_pixels.text = "PIXELS ASTRAY: %02d" % game_stats["stray_pixels"]
		black_pixels.text = "BLACK PIXELS: %02d" % game_stats["black_pixels"]

	else:
		if visible:
#			hud_control.visible = false
			pass
		

func spawn_color_indicator(position_x,selected_color_position_y, selected_color): 
# ukaz pride iz GM

	var new_color_indicator = ColorIndicator.instance()
	new_color_indicator.rect_position.x = position_x
	new_color_indicator.rect_position.y = selected_color_position_y
	new_color_indicator.color = selected_color
	indicator_holder.add_child(new_color_indicator)
	active_color_indicators.append(new_color_indicator)
	
	# _debug ... zapis indexa ... invisible
	var indicator_index = active_color_indicators.find(new_color_indicator)
	new_color_indicator.get_node("Label").text = str(indicator_index)
	
	
func _start_timing(start_time):
	game_time.restart_timer(start_time)


func _new_color_picked(picked_pixel_color):
	erase_color_indicator(picked_pixel_color)
	picked_color_rect.color = picked_pixel_color
	picked_color_label.text = str(round(255 * picked_pixel_color.r)) + " " + str(round(255 * picked_pixel_color.g)) + " " + str(round(255 * picked_pixel_color.b))
	
	
func erase_color_indicator(erase_color):
	
	# index indikatorja pobrane barve (prepoznan po enaki barvi)
	var current_indicator_index: int
	for indicator in active_color_indicators:
		if indicator.color == erase_color:
			current_indicator_index = active_color_indicators.find(indicator)
			indicator.self_modulate.a = 0
			indicator.get_node("Line").visible = true
			break
	
	
	# opredelitev sosedov glede na položaj pobrane barve
	if active_color_indicators.size() == 1: # če je samo še en indikator, nima sosedov	
		return

	# indexi onbeh sosednjih indikatorjev
	var next_indicator_index: int = current_indicator_index + 1
	var prev_indicator_index: int = current_indicator_index - 1
	
	# na začetku živih indikatorjev 
	if current_indicator_index == 0:		
		active_color_indicators[next_indicator_index].get_node("Line").visible = true
		# pošljem sosednje barve v GM
		Global.game_manager.colors_to_pick = [active_color_indicators[next_indicator_index].color]
	# na koncu živih indikatorjev
	elif current_indicator_index == active_color_indicators.size() - 1: # ker je index vedno eno manjši	
		active_color_indicators[prev_indicator_index].get_node("Line").visible = true
		# pošljem sosednje barve v GM
		Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color]
	# povsod vmes med živimi indikatorji
	elif current_indicator_index > 0 and current_indicator_index < (active_color_indicators.size() - 1):
		active_color_indicators[next_indicator_index].get_node("Line").visible = true
		active_color_indicators[prev_indicator_index].get_node("Line").visible = true
		# pošljem sosednje barve v GM
		Global.game_manager.colors_to_pick = [active_color_indicators[prev_indicator_index].color, active_color_indicators[next_indicator_index].color]
	
	# izbris iz arraya živih indikatorjev
	active_color_indicators.erase(active_color_indicators[current_indicator_index])

	

func erase_all_indicators():
	if not active_color_indicators.empty():
		for indicator in active_color_indicators:
			indicator.queue_free()
		active_color_indicators = []
	

func _on_GameTime_deathmode_on() -> void:
	Global.game_manager.deathmode_on = true


func _on_GameTime_gametime_is_up() -> void:
	Global.game_manager.end_game()
