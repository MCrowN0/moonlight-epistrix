extends Node

const directions: Array[String] = ['left', 'down', 'up', 'right']
const ratings: Array[String] = ['sick', 'good', 'bad', 'shit']
const rating_textures: Dictionary[String, CompressedTexture2D] = {
	'sick': preload("res://engine/resources/textures/ratings/sick.png"),
	'good': preload("res://engine/resources/textures/ratings/good.png"),
	'bad': preload("res://engine/resources/textures/ratings/bad.png"),
	'shit': preload("res://engine/resources/textures/ratings/shit.png")
}
const judge_values: Dictionary[String, float] = {
	"sick": 1.0,
	"good": 0.67,
	"bad": 0.34,
	"miss": 0.0
}
