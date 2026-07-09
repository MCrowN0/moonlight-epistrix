extends Control

const NOTE_SIZE: Vector2 = Vector2(157, 157) * Vector2(0.286, 0.286)

var local_beat: float = 0
var _local_oldstep: float = 0.0
var local_step: float = 0.0
var v1_chart: bool = false

@onready var conductor: Conductor = $Conductor

var cur_section: int = int(local_step / 16)

var chart: ChartResource

var internal_chart_data: Dictionary = {
	"song": {
		"notes": [
			{
				"sectionNotes": [
					[
						0,
						1,
						200
					]
				],
				"sectionBeats": 4,
				"bpm": 150,
				"changeBPM": false,
				"mustHitSection": false
			}
		]
	}
}

func _internal_seek(time: float = 0.0):
	$Instrumental.seek(time)
	$Voices.seek(time)

func _ready() -> void:
	conductor.target_audio = $Instrumental
	conductor.tempo = 140.0
	
	$ChartLoadFileDialog.add_filter("*.bin", "Project Overkill Binary Chart")
	$ChartLoadFileDialog.add_filter("*.json", "Psych Engine Legacy Chart")
	$ChartSaveFileDialog.add_filter("*.bin", "Project Overkill Binary Chart")
	for note in internal_chart_data["song"]["notes"][floori(cur_section)]["sectionNotes"]:
		var note_time: float = note[0]
		$ChartGrid.add_note((conductor.get_beat_at_time(note_time / 1000.0) * 4.0) * 157, note[1])

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	$ChartGrid.reset_grid()
	for note in internal_chart_data["song"]["notes"][floori(local_step / 16)]["sectionNotes"]:
		var note_time: float = note[0]
		$ChartGrid.add_note(((conductor.get_beat_at_time(note_time / 1000.0) - (floori(local_step / 16) * 4.0)) * 4.0) * 157, note[1])
	
	if local_step < 0: local_step = 0
	
	_local_oldstep = local_step
	if conductor.target_audio.playing:
		local_step = conductor.get_step()
		
	$ScrollLine.position.y = NOTE_SIZE.y * fmod(local_step, 16)
 
	if $CanvasLayer2/FoldableContainer/TabContainer/Charting/ContinuousScrolling.button_pressed :
		$Camera2D.position.y = $ScrollLine.position.y
	
	$CanvasLayer2/RichTextLabel.text = "[b]BEAT[/b] [i][ %s ][/i]\n[b]STEP[/b] [i][ %s ][/i]\n[b]SECTION[/b] [i][ %s ][/i]\n[b]BPM[/b] [i][ %s ][/i]" % [
		str(local_step / 4),
		str(local_step),
		str(floori(local_step / 16)),
		str(conductor.tempo)
	]

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton and event.is_pressed():
		if Input.is_action_just_pressed("ui_down") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			local_step = round(local_step + 1)
			
			_internal_seek(conductor.get_time_from_beat(local_step / 4.0))
		if Input.is_action_just_pressed("ui_up") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP):
			local_step = round(local_step - 1)
			if local_step < 0: local_step = 0 
			_internal_seek(conductor.get_time_from_beat(local_step / 4.0))
		if Input.is_action_just_pressed("ui_a"):
			local_step = round(local_step - 16)
			if local_step < 0: local_step = 0 
			_internal_seek(conductor.get_time_from_beat(local_step / 4.0))
		if Input.is_action_just_pressed("ui_d"):
			local_step = round(local_step + 16)
			_internal_seek(conductor.get_time_from_beat(local_step / 4.0))
		if Input.is_action_just_pressed("ui_space"):
			if not $Instrumental.playing:
				$Instrumental.play(conductor.get_time_from_beat(local_step / 4.0))
				$Voices.play(conductor.get_time_from_beat(local_step / 4.0))
				conductor.active = true
			else:
				$Instrumental.playing = false
				$Voices.playing = false 
				conductor.active = false

func _on_load_pressed() -> void:
	$CanvasLayer2/FoldableContainer/TabContainer/Song/Load.release_focus()
	$ChartLoadFileDialog.popup_centered_ratio()

func _on_save_pressed() -> void:
	$CanvasLayer2/FoldableContainer/TabContainer/Song/Save.release_focus()
	$ChartSaveFileDialog.popup_centered_ratio()

func _on_chart_load_file_dialog_file_selected(path: String) -> void:
	if path.ends_with(".json"):
		chart = ChartResource.new()
		var chart_data = load(path).data
		if chart_data.has("song") and not chart_data.get("song") is String:
			chart_data = chart_data.get("song")
		else:
			v1_chart = true
		chart.new_empty(chart_data.get("bpm"), chart_data.get("speed"), len(chart_data.get("notes")))
		var section_index: int = 0
		for section: Dictionary in chart_data.get("notes"):
			chart.add_section(
				section.get("sectionBeats", 4.0),
				section.get("mustHitSection", false),
				section.get("changeBPM", false),
				section.get("bpm", 130),
				len(section.get("sectionNotes", []))
			)
			for note in section.get("sectionNotes", []):
				chart.add_note(
					section_index,
					note[0],
					note[1],
					note[2]
				)
			section_index += 1
		$CanvasLayer2/FoldableContainer/TabContainer/Song/ChartStatus.text = "Chart loaded & converted!"
	if path.ends_with(".bin"):
		chart = ChartResource.new()
		chart.load(path)
		$CanvasLayer2/FoldableContainer/TabContainer/Song/ChartStatus.text = "Chart loaded!"

func _on_chart_save_file_dialog_file_selected(path: String) -> void:
	chart.save(ProjectSettings.globalize_path(path))
	$CanvasLayer2/FoldableContainer/TabContainer/Song/ChartStatus.text = "Chart saved!"

func _on_foldable_container_folding_changed(_is_folded: bool) -> void:
	$CanvasLayer2/FoldableContainer.release_focus()
