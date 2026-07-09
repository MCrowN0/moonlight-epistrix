extends Node

var song_events: Dictionary[String, Script] = {
	"faceless": preload("res://scripts/songs/faceless_script.gd")
}

const song_streams: Dictionary[String, Array] = {
	"faceless": [preload("res://resources/music/faceless/Inst.ogg"), preload("res://resources/music/faceless/Voices-Opponent.ogg"), preload("res://resources/music/faceless/Voices-Player.ogg")],
	"the-culling": [preload("res://resources/music/the-culling/Inst.ogg"), preload("res://resources/music/the-culling/Voices-Opponent.ogg"), preload("res://resources/music/the-culling/Voices-Player.ogg")]
}

const CHARACTER_PATH: String = "res://resources/characters"
