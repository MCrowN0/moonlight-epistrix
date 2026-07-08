extends Sprite2D

@export var movement_strength: float = 20.0
@export var smooth_speed: float = 8.0

var center_position: Vector2 = Vector2(640, 360)

func _ready():
	position = center_position

func _process(delta):
	var viewport_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	mouse_pos = mouse_pos.clamp(Vector2.ZERO, viewport_size)

	@warning_ignore("shadowed_variable_base_class")
	var offset = (mouse_pos - viewport_size * 0.5) / (viewport_size * 0.5)

	var target = center_position + offset * movement_strength

	position = position.lerp(target, smooth_speed * delta)
