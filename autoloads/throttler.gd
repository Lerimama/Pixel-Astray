extends Node

# CALL THROTLED --------------------------------------------------------------


var _to_call: Array = []
var _mutex: Mutex = Mutex.new()

var _frame_budget_msec: = 0 # 60 frametov na sekundo je cca 16 miliskund na frejm
# ko se igra naloži začnem štet ... GM
var _frame_budget_threshold_msec: = 0
var _is_setup: bool = false

# youtube video https://www.youtube.com/watch?v=WLDM0tQ-XqE
# project settings / general / run > SceneTree spremeniš v CustomSceneTree

# vsak frame kliče adaptiran TREE 
func _run_callables() -> void:

	if not _is_setup:
		push_error("Please run THROTTLER.start before calling")
		return

	var frame_budget_remaining_msec: = _frame_budget_msec	
	var frame_budget_used_msec: = 0
	var is_working: = true
	var call_count: = 0

	# dokler dela naj loopa
	# ko zmanjka časa znotraj frejma, neha delat ... potem se spet zažene z naslednjim frejmom FP
	while is_working:
		
		var before: = Time.get_ticks_msec()	

		# call next callable
		_mutex.lock()
		var entry = _to_call.pop_front()
		_mutex.unlock()

		var did_call: = false
		if entry:
			var callable_string = entry["callable"]
			var callable = entry["callable"]
			var args = entry["args"]
#			if not callable.empty:
			if callable != null and callable.is_valid():
# v4				if args != null and typeof(args) == TYPE_ARRAY and not args.is_empty():
				if args != null and typeof(args) == TYPE_ARRAY and not args.empty():
					entry["callable_object"].call_funcv(args)
#					callable.callv(args)
				else:
					entry["callable_object"].call_func()
#					callable.call()
				
				did_call = true
				call_count = +1
		
		# time taken
		var after: = Time.get_ticks_msec()
		var used: = after - before
		frame_budget_remaining_msec -= used
		frame_budget_used_msec += used	

		# stop running callables if none are left, or we are over budget
		if not did_call or frame_budget_remaining_msec < _frame_budget_threshold_msec:
			is_working = false

	if call_count > 0:
		print("budger: %s, used: %s, remaining: %s, calls: %s" % [_frame_budget_msec, frame_budget_used_msec, frame_budget_remaining_msec, call_count])


func start(frame_budget_mesec: int, frame_budget_threshold_msec: int) -> void:

	_frame_budget_msec = frame_budget_mesec
	_frame_budget_threshold_msec = frame_budget_threshold_msec
	_is_setup = true


func call_throttled(method_on_object: Node, method_string: String, args: Array = []) -> void:
# v4 func call_throttled(method, args: Array = []) -> void:

	printt ("CALLABLE", method_on_object, method_string, args)
	
	var callable_function: = funcref(method_on_object, method_string)
	var entry: Dictionary = {
		"callable_object" : method_on_object,
		"callable" : callable_function,
		"args": args,
	}

	_mutex.lock()
	_to_call.push_back(entry)
	_mutex.unlock()

