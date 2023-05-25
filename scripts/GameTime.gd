extends Control


signal deathmode_on
signal gametime_is_up

var timing_stopped: bool # kontrola znotraj timerja

var start_minutes: float = 5 # uporabno samo za "self-start"
var start_seconds: float = 59 # ko apliciraš minute, se odšteje ena minuta in 00 sekund nadomesti 59
var deathmode_start_time: float = 1

var time_minutes: float
var time_seconds: float

var game_time: float

onready var secs: Label = $Secs
onready var mins: Label = $Mins
onready var dots: Label = $Dots


func _ready() -> void:
	
#	restart_timer(start_minutes)
	pass

func _physics_process(delta: float) -> void:

	if Global.game_manager.game_is_on and not timing_stopped:
		
		game_time += delta # * 50
		
		var current_second = round(time_seconds - game_time ) # -1 ena je odštevanje
		
		# normal time
		if current_second < 0:
			game_time = 0
			current_second = time_seconds
			time_minutes -= 1
			mins.text = "%02d" % time_minutes	
		secs.text = "%02d" % current_second
		
		# dethmoud
		if time_minutes < deathmode_start_time:
			modulate = Config.color_red
			emit_signal("deathmode_on")
		
		# time is up	
		if time_minutes < 0:
			mins.text = "00"
			secs.text = "00"
			
			# reset time ?
			game_time = 0 
			timing_stopped = true
			
			modulate = Config.color_red
			yield(get_tree().create_timer(1), "timeout")
#			emit_signal("gametime_is_up")

	else: # nerabim ampak zazih
		game_time = 0
		timing_stopped = true
		
func restart_timer(restart_minutes):
	
	# ustavim štoparico
	timing_stopped = true
	
	# hud prikaže začeten čas (mm:00)
	mins.text = "%02d" % restart_minutes
	secs.text = "00"
	yield(get_tree().create_timer(1), "timeout")
	
	# ga zapišem v hudu
	mins.text = "%02d" % (restart_minutes - 1)
	secs.text = "%02d" % start_seconds			
	# resetiram čas na tajmerju na "prirejen" začeten čas  (mm-1:59)
	time_minutes = restart_minutes - 1
	time_seconds = start_seconds
	
	# začnem štopat
	yield(get_tree().create_timer(0.5), "timeout")
	
	timing_stopped = false
	
	

	
	
