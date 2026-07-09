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

func beat1(beat):
	if beat % 2 == 0 and not beat % 8 == 6:
		tree.create_tween().tween_property(global_script, "bgrayscale_percent", 0.0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.opponent_strum, "scroll_speed", 3.7, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.player_strum, "scroll_speed", 3.7, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		global_script.camera.target_zoom = Vector2(0.9, 0.9)
		global_script.camera.zoom += Vector2(0.02, 0.02)
	elif beat % 8 == 6:
		tree.create_tween().tween_property(global_script, "bgrayscale_percent", 1.165, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.opponent_strum, "scroll_speed", 2.5, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.player_strum, "scroll_speed", 2.5, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		global_script.camera.target_zoom = Vector2(1.0, 1.0)

func beat2(beat):
	if beat % 2 == 0:
		global_script.camera.zoom += Vector2(0.02, 0.02)

func beat3(beat):
	global_script.camera.zoom += Vector2(0.03, 0.03)
	global_script.bgrayscale_percent = 0.32
	tree.create_tween().tween_property(global_script, "bgrayscale_percent", 0.0, 0.15)

	if beat % 2 == 0:
		for i in range(4):
			global_script.opponent_strum._arrow_nodes[i].position.y = 20.0 if i % 2 == 0 else 0.0
			global_script.player_strum._arrow_nodes[i].position.y = 20.0 if i % 2 == 0 else 0.0
	else:
		for i in range(4):
			global_script.opponent_strum._arrow_nodes[i].position.y = 0.0 if i % 2 == 0 else 20.0
			global_script.player_strum._arrow_nodes[i].position.y = 0.0 if i % 2 == 0 else 20.0

func _init() -> void:
	play_scene = get_parent()
	global_script = play_scene.get_node("GlobalScript")
	stage_container = play_scene.get_node("StageContainer")
	
	stage_container.stage = "supernatural"
	stage = stage_container.stage_node
	
	dad = play_scene.get_node("Dad")
	gf = play_scene.get_node('Gf')
	bf = play_scene.get_node('Bf')
	
	dad.character = "spectre"
	bf.character = "bf"
	gf.queue_free()
	
	global_script.camera.target_position = Vector2(640, 360)
	global_script.camera.opponent_camera_position.x += 300
	global_script.camera.player_camera_position.x += 300
	global_script.camera.zoom_on_note_hit = false
	global_script.camera.opponent_camera_position.y -= 30
	global_script.camera.player_camera_position.y = global_script.camera.opponent_camera_position.y
	global_script.camera.offset_on_note_hit = false
	
	#global_script.opponent_strum.hold_note_invert_mask = true
	#global_script.player_strum.hold_note_invert_mask = true
	
	stage._reposition_characters(dad.get_path(), null, bf.get_path())
	
	global_script.black_over_hud.modulate.a = 1.0
	global_script.opponent_strum.modulate.a = 0.0
	global_script.player_strum.modulate.a = 0.0
	
	global_script.camera.target_zoom = Vector2(2.0, 2.0)
	
	tree = get_tree()

	add_event(0.0, func():
		tree.create_tween().tween_property(global_script.camera, "target_zoom", Vector2(1.2, 1.2), 3.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tree.create_tween().tween_property(global_script.black_over_hud, "modulate:a", 0.2, 4.0)
	)

	add_event(3.52, func():
		tree.create_tween().tween_property(global_script.opponent_strum, "modulate:a", 1.0, 1.0)
	)
	
	add_event(8.47, func():
		tree.create_tween().tween_property(global_script.player_strum, "modulate:a", 1.0, 1.0)
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
	
	var centered_strum_pos: float = 640 - (476 / 2.0)
	
	#add_event(32.47, func():
		#tree.create_tween().tween_property(global_script.opponent_strum, "position:x", centered_strum_pos, 0.3).set_trans(Tween.TRANS_QUAD)
		#tree.create_tween().tween_property(global_script.player_strum, "position:x", centered_strum_pos, 0.3).set_trans(Tween.TRANS_QUAD)
	#)
		
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
		#tree.create_tween().tween_property(global_script, "bgrayscale_percent", 0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		global_script.camera.target_zoom = Vector2(0.9, 0.9)
		global_script.play_scene.get_node("Conductor").connect("beat_hit", beat3)
	)
