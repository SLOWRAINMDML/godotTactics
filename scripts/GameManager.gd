extends Node

signal turn_order_updated(turn_order)
signal turn_advanced(current_character)
signal battle_started
signal battle_ended

enum GameState {
	MENU,
	BATTLE_PREPARATION,
	BATTLE,
	BATTLE_END,
	CHARACTER_MENU
}

var current_state: GameState = GameState.MENU
var round_count: int = 0
var battle_time: float = 0.0

# 모든 캐릭터의 행동 순서
var turn_order: Array = []
var current_turn_index: int = -1

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

func start_battle(all_characters: Array):
	turn_order = all_characters.filter(func(c): return is_instance_valid(c))
	current_state = GameState.BATTLE
	round_count = 1
	battle_time = 0.0
	current_turn_index = -1
	
	# DEX 스탯 기준으로 행동 순서 정렬
	turn_order.sort_custom(_compare_dex)
	
	emit_signal("battle_started")
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
	

func process_environment_turn():
	# 외부 전황 변화 적용
	for event in external_events:
		if event["trigger_turn"] <= round_count:
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
		{"description": "적 증원 부대 발견", "type": "enemy_reinforcement", "trigger_turn": round_count + randi_range(3, 8)},
		{"description": "아군 지원 요청 승인", "type": "ally_support", "trigger_turn": round_count + randi_range(2, 5)},
		{"description": "날씨 변화 - 안개 발생", "type": "weather_change", "trigger_turn": round_count + randi_range(1, 3)}
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

# 데미지 계산 (지형, 스킬, 캐릭터 스탯 성장률 반영)
func calculate_damage(attacker, defender, skill_name: String, terrain_name: String) -> Dictionary:
	var skill = GameData.SKILLS[skill_name]
	var terrain = GameData.TERRAINS[terrain_name]
	var result = {"damage": 0, "is_critical": false, "effects": []}
	
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
	if skill["type"] == "Physical":
		primary_stat = get_stat.call(attacker, "STR")
		secondary_stat = get_stat.call(attacker, "DEX")  # 정확도
		defense_stat = get_stat.call(defender, "DEF")
	elif skill["type"] == "Magic":
		primary_stat = get_stat.call(attacker, "INT")
		secondary_stat = get_stat.call(attacker, "RES")  # 마법 제어력
		defense_stat = get_stat.call(defender, "RES")
	
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
	var interaction = GameData.get_terrain_skill_interaction(terrain_name, skill_name)
	if interaction["multiplier"] > 1.0:
		damage = int(damage * interaction["multiplier"])
		result["effects"].append("환경 상호작용 보너스: x" + str(interaction["multiplier"]))
		
		# 지형 변화 효과
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
