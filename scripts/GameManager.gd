# -----------------------------------------------------------------------------
# [후임자를 위한 안내]
#
# GameManager.gd (게임 매니저)
#
# [역할]
# 이 스크립트는 Godot의 '싱글톤(Singleton)' 또는 '오토로드(Autoload)' 기능으로 등록되어
# 프로젝트 어디에서나 접근할 수 있는 전역 관리자입니다.
# 게임의 전체적인 상태(메뉴, 전투 중, 전투 종료 등)와 턴 기반 전투의 흐름을 제어합니다.
#
# [싱글톤(Singleton)이란?]
# - 프로젝트 전체에 오직 하나만 존재하는 특별한 객체입니다.
# - 어떤 씬이나 스크립트에서도 `GameManager.함수명()`처럼 직접 호출하여 사용할 수 있습니다.
# - 'project.godot' 파일의 [autoload] 섹션에 등록되어 관리됩니다.
# - 여러 씬에 걸쳐 공유되어야 하는 데이터나 기능을 관리할 때 매우 유용합니다.
#
# [Godot 학습 팁: 시그널(Signal)]
# - Godot의 핵심 기능 중 하나로, '이벤트 발생기'라고 생각하면 쉽습니다.
# - 예를 들어, `turn_changed` 시그널은 턴이 바뀔 때마다 "턴이 바뀌었다!"고 외치는 역할을 합니다.
# - 다른 스크립트에서는 이 시그널에 자신의 함수를 연결(`connect`)해 두었다가,
#   시그널이 발생하면 연결된 함수를 실행하여 특정 동작(예: UI 업데이트)을 수행합니다.
# - 이를 통해 스크립트 간의 직접적인 참조를 줄여, 보다 유연하고 독립적인 구조(느슨한 결합)를 만들 수 있습니다.
# -----------------------------------------------------------------------------
extends Node

<<<<<<< HEAD
signal turn_order_updated(turn_order)
signal turn_advanced(current_character)
signal battle_started
signal battle_ended
=======
# [시그널 정의]
# 이 스크립트가 발생시키는 이벤트들입니다. 다른 노드들이 이 신호에 반응할 수 있습니다.
signal turn_changed(current_turn) # 턴이 변경될 때 발생. 현재 턴 페이즈를 전달.
signal battle_started             # 전투가 시작될 때 발생.
signal battle_ended               # 전투가 종료될 때 발생.
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51

# [열거형(Enum) 정의]
# 게임의 여러 상태를 명확한 이름으로 관리하기 위해 사용합니다.
# 숫자로 상태를 관리하는 것보다 코드의 가독성을 높여줍니다. (예: 0 대신 GameState.MENU)

# 게임의 전체적인 상태를 나타냅니다.
enum GameState {
	MENU,                 # 메인 메뉴 화면
	BATTLE_PREPARATION,   # 전투 준비 화면
	BATTLE,               # 전투 진행 중
	BATTLE_END,           # 전투 종료 화면
	CHARACTER_MENU        # 캐릭터 정보/관리 화면
}

<<<<<<< HEAD
var current_state: GameState = GameState.MENU
var round_count: int = 0
var battle_time: float = 0.0

# 모든 캐릭터의 행동 순서
var turn_order: Array = []
var current_turn_index: int = -1
=======
# 턴제 전투의 단계를 나타냅니다.
enum TurnPhase {
	PLAYER_TURN,          # 플레이어 턴
	ENEMY_TURN,           # 적군 턴
	ENVIRONMENT_TURN      # 환경 효과 턴 (지형 변화, 상태 이상 데미지 등)
}

# [상태 변수]
var current_state: GameState = GameState.MENU # 현재 게임 상태를 저장.
var current_phase: TurnPhase = TurnPhase.PLAYER_TURN # 현재 턴 페이즈를 저장.
var turn_count: int = 0                      # 전체 턴 수를 계산.
var battle_time: float = 0.0                 # 전투가 시작된 후 경과 시간.

# [캐릭터 데이터]
# 현재 전투에 참여 중인 캐릭터들의 데이터를 배열로 저장합니다.
# BattleScene에서 실제 캐릭터 객체를 관리하고, 여기서는 데이터만 참조합니다.
var player_characters: Array = []
var enemy_characters: Array = []
var current_character_index: int = 0
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51

# [외부 전황 시스템]
# 이 게임의 독창적인 시스템으로, 현재 전투 외적인 상황을 시뮬레이션합니다.
# 예를 들어, '3턴 후에 적 증원군 도착'과 같은 이벤트를 관리합니다.
var external_events: Array = []
var intelligence_info: Dictionary = {} # 정찰, 스파이 활동으로 얻은 정보.
var intelligence_age: float = 0.0      # 정보의 신선도. 오래된 정보는 가치가 떨어짐.

# Godot 엔진이 이 노드를 씬 트리에 추가할 때 자동으로 호출하는 내장 함수입니다.
# 싱글톤이므로 게임 시작 시 단 한 번 호출됩니다.
func _ready():
	print("GameManager 싱글톤이 초기화되었습니다.")

# Godot 엔진이 매 프레임마다 호출하는 내장 함수입니다.
# @param delta: 이전 프레임과의 시간 간격(초).
func _process(delta):
	# 현재 게임 상태가 'BATTLE'(전투 중)일 때만 아래 로직을 실행합니다.
	if current_state == GameState.BATTLE:
		battle_time += delta       # 전투 시간 누적
		intelligence_age += delta  # 정보의 신선도 감소 (시간이 지날수록 오래된 정보가 됨)
		
		# 외부 전황 시뮬레이션 로직을 실행합니다.
		simulate_external_events(delta)

<<<<<<< HEAD
func start_battle(all_characters: Array):
	turn_order = all_characters.filter(func(c): return is_instance_valid(c))
=======
## 전투를 시작하는 함수입니다.
## BattleScene에서 테스트 전투를 설정할 때 호출됩니다.
## @param player_chars: 플레이어 캐릭터 데이터 배열
## @param enemy_chars: 적 캐릭터 데이터 배열
func start_battle(player_chars: Array, enemy_chars: Array):
	player_characters = player_chars
	enemy_characters = enemy_chars
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51
	current_state = GameState.BATTLE
	round_count = 1
	battle_time = 0.0
	current_turn_index = -1
	
<<<<<<< HEAD
	# DEX 스탯 기준으로 행동 순서 정렬
	turn_order.sort_custom(_compare_dex)
=======
	# 캐릭터의 민첩성(AGI) 스탯을 기준으로 턴 순서를 정렬합니다.
	# 민첩성이 높은 캐릭터가 먼저 행동하게 됩니다.
	player_characters.sort_custom(_compare_agility)
	enemy_characters.sort_custom(_compare_agility)
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51
	
	# "전투가 시작되었다"는 신호를 보냅니다.
	# BattleScene 같은 곳에서 이 신호를 받아 전투 시작 연출 등을 처리할 수 있습니다.
	emit_signal("battle_started")
<<<<<<< HEAD
	emit_signal("turn_order_updated", turn_order)
	print("전투 시작! DEX 기반 행동 순서가 결정되었습니다.")
	
	# 첫 턴 시작
	advance_turn()

func _compare_dex(a: Character, b: Character):
	# Character 노드를 직접 비교
	var dex_a = a.current_stats.get("DEX", 0)
	var dex_b = b.current_stats.get("DEX", 0)
	return dex_a > dex_b

func advance_turn():
	current_turn_index += 1
	
	# 모든 캐릭터가 행동을 마쳤으면 새 라운드 시작
	if current_turn_index >= turn_order.size():
		current_turn_index = 0
		round_count += 1
		print("== 새로운 라운드 시작: 라운드 ", round_count, " ==")
		emit_signal("turn_order_updated", turn_order)
	
	# 유효한 캐릭터를 찾을 때까지 인덱스 증가
	while current_turn_index < turn_order.size():
		var current_character = turn_order[current_turn_index]
		if is_instance_valid(current_character) and current_character.current_health > 0:
			emit_signal("turn_advanced", current_character)
			print("다음 턴: ", current_character.character_name, " (", current_turn_index + 1, "/", turn_order.size(), ")")
			return
		current_turn_index += 1

	# 모든 캐릭터가 행동 불능이면 전투 종료 (혹은 다른 처리)
	print("활동 가능한 캐릭터가 없어 라운드를 다시 시작합니다.")
	
	if check_battle_end():
		return

	# 이 경우, 모든 캐릭터가 죽었을 수 있으므로 무한 루프 방지를 위해 다시 0부터 시작
	current_turn_index = -1
	advance_turn()

func check_battle_end() -> bool:
	var players_alive = 0
	var enemies_alive = 0
	
	for char in turn_order:
		if is_instance_valid(char) and char.current_health > 0:
			if char.is_player_controlled:
				players_alive += 1
			else:
				enemies_alive += 1
	
	if players_alive == 0:
		end_battle(false)
		return true
	elif enemies_alive == 0:
		end_battle(true)
		return true
		
	return false
	
=======
	print("전투가 시작되었습니다!")

## 캐릭터들의 민첩성(AGI)을 비교하기 위한 정렬용 함수입니다.
## Array.sort_custom() 메소드에 사용됩니다.
func _compare_agility(a, b):
	return a["stats"]["AGI"] > b["stats"]["AGI"]

## 다음 턴으로 진행하는 함수입니다.
## BattleScene에서 '턴 종료' 버튼을 누르거나, AI의 턴이 끝나면 호출됩니다.
func next_turn():
	turn_count += 1
	
	# 현재 턴 페이즈에 따라 다음 페이즈로 전환합니다.
	match current_phase:
		TurnPhase.PLAYER_TURN:
			current_phase = TurnPhase.ENEMY_TURN
		TurnPhase.ENEMY_TURN:
			current_phase = TurnPhase.ENVIRONMENT_TURN
		TurnPhase.ENVIRONMENT_TURN:
			current_phase = TurnPhase.PLAYER_TURN
			# 환경 턴에서는 특별한 로직을 처리합니다.
			process_environment_turn()
	
	# "턴이 변경되었다"는 신호를 보냅니다.
	# BattleScene은 이 신호를 받아 UI(예: "적 턴" 레이블)를 업데이트합니다.
	emit_signal("turn_changed", current_phase)
	print("턴 변경: ", TurnPhase.keys()[current_phase])
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51

## 환경 턴에 수행될 로직을 처리합니다.
func process_environment_turn():
	# 예정된 외부 전황 이벤트가 현재 턴에 도달했는지 확인하고 적용합니다.
	for event in external_events:
		if event["trigger_turn"] <= round_count:
			apply_external_event(event)
			external_events.erase(event) # 처리된 이벤트는 목록에서 제거
	
	# 지형의 상태 변화를 처리합니다 (예: 불타는 땅이 일반 땅으로 변함).
	update_terrain_states()

## 외부 전황 이벤트를 실제로 적용하는 함수입니다.
func apply_external_event(event: Dictionary):
	print("외부 이벤트 발생: ", event["description"])
	# 여기에 증원군 생성, 날씨 변화 등의 실제 로직을 구현할 수 있습니다.

## 지형 상태의 자연적인 변화를 처리합니다.
func update_terrain_states():
	# 예를 들어, 'BurningGround' 지형이 몇 턴 후에 'Plain'으로 바뀌는 로직을 구현할 수 있습니다.
	pass

## 실시간으로 외부 전황을 시뮬레이션합니다.
## _process 함수에서 매 프레임 호출됩니다.
func simulate_external_events(delta: float):
	# 정보의 신선도가 계속해서 떨어집니다.
	intelligence_age += delta
	
	# 매 프레임마다 낮은 확률로 새로운 외부 이벤트를 생성합니다.
	if randf() < 0.01: # 1% 확률
		generate_random_external_event()

## 랜덤한 외부 이벤트를 생성하여 `external_events` 배열에 추가합니다.
func generate_random_external_event():
	var events = [
		{"description": "적 증원 부대 발견", "type": "enemy_reinforcement", "trigger_turn": round_count + randi_range(3, 8)},
		{"description": "아군 지원 요청 승인", "type": "ally_support", "trigger_turn": round_count + randi_range(2, 5)},
		{"description": "날씨 변화 - 안개 발생", "type": "weather_change", "trigger_turn": round_count + randi_range(1, 3)}
	]
	
	var event = events[randi() % events.size()]
	external_events.append(event)
	print("새로운 외부 이벤트 예정: ", event["description"])

## 정찰, 스파이 활동 등으로 새로운 정보를 획득했을 때 호출됩니다.
func acquire_intelligence(info_type: String, info_data: Dictionary):
	intelligence_info[info_type] = {
		"data": info_data,
		"acquired_time": battle_time
	}
	intelligence_age = 0.0 # 새로운 정보를 얻었으므로 신선도를 초기화합니다.
	print("새로운 정보 획득: ", info_type)

## 보유한 정보가 여전히 유효한지(너무 오래되지 않았는지) 확인합니다.
## @param info_type: 확인할 정보의 종류
## @param max_age: 정보의 최대 유효 시간(초)
func is_intelligence_valid(info_type: String, max_age: float = 30.0) -> bool:
	if info_type in intelligence_info:
		var info_age = battle_time - intelligence_info[info_type]["acquired_time"]
		return info_age <= max_age
	return false

<<<<<<< HEAD
# 데미지 계산 (지형, 스킬, 캐릭터 스탯 성장률 반영)
func calculate_damage(attacker, defender, skill_name: String, terrain_name: String) -> Dictionary:
=======
## 데미지를 계산하는 핵심 함수입니다.
## 공격자, 방어자, 스킬, 지형 등 다양한 요소를 복합적으로 계산합니다.
## @param attacker: 공격자 캐릭터 데이터
## @param defender: 방어자 캐릭터 데이터
## @param skill_name: 사용된 스킬 이름
## @param terrain_name: 방어자가 위치한 지형 이름
## @return: 최종 데미지 값
func calculate_damage(attacker: Dictionary, defender: Dictionary, skill_name: String, terrain_name: String) -> int:
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51
	var skill = GameData.SKILLS[skill_name]
	var terrain = GameData.TERRAINS[terrain_name]
	var result = {"damage": 0, "is_critical": false, "effects": []}
	
<<<<<<< HEAD
	# Helper to get stat
	var get_stat = func(unit, stat_name):
		if unit is Character:
			return unit.current_stats.get(stat_name, 0)
		return unit["stats"].get(stat_name, 0)
		
	# Helper to get class
	var get_class = func(unit):
		if unit is Character:
			return unit.current_class
		return unit.get("class", "Soldier")
	
	# === 1. 기본 데미지 계산 ===
	var primary_stat = 0
	var secondary_stat = 0
	var defense_stat = 0
	
	# 스킬 타입에 따른 주력/보조 스탯 결정
=======
	# 1. 기본 데미지 계산 (물리/마법)
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51
	if skill["type"] == "Physical":
		primary_stat = get_stat.call(attacker, "STR")
		secondary_stat = get_stat.call(attacker, "DEX")  # 정확도
		defense_stat = get_stat.call(defender, "DEF")
	elif skill["type"] == "Magic":
		primary_stat = get_stat.call(attacker, "INT")
		secondary_stat = get_stat.call(attacker, "RES")  # 마법 제어력
		defense_stat = get_stat.call(defender, "RES")
	
<<<<<<< HEAD
	# 기본 공식: 주력스탯*1.5 + 보조스탯*0.5 + 스킬위력 - 방어력*0.7
	var raw_damage = (primary_stat * 1.5) + (secondary_stat * 0.5) + skill["power"] - (defense_stat * 0.7)
	var damage = max(1, int(raw_damage))  # 최소 1 데미지 보장
	
	# === 2. 캐릭터 성장률 기반 스킬 숙련도 보너스 ===
	# === 2. 캐릭터 성장률 기반 스킬 숙련도 보너스 ===
	var skill_mastery_bonus = 1.0
	var growth_rates = {}
	if attacker is Character:
		growth_rates = attacker.stat_growth
	elif "growth_rates" in attacker:
		growth_rates = attacker["growth_rates"]
		
	if not growth_rates.is_empty():
		# 해당 스킬의 주력 스탯 성장률에 따른 숙련도 보너스
		var main_stat_growth = 0
		if skill["type"] == "Physical":
			main_stat_growth = growth_rates.get("STR", 0.5) * 100 # Character uses 0.0-1.0, Data uses 0-100? Check Character.gd
		elif skill["type"] == "Magic":
			main_stat_growth = growth_rates.get("INT", 0.5) * 100
		
		# 성장률이 높을수록 해당 타입 스킬에 특화됨
		# 성장률 80% = 1.15배, 60% = 1.0배, 40% = 0.9배
		skill_mastery_bonus = 0.5 + (main_stat_growth / 100.0)
		
		# 클래스 스킬 보너스 (현재 클래스의 대표 스킬이면 추가 보너스)
		var cls_name = get_class.call(attacker)
		if cls_name in GameData.CLASSES:
			var attacker_class = GameData.CLASSES[cls_name]
			if skill_name in attacker_class.get("skills", []):
				skill_mastery_bonus *= 1.1  # 10% 추가 보너스
	
	damage = int(damage * skill_mastery_bonus)
	if skill_mastery_bonus > 1.05:
		result["effects"].append("스킬 특화: x" + str("%.2f" % skill_mastery_bonus))
	
	# === 3. 크리티컬 히트 계산 ===
	var critical_chance = base_critical_chance(attacker, skill)
	if randf() < critical_chance:
		damage = int(damage * 1.8)  # 크리티컬은 1.8배
		result["is_critical"] = true
		result["effects"].append("Critical Hit!")
	
	# === 4. 지형 보정 ===
	damage = apply_terrain_bonus(damage, skill, terrain, result)
	
	# === 5. 환경 상호작용 ===
=======
	# 2. 스킬 기본 위력 추가 (최소 1의 데미지는 보장)
	var damage = max(1, base_damage + skill["power"])
	
	# 3. 지형 효과 적용 (예: 고지대에서 공격 시 보너스)
	if terrain["effect"] == "HighGroundBonus" and skill["type"] == "Physical":
		damage = int(damage * 1.2)
		print("고지대 보너스 적용!")
	
	# 4. 무기 적성 보너스 (자신의 클래스가 사용하는 스킬일 경우 보너스)
	var attacker_class = GameData.CLASSES[attacker["class"]]
	if skill_name in attacker_class["skills"]:
		damage = int(damage * 1.1)
	
	# 5. 환경 상호작용 (예: 젖은 상태의 적에게 번개 마법 사용 시 추가 데미지)
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51
	var interaction = GameData.get_terrain_skill_interaction(terrain_name, skill_name)
	if interaction["multiplier"] > 1.0:
		damage = int(damage * interaction["multiplier"])
		result["effects"].append("환경 상호작용 보너스: x" + str(interaction["multiplier"]))
		
		# 지형 변화 효과 적용
		if interaction["effect"] != null:
			apply_terrain_change_effect(interaction["effect"], terrain_name)
			result["effects"].append("지형 변화: " + interaction["effect"])
	
	# === 6. DEX 기반 명중률 체크 ===
	var hit_chance = calculate_hit_chance(attacker, defender, skill, terrain)
	if randf() > hit_chance:
		damage = 0
		result["effects"].append("Miss!")
	
	result["damage"] = damage
	return result

# 스킬별 주력 스탯 확인 (향후 다양한 스킬 타입 대응용)
func get_primary_stat_for_skill(skill: Dictionary) -> String:
	match skill["type"]:
		"Physical":
			return "STR"
		"Magic": 
			return "INT"
		"Dexterity":  # 기교 스킬 (정밀사격, 암살 등)
			return "DEX"
		"Defense":    # 방어 스킬 (가드, 도발 등)
			return "DEF"
		_:
			return "STR"  # 기본값

# 크리티컬 확률 계산
func base_critical_chance(attacker, skill: Dictionary) -> float:
	var dex = 0
	if attacker is Character:
		dex = attacker.current_stats.get("DEX", 0)
	else:
		dex = attacker["stats"]["DEX"]
		
	var base_crit = 0.05  # 기본 5%
	var dex_bonus = dex * 0.002  # DEX 1당 0.2% 증가
	var skill_crit = 0.0
	
	# 스킬별 크리티컬 보정
	match skill.get("effect", ""):
		"HighCritical":
			skill_crit = 0.15  # 15% 추가
		"Snipe":
			skill_crit = 0.25  # 25% 추가 (저격)
	
	return min(0.95, base_crit + dex_bonus + skill_crit)  # 최대 95%

# 명중률 계산 (DEX vs AGI)
func calculate_hit_chance(attacker, defender, skill: Dictionary, terrain: Dictionary) -> float:
	var att_dex = 0
	if attacker is Character:
		att_dex = attacker.current_stats.get("DEX", 0)
	else:
		att_dex = attacker["stats"]["DEX"]
		
	var def_agi = 0
	if defender is Character:
		def_agi = defender.current_stats.get("AGI", 0)
	else:
		def_agi = defender["stats"]["AGI"]

	var base_hit = 0.85  # 기본 85%
	var dex_bonus = att_dex * 0.01  # DEX 1당 1% 증가
	var agi_penalty = def_agi * 0.008  # AGI 1당 0.8% 회피
	
	# 지형에 따른 명중률 보정
	var terrain_modifier = 0.0
	match terrain.get("effect", ""):
		"Hide":  # 숲
			terrain_modifier = -0.15  # 15% 명중률 감소
		"HighGroundBonus":  # 고지대에서 공격
			terrain_modifier = 0.1   # 10% 명중률 증가
	
	# 스킬 타입에 따른 보정
	var skill_modifier = 0.0
	if skill["type"] == "Magic":
		skill_modifier = 0.05  # 마법은 회피하기 어려움
	
	return max(0.1, min(0.98, base_hit + dex_bonus - agi_penalty + terrain_modifier + skill_modifier))

# 지형 보정 적용
func apply_terrain_bonus(damage: int, skill: Dictionary, terrain: Dictionary, result: Dictionary) -> int:
	var modified_damage = damage
	
	match terrain.get("effect", ""):
		"HighGroundBonus":
			if skill["type"] == "Physical":
				modified_damage = int(damage * 1.25)
				result["effects"].append("고지대 보너스 +25%")
		"ThrowingBonus":
			if skill["range"] > 1:  # 원거리 공격
				modified_damage = int(damage * 1.15)
				result["effects"].append("투석 지형 보너스 +15%")
		"Slow":  # 늪지 등
			if skill["type"] == "Physical":
				modified_damage = int(damage * 0.9)
				result["effects"].append("늪지 이동 페널티 -10%")
	
	return modified_damage

## 환경 상호작용으로 인해 지형이 변화할 때 호출됩니다.
func apply_terrain_change_effect(effect_name: String, terrain_name: String):
	# 실제 지형을 바꾸는 로직은 BattleGrid.gd에 있으므로, 여기서는 시각적인 메시지만 출력합니다.
	# BattleGrid의 함수를 호출하여 실제 지형을 변경하도록 확장할 수 있습니다.
	match effect_name:
		"CreateBurningGround":
			print("🔥 ", terrain_name, "이(가) 불타는 땅으로 변화했습니다!")
		"Electrify":
			print("⚡ 전기가 흘러 주변 유닛들이 감전되었습니다!")
		"ForestFire":
			print("🔥 숲이 대화재로 번지고 있습니다!")

## 전투를 종료하는 함수입니다.
## @param victory: 승리 여부 (true: 승리, false: 패배)
func end_battle(victory: bool):
	current_state = GameState.BATTLE_END
	emit_signal("battle_ended")
	
	if victory:
		print("승리! 전투 시간: ", battle_time, "초")
		# 빠른 시간 내에 승리하면 정보가 보존되는 보너스.
		if battle_time < 60.0:
			print("신속한 승리로 정보가 유지됩니다!")
	else:
		print("패배...")
