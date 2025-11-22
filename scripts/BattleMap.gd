extends Node3D

signal unit_selected(unit)

var current_active_character: Character = null
var selected_character: Character = null
var is_attacking: bool = false

@onready var Units: Node3D = $Units
@onready var camera: Camera3D = $Camera3D
@onready var cursor: CSGBox3D = null
@onready var range_indicators: Node3D = Node3D.new()

func _ready() -> void:
	print("BattleMap _ready START")
	
	# Wait for the scene tree to be fully ready (children loaded)
	await get_tree().process_frame
	print("BattleMap: process_frame done")
	
	# Check for GridMap node
	var grid_map : GridMap = null
	if has_node("GridMap"):
		grid_map = $GridMap
		print("GridMap found – using existing map")
	else:
		print("GridMap not found – creating simple grid floor")
		create_grid_floor()
	
	print("BattleMap: Terrain setup done. Spawning characters...")
	
	# Initialize Cursor
	if cursor == null:
		cursor = CSGBox3D.new()
		cursor.size = Vector3(1.1, 1.1, 1.1) # Slightly larger than tile
		cursor.material = StandardMaterial3D.new()
		cursor.material.albedo_color = Color(1, 1, 0, 0.5) # Yellow transparent
		cursor.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cursor.visible = false
		add_child(cursor)
		print("Cursor created programmatically")
		
	# Add range indicators container
	if range_indicators.get_parent() == null:
		add_child(range_indicators)
	
	# Spawn characters (await because spawn_character is async)
	await spawn_all_characters()
	
	print("BattleMap: Characters spawned. _ready END")

# -------------------------------------------------
# 캐릭터 스폰 로직 (코루틴)
# -------------------------------------------------
func spawn_character(name:String, cls:String, char_id:String,
		grid_pos:Vector2i, is_player:bool) -> Character:
	print("Creating character: ", name)
	var character = Character.new()
	character.character_name = name
	character.current_class   = cls
	character.character_id    = char_id
	character.is_player_controlled = is_player

	Units.add_child(character)
	await get_tree().process_frame   # ensure node is fully added

	# 위치 계산 – GridMap이 있으면 map_to_world 사용, 없으면 단순 평면
	var world_pos : Vector3 = Vector3.ZERO
	if has_node("GridMap"):
		var grid_map : GridMap = $GridMap
		# GridMap의 셀 크기와 높이 보정 (예: y축은 cell_size.y * 0.5 로 기본 높이 적용)
		world_pos = grid_map.map_to_world(Vector3(grid_pos.x, 0, grid_pos.y))
		world_pos.y += grid_map.cell_size.y * 0.5   # 기본 높이 보정, 필요 시 조정
	else:
		# Calculate height based on simple terrain logic (Reverted)
		var x = grid_pos.x
		var z = grid_pos.y
		var height = 0
		var dist = Vector2(x, z).length()
		if dist > 6:
			if (x + z) % 3 == 0:
				height = 1
		if dist > 8:
			height = 2
			
		# Height * 0.5 (block height) + 0.5 (half block) + character offset
		world_pos = Vector3(x * 2, height * 0.5 + 0.5, z * 2)

	character.position = world_pos
	character.setup_visuals()
	print("  → Spawned at ", world_pos)
	return character

func create_grid_floor():
	print("Generating Simple 3D Terrain...")
	
	# Use a simple noise-like generation for terrain features
	var width = 20
	var depth = 20
	
	for x in range(-10, 10):
		for z in range(-10, 10):
			var height = 0
			
			# Simple "mountain" logic
			var dist = Vector2(x, z).length()
			if dist > 6:
				if (x + z) % 3 == 0:
					height = 1
			if dist > 8:
				height = 2
				
			# Create column for height
			for h in range(height + 1):
				var tile = CSGBox3D.new()
				tile.size = Vector3(1.8, 0.5, 1.8) # Thicker blocks
				# Position: x, y (height), z
				# h * 0.5 (height)
				tile.position = Vector3(x * 2, h * 0.5, z * 2)
				
				tile.material = StandardMaterial3D.new()
				
				# Color based on height/type
				if h == 0:
					if (x + z) % 2 == 0:
						tile.material.albedo_color = Color(0.4, 0.8, 0.4) # Grass 1
					else:
						tile.material.albedo_color = Color(0.3, 0.7, 0.3) # Grass 2
				elif h == 1:
					tile.material.albedo_color = Color(0.6, 0.5, 0.3) # Dirt/Rock
				else:
					tile.material.albedo_color = Color(0.5, 0.5, 0.5) # Stone
				
				add_child(tile)
	print("Simple 3D Terrain Generated.")

func spawn_all_characters():
	print("Spawning all characters...")
	
	var units = []
	
	# Player characters (3명)
	var player_configs = [
		{"class": "Gunner", "id": "", "grid": Vector2i(0, 0), "name": "포수"},
		{"class": "Spearman", "id": "", "grid": Vector2i(1, 0), "name": "살수"},
		{"class": "Archer", "id": "", "grid": Vector2i(2, 0), "name": "궁수"}
	]
	
	for config in player_configs:
		var player = await spawn_character(config["name"], config["class"], config["id"], config["grid"], true)
		units.append(player)
	
	# Enemy characters (2명)
	var enemy_configs = [
		{"class": "Enemy", "id": "kodama", "grid": Vector2i(-4, -4), "name": "Kodama"},
		{"class": "Enemy", "id": "nekomata", "grid": Vector2i(-2, -4), "name": "Nekomata"}
	]
	
	for config in enemy_configs:
		var enemy = await spawn_character(config["name"], config["class"], config["id"], config["grid"], false)
		units.append(enemy)
	
	print("All characters spawned! Total: ", units.size())
	
	# Connect turn signal
	if not GameManager.is_connected("turn_advanced", self._on_turn_advanced):
		GameManager.turn_advanced.connect(self._on_turn_advanced)
	
	# Start Battle
	GameManager.start_battle(units)

func _on_turn_advanced(character):
	current_active_character = character
	print("Active character: ", character.character_name)
	
	# Clear selection and range
	selected_character = null
	is_attacking = false
	clear_range_indicators()
	
	# Auto-select active player character
	if character.is_player_controlled:
		selected_character = character
		show_movement_range(character)
		emit_signal("unit_selected", character)
	
	# If enemy, simple AI (skip turn for now)
	if not character.is_player_controlled:
		await get_tree().create_timer(1.0).timeout
		print("Enemy turn done")
		GameManager.advance_turn()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				handle_click(event.position)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				handle_right_click(event.position)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# Zoom In
				if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
					camera.size = max(camera.size - 1.0, 5.0)
				else:
					camera.position.y = max(camera.position.y - 1.0, 2.0)
					camera.position.z = max(camera.position.z - 1.0, 2.0)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# Zoom Out
				if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
					camera.size = min(camera.size + 1.0, 30.0)
				else:
					camera.position.y = min(camera.position.y + 1.0, 20.0)
					camera.position.z = min(camera.position.z + 1.0, 20.0)

func handle_click(screen_pos):
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	# Simple grid calculation using plane intersection if no physics object hit (or if floor hit)
	# Assuming floor is at y=0
	var plane = Plane(Vector3.UP, 0)
	var intersection = plane.intersects_ray(from, camera.project_ray_normal(screen_pos))
	
	if intersection:
		var grid_pos = GridUtils.world_to_grid(intersection)
		print("Clicked grid: ", grid_pos)
		cursor.position = GridUtils.grid_to_world(grid_pos)
		cursor.visible = true
		
		# Check for unit
		var clicked_unit = get_unit_at_grid(Vector2i(grid_pos.x, grid_pos.z))
		
		if is_attacking:
			if clicked_unit and clicked_unit != current_active_character:
				# Attack target
				execute_attack(clicked_unit)
			else:
				# Cancel attack if clicking empty space or self
				is_attacking = false
				clear_range_indicators()
				show_movement_range(current_active_character)
				print("Attack cancelled")
			return

		if clicked_unit:
			# Only allow selecting own units or inspecting enemies
			selected_character = clicked_unit
			print("Selected: ", selected_character.character_name)
			emit_signal("unit_selected", selected_character)
			
			if selected_character == current_active_character:
				show_movement_range(selected_character)
			else:
				clear_range_indicators()
		else:
			# Move if clicking empty tile and active char is selected
			if selected_character == current_active_character and current_active_character.is_player_controlled:
				var target_pos = Vector2i(grid_pos.x, grid_pos.z)
				if current_active_character.move_to(target_pos, self):
					clear_range_indicators()
					selected_character = null
					emit_signal("unit_selected", null)
					
					# Check AP
					if current_active_character.current_ap <= 0:
						print("AP exhausted. Ending turn.")
						GameManager.advance_turn()
					else:
						# Re-select to show updated range or allow attack
						selected_character = current_active_character
						show_movement_range(selected_character)
						emit_signal("unit_selected", selected_character)

func handle_right_click(screen_pos):
	# Cancel selection or action
	selected_character = null
	is_attacking = false
	emit_signal("unit_selected", null)
	clear_range_indicators()

func start_attack_mode():
	if not current_active_character or not current_active_character.is_player_controlled:
		return
	
	is_attacking = true
	print("Attack mode started")
	show_attack_range(current_active_character)

signal log_message(text)

func execute_attack(target: Character):
	print("Attacking ", target.character_name)
	
	# Determine skill based on class (Simple logic for now)
	var skill_name = "Slash"
	if current_active_character.current_class == "Archer" or current_active_character.current_class == "Gungsu":
		skill_name = "ArrowShot"
	elif current_active_character.current_class == "Mage":
		skill_name = "Fireball"
	elif current_active_character.current_class == "Spearman" or current_active_character.current_class == "Salsu":
		skill_name = "Slash" # Or Pierce if available
	
	# Check range (simplified, ideally check before execute)
	var skill_data = GameData.SKILLS.get(skill_name)
	var range_val = skill_data.get("range", 1)
	var dist = current_active_character.grid_position.distance_to(target.grid_position)
	
	# Play Visual Effect
	await play_visual_effect(skill_name, target.position)
	
	var terrain_name = get_terrain_at_position(target.grid_position)
	
	var result = GameManager.calculate_damage(current_active_character, target, skill_name, terrain_name)
	var damage = result["damage"]
	
	target.take_damage(damage)
	
	var log_text = "%s uses %s on %s! " % [current_active_character.character_name, skill_name, target.character_name]
	if result["is_critical"]:
		log_text += "CRITICAL! "
	
	if damage == 0:
		log_text += "Miss!"
	else:
		log_text += "Dealt %d damage." % damage
		
	print(log_text)
	emit_signal("log_message", log_text)
	
	# Consume AP
	current_active_character.current_ap -= 1
	print("Action used. Remaining AP: ", current_active_character.current_ap)
	
	is_attacking = false
	clear_range_indicators()
	
	# Check AP for turn end
	if current_active_character.current_ap <= 0:
		print("AP exhausted. Ending turn.")
		GameManager.advance_turn()
	else:
		# Re-select
		selected_character = current_active_character
		show_movement_range(selected_character)
		emit_signal("unit_selected", selected_character)

func play_visual_effect(skill_name: String, target_pos: Vector3):
	var effect_name = "slash"
	if skill_name == "Fireball": effect_name = "fireball"
	elif skill_name == "Heal": effect_name = "heal"
	elif skill_name == "ArrowShot": effect_name = "arrow"
	
	var texture_path = "res://assets/textures/effects/" + effect_name + ".svg"
	if not FileAccess.file_exists(texture_path):
		print("Effect texture not found: ", texture_path)
		return
		
	var sprite = Sprite3D.new()
	add_child(sprite)
	sprite.position = target_pos + Vector3(0, 1.0, 0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.02
	sprite.texture = load(texture_path)
	sprite.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	tween.tween_property(sprite, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(sprite.queue_free)
	
	await tween.finished

func show_movement_range(character: Character):
	clear_range_indicators()
	var tiles = get_reachable_tiles(character.grid_position, character.move_range)
	print("Showing movement range for ", character.character_name, " Tiles: ", tiles.size())
	
	for tile in tiles:
		var indicator = CSGBox3D.new()
		indicator.size = Vector3(1.8, 0.05, 1.8)
		indicator.material = StandardMaterial3D.new()
		indicator.material.albedo_color = Color(0, 0, 1, 0.3) # Blue for move
		indicator.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		var world_pos = GridUtils.grid_to_world(Vector3i(tile.x, 0, tile.y))
		world_pos.y = 0.3
		indicator.position = world_pos
		range_indicators.add_child(indicator)

func show_attack_range(character: Character):
	clear_range_indicators()
	
	# Determine range based on class
	var range_val = 1
	if character.current_class == "Archer" or character.current_class == "Gungsu":
		range_val = 3
	elif character.current_class == "Mage":
		range_val = 3
	elif character.current_class == "Sniper":
		range_val = 5
		
	var tiles = get_reachable_tiles(character.grid_position, range_val)
	
	for tile in tiles:
		if tile == character.grid_position: continue
		
		var indicator = CSGBox3D.new()
		indicator.size = Vector3(1.8, 0.05, 1.8)
		indicator.material = StandardMaterial3D.new()
		indicator.material.albedo_color = Color(1, 0, 0, 0.3) # Red for attack
		indicator.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		var world_pos = GridUtils.grid_to_world(Vector3i(tile.x, 0, tile.y))
		world_pos.y = 0.3
		indicator.position = world_pos
		range_indicators.add_child(indicator)

func clear_range_indicators():
	for child in range_indicators.get_children():
		child.queue_free()

# Mock BattleGrid functions for Character.gd
func get_reachable_tiles(start_pos, range_val):
	# BFS for movement range
	var reachable = []
	var queue = [{"pos": start_pos, "dist": 0}]
	var visited = {start_pos: true}
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current["pos"]
		var dist = current["dist"]
		
		if dist <= range_val:
			reachable.append(pos)
			
			if dist < range_val:
				var neighbors = [
					pos + Vector2i(1, 0), pos + Vector2i(-1, 0),
					pos + Vector2i(0, 1), pos + Vector2i(0, -1)
				]
				
				for neighbor in neighbors:
					if not visited.has(neighbor):
						# Check bounds (e.g., -10 to 10)
						if abs(neighbor.x) <= 10 and abs(neighbor.y) <= 10:
							visited[neighbor] = true
							queue.append({"pos": neighbor, "dist": dist + 1})
	
	return reachable

func get_terrain_at_position(pos):
	return "Plain"

func get_height_at_position(pos):
	return 0

func change_terrain(pos, type):
	pass

func get_unit_at_grid(grid_pos: Vector2i) -> Character:
	for child in $Units.get_children():
		if child is Character and child.grid_position == grid_pos:
			return child
	return null

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	return GridUtils.grid_to_world(Vector3i(grid_pos.x, 0, grid_pos.y))
