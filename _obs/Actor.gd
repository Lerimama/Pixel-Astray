extends KinematicBody2D


var pixel_color =  Color.white
var direction: Vector2
onready var cell_size_x = 32 
export var step_time: float = 0.15
onready var Ghost: PackedScene = preload("res://game/pixel/ghost.tscn")
 

func _ready() -> void:

	global_position = Global.snap_to_nearest_grid(global_position)


	# štartej igro
#	yield(get_tree().create_timer(0.1), "timeout") # zato da se vse naloži
#	set_game()

#func _process(delta: float) -> void:
#	yield(get_tree().create_timer(0.1), "timeout") # zato da se vse naloži
#	step(Vector2.UP)
#	yield(get_tree().create_timer(0.1), "timeout") # zato da se vse naloži
##	step(Vector2.UP)
#	step(Vector2(100,100))
##
##	if Input.is_action_pressed("ui_up"): # ne koraka z 1 energijo
##		direction = Vector2.UP
##		step()
##	elif Input.is_action_pressed("ui_down"):
##		direction = Vector2.DOWN
##		step()
##	elif Input.is_action_pressed("ui_left"):
##		direction = Vector2.LEFT
##		step()
##	elif Input.is_action_pressed("ui_right"):
##		direction = Vector2.RIGHT
##		step()
##
##
#func step(step_direction):
#
#
#	global_position += direction * cell_size_x
	# če kolajda izbrani smeri gibanja prenesem kontrole na skill
	
#	global_position = Global.snap_to_nearest_grid(global_position)
	
#	spawn_trail_ghost()

#	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
#	step_tween.tween_property(self, "position", global_position + direction * cell_size_x, step_time)
#	step_tween.tween_callback(self, "end_move")
#
#	# pošljem signal, da odštejem točko
#	emit_signal("stat_changed", self, "cells_travelled", 1)
#
#func end_move():
#
#	global_position = Global.snap_to_nearest_grid(global_position)
#	# reset ray dir
#	direction = Vector2.ZERO
#
#func spawn_trail_ghost():
#
#	var trail_alpha: float = 0.2
#	var trail_ghost_fade_time: float = 0.4
#
#	var new_trail_ghost = spawn_ghost(global_position)
#	new_trail_ghost.modulate.a = trail_alpha
#
#	# fadeout
#	var trail_fade_tween = get_tree().create_tween()
#	trail_fade_tween.tween_property(new_trail_ghost, "modulate:a", 0, trail_ghost_fade_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
#	trail_fade_tween.tween_callback(new_trail_ghost, "queue_free")
#
#
#func spawn_ghost(current_pixel_position):
#
#	# trail ghosts
#	var new_pixel_ghost = Ghost.instance()
#	new_pixel_ghost.global_position = current_pixel_position
#	new_pixel_ghost.modulate = pixel_color
#	get_parent().add_child(new_pixel_ghost)
#
#	return new_pixel_ghost
