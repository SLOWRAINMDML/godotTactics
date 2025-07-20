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
		"parent": null, # 상위 클래스가 없는 기본 직업
		"weapons": ["Sword"], # 사용 가능 무기
		"skills": ["Slash", "Guard"], # 기본 보유 스킬
		"aptitude": {}, # 전직에 필요한 특정 스탯 적성 (없음)
		"stat_growth": {"STR": 0.7, "DEF": 0.6, "DEX": 0.4, "AGI": 0.4, "INT": 0.3, "RES": 0.4} # 레벨업 시 스탯 성장률
	},
	"Knight": {
		"parent": "Soldier", # 'Soldier' 클래스에서 전직 가능
		"weapons": ["Sword", "Lance"],
		"skills": ["Slash", "Guard", "Charge", "Parry"],
		"aptitude": {"STR": "S"}, # 전직 조건: 힘(STR) 적성이 S등급 이상이어야 함
		"stat_growth": {"STR": 0.8, "DEF": 0.8, "DEX": 0.3, "AGI": 0.3, "INT": 0.2, "RES": 0.5}
	},
	"Archer": {
		"parent": null,
		"weapons": ["Bow"],
		"skills": ["ArrowShot", "DoubleShot"],
		"aptitude": {"DEX": "B"},
		"stat_growth": {"STR": 0.4, "DEF": 0.4, "DEX": 0.8, "AGI": 0.7, "INT": 0.4, "RES": 0.3}
	},
	"Sniper": {
		"parent": "Archer",
		"weapons": ["Bow", "Crossbow"],
		"skills": ["Snipe", "EagleEye"],
		"aptitude": {"DEX": "S"},
		"stat_growth": {"STR": 0.5, "DEF": 0.4, "DEX": 0.9, "AGI": 0.8, "INT": 0.5, "RES": 0.4}
	},
	"Mage": {
		"parent": null,
		"weapons": ["Staff"],
		"skills": ["Fireball", "MagicShield"],
		"aptitude": {"INT": "B"},
		"stat_growth": {"STR": 0.2, "DEF": 0.3, "DEX": 0.4, "AGI": 0.5, "INT": 0.9, "RES": 0.7}
	},
	"ArchMage": {
		"parent": "Mage",
		"weapons": ["Staff"],
		"skills": ["Meteor", "ChainLightning"],
		"aptitude": {"INT": "S"},
		"stat_growth": {"STR": 0.1, "DEF": 0.3, "DEX": 0.4, "AGI": 0.6, "INT": 1.0, "RES": 0.8}
	}
}

# [스킬 데이터]
# 게임의 모든 스킬 정보를 정의합니다.
var SKILLS = {
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

# [적성 등급별 보너스]
# 무기나 스탯의 적성 등급(S, A, B, C, D)에 따른 성능 보너스를 정의합니다.
var APTITUDE_BONUS = {
	"S": 1.5, # S등급은 150%의 효율
	"A": 1.3,
	"B": 1.1,
	"C": 1.0, # C등급은 100% (기준)
	"D": 0.8  # D등급은 80% (패널티)
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