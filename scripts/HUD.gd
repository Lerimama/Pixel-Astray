extends Node2D


var player_stats: Dictionary
var game_stats: Dictionary

onready var hud_control: Control = $HudControl

# player hud
onready var player_life: Label = $HudControl/Life
onready var player_points: Label = $HudControl/Points
onready var skill_change_count: Label = $HudControl/SkilChangeCount
onready var cells_travelled: Label = $HudControl/CellsTravelled
onready var color_sum: Label = $HudControl/ColorSum/Value

# game hud
onready var stray_pixels: Label = $HudControl/PixelsStray
onready var black_pixels: Label = $HudControl/PixelsHome
onready var picked_color: Control = $HudControl/PickedColor


func _ready() -> void:
	
	# skrij statistiko
	hud_control.visible = true


func _process(delta: float) -> void:
	
	if Global.game_manager.game_is_on:
		
		if not hud_control.visible:
			hud_control.visible = true
		
		player_stats = Global.game_manager.new_player_stats
		game_stats = Global.game_manager.new_game_stats
		
		# pixel stats
		skill_change_count.text = "SKILL CHANGES: %04d" % player_stats["skill_change_count"]
		cells_travelled.text = "CELLS TRAVELLED: %04d" % player_stats["cells_travelled"]
		
		# game stats
		player_life.text = "LIFE: %s" % game_stats["player_life"]
		player_points.text = "POINTS: %04d" % game_stats["player_points"]
		
		
		color_sum.text = str(Global.game_manager.player_color_sum_r) + " " + str(Global.game_manager.player_color_sum_g) + " " + str(Global.game_manager.player_color_sum_b)
		
		stray_pixels.text = "STRAY PIXELS: %02d" % game_stats["stray_pixels"]
		black_pixels.text = "BLACK PIXELS: %02d" % game_stats["black_pixels"]

	else:
		if hud_control.visible:
#			hud_control.visible = false
			pass
		

func _on_GameTime_deathmode_on() -> void:
	Global.game_manager.deathmode_on = true


func _on_GameTime_gametime_is_up() -> void:
	Global.game_manager.end_game()
