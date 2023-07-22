extends HBoxContainer


var energy: int setget _on_amount_change
var previous_energy: int # preverjam smer spremembe lajfa
var low_energy: float 
var low_energy_level: float = 0.2 # 10% ... going red 

onready var texture_progress: TextureProgress = $TextureProgress


func _ready() -> void:
	
	set_icons_state() # preveri lajf na začetku in seta pravilno stanje ikon 
	low_energy = texture_progress.max_value * low_energy_level

func _process(delta: float) -> void:
	
	self.energy = Global.game_manager.player_stats["player_energy"]
	
	
func _on_amount_change(new_value):
	
	# setam prev energy ... pravi_life count se še ni spremenil
	previous_energy = energy 
	
	# setam current energy
	energy = new_value # v bistvu Global.game_manager.player_stats["player_energy"]
	
	if previous_energy > energy and energy > low_energy:
#		modulate = Global.color_red
#		yield(get_tree().create_timer(0.5), "timeout")
#		modulate = Color.white
		pass
	
	elif previous_energy < energy and energy > low_energy:
		modulate = Global.color_green
		yield(get_tree().create_timer(0.5), "timeout")
		modulate = Color.white
		
	elif energy <= low_energy:
		modulate = Global.color_red
		
	else: # če ni spremembe	
		return
	
	set_icons_state()
 

func set_icons_state():
	
	texture_progress.value = energy
