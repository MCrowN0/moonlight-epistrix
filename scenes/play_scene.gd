extends Node2D

var cur_song: String = "faceless"

func _ready() -> void:
	var streams: AudioStreamSynchronized = AudioStreamSynchronized.new()
	streams.stream_count = 3
	for i in range(3):
		streams.set_sync_stream(i, ProjectData.song_streams[cur_song][i])
	$Song.stream = streams
	if ProjectData.song_events.has(cur_song):
		$EventNode.set_script(ProjectData.song_events[cur_song])

	await get_tree().create_timer(1.0).timeout
	
	$ChartHandler.start_chart("res://resources/music/%s/" % cur_song, "chart.bin")
