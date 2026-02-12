extends Node2D

@onready var grid: GridContainer = $Control/ScrollContainer/GridContainer

var GameTileScene := preload("res://scenes/game_tile.tscn")


func _ready():
	load_games()


# --------------------------------------------------
# Load All Games
# --------------------------------------------------
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


# --------------------------------------------------
# Load Single Game
# --------------------------------------------------
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


# --------------------------------------------------
# Create Tile
# --------------------------------------------------
func add_tile(data: Dictionary, game_path: String):
	var tile = GameTileScene.instantiate()
	grid.add_child(tile)

	var thumb: TextureButton = tile.get_node("Thumbnail")
	var name_label: Label = tile.get_node("Name")

	# Set title
	name_label.text = data.get("title", "Unknown Game")

	# Load cover image
	var cover_path = game_path.path_join("cover.png")
	if FileAccess.file_exists(cover_path):
		var img = Image.load_from_file(cover_path)
		if img != null:
			var tex = ImageTexture.create_from_image(img)
			thumb.texture_normal = tex

	# Store metadata
	tile.set_meta("game_path", game_path)
	tile.set_meta("data", data)

	# Enable focus for controller/keyboard
	thumb.focus_mode = Control.FOCUS_ALL

	# Connect press
	thumb.pressed.connect(func():
		launch_game(
			tile.get_meta("game_path"),
			tile.get_meta("data")
		)
	)

	# Simple focus animation
	thumb.focus_entered.connect(func():
		tile.scale = Vector2(1.1, 1.1)
	)

	thumb.focus_exited.connect(func():
		tile.scale = Vector2.ONE
	)

	# Focus first tile automatically
	if grid.get_child_count() == 1:
		thumb.grab_focus()


# --------------------------------------------------
# Launch Game (Cross Platform)
# --------------------------------------------------
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

	# Quit launcher after starting game
	get_tree().quit()


# --------------------------------------------------
# Shutdown System (Optional)
# --------------------------------------------------
func shutdown_system():
	var os_name = OS.get_name()

	if os_name == "Windows":
		OS.execute("shutdown", ["/s", "/t", "0"], [])
	elif os_name == "Linux":
		OS.execute("shutdown", ["-h", "now"], [])


# --------------------------------------------------
# Get Games Directory (Cross Platform)
# --------------------------------------------------
func get_games_dir() -> String:
	if OS.has_feature("editor"):
		# Running inside the editor
		return ProjectSettings.globalize_path("res://games")
	else:
		# Running exported build
		var base_dir = OS.get_executable_path().get_base_dir()
		return base_dir.path_join("games")
