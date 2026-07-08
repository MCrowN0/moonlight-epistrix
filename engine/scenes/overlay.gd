extends CanvasLayer

var max_steps: int = 10 
@warning_ignore("integer_division")
var current_step: int = max_steps / 2
var vol_widths: Array[float] = [0.0, 22.0, 39.11, 57.455, 73.25, 93.08, 115.225, 137.47, 158.16, 180.06, 203.0]

var time: float = 0.0

func _ready():
	Global.connect("on_save_loaded", func():
		current_step = Global.volume
		apply_volume(false)
	)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("volup"):
			if current_step < max_steps:
				current_step += 1
				apply_volume()
		elif event.is_action_pressed("voldown"):
			if current_step > 0:
				current_step -= 1
				apply_volume()

func apply_volume(animate: bool = true):
	create_tween().tween_property($Sprite2D/Sprite2D2, "region_rect:size:x", vol_widths[current_step], 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	create_tween().tween_property($Sprite2D/Sprite2D2, "position:x", (-302.65) + ((203- - vol_widths[current_step]) / 2), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	Global.volume = current_step
	
	var bus_index = 0
	if current_step == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		var linear = float(current_step) / max_steps
		var db = 20 * (log(linear) / log(10))
		AudioServer.set_bus_volume_db(bus_index, db)
		if animate:
			time = 0
			if $Sprite2D.position.y == -50:
				create_tween().tween_property($Sprite2D, "position:y", 60, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			set_physics_process(true)

func _physics_process(delta: float) -> void:
	time += delta
	if time >= 1:
		create_tween().tween_property($Sprite2D, "position:y", -50, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		time = 0
		set_physics_process(false)
