extends Node2D

func load_xml_spritesheet_from_texture(path: String, texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var xml_file := FileAccess.open('%s.xml' % path, FileAccess.READ)
	if not xml_file:
		push_error("Failed to open XML: %s.xml" % path)
		return frames

	var xml := XMLParser.new()
	xml.open('%s.xml' % path)
	
	

	var entries := []
	var anim_max_size := {}

	while xml.read() == OK:
		if xml.get_node_type() == XMLParser.NODE_ELEMENT and xml.get_node_name() == "SubTexture":
			var x := int(xml.get_named_attribute_value("x"))
			var y := int(xml.get_named_attribute_value("y"))
			var w := int(xml.get_named_attribute_value("width"))
			var h := int(xml.get_named_attribute_value("height"))
			var offsetx := 0
			var offsety := 0
			var frame_w := w
			var frame_h := h
			if xml.has_attribute("frameX"):
				offsetx = int(xml.get_named_attribute_value("frameX"))
			if xml.has_attribute("frameY"):
				offsety = int(xml.get_named_attribute_value("frameY"))
			if xml.has_attribute("frameWidth"):
				frame_w = int(xml.get_named_attribute_value("frameWidth"))
			if xml.has_attribute("frameHeight"):
				frame_h = int(xml.get_named_attribute_value("frameHeight"))

			var full_name := xml.get_named_attribute_value("name")
			var anim_name := full_name.get_slice("0", 0)

			entries.append({
				"anim_name": anim_name, "x": x, "y": y, "w": w, "h": h,
				"offsetx": offsetx, "offsety": offsety,
				"frame_w": frame_w, "frame_h": frame_h,
			})

			if not anim_max_size.has(anim_name):
				anim_max_size[anim_name] = Vector2i(frame_w, frame_h)
			else:
				var cur: Vector2i = anim_max_size[anim_name]
				anim_max_size[anim_name] = Vector2i(max(cur.x, frame_w), max(cur.y, frame_h))
	
	for entry in entries:
		var anim_name: String = entry["anim_name"]
		var max_size: Vector2i = anim_max_size[anim_name]

		var region := Rect2(entry["x"], entry["y"], entry["w"], entry["h"])
		var margin := Rect2(
			abs(entry["offsetx"]), abs(entry["offsety"]),
			max_size.x - entry["w"], max_size.y - entry["h"]
		)

		var atlas_tex := AtlasTexture.new()
		atlas_tex.atlas = texture
		atlas_tex.region = region
		atlas_tex.margin = margin

		if not frames.has_animation(anim_name):
			frames.add_animation(anim_name)
		frames.add_frame(anim_name, atlas_tex)

	return frames

func load_xml_spritesheet(path: String, format: String = 'png') -> SpriteFrames:
	var texture
	if format in ["png", "webp"]:
		texture = load('%s.%s' % [path, format]) as Texture2D
	elif format == "avif":
		texture = CoolUtil.load_avif("%s.%s" % [path, format])
	else:
		push_error("Unsupported spritesheet format: %s" % format)
	if not texture:
		push_error("Failed to load texture: %s.%s" % [path, format])
		return SpriteFrames.new()
	return load_xml_spritesheet_from_texture(path, texture)
