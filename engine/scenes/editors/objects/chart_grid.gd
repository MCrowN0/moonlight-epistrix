extends Control

const strum_note_scene: PackedScene = preload("res://engine/scenes/editors/objects/strum_note.tscn")
var notes: Array[TextureRect] = []



func add_note(y: float, note_id: int = 0) -> void:
	var strum_note_instance: TextureRect = strum_note_scene.instantiate()
	strum_note_instance.note_id = note_id
	strum_note_instance.position.x = (157 * note_id)
	strum_note_instance.position.y = y
	$GridBG/NoteContainer.add_child(strum_note_instance)

func reset_grid() -> void:
	for child in $GridBG/NoteContainer.get_children():
		child.queue_free()
