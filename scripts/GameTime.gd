extends Control


signal deathmode_on
signal gametime_is_up

var timer_mode: = -1
var game_is_on: bool 

var game_time: float
export var time_minutes: float = 5
var time_seconds: float = 59
var current_second = time_seconds # to je za beleženje tre

var game_time_limit: float
var deathmatch_time: float
var minute_in_seconds = 60

onready var secs: Label = $Secs
onready var mins: Label = $Mins
onready var dots: Label = $Dots


func _ready() -> void:
	
	
	mins.text = "%02d" % time_minutes
	secs.text = "%02d" % time_seconds


func _physics_process(delta: float) -> void:

	if Global.game_manager.game_is_on:
		
		game_time += delta *50
		
		current_second = round(time_seconds + game_time * timer_mode) # -1 ena je odštevanje
		
		# normal time
		if current_second < 0:
			game_time = 0
			current_second = time_seconds
			time_minutes += timer_mode
			mins.text = "%02d" % time_minutes	
		secs.text = "%02d" % current_second
		
		# dethmoud
		if time_minutes < 1:
			modulate = Config.color_red
			emit_signal("deathmode_on")
		
		# time is up	
		if time_minutes < 0:
#			game_is_on = false
			mins.text = "00"
			secs.text = "00"
			# reset time ?
			game_time = 0 
			modulate = Config.color_red
			yield(get_tree().create_timer(1), "timeout")
			emit_signal("gametime_is_up")

	else: 
		game_time = 0
		
		
	
	

	
	
