extends Node

@onready var song: AudioStreamPlayer = get_parent().get_node("Song")

const fast_foward_speed = 8.0
const normal_speed = 1.0
const fast_foward_input = "debug_fast_foward"
const fast_foward_volume = -20.0
const normal_volume = 0.0

func _input(event: InputEvent) -> void:
	var speed
	var volume

	if event.is_action_pressed(fast_foward_input):
		speed = fast_foward_speed
		volume = fast_foward_volume
		
	elif event.is_action_released(fast_foward_input): 
		speed = normal_speed
		volume = normal_volume
	else: return
	
	Engine.time_scale = speed
	song.pitch_scale = speed
	song.volume_db = volume
	
