class_name RatingContainer extends Node

var notes_played: float = 0.0
var hit_value: float = 0.0

func get_accuracy() -> float:
	if notes_played == 0: return 0.0
	
	var acc := (hit_value / notes_played) * 100.0
	return clamp(acc, 0.0, 100.0)

func note_hit(_note_id: int, rating: String, _must_hit_section: bool, _note_length: float) -> void:
	if rating == "miss": notes_played += 1
	
	if not rating in Constants.ratings: return
	
	notes_played += 1
	
	if Constants.judge_values.has(rating):
		hit_value += Constants.judge_values[rating]
	
	var rating_sprite: Sprite2D = Sprite2D.new()
	rating_sprite.texture = Constants.rating_textures[rating]
	rating_sprite.scale -= Vector2(0.3, 0.3)
	rating_sprite.set_script(preload("res://engine/nodes/rating.gd"))
	add_child(rating_sprite)
