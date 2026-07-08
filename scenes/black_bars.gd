class_name BlackBars extends Node2D

var size: float = 0.0 :
	set(value):
		size = value
		$Top.size.y = value
		$Bottom.size.y = value
		$Bottom.position.y = 720 - value

@warning_ignore("shadowed_global_identifier")
func tween_to(value: float, time: float = 1.0, trans: Tween.TransitionType = Tween.TRANS_LINEAR, ease: Tween.EaseType = Tween.EASE_IN_OUT):
	get_tree().create_tween().tween_property(self, "size", value, time).set_trans(trans).set_ease(ease)
