class_name Strum extends Control

func set_sheet_path(value: String) -> void:
	sheet_path = value
	_sheet_frames = XMLSpritesheet.load_xml_spritesheet(sheet_path, format)
	for dir in Constants.directions:
		var strum_arrow: AnimatedSprite2D = get_node("canvas_group/%s" % dir)
		strum_arrow.sprite_frames = _sheet_frames.duplicate(true)
		strum_arrow.sprite_frames.remove_animation('default')
		if strum_arrow.sprite_frames.has_animation(get('static_%s_prefix' % dir)):
			strum_arrow.sprite_frames.rename_animation(get('static_%s_prefix' % dir), 'default')
		if strum_arrow.sprite_frames.has_animation(get('press_%s_prefix' % dir)):
			strum_arrow.sprite_frames.rename_animation(get('press_%s_prefix' % dir), 'press')
		if strum_arrow.sprite_frames.has_animation(get('confirm_%s_prefix' % dir)):
			strum_arrow.sprite_frames.rename_animation(get('confirm_%s_prefix' % dir), 'hit')
		for anim in ['press', 'hit']:
			if strum_arrow.sprite_frames.has_animation(anim):
				strum_arrow.sprite_frames.set_animation_speed(anim, framerate)
				strum_arrow.sprite_frames.set_animation_loop_mode(anim, SpriteFrames.LOOP_NONE)

var _sheet_frames: SpriteFrames = SpriteFrames.new()

## Wether this is a opponent/botplay strum.[br]
## (For example, on a player strum, this would be off)
@export var is_cpu_strum: bool = false
## Self explanatory.[br]
## (Warning! This does not change the position of the strum! Just the trajectory of the notes!)
@export var downscroll: bool = false

## Makes hold notes invert whats beneat them.[br]
## ...Not much context needed here.
@export var hold_note_invert_mask: bool = false

@export_category("Plug-ins")

@export_node_path("OffsetAnimatedSprite2D") var character: NodePath
@export_node_path("Node2D") var rating_container: NodePath

@onready var character_node: Character = get_node(character) as Character if has_node(character) else null

@export_category("Animation")

@export var sheet_path: String = 'res://engine/resources/textures/NOTE_assets' : set = set_sheet_path
@export var format: String = 'webp'
@export var framerate: int = 24

@export_category("Animation Prefixes")

@export var static_left_prefix: String = 'arrow static instance 1'
@export var static_down_prefix: String = 'arrow static instance 2'
@export var static_up_prefix: String = 'arrow static instance 4'
@export var static_right_prefix: String = 'arrow static instance 3'

@export var press_left_prefix: String = 'left press instance 1'
@export var press_down_prefix: String = 'down press instance 1'
@export var press_up_prefix: String = 'up press instance 1'
@export var press_right_prefix: String = 'right press instance 1'

@export var confirm_left_prefix: String = 'left confirm instance 1'
@export var confirm_down_prefix: String = 'down confirm instance 1'
@export var confirm_up_prefix: String = 'up confirm instance 1'
@export var confirm_right_prefix: String = 'right confirm instance 1'

@export var left_note_prefix: String = 'purple instance 1'
@export var down_note_prefix: String = 'blue instance 1'
@export var up_note_prefix: String = 'green instance 1'
@export var right_note_prefix: String = 'red instance 1'

@export_category("Hold Textures")

# NOTE: make this more soft-codeable idk
@export var left_hold_tex: Texture = preload("res://engine/resources/textures/longpur.png")
@export var down_hold_tex: Texture = preload("res://engine/resources/textures/longblu.png")
@export var up_hold_tex: Texture = preload("res://engine/resources/textures/longgre.png")
@export var right_hold_tex: Texture = preload("res://engine/resources/textures/longred.png")

@export var left_holdend_prefix: String = "pruple end hold instance 1"
@export var down_holdend_prefix: String = "blue hold end instance 1"
@export var up_holdend_prefix: String = "green hold end instance 1"
@export var right_holdend_prefix: String = "red hold end instance 1"

var _notes_shaking: bool = false;
var shake_intensity: float = 4
var original_arrow_positions: Array = [-181.88, -61.88, 58.12, 178.12]

enum AnimState { DEFAULT = 0, PRESS = 1, HIT = 2 }
var arrow_anim_states: Array[int] = [0, 0, 0, 0]

const note_scene = preload("res://engine/nodes/note.tscn")

var note_hitting: Array[bool] = [false, false, false, false]
var note_times: Array[Array] = [[], [], [], []]
var input_times: Array[Array] = [[], [], [], []]
var input_note_map: Dictionary[float, float] = {}
var scroll_speed: float = 1.0

var conductor_node: Conductor:
	set(value):
		conductor_node = value
		input_tracker.conductor = value

var current_time: float = 0.0

var misses: int = 0

@onready var _arrow_nodes: Array = []

@onready var input_tracker: InputTracker = $InputTracker

var _rating_container: Node
var modcharts: Array = []

signal note_hit(note_id, rating, must_hit_section, note_length)
signal advanced_note_hit(note_id, note_length, note_time, current_time, start_hold)
signal note_miss(note_id, must_hit_section)

signal modifier_hit(type: String, intensity: float)

func emit_modifier(type: String, intensity: float) -> void:
	modifier_hit.emit(type, intensity)

func add_modchart(modchart) -> void:
	if not modchart in modcharts:
		modcharts.append(modchart)

func remove_modchart(modchart) -> void:
	if modchart in modcharts:
		modcharts.erase(modchart)

func _spawn_note(note_id: int, target_time: float = 0.0, note_length: float = 0.0, must_hit_section: bool = false):
	var note_instance = note_scene.instantiate()
	note_instance.note_id = note_id
	note_instance.target_time = target_time
	note_instance.invert_mask = hold_note_invert_mask
	note_instance.parent_strum = self
	note_instance.sprite_frames = _sheet_frames
	note_instance.get_node("LongNote/End").sprite_frames = _sheet_frames
	note_instance.note_length = note_length
	note_instance.must_hit_section = must_hit_section
	get_parent().add_child(note_instance)

func average(numbers: Array) -> float:
	var sum := 0.0
	for n in numbers:
		sum += n
	return sum / numbers.size()

func _check_note_hit(note_id: int, target_time: float, note_length: float = 0.0, must_hit_section: bool = false) -> bool:
	var result := input_tracker.check_note_hit(
		current_time * 1000.0,
		target_time,
		note_length,
		note_id,
		is_cpu_strum
	)

	if result.hit:
		if not input_note_map.has(current_time * 1000.0) and (is_cpu_strum or input_tracker.get_pressed(note_id)):
			input_times[note_id].append(current_time * 1000.0)
			input_note_map[current_time * 1000.0] = target_time
		else:
			if not target_time in input_note_map.values():
				return false
		if result.start_hold:
			note_hitting[note_id] = true
		_note_hit(note_id, note_length / 1000.0)
		note_hit.emit(note_id, result.rating, must_hit_section, note_length)
		advanced_note_hit.emit(note_id, note_length, target_time, current_time, result.start_hold)
		return true

	return false

func _note_hit(note_id: int, note_length: float = 0.0):
	_arrow_nodes[note_id].play('hit')
	arrow_anim_states[note_id] = AnimState.HIT
	if is_cpu_strum:
		await get_tree().create_timer(0.2 + note_length).timeout
		_arrow_nodes[note_id].play('default')
		arrow_anim_states[note_id] = AnimState.DEFAULT

var internal_lerp: bool = true

func _ready() -> void:
	input_tracker.set_left_primary(KEY_D)
	input_tracker.set_down_primary(KEY_F)
	input_tracker.set_up_primary(KEY_J)
	input_tracker.set_right_primary(KEY_K)
	
	input_tracker.is_cpu_strum = is_cpu_strum
	
	for dir in Constants.directions:
		_arrow_nodes.append(get_node("canvas_group/%s" % dir))
	
	set_sheet_path(sheet_path)
	
	if has_node(character):
		connect("advanced_note_hit", Callable(character_node, "note_hit"))
		if rating_container and not is_cpu_strum:
			_rating_container = get_node(rating_container)
			connect("note_miss", func(note_id, _must_hit_section):
				if is_instance_valid(_rating_container):
					_rating_container.notes_played -= 1
				if is_instance_valid(character_node) and character_node.sprite_frames.has_animation("%s miss" % Constants.directions[note_id]):
					character_node.play("%s miss" % Constants.directions[note_id])
			)
			connect("note_hit", Callable(_rating_container, "note_hit"))

	connect("modifier_hit", func(type: String, intensity: float):
		match type:
			"strumscale":
				for arrow_node: AnimatedSprite2D in _arrow_nodes:
					arrow_node.scale += Vector2(intensity, intensity)
			"strumscalex":
				for arrow_node: AnimatedSprite2D in _arrow_nodes:
					arrow_node.scale.x += intensity
			"strumscaley":
				for arrow_node: AnimatedSprite2D in _arrow_nodes:
					arrow_node.scale.y += intensity
			"strumrotate":
				for arrow_node: AnimatedSprite2D in _arrow_nodes:
					arrow_node.rotation_degrees += intensity
			"strumskew":
				for arrow_node: AnimatedSprite2D in _arrow_nodes:
					arrow_node.skew += intensity
	)

func _physics_process(_delta: float) -> void:
	if not (is_instance_valid(conductor_node) and conductor_node.active):
		return

	if internal_lerp:
		for arrow_node: AnimatedSprite2D in _arrow_nodes:
			arrow_node.rotation_degrees = lerp_angle(arrow_node.rotation_degrees, 0.0, 0.1)
			arrow_node.scale = lerp(arrow_node.scale, Vector2(0.75, 0.75), 0.1)
			arrow_node.skew = lerp(arrow_node.skew, 0.0, 0.1)

	current_time = conductor_node.get_time()

	if not is_cpu_strum and is_instance_valid(input_tracker):
		for i in range(4):
			var arrow = _arrow_nodes[i]
			var current = arrow_anim_states[i]
			var pressed = input_tracker.get_pressed(i)
			
			if current == AnimState.HIT:
				if not pressed:
					arrow.animation = 'default'
					arrow_anim_states[i] = AnimState.DEFAULT
			else:
				if pressed:
					if current != AnimState.PRESS:
						arrow.play("press")
						arrow_anim_states[i] = AnimState.PRESS
				else:
					if current != AnimState.DEFAULT:
						arrow.animation = 'default'
						arrow_anim_states[i] = AnimState.DEFAULT

	if _notes_shaking:
		shake_notes()

func set_notes_shaking(shaking):
	_notes_shaking = shaking
	if not shaking:
		shake_timer = 0.0
		for i in range(4):
			_arrow_nodes[i].position = Vector2(original_arrow_positions[i], 0)

var shake_offset: Vector2
var shake_timer: float = 0.0

func shake_notes():
	shake_timer -= get_physics_process_delta_time()
	
	if shake_timer <= 0:
		for i in range(4):
			shake_timer = 0.016
			shake_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
			_arrow_nodes[i].position = Vector2(original_arrow_positions[i], 0) + shake_offset
