# 🎮 Godot Development Rules and Guidelines

## 📋 Goal

This document provides rules and guidelines for consistent and efficient development of the tactical SRPG project using the Godot 4.4 engine.

---

## 🗂️ Project Structure Rules

### 1. **Folder Structure Principle**

```
Project_Root/
├── scenes/          # Scene files (.tscn + .gd)
│   ├── ui/         # UI related scenes
│   ├── battle/     # Battle related scenes
│   └── menu/       # Menu related scenes
├── scripts/         # Pure logic scripts
│   ├── managers/   # Singleton managers
│   ├── data/       # Data classes
│   └── utils/      # Utility functions
├── assets/          # Resource files
│   ├── sprites/    # Sprite images
│   ├── audio/      # Sound files
│   └── fonts/      # Font files
├── resources/       # Godot resource files (.tres, .res)
└── addons/          # Plugins and extensions
```

---
(The rest of the guideline content follows)
---

## 🎓 Godot Engine Basic Syntax Learning Guide (For Successors)

For those who are new to this project or unfamiliar with the Godot engine, this guide explains the core concepts and provides learning resources.

### 1. **GDScript: An Easy Language Like Python**

GDScript, Godot's main scripting language, is very similar to Python and easy to learn. Understanding the basic syntax below will be of great help in understanding the project code.

- **Variable Declaration**: `var my_variable = 10`
- **Type Hint**: `var health: int = 100` (Type hints are **mandatory** in this project.)
- **Function Declaration**: `func my_function(param1: String, param2: int) -> bool:`
- **Conditionals**: `if`, `elif`, `else` (Same as Python)
- **Loops**: `for i in range(10):`, `while condition:` (Same as Python)
- **Comments**: `#` for single-line comments, `##` for documentation comments

> 📚 **Recommended Learning Material**: [GDScript Basics Official Tutorial](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html)

### 2. **Nodes and Scenes: Assembling Like Lego Blocks**

Godot develops games by assembling small functional units called 'Nodes' into 'Scenes'.

- **Node**: The smallest component of a game. (e.g., `Sprite2D` displays an image, `Label` displays text, `Button` displays a button)
- **Scene**: An assembly of nodes in a hierarchical structure (Parent-Child), like a tree. A single character, a bullet, or a UI window can each be a scene.
- **Scene Tree**: The entire structure of scenes and nodes currently running in the game.

> 📚 **Recommended Learning Material**: [Scenes and Nodes Official Tutorial](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scenes_and_nodes.html)

### 3. **Signals: Announcing "Something Happened!"**

A signal is a 'broadcasting' system where one node notifies other nodes that a specific event has occurred. This reduces direct dependencies between codes, creating a more flexible structure.

- **How it works**:
  1. **Emitter**: Emits a signal when a button is pressed (`pressed`) or a character dies (`character_died`).
  2. **Receiver**: A function of another node is `connect`ed to this signal.
  3. **Result**: When the signal is emitted, all connected functions are automatically executed.

- **Example in our project**:
  - `BattleGrid.gd` emits the `tile_clicked` signal when a tile is clicked.
  - `BattleScene.gd` connects its `_on_tile_clicked` function to this signal and processes the tile click upon receiving the signal.

> 📚 **Recommended Learning Material**: [Signals Official Tutorial](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)

### 4. **Singleton (Autoload): A Global Manager Accessible from Anywhere**

`GameManager.gd` and `GameData.gd` are registered as singletons. These are global objects that can be accessed directly from anywhere in the project, like `GameManager.next_turn()`.

- **Purpose**: Used to manage features that need to be shared across multiple scenes, such as the overall game state, common data, and save/load functionality.
- **How to check**: You can see the list of registered singletons in the Godot editor under `Project > Project Settings > Autoload` tab.

---

Following these rules will help you create a consistent and maintainable Godot project! 🎮
