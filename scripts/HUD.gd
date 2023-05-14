extends Node2D


var player_stats: Dictionary
var game_stats: Dictionary

onready var hud_control: Control = $HudControl

# player hud
onready var player_life: Label = $HudControl/Life
onready var player_points: Label = $HudControl/Points
onready var player_color: Label = $HudControl/PlayerColor
onready var skill_change_count: Label = $HudControl/SkilChangeCount
onready var cells_travelled: Label = $HudControl/CellsTravelled

# game hud
onready var game_time: Label = $HudControl/GameTime
onready var stray_pixels: Label = $HudControl/PixelsStray
onready var black_pixels: Label = $HudControl/PixelsHome
onready var picked_color: Control = $HudControl/PickedColor
onready var color_rect: ColorRect = $HudControl/ColorPicked/ColorBox/ColorRect
onready var value: Label = $HudControl/ColorPicked/Value


# temp ... moral bi delat z global nodetom
onready var game_manager: Node = $"../../GameManager"


func _ready() -> void:
	
	# skrij statistiko
	hud_control.visible = true

#	Global.game_manager.connect("stat_change_received", self, "on_stat_change_received", [], CONNECT_DEFERRED) # signal pride iz GM in pošlje spremenjeno statistiko
#	game_manager.connect("stat_change_received", self, "_on_stat_change_received") # signal pride iz GM in pošlje spremenjeno statistiko


func _process(delta: float) -> void:
	
	if Global.game_manager.game_started:
		
		if not hud_control.visible:
			hud_control.visible = true
		
		player_stats = Global.game_manager.new_player_stats
		game_stats = Global.game_manager.new_game_stats
		
		# pixel stats
		player_life.text = "LIFE: %s" % player_stats["life"]
		player_points.text = "POINTS: %02d" % player_stats["points"]
		skill_change_count.text = "SKILL CHANGES: %02d" % player_stats["skill_change_count"]
		cells_travelled.text = "CELLS TRAVELLED: %04d" % player_stats["cells_travelled"]
		
		# game stats
		stray_pixels.text = "STRAY PIXELS: %02d" % Global.game_manager.new_game_stats["stray_pixels"]
		black_pixels.text = "BLACK PIXELS: %02d" % Global.game_manager.new_game_stats["black_pixels"]
#		game_time.text = "00:%02d" % Global.game_manager.new_game_stats["game_time"]

	else:
		if hud_control.visible:
#			hud_control.visible = false
			pass
		

