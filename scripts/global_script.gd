class_name GlobalScript extends Node

@onready var play_scene: Node2D = get_parent()
@onready var hud: CanvasLayer = play_scene.get_node("HUD")
@onready var camera: PlaySceneCamera = play_scene.get_node("PlaySceneCamera")

@onready var dad: Character = play_scene.get_node("Dad")
@onready var gf: Character = play_scene.get_node("Gf")
@onready var bf: Character = play_scene.get_node("Bf")

@onready var white_under_hud: ColorRect = hud.get_node("WhiteUnderHud")
@onready var white_over_hud: ColorRect = hud.get_node("WhiteOverHud")

@onready var black_under_hud: ColorRect = hud.get_node("BlackUnderHud")
@onready var black_over_hud: ColorRect = hud.get_node("BlackOverHud")

@onready var opponent_strum: Strum = hud.get_node("C/SubViewport/OpponentStrum")
@onready var player_strum: Strum = hud.get_node("C/SubViewport/PlayerStrum")

var bgrayscale_percent: float = 1.165
@onready var blue_grayscale: ColorRect = play_scene.get_node("BlueGrayscale/ColorRect")

func _physics_process(delta: float) -> void:
	blue_grayscale.material.set_shader_parameter("percentage", bgrayscale_percent)

func flash(time: float = 1.0, over_hud: bool = false):
	var white: ColorRect = white_over_hud if over_hud else white_under_hud
	white.modulate.a = 1.0
	
	get_tree().create_tween().tween_property(
		white,
		"modulate:a",
		0.0,
		time
	)

func fade_strum(which: String = "opponent", to: float = 1.0, time: float = 1.0):
	get_tree().create_tween().tween_property(
		opponent_strum if which == "opponent" else player_strum,
		"modulate:a",
		to,
		time
	)

func cam_to(position: Vector2):
	camera.target_position = position

func cam_to_char(character: String, zoom: bool = false):
	camera.go_to_character(character, zoom)

func cam_zoom(zoom: float):
	camera.target_zoom = Vector2(zoom, zoom)
