extends FoldableContainer

var dragging := false
var drag_offset := Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if event.pressed and not (get_viewport().get_mouse_position().x - position.x) <= 30:
				dragging = true
				drag_offset = event.position
				get_viewport().set_input_as_handled()
			else:
				dragging = false
	
	if event is InputEventMouseMotion and dragging:
		position.x = clamp((position.x + event.relative.x), 0, 1280 - size.x)
		position.y = clamp((position.y + event.relative.y), 0, 720 - size.y)
		Input.warp_mouse(Vector2(clamp(get_viewport().get_mouse_position().x, 0, 1280), clamp(get_viewport().get_mouse_position().y, 0, 720)))
		get_viewport().set_input_as_handled()
