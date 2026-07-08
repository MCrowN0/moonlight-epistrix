extends Node2D

var cur_song: String = ""

func _ready() -> void:
	$Song.stream = ProjectData.song_streams[cur_song]
	$EventNode.set_script(ProjectData.song_events[cur_song])

	await get_tree().create_timer(1.0).timeout

	$ChartHandler.start_chart("res://resources/music/songs/%s/" % cur_song, "chart.bin")
	$HUD/OpponentStrum.hold_under_strum = true
	$HUD/PlayerStrum.hold_under_strum = true

	#$PlaySceneCamera.target_position = Vector2(640, 360)
