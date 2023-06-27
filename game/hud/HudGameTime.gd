extends Control


signal deathmode_on # pošlje se v hud, ki javi game managerju
signal gametime_is_up # pošlje se v hud, ki javi game managerju

export var countdown_mode: bool = false
export var timing_on: bool # kontrola znotraj timerja

var time: float # čas v timerju
var time_minutes: float
var time_seconds: float

# stopwatch
var time_limit: float = 5 # omejen čas poslan od drugje (5 je, če je samoštartan)

# countdown
var start_minutes: float = 1 # uporabno kadar ne dobi podatkov od zunaj
var start_seconds: float = 59 # ko apliciraš minute, se odšteje ena minuta in 00 sekund nadomesti 59

var deathmode_time: float = 1

onready var secs: Label = $Secs
onready var mins: Label = $Mins
onready var dots: Label = $Dots


func _ready() -> void:

	timing_on = false


func _physics_process(delta: float) -> void:
	
	if timing_on: # timing_on se prižge na kocnu start_timer
		
		if countdown_mode:
			countdown(delta)
		else:
			stopwatch(delta)


func start_timer(game_time):
	
	modulate = Global.color_white
	
	
	if countdown_mode:
	
		# hud prikaže začeten čas (mm:00)
		start_minutes = game_time
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
		
	# stopwatch
	else:
		
		time_limit = game_time
		
		time = 0
		mins.text = "00"
		secs.text = "00"
	
	# začnem štopat
	yield(get_tree().create_timer(0.5), "timeout")
	timing_on = true
	
	
func stop_timer():
	
	# ustavim štoparico
	timing_on = false
	modulate = Global.color_red
		
					
func restart_timer(minutes):
	
	stop_timer()
	start_timer(minutes)

		
func stopwatch(delta):	
		
		time += delta #* 50
		
		# sekunde
		var game_seconds: float = round(time)
		var current_second = int(game_seconds) % 60
		if current_second > 59:
			current_second = 00
		secs.text = "%02d" % current_second
		
		# izračun minut
		var minutes_passed = floor(round(time) / 60)
		mins.text = "%02d" % minutes_passed	

		# time is up	
		if game_seconds > time_limit - 1: # ker uravnavam s časom, ki je PRETEKEL
			stop_timer()
			emit_signal("gametime_is_up")


func countdown(delta):
		
		time += delta #* 50
		
		var current_second = round(time_seconds - time ) # -1 ena je odštevanje
		
		# normal time
		if current_second < 0:
			time = 0
			current_second = time_seconds
			time_minutes -= 1
			mins.text = "%02d" % time_minutes	
		secs.text = "%02d" % current_second
		
		# deathmoud
		if time_minutes < deathmode_time:
			modulate = Global.color_red
			emit_signal("deathmode_on") # pošlje se v hud, ki javi game managerju		
		
		# time is up	
		if time_minutes < 0:
			time = 0 # zazih
			mins.text = "00"
			secs.text = "00"
			stop_timer()
			emit_signal("gametime_is_up") # pošlje se v hud, ki javi game managerju		
			

	

	
	
