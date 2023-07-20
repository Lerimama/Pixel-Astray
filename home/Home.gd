extends Node


onready var play_btn: Button = $Menu/PlayBtn
onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready():
	play_btn.grab_focus()


func _on_PlayBtn_pressed() -> void:
	Global.sound_manager.play_sfx("btn_confirm")
	animation_player.play("select_game")
	

func _on_PlayBtn_focus_exited() -> void:
	Global.sound_manager.play_sfx("btn_focus_change")


func _on_AboutBtn_pressed() -> void:
	animation_player.play("about")

func _on_AboutBtn_focus_exited() -> void:
	Global.sound_manager.play_sfx("btn_focus_change")


func _on_SettingsBtn_pressed() -> void:
	animation_player.play("settings")

func _on_SettingsBtn_focus_exited() -> void:
	Global.sound_manager.play_sfx("btn_focus_change")


func _on_CreditsBtn_pressed() -> void:
	animation_player.play("credits")

func _on_CreditsBtn_focus_exited() -> void:
	Global.sound_manager.play_sfx("btn_focus_change")


func _on_SettingsBackBtn_pressed() -> void:
	animation_player.play_backwards("settings")
	
func _on_PlayBackBtn_pressed() -> void:
	animation_player.play_backwards("select_game")
	
func _on_CreditsBackBtn_pressed() -> void:
	animation_player.play_backwards("credits")

func _on_AboutBackBtn_pressed() -> void:
	animation_player.play_backwards("about")


func _on_SelectGame1Btn_pressed() -> void:
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?

func _on_SelectGame2Btn_pressed() -> void:
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?

func _on_SelectGame3Btn_pressed() -> void:
	Global.main_node.home_out() # ... tole je, če ni animacije ... Quick play?
