# 🕹️ Atom Arcade Launcher

A fullscreen game launcher designed for DIY arcade machines, built with Godot 4.
It loads games from a local directory, displays cover images and descriptions,
and is controlled entirely via an arcade joystick and buttons connected through
an Arduino microcontroller.

---

## 📋 Requirements

- A machine running **Windows** or **Linux**
- The [Atom Arcade Connector](https://github.com/maxe1025/atom_arcade_connector) GDExtension (included in the export)
- An Arduino running the Atom Arcade Connector firmware, connected via USB
- Your games stored in the correct directory structure (see below)

---

## 🚀 Setup

### 1. Download the Launcher

Download the latest release for your platform from the [Releases]() page and extract it to a folder of your choice.

```
atom_arcade_launcher/
├── atom_arcade_launcher.exe     # Windows
├── atom_arcade_launcher.x86_64  # Linux
├── atom_arcade_launcher.pck
└── games/                       # Your games go here
```

### 2. Connect the Arduino

Plug in your arcade controller via USB. The launcher will automatically
detect the correct serial port based on your operating system:

| OS      | Port            |
|---------|-----------------|
| Windows | `COM3`          |
| Linux   | `/dev/ttyACM0`  |
| macOS   | `/dev/tty.usbmodem` |

> If your controller uses a different port, you can change it in `_get_serial_port()` inside `main.gd` before exporting.

### 3. Run the Launcher

Simply run the executable. The launcher will automatically scan the `games/`
directory next to the executable and load all valid game entries.

---

## 🎮 Controls

| Input         | Action                        |
|---------------|-------------------------------|
| Joystick      | Navigate between games        |
| **A**         | Launch selected game          |
| **START**     | Focus the shutdown button     |
| **A** (on shutdown button) | Shut down the system |

---

## 📁 Games Directory Structure

All games must be placed inside the `games/` folder, each in their own subfolder.
Every game folder **must** contain an `info.json` file. A `cover.png` is optional
but recommended.

```
games/
├── MyGame/
│   ├── info.json
│   ├── cover.png        # Optional, 300x400px recommended
│   ├── game.exe         # Windows executable
│   └── game.x86_64      # Linux executable
├── AnotherGame/
│   ├── info.json
│   ├── cover.png
│   └── ...
```

> If no `cover.png` is found, a default placeholder image will be shown.

---

## 📄 info.json Reference

Each game folder must contain an `info.json` file with the following fields:

| Field           | Required | Description                                 |
|-----------------|----------|---------------------------------------------|
| `title`         | ✅ Yes   | Display name of the game                    |
| `description`   | ✅ Yes   | Description shown at the bottom of the screen. Supports BBCode. |
| `exec_windows`  | ✅ Yes   | Filename of the Windows executable          |
| `exec_linux`    | ✅ Yes   | Filename of the Linux executable            |

### Example `info.json`

```json
{
  "title": "My Arcade Game",
  "description": "[b][font_size=18]My Arcade Game[/font_size][/b]\n[color=gray]Version 1.2.0 — February 2026[/color]\n\nA fast-paced arcade shooter where you blast through waves of enemies.\nSurvive as long as possible and beat the high score!\n\n[b]Controls:[/b]\n• Joystick — Move\n• [color=yellow]A[/color] — Shoot\n• [color=yellow]B[/color] — Bomb\n\n[color=yellow]Platform:[/color] Windows / Linux",
  "exec_windows": "my_arcade_game.exe",
  "exec_linux": "my_arcade_game.x86_64"
}
```

### BBCode Tips for Descriptions

The description field supports Godot's BBCode formatting:

| BBCode                        | Effect              |
|-------------------------------|---------------------|
| `[b]text[/b]`                 | **Bold**            |
| `[i]text[/i]`                 | *Italic*            |
| `[color=yellow]text[/color]`  | Colored text        |
| `[font_size=18]text[/font_size]` | Larger text      |
| `\n`                          | New line            |

---

## 🛠️ Building from Source

1. Clone this repository
2. Open the project in **Godot 4.x**
3. Make sure the [Atom Arcade Connector](https://github.com/maxe1025/atom_arcade_connector) GDExtension is present in the project
4. Export the project for your target platform
5. Place the exported files together with a `games/` folder

---

## 📜 License

MIT License — feel free to use and modify this project for your own arcade build.