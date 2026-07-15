extends EventNode

var dad: Character
var gf: Character
var bf: Character

var stage_container: StageContainer
var stage: Stage
var play_scene: Node2D

var black_bars: BlackBars
var global_script: GlobalScript

var tree: SceneTree

var note_eff: int = 0
var arrow_spread: float = 1.0
var arrow_scale: Vector2 = Vector2(0.75, 0.75)
var arrow_rotation: float = 0.0

func beat1(beat):
	if beat % 2 == 0 and not beat % 8 == 6:
		tree.create_tween().tween_property(global_script, "bgrayscale_percent", 0.0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.opponent_strum, "scroll_speed", 3.7, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.player_strum, "scroll_speed", 3.7, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		global_script.camera.target_zoom = Vector2(0.9, 0.9)
		global_script.camera.zoom += Vector2(0.02, 0.02)
		
		arrow_scale = Vector2(0.8, 0.8)
		tree.create_tween().tween_property(self, "arrow_scale", Vector2(0.75, 0.75), 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	elif beat % 8 == 6:
		tree.create_tween().tween_property(global_script, "bgrayscale_percent", 1.165, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.opponent_strum, "scroll_speed", 2.5, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.player_strum, "scroll_speed", 2.5, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		global_script.camera.target_zoom = Vector2(1.0, 1.0)
		tree.create_tween().tween_property(self, "arrow_scale", Vector2(0.7, 0.7), 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func beat2(beat):
	if beat % 2 == 0:
		global_script.camera.zoom += Vector2(0.02, 0.02)
		arrow_scale = Vector2(0.8, 0.8)
		tree.create_tween().tween_property(self, "arrow_scale", Vector2(0.75, 0.75), 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		arrow_spread = 1.067
		tree.create_tween().tween_property(self, "arrow_spread", 1.0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func beat3(beat):
	global_script.camera.zoom += Vector2(0.03, 0.03)
	global_script.camera.rotation_degrees = 2 if beat % 2 == 0 else -2
	global_script.bgrayscale_percent = 0.32
	tree.create_tween().tween_property(global_script, "bgrayscale_percent", 0.0, 0.15)

	arrow_scale = Vector2(0.8, 0.8)
	tree.create_tween().tween_property(self, "arrow_scale", Vector2(0.75, 0.75), 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	arrow_rotation = 20 if beat % 2 == 0 else -20
	tree.create_tween().tween_property(self, "arrow_rotation", 0, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	if beat % 16 >= 8:
		global_script.camera.target_zoom = Vector2(1.1, 1.1)
	else:
		global_script.camera.target_zoom = Vector2(0.9, 0.9)

func beat4(beat):
	time_multiplier = 1.0
	time_multiplier += 0.2
	
	if beat % 8 in [0, 3, 5, 6, 7]:
		if not beat % 8 == 6:
			global_script.camera.zoom += Vector2(0.05, 0.05)
			
		arrow_scale = Vector2(0.69, 0.69)
		tree.create_tween().tween_property(self, "arrow_scale", Vector2(0.75, 0.75), 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if beat % 8 in [2, 6]:
		global_script.camera.zoom -= Vector2(0.02, 0.02)
		if beat % 8 == 2:
			arrow_rotation = 10.0
		else:
			arrow_rotation = -10.0
		tree.create_tween().tween_property(self, "arrow_rotation", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		arrow_spread = 1.2
		tree.create_tween().tween_property(self, "arrow_spread", 1.0, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

var add_time: float = 0.0
var time_multiplier: float = 0.0

func _physics_process(delta: float) -> void:
	for i in range(4):
		global_script.opponent_strum._arrow_nodes[i].position.x = global_script.opponent_strum.original_arrow_positions[i] * arrow_spread
		global_script.opponent_strum._arrow_nodes[i].scale = arrow_scale
		global_script.opponent_strum._arrow_nodes[i].rotation_degrees = arrow_rotation
		global_script.player_strum._arrow_nodes[i].position.x = global_script.player_strum.original_arrow_positions[i] * arrow_spread
		global_script.player_strum._arrow_nodes[i].scale = arrow_scale
		global_script.player_strum._arrow_nodes[i].rotation_degrees = arrow_rotation
	
	match note_eff:
		1:
			for i in range(4):
				global_script.opponent_strum._arrow_nodes[i].position.y = sin(global_script.play_scene.get_node("Conductor").get_time() + (i * 2.0)) * 13.0
				global_script.player_strum._arrow_nodes[i].position.y = cos(global_script.play_scene.get_node("Conductor").get_time() + (i * 2.0)) * 13.0
				global_script.opponent_strum._arrow_nodes[i].position += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
				global_script.player_strum._arrow_nodes[i].position += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))

func _reset_note_pos():
	for i in range(4):
		global_script.opponent_strum._arrow_nodes[i].position = Vector2(global_script.opponent_strum.original_arrow_positions[i], 0.0)
		global_script.player_strum._arrow_nodes[i].position = Vector2(global_script.player_strum.original_arrow_positions[i], 0.0)

func _init() -> void:
	play_scene = get_parent()
	global_script = play_scene.get_node("GlobalScript")
	stage_container = play_scene.get_node("StageContainer")
	
	stage_container.stage = "supernatural"
	stage = stage_container.stage_node
	
	dad = play_scene.get_node("Dad")
	gf = play_scene.get_node('Gf')
	bf = play_scene.get_node('Bf')
	
	dad.character = "moose"
	dad.kool = true
	bf.character = "bf"
	gf.queue_free()
	
	global_script.camera.target_position = Vector2(640, 360)
	global_script.camera.opponent_camera_position.x += 300
	global_script.camera.player_camera_position.x += 300
	global_script.camera.zoom_on_note_hit = false
	global_script.camera.opponent_camera_position.y -= 30
	global_script.camera.player_camera_position.y = global_script.camera.opponent_camera_position.y
	global_script.camera.offset_on_note_hit = false
	
	global_script.hud.get_node("C").material = null
	
	stage._reposition_characters(dad.get_path(), null, bf.get_path())
	
	global_script.black_over_hud.modulate.a = 1.0
	global_script.opponent_strum.modulate.a = 0.0
	global_script.player_strum.modulate.a = 0.0
	
	global_script.camera.target_zoom = Vector2(2.0, 2.0)
	
	set_physics_process(true)
	
	tree = get_tree()

	add_event(0.0, func():
		tree.create_tween().tween_property(global_script.camera, "target_zoom", Vector2(1.2, 1.2), 3.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.black_over_hud, "modulate:a", 0.2, 4.0)
	)

	add_event(3.52, func():
		tree.create_tween().tween_property(global_script.opponent_strum, "modulate:a", 1.0, 1.0)
		tree.create_tween().tween_property(global_script.opponent_strum, "scale", Vector2(1.0, 1.0), 1.0).from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_EXPO)
	)
	
	add_event(8.47, func():
		tree.create_tween().tween_property(global_script.player_strum, "modulate:a", 1.0, 1.0)
		tree.create_tween().tween_property(global_script.player_strum, "scale", Vector2(1.0, 1.0), 1.0).from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_EXPO)
	)
	
	add_event(19.76, func():
		tree.create_tween().tween_property(global_script.camera, "target_zoom", Vector2(1.4, 1.4), 2.0).set_trans(Tween.TRANS_EXPO)
	)

	add_event(22.23, func():
		tree.create_tween().tween_property(global_script.camera, "target_zoom", Vector2(0.9, 0.9), 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tree.create_tween().tween_property(global_script, "bgrayscale_percent", 0.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	)
	
	add_event(22.58, func():
		global_script.black_over_hud.modulate.a = 0.0
		global_script.white_under_hud.modulate.a = 1.0
		tree.create_tween().tween_property(global_script.white_under_hud, "modulate:a", 0.0, 1.0)
		
		@warning_ignore("unused_parameter")
		global_script.play_scene.get_node("Conductor").connect("beat_hit", beat1)
	)
	
	add_event(33.88, func():
		global_script.player_strum.downscroll = true
		tree.create_tween().tween_property(global_script.player_strum, "position:y", 720 - 119 - 40.0, 0.3).set_trans(Tween.TRANS_QUAD)
		
		global_script.play_scene.get_node("Conductor").disconnect("beat_hit", beat1)
		global_script.play_scene.get_node("Conductor").connect("beat_hit", beat2)
		
		tree.create_tween().tween_property(global_script, "bgrayscale_percent", 0.0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.opponent_strum, "scroll_speed", 3.7, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.player_strum, "scroll_speed", 3.5, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		global_script.camera.target_zoom = Vector2(0.9, 0.9)
	)
	
	add_event(44.47, func():
		global_script.player_strum.downscroll = false
		tree.create_tween().tween_property(global_script.player_strum, "position:y", 40.0, 0.3).set_trans(Tween.TRANS_QUAD)
		 
		
		global_script.play_scene.get_node("Conductor").disconnect("beat_hit", beat2)
		tree.create_tween().tween_property(global_script, "bgrayscale_percent", 1.165, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		#tree.create_tween().tween_property(global_script.opponent_strum, "scroll_speed", 2.5, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		#tree.create_tween().tween_property(global_script.p layer_strum, "scroll_speed", 2.5, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		global_script.camera.target_zoom = Vector2(1.0, 1.0)
	)
	
	add_event(44.82, func():
		tree.create_tween().tween_property(global_script, "bgrayscale_percent", 0.0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	)
	
	add_event(45.17, func():
		global_script.camera.target_zoom = Vector2(0.9, 0.9)
		note_eff = 1
		global_script.play_scene.get_node("Conductor").connect("beat_hit", beat3)
	)
	
	add_event(67.41, func():
		note_eff = 0
		_reset_note_pos()
		tree.create_tween().tween_property(self, "arrow_spread", 1.1, 0.76-0.41).set_trans(Tween.TRANS_EXPO)
		tree.create_tween().tween_property(global_script.opponent_strum, "position:y", 95, 0.76-0.41).set_trans(Tween.TRANS_EXPO)
		tree.create_tween().tween_property(global_script.player_strum, "position:y", 95, 0.76-0.41).set_trans(Tween.TRANS_EXPO)
		global_script.hud.get_node("BlackBars").tween_to(75.0, 0.76-0.41, Tween.TRANS_EXPO)
	)
	
	add_event(67.76, func():
		note_eff = 3
		global_script.white_under_hud.modulate.a = 1.0
		tree.create_tween().tween_property(global_script.white_under_hud, "modulate:a", 0.0, 1.0)
		global_script.cam_zoom(1.2)
		
		global_script.play_scene.get_node("Conductor").disconnect("beat_hit", beat3)
		global_script.play_scene.get_node("Conductor").connect("beat_hit", beat4)
	)
