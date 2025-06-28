extends Node2D
class_name BattleGrid

# 그리드 크기 (화면 가득 채우는 큰 맵)
var grid_width: int = 50
var grid_height: int = 65

# 지형 정보 저장
var terrain_data: Dictionary = {}
var height_data: Dictionary = {}

# 타일 ID 정의
enum TileType {
	PLAIN = 0,
	MOUNTAIN = 1,
	FOREST = 2,
	SWAMP = 3,
	DESERT = 4,
	ROCKY = 5,
	BURNING = 6,
	FROZEN = 7
}

# 지형 타입과 이름 매핑
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

signal tile_clicked(grid_pos, terrain_name)
signal tile_hovered(grid_pos, terrain_name, height)
signal character_position_changed(character, old_pos, new_pos)

# 컨테이너 노드들
var terrain_container: Node2D
var highlight_container: Node2D

var highlighted_tile_nodes: Dictionary = {}

# 마우스 호버 관련 변수들
var hovered_tile_pos: Vector2i = Vector2i(-1, -1)
var hover_highlight_node: ColorRect

func _ready():
	print("BattleGrid _ready() 시작")
	
	position = Vector2(400, 200)
	
	# 컨테이너들 설정
	setup_containers()
	
	print("맵 생성 시작...")
	generate_test_map()
	
	print("타일 그리기 시작...")
	call_deferred("draw_terrain_tiles")
	
	print("BattleGrid 초기화 완료")

func setup_containers():
	terrain_container = Node2D.new()
	terrain_container.name = "TerrainContainer"
	terrain_container.y_sort_enabled = true
	add_child(terrain_container)
	
	highlight_container = Node2D.new()
	highlight_container.name = "HighlightContainer"
	highlight_container.y_sort_enabled = true
	highlight_container.z_index = 1 # 지형 위에 그려지도록 설정
	add_child(highlight_container)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("BattleGrid _unhandled_input 호출됨")
		
		var mouse_pos = get_global_mouse_position()
		var local_pos = to_local(mouse_pos)
		var grid_pos = local_to_grid(local_pos)
		
		print("BattleGrid 마우스 클릭 위치: ", mouse_pos)
		print("로컬 위치: ", local_pos)
		print("그리드 위치: ", grid_pos)
		
		if is_valid_grid_position(grid_pos):
			var terrain_name = get_terrain_at_position(grid_pos)
			emit_signal("tile_clicked", grid_pos, terrain_name)
			print("클릭된 타일: ", grid_pos, " 지형: ", terrain_name)
		else:
			print("유효하지 않은 그리드 위치: ", grid_pos)

func _process(_delta):
	# 마우스 호버 감지
	handle_mouse_hover()

func handle_mouse_hover():
	var mouse_pos = get_global_mouse_position()
	var local_pos = to_local(mouse_pos)
	var grid_pos = local_to_grid(local_pos)
	
	# 유효한 그리드 위치가 아니거나 이미 호버된 타일인 경우 무시
	if not is_valid_grid_position(grid_pos):
		if hovered_tile_pos != Vector2i(-1, -1):
			clear_hover_highlight()
			hovered_tile_pos = Vector2i(-1, -1)
		return
	
	if grid_pos == hovered_tile_pos:
		return
	
	# 이전 호버 하이라이트 제거
	clear_hover_highlight()
	
	# 새로운 타일에 호버 하이라이트 추가
	hovered_tile_pos = grid_pos
	show_hover_highlight(grid_pos)
	
	# 타일 정보를 BattleScene에 전달
	var terrain_name = get_terrain_at_position(grid_pos)
	var height = get_height_at_position(grid_pos)
	emit_signal("tile_hovered", grid_pos, terrain_name, height)

func show_hover_highlight(grid_pos: Vector2i):
	# 호버 하이라이트용 노드 생성 (간단한 방식으로 변경)
	if not hover_highlight_node:
		hover_highlight_node = ColorRect.new()
		hover_highlight_node.color = Color(1.0, 1.0, 0.0, 0.3)  # 반투명 노란색 배경
		hover_highlight_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hover_highlight_node)  # 직접 BattleGrid에 추가
	
	# 월드 좌표로 직접 변환하여 위치 설정
	var world_pos = grid_to_world(grid_pos)
	
	hover_highlight_node.position = world_pos - Vector2(35, 17.5)  # 타일 중심에 맞춤
	hover_highlight_node.size = Vector2(70, 35)  # 이소메트릭 다이아몬드 크기
	hover_highlight_node.show()

func clear_hover_highlight():
	if hover_highlight_node:
		hover_highlight_node.hide()

func generate_test_map():
	print("랜덤 고저차 맵 생성 시작...")
	print("맵 크기: ", grid_width, "x", grid_height, " = ", grid_width * grid_height, "개 타일")
	
	# 기존 데이터 클리어
	terrain_data.clear()
	height_data.clear()
	
	# 1단계: 높이 맵 생성 (Perlin noise 같은 효과)
	generate_height_map()
	
			# 2단계: 높이에 따른 지형 타입 결정 - 모든 타일을 빠짐없이 생성
	var tile_count = 0
	for x in range(grid_width):
		for y in range(grid_height):
			var grid_pos = Vector2i(x, y)
			var height = height_data[grid_pos]
			var tile_type = get_tile_type_by_height_and_position(x, y, height)
			
			# 지형 데이터 저장 (TileMap은 사용하지 않고 수동으로 그림)
			var terrain_name = tile_to_terrain[tile_type]
			terrain_data[grid_pos] = terrain_name
			tile_count += 1
	
	print("맵 생성 완료! 총 ", tile_count, "개 타일 생성됨")
	
	# 데이터 검증
	print("terrain_data 크기: ", terrain_data.size())
	print("height_data 크기: ", height_data.size())

func generate_height_map():
	# 랜덤 시드 설정
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# 높이 맵 생성 (단순한 노이즈 시뮬레이션) - 원래대로 복구
	for x in range(grid_width):
		for y in range(grid_height):
			var grid_pos = Vector2i(x, y)
			
			# 여러 주파수의 노이즈를 조합 (더 작은 범위로)
			var height = 0.0
			height += get_noise_value(x, y, 10.0, rng) * 1.5  # 큰 언덕 (축소)
			height += get_noise_value(x, y, 5.0, rng) * 1.0   # 중간 지형 (축소)
			height += get_noise_value(x, y, 2.0, rng) * 0.5   # 작은 변화 (축소)
			
			# 높이를 정수로 변환 (-1 ~ +10 범위로 축소)
			var final_height = int(round(height))
			final_height = clamp(final_height, -1, 10)
			
			height_data[grid_pos] = final_height

func get_noise_value(x: int, y: int, frequency: float, rng: RandomNumberGenerator) -> float:
	# 간단한 노이즈 함수 (실제 Perlin noise는 아니지만 비슷한 효과)
	var sample_x = x / frequency
	var sample_y = y / frequency
	
	# 여러 점의 랜덤값을 보간
	var x1 = int(sample_x)
	var y1 = int(sample_y)
	var x2 = x1 + 1
	var y2 = y1 + 1
	
	# 4개 모서리의 값
	var v1 = get_pseudo_random(x1, y1, rng.seed)
	var v2 = get_pseudo_random(x2, y1, rng.seed)
	var v3 = get_pseudo_random(x1, y2, rng.seed)
	var v4 = get_pseudo_random(x2, y2, rng.seed)
	
	# 선형 보간
	var fx = sample_x - x1
	var fy = sample_y - y1
	
	var top = lerp(v1, v2, fx)
	var bottom = lerp(v3, v4, fx)
	return lerp(top, bottom, fy)

func get_pseudo_random(x: int, y: int, seed_val: int) -> float:
	# 의사 랜덤 함수
	var hash_val = (x * 374761393 + y * 668265263 + seed_val) % 2147483647
	return (hash_val % 2000) / 1000.0 - 1.0  # -1.0 ~ 1.0 범위

func get_tile_type_by_height_and_position(x: int, y: int, height: int) -> int:
	# 높이와 위치에 따른 지형 타입 결정 - 원래 높이 범위로 복구
	var rng = RandomNumberGenerator.new()
	rng.seed = x * 1000 + y  # 위치 기반 시드
	
	match height:
		-1:  # 낮은 지역 (늪, 평지)
			var types = [TileType.SWAMP, TileType.PLAIN]
			return types[rng.randi() % types.size()]
		0:  # 평지
			var types = [TileType.PLAIN, TileType.FOREST, TileType.DESERT]
			return types[rng.randi() % types.size()]
		1, 2:  # 약간 높은 지역
			var types = [TileType.PLAIN, TileType.FOREST, TileType.ROCKY]
			return types[rng.randi() % types.size()]
		3, 4, 5:  # 높은 지역
			var types = [TileType.MOUNTAIN, TileType.ROCKY]
			return types[rng.randi() % types.size()]
		_:  # 6+ 매우 높은 산 (접근 불가)
			if height >= 8:
				return TileType.ROCKY  # 험준한 바위산
			else:
				return TileType.MOUNTAIN

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height

func get_terrain_at_position(grid_pos: Vector2i) -> String:
	if grid_pos in terrain_data:
		return terrain_data[grid_pos]
	return "Plain"

func get_height_at_position(grid_pos: Vector2i) -> int:
	if grid_pos in height_data:
		return height_data[grid_pos]
	return 0

# 이동 가능한 타일들을 계산 (이동력 고려)
func get_reachable_tiles(start_pos: Vector2i, move_range: int) -> Array:
	print("이동 가능 타일 계산 시작: ", start_pos, " 범위: ", move_range)
	
	var reachable = []
	var visited = {}
	var queue = [{pos = start_pos, cost = 0}]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current.pos
		var cost = current.cost
		
		if pos in visited:
			continue
			
		visited[pos] = true
		if cost <= move_range:
			reachable.append(pos)
		
		# 인접한 4방향 확인
		var neighbors = [
			Vector2i(pos.x + 1, pos.y),
			Vector2i(pos.x - 1, pos.y),
			Vector2i(pos.x, pos.y + 1),
			Vector2i(pos.x, pos.y - 1)
		]
		
		for neighbor in neighbors:
			if is_valid_grid_position(neighbor) and not neighbor in visited:
				var neighbor_height = get_height_at_position(neighbor)
				
				# 높이 8 이상은 접근 불가 (험준한 산) - 원래 높이 범위에 맞게 조정
				if neighbor_height >= 8:
					continue
				
				var terrain_name = get_terrain_at_position(neighbor)
				var move_cost = GameData.TERRAINS[terrain_name]["move_cost"]
				
				# 높이차가 너무 크면 이동 불가 (2 이상 차이로 조정)
				var current_height = get_height_at_position(pos)
				var height_diff = abs(neighbor_height - current_height)
				if height_diff >= 2:
					move_cost += height_diff  # 높이차 패널티
				
				var new_cost = cost + move_cost
				
				if new_cost <= move_range:
					queue.append({pos = neighbor, cost = new_cost})
	
	print("계산된 이동 가능 타일 수: ", reachable.size())
	if reachable.size() > 0:
		print("첫 5개 타일: ", reachable.slice(0, min(5, reachable.size())))
	
	return reachable

# 공격 범위 계산 (직선 거리와 높이 고려)
func get_attack_range(attacker_pos: Vector2i, weapon_range: int, height_limit: int = 3) -> Array:
	var attackable = []
	var attacker_height = get_height_at_position(attacker_pos)
	
	for x in range(max(0, attacker_pos.x - weapon_range), min(grid_width, attacker_pos.x + weapon_range + 1)):
		for y in range(max(0, attacker_pos.y - weapon_range), min(grid_height, attacker_pos.y + weapon_range + 1)):
			var target_pos = Vector2i(x, y)
			var distance = attacker_pos.distance_to(target_pos)
			
			if distance <= weapon_range and target_pos != attacker_pos:
				var target_height = get_height_at_position(target_pos)
				var height_diff = abs(target_height - attacker_height)
				
				# 높이차가 너무 크면 공격 불가
				if height_diff <= height_limit:
					attackable.append(target_pos)
	
	return attackable

# 시야 계산 (높이와 장애물 고려)
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

# 시선 차단 확인
func has_line_of_sight(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	var from_height = get_height_at_position(from_pos)
	var to_height = get_height_at_position(to_pos)
	
	# 단순한 높이 기반 시야 계산
	# 실제로는 더 복잡한 레이캐스팅이 필요할 수 있음
	var height_advantage = from_height - to_height
	
	# 높은 곳에서 낮은 곳을 보는 것은 쉬움
	if height_advantage > 0:
		return true
	
	# 같은 높이거나 낮은 곳에서는 거리에 따라 제한
	var distance = from_pos.distance_to(to_pos)
	return distance <= 3  # 기본 시야 거리
	
# 지형 변화 (화염마법으로 숲이 불타는 땅이 되는 등)
func change_terrain(grid_pos: Vector2i, new_terrain: String):
	if is_valid_grid_position(grid_pos):
		terrain_data[grid_pos] = new_terrain
		
		# 새로운 지형의 높이 정보 업데이트
		if GameData.TERRAINS.has(new_terrain):
			height_data[grid_pos] = GameData.TERRAINS[new_terrain]["height"]
		else:
			height_data[grid_pos] = 0  # 기본값
		
		# 시각적으로 타일 변경 - 해당 타일만 다시 그리기
		update_single_tile(grid_pos)
		
		print("지형 변화: ", grid_pos, " -> ", new_terrain)

# 단일 타일 업데이트 함수
func update_single_tile(grid_pos: Vector2i):
	# 기존 타일 제거
	var tile_name = "Tile_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	for child in terrain_container.get_children():
		if child.name == tile_name:
			child.queue_free()
			break
	
	# 새 타일 생성
	var terrain_name = terrain_data[grid_pos]
	var height = height_data.get(grid_pos, 0)
	var world_pos = grid_to_world(grid_pos)
	create_isometric_tile(world_pos, terrain_name, height, grid_pos)

# 이소메트릭 좌표 변환 함수들
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	var x = (grid_pos.x - grid_pos.y) * 35  # TILE_WIDTH / 2
	var y = (grid_pos.x + grid_pos.y) * 17.5 # TILE_HEIGHT / 2
	return Vector2(x, y)

func grid_to_iso(grid_pos: Vector2i) -> Vector2:
	# 그리드 좌표를 이소메트릭 좌표로 변환
	var x = (grid_pos.x - grid_pos.y) * 35  # 타일 가로 간격
	var y = (grid_pos.x + grid_pos.y) * 17.5  # 타일 세로 간격
	return Vector2(x, y)

func iso_to_world(iso_pos: Vector2) -> Vector2:
	# 이소메트릭 좌표를 월드 좌표로 변환 (스케일링)
	return Vector2(iso_pos.x * 2, iso_pos.y * 2)

func local_to_grid(local_pos: Vector2) -> Vector2i:
	var iso_x = local_pos.x / 70.0 # TILE_WIDTH
	var iso_y = local_pos.y / 35.0 # TILE_HEIGHT
	
	var grid_x = round(iso_y + iso_x)
	var grid_y = round(iso_y - iso_x)
	
	return Vector2i(grid_x, grid_y)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return local_to_grid(to_local(world_pos))

# 하이라이트 시스템 설정
func highlight_tiles(tiles: Array, color: Color):
	clear_highlights()
	
	for grid_pos in tiles:
		if is_valid_grid_position(grid_pos):
			var world_pos = grid_to_world(grid_pos)
			var height = get_height_at_position(grid_pos)
			
			var highlight_poly = Polygon2D.new()
			highlight_poly.polygon = PackedVector2Array([
				Vector2(-35, 0), Vector2(0, 17.5),
				Vector2(35, 0), Vector2(0, -17.5)
			])
			highlight_poly.color = color
			
			var height_offset = -height * 15
			highlight_poly.position = world_pos + Vector2(0, height_offset + 1)
			
			highlight_container.add_child(highlight_poly)
			highlighted_tile_nodes[grid_pos] = highlight_poly

func clear_highlights():
	for node in highlighted_tile_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	highlighted_tile_nodes.clear()

# 이소메트릭 타일 렌더링
func draw_terrain_tiles():
	print("지형 타일 그리기 시작...")
	
	# 기존 타일들 제거
	for child in terrain_container.get_children():
		child.queue_free()
	
	for pos in terrain_data.keys():
		var terrain_name = terrain_data[pos]
		var height = height_data.get(pos, 0)
		var world_pos = grid_to_world(pos)
		create_isometric_tile(world_pos, terrain_name, height, pos)
	
	print("이소메트릭 타일 그리기 완료!")

func create_isometric_tile(world_pos: Vector2, terrain_name: String, height: int, grid_pos: Vector2i):
	var tile_container = Node2D.new()
	tile_container.name = "Tile_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	tile_container.position = world_pos
	
	# 타일 베이스 색상
	var base_color = get_terrain_color(terrain_name, height)
	
	# 이소메트릭 다이아몬드 타일 생성
	var diamond_tile = create_diamond_tile(base_color, height)
	tile_container.add_child(diamond_tile)
	
	# 인접 타일과의 높이 차이 계산하여 측면 생성 여부 결정
	var needs_sides = calculate_side_visibility(grid_pos, height)
	
	# 왼쪽 측면이 필요한 경우 (현재 타일이 더 높거나 같을 때)
	if needs_sides.left:
		var left_side = create_tile_side(base_color.darkened(0.3), height, "left", needs_sides.left_height)
		tile_container.add_child(left_side)
	
	# 오른쪽 측면이 필요한 경우 (현재 타일이 더 높거나 같을 때)
	if needs_sides.right:
		var right_side = create_tile_side(base_color.darkened(0.5), height, "right", needs_sides.right_height)
		tile_container.add_child(right_side)
	
	# 높이 라벨 (선택적)
	if height != 0:
		var height_label = Label.new()
		height_label.text = str(height)
		height_label.position = Vector2(-8, -5)
		height_label.add_theme_color_override("font_color", Color.BLACK)
		height_label.add_theme_font_size_override("font_size", 12)
		tile_container.add_child(height_label)
	
	terrain_container.add_child(tile_container)

func calculate_side_visibility(grid_pos: Vector2i, current_height: int) -> Dictionary:
	# 인접 타일들과의 높이 차이를 계산하여 어떤 측면이 필요한지 결정
	var result = {
		"left": false,
		"right": false,
		"left_height": 0,
		"right_height": 0
	}
	
	# 왼쪽 측면 (남서쪽 타일과 비교)
	var left_neighbor_pos = Vector2i(grid_pos.x - 1, grid_pos.y + 1)
	var left_neighbor_height = get_height_at_position(left_neighbor_pos)
	
	# 오른쪽 측면 (남동쪽 타일과 비교)
	var right_neighbor_pos = Vector2i(grid_pos.x + 1, grid_pos.y + 1)
	var right_neighbor_height = get_height_at_position(right_neighbor_pos)
	
	# 현재 타일이 더 높거나, 인접 타일이 존재하지 않는 경우 측면 표시
	# 또는 높이가 0이어도 최소한의 측면을 표시하여 배경이 보이지 않도록 함
	
	# 왼쪽 측면 조건
	if not is_valid_grid_position(left_neighbor_pos) or current_height >= left_neighbor_height:
		result.left = true
		result.left_height = max(1, current_height - left_neighbor_height)  # 최소 1픽셀 높이
	
	# 오른쪽 측면 조건
	if not is_valid_grid_position(right_neighbor_pos) or current_height >= right_neighbor_height:
		result.right = true
		result.right_height = max(1, current_height - right_neighbor_height)  # 최소 1픽셀 높이
	
	# 모든 타일에 최소한의 측면을 표시하여 배경 누출 방지
	if not result.left and not result.right:
		result.left = true
		result.right = true
		result.left_height = 1
		result.right_height = 1
	
	return result

func create_diamond_tile(color: Color, height: int) -> Polygon2D:
	var diamond = Polygon2D.new()
	
	# 이소메트릭 다이아몬드 형태 점들 (측면 배경색까지 완전히 덮도록 훨씬 더 크게)
	var points = PackedVector2Array([
		Vector2(0, -35),    # 위 (훨씬 더 높게)
		Vector2(70, 0),     # 오른쪽 (훨씬 더 넓게)
		Vector2(0, 35),     # 아래 (훨씬 더 낮게)
		Vector2(-70, 0)     # 왼쪽 (훨씬 더 넓게)
	])
	
	# 높이에 따른 Y 오프셋
	var height_offset = -height * 15  # 훨씬 더 큰 높이 효과
	for i in range(points.size()):
		points[i].y += height_offset
	
	diamond.polygon = points
	diamond.color = color
	
	# 테두리 추가
	var outline = Line2D.new()
	outline.width = 1.0
	outline.default_color = Color.BLACK.lightened(0.3)
	outline.closed = true
	for point in points:
		outline.add_point(point)
	diamond.add_child(outline)
	
	return diamond

func create_tile_side(color: Color, tile_height: int, side: String, side_height: int = -1) -> Polygon2D:
	var side_polygon = Polygon2D.new()
	var points = PackedVector2Array()
	
	# side_height가 지정되지 않으면 타일 높이 사용
	if side_height == -1:
		side_height = tile_height
	
	# 실제 측면 높이를 픽셀로 변환 (최소 15픽셀 보장으로 배경 누출 방지)
	var height_pixels = max(15, side_height * 15)
	var base_height_offset = -tile_height * 15
	
	if side == "left":
		# 왼쪽 측면 (배경색 완전히 덮도록 더 크게)
		points = PackedVector2Array([
			Vector2(-70, 0 + base_height_offset),      # 다이아몬드 왼쪽 점
			Vector2(0, 35 + base_height_offset),       # 다이아몬드 아래 점
			Vector2(0, 35 + height_pixels),            # 바닥 아래 점 (높이 확장)
			Vector2(-70, 0 + height_pixels)            # 바닥 왼쪽 점 (높이 확장)
		])
	else: # right
		# 오른쪽 측면 (배경색 완전히 덮도록 더 크게)
		points = PackedVector2Array([
			Vector2(0, 35 + base_height_offset),       # 다이아몬드 아래 점
			Vector2(70, 0 + base_height_offset),       # 다이아몬드 오른쪽 점
			Vector2(70, 0 + height_pixels),            # 바닥 오른쪽 점 (높이 확장)
			Vector2(0, 35 + height_pixels)             # 바닥 아래 점 (높이 확장)
		])
	
	side_polygon.polygon = points
	side_polygon.color = color
	
	# 측면 테두리
	var outline = Line2D.new()
	outline.width = 1.0
	outline.default_color = Color.BLACK.lightened(0.2)
	for point in points:
		outline.add_point(point)
	outline.add_point(points[0])  # 닫기
	side_polygon.add_child(outline)
	
	return side_polygon

func get_terrain_color(terrain_name: String, height: int = 0) -> Color:
	var base_color: Color
	
	# 높이 8 이상의 험준한 산은 특별한 색상으로 표시 (접근 불가) - 원래 범위로 복구
	if height >= 8:
		base_color = Color(0.3, 0.3, 0.3)  # 진한 회색
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
	
	# 높이에 따른 명도 조정 (원래 범위로)
	var height_factor: float
	if height >= 8:
		height_factor = 0.5  # 접근 불가 지역은 어둡게
	else:
		height_factor = 1.0 + (height * 0.1)  # 높이 1당 10% 밝기 증가
		height_factor = clamp(height_factor, 0.7, 1.8)
	
	return Color(
		base_color.r * height_factor,
		base_color.g * height_factor,
		base_color.b * height_factor,
		base_color.a
	) 
