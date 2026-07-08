class_name Character extends OffsetAnimatedSprite2D

var _anim_lock: bool = false

## Only required for non-bf/dad characters!
@export_node_path("Conductor") var conductor_path
@onready var conductor: Conductor = get_node_or_null(conductor_path) if not conductor_path == null else null
var ignore_note_hits: bool = false

var character_resource: CharacterResource = CharacterResource.new()
var character_metadata: Dictionary = {}
var animations: Array = []

signal character_changed(new_character)

func _set_character(value: String) -> void:
	character = value
	character_changed.emit(value)
	
	character_resource.load("%s/%s.bin" % [ProjectData.CHARACTER_PATH, value])
	character_metadata = character_resource.get_metadata()
	animations = character_resource.get_animations()
	if not value in preloaded_textures:
		sprite_frames = XMLSpritesheet.load_xml_spritesheet(character_metadata.get("path"), character_metadata.get("format"))
	else:
		sprite_frames = XMLSpritesheet.load_xml_spritesheet_from_texture(character_metadata.get("path"), preloaded_textures[value])
	
	@warning_ignore("shadowed_variable_base_class")
	for animation: Dictionary in animations:
		if not animation.prefix == animation.animation:
			sprite_frames.rename_animation(animation.prefix, animation.animation)
		sprite_frames.set_animation_speed(animation.animation, animation.framerate)
		sprite_frames.set_animation_loop_mode(animation.animation, SpriteFrames.LOOP_LINEAR if animation.looped else SpriteFrames.LOOP_NONE)
		add_offset(animation.animation, animation.offset)
	
	if character_metadata.get("default_animation") in ["dance_left", "dance_right"]: is_dancer = true
	play(character_metadata.get("default_animation"))

@export var player: bool = false

var direction_animations: Array = Constants.directions
var character: String = 'bf' : set = _set_character
var is_dancer: bool = false

var preloaded_textures: Dictionary[String, CompressedTexture2D]

func load_texture_async(path: String):
	ResourceLoader.load_threaded_request(path)
	
	while true:
		var status = ResourceLoader.load_threaded_get_status(path)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			return ResourceLoader.load_threaded_get(path)
		
		await get_tree().process_frame

@warning_ignore("shadowed_variable")
func preload_character(character: String) -> void:
	var data: CharacterResource = CharacterResource.new()
	data.load("res://resources/characters/%s.bin" % character)
	var metadata: Dictionary = data.get_metadata()
	preloaded_textures[character] = await load_texture_async("%s.%s" % [metadata.get("path"), metadata.get("format")])

@warning_ignore("shadowed_variable")
func unload_character(character: String) -> void:
	preloaded_textures[character] = null

func unload_characters(characters: Array[String]) -> void:
	@warning_ignore("shadowed_variable")
	for character in characters:
		unload_character(character)

func preload_characters(characters: Array[String]) -> void:
	@warning_ignore("shadowed_variable")
	for character in characters:
		preload_character(character)

func _ready() -> void:
	if is_instance_valid(conductor):
		conductor.connect("beat_hit", beat_hit)
	
	connect("frame_changed", func():
		if sprite_frames.has_animation("idle") and sprite_frames.get_animation_loop("idle") and animation in ["left", "down", "up", "right", "left miss", "down miss", "up miss", "right miss"] and frame == sprite_frames.get_frame_count(animation) - 1:
			play("idle")
	)
	connect("animation_changed", func():
		if keeping and not animation_to_keep == animation:
			keeping = false
	)

func get_animation_duration(anim_name: String) -> float:
	if not sprite_frames or not sprite_frames.has_animation(anim_name):
		return 0.0
	
	var frames: int = sprite_frames.get_frame_count(anim_name)
	var fps: float = sprite_frames.get_animation_speed(anim_name)
	
	if fps <= 0:
		return 0.0
	
	return frames / fps

func beat_hit(beat: int):
	if not sprite_frames == null:
		if not animation == "stare" and animation in ["idle", "dance_left", "dance_right", "left", "down", "up", "right", "left miss", "down miss", "up miss", "right miss"]:
			if (sprite_frames.has_animation('dance_left') or (beat % 2 == 0 and sprite_frames.has_animation("idle"))) and not _anim_lock:
				var anim_to_play: String
				if is_dancer: anim_to_play = "dance_left" if not animation == "dance_left" else "dance_right"
				else: anim_to_play = "idle"
				if not sprite_frames.get_animation_loop(anim_to_play) and frame == sprite_frames.get_frame_count(animation) - 1:
					play(anim_to_play)

var keeping: bool = false
var animation_to_keep: String = ""
var animation_sustain_thing: bool = true
var lock_duration: float = 0.1

func keep(anim: String):
	keeping = true
	animation_to_keep = anim
	
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if keeping:
		if not animation == animation_to_keep or (animation == animation_to_keep and frame == sprite_frames.get_frame_count(animation_to_keep)):
			play(animation_to_keep)
	
	if len(times_pressed) > 5:
		times_pressed.pop_back()

var times_pressed: Array[float] = []

@warning_ignore("unused_parameter")
func note_hit(note_id: int, note_length: float, note_time: float, current_time: float, start_hold: bool) -> void:
	if ignore_note_hits: return
	
	if not times_pressed.has(note_time):
		frame = 0
		times_pressed.append(note_time)
	
	if animation_sustain_thing and (not note_length <= 0) and animation == direction_animations[note_id]:
		var ms_current_time: float = current_time * 1000.0
		var hold_left: float = (note_length) - (ms_current_time - note_time)
		var anim_dur: float = get_animation_duration(animation) * 100.0
		
		if hold_left <= anim_dur: return
	
	animation = direction_animations[note_id]
	frame = 0
	play(direction_animations[note_id])
	_anim_lock = true
	await get_tree().create_timer(lock_duration).timeout
	_anim_lock = false
