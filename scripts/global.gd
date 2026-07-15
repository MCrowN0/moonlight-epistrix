extends Node
const save_location = "user://moooon"

var money: int = 0

var botplay: bool = false
var skip_countdown: bool = false
var volume: int = 5

var song_id: int = 0
var debug_play: bool = true

signal on_save_loaded

var normal_icon: Image = Image.load_from_file("res://icon.png")
var x_icon: Image = Image.load_from_file("res://icon2.png")

func _ready() -> void:
	load_game()
	on_save_loaded.emit()
	
	PhysicsServer2D.set_active(false)
	NavigationServer2D.set_active(false)

	RenderingServer.set_default_clear_color(Color(0, 0, 0))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()

func save_game() -> Dictionary:
	var save_file = FileAccess.open(save_location, FileAccess.WRITE)
	var save_dict = {
		"botplay": botplay,
		"skip_countdown": skip_countdown,
		"volume": volume
	}
	save_file.store_line(JSON.stringify(save_dict))
	return save_dict

func load_game() -> Dictionary:
	if not FileAccess.file_exists(save_location):
		botplay = false
		skip_countdown = false
		volume = 5
		return {"botplay": botplay, "skip_countdown": skip_countdown, "volume": volume}
		
	var save_file = FileAccess.open(save_location, FileAccess.READ)
	var save_dict: Dictionary = {}
	save_dict = JSON.parse_string(save_file.get_as_text())
	botplay = save_dict.get("botplay", false)
	skip_countdown = save_dict.get("skip_countdown", false)
	volume = save_dict.get("volume", 5)
	return save_dict
