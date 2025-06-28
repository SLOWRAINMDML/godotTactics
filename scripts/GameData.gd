extends Node

# 클래스 데이터
var CLASSES = {
	"Soldier": {
		"parent": null,
		"weapons": ["Sword"],
		"skills": ["Slash", "Guard"],
		"aptitude": {},
		"stat_growth": {"STR": 0.7, "DEF": 0.6, "DEX": 0.4, "AGI": 0.4, "INT": 0.3, "RES": 0.4}
	},
	"Knight": {
		"parent": "Soldier", 
		"weapons": ["Sword", "Lance"],
		"skills": ["Slash", "Guard", "Charge", "Parry"],
		"aptitude": {"STR": "S"},
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

# 스킬 데이터
var SKILLS = {
	"Slash": {"type": "Physical", "element": null, "power": 18, "range": 1, "effect": null},
	"Guard": {"type": "Physical", "element": null, "power": 0, "range": 0, "effect": "DefenseUp"},
	"Charge": {"type": "Physical", "element": null, "power": 25, "range": 1, "effect": "KnockBack"},
	"ArrowShot": {"type": "Physical", "element": null, "power": 16, "range": 3, "effect": null},
	"DoubleShot": {"type": "Physical", "element": null, "power": 10, "range": 2, "effect": "AttackTwice"},
	"Snipe": {"type": "Physical", "element": null, "power": 28, "range": 5, "effect": "IgnoreDefense"},
	"Fireball": {"type": "Magic", "element": "Fire", "power": 22, "range": 3, "effect": "CreateBurningGround"},
	"MagicShield": {"type": "Magic", "element": null, "power": 0, "range": 0, "effect": "MagicDefenseUp"},
	"Meteor": {"type": "Magic", "element": "Fire", "power": 35, "range": 4, "effect": "AreaFireDamage"},
	"ChainLightning": {"type": "Magic", "element": "Lightning", "power": 30, "range": 3, "effect": "ChainElectric"}
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

# 적성 등급별 보너스
var APTITUDE_BONUS = {
	"S": 1.5,
	"A": 1.3,
	"B": 1.1,
	"C": 1.0,
	"D": 0.8
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