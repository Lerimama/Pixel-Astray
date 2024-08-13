extends SceneTree

class_name CustomSceneTree

var _throttler = null


func _initialize() -> void:
	print("Main loop initialized")
	
func _finalize() -> void:
	print("Main loop finalized")


func _physics_process(_delta: float) -> bool:
	
	if _throttler == null:
		_throttler = self.root.get_node_or_null("Throttled")
	if _throttler._is_setup:
		_throttler._run_callables()
		
	return false


func _process(_delta: float) -> bool:
	print("Process")
	return false
