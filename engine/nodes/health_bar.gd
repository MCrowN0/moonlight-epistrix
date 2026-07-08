extends Node2D

@export_node_path("ChartHandler") var chart_handler_path: NodePath

func get_most_common_color(texture: Texture2D) -> Color:
	var image := texture.get_image()
	image.convert(Image.FORMAT_RGBA8)

	var counts: Dictionary = {}
	var width := image.get_width()
	var height := image.get_height()

	for y in height:
		for x in width:
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.5:
				continue
			var key := Color(
				snapped(pixel.r, 0.05),
				snapped(pixel.g, 0.05),
				snapped(pixel.b, 0.05),
				1.0
			)
			counts[key] = counts.get(key, 0) + 1

	if counts.is_empty():
		return Color.TRANSPARENT

	var best_color := Color.BLACK
	var best_count := 0
	for color in counts:
		if counts[color] > best_count:
			best_count = counts[color]
			best_color = color

	return best_color
