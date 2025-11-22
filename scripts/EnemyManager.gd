extends Node

# 현재 배틀의 적들
var current_enemies: Array[Dictionary] = []
var spawned_enemies: Array[Node] = []

func _ready():
	# 데이터베이스 초기화
	EnemyData.initialize_database()
	EnemyDataExtended.initialize_extended_database()
	EnemySkills.initialize_skills()

# 적 생성 (데이터에서 실제 노드로)
func spawn_enemy(enemy_id: String, position: Vector2i, team: String = "enemy") -> Node:
	var enemy_data = EnemyData.get_enemy(enemy_id)
	if not enemy_data:
		enemy_data = EnemyDataExtended.get_enemy(enemy_id)
	
	if not enemy_data:
		print("적 데이터를 찾을 수 없습니다: ", enemy_id)
		return null
	
	var enemy_character = Character.new()
	enemy_character.character_name = enemy_data.name
	enemy_character.character_id = enemy_id
	enemy_character.grid_position = position
	enemy_character.is_player_controlled = (team == "player")
	
	# Character.gd properties mapping
	enemy_character.max_health = enemy_data.hp
	enemy_character.current_health = enemy_data.hp
	enemy_character.max_mana = enemy_data.mp
	enemy_character.current_mana = enemy_data.mp
	
	# Stats mapping
	enemy_character.base_stats["STR"] = enemy_data.atk
	enemy_character.base_stats["DEF"] = enemy_data.def
	enemy_character.base_stats["DEX"] = enemy_data.dex
	enemy_character.base_stats["RES"] = enemy_data.res
	enemy_character.base_stats["AGI"] = enemy_data.dex
	enemy_character.base_stats["INT"] = enemy_data.atk
	
	enemy_character.move_range = enemy_data.mov
	# enemy_character.jump_height = enemy_data.jump
	
	enemy_character.calculate_current_stats()
	
	# Add active skills to learned_skills
	for skill in enemy_data.active_skills:
		if not skill in enemy_character.learned_skills:
			enemy_character.learned_skills.append(skill)
	
	# 사이즈에 따른 추가 설정
	var scale_mod = 1.0
	match enemy_data.size:
		EnemyData.EnemySize.SMALL:
			scale_mod = 1.0
		EnemyData.EnemySize.MEDIUM:
			scale_mod = 1.2
		EnemyData.EnemySize.LARGE:
			scale_mod = 1.5
		EnemyData.EnemySize.HUGE:
			scale_mod = 2.0
	
	# Apply scale if sprite exists (it's created in _ready, so we might need to store scale)
	enemy_character.scale = Vector3(scale_mod, scale_mod, scale_mod)
	
	spawned_enemies.append(enemy_character)
	return enemy_character

# 스테이지별 적 그룹 생성
func create_stage_enemies(stage_type: String, difficulty: String) -> Array[Dictionary]:
	var enemy_list: Array[String] = []
	
	# 난이도별 기본 적들
	var base_enemies = EnemyDataExtended.get_enemy_group_by_difficulty(difficulty)
	
	# 스테이지 타입별 추가 적들
	match stage_type:
		"forest_stage":
			enemy_list = EnemyDataExtended.get_enemies_for_terrain("Forest")
		"mountain_stage":
			enemy_list = EnemyDataExtended.get_enemies_for_terrain("Mountain")
		"water_stage":
			enemy_list = EnemyDataExtended.get_enemies_for_terrain("River")
		"cave_stage":
			enemy_list = EnemyDataExtended.get_enemies_for_terrain("Cave")
		"volcano_stage":
			enemy_list = EnemyDataExtended.get_enemies_for_terrain("Volcano")
		_:
			enemy_list = base_enemies
	
	# 적 조합 생성
	var stage_enemies: Array[Dictionary] = []
	var enemy_count = _get_enemy_count_by_difficulty(difficulty)
	
	for i in range(enemy_count):
		if enemy_list.size() > 0:
			var random_enemy_id = enemy_list[randi() % enemy_list.size()]
			var enemy_config = {
				"id": random_enemy_id,
				"position": Vector2i(randi() % 10, randi() % 10),  # 임시 위치
				"variant": _get_random_variant()
			}
			stage_enemies.append(enemy_config)
	
	return stage_enemies

# 난이도별 적 수량
func _get_enemy_count_by_difficulty(difficulty: String) -> int:
	match difficulty:
		"easy":
			return randi_range(2, 4)
		"normal":
			return randi_range(3, 5)
		"hard":
			return randi_range(4, 6)
		"expert":
			return randi_range(5, 7)
		"boss":
			return 1
		_:
			return 3

# 랜덤 변형 생성 (엘리트, 약화 등)
func _get_random_variant() -> String:
	var variants = ["normal", "normal", "normal", "elite", "weakened"]
	return variants[randi() % variants.size()]

# 특수 이벤트 적 생성
func create_special_event_enemies(event_type: String) -> Array[Dictionary]:
	var special_enemies: Array[Dictionary] = []
	
	match event_type:
		"tsukumogami_gathering":
			# 쓰쿠모가미들의 모임
			special_enemies = [
				{"id": "kotofurunushi", "position": Vector2i(5, 5), "variant": "elite"},
				{"id": "biwa_bokuboku", "position": Vector2i(4, 5), "variant": "normal"},
				{"id": "chirizuka_kaiou", "position": Vector2i(6, 5), "variant": "boss"}
			]
		
		"mountain_spirits":
			# 산의 정령들
			special_enemies = [
				{"id": "tengu", "position": Vector2i(8, 3), "variant": "elite"},
				{"id": "yamauba", "position": Vector2i(2, 7), "variant": "normal"},
				{"id": "yamawarawa", "position": Vector2i(5, 5), "variant": "normal"},
				{"id": "kodama", "position": Vector2i(3, 4), "variant": "normal"}
			]
		
		"water_yokai_festival":
			# 물 요괊들의 축제
			special_enemies = [
				{"id": "kappa", "position": Vector2i(4, 6), "variant": "elite"},
				{"id": "kawauso", "position": Vector2i(6, 4), "variant": "normal"},
				{"id": "kappa", "position": Vector2i(2, 8), "variant": "normal"}
			]
		
		"fox_fire_parade":
			# 여우불 행렬
			for i in range(5):
				special_enemies.append({
					"id": "kitsunebi",
					"position": Vector2i(i * 2, 5),
					"variant": "normal"
				})
	
	return special_enemies

# 적 강화/약화 적용
func apply_enemy_variant(enemy_character: Node, variant: String):
	match variant:
		"elite":
			# 엘리트: 모든 능력치 +30%, 스킬 강화
			enemy_character.max_health = int(enemy_character.max_health * 1.3)
			enemy_character.current_health = enemy_character.max_health
			enemy_character.base_stats["STR"] = int(enemy_character.base_stats["STR"] * 1.3)
			enemy_character.base_stats["DEF"] = int(enemy_character.base_stats["DEF"] * 1.3)
			
		"weakened":
			# 약화: 모든 능력치 -20%
			enemy_character.max_health = int(enemy_character.max_health * 0.8)
			enemy_character.current_health = enemy_character.max_health
			enemy_character.base_stats["STR"] = int(enemy_character.base_stats["STR"] * 0.8)
			enemy_character.base_stats["DEF"] = int(enemy_character.base_stats["DEF"] * 0.8)
		
		"boss":
			# 보스: 모든 능력치 +50%, 추가 스킬
			enemy_character.max_health = int(enemy_character.max_health * 1.5)
			enemy_character.current_health = enemy_character.max_health
			enemy_character.max_mana = int(enemy_character.max_mana * 1.5)
			enemy_character.current_mana = enemy_character.max_mana
			enemy_character.base_stats["STR"] = int(enemy_character.base_stats["STR"] * 1.5)
			enemy_character.base_stats["DEF"] = int(enemy_character.base_stats["DEF"] * 1.5)

# 적 정보 출력 (디버그용)
func print_enemy_info(enemy_id: String):
	var enemy_data = EnemyData.get_enemy(enemy_id)
	if not enemy_data:
		enemy_data = EnemyDataExtended.get_enemy(enemy_id)
	
	if not enemy_data:
		print("적을 찾을 수 없습니다: ", enemy_id)
		return
	
	print("=== 적 정보 ===")
	print("이름: ", enemy_data.name)
	print("설명: ", enemy_data.description)
	print("타입: ", EnemyData.EnemyType.keys()[enemy_data.enemy_type])
	print("레벨: ", enemy_data.level)
	print("HP: ", enemy_data.hp, " MP: ", enemy_data.mp)
	print("ATK: ", enemy_data.atk, " DEF: ", enemy_data.def)
	print("DEX: ", enemy_data.dex, " RES: ", enemy_data.res)
	print("이동력: ", enemy_data.mov, " 점프: ", enemy_data.jump)
	print("주속성: ", EnemyData.ElementType.keys()[enemy_data.primary_element])
	if enemy_data.secondary_element != EnemyData.ElementType.NONE:
		print("부속성: ", EnemyData.ElementType.keys()[enemy_data.secondary_element])
	print("저항: ", enemy_data.resistances)
	print("약점: ", enemy_data.weaknesses)
	print("특수능력: ", enemy_data.special_abilities)
	print("패시브 스킬: ", enemy_data.passive_skills)
	print("액티브 스킬: ", enemy_data.active_skills)
	print("지형 선호: ", enemy_data.terrain_preferences)
	print("경험치: ", enemy_data.exp_reward, " 골드: ", enemy_data.gold_reward)
	print("드롭 아이템: ", enemy_data.item_drops)
	print("드롭 확률: ", enemy_data.drop_rates)

# 모든 적 목록 출력
func print_all_enemies():
	print("=== 기본 적 목록 ===")
	for enemy_id in EnemyData.enemies.keys():
		print("- ", enemy_id, ": ", EnemyData.enemies[enemy_id].name)
	
	print("\n=== 확장 적 목록 ===")
	for enemy_id in EnemyDataExtended.enemies.keys():
		print("- ", enemy_id, ": ", EnemyDataExtended.enemies[enemy_id].name)

# 적 스킬 사용
func use_enemy_skill(enemy_character: Node, skill_id: String, target_position: Vector2i) -> bool:
	var skill = EnemySkills.get_skill(skill_id)
	if not skill:
		print("스킬을 찾을 수 없습니다: ", skill_id)
		return false
	
	# MP 체크
	if enemy_character.current_mana < skill.mp_cost:
		print("MP가 부족합니다. 필요: ", skill.mp_cost, " 현재: ", enemy_character.current_mana)
		return false
	
	# MP 소모
	enemy_character.current_mana -= skill.mp_cost
	
	print(enemy_character.character_name, "이(가) ", skill.name, " 스킬을 사용했습니다!")
	
	# 스킬 효과 적용 (실제 구현은 전투 시스템에서)
	_apply_skill_effects(skill, enemy_character, target_position)
	
	return true

# 스킬 효과 적용 (기본 구현)
func _apply_skill_effects(skill: EnemySkills.Skill, caster: Node, target_position: Vector2i):
	print("스킬 효과 적용: ", skill.name)
	for effect in skill.effects:
		print("- 효과: ", effect)
