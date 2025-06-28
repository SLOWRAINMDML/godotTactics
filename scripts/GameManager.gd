extends Node

signal turn_changed(current_turn)
signal battle_started
signal battle_ended

enum GameState {
	MENU,
	BATTLE_PREPARATION,
	BATTLE,
	BATTLE_END,
	CHARACTER_MENU
}

enum TurnPhase {
	PLAYER_TURN,
	ENEMY_TURN,
	ENVIRONMENT_TURN
}

var current_state: GameState = GameState.MENU
var current_phase: TurnPhase = TurnPhase.PLAYER_TURN
var turn_count: int = 0
var battle_time: float = 0.0

# 참가중인 캐릭터들
var player_characters: Array = []
var enemy_characters: Array = []
var current_character_index: int = 0

# 외부 전황 시뮬레이션
var external_events: Array = []
var intelligence_info: Dictionary = {}
var intelligence_age: float = 0.0  # 정보의 신선도

func _ready():
	print("GameManager 싱글톤이 초기화되었습니다.")

func _process(delta):
	if current_state == GameState.BATTLE:
		battle_time += delta
		intelligence_age += delta
		
		# 외부 전황 시뮬레이션
		simulate_external_events(delta)

func start_battle(player_chars: Array, enemy_chars: Array):
	player_characters = player_chars
	enemy_characters = enemy_chars
	current_state = GameState.BATTLE
	current_phase = TurnPhase.PLAYER_TURN
	turn_count = 0
	battle_time = 0.0
	current_character_index = 0
	
	# 민첩도 순으로 턴 순서 정렬
	player_characters.sort_custom(_compare_agility)
	enemy_characters.sort_custom(_compare_agility)
	
	emit_signal("battle_started")
	print("전투가 시작되었습니다!")

func _compare_agility(a, b):
	return a["stats"]["AGI"] > b["stats"]["AGI"]

func next_turn():
	turn_count += 1
	
	# 턴 페이즈 전환
	match current_phase:
		TurnPhase.PLAYER_TURN:
			current_phase = TurnPhase.ENEMY_TURN
		TurnPhase.ENEMY_TURN:
			current_phase = TurnPhase.ENVIRONMENT_TURN
		TurnPhase.ENVIRONMENT_TURN:
			current_phase = TurnPhase.PLAYER_TURN
			# 환경 변화 처리
			process_environment_turn()
	
	emit_signal("turn_changed", current_phase)
	print("턴 변경: ", TurnPhase.keys()[current_phase])

func process_environment_turn():
	# 외부 전황 변화 적용
	for event in external_events:
		if event["trigger_turn"] <= turn_count:
			apply_external_event(event)
			external_events.erase(event)
	
	# 지형 상태 변화 (불타는 땅 -> 재, 얼어붙은 땅 -> 해빙 등)
	update_terrain_states()

func apply_external_event(event: Dictionary):
	print("외부 이벤트 발생: ", event["description"])
	# 증원, 정보 변화, 환경 변화 등을 처리

func update_terrain_states():
	# 지형 상태의 자연적 변화 처리
	pass

func simulate_external_events(delta: float):
	# 정보의 신선도 감소
	intelligence_age += delta
	
	# 랜덤 외부 이벤트 생성
	if randf() < 0.01:  # 1% 확률로 매 프레임
		generate_random_external_event()

func generate_random_external_event():
	var events = [
		{"description": "적 증원 부대 발견", "type": "enemy_reinforcement", "trigger_turn": turn_count + randi_range(3, 8)},
		{"description": "아군 지원 요청 승인", "type": "ally_support", "trigger_turn": turn_count + randi_range(2, 5)},
		{"description": "날씨 변화 - 안개 발생", "type": "weather_change", "trigger_turn": turn_count + randi_range(1, 3)}
	]
	
	var event = events[randi() % events.size()]
	external_events.append(event)
	print("새로운 외부 이벤트 예정: ", event["description"])

# 정보 획득 (정찰, 스파이 등)
func acquire_intelligence(info_type: String, info_data: Dictionary):
	intelligence_info[info_type] = {
		"data": info_data,
		"acquired_time": battle_time
	}
	intelligence_age = 0.0
	print("새로운 정보 획득: ", info_type)

# 정보 유효성 확인 (빠른 전투 종료시 유리함)
func is_intelligence_valid(info_type: String, max_age: float = 30.0) -> bool:
	if info_type in intelligence_info:
		var info_age = battle_time - intelligence_info[info_type]["acquired_time"]
		return info_age <= max_age
	return false

# 데미지 계산 (지형, 스킬, 적성 고려)
func calculate_damage(attacker: Dictionary, defender: Dictionary, skill_name: String, terrain_name: String) -> int:
	var skill = GameData.SKILLS[skill_name]
	var terrain = GameData.TERRAINS[terrain_name]
	var base_damage = 0
	
	# 기본 데미지 계산
	if skill["type"] == "Physical":
		base_damage = attacker["stats"]["STR"] - defender["stats"]["DEF"]
	elif skill["type"] == "Magic":
		base_damage = attacker["stats"]["INT"] - defender["stats"]["RES"]
	
	var damage = max(1, base_damage + skill["power"])
	
	# 지형 효과 적용
	if terrain["effect"] == "HighGroundBonus" and skill["type"] == "Physical":
		damage = int(damage * 1.2)
		print("고지대 보너스 적용!")
	
	# 무기 적성 보너스
	var attacker_class = GameData.CLASSES[attacker["class"]]
	if skill_name in attacker_class["skills"]:
		# 스킬 사용 가능한 클래스면 보너스
		damage = int(damage * 1.1)
	
	# 환경 상호작용
	var interaction = GameData.get_terrain_skill_interaction(terrain_name, skill_name)
	if interaction["multiplier"] > 1.0:
		damage = int(damage * interaction["multiplier"])
		print("환경 상호작용 보너스: x", interaction["multiplier"])
		
		# 지형 변화 효과
		if interaction["effect"] != null:
			apply_terrain_change_effect(interaction["effect"], terrain_name)
	
	return damage

func apply_terrain_change_effect(effect_name: String, terrain_name: String):
	match effect_name:
		"CreateBurningGround":
			print("🔥 ", terrain_name, "이(가) 불타는 땅으로 변화했습니다!")
		"Electrify":
			print("⚡ 전기가 흘러 주변 유닛들이 감전되었습니다!")
		"ForestFire":
			print("🔥 숲이 대화재로 번지고 있습니다!")

func end_battle(victory: bool):
	current_state = GameState.BATTLE_END
	emit_signal("battle_ended")
	
	if victory:
		print("승리! 전투 시간: ", battle_time, "초")
		# 빠른 승리 시 정보 보존
		if battle_time < 60.0:
			print("신속한 승리로 정보가 유지됩니다!")
	else:
		print("패배...") 
