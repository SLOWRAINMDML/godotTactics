extends Node

# 클래스 데이터
var CLASSES = {
	"Soldier": {
		"parent": null,
		"weapons": ["Sword"],
		"skills": ["Slash", "Guard"],
		"stat_growth": {"STR": 0.7, "DEF": 0.6, "DEX": 0.4, "AGI": 0.4, "INT": 0.3, "RES": 0.4}
	},
	"Knight": {
		"parent": "Soldier", 
		"weapons": ["Sword", "Lance"],
		"skills": ["Slash", "Guard", "Charge", "Parry"],
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

# 스킬 데이터
var SKILLS = {
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
}

# 지형 데이터
var TERRAINS = {
	"Plain": {"height": 0, "move_cost": 1, "effect": null, "state": "Normal"},
	"Mountain": {"height": 2, "move_cost": 3, "effect": "HighGroundBonus", "state": "Normal"},
	"Forest": {"height": 0, "move_cost": 2, "effect": "Hide", "state": "Normal"},
	"Swamp": {"height": -1, "move_cost": 4, "effect": "Slow", "state": "Wet"},
	"Desert": {"height": 0, "move_cost": 3, "effect": "Thirst", "state": "Dry"},
	"RockyTerrain": {"height": 1, "move_cost": 2, "effect": "ThrowingBonus", "state": "Normal"},
	"BurningGround": {"height": 0, "move_cost": 2, "effect": "FireDamage", "state": "Burning"},
	"FrozenGround": {"height": 0, "move_cost": 2, "effect": "SlipChance", "state": "Frozen"}
}

# 환경 상호작용 룰
var ENVIRONMENT_INTERACTIONS = {
	"Fire_Dry": {"multiplier": 1.5, "effect": "CreateBurningGround"},
	"Lightning_Wet": {"multiplier": 1.3, "effect": "Electrify"},
	"Ice_Wet": {"multiplier": 1.2, "effect": "Freeze"},
	"Fire_Forest": {"multiplier": 1.4, "effect": "ForestFire"}
}

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
}

func _ready():
	print("GameData 싱글톤이 초기화되었습니다.")

# 캐릭터가 특정 클래스로 전직 가능한지 확인
func can_class_change(character_data: Dictionary, target_class: String) -> bool:
	var class_info = CLASSES[target_class]
	if class_info["parent"] == null:
		return true
		
	# 상위 클래스 조건 확인
	var current_class = character_data["class"]
	if current_class == class_info["parent"]:
		# 적성 조건 확인
		for stat in class_info["aptitude"]:
			var required_grade = class_info["aptitude"][stat]
			var character_aptitude = character_data.get("aptitude", {}).get(stat, "D")
			if not is_aptitude_sufficient(character_aptitude, required_grade):
				return false
		return true
	return false

func is_aptitude_sufficient(current: String, required: String) -> bool:
	var grades = ["D", "C", "B", "A", "S"]
	return grades.find(current) >= grades.find(required)

# 지형과 스킬 상호작용 확인
func get_terrain_skill_interaction(terrain_name: String, skill_name: String) -> Dictionary:
	var terrain = TERRAINS[terrain_name]
	var skill = SKILLS[skill_name]
	var result = {"multiplier": 1.0, "effect": null}
	
	# 환경 상호작용 확인
	if skill["element"] != null:
		var interaction_key = skill["element"] + "_" + terrain["state"]
		if interaction_key in ENVIRONMENT_INTERACTIONS:
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