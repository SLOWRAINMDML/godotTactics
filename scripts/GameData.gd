# -----------------------------------------------------------------------------
# [후임자를 위한 안내]
#
# GameData.gd (게임 데이터)
#
# [역할]
# 이 스크립트는 GameManager와 마찬가지로 '싱글톤(Singleton)'으로 등록되어 있습니다.
# 프로젝트의 모든 '정적 데이터(Static Data)'를 중앙에서 관리하는 데이터 저장소 역할을 합니다.
# '정적 데이터'란, 게임 플레이 중에 거의 변하지 않는 고정된 값들을 의미합니다.
# (예: 클래스의 성장률, 스킬의 위력, 지형의 이동 비용 등)
#
# [데이터 기반 설계(Data-Driven Design)의 중요성]
# - 이 파일만 수정하면 게임의 밸런스를 쉽게 조절할 수 있습니다.
#   예를 들어, 'Knight' 클래스가 너무 강하다면, 코드 로직을 건드리지 않고
#   `CLASSES["Knight"]["stat_growth"]` 의 값만 낮추면 됩니다.
# - 새로운 클래스, 스킬, 지형을 추가할 때, 복잡한 코드를 수정할 필요 없이
#   이곳에 새로운 데이터 항목만 추가하면 시스템에 바로 적용됩니다.
# - 게임의 핵심 로직과 데이터를 분리하여 유지보수성을 크게 향상시킵니다.
#
# [Godot 학습 팁: Dictionary]
# - GDScript의 Dictionary는 Python의 Dictionary와 매우 유사하며, '키(Key)'와 '값(Value)'의 쌍으로
#   데이터를 저장하는 강력한 자료구조입니다.
# - 우리 프로젝트에서는 복잡한 게임 데이터를 구조적으로 표현하기 위해 Dictionary를 적극적으로 사용합니다.
#   `데이터["키"]` 형태로 값에 접근할 수 있습니다.
# -----------------------------------------------------------------------------
extends Node

# [클래스 데이터]
# 게임에 등장하는 모든 직업(클래스)의 정보를 정의합니다.
var CLASSES = {
	"Soldier": {
<<<<<<< HEAD
		"parent": null,
		"weapons": ["Sword"],
		"skills": ["Slash", "Guard"],
		"stat_growth": {"STR": 0.7, "DEF": 0.6, "DEX": 0.4, "AGI": 0.4, "INT": 0.3, "RES": 0.4}
=======
		"parent": null, # 상위 클래스가 없는 기본 직업
		"weapons": ["Sword"], # 사용 가능 무기
		"skills": ["Slash", "Guard"], # 기본 보유 스킬
		"aptitude": {}, # 전직에 필요한 특정 스탯 적성 (없음)
		"stat_growth": {"STR": 0.7, "DEF": 0.6, "DEX": 0.4, "AGI": 0.4, "INT": 0.3, "RES": 0.4} # 레벨업 시 스탯 성장률
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51
	},
	"Knight": {
		"parent": "Soldier", # 'Soldier' 클래스에서 전직 가능
		"weapons": ["Sword", "Lance"],
		"skills": ["Slash", "Guard", "Charge", "Parry"],
<<<<<<< HEAD
=======
		"aptitude": {"STR": "S"}, # 전직 조건: 힘(STR) 적성이 S등급 이상이어야 함
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51
		"stat_growth": {"STR": 0.8, "DEF": 0.8, "DEX": 0.3, "AGI": 0.3, "INT": 0.2, "RES": 0.5}
	},
	"Archer": {
		"parent": null,
		"weapons": ["Bow"],
		"skills": ["ArrowShot", "DoubleShot"],
		"stat_growth": {"STR": 0.4, "DEF": 0.4, "DEX": 0.8, "AGI": 0.7, "INT": 0.4, "RES": 0.3}
	},
	"Sniper": {
		"parent": "Archer",
		"weapons": ["Bow", "Crossbow"],
		"skills": ["Snipe", "EagleEye"],
		"stat_growth": {"STR": 0.5, "DEF": 0.4, "DEX": 0.9, "AGI": 0.8, "INT": 0.5, "RES": 0.4}
	},
	"Mage": {
		"parent": null,
		"weapons": ["Staff"],
		"skills": ["Fireball", "MagicShield"],
		"stat_growth": {"STR": 0.2, "DEF": 0.3, "DEX": 0.4, "AGI": 0.5, "INT": 0.9, "RES": 0.7}
	},
	"ArchMage": {
		"parent": "Mage",
		"weapons": ["Staff"],
		"skills": ["Meteor", "ChainLightning"],
		"stat_growth": {"STR": 0.1, "DEF": 0.3, "DEX": 0.4, "AGI": 0.6, "INT": 1.0, "RES": 0.8}
	}
}

# [스킬 데이터]
# 게임의 모든 스킬 정보를 정의합니다.
var SKILLS = {
<<<<<<< HEAD
	"Slash": {"type": "Physical", "element": null, "power": 18, "range": 1, "effect": null, "mp_cost": 0, "accuracy": 0.95},
	"Guard": {"type": "Physical", "element": null, "power": 0, "range": 0, "effect": "DefenseUp", "mp_cost": 2, "accuracy": 1.0},
	"Charge": {"type": "Physical", "element": null, "power": 25, "range": 1, "effect": "KnockBack", "mp_cost": 4, "accuracy": 0.85},
	"ArrowShot": {"type": "Physical", "element": null, "power": 16, "range": 3, "effect": null, "mp_cost": 0, "accuracy": 0.90},
	"DoubleShot": {"type": "Physical", "element": null, "power": 10, "range": 2, "effect": "AttackTwice", "mp_cost": 3, "accuracy": 0.85},
	"Snipe": {"type": "Physical", "element": null, "power": 28, "range": 5, "effect": "HighCritical", "mp_cost": 6, "accuracy": 0.75},
	"Fireball": {"type": "Magic", "element": "Fire", "power": 22, "range": 3, "effect": "CreateBurningGround", "mp_cost": 8, "accuracy": 0.88},
	"MagicShield": {"type": "Magic", "element": null, "power": 0, "range": 0, "effect": "MagicDefenseUp", "mp_cost": 5, "accuracy": 1.0},
	"Meteor": {"type": "Magic", "element": "Fire", "power": 35, "range": 4, "effect": "AreaFireDamage", "mp_cost": 15, "accuracy": 0.80},
	"ChainLightning": {"type": "Magic", "element": "Lightning", "power": 30, "range": 3, "effect": "ChainElectric", "mp_cost": 12, "accuracy": 0.85},
	
	# 적 전용 스킬들
	"Stealth": {"type": "Physical", "element": null, "power": 0, "range": 0, "effect": "Invisible", "mp_cost": 3, "accuracy": 1.0},
	"Intimidate": {"type": "Physical", "element": null, "power": 0, "range": 2, "effect": "Fear", "mp_cost": 2, "accuracy": 0.80},
	"Dark_Bolt": {"type": "Magic", "element": "Dark", "power": 20, "range": 4, "effect": "Curse", "mp_cost": 6, "accuracy": 0.90},
	"Curse": {"type": "Magic", "element": "Dark", "power": 0, "range": 3, "effect": "Debuff_All", "mp_cost": 8, "accuracy": 0.85},
	"Life_Drain": {"type": "Magic", "element": "Dark", "power": 15, "range": 2, "effect": "Heal_Self", "mp_cost": 5, "accuracy": 0.90},
	"Holy_Strike": {"type": "Physical", "element": "Holy", "power": 26, "range": 1, "effect": "Purify", "mp_cost": 6, "accuracy": 0.92},
	"Shield_Bash": {"type": "Physical", "element": null, "power": 12, "range": 1, "effect": "Stun", "mp_cost": 3, "accuracy": 0.88},
	"Divine_Protection": {"type": "Magic", "element": "Holy", "power": 0, "range": 0, "effect": "All_Resist_Up", "mp_cost": 10, "accuracy": 1.0},
	"Fire_Breath": {"type": "Magic", "element": "Fire", "power": 30, "range": 3, "effect": "Area_Fire", "mp_cost": 12, "accuracy": 0.85},
	"Wing_Gust": {"type": "Physical", "element": "Wind", "power": 18, "range": 2, "effect": "Push_Back", "mp_cost": 4, "accuracy": 0.90},
	"Tail_Sweep": {"type": "Physical", "element": null, "power": 22, "range": 1, "effect": "Area_Attack", "mp_cost": 6, "accuracy": 0.80}
=======
	"Slash": {"type": "Physical", "element": null, "power": 18, "range": 1, "effect": null},
	"Guard": {"type": "Physical", "element": null, "power": 0, "range": 0, "effect": "DefenseUp"}, # power 0: 공격 스킬 아님
	"Charge": {"type": "Physical", "element": null, "power": 25, "range": 1, "effect": "KnockBack"},
	"ArrowShot": {"type": "Physical", "element": null, "power": 16, "range": 3, "effect": null}, # range 3: 3칸 떨어진 적 공격 가능
	"DoubleShot": {"type": "Physical", "element": null, "power": 10, "range": 2, "effect": "AttackTwice"},
	"Snipe": {"type": "Physical", "element": null, "power": 28, "range": 5, "effect": "IgnoreDefense"},
	"Fireball": {"type": "Magic", "element": "Fire", "power": 22, "range": 3, "effect": "CreateBurningGround"}, # type: 마법, element: 불 속성
	"MagicShield": {"type": "Magic", "element": null, "power": 0, "range": 0, "effect": "MagicDefenseUp"},
	"Meteor": {"type": "Magic", "element": "Fire", "power": 35, "range": 4, "effect": "AreaFireDamage"},
	"ChainLightning": {"type": "Magic", "element": "Lightning", "power": 30, "range": 3, "effect": "ChainElectric"} # element: 번개 속성
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51
}

# [지형 데이터]
# 맵을 구성하는 모든 지형의 특성을 정의합니다.
var TERRAINS = {
	"Plain": {"height": 0, "move_cost": 1, "effect": null, "state": "Normal"}, # height: 지형 높이, move_cost: 이동 시 소모되는 이동력
	"Mountain": {"height": 2, "move_cost": 3, "effect": "HighGroundBonus", "state": "Normal"}, # effect: 고지대 보너스
	"Forest": {"height": 0, "move_cost": 2, "effect": "Hide", "state": "Normal"}, # effect: 은신 가능
	"Swamp": {"height": -1, "move_cost": 4, "effect": "Slow", "state": "Wet"}, # state: 젖은 상태 (환경 상호작용에 사용)
	"Desert": {"height": 0, "move_cost": 3, "effect": "Thirst", "state": "Dry"}, # state: 건조 상태
	"RockyTerrain": {"height": 1, "move_cost": 2, "effect": "ThrowingBonus", "state": "Normal"},
	"BurningGround": {"height": 0, "move_cost": 2, "effect": "FireDamage", "state": "Burning"}, # state: 불타는 상태
	"FrozenGround": {"height": 0, "move_cost": 2, "effect": "SlipChance", "state": "Frozen"} # state: 얼어붙은 상태
}

# [환경 상호작용 룰]
# 특정 속성의 스킬이 특정 상태의 지형과 만났을 때 발생하는 추가 효과를 정의합니다.
# 예: '불(Fire)' 속성 스킬을 '건조한(Dry)' 상태의 지형에 사용하면 데미지가 1.5배가 되고, 지형이 '불타는 땅'으로 변합니다.
var ENVIRONMENT_INTERACTIONS = {
	"Fire_Dry": {"multiplier": 1.5, "effect": "CreateBurningGround"}, # 데미지 배율 1.5배, '불타는 땅 생성' 효과
	"Lightning_Wet": {"multiplier": 1.3, "effect": "Electrify"}, # '젖은' 상태에 '번개' 스킬 -> 1.3배 데미지, '감전' 효과
	"Ice_Wet": {"multiplier": 1.2, "effect": "Freeze"},
	"Fire_Forest": {"multiplier": 1.4, "effect": "ForestFire"} # '숲' 지형에 '불' 스킬 -> 1.4배 데미지, '산불' 효과
}

<<<<<<< HEAD
# 캐릭터별 성장률 기반 특화 보너스 계산 (무기 적성 시스템 대체)
# 성장률이 높을수록 해당 스탯 관련 스킬에 특화됨
func get_stat_specialization_bonus(growth_rate: int) -> float:
	# 성장률 90% = 1.2배, 80% = 1.15배, 70% = 1.1배, 60% = 1.0배, 50% = 0.95배
	return 0.5 + (growth_rate / 100.0)

# 적 캐릭터 타입 정의
var ENEMY_TYPES = {
	"Goblin_Scout": {
		"base_stats": {"STR": 8, "DEF": 6, "DEX": 12, "AGI": 14, "INT": 5, "RES": 4},
		"growth_rates": {"STR": 45, "DEF": 40, "DEX": 80, "AGI": 85, "INT": 30, "RES": 35},
		"class": "Scout",
		"skills": ["ArrowShot", "Stealth"],
		"ai_pattern": "hit_and_run",
		"threat_level": 1,
		"equipment": {"weapon": "Short_Bow", "armor": "Leather"},
		"special_traits": ["Fast_Movement", "Coward"]
	},
	"Orc_Warrior": {
		"base_stats": {"STR": 16, "DEF": 12, "DEX": 8, "AGI": 6, "INT": 4, "RES": 6},
		"growth_rates": {"STR": 90, "DEF": 75, "DEX": 45, "AGI": 40, "INT": 25, "RES": 50},
		"class": "Warrior",
		"skills": ["Slash", "Charge", "Intimidate"],
		"ai_pattern": "aggressive_melee",
		"threat_level": 2,
		"equipment": {"weapon": "War_Axe", "armor": "Chain_Mail"},
		"special_traits": ["High_HP", "Berserker"]
	},
	"Dark_Mage": {
		"base_stats": {"STR": 6, "DEF": 8, "DEX": 10, "AGI": 9, "INT": 18, "RES": 15},
		"growth_rates": {"STR": 20, "DEF": 35, "DEX": 50, "AGI": 60, "INT": 95, "RES": 85},
		"class": "Dark_Mage",
		"skills": ["Dark_Bolt", "Curse", "Life_Drain"],
		"ai_pattern": "support_caster",
		"threat_level": 3,
		"equipment": {"weapon": "Cursed_Staff", "armor": "Dark_Robe"},
		"special_traits": ["Magic_Immunity", "Life_Steal"]
	},
	"Elite_Knight": {
		"base_stats": {"STR": 20, "DEF": 18, "DEX": 12, "AGI": 10, "INT": 8, "RES": 12},
		"growth_rates": {"STR": 85, "DEF": 90, "DEX": 60, "AGI": 55, "INT": 50, "RES": 70},
		"class": "Paladin",
		"skills": ["Holy_Strike", "Shield_Bash", "Divine_Protection"],
		"ai_pattern": "defensive_tank",
		"threat_level": 4,
		"equipment": {"weapon": "Holy_Sword", "armor": "Plate_Mail", "shield": "Tower_Shield"},
		"special_traits": ["Magic_Resistance", "Leadership"]
	},
	"Dragon_Whelp": {
		"base_stats": {"STR": 22, "DEF": 16, "DEX": 14, "AGI": 16, "INT": 12, "RES": 14},
		"growth_rates": {"STR": 95, "DEF": 80, "DEX": 70, "AGI": 75, "INT": 85, "RES": 80},
		"class": "Dragon",
		"skills": ["Fire_Breath", "Wing_Gust", "Tail_Sweep"],
		"ai_pattern": "area_dominance",
		"threat_level": 5,
		"equipment": {},  # 드래곤은 장비 없음
		"special_traits": ["Flying", "Fire_Immunity", "Area_Attack", "Boss"]
	}
}

# AI 패턴 정의
var AI_PATTERNS = {
	"hit_and_run": {
		"priority": ["attack_weakest", "maintain_distance", "use_terrain"],
		"aggression": 0.3,
		"retreat_threshold": 0.4,  # HP 40% 이하면 후퇴
		"preferred_range": 3
	},
	"aggressive_melee": {
		"priority": ["charge_strongest", "close_distance", "ignore_damage"],
		"aggression": 0.9,
		"retreat_threshold": 0.1,  # HP 10% 이하에서만 후퇴
		"preferred_range": 1
	},
	"support_caster": {
		"priority": ["buff_allies", "debuff_enemies", "stay_back"],
		"aggression": 0.2,
		"retreat_threshold": 0.6,  # HP 60% 이하면 후퇴
		"preferred_range": 4
	},
	"defensive_tank": {
		"priority": ["protect_allies", "draw_attention", "hold_position"],
		"aggression": 0.5,
		"retreat_threshold": 0.2,  # HP 20% 이하에서만 후퇴
		"preferred_range": 1
	},
	"area_dominance": {
		"priority": ["area_attack", "control_center", "intimidate"],
		"aggression": 0.7,
		"retreat_threshold": 0.0,  # 절대 후퇴하지 않음
		"preferred_range": 2
	}
}

# 전투 난이도별 적 구성
var ENCOUNTER_TEMPLATES = {
	"tutorial": {
		"enemies": [
			{"type": "Goblin_Scout", "count": 2, "level_range": [1, 2]},
		],
		"total_threat": 2,
		"special_conditions": ["player_advantage", "tutorial_hints"]
	},
	"easy": {
		"enemies": [
			{"type": "Goblin_Scout", "count": 3, "level_range": [2, 4]},
			{"type": "Orc_Warrior", "count": 1, "level_range": [3, 5]}
		],
		"total_threat": 5,
		"special_conditions": []
	},
	"normal": {
		"enemies": [
			{"type": "Goblin_Scout", "count": 2, "level_range": [4, 6]},
			{"type": "Orc_Warrior", "count": 2, "level_range": [5, 7]},
			{"type": "Dark_Mage", "count": 1, "level_range": [5, 6]}
		],
		"total_threat": 9,
		"special_conditions": ["coordinated_ai"]
	},
	"hard": {
		"enemies": [
			{"type": "Orc_Warrior", "count": 3, "level_range": [7, 9]},
			{"type": "Dark_Mage", "count": 2, "level_range": [7, 8]},
			{"type": "Elite_Knight", "count": 1, "level_range": [8, 10]}
		],
		"total_threat": 16,
		"special_conditions": ["smart_positioning", "combo_attacks"]
	},
	"boss": {
		"enemies": [
			{"type": "Dragon_Whelp", "count": 1, "level_range": [12, 15]},
			{"type": "Elite_Knight", "count": 2, "level_range": [10, 12]},
			{"type": "Dark_Mage", "count": 1, "level_range": [9, 11]}
		],
		"total_threat": 25,
		"special_conditions": ["boss_mechanics", "phase_transitions", "environmental_hazards"]
	}
=======
# [적성 등급별 보너스]
# 무기나 스탯의 적성 등급(S, A, B, C, D)에 따른 성능 보너스를 정의합니다.
var APTITUDE_BONUS = {
	"S": 1.5, # S등급은 150%의 효율
	"A": 1.3,
	"B": 1.1,
	"C": 1.0, # C등급은 100% (기준)
	"D": 0.8  # D등급은 80% (패널티)
>>>>>>> 99ae945aad768494fb8ff1bbfe17c79503c3ea51
}

# Godot 엔진이 이 노드를 씬 트리에 추가할 때 자동으로 호출하는 내장 함수입니다.
func _ready():
	print("GameData 싱글톤이 초기화되었습니다.")

## 캐릭터가 특정 클래스로 전직할 수 있는지 여부를 확인하는 함수입니다.
## @param character_data: 확인할 캐릭터의 현재 데이터 (클래스, 적성 등)
## @param target_class: 전직하려는 목표 클래스 이름
## @return: 전직 가능하면 true, 불가능하면 false
func can_class_change(character_data: Dictionary, target_class: String) -> bool:
	var class_info = CLASSES[target_class]

	# 목표 클래스가 기본 직업군이면 누구나 전직 가능.
	if class_info["parent"] == null:
		return true
		
	# 1. 상위 클래스 조건 확인: 현재 클래스가 목표 클래스의 'parent'와 일치해야 함.
	var current_class = character_data["class"]
	if current_class == class_info["parent"]:
		# 2. 필요 적성 조건 확인
		for stat in class_info["aptitude"]:
			var required_grade = class_info["aptitude"][stat] # 전직에 필요한 등급
			var character_aptitude = character_data.get("aptitude", {}).get(stat, "D") # 캐릭터가 가진 등급

			# 캐릭터의 적성 등급이 필요 등급보다 낮으면 전직 불가.
			if not is_aptitude_sufficient(character_aptitude, required_grade):
				return false

		# 모든 조건을 만족하면 전직 가능.
		return true

	return false

## 두 적성 등급을 비교하여 현재 등급이 요구 등급 이상인지 확인합니다.
## @param current: 현재 등급 (예: "A")
## @param required: 요구 등급 (예: "B")
## @return: 현재 등급이 요구 등급 이상이면 true
func is_aptitude_sufficient(current: String, required: String) -> bool:
	var grades = ["D", "C", "B", "A", "S"] # 등급 서열
	# 배열에서 등급의 인덱스를 찾아 비교. 인덱스가 크거나 같으면 더 높은 등급.
	return grades.find(current) >= grades.find(required)

## 지형과 스킬 간의 상호작용 효과를 반환하는 함수입니다.
## @param terrain_name: 대상 지형의 이름
## @param skill_name: 사용된 스킬의 이름
## @return: 상호작용 효과 (데미지 배율, 추가 효과 등)를 담은 Dictionary
func get_terrain_skill_interaction(terrain_name: String, skill_name: String) -> Dictionary:
	var terrain = TERRAINS[terrain_name]
	var skill = SKILLS[skill_name]
	var result = {"multiplier": 1.0, "effect": null} # 기본값: 아무 효과 없음
	
	# 스킬에 속성('element')이 있을 경우에만 환경 상호작용을 확인합니다.
	if skill["element"] != null:
		# "스킬속성_지형상태" 형태의 키를 만듭니다 (예: "Fire_Dry")
		var interaction_key = skill["element"] + "_" + terrain["state"]

		# 이 키가 `ENVIRONMENT_INTERACTIONS`에 정의되어 있는지 확인합니다.
		if interaction_key in ENVIRONMENT_INTERACTIONS:
			# 정의된 효과를 복사하여 반환합니다. (.duplicate()를 사용하여 원본 데이터 보호)
			result = ENVIRONMENT_INTERACTIONS[interaction_key].duplicate()
	
	return result 

# 적 캐릭터 생성 함수
func create_enemy_character(enemy_type: String, level: int, position: Vector2i) -> Dictionary:
	var enemy_template = ENEMY_TYPES[enemy_type]
	var character_data = {}
	
	# 기본 정보 설정
	character_data["name"] = enemy_type.replace("_", " ")
	character_data["id"] = enemy_type + "_" + str(randi())
	character_data["class"] = enemy_template["class"]
	character_data["level"] = level
	character_data["position"] = position
	character_data["is_player_controlled"] = false
	
	# 레벨에 따른 스탯 조정
	character_data["stats"] = {}
	for stat in enemy_template["base_stats"]:
		var base_value = enemy_template["base_stats"][stat]
		var level_bonus = (level - 1) * 2  # 레벨당 2씩 증가
		character_data["stats"][stat] = base_value + level_bonus
	
	# 적성 및 스킬 복사
	character_data["aptitude"] = enemy_template["aptitude"].duplicate()
	character_data["skills"] = enemy_template["skills"].duplicate()
	
	# AI 정보 추가
	character_data["ai_pattern"] = enemy_template["ai_pattern"]
	character_data["threat_level"] = enemy_template["threat_level"]
	character_data["special_traits"] = enemy_template["special_traits"].duplicate()
	
	return character_data

# 난이도에 따른 적 그룹 생성
func generate_enemy_encounter(difficulty: String, player_level: int) -> Array:
	var template = ENCOUNTER_TEMPLATES[difficulty]
	var enemies = []
	
	for enemy_group in template["enemies"]:
		for i in range(enemy_group["count"]):
			var enemy_level = randi_range(enemy_group["level_range"][0], enemy_group["level_range"][1])
			# 플레이어 레벨에 따른 조정
			enemy_level = max(1, enemy_level + (player_level - 5))
			
			var position = Vector2i(randi_range(5, 15), randi_range(5, 15))  # 임시 위치
			var enemy = create_enemy_character(enemy_group["type"], enemy_level, position)
			enemies.append(enemy)
	
	return enemies 