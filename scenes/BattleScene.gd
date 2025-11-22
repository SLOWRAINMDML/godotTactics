extends Node2D

# 노드 참조
@onready var battle_grid = $BattleGrid
@onready var characters_node: Node2D = $Characters
@onready var camera: Camera2D = $Camera2D

# UI 요소들
@onready var turn_label: Label = $UI/TurnInfo/TurnLabel
@onready var turn_counter: Label = $UI/TurnInfo/TurnCounter
@onready var character_name_label: Label = $UI/CharacterInfo/NameLabel
@onready var character_class_label: Label = get_node_or_null("UI/CharacterInfo/ClassLabel")
@onready var character_level_label: Label = $UI/CharacterInfo/LevelLabel
@onready var hp_bar: ProgressBar = $UI/CharacterInfo/HPBar
@onready var mp_bar: ProgressBar = $UI/CharacterInfo/MPBar

# 스탯 라벨들
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

# 타일 정보 UI 요소들
var tile_info_panel: Panel
var tile_coord_label: Label
var tile_terrain_label: Label
var tile_height_label: Label

# 행동 순서 UI
var turn_order_panel: Panel
var turn_order_vbox: VBoxContainer
var final_turn_order: Array

# 게임 상태
var player_characters: Array = []
var enemy_characters: Array = []
var all_characters: Array = []
var selected_character: Character = null # 정보창에 표시될 캐릭터
var current_turn_character: Character = null # 턴의 주인공
var current_action_mode: String = "none"  # none, move, attack, skill
var highlighted_tiles: Array = []
var previous_selection: Character = null # 시각 효과 제어용

# 액션 모드
enum ActionMode {
	NONE,
	MOVE,
	ATTACK,
	SKILL
}

var action_mode: ActionMode = ActionMode.NONE

# 카메라 이동 관련
var camera_speed: float = 500.0
var camera_zoom_speed: float = 0.1
var min_zoom: float = 0.3
var max_zoom: float = 2.0

# 화면 가장자리 스크롤 관련
var edge_scroll_enabled: bool = true
var edge_scroll_zone: float = 50.0  # 화면 가장자리 감지 영역 (픽셀)
var edge_scroll_speed: float = 400.0  # 가장자리 스크롤 속도

func _ready():
	print("BattleScene 초기화 시작")
	
	# UI 생성
	setup_tile_info_ui()
	setup_turn_order_ui()
	
	# 신호 연결
	connect_signals()
	
	# 테스트 전투 시작
	start_test_battle()

func _input(event):
	# 화면 가장자리 스크롤 토글 (E 키)
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		edge_scroll_enabled = !edge_scroll_enabled
		print("화면 가장자리 스크롤: ", "켜짐" if edge_scroll_enabled else "꺼짐")
		return
	
	# 카메라 줌 처리
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(1.0 + camera_zoom_speed)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(1.0 - camera_zoom_speed)
			return
			
	# 마우스 클릭으로 캐릭터 정보 보기
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var clicked_on_character = false
		for character in all_characters:
			var char_rect = Rect2(character.global_position - Vector2(16, 16), Vector2(32, 32))
			if char_rect.has_point(mouse_pos):
				print("정보 보기 위해 클릭: ", character.character_name)
				select_character_for_display(character)
				clicked_on_character = true
				get_viewport().set_input_as_handled()
				break
		# 캐릭터를 클릭하지 않았을 때만 타일 클릭 로직 실행
		if not clicked_on_character:
			# 타일 클릭 이벤트는 BattleGrid에서 신호로 처리됨
			pass

func _process(delta):
	handle_camera_movement(delta)

func connect_signals():
	# GameManager 신호 연결
	GameManager.turn_order_updated.connect(_on_turn_order_updated)
	GameManager.turn_advanced.connect(_on_turn_advanced)
	GameManager.battle_started.connect(_on_battle_started)
	GameManager.battle_ended.connect(_on_battle_ended)
	
	# BattleGrid 신호 연결 (안전하게)
	if battle_grid and battle_grid.has_signal("tile_clicked"):
		battle_grid.tile_clicked.connect(_on_tile_clicked)
	else:
		print("WARNING: battle_grid의 tile_clicked 신호를 찾을 수 없습니다.")
	
	if battle_grid and battle_grid.has_signal("tile_hovered"):
		battle_grid.tile_hovered.connect(_on_tile_hovered)
	else:
		print("WARNING: battle_grid의 tile_hovered 신호를 찾을 수 없습니다.")
	
	# UI 버튼 연결
	move_button.pressed.connect(_on_move_button_pressed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	skill_button.pressed.connect(_on_skill_button_pressed)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)

func start_test_battle():
	# 테스트용 캐릭터 생성
	create_test_characters()
	
	# GameManager에 전투 시작 알림 (캐릭터 노드 자체를 전달)
	GameManager.start_battle(all_characters)
	
	# UI 초기 업데이트 (선택된 캐릭터가 없으므로 빈 상태로 업데이트)
	await get_tree().process_frame
	update_character_info_display(null)
	update_action_buttons()
	
	# 카메라 조작 안내 추가
	create_camera_instructions()

func create_test_characters():
	# 플레이어 캐릭터들
	var elena_data = {
		"name": "Elena",
		"class": "Knight",
		"level": 12,
		"stats": {"STR": 18, "DEF": 14, "DEX": 9, "AGI": 8, "INT": 7, "RES": 8},
		"aptitude": {"Sword": "A", "Lance": "S"},
		"skills": ["Slash", "Guard", "Charge"],
		"position": Vector2i(20, 25)
	}
	
	var mira_data = {
		"name": "Mira",
		"class": "Mage",
		"level": 14,
		"stats": {"STR": 5, "DEF": 6, "DEX": 9, "AGI": 10, "INT": 18, "RES": 14},
		"aptitude": {"Staff": "S", "Magic": "S"},
		"skills": ["Fireball", "MagicShield"],
		"position": Vector2i(18, 27)
	}
	
	var finn_data = {
		"name": "Finn",
		"class": "Archer",
		"level": 10,
		"stats": {"STR": 9, "DEF": 7, "DEX": 15, "AGI": 13, "INT": 5, "RES": 6},
		"aptitude": {"Bow": "S", "Crossbow": "B"},
		"skills": ["ArrowShot", "DoubleShot"],
		"position": Vector2i(22, 23)
	}
	
	# 적 캐릭터들 (맵 안 위치로 수정)
	var enemy1_data = {
		"name": "적 병사",
		"class": "Soldier",
		"level": 8,
		"stats": {"STR": 12, "DEF": 10, "DEX": 8, "AGI": 7, "INT": 5, "RES": 6},
		"aptitude": {"Sword": "B"},
		"skills": ["Slash", "Guard"],
		"position": Vector2i(7, 3)  # 맵 안쪽으로 이동
	}
	
	var enemy2_data = {
		"name": "적 궁수",
		"class": "Archer",
		"level": 9,
		"stats": {"STR": 8, "DEF": 6, "DEX": 13, "AGI": 11, "INT": 6, "RES": 5},
		"aptitude": {"Bow": "A"},
		"skills": ["ArrowShot"],
		"position": Vector2i(8, 5)  # 맵 안쪽으로 이동
	}
	
	# 캐릭터 인스턴스 생성
	player_characters = [
		create_character_instance(elena_data, true),
		create_character_instance(mira_data, true),
		create_character_instance(finn_data, true)
	]
	
	enemy_characters = [
		create_character_instance(enemy1_data, false),
		create_character_instance(enemy2_data, false)
	]
	
	all_characters = player_characters + enemy_characters
	
	print("테스트 캐릭터들이 생성되었습니다.")

func create_character_instance(data: Dictionary, is_player: bool) -> Character:
	print("캐릭터 생성 시작: ", data["name"])
	
	# Character 인스턴스 생성
	var character = Character.new()
	if not character:
		print("ERROR: Character 생성 실패!")
		return null
	
	character.is_player_controlled = is_player
	
	# 캐릭터를 씬에 먼저 추가
	characters_node.add_child(character)
	
	# 캐릭터 데이터 초기화
	character.initialize_character(data)
	
	# 그리드 위치에 배치 (높이 반영)
	var grid_pos = data["position"]
	var world_pos = battle_grid.grid_to_world(grid_pos)
	
	# 높이 반영 (BattleGrid에서 높이 데이터 가져오기)
	var height = 0
	if battle_grid and battle_grid.has_method("get_height_at_position"):
		height = battle_grid.get_height_at_position(grid_pos)
	
	# BattleGrid의 위치를 더해주고, 높이만큼 위로 올리기
	var final_pos = battle_grid.position + world_pos
	final_pos.y -= height * 15
	character.position = final_pos
	
	# 이소메트릭 캐릭터 시각적 표현
	create_isometric_character_visual(character, is_player, data)
	
	print("캐릭터 ", data["name"], " 생성 완료 - 위치: ", grid_pos, " -> ", world_pos, " (높이: ", height, ")")
	print("DEBUG: 실제 전달된 위치 데이터: ", data["position"])
	print("DEBUG: 캐릭터의 grid_position: ", character.grid_position)
	
	# 신호 연결 (안전하게)
	if character.character_died and not character.character_died.is_connected(_on_character_died):
		character.character_died.connect(_on_character_died)
	if character.health_changed and not character.health_changed.is_connected(_on_character_health_changed):
		character.health_changed.connect(_on_character_health_changed)
	
	return character

func create_isometric_character_visual(character: Character, is_player: bool, data: Dictionary):
	var character_container = Node2D.new()
	character_container.name = "Visual"
	
	# 캐릭터 바디 (원형에서 이소메트릭 타원으로)
	var body = create_character_body(is_player)
	character_container.add_child(body)
	
	# 그림자
	var shadow = create_character_shadow()
	character_container.add_child(shadow)
	
	# 이름 라벨
	var label = Label.new()
	label.text = data["name"]
	label.position = Vector2(-25, -35)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 12)
	character_container.add_child(label)
	
	# HP 바
	var hp_bar = create_character_hp_bar()
	hp_bar.name = "HP_Container"
	character_container.add_child(hp_bar)
	
	character.add_child(character_container)

func create_character_body(is_player: bool) -> Node2D:
	var body_container = Node2D.new()
	
	# 메인 바디 (이소메트릭 타원)
	var body = Polygon2D.new()
	var points = PackedVector2Array()
	
	# 이소메트릭 타원 점들 생성
	for i in range(16):
		var angle = i * PI * 2 / 16
		var x = cos(angle) * 12  # 가로 반지름
		var y = sin(angle) * 6   # 세로 반지름 (이소메트릭 압축)
		points.append(Vector2(x, y - 10))  # 약간 위로
	
	body.polygon = points
	body.color = Color.BLUE if is_player else Color.RED
	
	# 테두리
	var outline = Line2D.new()
	outline.width = 2.0
	outline.default_color = Color.BLACK
	outline.closed = true
	for point in points:
		outline.add_point(point)
	
	body_container.add_child(body)
	body_container.add_child(outline)
	
	return body_container

func create_character_shadow() -> Polygon2D:
	var shadow = Polygon2D.new()
	var points = PackedVector2Array()
	
	# 바닥 그림자 (타원형)
	for i in range(12):
		var angle = i * PI * 2 / 12
		var x = cos(angle) * 8
		var y = sin(angle) * 4
		points.append(Vector2(x, y + 5))  # 바닥에
	
	shadow.polygon = points
	shadow.color = Color(0, 0, 0, 0.3)  # 반투명 검정
	
	return shadow

func create_character_hp_bar() -> Node2D:
	var hp_container = Node2D.new()
	
	# HP 바 배경
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(30, 4)
	hp_bg.position = Vector2(-15, -25)
	hp_bg.color = Color.BLACK
	hp_container.add_child(hp_bg)
	
	# HP 바
	var hp_bar = ColorRect.new()
	hp_bar.name = "HPBar"
	hp_bar.size = Vector2(28, 2)
	hp_bar.position = Vector2(-14, -24)
	hp_bar.color = Color.GREEN
	hp_container.add_child(hp_bar)
	
	return hp_container

func character_to_data(character: Character) -> Dictionary:
	if not character:
		print("WARNING: character_to_data에서 null 캐릭터 전달됨")
		return {}
	
	return {
		"name": character.character_name if character.character_name else "Unknown",
		"class": character.current_class if character.current_class else "Fighter",
		"level": character.level if character.level else 1,
		"stats": character.current_stats if character.current_stats else {},
		"aptitude": character.aptitudes if character.aptitudes else {},
		"skills": character.learned_skills if character.learned_skills else []
	}

func handle_camera_movement(delta):
	var movement = Vector2.ZERO
	
	# WASD 또는 화살표 키로 카메라 이동
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		movement.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		movement.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		movement.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		movement.y += 1
	
	# 화면 가장자리 마우스 스크롤 처리
	if edge_scroll_enabled:
		var edge_movement = handle_edge_scroll(delta)
		movement += edge_movement
	
	# 카메라 이동 적용
	if movement != Vector2.ZERO:
		movement = movement.normalized() * camera_speed * delta
		var new_position = camera.position + movement
		
		# 맵 경계 체크 (50x35 맵 크기에 맞춘 범위)
		var map_bounds = Rect2(-1000, -1000, 6000, 5000)  # 큰 맵 범위
		new_position.x = clamp(new_position.x, map_bounds.position.x, map_bounds.position.x + map_bounds.size.x)
		new_position.y = clamp(new_position.y, map_bounds.position.y, map_bounds.position.y + map_bounds.size.y)
		
		camera.position = new_position

func zoom_camera(zoom_factor: float):
	var new_zoom = camera.zoom * zoom_factor
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	camera.zoom = new_zoom
	print("카메라 줌: ", camera.zoom)

func handle_edge_scroll(delta: float) -> Vector2:
	var mouse_pos = get_global_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_mouse_pos = get_viewport().get_mouse_position()
	
	var edge_movement = Vector2.ZERO
	
	# 왼쪽 가장자리
	if screen_mouse_pos.x <= edge_scroll_zone:
		var intensity = (edge_scroll_zone - screen_mouse_pos.x) / edge_scroll_zone
		edge_movement.x -= intensity
	
	# 오른쪽 가장자리
	elif screen_mouse_pos.x >= viewport_size.x - edge_scroll_zone:
		var intensity = (screen_mouse_pos.x - (viewport_size.x - edge_scroll_zone)) / edge_scroll_zone
		edge_movement.x += intensity
	
	# 위쪽 가장자리
	if screen_mouse_pos.y <= edge_scroll_zone:
		var intensity = (edge_scroll_zone - screen_mouse_pos.y) / edge_scroll_zone
		edge_movement.y -= intensity
	
	# 아래쪽 가장자리
	elif screen_mouse_pos.y >= viewport_size.y - edge_scroll_zone:
		var intensity = (screen_mouse_pos.y - (viewport_size.y - edge_scroll_zone)) / edge_scroll_zone
		edge_movement.y += intensity
	
	# 대각선 이동시 정규화
	if edge_movement.length() > 1.0:
		edge_movement = edge_movement.normalized()
	
	return edge_movement * (edge_scroll_speed / camera_speed)  # 상대적 속도 조정

func create_camera_instructions():
	# UI 노드가 존재하는지 확인
	var ui_node = get_node("UI")
	if not ui_node:
		print("UI 노드를 찾을 수 없습니다.")
		return
	
	# 카메라 조작 안내 패널 생성
	var instructions_panel = Panel.new()
	instructions_panel.size = Vector2(280, 140)
	instructions_panel.position = Vector2(10, 100)
	instructions_panel.add_theme_color_override("bg_color", Color(0, 0, 0, 0.7))
	
	var instructions_label = Label.new()
	instructions_label.text = """🎮 카메라 조작법:
WASD/화살표: 카메라 이동
마우스 휠: 줌 인/아웃
화면 가장자리: 자동 스크롤
E 키: 가장자리 스크롤 토글

🗺️ 이소메트릭 맵 완성!
크기: 40x30 | 높이: -2~+5"""
	instructions_label.position = Vector2(10, 10)
	instructions_label.size = Vector2(260, 120)
	instructions_label.add_theme_color_override("font_color", Color.WHITE)
	instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	instructions_panel.add_child(instructions_label)
	ui_node.add_child(instructions_panel)

func select_character_for_display(character: Character):
	# 시각적 표시(노란 테두리)는 현재 턴인 캐릭터에게만 유지
	if selected_character and is_instance_valid(selected_character):
		var ring = selected_character.get_node_or_null("SelectionRing")
		if ring: ring.queue_free()
		var arrow = selected_character.get_node_or_null("SelectionArrow")
		if arrow: arrow.queue_free()

	selected_character = character
	update_character_info_display(selected_character)

	# 현재 턴인 캐릭터에게는 항상 시각적 표시
	if is_instance_valid(current_turn_character):
		show_character_selection_visual(current_turn_character)

func update_character_info_display(character: Character):
	if character:
		# UI 요소들이 존재하는지 확인
		if character_name_label:
			character_name_label.text = character.character_name + " Lv." + str(character.level)
		if character_class_label:
			character_class_label.text = "클래스: " + character.current_class
		if hp_bar:
			hp_bar.max_value = character.max_health
			hp_bar.value = character.current_health
		if mp_bar:
			mp_bar.max_value = character.max_mana
			mp_bar.value = character.current_mana
		update_stat_labels(character)
	else:
		# 선택된 캐릭터가 없음 - UI 초기화
		if character_name_label: character_name_label.text = "캐릭터 없음"
		if character_class_label: character_class_label.text = "클래스: 없음"
		if hp_bar: hp_bar.value = 0
		if mp_bar: mp_bar.value = 0
		reset_stat_labels()

func update_action_buttons():
	# 버튼 활성화는 오직 '현재 턴인 캐릭터'를 기준으로 판단
	if not current_turn_character:
		move_button.disabled = true
		attack_button.disabled = true
		skill_button.disabled = true
		end_turn_button.disabled = true
		return

	var can_move = not current_turn_character.has_moved
	var can_use_action = not current_turn_character.has_acted

	move_button.disabled = not can_move
	attack_button.disabled = not can_use_action
	skill_button.disabled = not (can_use_action and current_turn_character.learned_skills.size() > 0)
	end_turn_button.disabled = false # 자기 턴일땐 항상 종료 가능

func update_stat_labels(character: Character):
	if not character:
		reset_stat_labels()
		return
		
	var stats = character.current_stats
	
	if str_label: str_label.text = "STR: " + str(stats.get("STR", 0))
	if def_label: def_label.text = "DEF: " + str(stats.get("DEF", 0))
	if dex_label: dex_label.text = "DEX: " + str(stats.get("DEX", 0))
	if agi_label: agi_label.text = "AGI: " + str(stats.get("AGI", 0))
	if int_label: int_label.text = "INT: " + str(stats.get("INT", 0))
	if res_label: res_label.text = "RES: " + str(stats.get("RES", 0))

func reset_stat_labels():
	if str_label:
		str_label.text = "STR: -"
	if def_label:
		def_label.text = "DEF: -"
	if dex_label:
		dex_label.text = "DEX: -"
	if agi_label:
		agi_label.text = "AGI: -"
	if int_label:
		int_label.text = "INT: -"
	if res_label:
		res_label.text = "RES: -"

func clear_highlights():
	highlighted_tiles.clear()
	battle_grid.clear_highlights()

func highlight_tiles(tiles: Array, color: Color = Color.YELLOW):
	clear_highlights()
	highlighted_tiles = tiles
	battle_grid.highlight_tiles(tiles, color)

func create_selection_border() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.border_color = Color.YELLOW
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.bg_color = Color.TRANSPARENT
	return style

# 신호 핸들러들
func _on_tile_clicked(grid_pos: Vector2i, terrain_name: String):
	print("타일 클릭됨: ", grid_pos, " (", terrain_name, ")")
	print("현재 액션 모드: ", ActionMode.keys()[action_mode])
	
	# 타일 위에 있는 캐릭터 정보 표시
	var char_on_tile = get_character_at_position(grid_pos)
	if char_on_tile:
		select_character_for_display(char_on_tile)
		
	match action_mode:
		ActionMode.MOVE:
			print("이동 모드에서 타일 클릭")
			if current_turn_character and current_turn_character.is_player_controlled:
				print("플레이어 캐릭터로 이동 시도: ", current_turn_character.character_name)
				
				if current_turn_character.move_to(grid_pos, battle_grid):
					print("이동 성공!")
					action_mode = ActionMode.NONE
					clear_highlights()
					update_action_buttons()
				else:
					print("이동 실패!")
		
		ActionMode.ATTACK:
			if current_turn_character and current_turn_character.is_player_controlled:
				var target = get_character_at_position(grid_pos)
				if target and not target.is_player_controlled:
					perform_attack(current_turn_character, target)
					action_mode = ActionMode.NONE
					clear_highlights()
		
		ActionMode.SKILL:
			if current_turn_character and current_turn_character.is_player_controlled:
				# 임시로 첫 번째 스킬 사용
				if current_turn_character.learned_skills.size() > 0:
					var skill_name = current_turn_character.learned_skills[0]
					if current_turn_character.use_skill(skill_name, grid_pos, battle_grid):
						action_mode = ActionMode.NONE
						clear_highlights()
						update_action_buttons()
		
		ActionMode.NONE:
			pass # 아무 모드가 아닐땐 타일 클릭으로 아무것도 하지 않음

func get_character_at_position(grid_pos: Vector2i) -> Character:
	for character in all_characters:
		if character.grid_position == grid_pos:
			return character
	return null

func perform_attack(attacker: Character, target: Character):
	var skill_name = "Slash"  # 기본 공격
	if skill_name in attacker.learned_skills:
		var terrain_name = battle_grid.get_terrain_at_position(target.grid_position)
		var damage_result = GameManager.calculate_damage(
			character_to_data(attacker),
			character_to_data(target),
			skill_name,
			terrain_name
		)
		
		var damage = damage_result["damage"]
		var is_critical = damage_result["is_critical"]
		var effects = damage_result["effects"]
		
		if damage > 0:
			target.take_damage(damage)
			
			# 전투 로그 출력
			var attack_log = attacker.character_name + "이(가) " + target.character_name + "을(를) 공격!"
			if is_critical:
				attack_log += " 🎯 크리티컬 히트!"
			attack_log += " " + str(damage) + " 데미지!"
			
			print(attack_log)
			
			# 추가 효과들 출력
			for effect in effects:
				if effect != "Critical Hit!":
					print("  → " + effect)
		else:
			print(attacker.character_name + "의 공격이 빗나갔습니다!")
		
		attacker.has_acted = true
		update_action_buttons()

func _on_move_button_pressed():
	print("이동 버튼 클릭됨")
	if current_turn_character and not current_turn_character.has_moved:
		action_mode = ActionMode.MOVE
		clear_highlights()
		var reachable = battle_grid.get_reachable_tiles(current_turn_character.grid_position, current_turn_character.move_range)
		battle_grid.highlight_tiles(reachable, Color(1.0, 0.2, 0.2, 0.6))
		print("이동 모드 활성화")
	else:
		print("이미 이동한 캐릭터입니다!")

func _on_attack_button_pressed():
	if current_turn_character and not current_turn_character.has_acted:
		action_mode = ActionMode.ATTACK
		clear_highlights()
		var attackable = battle_grid.get_attack_range(current_turn_character.grid_position, 1)  # 기본 사거리 1
		highlight_tiles(attackable, Color.RED)
		print("공격 모드 활성화")

func _on_skill_button_pressed():
	if current_turn_character and not current_turn_character.has_acted and current_turn_character.learned_skills.size() > 0:
		action_mode = ActionMode.SKILL
		clear_highlights()
		var skill_name = current_turn_character.learned_skills[0]  # 첫 번째 스킬
		var skill_data = GameData.SKILLS[skill_name]
		var skill_range = battle_grid.get_attack_range(current_turn_character.grid_position, skill_data["range"])
		highlight_tiles(skill_range, Color.PURPLE)
		print("스킬 모드 활성화: ", skill_name)

func _on_end_turn_button_pressed():
	print("턴 종료 버튼 클릭")
	if not current_turn_character:
		print("현재 턴인 캐릭터가 없습니다.")
		return
	
	GameManager.advance_turn()
	action_mode = ActionMode.NONE
	clear_highlights()
	
	# 현재 캐릭터의 턴 종료 처리
	current_turn_character.end_turn()
	print(current_turn_character.character_name, " 턴 종료")
	self.current_turn_character = null # 턴 종료 시 주인공 정보 초기화

func _on_turn_order_updated(turn_order: Array):
	print("행동 순서 UI 업데이트")
	final_turn_order = turn_order
	
	# 기존 목록 지우기
	for child in turn_order_vbox.get_children():
		child.queue_free()
	
	# 새 목록 생성 (애니메이션을 위해 "?" 로 초기화)
	for character in turn_order:
		if is_instance_valid(character):
			var label = Label.new()
			label.text = "???"
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_font_size_override("font_size", 14)
			turn_order_vbox.add_child(label)

func _on_turn_advanced(character: Character, turn_order: Array):
	print("새로운 턴 시작: ", character.character_name)

	# 1. 새로운 턴의 주인공 설정
	self.current_turn_character = character
	
	# 2. 캐릭터 상태 초기화
	character.has_moved = false
	character.has_acted = false
	
	# 3. UI 업데이트
	# 3a. 턴 순서 목록 강조
	for i in range(turn_order_vbox.get_child_count()):
		var label = turn_order_vbox.get_child(i) as Label
		if i < turn_order.size() and is_instance_valid(turn_order[i]):
			if turn_order[i] == character:
				label.add_theme_color_override("font_color", Color.YELLOW)
				label.text = "> " + turn_order[i].character_name
			else:
				var original_color = Color.WHITE if turn_order[i].is_player_controlled else Color.PINK
				label.add_theme_color_override("font_color", original_color)
				label.text = turn_order[i].character_name

	# 3b. 정보창 & 버튼 업데이트
	update_character_info_display(character)
	update_action_buttons()
	
	# 3c. 캐릭터 위에 선택 표시
	show_character_selection_visual(character)

	# 4. 턴 종류에 따른 행동 개시
	if character.is_player_controlled:
		# 플레이어 턴: 자동으로 이동 모드 활성화 및 이동 범위 표시
		turn_label.text = character.character_name + " 행동"
		action_mode = ActionMode.MOVE
		clear_highlights()
		var reachable = battle_grid.get_reachable_tiles(character.grid_position, character.move_range)
		battle_grid.highlight_tiles(reachable, Color(1.0, 0.2, 0.2, 0.6))
	else:
		# 적 턴
		turn_label.text = "적 턴: " + character.character_name
		action_mode = ActionMode.NONE # 플레이어 입력 방지
		clear_highlights()
		show_toast("적 " + character.character_name + "의 차례")
		await get_tree().create_timer(1.5).timeout # 메시지 보일 시간
		process_enemy_turn(character)
	
	turn_counter.text = "라운드: " + str(GameManager.round_count)

func _on_battle_started():
	print("전투 시작! 애니메이션 시퀀스를 시작합니다.")
	animate_turn_order()

func _on_battle_ended():
	print("전투 종료!")

func _on_character_died(character: Character):
	all_characters.erase(character)
	if character.is_player_controlled:
		player_characters.erase(character)
	else:
		enemy_characters.erase(character)
	
	# 승리 조건 확인
	if enemy_characters.size() == 0:
		GameManager.end_battle(true)
	elif player_characters.size() == 0:
		GameManager.end_battle(false)

func _on_character_health_changed(character: Character, new_health: int, max_health: int):
	# 캐릭터 위의 HP 바 업데이트
	var visual_node = character.get_node_or_null("Visual")
	if visual_node:
		var hp_bar = visual_node.get_node_or_null("HP_Container/HPBar")
		if hp_bar:
			var hp_percentage = float(new_health) / float(max_health)
			hp_bar.size.x = 28 * hp_percentage
			
			# HP에 따른 색상 변경
			if hp_percentage > 0.6:
				hp_bar.color = Color.GREEN
			elif hp_percentage > 0.3:
				hp_bar.color = Color.YELLOW
			else:
				hp_bar.color = Color.RED
	
	update_character_info_display(character)

func process_enemy_turn(enemy: Character):
	print("적 ", enemy.character_name, " 행동 처리 시작")
	
	if enemy.current_health <= 0:
		print("이미 행동 불능 상태입니다.")
		GameManager.advance_turn()
		return
		
	# 간단한 AI 로직
	await get_tree().create_timer(1.0).timeout  # 1초 대기
	
	print("적 ", enemy.character_name, " 행동 중...")
	
	# 가장 가까운 플레이어를 찾아 공격
	var closest_player = find_closest_player(enemy)
	if closest_player:
		var distance = enemy.grid_position.distance_to(closest_player.grid_position)
		print("가장 가까운 플레이어: ", closest_player.character_name, ", 거리: ", distance)
		
		# 공격 가능 범위 확인 (기본 사거리 1)
		var can_attack = false
		var attack_range = battle_grid.get_attack_range(enemy.grid_position, 1)
		if closest_player.grid_position in attack_range:
			can_attack = true
			
		if can_attack:
			print("적이 공격합니다!")
			perform_attack(enemy, closest_player)
		else:
			# 플레이어 쪽으로 이동
			print("적이 이동합니다!")
			move_enemy_towards_target(enemy, closest_player)
			
			# 이동 후 다시 공격 시도
			await get_tree().create_timer(0.5).timeout
			attack_range = battle_grid.get_attack_range(enemy.grid_position, 1)
			if closest_player.grid_position in attack_range:
				print("이동 후 적이 공격합니다!")
				perform_attack(enemy, closest_player)

	enemy.end_turn()
	await get_tree().create_timer(0.5).timeout
	
	print("적 ", enemy.character_name, " 행동 완료 - 다음 턴으로 전환")
	GameManager.advance_turn()

func find_closest_player(enemy: Character) -> Character:
	var closest: Character = null
	var min_distance = 999.0
	
	for player in player_characters:
		if player.current_health > 0:
			var distance = enemy.grid_position.distance_to(player.grid_position)
			if distance < min_distance:
				min_distance = distance
				closest = player
	
	return closest

func move_enemy_towards_target(enemy: Character, target: Character):
	var reachable = battle_grid.get_reachable_tiles(enemy.grid_position, enemy.move_range)
	var best_pos = enemy.grid_position
	var min_distance = enemy.grid_position.distance_to(target.grid_position)
	
	for pos in reachable:
		var distance = pos.distance_to(target.grid_position)
		if distance < min_distance:
			min_distance = distance
			best_pos = pos
	
	if best_pos != enemy.grid_position:
		enemy.move_to(best_pos, battle_grid)

func setup_tile_info_ui():
	# 타일 정보 패널 생성
	tile_info_panel = Panel.new()
	tile_info_panel.size = Vector2(200, 100)
	tile_info_panel.position = Vector2(10, get_viewport().size.y - 120)  # 왼쪽 하단 위치
	
	# 패널 스타일 설정
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.8)  # 반투명 검은색 배경
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.6, 0.6, 0.6, 1.0)  # 회색 테두리
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	tile_info_panel.add_theme_stylebox_override("panel", style)
	
	# VBoxContainer 생성하여 라벨들을 수직 배치
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(180, 80)
	
	# 좌표 라벨
	tile_coord_label = Label.new()
	tile_coord_label.text = "좌표: --"
	tile_coord_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(tile_coord_label)
	
	# 지형 라벨
	tile_terrain_label = Label.new()
	tile_terrain_label.text = "지형: --"
	tile_terrain_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(tile_terrain_label)
	
	# 높이 라벨
	tile_height_label = Label.new()
	tile_height_label.text = "높이: --"
	tile_height_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(tile_height_label)
	
	tile_info_panel.add_child(vbox)
	
	# UI 레이어에 추가
	var ui_node = get_node("UI")
	ui_node.add_child(tile_info_panel)
	
	# 초기에는 숨김
	tile_info_panel.hide()

func _on_tile_hovered(grid_pos: Vector2i, terrain_name: String, height: int):
	# 타일 정보 표시
	tile_coord_label.text = "좌표: (" + str(grid_pos.x) + ", " + str(grid_pos.y) + ")"
	
	# 지형 이름을 한국어로 변환
	var korean_terrain_name = get_korean_terrain_name(terrain_name)
	tile_terrain_label.text = "지형: " + korean_terrain_name
	
	tile_height_label.text = "높이: " + str(height)
	
	# 패널 표시
	tile_info_panel.show()

func get_korean_terrain_name(terrain_name: String) -> String:
	var korean_names = {
		"Plain": "평지",
		"Mountain": "산",
		"Forest": "숲",
		"Swamp": "늪",
		"Desert": "사막",
		"RockyTerrain": "바위",
		"BurningGround": "불타는 땅",
		"FrozenGround": "얼어붙은 땅"
	}
	
	if terrain_name in korean_names:
		return korean_names[terrain_name]
	else:
		return terrain_name 

func setup_turn_order_ui():
	var ui_node = get_node("UI")

	turn_order_panel = Panel.new()
	var viewport_size = get_viewport().get_visible_rect().size
	turn_order_panel.size = Vector2(150, 400)
	turn_order_panel.position = Vector2(viewport_size.x - 160, 10)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.SKY_BLUE
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	turn_order_panel.add_theme_stylebox_override("panel", style)
	
	var title = Label.new()
	title.text = "행동 순서"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 5)
	title.size = Vector2(150, 20)
	title.add_theme_font_size_override("font_size", 16)
	turn_order_panel.add_child(title)
	
	turn_order_vbox = VBoxContainer.new()
	turn_order_vbox.position = Vector2(10, 35)
	turn_order_vbox.size = Vector2(130, 360)
	turn_order_panel.add_child(turn_order_vbox)

	ui_node.add_child(turn_order_panel)

func show_toast(message: String, duration: float = 2.0):
	var toast_panel = Panel.new()
	toast_panel.size = Vector2(300, 60)
	toast_panel.position = Vector2(get_viewport().size.x / 2 - 150, 50)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	toast_panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size = toast_panel.size
	label.add_theme_font_size_override("font_size", 24)
	toast_panel.add_child(label)
	
	get_node("UI").add_child(toast_panel)
	
	var tween = create_tween()
	toast_panel.modulate.a = 0.0
	tween.tween_property(toast_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(toast_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(toast_panel.queue_free)

func animate_turn_order():
	show_toast("전투 개시!")
	await get_tree().create_timer(1.0).timeout
	
	var char_names = []
	for char in final_turn_order:
		if is_instance_valid(char):
			char_names.append(char.character_name)

	# 슬롯머신 효과
	var duration = 2.0
	var interval = 0.05
	var elapsed = 0.0
	while elapsed < duration:
		for i in range(turn_order_vbox.get_child_count()):
			var label = turn_order_vbox.get_child(i) as Label
			label.text = char_names[randi() % char_names.size()]
		await get_tree().create_timer(interval).timeout
		elapsed += interval
	
	# 최종 순서 표시
	for i in range(turn_order_vbox.get_child_count()):
		var label = turn_order_vbox.get_child(i) as Label
		if i < final_turn_order.size():
			var char = final_turn_order[i]
			if is_instance_valid(char):
				label.text = char.character_name
				var original_color = Color.WHITE if char.is_player_controlled else Color.PINK
				label.add_theme_color_override("font_color", original_color)
				
	await get_tree().create_timer(0.5).timeout
	
	# 첫 턴 시작
	GameManager.advance_turn()

func show_character_selection_visual(character: Character):
	# 이전에 표시된 시각 효과가 있다면 모두 지움
	clear_character_selection_visual()

	# 새 캐릭터에게 시각 효과 적용
	if is_instance_valid(character):
		# 선택된 캐릭터 주위에 노란색 테두리 표시
		var selection_ring = ColorRect.new()
		selection_ring.name = "SelectionRing"
		selection_ring.size = Vector2(40, 40)
		selection_ring.color = Color.TRANSPARENT
		selection_ring.add_theme_stylebox_override("panel", create_selection_border())
		selection_ring.position = Vector2(-20, -20)
		character.add_child(selection_ring)
		
		# 선택된 캐릭터 위에 화살표 표시
		var arrow = Label.new()
		arrow.name = "SelectionArrow"
		arrow.text = "▼"
		arrow.position = Vector2(-8, -35)
		arrow.add_theme_color_override("font_color", Color.YELLOW)
		arrow.add_theme_font_size_override("font_size", 20)
		character.add_child(arrow)
		
		previous_selection = character

func clear_character_selection_visual():
	if is_instance_valid(previous_selection):
		var old_ring = previous_selection.get_node_or_null("SelectionRing")
		if old_ring: old_ring.queue_free()
		
		var old_arrow = previous_selection.get_node_or_null("SelectionArrow")
		if old_arrow: old_arrow.queue_free()
	
	previous_selection = null
