extends Node2D


onready var perf_stat: Label = $VBoxContainer/PerfStat
onready var perf_stat_2: Label = $VBoxContainer/PerfStat2
onready var perf_stat_3: Label = $VBoxContainer/PerfStat3
onready var perf_stat_4: Label = $VBoxContainer/PerfStat4
onready var perf_stat_5: Label = $VBoxContainer/PerfStat5
onready var perf_stat_6: Label = $VBoxContainer/PerfStat6


func _process(delta: float) -> void:
	
	#	print("Performance ----------------") # Prints the FPS to the console
	#	print(" TIME_FPS -> ",Performance.get_monitor(Performance.TIME_FPS)) # Prints the FPS to the console
	#	print(" RENDER_TEXTURE_MEM_USED -> ",Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)) # Prints the FPS to the console
	#	print(" RENDER_VIDEO_MEM_USED -> ",Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) # Prints the FPS to the console
	#	print(" RENDER_VERTICES_IN_FRAME -> ",Performance.get_monitor(13)) # Prints the FPS to the console
	#	print(" OBJECT_COUNT -> ",Performance.get_monitor(Performance.OBJECT_COUNT)) # Prints the FPS to the console
	#	print(" OBJECT_RESOURCE_COUNT -> ",Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)) # Prints the FPS to the console

	if visible:
		perf_stat.text = "FPS: %d" % Performance.get_monitor(Performance.TIME_FPS)
		perf_stat_2.text = "Texture memory: %d" % Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
		perf_stat_3.text = "Video memory: %d" % Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
		perf_stat_4.text = "Object count: %d" % Performance.get_monitor(Performance.OBJECT_COUNT)
		perf_stat_5.text = "Obj resource count: %d" % Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
