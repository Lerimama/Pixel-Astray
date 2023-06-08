extends Control


signal deathmode_on
signal gametime_is_up

export var countdown_mode: bool = false

export var timing_on: bool # kontrola znotraj timerja

var start_minutes: float = 5 # uporabno samostart_min za "self-start"
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
	
	if Global.game_manager.game_is_on and timing_on:
		
		if countdown_mode:
			count_down(delta)
		else:
			count_up(delta)


		
func count_up(delta):	
		
		game_time += delta # * 50
		
		# sekunde
		var game_seconds: int = round(game_time)
		var current_second = game_seconds % 60
		if current_second > 59:
			current_second = 00
		secs.text = "%02d" % current_second
		
		# izračun minut
		var minutes_passed = floor(round(game_time) / 60)
		mins.text = "%02d" % minutes_passed	

		# time is up	
		if minutes_passed > start_minutes - 1: # ker uravnavam z minutami, ki so pretekle
			print("juhej")
			stop_timer()
			emit_signal("gametime_is_up")


func count_down(delta):
		
		game_time += delta #* 50
		
		var current_second = round(time_seconds - game_time ) # -1 ena je odštevanje
		
		# normal time
		if current_second < 0:
			game_time = 0
			current_second = time_seconds
			time_minutes -= 1
			mins.text = "%02d" % time_minutes	
		secs.text = "%02d" % current_second
		
		# deathmoud
		if time_minutes < deathmode_start_time:
			modulate = Config.color_red
			emit_signal("deathmode_on")
		
		# time is up	
		if time_minutes < 0:
			game_time = 0 # zazih
			mins.text = "00"
			secs.text = "00"
			stop_timer()
			emit_signal("gametime_is_up")		
		

func start_timer(minutes):
	
	modulate = Config.color_white
	# hud prikaže začeten čas (mm:00)
	if countdown_mode:
		
		start_minutes = minutes
		
		mins.text = "%02d" % start_minutes
		secs.text = "00"
		# mine prva sekunda ...
		yield(get_tree().create_timer(1), "timeout")
		# popravim sekundo v hudu
		mins.text = "%02d" % (start_minutes - 1)
		secs.text = "%02d" % start_seconds	
		# resetiram čas na samme tajmerju na "prirejen" začeten čas  (mm-1:59)
		time_minutes = start_minutes - 1
		time_seconds = start_seconds
	else:
		game_time = 0
		mins.text = "00"
		secs.text = "00"
	
	# začnem štopat
	yield(get_tree().create_timer(0.5), "timeout")
	timing_on = true
	
	
func stop_timer():
	
	# ustavim štoparico
	timing_on = false
	modulate = Config.color_red
		
					
func restart_timer(minutes):
	
	stop_timer()
	start_timer(minutes)
	
	
		

		

	

	
	
