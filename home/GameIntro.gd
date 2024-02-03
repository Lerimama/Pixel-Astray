extends Node2D


var direction: Vector2
onready var pixel: KinematicBody2D = $Pixel


func _ready() -> void:

	# štartej igro
	yield(get_tree().create_timer(0.1), "timeout") # zato da se vse naloži
#	set_game()


func set_game():

	# pixel on
	Global.main_camera.zoom = Vector2(2, 2)
	yield(get_tree().create_timer(2), "timeout")

#	var plejer
#	# pixel event
#	if not players_in_game.empty():
#		for player in players_in_game:
#			plejer = player
#	plejer.animation_player.play("color_burst")	
#	yield(get_tree().create_timer(3.6), "timeout")
	split_stray_colors(game_stats["stray_pixels_count"])
#	# -> tukaj daš fejdin efekt na strejse
#	yield(get_tree().create_timer(0.5), "timeout")
##	plejer.animation_player.stop()	
##	plejer.animation_player.play("still_alive")	
##	yield(get_tree().create_timer(3.5), "timeout")

	yield(get_tree().create_timer(2), "timeout")
	Global.main_camera.animation_player.play("intro_zoom")

#	Global.game_countdown.start_countdown()
#	return


	# highscore za hud
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(game_stats["level_no"])
	game_stats["highscore"] = current_highscore_line[0]
	game_stats["highscore_owner"] = current_highscore_line[1]

	Global.hud.fade_in() # hud zna vse sam ... vseskozi je GM njegov "mentor"

	# tukaj pride poziv intro
	yield(get_tree().create_timer(1), "timeout")
	Global.game_countdown.start_countdown()

#	play_intro()
#
#
#
#func play_intro():
#	pass
