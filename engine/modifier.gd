class_name Modifier
extends Resource

enum Type {
	Blind,
	Sway,
	BopOnBeat,
	BopOnStep,
	BopOnBeatUp,
	BopOnStepUp
}
var _type: Type
var _intensity: float = 0.0

func set_modifier_type(type: Type) -> void:
	_type = type

func set_intensity(intensity: float) -> void:
	_intensity = intensity
