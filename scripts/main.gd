extends Node2D

@onready var grid: GridContainer = $Control/ScrollContainer/GridContainer
@onready var scroll_container: ScrollContainer = $Control/ScrollContainer
@onready var description_label: RichTextLabel = $Control/FooterPanel/DescriptionLabel
@onready var header_label: Label = $Control/Panel/Header
@onready var shutdown_button: Button = $Control/Panel/ShutdownButton

var GameTileScene := preload("res://scenes/game_tile.tscn")
var default_cover := preload("res://img/cover.png")

# Arcade Controller Constants
# For documentation visit the Atom Arcade Connector GitHub page:
# https://github.com/maxe1025/atom_arcade_connector
const BTN_A     = 0b00000001
const BTN_B     = 0b00000010
const BTN_X     = 0b00000100
const BTN_Y     = 0b00001000
const BTN_LB    = 0b00010000
const BTN_RB    = 0b00100000
const BTN_START = 0b01000000

var controller: Controller

var input_cooldown := 0.3
var input_timer := 0.0
var btn_a_was_pressed := false
var btn_start_was_pressed := false


func _ready():
	controller = Controller.new()
	controller.start(_get_serial_port())

	load_games()
	
	shutdown_button.pressed.connect(shutdown_system)

	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_update_header)
	add_child(timer)
	_update_header()


func _process(delta: float):
	if not controller:
		return

	input_timer -= delta

	var raw_x = controller.get_axis_x()
	var raw_y = controller.get_axis_y()
	var buttons = controller.get_buttons()

	if input_timer <= 0:
		var move_x = (raw_x - 512.0) / 512.0
		var move_y = (raw_y - 512.0) / 512.0

		var focused = get_viewport().gui_get_focus_owner()

		if focused == shutdown_button:
			if abs(move_x) > 0.5 or abs(move_y) > 0.5:
				var tiles = grid.get_children()
				if tiles.size() > 0:
					tiles[0].get_node("MarginContainer/Thumbnail").grab_focus()
				input_timer = input_cooldown
		else:
			if move_x > 0.5:
				_move_focus(-1)
				input_timer = input_cooldown
			elif move_x < -0.5:
				_move_focus(1)
				input_timer = input_cooldown
			elif move_y > 0.5:
				_move_focus(-grid.columns)
				input_timer = input_cooldown
			elif move_y < -0.5:
				_move_focus(grid.columns)
				input_timer = input_cooldown

	var btn_a_pressed = (buttons & BTN_A) != 0
	if btn_a_pressed and not btn_a_was_pressed:
		var focused = get_viewport().gui_get_focus_owner()
		if focused == shutdown_button:
			shutdown_system()
		else:
			_launch_focused_game()
	btn_a_was_pressed = btn_a_pressed

	var btn_start_pressed = (buttons & BTN_START) != 0
	if btn_start_pressed and not btn_start_was_pressed:
		shutdown_button.grab_focus()
	btn_start_was_pressed = btn_start_pressed


func _move_focus(direction: int):
	var focused = get_viewport().gui_get_focus_owner()
	if focused == null:
		if grid.get_child_count() > 0:
			grid.get_child(0).get_node("MarginContainer/Thumbnail").grab_focus()
		return

	var tiles = grid.get_children()
	for i in range(tiles.size()):
		var thumb = tiles[i].get_node("MarginContainer/Thumbnail")
		if thumb == focused:
			var next_index = clamp(i + direction, 0, tiles.size() - 1)
			var next_thumb = tiles[next_index].get_node("MarginContainer/Thumbnail")
			next_thumb.grab_focus()
			_scroll_to_tile(tiles[next_index])
			return


func _scroll_to_tile(tile: Node):
	await get_tree().process_frame

	var tile_top = tile.global_position.y - grid.global_position.y
	var tile_bottom = tile_top + tile.size.y

	var scroll_top = scroll_container.scroll_vertical
	var scroll_bottom = scroll_top + scroll_container.size.y

	if tile_top < scroll_top:
		scroll_container.scroll_vertical = int(tile_top)
	elif tile_bottom > scroll_bottom:
		scroll_container.scroll_vertical = int(tile_bottom - scroll_container.size.y)


func _launch_focused_game():
	var focused = get_viewport().gui_get_focus_owner()
	if focused == null:
		return

	var tile = focused.get_parent().get_parent()
	if tile.has_meta("game_path") and tile.has_meta("data"):
		launch_game(tile.get_meta("game_path"), tile.get_meta("data"))


func _get_serial_port() -> String:
	match OS.get_name():
		"Windows":
			return "COM3"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return "/dev/ttyACM1"
		"macOS":
			return "/dev/tty.usbmodem"
		_:
			return "/dev/ttyACM0"


func _update_header():
	var datetime = Time.get_datetime_dict_from_system()

	var hour = "%02d" % datetime["hour"]
	var minute = "%02d" % datetime["minute"]
	var day = "%02d" % datetime["day"]
	var month = "%02d" % datetime["month"]
	var year = str(datetime["year"])

	var time_str = hour + ":" + minute
	var date_str = day + "." + month + "." + year

	header_label.text = time_str + "  |  " + date_str


# Load All Games
func load_games():
	var games_dir = get_games_dir()

	if not DirAccess.dir_exists_absolute(games_dir):
		print("Games folder not found: ", games_dir)
		return

	var dir = DirAccess.open(games_dir)
	if dir == null:
		print("Could not open games directory.")
		return

	dir.list_dir_begin()
	var folder_name = dir.get_next()

	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var game_path = games_dir.path_join(folder_name)
			load_game(game_path)

		folder_name = dir.get_next()

	dir.list_dir_end()


# Load Single Game
func load_game(game_path: String):
	var info_path = game_path.path_join("info.json")

	if not FileAccess.file_exists(info_path):
		print("Missing info.json in: ", game_path)
		return

	var file = FileAccess.open(info_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)

	if typeof(data) != TYPE_DICTIONARY:
		print("Invalid JSON in: ", info_path)
		return

	add_tile(data, game_path)
	print("Tile added.")


# Create Tile
func add_tile(data: Dictionary, game_path: String):
	var tile = GameTileScene.instantiate()
	grid.add_child(tile)

	var thumb: TextureButton = tile.get_node("MarginContainer/Thumbnail")
	var name_label: Label = tile.get_node("Name")

	name_label.text = data.get("title", "Unknown Game")

	var cover_path = game_path.path_join("cover.png")
	if FileAccess.file_exists(cover_path):
		var img = Image.load_from_file(cover_path)
		if img != null:
			var tex = ImageTexture.create_from_image(img)
			thumb.texture_normal = tex
		else:
			thumb.texture_normal = default_cover
	else:
		thumb.texture_normal = default_cover


	tile.set_meta("game_path", game_path)
	tile.set_meta("data", data)

	thumb.focus_mode = Control.FOCUS_ALL

	thumb.pressed.connect(func():
		launch_game(
			tile.get_meta("game_path"),
			tile.get_meta("data")
		)
	)

	var tween: Tween
	thumb.pivot_offset = thumb.size / 2

	thumb.focus_entered.connect(func():
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(thumb, "scale", Vector2(1.12, 1.12), 0.12)

		description_label.bbcode_enabled = true
		description_label.text = tile.get_meta("data").get("description", "")
	)

	thumb.focus_exited.connect(func():
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(thumb, "scale", Vector2.ONE, 0.12)
	)

	if grid.get_child_count() == 1:
		thumb.grab_focus()


# Launch Game
func launch_game(game_path: String, data: Dictionary):
	var os_name = OS.get_name()
	var exec_key := ""

	if os_name == "Windows":
		exec_key = "exec_windows"
	elif os_name == "Linux":
		exec_key = "exec_linux"
	else:
		push_error("Unsupported OS: " + os_name)
		return

	if not data.has(exec_key):
		push_error("Missing executable for " + os_name)
		return

	var full_path = game_path.path_join(data[exec_key])

	print("Launching: ", full_path)

	OS.execute(full_path, [], [])

	get_tree().quit()


func shutdown_system():
	var os_name = OS.get_name()
	if os_name == "Windows":
		OS.execute("shutdown", ["/s", "/t", "0"])
	elif os_name in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"]:
		OS.execute("shutdown", ["-h", "now"])
	elif os_name == "macOS":
		OS.execute("sudo", ["shutdown", "-h", "now"])
	get_tree().quit()


# Get Games Directory
func get_games_dir() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://games")
	else:
		var base_dir = OS.get_executable_path().get_base_dir()
		return base_dir.path_join("games")
