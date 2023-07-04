extends Control

var test_view_on
func _ready() -> void:
	pass




# UI

func _on_CheckBox_toggled(button_pressed: bool) -> void:

	if test_view_on:
		test_view_on = false
		testhud_node.hide()
	else:
		testhud_node.show()
		test_view_on = true

func _on_ShakeToggle_toggled(button_pressed: bool) -> void:

	if shake_on:
		bolt_explosion_shake = 0
		bullet_hit_shake = 0
		misile_hit_shake = 0
		shake_on = false
	else:
		bolt_explosion_shake = 0.5
		bullet_hit_shake = 0.2
		misile_hit_shake = 0.4
		shake_on = true

func _on_AddTraumaBtn_pressed() -> void:
	mouse_used = true
	add_trauma(add_trauma)

func _on_TimeSlider_value_changed(value: float) -> void:
	Engine.time_scale = value

func _on_ZoomSlider_value_changed(value: float) -> void:
	zoom = Vector2(value, value)

func _on_ResetView_pressed() -> void:
	position = Vector2.ZERO + camera_center 
	zoom = Vector2.ONE

func _on_Seed_value_changed(value: float) -> void:
	noise.seed = value

func _on_Octaves_value_changed(value: float) -> void:
	noise.octaves = value

func _on_Period_value_changed(value: float) -> void:
	noise.period = value

func _on_Persistence_value_changed(value: float) -> void:
	noise.persistence = value

func _on_Lacunarity_value_changed(value: float) -> void:
	noise.lacunarity = value


# UI FOKUS

func _on_AddTraumaBtn_mouse_entered() -> void:
	mouse_used = true
func _on_AddTraumaBtn_mouse_exited() -> void:
	mouse_used = false

func _on_ResetView_mouse_entered() -> void:
	mouse_used = true
func _on_ResetView_mouse_exited() -> void:
	mouse_used = false

func _on_ZoomSlider_mouse_entered() -> void:
	mouse_used = true
func _on_ZoomSlider_mouse_exited() -> void:
	mouse_used = false

func _on_TimeSlider_mouse_entered() -> void:
	mouse_used = true
func _on_TimeSlider_mouse_exited() -> void:
	mouse_used = false

func _on_Control_mouse_entered() -> void:
	mouse_used = true
func _on_Control_mouse_exited() -> void:
	mouse_used = false

func _on_Lacunarity_mouse_entered() -> void:
	mouse_used = true
func _on_Lacunarity_mouse_exited() -> void:
	mouse_used = false

func _on_Persistance_mouse_entered() -> void:
	mouse_used = true
func _on_Persistance_mouse_exited() -> void:
	mouse_used = false

func _on_Period_mouse_entered() -> void:
	mouse_used = true
func _on_Period_mouse_exited() -> void:
	mouse_used = false

func _on_Octaves_mouse_entered() -> void:
	mouse_used = true
func _on_Octaves_mouse_exited() -> void:
	mouse_used = false

func _on_SeedSlider_mouse_entered() -> void:
	mouse_used = true
func _on_SeedSlider_mouse_exited() -> void:
	mouse_used = false

func _on_CheckBox_mouse_entered() -> void:
	mouse_used = true
func _on_CheckBox_mouse_exited() -> void:
	mouse_used = false



func _on_ShakeToggle_mouse_entered() -> void:
	pass # Replace with function body.

func _on_ShakeToggle_mouse_exited() -> void:
	pass # Replace with function body.
