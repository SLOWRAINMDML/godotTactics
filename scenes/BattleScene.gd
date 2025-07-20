# -----------------------------------------------------------------------------
# [후임자를 위한 안내]
#
# BattleScene.gd (전투 씬)
#
# [역할]
# 이 스크립트는 `BattleScene.tscn` 씬의 루트 노드에 연결되어, 전투와 관련된 모든 요소를
# 총괄하는 '메인 컨트롤러' 역할을 합니다.
# 사용자의 입력을 받고, 게임의 상태를 관리하며, UI를 업데이트하고,
# 다른 주요 노드들(BattleGrid, Character, GameManager) 사이의 상호작용을 조율합니다.
#
# [주요 기능]
# 1. 노드 관리: BattleGrid, Camera, UI 요소 등 씬 내의 주요 노드들을 참조하고 제어합니다.
# 2. 상태 관리: `ActionMode` 열거형을 통해 '이동', '공격' 등 플레이어의 현재 행동 모드를 관리합니다.
# 3. 캐릭터 관리: 캐릭터를 생성하고, 선택하며, 선택된 캐릭터의 정보를 UI에 표시합니다.
# 4. 이벤트 처리: `GameManager`, `BattleGrid`, `Character` 등에서 발생하는 시그널(이벤트)을
#                받아 처리하는 함수(`_on_...`)들을 포함합니다.
# 5. 입력 처리: `_input` 함수를 통해 키보드, 마우스 입력을 받아 카메라를 조작하거나 캐릭터를 선택합니다.
#
# [Godot 학습 팁: @onready 와 노드 경로]
# - `@onready var node = $NodePath` 구문은 씬 트리가 준비되었을 때, 지정된 경로의 노드를
#   찾아 변수에 할당하는 편리한 기능입니다. `$Path`는 `get_node("Path")`의 단축 표현입니다.
# - `$SomeNode`는 이 스크립트가 붙어있는 노드의 직접적인 자식 노드를 의미합니다.
# - `$UI/TurnInfo/TurnLabel` 처럼 경로를 사용하여 자식의 자식 노드에도 접근할 수 있습니다.
# -----------------------------------------------------------------------------
extends Node2D

# [노드 참조]
# @onready 키워드는 씬 트리가 완전히 로드된 후에 변수를 초기화하도록 합니다.
# 이를 통해 스크립트가 실행될 때 노드를 안전하게 참조할 수 있습니다.
@onready var battle_grid: BattleGrid = $BattleGrid # BattleGrid 노드 참조
@onready var characters_node: Node2D = $Characters # 모든 캐릭터 노드들의 부모가 될 노드
@onready var camera: Camera2D = $Camera2D # 씬의 메인 카메라

# [UI 요소 참조]
@onready var turn_label: Label = $UI/TurnInfo/TurnLabel
@onready var turn_counter: Label = $UI/TurnInfo/TurnCounter
@onready var character_name_label: Label = $UI/CharacterInfo/NameLabel
@onready var character_class_label: Label = get_node_or_null("UI/CharacterInfo/ClassLabel")
@onready var character_level_label: Label = $UI/CharacterInfo/LevelLabel
@onready var hp_bar: ProgressBar = $UI/CharacterInfo/HPBar
@onready var mp_bar: ProgressBar = $UI/CharacterInfo/MPBar
@onready var str_label: Label = $UI/CharacterInfo/StrLabel
@onready var def_label: Label = $UI/CharacterInfo/DefLabel
@onready var dex_label: Label = $UI/CharacterInfo/DexLabel
@onready var agi_label: Label = $UI/CharacterInfo/AgiLabel
@onready var int_label: Label = $UI/CharacterInfo/IntLabel
@onready var res_label: Label = $UI/CharacterInfo/ResLabel
@onready var move_button: Button = $UI/ActionPanel/MoveButton
@onready var attack_button: Button = $UI/ActionPanel/AttackButton
@onready var skill_button: Button = $UI/ActionPanel/SkillButton
@onready var end_turn_button: Button = $UI/ActionPanel/EndTurnButton

# [동적 UI 요소]
# 코드로 생성되므로 @onready를 사용하지 않습니다.
var tile_info_panel: Panel
var tile_coord_label: Label
var tile_terrain_label: Label
var tile_height_label: Label

# [게임 상태 변수]
var player_characters: Array[Character] = [] # 아군 캐릭터 객체 목록
var enemy_characters: Array[Character] = []  # 적군 캐릭터 객체 목록
var all_characters: Array[Character] = []    # 모든 캐릭터 객체 목록
var selected_character: Character = null     # 현재 선택된 캐릭터
var highlighted_tiles: Array = []            # 현재 하이라이트된 타일들

# [액션 모드]
# 플레이어의 현재 행동 상태를 관리하는 열거형(Enum)입니다.
enum ActionMode {
	NONE,   # 기본 상태 (캐릭터 선택 가능)
	MOVE,   # 이동 모드
	ATTACK, # 공격 모드
	SKILL   # 스킬 사용 모드
}
var action_mode: ActionMode = ActionMode.NONE # 현재 액션 모드

# [카메라 관련 변수]
var camera_speed: float = 500.0      # 카메라 이동 속도
var camera_zoom_speed: float = 0.1   # 카메라 줌 속도
var min_zoom: float = 0.3            # 최소 줌
var max_zoom: float = 2.0            # 최대 줌
var edge_scroll_enabled: bool = true # 화면 가장자리 스크롤 기능 활성화 여부
var edge_scroll_zone: float = 50.0   # 화면 가장자리 감지 영역 (픽셀)
var edge_scroll_speed: float = 400.0 # 가장자리 스크롤 속도

# Godot 엔진이 이 노드를 씬 트리에 추가할 때 자동으로 호출하는 내장 함수입니다.
func _ready():
	print("BattleScene 초기화 시작")
	setup_tile_info_ui()
	connect_signals()
	start_test_battle()

## Godot 엔진이 매 프레임마다 입력을 처리하기 위해 호출하는 내장 함수입니다.
## `_unhandled_input` 보다 먼저 호출됩니다.
func _input(event):
	# E 키로 화면 가장자리 스크롤 기능을 켜고 끕니다.
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		edge_scroll_enabled = !edge_scroll_enabled
		print("화면 가장자리 스크롤: ", "켜짐" if edge_scroll_enabled else "꺼짐")
		return # 이벤트를 처리했으므로 여기서 함수 종료
	
	# 마우스 휠로 카메라 줌을 조절합니다.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(1.0 + camera_zoom_speed)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(1.0 - camera_zoom_speed)
			return
	
	# 마우스 왼쪽 버튼 클릭을 처리합니다.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		print("BattleScene _input 호출됨: ", mouse_pos)
		print("현재 액션 모드: ", ActionMode.keys()[action_mode])
		
		# 기본 상태(NONE)일 때만 캐릭터 선택을 시도합니다.
		if action_mode == ActionMode.NONE:
			if handle_character_selection(mouse_pos):
				# 캐릭터 선택에 성공하면, 이 클릭 이벤트가 다른 노드(예: BattleGrid)로
				# 전달되지 않도록 '소비' 처리합니다.
				get_viewport().set_input_as_handled()
				return
		else:
			print("액션 모드가 NONE이 아님 - 캐릭터 선택 처리 안 함")

## Godot 엔진이 매 프레임마다 호출하는 내장 함수입니다. 게임 로직 업데이트에 사용됩니다.
func _process(delta):
	handle_camera_movement(delta)

## 게임 내 다른 객체들과의 시그널(이벤트) 연결을 설정합니다.
func connect_signals():
	# GameManager의 시그널에 이 씬의 함수들을 연결합니다.
	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.battle_started.connect(_on_battle_started)
	GameManager.battle_ended.connect(_on_battle_ended)
	
	# BattleGrid의 시그널에 이 씬의 함수들을 연결합니다.
	if battle_grid and battle_grid.has_signal("tile_clicked"):
		battle_grid.tile_clicked.connect(_on_tile_clicked)
	else:
		print("WARNING: battle_grid의 tile_clicked 신호를 찾을 수 없습니다.")
	
	if battle_grid and battle_grid.has_signal("tile_hovered"):
		battle_grid.tile_hovered.connect(_on_tile_hovered)
	else:
		print("WARNING: battle_grid의 tile_hovered 신호를 찾을 수 없습니다.")
	
	# UI 버튼들의 'pressed' 시그널에 각각의 핸들러 함수를 연결합니다.
	move_button.pressed.connect(_on_move_button_pressed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	skill_button.pressed.connect(_on_skill_button_pressed)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)

## 테스트용 전투를 시작합니다.
func start_test_battle():
	create_test_characters()
	
	# 생성된 캐릭터 데이터를 GameManager에 전달하여 전투를 공식적으로 시작합니다.
	var player_data = []
	var enemy_data = []
	for character in player_characters:
		player_data.append(character_to_data(character))
	for character in enemy_characters:
		enemy_data.append(character_to_data(character))
	
	GameManager.start_battle(player_data, enemy_data)
	
	# `await get_tree().process_frame`은 다음 프레임까지 대기하는 역할을 합니다.
	# 모든 노드가 초기화된 후 UI를 업데이트하기 위해 사용됩니다.
	await get_tree().process_frame
	update_character_info()
	
	create_camera_instructions()

## 테스트용 플레이어 및 적 캐릭터 데이터를 정의하고 생성합니다.
func create_test_characters():
	# 플레이어 캐릭터 데이터 정의...
	var elena_data = { "name": "Elena", "class": "Knight", "level": 12, "stats": {"STR": 18, "DEF": 14, "DEX": 9, "AGI": 8, "INT": 7, "RES": 8}, "aptitude": {"Sword": "A", "Lance": "S"}, "skills": ["Slash", "Guard", "Charge"], "position": Vector2i(20, 25) }
	var mira_data = { "name": "Mira", "class": "Mage", "level": 14, "stats": {"STR": 5, "DEF": 6, "DEX": 9, "AGI": 10, "INT": 18, "RES": 14}, "aptitude": {"Staff": "S", "Magic": "S"}, "skills": ["Fireball", "MagicShield"], "position": Vector2i(18, 27) }
	var finn_data = { "name": "Finn", "class": "Archer", "level": 10, "stats": {"STR": 9, "DEF": 7, "DEX": 15, "AGI": 13, "INT": 5, "RES": 6}, "aptitude": {"Bow": "S", "Crossbow": "B"}, "skills": ["ArrowShot", "DoubleShot"], "position": Vector2i(22, 23) }
	
	# 적 캐릭터 데이터 정의...
	var enemy1_data = { "name": "적 병사", "class": "Soldier", "level": 8, "stats": {"STR": 12, "DEF": 10, "DEX": 8, "AGI": 7, "INT": 5, "RES": 6}, "aptitude": {"Sword": "B"}, "skills": ["Slash", "Guard"], "position": Vector2i(7, 3) }
	var enemy2_data = { "name": "적 궁수", "class": "Archer", "level": 9, "stats": {"STR": 8, "DEF": 6, "DEX": 13, "AGI": 11, "INT": 6, "RES": 5}, "aptitude": {"Bow": "A"}, "skills": ["ArrowShot"], "position": Vector2i(8, 5) }
	
	# 캐릭터 인스턴스를 생성하고 배열에 추가합니다.
	player_characters = [ create_character_instance(elena_data, true), create_character_instance(mira_data, true), create_character_instance(finn_data, true) ]
	enemy_characters = [ create_character_instance(enemy1_data, false), create_character_instance(enemy2_data, false) ]
	all_characters = player_characters + enemy_characters
	
	print("테스트 캐릭터들이 생성되었습니다.")

## 데이터로부터 하나의 캐릭터 인스턴스를 생성하고 씬에 배치합니다.
func create_character_instance(data: Dictionary, is_player: bool) -> Character:
	print("캐릭터 생성 시작: ", data["name"])
	
	# 1. Character 클래스의 새 인스턴스를 만듭니다.
	var character = Character.new()
	if not character:
		print("ERROR: Character 생성 실패!")
		return null
	
	character.is_player_controlled = is_player
	
	# 2. 씬 트리의 'Characters' 노드 아래에 추가합니다.
	characters_node.add_child(character)
	
	# 3. 데이터로 캐릭터의 속성을 초기화합니다.
	character.initialize_character(data)
	
	# 4. 그리드 좌표를 실제 화면(월드) 좌표로 변환하여 배치합니다.
	var grid_pos = data["position"]
	var world_pos = battle_grid.grid_to_world(grid_pos)
	
	# 5. 타일의 높이를 가져와 캐릭터의 y좌표를 조정하여 입체감을 줍니다.
	var height = battle_grid.get_height_at_position(grid_pos)
	var final_pos = battle_grid.position + world_pos
	final_pos.y -= height * 15 # 높이 1당 15픽셀씩 위로 이동
	character.position = final_pos
	
	# 6. 캐릭터의 시각적 표현(몸체, 그림자, 이름표 등)을 생성합니다.
	create_isometric_character_visual(character, is_player, data)
	
	print("캐릭터 ", data["name"], " 생성 완료 - 위치: ", grid_pos, " -> ", world_pos, " (높이: ", height, ")")
	
	# 7. 캐릭터의 시그널에 핸들러 함수를 연결합니다.
	if character.character_died and not character.character_died.is_connected(_on_character_died):
		character.character_died.connect(_on_character_died)
	if character.health_changed and not character.health_changed.is_connected(_on_character_health_changed):
		character.health_changed.connect(_on_character_health_changed)
	
	return character

## 캐릭터의 시각적 요소를 코드로 생성하여 붙입니다. (스프라이트 대신 Polygon2D 사용)
func create_isometric_character_visual(character: Character, is_player: bool, data: Dictionary):
	var character_container = Node2D.new()
	character_container.name = "Visual"
	
	var body = create_character_body(is_player)
	character_container.add_child(body)
	
	var shadow = create_character_shadow()
	character_container.add_child(shadow)
	
	var label = Label.new()
	label.text = data["name"]
	label.position = Vector2(-25, -35)
	label.add_theme_color_override("font_color", Color.WHITE)
	# ... (라벨 스타일 설정)
	character_container.add_child(label)
	
	var hp_bar = create_character_hp_bar()
	hp_bar.name = "HP_Container"
	character_container.add_child(hp_bar)
	
	character.add_child(character_container)

## 캐릭터의 몸체를 나타내는 이소메트릭 타원(Polygon2D)을 생성합니다.
func create_character_body(is_player: bool) -> Node2D:
	var body_container = Node2D.new()
	var body = Polygon2D.new()
	var points = PackedVector2Array()
	
	for i in range(16):
		var angle = i * PI * 2 / 16
		var x = cos(angle) * 12
		var y = sin(angle) * 6
		points.append(Vector2(x, y - 10))
	
	body.polygon = points
	body.color = Color.BLUE if is_player else Color.RED
	
	var outline = Line2D.new()
	# ... (테두리 설정)
	
	body_container.add_child(body)
	body_container.add_child(outline)
	return body_container

## 캐릭터의 그림자를 생성합니다.
func create_character_shadow() -> Polygon2D:
	# ... (그림자 생성 로직)
	return Polygon2D.new()

## 캐릭터 머리 위에 표시될 HP 바를 생성합니다.
func create_character_hp_bar() -> Node2D:
	# ... (HP 바 생성 로직)
	return Node2D.new()

## Character 객체를 GameManager에 전달할 데이터(Dictionary) 형태로 변환합니다.
func character_to_data(character: Character) -> Dictionary:
	if not character: return {}
	return {
		"name": character.character_name, "class": character.current_class, "level": character.level,
		"stats": character.current_stats, "aptitude": character.aptitudes, "skills": character.learned_skills
	}

## 카메라 이동 로직을 처리합니다.
func handle_camera_movement(delta):
	# ... (WASD, 화살표 키, 화면 가장자리 스크롤 처리)
	pass

## 카메라 줌 로직을 처리합니다.
func zoom_camera(zoom_factor: float):
	# ... (줌 인/아웃 및 최대/최소 줌 제한)
	pass

## 화면 가장자리 스크롤 로직을 처리합니다.
func handle_edge_scroll(delta: float) -> Vector2:
	# ... (마우스 위치에 따른 카메라 이동 벡터 계산)
	return Vector2.ZERO

## 카메라 조작법 안내 UI를 생성합니다.
func create_camera_instructions():
	# ... (Panel, Label 등을 코드로 생성하여 안내문 표시)
	pass

## 마우스 클릭 위치에 있는 캐릭터를 찾아 선택합니다.
func handle_character_selection(mouse_pos: Vector2) -> bool:
	print("캐릭터 선택 처리: ", mouse_pos)
	for character in all_characters:
		if character.is_player_controlled:
			# 캐릭터의 위치를 중심으로 사각형 영역(Rect2)을 만들어 클릭 지점이 포함되는지 확인합니다.
			var char_rect = Rect2(character.global_position - Vector2(16, 16), Vector2(32, 32))
			if char_rect.has_point(mouse_pos):
				print("캐릭터 클릭됨: ", character.character_name)
				select_character(character)
				return true
	
	print("선택된 캐릭터가 없습니다.")
	return false

## 특정 캐릭터를 선택하고 관련 UI 및 하이라이트를 업데이트합니다.
func select_character(character: Character):
	if selected_character:
		clear_highlights()
		clear_character_selection_visual()
	
	selected_character = character
	update_character_info()
	show_character_selection_visual(character)
	
	# 선택된 캐릭터의 이동 가능 범위를 자동으로 표시합니다.
	if selected_character and selected_character.is_player_controlled:
		var reachable = battle_grid.get_reachable_tiles(selected_character.grid_position, selected_character.move_range)
		if reachable.size() > 0:
			battle_grid.highlight_tiles(reachable, Color(0.2, 0.8, 0.2, 0.6)) # 이동 범위는 녹색으로 표시
		else:
			print("이동 가능한 타일이 없습니다!")
	
	print(character.character_name, " 선택됨")

## 선택된 캐릭터의 정보를 UI 패널에 업데이트합니다.
func update_character_info():
	# ... (선택된 캐릭터가 있으면 이름, 레벨, HP, MP, 스탯 등을 UI 라벨과 프로그레스바에 반영)
	pass

## UI의 스탯 라벨들을 업데이트합니다.
func update_stat_labels():
	# ... (STR, DEF 등 각 스탯 라벨의 텍스트를 업데이트)
	pass

## UI의 스탯 라벨들을 초기 상태로 리셋합니다.
func reset_stat_labels():
	# ... (모든 스탯 라벨을 "-"로 표시)
	pass

## 모든 타일 하이라이트를 제거합니다.
func clear_highlights():
	highlighted_tiles.clear()
	battle_grid.clear_highlights()

## 특정 타일들에 하이라이트를 표시합니다.
func highlight_tiles(tiles: Array, color: Color = Color.YELLOW):
	clear_highlights()
	highlighted_tiles = tiles
	battle_grid.highlight_tiles(tiles, color)

## 선택된 캐릭터임을 나타내는 시각적 효과(링, 화살표)를 표시합니다.
func show_character_selection_visual(character: Character):
	# ... (ColorRect와 Label을 코드로 생성하여 캐릭터의 자식으로 추가)
	pass

## 캐릭터 선택 시각적 효과를 제거합니다.
func clear_character_selection_visual():
	# ... (이전에 추가했던 링과 화살표 노드를 찾아서 queue_free()로 제거)
	pass

## 선택 링의 테두리 스타일(StyleBoxFlat)을 생성합니다.
func create_selection_border() -> StyleBoxFlat:
	# ... (노란색 테두리를 가진 StyleBoxFlat 리소스 생성)
	return StyleBoxFlat.new()

# --- 시그널 핸들러 함수들 ---
# 함수의 이름이 `_on_노드이름_시그널이름` 규칙을 따릅니다.
# 이는 Godot 에디터에서 시그널을 연결할 때 자동으로 생성되는 이름 형식입니다.

## BattleGrid의 `tile_clicked` 시그널이 발생했을 때 호출됩니다.
func _on_tile_clicked(grid_pos: Vector2i, terrain_name: String):
	print("타일 클릭됨: ", grid_pos, " (", terrain_name, ")")
	print("현재 액션 모드: ", ActionMode.keys()[action_mode])
	
	# 현재 액션 모드에 따라 다른 동작을 수행합니다.
	match action_mode:
		ActionMode.MOVE:
			# 이동 모드일 때: 선택된 캐릭터를 해당 타일로 이동시킵니다.
			if selected_character and selected_character.is_player_controlled:
				if selected_character.move_to(grid_pos, battle_grid):
					# 이동 성공 시, 액션 모드를 초기화하고 하이라이트를 제거합니다.
					action_mode = ActionMode.NONE
					clear_highlights()
					update_character_info()
		
		ActionMode.ATTACK:
			# 공격 모드일 때: 해당 타일에 있는 적을 공격합니다.
			if selected_character and selected_character.is_player_controlled:
				var target = get_character_at_position(grid_pos)
				if target and not target.is_player_controlled:
					perform_attack(selected_character, target)
					action_mode = ActionMode.NONE
					clear_highlights()
		
		ActionMode.SKILL:
			# 스킬 모드일 때: 해당 타일에 스킬을 사용합니다.
			# ... (스킬 사용 로직)
			pass
		
		ActionMode.NONE:
			# 기본 상태에서는 아무것도 하지 않습니다.
			pass

## 특정 그리드 좌표에 있는 캐릭터 객체를 찾아 반환합니다.
func get_character_at_position(grid_pos: Vector2i) -> Character:
	for character in all_characters:
		if character.grid_position == grid_pos:
			return character
	return null

## 공격을 수행합니다.
func perform_attack(attacker: Character, target: Character):
	var skill_name = "Slash"
	if skill_name in attacker.learned_skills:
		# GameManager에 데미지 계산을 요청합니다.
		var damage = GameManager.calculate_damage(
			character_to_data(attacker), character_to_data(target),
			skill_name, battle_grid.get_terrain_at_position(target.grid_position)
		)
		target.take_damage(damage)
		attacker.has_acted = true
		print(attacker.character_name, "이(가) ", target.character_name, "을(를) 공격! ", damage, " 데미지!")
		update_character_info()

## '이동' 버튼을 눌렀을 때 호출됩니다.
func _on_move_button_pressed():
	if selected_character and not selected_character.has_moved:
		action_mode = ActionMode.MOVE
		var reachable = battle_grid.get_reachable_tiles(selected_character.grid_position, selected_character.move_range)
		highlight_tiles(reachable, Color(0.2, 0.8, 0.2, 0.6))
		print("이동 모드 활성화")

## '공격' 버튼을 눌렀을 때 호출됩니다.
func _on_attack_button_pressed():
	if selected_character and not selected_character.has_acted:
		action_mode = ActionMode.ATTACK
		var attackable = battle_grid.get_attack_range(selected_character.grid_position, 1) # 기본 사거리 1
		highlight_tiles(attackable, Color(1.0, 0.2, 0.2, 0.6)) # 공격 범위는 붉은색으로 표시
		print("공격 모드 활성화")

## '스킬' 버튼을 눌렀을 때 호출됩니다.
func _on_skill_button_pressed():
	if selected_character and not selected_character.has_acted and selected_character.learned_skills.size() > 0:
		action_mode = ActionMode.SKILL
		var skill_name = selected_character.learned_skills[0]
		var skill_data = GameData.SKILLS[skill_name]
		var skill_range = battle_grid.get_attack_range(selected_character.grid_position, skill_data["range"])
		highlight_tiles(skill_range, Color(0.8, 0.2, 1.0, 0.6)) # 스킬 범위는 보라색으로 표시
		print("스킬 모드 활성화: ", skill_name)

## '턴 종료' 버튼을 눌렀을 때 호출됩니다.
func _on_end_turn_button_pressed():
	if GameManager.current_phase != GameManager.TurnPhase.PLAYER_TURN:
		print("현재 플레이어 턴이 아닙니다!")
		return
	
	GameManager.next_turn()
	action_mode = ActionMode.NONE
	clear_highlights()
	clear_character_selection_visual()
	
	for character in player_characters:
		character.end_turn()
	print("플레이어 턴 종료됨")

## GameManager의 `turn_changed` 시그널에 의해 호출됩니다.
func _on_turn_changed(current_turn):
	print("턴 변경됨: ", GameManager.TurnPhase.keys()[current_turn])
	match current_turn:
		GameManager.TurnPhase.PLAYER_TURN:
			turn_label.text = "플레이어 턴"
			for character in player_characters:
				character.has_moved = false
				character.has_acted = false
		GameManager.TurnPhase.ENEMY_TURN:
			turn_label.text = "적 턴"
			for character in enemy_characters:
				character.has_moved = false
				character.has_acted = false
			process_enemy_turn() # AI 턴 처리 시작
		GameManager.TurnPhase.ENVIRONMENT_TURN:
			turn_label.text = "환경 턴"
			await get_tree().create_timer(1.0).timeout
			GameManager.next_turn()
	
	turn_counter.text = "턴: " + str(GameManager.turn_count)
	update_character_info()

## GameManager의 `battle_started` 시그널에 의해 호출됩니다.
func _on_battle_started():
	print("전투 시작!")

## GameManager의 `battle_ended` 시그널에 의해 호출됩니다.
func _on_battle_ended():
	print("전투 종료!")

## Character의 `character_died` 시그널에 의해 호출됩니다.
func _on_character_died(character: Character):
	all_characters.erase(character)
	if character.is_player_controlled:
		player_characters.erase(character)
	else:
		enemy_characters.erase(character)
	
	# 승리/패배 조건 확인
	if enemy_characters.size() == 0:
		GameManager.end_battle(true)
	elif player_characters.size() == 0:
		GameManager.end_battle(false)

## Character의 `health_changed` 시그널에 의해 호출됩니다.
func _on_character_health_changed(character: Character, new_health: int, max_health: int):
	# 캐릭터 머리 위의 HP 바를 업데이트합니다.
	var visual_node = character.get_node_or_null("Visual")
	if visual_node:
		var hp_bar_rect = visual_node.get_node_or_null("HP_Container/HPBar") as ColorRect
		if hp_bar_rect:
			var hp_percentage = float(new_health) / float(max_health)
			hp_bar_rect.size.x = 28 * hp_percentage
			# ... (HP에 따른 색상 변경)
	
	if character == selected_character:
		update_character_info()

## 적의 턴을 처리하는 간단한 AI 로직입니다.
func process_enemy_turn():
	print("적 턴 처리 시작")
	await get_tree().create_timer(1.0).timeout
	
	for enemy in enemy_characters:
		if enemy.current_health > 0:
			# 가장 가까운 플레이어를 찾아 이동 후 공격하는 단순한 AI
			var closest_player = find_closest_player(enemy)
			if closest_player:
				var distance = enemy.grid_position.distance_to(closest_player.grid_position)
				if distance <= 1:
					perform_attack(enemy, closest_player)
				else:
					move_enemy_towards_target(enemy, closest_player)
		
		enemy.end_turn()
		await get_tree().create_timer(0.5).timeout
	
	print("적 턴 완료 - 플레이어 턴으로 전환")
	GameManager.next_turn()

## 적에게서 가장 가까운 플레이어를 찾습니다.
func find_closest_player(enemy: Character) -> Character:
	# ... (거리 계산 로직)
	return null

## 적을 목표(플레이어)를 향해 이동시킵니다.
func move_enemy_towards_target(enemy: Character, target: Character):
	# ... (최적의 이동 경로 탐색 로직)
	pass

## 마우스 호버 시 타일 정보를 표시할 UI를 생성합니다.
func setup_tile_info_ui():
	# ... (Panel, VBoxContainer, Label 등을 코드로 생성하여 UI 구성)
	pass

## BattleGrid의 `tile_hovered` 시그널에 의해 호출됩니다.
func _on_tile_hovered(grid_pos: Vector2i, terrain_name: String, height: int):
	tile_coord_label.text = "좌표: (%d, %d)" % [grid_pos.x, grid_pos.y]
	tile_terrain_label.text = "지형: " + get_korean_terrain_name(terrain_name)
	tile_height_label.text = "높이: " + str(height)
	tile_info_panel.show()

## 지형의 영어 이름을 한글 이름으로 변환합니다.
func get_korean_terrain_name(terrain_name: String) -> String:
	var korean_names = {
		"Plain": "평지", "Mountain": "산", "Forest": "숲", "Swamp": "늪",
		"Desert": "사막", "RockyTerrain": "바위", "BurningGround": "불타는 땅",
		"FrozenGround": "얼어붙은 땅"
	}
	return korean_names.get(terrain_name, terrain_name)
