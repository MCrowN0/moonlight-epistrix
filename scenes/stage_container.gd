class_name StageContainer extends Node2D

var stage_scenes: Dictionary[String, PackedScene] = {
}
var stage_node: Stage
var stage: String = "" :
	set(value):
		stage = value
		stage_node = stage_scenes[stage].instantiate()
		add_child(stage_node)
