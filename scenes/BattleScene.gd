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

# 게임 상태
var player_characters: Array = []
var enemy_characters: Array = []
var all_characters: Array = []
var selected_character: Character = null
var current_action_mode: String = "none"  # none, move, attack, skill
var highlighted_tiles: Array = []

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
	
	# 타일 정보 UI 생성
	setup_tile_info_ui()
	
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
	
	# 마우스 클릭 처리
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		print("BattleScene _input 호출됨: ", mouse_pos)
		print("현재 액션 모드: ", ActionMode.keys()[action_mode])
		
		# 현재 액션 모드가 NONE일 때만 캐릭터 선택 처리
		if action_mode == ActionMode.NONE:
			if handle_character_selection(mouse_pos):
				# 캐릭터 선택 성공시 이벤트 소비
				print("캐릭터 선택 성공 - 이벤트 소비")
				get_viewport().set_input_as_handled()
				return
		else:
			print("액션 모드가 NONE이 아님 - 캐릭터 선택 처리 안 함")

func _process(delta):
	handle_camera_movement(delta)

func connect_signals():
	# GameManager 신호 연결
	GameManager.turn_changed.connect(_on_turn_changed)
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
	
	# GameManager에 전투 시작 알림
	var player_data = []
	var enemy_data = []
	
	for character in player_characters:
		player_data.append(character_to_data(character))
	
	for character in enemy_characters:
		enemy_data.append(character_to_data(character))
	
	GameManager.start_battle(player_data, enemy_data)
	
	# 첫 번째 플레이어 캐릭터 선택 - 완전히 초기화한 후 선택
	if player_characters.size() > 0:
		print("첫 번째 캐릭터 자동 선택: ", player_characters[0].character_name)
		# 기존 선택 표시가 있을 수 있으므로 모든 캐릭터에서 제거
		for character in all_characters:
			var selection_ring = character.get_node_or_null("SelectionRing")
			if selection_ring:
				selection_ring.queue_free()
			var arrow = character.get_node_or_null("SelectionArrow")
			if arrow:
				arrow.queue_free()
		
		# 상태 초기화
		selected_character = null
		clear_highlights()
		
		# 한 프레임 기다린 후 새로운 캐릭터 선택
		await get_tree().process_frame
		select_character(player_characters[0])
	
	# UI 초기 업데이트
	await get_tree().process_frame  # 한 프레임 대기
	update_character_info()
	
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
	var world_pos = Vector2(grid_pos.x * 70, grid_pos.y * 35)
	
	# 높이 반영 (BattleGrid에서 높이 데이터 가져오기)
	var height = 0
	if battle_grid and battle_grid.has_method("get_height_at_position"):
		height = battle_grid.get_height_at_position(grid_pos)
	
	# 높이만큼 위로 올리기
	world_pos.y -= height * 15
	character.position = world_pos
	
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

func handle_character_selection(mouse_pos: Vector2) -> bool:
	print("캐릭터 선택 처리: ", mouse_pos)
	
	# 모든 캐릭터를 확인하여 클릭된 캐릭터 찾기
	for character in all_characters:
		if character.is_player_controlled:  # 플레이어 캐릭터만 선택 가능
			print("캐릭터 확인: ", character.character_name, " 위치: ", character.global_position)
			var char_rect = Rect2(character.global_position - Vector2(16, 16), Vector2(32, 32))
			print("캐릭터 영역: ", char_rect)
			if char_rect.has_point(mouse_pos):
				print("캐릭터 클릭됨: ", character.character_name)
				select_character(character)
				return true
	
	print("선택된 캐릭터가 없습니다.")
	return false

func select_character(character: Character):
	# 이전 선택 해제
	if selected_character:
		clear_highlights()
		clear_character_selection_visual()
	
	selected_character = character
	update_character_info()
	
	# 선택된 캐릭터 시각적 표시
	show_character_selection_visual(character)
	
	# 선택된 캐릭터의 이동 범위 자동 표시 (has_moved 조건 제거)
	if selected_character and selected_character.is_player_controlled:
		print("=== 이동 범위 표시 시작 ===")
		print("캐릭터: ", selected_character.character_name)
		print("현재 위치: ", selected_character.grid_position)
		print("이동 거리: ", selected_character.move_range)
		
		var reachable = battle_grid.get_reachable_tiles(selected_character.grid_position, selected_character.move_range)
		print("계산된 이동 가능 타일: ", reachable.size(), "개")
		
		if reachable.size() > 0:
			# 붉은 반투명 그림자로 이동 범위 표시
			battle_grid.highlight_tiles(reachable, Color(1.0, 0.2, 0.2, 0.8))  # 좀 더 진하게
			print("하이라이트 표시 완료")
		else:
			print("이동 가능한 타일이 없습니다!")
		print("=== 이동 범위 표시 완료 ===")
	
	print(character.character_name, " 선택됨")

func update_character_info():
	print("update_character_info 호출됨")
	
	if selected_character:
		print("선택된 캐릭터 정보 업데이트: ", selected_character.character_name)
		
		# UI 요소들이 존재하는지 확인
		if character_name_label:
			character_name_label.text = selected_character.character_name + " Lv." + str(selected_character.level)
			print("이름 라벨 업데이트: ", character_name_label.text)
		else:
			print("character_name_label이 null입니다!")
		
		if character_class_label:
			character_class_label.text = "클래스: " + selected_character.current_class
			print("클래스 라벨 업데이트: ", character_class_label.text)
		else:
			print("character_class_label이 null입니다!")
		
		if hp_bar:
			hp_bar.max_value = selected_character.max_health
			hp_bar.value = selected_character.current_health
			print("HP 바 업데이트: ", hp_bar.value, "/", hp_bar.max_value)
		else:
			print("hp_bar가 null입니다!")
		
		if mp_bar:
			mp_bar.max_value = selected_character.max_mana
			mp_bar.value = selected_character.current_mana
			print("MP 바 업데이트: ", mp_bar.value, "/", mp_bar.max_value)
		else:
			print("mp_bar가 null입니다!")
		
		# 상세 스탯 업데이트
		update_stat_labels()

func update_stat_labels():
	if not selected_character:
		reset_stat_labels()
		return
		
	var stats = selected_character.current_stats
	
	if str_label:
		str_label.text = "STR: " + str(stats.get("STR", 0))
	if def_label:
		def_label.text = "DEF: " + str(stats.get("DEF", 0))
	if dex_label:
		dex_label.text = "DEX: " + str(stats.get("DEX", 0))
	if agi_label:
		agi_label.text = "AGI: " + str(stats.get("AGI", 0))
	if int_label:
		int_label.text = "INT: " + str(stats.get("INT", 0))
	if res_label:
		res_label.text = "RES: " + str(stats.get("RES", 0))

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
		
		# 행동 가능 여부에 따른 버튼 활성화
		var can_act = GameManager.current_phase == GameManager.TurnPhase.PLAYER_TURN
		if move_button:
			move_button.disabled = not (can_act and not selected_character.has_moved)
		if attack_button:
			attack_button.disabled = not (can_act and not selected_character.has_acted)
		if skill_button:
			skill_button.disabled = not (can_act and not selected_character.has_acted)
	else:
		print("선택된 캐릭터가 없음 - UI 초기화")
		if character_name_label:
			character_name_label.text = "캐릭터 없음"
		if character_class_label:
			character_class_label.text = "클래스: 없음"
		if hp_bar:
			hp_bar.value = 0
		if mp_bar:
			mp_bar.value = 0

func clear_highlights():
	highlighted_tiles.clear()
	battle_grid.clear_highlights()

func highlight_tiles(tiles: Array, color: Color = Color.YELLOW):
	clear_highlights()
	highlighted_tiles = tiles
	battle_grid.highlight_tiles(tiles, color)

func show_character_selection_visual(character: Character):
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
	
	print("캐릭터 선택 시각화 표시: ", character.character_name)

func clear_character_selection_visual():
	# 이전 선택된 캐릭터의 시각적 표시만 제거
	if is_instance_valid(selected_character):
		var selection_ring = selected_character.get_node_or_null("SelectionRing")
		if selection_ring:
			selection_ring.queue_free()
		
		var arrow = selected_character.get_node_or_null("SelectionArrow")
		if arrow:
			arrow.queue_free()
		
		print(selected_character.character_name, "의 선택 표시 제거됨")

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
	
	match action_mode:
		ActionMode.MOVE:
			print("이동 모드에서 타일 클릭")
			if selected_character and selected_character.is_player_controlled:
				print("플레이어 캐릭터로 이동 시도: ", selected_character.character_name)
				print("목표 위치: ", grid_pos)
				print("현재 위치: ", selected_character.grid_position)
				
				if selected_character.move_to(grid_pos, battle_grid):
					print("이동 성공!")
					action_mode = ActionMode.NONE
					clear_highlights()
					update_character_info()
				else:
					print("이동 실패!")
		
		ActionMode.ATTACK:
			if selected_character and selected_character.is_player_controlled:
				var target = get_character_at_position(grid_pos)
				if target and not target.is_player_controlled:
					perform_attack(selected_character, target)
					action_mode = ActionMode.NONE
					clear_highlights()
		
		ActionMode.SKILL:
			if selected_character and selected_character.is_player_controlled:
				# 임시로 첫 번째 스킬 사용
				if selected_character.learned_skills.size() > 0:
					var skill_name = selected_character.learned_skills[0]
					if selected_character.use_skill(skill_name, grid_pos, battle_grid):
						action_mode = ActionMode.NONE
						clear_highlights()
						update_character_info()
		
		ActionMode.NONE:
			# 타일 클릭 시에는 아무것도 하지 않음 (캐릭터 선택은 _input에서 처리)
			pass

func get_character_at_position(grid_pos: Vector2i) -> Character:
	for character in all_characters:
		if character.grid_position == grid_pos:
			return character
	return null

func perform_attack(attacker: Character, target: Character):
	var skill_name = "Slash"  # 기본 공격
	if skill_name in attacker.learned_skills:
		var terrain_name = battle_grid.get_terrain_at_position(target.grid_position)
		var damage = GameManager.calculate_damage(
			character_to_data(attacker),
			character_to_data(target),
			skill_name,
			terrain_name
		)
		
		target.take_damage(damage)
		attacker.has_acted = true
		
		print(attacker.character_name, "이(가) ", target.character_name, "을(를) 공격! ", damage, " 데미지!")
		
		update_character_info()

func _on_move_button_pressed():
	print("이동 버튼 클릭됨")
	if selected_character:
		print("선택된 캐릭터: ", selected_character.character_name)
		print("이미 이동했는가: ", selected_character.has_moved)
		print("현재 위치: ", selected_character.grid_position)
		
		if not selected_character.has_moved:
			action_mode = ActionMode.MOVE
			var reachable = battle_grid.get_reachable_tiles(selected_character.grid_position, selected_character.move_range)
			print("이동 가능한 타일 수: ", reachable.size())
			print("이동 가능한 타일들: ", reachable)
			# 붉은 반투명 그림자로 이동 범위 표시
			battle_grid.highlight_tiles(reachable, Color(1.0, 0.2, 0.2, 0.6))
			print("이동 모드 활성화")
		else:
			print("이미 이동한 캐릭터입니다!")
	else:
		print("선택된 캐릭터가 없습니다!")

func _on_attack_button_pressed():
	if selected_character and not selected_character.has_acted:
		action_mode = ActionMode.ATTACK
		var attackable = battle_grid.get_attack_range(selected_character.grid_position, 1)  # 기본 사거리 1
		highlight_tiles(attackable, Color.RED)
		print("공격 모드 활성화")

func _on_skill_button_pressed():
	if selected_character and not selected_character.has_acted and selected_character.learned_skills.size() > 0:
		action_mode = ActionMode.SKILL
		var skill_name = selected_character.learned_skills[0]  # 첫 번째 스킬
		var skill_data = GameData.SKILLS[skill_name]
		var skill_range = battle_grid.get_attack_range(selected_character.grid_position, skill_data["range"])
		highlight_tiles(skill_range, Color.PURPLE)
		print("스킬 모드 활성화: ", skill_name)

func _on_end_turn_button_pressed():
	print("플레이어 턴 종료 버튼 클릭")
	
	# 현재 플레이어 턴인지 확인
	if GameManager.current_phase != GameManager.TurnPhase.PLAYER_TURN:
		print("현재 플레이어 턴이 아닙니다!")
		return
	
	GameManager.next_turn()
	action_mode = ActionMode.NONE
	clear_highlights()
	clear_character_selection_visual()
	
	# 모든 플레이어 캐릭터의 턴 종료 처리
	for character in player_characters:
		character.end_turn()
	
	print("플레이어 턴 종료됨")

func _on_turn_changed(current_turn):
	print("턴 변경됨: ", GameManager.TurnPhase.keys()[current_turn])
	
	match current_turn:
		GameManager.TurnPhase.PLAYER_TURN:
			turn_label.text = "플레이어 턴"
			# 플레이어 캐릭터들의 행동 상태 초기화
			for character in player_characters:
				character.has_moved = false
				character.has_acted = false
			print("플레이어 턴 시작 - 모든 캐릭터 행동 가능")
			
		GameManager.TurnPhase.ENEMY_TURN:
			turn_label.text = "적 턴"
			# 적 캐릭터들의 행동 상태 초기화
			for character in enemy_characters:
				character.has_moved = false
				character.has_acted = false
			process_enemy_turn()
			
		GameManager.TurnPhase.ENVIRONMENT_TURN:
			turn_label.text = "환경 턴"
			print("환경 턴 처리 중...")
			# 환경 턴은 자동으로 다음 턴으로 넘어감
			await get_tree().create_timer(1.0).timeout
			GameManager.next_turn()
	
	turn_counter.text = "턴: " + str(GameManager.turn_count)
	update_character_info()

func _on_battle_started():
	print("전투 시작!")

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
	
	if character == selected_character:
		update_character_info()

func process_enemy_turn():
	print("적 턴 처리 시작")
	
	# 간단한 AI 로직
	await get_tree().create_timer(1.0).timeout  # 1초 대기
	
	for enemy in enemy_characters:
		if enemy.current_health > 0:
			print("적 ", enemy.character_name, " 행동 중...")
			
			# 가장 가까운 플레이어를 찾아 공격
			var closest_player = find_closest_player(enemy)
			if closest_player:
				var distance = enemy.grid_position.distance_to(closest_player.grid_position)
				print("거리: ", distance)
				
				if distance <= 1:  # 인접하면 공격
					print("적이 공격합니다!")
					perform_attack(enemy, closest_player)
				else:
					# 플레이어 쪽으로 이동
					print("적이 이동합니다!")
					move_enemy_towards_target(enemy, closest_player)
		
		enemy.end_turn()
		await get_tree().create_timer(0.5).timeout  # 0.5초 대기
	
	print("적 턴 완료 - 플레이어 턴으로 전환")
	# 적 턴 종료 후 환경 턴으로 (GameManager가 자동으로 플레이어 턴으로 돌림)
	GameManager.next_turn()

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
