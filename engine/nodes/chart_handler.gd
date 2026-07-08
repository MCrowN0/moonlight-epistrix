class_name ChartHandler extends Node

enum VocalMode {
	Full,
	InstAndVox,
	InstAndSeparatedVox
}



@export_node_path("Control") var opponent_strum: NodePath
@export_node_path("Control") var player_strum: NodePath

@export_node_path("Conductor") var conductor: NodePath

@export_node_path("Camera2D") var playscene_camera: NodePath

@export_node_path("EventNode") var script_: NodePath

@onready var opponent_strum_node: Strum = get_node_or_null(opponent_strum)
@onready var player_strum_node: Strum = get_node_or_null(player_strum)

@onready var conductor_node: Conductor = get_node_or_null(conductor)

@onready var playscene_camera_node: Camera2D = get_node_or_null(playscene_camera) 

@onready var script_node: EventNode = get_node_or_null(script_)

## stream 0 - inst
## stream 1 - full vox OR opponent vox
## stream 2 - player vox
@export var vocal_mode: VocalMode = VocalMode.Full

@export_node_path("AudioStreamPlayer") var song_path: NodePath

@onready var song_node: AudioStreamPlayer = get_node_or_null(song_path)

var must_hit_section: bool = false

var health: float = 0.5

var section: int = 0
var arrow: int = 0
var current_section_data: Array = []

var scroll_speed: float = 1.0
var is_legacy_psych_chart: bool = false
var is_binary: bool = false

var dead_beats: int = 0

var health_damage: float = 0.05
var health_gain: float = 0.05

var chart: ChartResource
var chart_metadata: Dictionary
var chart_sections: Array

var is_dead: bool = false

const note = preload("res://engine/nodes/note.tscn")

signal death

## This function should be called after any countdown or whatever that you have.
## It starts the song and the chart
func start_chart(song_folder_path: String = '', chart_name: String = 'chart.json', from_position: float = 0.0) -> void:
	chart = ChartResource.new()
	chart.load("%s/%s" % [song_folder_path, chart_name])
	chart_metadata = chart.get_metadata()
	chart_sections = chart.get_sections()
	scroll_speed = chart_metadata.get("scroll_speed", 1.0)
		
	if is_instance_valid(opponent_strum_node):
		opponent_strum_node.conductor_node = conductor_node
		opponent_strum_node.scroll_speed = scroll_speed
		if is_instance_valid(playscene_camera_node):
			opponent_strum_node.connect("note_hit", Callable(playscene_camera_node, "opponent_note_hit"))
			if is_instance_valid(opponent_strum_node.character_node):
				conductor_node.connect("beat_hit", opponent_strum_node.character_node.beat_hit)
				playscene_camera_node.opponent_character = opponent_strum_node.character_node

	if is_instance_valid(player_strum_node):
		player_strum_node.conductor_node = conductor_node
		player_strum_node.scroll_speed = scroll_speed
		if is_instance_valid(playscene_camera_node):
			player_strum_node.connect("note_hit", Callable(playscene_camera_node, "player_note_hit"))
			@warning_ignore("unused_parameter", "shadowed_variable")
			player_strum_node.connect("advanced_note_hit", func(note_id, note_length, target_time, current_time, start_hold):
				if start_hold or note_length <= 0:
					health = clamp(health + health_gain, 0, 1)
			)
			@warning_ignore("unused_parameter", "shadowed_variable")
			player_strum_node.connect("note_miss", func(note_id, must_hit_section):
				health = clamp(health - health_damage, 0, 1)
			)
			if is_instance_valid(player_strum_node.character_node):
				conductor_node.connect("beat_hit", player_strum_node.character_node.beat_hit)
				playscene_camera_node.player_character = player_strum_node.character_node

	var section_time: float = 0.0
	var section_beats: int = 0
	conductor_node.reset_tempo_changes()
	@warning_ignore("shadowed_variable")
	for section in chart_sections:
		section_beats += section.beats
		section_time = conductor_node.get_time_from_beat(section_beats)
		if section.change_bpm == true:
			var bpm_change = BpmChange.new()
			bpm_change.time = section_time
			bpm_change.bpm = section.bpm

	if has_node(song_path):
		song_node.play(from_position)
		conductor_node.target_audio = song_node
	
	conductor_node.active = true
	conductor_node.tempo = chart_metadata.get("bpm", 130)
	
	if is_instance_valid(script_node):
		if script_node.has_method("_on_song_start"): script_node.call("_on_song_start")

func _physics_process(_delta: float) -> void:
	if health <= 0.0 and !is_dead: 
		is_dead = true
		death.emit()

	if conductor_node.active:
		if is_instance_valid(script_node):
			if conductor_node.get_time() >= script_node.get_first_event_time():
				script_node.call_first_event()
		
		if section < len(chart_sections) - 1:
			current_section_data = chart_sections[section].get("notes", [])
			if len(current_section_data) > 0:
				if (conductor_node.get_time() >= (current_section_data[arrow].get("time", 0.0) / 1000) - 20):
					must_hit_section = chart_sections[section].get("must_hit_section", false)
					if must_hit_section:
						if current_section_data[arrow].get("id") < 4:
							player_strum_node._spawn_note(int(current_section_data[arrow].get("id")) % 4, current_section_data[arrow].get("time"), current_section_data[arrow].get("length"), must_hit_section)
						else:
							opponent_strum_node._spawn_note(int(current_section_data[arrow].get("id")) % 4, current_section_data[arrow].get("time"), current_section_data[arrow].get("length"), must_hit_section)
					else:
						if current_section_data[arrow].get("id") < 4:
							opponent_strum_node._spawn_note(int(current_section_data[arrow].get("id")) % 4, current_section_data[arrow].get("time"), current_section_data[arrow].get("length"), must_hit_section)
						else:
							player_strum_node._spawn_note(int(current_section_data[arrow].get("id")) % 4, current_section_data[arrow].get("time"), current_section_data[arrow].get("length"), must_hit_section)
					arrow += 1
				
			if arrow >= len(current_section_data):
				arrow = 0
				section += 1
