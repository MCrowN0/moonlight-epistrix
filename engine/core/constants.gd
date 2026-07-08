extends Node

var uses_custom_directions = ProjectData.get("directions") == null
var uses_custom_ratings = ProjectData.get("ratings") == null
var uses_custom_rating_textures = ProjectData.get("rating_textures") == null
var uses_custom_judge_values = ProjectData.get("judge_values") == null

var directions: Array[String]:
	get:
		return ProjectData.get("directions") if not uses_custom_directions else EngineConstants.directions
var ratings: Array[String]:
	get:
		return ProjectData.get("ratings") if not uses_custom_ratings else EngineConstants.ratings
var rating_textures: Dictionary[String, CompressedTexture2D]:
	get:
		return ProjectData.get("rating_textures") if not uses_custom_rating_textures else EngineConstants.rating_textures
var judge_values: Dictionary[String, float]:
	get:
		return ProjectData.get("judge_values") if not uses_custom_judge_values else EngineConstants.judge_values
