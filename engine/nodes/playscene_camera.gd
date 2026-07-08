class_name PlaySceneCamera extends Camera2D

var offset_on_note_press: bool = false
var camera_offset: Array = [
	Vector2(-20, 0),
	Vector2(0, 20),
	Vector2(0, -20),
	Vector2(20, 0)
]

@export var opponent_camera_position: Vector2 = Vector2(300, 360)
@export var player_camera_position: Vector2 = Vector2(400, 360)

@export var opponent_camera_zoom: Vector2 = Vector2(1.0, 1.0)
@export var player_camera_zoom: Vector2 = Vector2(1.0, 1.0)

var opponent_character: Character
var player_character: Character

var internal_offset: Vector2 = Vector2.ZERO

@export var target_offset: Vector2 = Vector2.ZERO
@export var target_position: Vector2 = Vector2.ZERO
@export var target_zoom: Vector2 = Vector2.ONE
@export var target_angle: float = 0.0

var offset_on_note_hit: bool = true
var zoom_on_note_hit: bool = true
var follow_section: bool = true

var speed: float = 4.4
func get_interpolation_factor(delta: float) -> float:
	return abs(1.0 - exp(-(speed * 10.0) * delta))

var center_position = Vector2(640, 630)

func change_center(to: Vector2) -> void:
	center_position = to

func auto_adjust_dad_camera_positions(dad: Character):
	opponent_camera_position = dad.position - Vector2(640, 360)

func auto_adjust_bf_camera_positions(bf: Character):
	player_camera_position = bf.position - Vector2(640, 360)

func auto_adjust_character_camera_positions(dad: Character, bf: Character):
	auto_adjust_dad_camera_positions(dad)
	auto_adjust_bf_camera_positions(bf)

func go_to_character(character: String, _zoom: bool = false, _instant: bool = false):
	target_position = get("%s_camera_position" % [character])
	if _instant:
		position = target_position
	if _zoom:
		target_zoom = get("%s_camera_zoom" % [character])
		if _instant:
			zoom = target_zoom

func _note_hit(note_id: int, must_hit_section: bool, is_player: bool) -> void:
	var condition: bool = must_hit_section if is_player else not must_hit_section
	var character: String = ["opponent", "player"][int(is_player)]
	if condition:
		if follow_section:
			target_position = get("%s_camera_position" % [character])
		if zoom_on_note_hit:
			target_zoom = get("%s_camera_zoom" % [character])
		internal_offset = camera_offset[note_id]

func player_note_hit(note_id: int, _rating: String, must_hit_section: bool, _note_length: float) -> void:
	_note_hit(note_id, must_hit_section, true)

func opponent_note_hit(note_id: int, _rating: String, must_hit_section: bool, _note_length: float) -> void:
	_note_hit(note_id, must_hit_section, false)

func _physics_process(delta: float) -> void:
	if is_instance_valid(opponent_character) and is_instance_valid(player_character):
		if opponent_character.animation == "idle" and player_character.animation == "idle":
				internal_offset = Vector2.ZERO
	
	var _target_position: Vector2 = target_position + target_offset + (internal_offset if offset_on_note_hit else Vector2(0.0, 0.0))
	
	position.x = CoolUtil.circ_lerp(position.x, _target_position.x, get_interpolation_factor(delta))
	position.y = CoolUtil.circ_lerp(position.y, _target_position.y, get_interpolation_factor(delta))

	zoom.x = CoolUtil.circ_lerp(zoom.x, target_zoom.x, get_interpolation_factor(delta))
	zoom.y = CoolUtil.circ_lerp(zoom.y, target_zoom.y, get_interpolation_factor(delta))

	rotation_degrees = CoolUtil.circ_lerp(rotation_degrees, target_angle, get_interpolation_factor(delta))

func center_camera():
	target_position = center_position
