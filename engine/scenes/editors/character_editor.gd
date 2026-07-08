extends Control

const IMAGE_FORMATS: Array[String] = ["png", "webp", "avif"]
const TO_INFER_DEFAULT_ANIMATIONS: Array[String] = ["idle", "dance_left"]

func _infer_format(char_path: String) -> String:
	for format in IMAGE_FORMATS:
		if char_path.ends_with(format): return format
	return ""

func _infer_default_animation(sprite_frames: SpriteFrames) -> String:
	if sprite_frames.has_animation("idle"): return "idle"
	elif sprite_frames.has_animation("dance_left"): return "dance_left"
	return ""

func _infer_animations_from_prefixes(sprite_frames: SpriteFrames) -> Dictionary:
	var infered_sprite_frames: SpriteFrames = sprite_frames
	var prefixes: Dictionary = {}
	var guess_animations: Array[String] = ["idle", "dance_left", "dance_right", "left", "down", "up", "right"]
	
	for animation in sprite_frames.get_animation_names():
		for guess_animation in guess_animations:
			if guess_animation in animation.to_lower():
				var target = guess_animation
				if guess_animation in Constants.directions and "miss" in animation.to_lower():
					target += " miss"
				if animation != target:
					infered_sprite_frames.rename_animation(animation, target)
				prefixes[target] = animation
			else: prefixes[animation] = animation
	return {
		"sprite_frames": infered_sprite_frames,
		"prefixes": prefixes
	}

@onready var underlay: Sprite2D = $Underlay
@onready var character_preview: OffsetAnimatedSprite2D = $CharacterPreview

@onready var character_load_file_dialog: FileDialog = $CharacterLoadFileDialog
@onready var character_save_file_dialog: FileDialog = $CharacterSaveFileDialog
@onready var character_set_img_file_dialog: FileDialog = $CharacterSetIMGFileDialog

@onready var option_button: OptionButton = $CanvasLayer2/TabContainer/Animations/OptionButton
@onready var item_list: ItemList = $CanvasLayer2/TabContainer/Animations/ItemList
@onready var show_underlay: CheckBox = $CanvasLayer2/TabContainer/Animations/ShowUnderlay

@onready var rename_text: LineEdit = $CanvasLayer2/TabContainer/Animations/RenameText
@onready var rename_button: Button = $CanvasLayer2/TabContainer/Animations/RenameButton

@onready var framerate_spinbox: SpinBox = $CanvasLayer2/TabContainer/Animations/FramerateSpinbox

@onready var accept_dialog: AcceptDialog = $AcceptDialog
@onready var looped: CheckButton = $CanvasLayer2/TabContainer/Animations/Looped
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

var character_resource: CharacterResource = CharacterResource.new()
var ignore_infer: bool = false

var reference_sprite_frames: SpriteFrames = SpriteFrames.new()
var offseted_sprite_frames: SpriteFrames = SpriteFrames.new()

var character_path: String = "":
	set(value):
		if not ignore_infer:
			img_format = _infer_format(value)
			character_path = value.replace(".%s" % img_format, "")
		else:
			character_path = value
		var sprite_frames: SpriteFrames = XMLSpritesheet.load_xml_spritesheet(character_path, img_format)
		sprite_frames.remove_animation("default")
		
		if not ignore_infer:
			animations = []
			var inferred_stuff: Dictionary = _infer_animations_from_prefixes(sprite_frames)
			sprite_frames = inferred_stuff["sprite_frames"]
			
			default_animation = _infer_default_animation(sprite_frames)
			
			for animation: String in sprite_frames.get_animation_names():
				option_button.add_item(animation)
				if animation == default_animation:
					option_button.selected = sprite_frames.get_animation_names().find(animation)
				item_list.add_item(animation)
				animations.append({
					"animation": animation,
					"prefix": inferred_stuff["prefixes"][animation],
					"framerate": 24,
					"loop": false,
					"offset": Vector2(0.0, 0.0)
				})
				sprite_frames.set_animation_speed(animation, 24)
				sprite_frames.set_animation_loop_mode(animation, SpriteFrames.LOOP_NONE)
		else:
			for animation in animations:
				if animation.prefix != animation.animation:
					sprite_frames.rename_animation(animation.prefix, animation.animation)
			for i in range(len(animations)):
				option_button.add_item(animations[i].animation)
				if animations[i].animation == default_animation:
					option_button.selected = i
				sprite_frames.set_animation_speed(animations[i].animation, animations[i].framerate)
				sprite_frames.set_animation_loop(animations[i].animation, animations[i].loop)
				item_list.add_item(animations[i].animation)
		character_preview.sprite_frames = sprite_frames
		sprite_frames = sprite_frames
		character_preview.animation = default_animation
		underlay.texture = sprite_frames.get_frame_texture(default_animation, 0)
		character_preview.play()

var default_animation: String = ""
var img_format: String = ""
var animations: Array[Dictionary]

const LOAD_DIALOG_TEXT: String = "Character data loaded!"
const SAVE_DIALOG_TEXT: String = "Character data saved!"
const LOAD_FAIL_DIALOG_TEXT: String = "Loading failed!"
const NO_ANIM_SELECTED_DIALOG_TEXT: String = "Please select an animation first!"

func _ready() -> void:
	character_load_file_dialog.add_filter("*.bin", "Project Overkill Binary character")
	character_load_file_dialog.add_filter("*.json", "Project Overkill JSON character")
	character_save_file_dialog.add_filter("*.bin", "Project Overkill Binary character")
	character_set_img_file_dialog.add_filter(
		"*.png, *.webp, *.avif",
	    "Supported Images"
	)
	character_set_img_file_dialog.add_filter("*.png", "PNG Images")
	character_set_img_file_dialog.add_filter("*.webp", "WebP Images")
	character_set_img_file_dialog.add_filter("*.avif", "AVIF Images")

func _on_character_set_img_file_dialog_file_selected(path_arg: String) -> void:
	option_button.clear()
	item_list.clear()
	character_path = path_arg

func _on_character_load_file_dialog_file_selected(path_arg: String) -> void:
	animations = []
	accept_dialog.dialog_text = LOAD_DIALOG_TEXT
	if path_arg.ends_with(".json"):
		ignore_infer = true
		var character_json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path_arg))
		default_animation = character_json.get("default_animation", "idle")
		img_format = character_json.get("format", "png")
		for animation: Dictionary in character_json.animations:
			animations.append({
				"animation": animation.get("animation", ""),
				"prefix": animation.get("prefix", ""),
				"framerate": animation.get("framerate", 24),
				"loop": animation.get("loop", false),
				"offset": animation.get("offset", Vector2(0.0, 0.0))
			})
		character_path = "res://" + character_json.get("path", "")
		ignore_infer = false
	elif path_arg.ends_with(".bin"):
		character_resource.load(path_arg)
		ignore_infer = true
		img_format = character_resource.get_metadata().get("format")
		default_animation = character_resource.get_metadata().get("default_animation")
		for animation: Dictionary in character_resource.get_animations():
			animations.append({
				"animation": animation.get("animation", ""),
				"prefix": animation.get("prefix", ""),
				"framerate": animation.get("framerate", 24),
				"loop": animation.get("looped", false),
				"offset": animation.get("offset", Vector2(0.0, 0.0))
			})
		character_path = character_resource.get_metadata().get("path")
		ignore_infer = false
	else:
		accept_dialog.dialog_text = LOAD_FAIL_DIALOG_TEXT
	accept_dialog.popup()

func _on_character_save_file_dialog_file_selected(path_arg: String) -> void:
	character_resource.new_empty(character_path, default_animation, img_format)
	for animation in animations:
		character_resource.add_animation(
			animation.get("animation", ""),
			animation.get("prefix", ""),
			animation.get("framerate", 24),
			animation.get("loop", false),
			animation.get("offset", Vector2(0.0, 0.0))
		)
	character_resource.save(ProjectSettings.globalize_path(path_arg))
	accept_dialog.dialog_text = SAVE_DIALOG_TEXT
	accept_dialog.popup()

func _on_load_pressed() -> void:
	character_load_file_dialog.popup()

func _on_save_pressed() -> void:
	character_save_file_dialog.popup()

func _on_set_path_pressed() -> void:
	character_set_img_file_dialog.popup()

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	underlay.position = character_preview.position

	if not len(item_list.get_selected_items()) == 0:
		var factor: int = 5 if Input.is_action_pressed("shift") else 1
		var index_selected: int = item_list.get_selected_items()[0]
		var direction: Vector2 = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		
		animations[index_selected].offset += direction * factor
		character_preview.update_offset(animations[index_selected].animation, animations[index_selected].offset)

var moving_camera: bool = false
var dragging_character: bool = false
var start_mouse_position: Vector2 = Vector2(0.0, 0.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if not len(item_list.get_selected_items()) == 0:
			if Input.is_action_just_pressed("ui_space"):
				character_preview.frame = 0
				character_preview.play()
			if Input.is_action_just_pressed("reset"):
				confirmation_dialog.popup()
		
	if event is InputEventMouseButton and (get_viewport().get_mouse_position().x < 820.0 or get_viewport().get_mouse_position().y > 536.0):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			rename_text.release_focus()
		moving_camera = Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		start_mouse_position = get_viewport().get_mouse_position()
		
		if event.pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and (get_viewport().get_mouse_position().x < 820.0):
			dragging_character = true
		else:
			dragging_character = false
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP) or Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			var mouse_before = $Camera2D.get_global_mouse_position()
			$Camera2D.zoom += Vector2(0.1, 0.1) if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP) else Vector2(-0.1, -0.1)
			var mouse_after = $Camera2D.get_global_mouse_position()
			$Camera2D.global_position += mouse_before - mouse_after
	
	if event is InputEventMouse and (get_viewport().get_mouse_position().x < 820.0 or get_viewport().get_mouse_position().y > 536.0):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			$Camera2D.position -= (event.position - start_mouse_position)
			start_mouse_position = event.position
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and dragging_character and not len(item_list.get_selected_items()) == 0:
			var index_selected: int = item_list.get_selected_items()[0]
			animations[index_selected].offset += (event.position - start_mouse_position)
			start_mouse_position = event.position
			character_preview.clear_offsets()
			character_preview.add_offset(animations[index_selected].animation, animations[index_selected].offset)
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)

@warning_ignore("unused_parameter")
func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == 1:
		character_preview.animation = animations[index].animation
		framerate_spinbox.value = animations[index].framerate
		looped.button_pressed = animations[index].loop
		character_preview.play()

func _on_show_underlay_toggled(toggled_on: bool) -> void:
	underlay.visible = toggled_on

func _on_show_character_toggled(toggled_on: bool) -> void:
	character_preview.visible = toggled_on

func _on_rename_button_pressed() -> void:
	if len(item_list.get_selected_items()) == 0:
		accept_dialog.dialog_text = NO_ANIM_SELECTED_DIALOG_TEXT
		accept_dialog.popup()
	else:
		var index_selected: int = item_list.get_selected_items()[0]
		animations[index_selected].animation = rename_text.text
		item_list.set_item_text(index_selected, rename_text.text)

func _on_option_button_item_selected(index: int) -> void:
	underlay.texture = character_preview.sprite_frames.get_frame_texture(animations[index].animation, 0)

@warning_ignore("unused_parameter")
func _on_looped_toggled(toggled_on: bool) -> void:
	if len(item_list.get_selected_items()) == 0: return
	
	var index_selected: int = item_list.get_selected_items()[0]
	animations[index_selected].loop = toggled_on
	character_preview.sprite_frames.set_animation_loop_mode(animations[index_selected].animation, SpriteFrames.LOOP_NONE if not toggled_on else SpriteFrames.LOOP_LINEAR)

func _on_framerate_spinbox_value_changed(value: float) -> void:
	if len(item_list.get_selected_items()) == 0: return
	
	var index_selected: int = item_list.get_selected_items()[0]
	animations[index_selected].framerate = value
	character_preview.sprite_frames.set_animation_speed(animations[index_selected].animation, value)

func _on_confirmation_dialog_confirmed() -> void:
	animations[item_list.get_selected_items()[0]].offset = Vector2(0.0, 0.0)
	character_preview.update_offset(animations[item_list.get_selected_items()[0]].animation, Vector2(0.0, 0.0))
