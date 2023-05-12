extends Node2D


var player_stats: Dictionary
var game_stats: Dictionary

onready var hud_control: Control = $Control

# player hud
onready var player_life: Label = $Control/PlayerLife
onready var player_points: Label = $Control/PlayerPoints
onready var player_color: Label = $Control/PlayerColor
onready var colors_picked: Label = $Control/ColorsPicked
onready var color_change_count: Label = $Control/ColorChangeCount

# game hud
onready var game_time: Label = $Control/GameTime
onready var stray_pixels: Label = $Control/PixelsStray
onready var black_pixels: Label = $Control/PixelsHome
onready var colors_left: Label = $Control/ArenaColors

# temp ... moral bi delat z global nodetom
onready var game_manager: Node = $"../../GameManager"


func _ready() -> void:
	
	# skrij statistiko
	hud_control.visible = false

#	Global.game_manager.connect("stat_change_received", self, "on_stat_change_received", [], CONNECT_DEFERRED) # signal pride iz GM in pošlje spremenjeno statistiko
	game_manager.connect("stat_change_received", self, "_on_stat_change_received") # signal pride iz GM in pošlje spremenjeno statistiko


func _process(delta: float) -> void:
	
	if Global.game_manager.game_started:
		
		if not hud_control.visible:
			hud_control.visible = true
		
		player_stats = Global.game_manager.new_player_stats
		game_stats = Global.game_manager.new_game_stats
		
		# pixel stats
		player_life.text = "P1 LIFE: %s" % player_stats["life"]
		player_points.text = "P1 POINTS: %02d" % player_stats["points"]   # dela
		player_color.text = "P1 COLOR SUM: %02d" % player_stats["color_sum"]
		player_color.text = "P1 PICKED COLORS: %02d" % player_stats["colors_picked"]
		color_change_count.text = "COLOR CHANGES: %02d" % player_stats["color_change_count"]
		# game stats
		game_time.text = "00:%02d" % Global.game_manager.new_game_stats["game_time"]
		stray_pixels.text = "STRAY PIXELS: %02d" % Global.game_manager.strays_in_game.size()
		black_pixels.text = "BLACK PIXELS: %02d" % Global.game_manager.strays_in_game.size()
	else:
		if hud_control.visible:
			hud_control.visible = false
		

