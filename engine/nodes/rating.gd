extends Sprite2D

var y_accum: float = -1.4

func _physics_process(_delta: float) -> void:
	position.y += y_accum
	modulate.a -= 0.024
	rotation_degrees += 0.1
	y_accum += 0.1
	
	if modulate.a <= 0:
		queue_free()
