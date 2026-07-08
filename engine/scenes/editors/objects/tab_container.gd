extends TabContainer

func _ready() -> void:
	_on_tab_changed(current_tab)

func _on_tab_changed(tab: int) -> void:
	match tab:
		0: size.y = 240
		_: size.y = 382.0
	get_parent().size.y = (414 - 382.0) + size.y
