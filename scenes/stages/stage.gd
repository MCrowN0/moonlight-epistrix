class_name Stage extends Node2D

@export_node_path("Sprite2D") var dad_path
@export_node_path("Sprite2D") var gf_path
@export_node_path("Sprite2D") var bf_path

var dad: Sprite2D
var gf: Sprite2D
var bf: Sprite2D

func _init() -> void:
	for character in ["dad", "gf", "bf"]:
		var path = get("%s_path" % character)
		if not path == null:
			set(character, get_node(path))

func _reposition_characters(ext_dad: NodePath, ext_gf: NodePath, ext_bf: NodePath):
	for character in ["dad", "gf", "bf"]:
			match character:
				"dad":
					get_node(ext_dad).position = get_node(dad_path).position
					get_node(ext_dad).scale = get_node(dad_path).scale
					get_node(ext_dad).modulate = get_node(dad_path).modulate
					get_node(dad_path).queue_free()
				"gf":
					get_node(ext_gf).position = get_node(gf_path).position
					get_node(ext_gf).scale = get_node(gf_path).scale
					get_node(ext_gf).modulate = get_node(gf_path).modulate
					get_node(gf_path).queue_free()
				"bf":
					get_node(ext_bf).position = get_node(bf_path).position
					get_node(ext_bf).scale = get_node(bf_path).scale
					get_node(ext_bf).modulate = get_node(bf_path).modulate
					get_node(bf_path).queue_free()
				
