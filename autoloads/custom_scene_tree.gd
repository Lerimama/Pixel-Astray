extends SceneTree
class_name CustomSceneTree


var _throttler = null

func _initialize() -> void:
	print("Main loop initialized")
	
	
func _finalize() -> void:
	print ("Main Loop Finalized")
	
func _physics_process(_delta: float) -> bool: # custom _FP
	print ("!!!!!___FP")
	
	# workaround zaradi zaporedja ker se zogid pred AL funkcijami ... https://youtu.be/WLDM0tQ-XqE?t=439
	if _throttler == null:
		_throttler = self.root.get_node_or_null("Throttler")
	if _throttler._is_setup:
		_throttler._run_callables()
		
	return false
	
func _process(_delta: float) -> bool: # custom _P
	
	print ("!!!!!___P")
	
	return false
