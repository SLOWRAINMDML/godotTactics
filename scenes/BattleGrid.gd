# -----------------------------------------------------------------------------
# [후임자를 위한 안내]
#
# BattleGrid.gd (전투 그리드)
#
# [역할]
# 이 스크립트는 전술 SRPG의 핵심인 전투 맵을 생성하고 관리합니다.
# 2D 환경에서 입체적인 느낌을 주는 이소메트릭(Isometric) 뷰를 구현하며,
# 맵의 모든 타일 정보(지형, 높이)를 다루고, 사용자 입력(클릭, 호버)을 처리합니다.
#
# [주요 기능]
# 1. 맵 생성: `generate_test_map`을 통해 절차적으로 랜덤 맵을 생성합니다.
# 2. 타일 렌더링: `draw_terrain_tiles`를 통해 각 타일을 높이에 맞춰 시각적으로 그립니다.
# 3. 좌표 변환: 이소메트릭 뷰의 핵심인 '그리드 좌표'와 '화면 좌표'를 서로 변환합니다.
# 4. 입력 처리: 마우스 클릭 위치를 그리드 좌표로 변환하여 `BattleScene`에 알립니다.
# 5. 게임 로직 지원: 캐릭터의 이동/공격 가능 범위 계산, 시야 확인 등의 기능을 제공합니다.
#
# [Godot 학습 팁: 절차적 생성(Procedural Generation)]
# - `generate_test_map` 함수는 코드를 통해 동적으로 게임 콘텐츠(맵)를 만들어내는 좋은 예시입니다.
# - 노이즈 함수(`get_noise_value`)를 사용하여 자연스러운 지형을 만드는 기법을 학습할 수 있습니다.
# - Godot에서 `Polygon2D`나 `ColorRect` 같은 노드를 코드로 직접 생성하고 씬에 추가하는 방법을
#   `create_isometric_tile` 함수에서 확인할 수 있습니다.
# -----------------------------------------------------------------------------
extends Node2D
class_name BattleGrid

# 그리드 크기 (가로 50칸, 세로 65칸의 대형 맵)
var grid_width: int = 50
var grid_height: int = 65

# 지형 정보 저장용 Dictionary
var terrain_data: Dictionary = {} # Key: Vector2i(그리드 좌표), Value: String(지형 이름)
var height_data: Dictionary = {}  # Key: Vector2i(그리드 좌표), Value: int(높이)

# 타일 종류를 명확하게 관리하기 위한 열거형(Enum)
enum TileType {
	PLAIN, MOUNTAIN, FOREST, SWAMP, DESERT,
	ROCKY, BURNING, FROZEN
}

# Enum 값과 GameData에 정의된 지형 이름을 매핑
var tile_to_terrain = {
	TileType.PLAIN: "Plain",
	TileType.MOUNTAIN: "Mountain",
	TileType.FOREST: "Forest",
	TileType.SWAMP: "Swamp",
	TileType.DESERT: "Desert",
	TileType.ROCKY: "RockyTerrain",
	TileType.BURNING: "BurningGround",
	TileType.FROZEN: "FrozenGround"
}

# [시그널 정의]
# 이 그리드에서 발생하는 주요 이벤트를 외부에 알립니다.
signal tile_clicked(grid_pos, terrain_name) # 타일이 클릭되었을 때 발생
signal tile_hovered(grid_pos, terrain_name, height) # 마우스가 타일 위에 올라갔을 때 발생
signal character_position_changed(character, old_pos, new_pos) # 캐릭터 위치가 변경되었을 때 발생 (현재는 미사용)

# 타일과 하이라이트를 담을 컨테이너 노드
var terrain_container: Node2D   # 모든 지형 타일(Polygon2D)이 이곳의 자식으로 추가됨
var highlight_container: Node2D # 이동/공격 범위 하이라이트가 이곳에 추가됨

var highlighted_tile_nodes: Dictionary = {} # 현재 표시 중인 하이라이트 노드들을 관리

# 마우스 호버(Hover) 관련 변수
var hovered_tile_pos: Vector2i = Vector2i(-1, -1) # 현재 마우스가 올라가 있는 타일 좌표
var hover_highlight_node: ColorRect # 호버된 타일을 표시하는 노란색 반투명 사각형

# Godot 엔진이 이 노드를 씬 트리에 추가할 때 자동으로 호출하는 내장 함수입니다.
func _ready():
	print("BattleGrid _ready() 시작")
	
	# 그리드의 원점 위치를 조정합니다.
	position = Vector2(400, 200)
	
	setup_containers()
	
	print("맵 생성 시작...")
	generate_test_map()
	
	print("타일 그리기 시작...")
	# 맵 생성이 완료된 후, 다음 프레임에서 타일을 그리도록 예약합니다.
	# 이는 모든 노드가 초기화된 후 그리기를 시작하여 안정성을 높입니다.
	call_deferred("draw_terrain_tiles")
	
	print("BattleGrid 초기화 완료")

## 타일과 하이라이트를 담을 컨테이너 노드를 생성하고 설정합니다.
func setup_containers():
	terrain_container = Node2D.new()
	terrain_container.name = "TerrainContainer"
	terrain_container.y_sort_enabled = true # y좌표에 따라 자식 노드들의 렌더링 순서를 자동 정렬 (아래쪽 타일이 위에 그려짐)
	add_child(terrain_container)
	
	highlight_container = Node2D.new()
	highlight_container.name = "HighlightContainer"
	highlight_container.y_sort_enabled = true
	highlight_container.z_index = 1 # z_index를 높여 지형 타일보다 항상 위에 그려지도록 설정
	add_child(highlight_container)

## 처리되지 않은 모든 입력을 감지하는 내장 함수입니다. UI 요소가 처리하지 않은 입력을 받습니다.
## 마우스 클릭으로 타일을 선택하는 기능을 담당합니다.
func _unhandled_input(event):
	# 마우스 왼쪽 버튼 클릭 이벤트인지 확인합니다.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("BattleGrid _unhandled_input 호출됨")
		
		# 1. 전역 마우스 위치를 가져옵니다.
		var mouse_pos = get_global_mouse_position()
		# 2. 전역 위치를 이 노드 기준의 지역 위치로 변환합니다.
		var local_pos = to_local(mouse_pos)
		# 3. 지역 위치를 그리드 좌표로 변환합니다.
		var grid_pos = local_to_grid(local_pos)
		
		print("BattleGrid 마우스 클릭 위치: ", mouse_pos)
		print("로컬 위치: ", local_pos)
		print("그리드 위치: ", grid_pos)
		
		# 유효한 그리드 좌표인 경우에만 처리합니다.
		if is_valid_grid_position(grid_pos):
			var terrain_name = get_terrain_at_position(grid_pos)
			# "tile_clicked" 시그널을 발생시켜 BattleScene에 정보를 전달합니다.
			emit_signal("tile_clicked", grid_pos, terrain_name)
			print("클릭된 타일: ", grid_pos, " 지형: ", terrain_name)
		else:
			print("유효하지 않은 그리드 위치: ", grid_pos)

## 매 프레임마다 호출되는 내장 함수입니다.
func _process(_delta):
	# 마우스 커서의 위치를 지속적으로 추적하여 호버 효과를 처리합니다.
	handle_mouse_hover()

## 마우스 호버 효과를 처리하는 함수입니다.
func handle_mouse_hover():
	var mouse_pos = get_global_mouse_position()
	var local_pos = to_local(mouse_pos)
	var grid_pos = local_to_grid(local_pos)
	
	# 마우스가 맵 밖으로 나가면 하이라이트를 제거합니다.
	if not is_valid_grid_position(grid_pos):
		if hovered_tile_pos != Vector2i(-1, -1):
			clear_hover_highlight()
			hovered_tile_pos = Vector2i(-1, -1)
		return
	
	# 같은 타일 위에 계속 머물러 있으면 아무 작업도 하지 않습니다.
	if grid_pos == hovered_tile_pos:
		return
	
	clear_hover_highlight()
	
	# 새로운 타일에 호버 효과를 표시합니다.
	hovered_tile_pos = grid_pos
	show_hover_highlight(grid_pos)
	
	# 타일 정보를 BattleScene에 시그널로 전달하여 UI에 표시하도록 합니다.
	var terrain_name = get_terrain_at_position(grid_pos)
	var height = get_height_at_position(grid_pos)
	emit_signal("tile_hovered", grid_pos, terrain_name, height)

## 마우스가 올라간 타일에 노란색 반투명 하이라이트를 표시합니다.
func show_hover_highlight(grid_pos: Vector2i):
	if not hover_highlight_node:
		hover_highlight_node = ColorRect.new()
		hover_highlight_node.color = Color(1.0, 1.0, 0.0, 0.3) # 노란색, 30% 불투명도
		hover_highlight_node.mouse_filter = Control.MOUSE_FILTER_IGNORE # 마우스 입력을 무시하도록 설정
		add_child(hover_highlight_node)
	
	var world_pos = grid_to_world(grid_pos)
	
	# 타일 크기에 맞게 위치와 크기를 설정합니다.
	hover_highlight_node.position = world_pos - Vector2(35, 17.5)
	hover_highlight_node.size = Vector2(70, 35)
	hover_highlight_node.show()

## 호버 하이라이트를 숨깁니다.
func clear_hover_highlight():
	if hover_highlight_node:
		hover_highlight_node.hide()

## 테스트용 랜덤 맵을 생성합니다.
func generate_test_map():
	print("랜덤 고저차 맵 생성 시작...")
	print("맵 크기: ", grid_width, "x", grid_height, " = ", grid_width * grid_height, "개 타일")
	
	terrain_data.clear()
	height_data.clear()
	
	# 1단계: 노이즈를 사용하여 높이 맵을 생성합니다.
	generate_height_map()
	
	# 2단계: 생성된 높이에 따라 각 타일의 지형 타입을 결정합니다.
	var tile_count = 0
	for x in range(grid_width):
		for y in range(grid_height):
			var grid_pos = Vector2i(x, y)
			var height = height_data[grid_pos]
			var tile_type = get_tile_type_by_height_and_position(x, y, height)
			
			var terrain_name = tile_to_terrain[tile_type]
			terrain_data[grid_pos] = terrain_name
			tile_count += 1
	
	print("맵 생성 완료! 총 ", tile_count, "개 타일 생성됨")
	print("terrain_data 크기: ", terrain_data.size())
	print("height_data 크기: ", height_data.size())

## 노이즈 알고리즘을 사용하여 맵의 높이 정보를 생성합니다.
func generate_height_map():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for x in range(grid_width):
		for y in range(grid_height):
			var grid_pos = Vector2i(x, y)
			
			# 여러 다른 주파수의 노이즈 값을 조합하여 더 자연스러운 지형을 만듭니다.
			var height = 0.0
			height += get_noise_value(x, y, 10.0, rng) * 1.5  # 큰 언덕
			height += get_noise_value(x, y, 5.0, rng) * 1.0   # 중간 지형
			height += get_noise_value(x, y, 2.0, rng) * 0.5   # 작은 디테일
			
			# 높이 값을 -1에서 10 사이의 정수로 변환합니다.
			var final_height = int(round(height))
			final_height = clamp(final_height, -1, 10)
			
			height_data[grid_pos] = final_height

## 특정 좌표에 대한 노이즈 값을 계산합니다. (유사 펄린 노이즈)
func get_noise_value(x: int, y: int, frequency: float, rng: RandomNumberGenerator) -> float:
	var sample_x = x / frequency
	var sample_y = y / frequency
	
	var x1 = int(sample_x)
	var y1 = int(sample_y)
	var x2 = x1 + 1
	var y2 = y1 + 1
	
	# 주변 4개 점의 의사 랜덤 값을 가져옵니다.
	var v1 = get_pseudo_random(x1, y1, rng.seed)
	var v2 = get_pseudo_random(x2, y1, rng.seed)
	var v3 = get_pseudo_random(x1, y2, rng.seed)
	var v4 = get_pseudo_random(x2, y2, rng.seed)
	
	# 선형 보간(lerp)을 통해 부드럽게 값을 연결합니다.
	var fx = sample_x - x1
	var fy = sample_y - y1
	
	var top = lerp(v1, v2, fx)
	var bottom = lerp(v3, v4, fx)
	return lerp(top, bottom, fy)

## 주어진 좌표와 시드 값으로 의사 랜덤 값을 생성합니다.
func get_pseudo_random(x: int, y: int, seed_val: int) -> float:
	var hash_val = (x * 374761393 + y * 668265263 + seed_val) % 2147483647
	return (hash_val % 2000) / 1000.0 - 1.0  # -1.0 ~ 1.0 범위의 실수 반환

## 높이와 위치에 따라 지형 타입을 결정합니다.
func get_tile_type_by_height_and_position(x: int, y: int, height: int) -> int:
	var rng = RandomNumberGenerator.new()
	rng.seed = x * 1000 + y # 위치 기반 시드로 동일 위치에서는 항상 같은 결과가 나오도록 함
	
	match height:
		-1: return [TileType.SWAMP, TileType.PLAIN][rng.randi() % 2]
		0: return [TileType.PLAIN, TileType.FOREST, TileType.DESERT][rng.randi() % 3]
		1, 2: return [TileType.PLAIN, TileType.FOREST, TileType.ROCKY][rng.randi() % 3]
		3, 4, 5: return [TileType.MOUNTAIN, TileType.ROCKY][rng.randi() % 2]
		_: # 6 이상
			if height >= 8: return TileType.ROCKY # 8 이상은 험준한 바위산
			else: return TileType.MOUNTAIN

## 주어진 그리드 좌표가 맵 범위 내에 있는지 확인합니다.
func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height

## 특정 그리드 좌표의 지형 이름을 반환합니다.
func get_terrain_at_position(grid_pos: Vector2i) -> String:
	if grid_pos in terrain_data:
		return terrain_data[grid_pos]
	return "Plain" # 기본값

## 특정 그리드 좌표의 높이를 반환합니다.
func get_height_at_position(grid_pos: Vector2i) -> int:
	if grid_pos in height_data:
		return height_data[grid_pos]
	return 0 # 기본값

## 이동 가능한 타일 범위를 계산합니다. (너비 우선 탐색, BFS 알고리즘 사용)
## @param start_pos: 시작 그리드 좌표
## @param move_range: 캐릭터의 최대 이동력
## @return: 이동 가능한 모든 그리드 좌표의 배열
func get_reachable_tiles(start_pos: Vector2i, move_range: int) -> Array:
	print("이동 가능 타일 계산 시작: ", start_pos, " 범위: ", move_range)
	
	var reachable = [] # 결과 배열
	var visited = {}   # 이미 방문한 타일 기록
	var queue = [{ "pos": start_pos, "cost": 0 }] # 탐색 대기열
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current.pos
		var cost = current.cost
		
		if pos in visited: continue
			
		visited[pos] = true
		if cost <= move_range:
			reachable.append(pos)
		
		# 상하좌우 4방향의 인접 타일을 확인합니다.
		var neighbors = [
			Vector2i(pos.x + 1, pos.y), Vector2i(pos.x - 1, pos.y),
			Vector2i(pos.x, pos.y + 1), Vector2i(pos.x, pos.y - 1)
		]
		
		for neighbor in neighbors:
			if is_valid_grid_position(neighbor) and not neighbor in visited:
				var neighbor_height = get_height_at_position(neighbor)
				
				# 높이 8 이상의 험준한 산은 이동 불가
				if neighbor_height >= 8: continue
				
				# 지형에 따른 이동 비용을 가져옵니다.
				var terrain_name = get_terrain_at_position(neighbor)
				var move_cost = GameData.TERRAINS[terrain_name]["move_cost"]
				
				# 높이 차이에 따른 패널티 추가
				var current_height = get_height_at_position(pos)
				var height_diff = abs(neighbor_height - current_height)
				if height_diff >= 2:
					move_cost += height_diff
				
				var new_cost = cost + move_cost
				
				# 누적 비용이 최대 이동력을 초과하지 않으면 대기열에 추가합니다.
				if new_cost <= move_range:
					queue.append({ "pos": neighbor, "cost": new_cost })
	
	print("계산된 이동 가능 타일 수: ", reachable.size())
	return reachable

## 공격 가능한 타일 범위를 계산합니다.
## @param attacker_pos: 공격자 위치
## @param weapon_range: 무기 사거리
## @param height_limit: 공격 가능한 최대 높이 차이
## @return: 공격 가능한 모든 그리드 좌표의 배열
func get_attack_range(attacker_pos: Vector2i, weapon_range: int, height_limit: int = 3) -> Array:
	var attackable = []
	var attacker_height = get_height_at_position(attacker_pos)
	
	# 사거리 내의 모든 타일을 순회합니다.
	for x in range(max(0, attacker_pos.x - weapon_range), min(grid_width, attacker_pos.x + weapon_range + 1)):
		for y in range(max(0, attacker_pos.y - weapon_range), min(grid_height, attacker_pos.y + weapon_range + 1)):
			var target_pos = Vector2i(x, y)
			var distance = attacker_pos.distance_to(target_pos)
			
			if distance <= weapon_range and target_pos != attacker_pos:
				var target_height = get_height_at_position(target_pos)
				var height_diff = abs(target_height - attacker_height)
				
				# 높이 차이가 너무 크면 공격 불가
				if height_diff <= height_limit:
					attackable.append(target_pos)
	
	return attackable

## 시야에 들어오는 타일 범위를 계산합니다. (현재는 단순화된 버전)
func get_visible_tiles(observer_pos: Vector2i, sight_range: int) -> Array:
	var visible = []
	var observer_height = get_height_at_position(observer_pos)
	
	for x in range(max(0, observer_pos.x - sight_range), min(grid_width, observer_pos.x + sight_range + 1)):
		for y in range(max(0, observer_pos.y - sight_range), min(grid_height, observer_pos.y + sight_range + 1)):
			var target_pos = Vector2i(x, y)
			var distance = observer_pos.distance_to(target_pos)
			
			if distance <= sight_range:
				if has_line_of_sight(observer_pos, target_pos):
					visible.append(target_pos)
	
	return visible

## 두 지점 사이에 시야가 확보되는지 확인합니다. (Line of Sight, LOS)
func has_line_of_sight(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	# TODO: 더 정교한 시야 계산 로직(예: Bresenham 알고리즘) 구현 필요.
	# 현재는 단순한 높이와 거리 기반으로 계산합니다.
	var from_height = get_height_at_position(from_pos)
	var to_height = get_height_at_position(to_pos)
	
	var height_advantage = from_height - to_height
	
	if height_advantage > 0: return true # 높은 곳에서는 잘 보임
	
	var distance = from_pos.distance_to(to_pos)
	return distance <= 3 # 기본 시야 거리

## 특정 타일의 지형을 변경합니다. (예: 스킬 효과)
func change_terrain(grid_pos: Vector2i, new_terrain: String):
	if is_valid_grid_position(grid_pos):
		terrain_data[grid_pos] = new_terrain
		
		if GameData.TERRAINS.has(new_terrain):
			height_data[grid_pos] = GameData.TERRAINS[new_terrain]["height"]
		else:
			height_data[grid_pos] = 0
		
		# 해당 타일만 다시 그려서 시각적으로 업데이트합니다.
		update_single_tile(grid_pos)
		
		print("지형 변화: ", grid_pos, " -> ", new_terrain)

## 단일 타일만 다시 그리는 함수입니다.
func update_single_tile(grid_pos: Vector2i):
	# 기존 타일 노드를 찾아서 제거합니다.
	var tile_name = "Tile_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	for child in terrain_container.get_children():
		if child.name == tile_name:
			child.queue_free()
			break
	
	# 새로운 정보로 타일을 다시 생성합니다.
	var terrain_name = terrain_data[grid_pos]
	var height = height_data.get(grid_pos, 0)
	var world_pos = grid_to_world(grid_pos)
	create_isometric_tile(world_pos, terrain_name, height, grid_pos)

# --- 이소메트릭 좌표 변환 함수들 ---
# 이 함수들은 이소메트릭 뷰의 핵심입니다.

## 그리드 좌표(예: 10, 15)를 화면(월드) 좌표(예: 350, 262.5)로 변환합니다.
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	# TILE_WIDTH_HALF = 35, TILE_HEIGHT_HALF = 17.5
	var x = (grid_pos.x - grid_pos.y) * 35
	var y = (grid_pos.x + grid_pos.y) * 17.5
	return Vector2(x, y)

## 화면(로컬) 좌표를 가장 가까운 그리드 좌표로 변환합니다.
func local_to_grid(local_pos: Vector2) -> Vector2i:
	# TILE_WIDTH = 70, TILE_HEIGHT = 35
	var iso_x = local_pos.x / 70.0
	var iso_y = local_pos.y / 35.0
	
	var grid_x = round(iso_y + iso_x)
	var grid_y = round(iso_y - iso_x)
	
	return Vector2i(grid_x, grid_y)

## 전역(월드) 좌표를 그리드 좌표로 변환합니다.
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return local_to_grid(to_local(world_pos))

# --- 하이라이트 및 렌더링 함수들 ---

## 주어진 타일 배열에 하이라이트를 표시합니다.
func highlight_tiles(tiles: Array, color: Color):
	clear_highlights()
	
	for grid_pos in tiles:
		if is_valid_grid_position(grid_pos):
			var world_pos = grid_to_world(grid_pos)
			var height = get_height_at_position(grid_pos)
			
			# 다이아몬드 형태의 Polygon2D를 생성하여 하이라이트로 사용합니다.
			var highlight_poly = Polygon2D.new()
			highlight_poly.polygon = PackedVector2Array([
				Vector2(-35, 0), Vector2(0, 17.5),
				Vector2(35, 0), Vector2(0, -17.5)
			])
			highlight_poly.color = color
			
			# 높이에 맞게 하이라이트의 y 위치를 조정합니다.
			var height_offset = -height * 15
			highlight_poly.position = world_pos + Vector2(0, height_offset + 1)
			
			highlight_container.add_child(highlight_poly)
			highlighted_tile_nodes[grid_pos] = highlight_poly

## 모든 하이라이트를 제거합니다.
func clear_highlights():
	for node in highlighted_tile_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	highlighted_tile_nodes.clear()

## 맵의 모든 지형 타일을 그립니다.
func draw_terrain_tiles():
	print("지형 타일 그리기 시작...")
	
	for child in terrain_container.get_children():
		child.queue_free()
	
	for pos in terrain_data.keys():
		var terrain_name = terrain_data[pos]
		var height = height_data.get(pos, 0)
		var world_pos = grid_to_world(pos)
		create_isometric_tile(world_pos, terrain_name, height, pos)
	
	print("이소메트릭 타일 그리기 완료!")

## 하나의 이소메트릭 타일을 생성하는 함수입니다. (타일 상판 + 측면)
func create_isometric_tile(world_pos: Vector2, terrain_name: String, height: int, grid_pos: Vector2i):
	var tile_container = Node2D.new()
	tile_container.name = "Tile_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	tile_container.position = world_pos
	
	var base_color = get_terrain_color(terrain_name, height)
	
	# 타일 상판(다이아몬드) 생성
	var diamond_tile = create_diamond_tile(base_color, height)
	tile_container.add_child(diamond_tile)
	
	# 인접 타일과의 높이를 비교하여 필요한 경우 측면을 생성합니다.
	var needs_sides = calculate_side_visibility(grid_pos, height)
	
	if needs_sides.left:
		var left_side = create_tile_side(base_color.darkened(0.3), height, "left", needs_sides.left_height)
		tile_container.add_child(left_side)
	
	if needs_sides.right:
		var right_side = create_tile_side(base_color.darkened(0.5), height, "right", needs_sides.right_height)
		tile_container.add_child(right_side)
	
	# 높이가 0이 아닐 경우 높이 숫자를 표시합니다. (디버깅용)
	if height != 0:
		var height_label = Label.new()
		height_label.text = str(height)
		height_label.position = Vector2(-8, -5)
		height_label.add_theme_color_override("font_color", Color.BLACK)
		height_label.add_theme_font_size_override("font_size", 12)
		tile_container.add_child(height_label)
	
	terrain_container.add_child(tile_container)

## 타일의 측면을 그려야 하는지 여부를 계산합니다.
func calculate_side_visibility(grid_pos: Vector2i, current_height: int) -> Dictionary:
	var result = { "left": false, "right": false, "left_height": 0, "right_height": 0 }
	
	var left_neighbor_pos = Vector2i(grid_pos.x - 1, grid_pos.y + 1)
	var left_neighbor_height = get_height_at_position(left_neighbor_pos)
	
	var right_neighbor_pos = Vector2i(grid_pos.x + 1, grid_pos.y + 1)
	var right_neighbor_height = get_height_at_position(right_neighbor_pos)
	
	if not is_valid_grid_position(left_neighbor_pos) or current_height >= left_neighbor_height:
		result.left = true
		result.left_height = max(1, current_height - left_neighbor_height)
	
	if not is_valid_grid_position(right_neighbor_pos) or current_height >= right_neighbor_height:
		result.right = true
		result.right_height = max(1, current_height - right_neighbor_height)
	
	# 배경이 비쳐 보이지 않도록 모든 타일에 최소한의 측면을 보장합니다.
	if not result.left and not result.right:
		result.left = true
		result.right = true
		result.left_height = 1
		result.right_height = 1
	
	return result

## 타일의 상판(다이아몬드 모양)을 생성합니다.
func create_diamond_tile(color: Color, height: int) -> Polygon2D:
	var diamond = Polygon2D.new()
	
	# 다이아몬드 모양의 폴리곤 점들
	var points = PackedVector2Array([
		Vector2(0, -35), Vector2(70, 0),
		Vector2(0, 35), Vector2(-70, 0)
	])
	
	# 높이에 따라 y좌표를 오프셋합니다.
	var height_offset = -height * 15
	for i in range(points.size()):
		points[i].y += height_offset
	
	diamond.polygon = points
	diamond.color = color
	
	# 테두리를 추가합니다.
	var outline = Line2D.new()
	outline.width = 1.0
	outline.default_color = Color.BLACK.lightened(0.3)
	outline.closed = true
	for point in points:
		outline.add_point(point)
	diamond.add_child(outline)
	
	return diamond

## 타일의 측면(왼쪽 또는 오른쪽)을 생성합니다.
func create_tile_side(color: Color, tile_height: int, side: String, side_height: int = -1) -> Polygon2D:
	var side_polygon = Polygon2D.new()
	var points = PackedVector2Array()
	
	if side_height == -1: side_height = tile_height
	
	var height_pixels = max(15, side_height * 15)
	var base_height_offset = -tile_height * 15
	
	if side == "left":
		points = PackedVector2Array([
			Vector2(-70, 0 + base_height_offset), Vector2(0, 35 + base_height_offset),
			Vector2(0, 35 + height_pixels), Vector2(-70, 0 + height_pixels)
		])
	else: # right
		points = PackedVector2Array([
			Vector2(0, 35 + base_height_offset), Vector2(70, 0 + base_height_offset),
			Vector2(70, 0 + height_pixels), Vector2(0, 35 + height_pixels)
		])
	
	side_polygon.polygon = points
	side_polygon.color = color
	
	var outline = Line2D.new()
	outline.width = 1.0
	outline.default_color = Color.BLACK.lightened(0.2)
	for point in points: outline.add_point(point)
	outline.add_point(points[0])
	side_polygon.add_child(outline)
	
	return side_polygon

## 지형과 높이에 따라 타일의 기본 색상을 결정합니다.
func get_terrain_color(terrain_name: String, height: int = 0) -> Color:
	var base_color: Color
	
	if height >= 8:
		base_color = Color(0.3, 0.3, 0.3) # 험준한 산
	else:
		match terrain_name:
			"Plain": base_color = Color.LIGHT_GREEN
			"Mountain": base_color = Color.GRAY
			"Forest": base_color = Color.DARK_GREEN
			"Swamp": base_color = Color.SADDLE_BROWN
			"Desert": base_color = Color.SANDY_BROWN
			"RockyTerrain": base_color = Color.DIM_GRAY
			"BurningGround": base_color = Color.RED
			"FrozenGround": base_color = Color.LIGHT_BLUE
			_: base_color = Color.WHITE
	
	# 높이가 높을수록 색상을 약간 더 밝게 조정하여 입체감을 줍니다.
	var height_factor = 1.0 + (height * 0.1)
	if height >= 8: height_factor = 0.5
	height_factor = clamp(height_factor, 0.7, 1.8)
	
	return base_color.lightened(height_factor - 1.0)
