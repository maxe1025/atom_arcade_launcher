extends Node

const CONFIG_FILENAME = "serial_config.json"

const DEFAULTS = {
	"display_port": {
		"Windows": "COM7",
		"Linux": "/dev/ttyACM0",
		"FreeBSD": "/dev/ttyACM0",
		"NetBSD": "/dev/ttyACM0",
		"OpenBSD": "/dev/ttyACM0",
		"BSD": "/dev/ttyACM0",
		"macOS": "/dev/tty.usbmodem2"
	},
	"controller_port": {
		"Windows": "COM3",
		"Linux": "/dev/ttyACM1",
		"FreeBSD": "/dev/ttyACM1",
		"NetBSD": "/dev/ttyACM1",
		"OpenBSD": "/dev/ttyACM1",
		"BSD": "/dev/ttyACM1",
		"macOS": "/dev/tty.usbmodem"
	}
}

var _config: Dictionary = {}


func _ready() -> void:
	_load_config()


func _get_config_path() -> String:
	var os_name = OS.get_name()
	var launcher_dir: String

	if OS.has_feature("editor"):
		launcher_dir = ProjectSettings.globalize_path("res://")
	else:
		if os_name == "Windows":
			launcher_dir = OS.get_executable_path().get_base_dir().path_join("..\\..\\")
		else:
			launcher_dir = OS.get_executable_path().get_base_dir().path_join("../../")

	return launcher_dir.path_join(CONFIG_FILENAME)


func _load_config() -> void:
	var config_path = _get_config_path()
	print("Looking for serial config at: ", config_path)

	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var err = json.parse(file.get_as_text())
			file.close()
			if err == OK:
				_config = json.data
				print("Serial config loaded successfully.")
				return
			else:
				push_error("Failed to parse serial config: " + config_path)
		else:
			push_error("Failed to open serial config: " + config_path)
	else:
		print("No serial config found, using defaults. Generating template at: ", config_path)
		_write_default_config(config_path)


func _write_default_config(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(DEFAULTS, "\t"))
		file.close()
		print("Default serial config written to: ", path)
	else:
		push_warning("Could not write default serial config to: " + path)


func get_display_port() -> String:
	var os_name = OS.get_name()
	if _config.has("display_port"):
		var key = os_name if _config["display_port"].has(os_name) else "Linux"
		return _config["display_port"].get(key, DEFAULTS["display_port"].get(os_name, "/dev/ttyACM0"))
	return DEFAULTS["display_port"].get(os_name, "/dev/ttyACM0")


func get_controller_port() -> String:
	var os_name = OS.get_name()
	if _config.has("controller_port"):
		var key = os_name if _config["controller_port"].has(os_name) else "Linux"
		return _config["controller_port"].get(key, DEFAULTS["controller_port"].get(os_name, "/dev/ttyACM1"))
	return DEFAULTS["controller_port"].get(os_name, "/dev/ttyACM1")
