extends TextureRect

const note_texture_sheet: CompressedTexture2D = preload("res://engine/resources/textures/editors/note.webp")
var note_id: int = 0

func _ready() -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = note_texture_sheet
	@warning_ignore("integer_division")
	atlas_texture.region = Rect2(
		(int(note_id > 1) * (note_texture_sheet.get_height() / 2)),
		(note_id * (note_texture_sheet.get_width() / 2)) % note_texture_sheet.get_width(),
		note_texture_sheet.get_width() / 2,
		note_texture_sheet.get_height() / 2
	)
	texture = atlas_texture
