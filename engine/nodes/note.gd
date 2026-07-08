extends Note

var note_id: int = 0
var note_length: float = 0.0
var must_hit_section: bool = false
var pressed_time: float = 0.0
var hold_bias: float = 0.0
var target_time: float = 0.0
var current_time: float = 0.0
var strum_y: float = 0.0
var scroll_speed: float = 0.0

var hit_time: float

var parent_strum: Strum

var direction: String
var arrow_node: Node2D
var long_note: Node2D
var long_end: Node2D

var invert_mask: bool = false

var position_offset: Vector2 = Vector2(0.0, 0.0)
var scale_offset: Vector2 = Vector2(0.0, 0.0)

func _enter_tree() -> void:
	visible = false
	
	if not invert_mask:
		$LongNote.material = null
		$LongNote/End.material = null
	
	if is_instance_valid(parent_strum):
		direction = Constants.directions[note_id]
		arrow_node = parent_strum.get_node("canvas_group/%s" % direction)
		play(parent_strum.get("%s_note_prefix" % direction))
		global_position.x = arrow_node.get_global_position().x
		global_scale = arrow_node.global_scale
		
		if note_length > 0:
			long_note = $LongNote
			long_end = long_note.get_node("End")
			long_note.texture = parent_strum.get("%s_hold_tex" % direction)
			long_end.play(parent_strum.get("%s_holdend_prefix" % direction))
			long_note.visible = true
			long_end.flip_v = parent_strum.downscroll
		else: 
			$LongNote.queue_free()
			long_note = null
			long_end = null
		
		scroll_speed = parent_strum.scroll_speed * 0.5
		strum_y = arrow_node.get_global_position().y
		current_time = parent_strum.current_time
	
		parent_strum.connect("modifier_hit", func(type: String, intensity: float):
			match type:
				"scale": scale += Vector2(intensity, intensity)
				"scalex": scale.x += intensity
				"scaley": scale.y += intensity
				"rotate": rotation_degrees += intensity
				"skew": skew += intensity
		)

func _physics_process(delta: float) -> void:
	current_time = parent_strum.current_time
	var time_ms = parent_strum.current_time * 1000.0
	var half_scroll = parent_strum.scroll_speed * 0.5
	strum_y = arrow_node.global_position.y 
	var downscroll: bool = parent_strum.downscroll
	var scroll_dir: float = -1.0 if downscroll else 1.0
	
	scale_offset *= 0.9
	position_offset *= 0.9
	
	if CoolUtil.should_note_be_visible(time_ms, target_time, half_scroll, strum_y, 720.0):
		position.y = strum_y + ((1 - (time_ms - target_time)) * half_scroll * scroll_dir)
		
		global_position.x = arrow_node.get_global_position().x
		global_position += position_offset
		global_scale = arrow_node.global_scale + scale_offset
		
		#GENERAL MODCHARTS
		for modchart in parent_strum.modcharts:
			match modchart:
				"blind":
					if (target_time - (time_ms - note_length)) < 300.0:
						modulate.a = lerp(modulate.a, 0.0, 0.07)
				"shakepress":
					if (target_time - (time_ms - note_length)) < 300.0:
						var closeness: float = (target_time - (time_ms - note_length)) / 300.0
						position.x += randf_range(-closeness * 5.0, closeness * 5.0)
						#half_scroll = (parent_strum.scroll_speed * 0.5) * (closeness * 5.0)

		if time_ms >= (target_time - 250):
			if not target_time in parent_strum.note_times[note_id]:
				parent_strum.note_times[note_id].append(target_time)
			
			if (len(parent_strum.note_times[note_id]) > 0 and target_time == parent_strum.note_times[note_id][0]) and parent_strum._check_note_hit(note_id, target_time, note_length, must_hit_section):
				pressed_time += delta * 1000.0
				
				if hit_time == null:
					hit_time = time_ms
				
				self_modulate.a = 0
				position.y = strum_y
				if long_note:
					var length = ((target_time + note_length) - time_ms) * half_scroll * scroll_dir
					var note_points = [
						Vector2(0, 0),
					]
					
					#HOLD NOTE MODCHARTS
					for modchart in parent_strum.modcharts:
						match modchart:
							"shakepress":
								var fall_off: float = 0.0
								var stop_falling_off: bool = false
								for i in range(int(length / 50.0)):
									note_points.append(Vector2(sin((parent_strum.current_time) + (i * 3.0)) * (30.0 - fall_off), i * 50.0 if i * 50.0 < length else length))
									if not stop_falling_off: fall_off += 6.0
									if fall_off >= 30.0:
										fall_off = 30.0
										stop_falling_off = true
					
					note_points.append(Vector2(0, length))
					long_note.points = PackedVector2Array(note_points)
					note_points = null
				if time_ms >= (target_time + note_length):
					var idx = parent_strum.note_times[note_id].find(target_time)
					if idx != -1:
						parent_strum.note_times[note_id].remove_at(idx)
					parent_strum.note_hitting[note_id] = false
					queue_free()
					return
		elif time_ms >= (target_time - 4000.0): visible = true
		else:
			if long_note:
				var note_points = PackedVector2Array([
					Vector2(0, 0),
					Vector2(0,  note_length * half_scroll * scroll_dir)
				])
				long_note.points = note_points
				note_points = null
		
		var missed_offscreen: bool = (not downscroll and position.y < -200) or (downscroll and position.y > 920)
		if time_ms >= ((target_time + note_length * 2) + 100) and missed_offscreen:
			var idx = parent_strum.note_times[note_id].find(target_time)
			if idx != -1:
				parent_strum.note_times[note_id].remove_at(idx)
			if self_modulate.a > 0:
				if hit_time != null and not (long_note and (pressed_time >= hold_bias * note_length or (note_length - pressed_time < 100))):
					if is_instance_valid(parent_strum) and "misses" in parent_strum:
						parent_strum.misses += 1
						parent_strum.note_miss.emit(note_id, must_hit_section)
			queue_free()
		if long_note: long_end.position.y = long_note.points[1].y + (32 * scroll_dir)
