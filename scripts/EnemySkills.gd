class_name EnemySkills
extends Resource

# 스킬 타입 열거형
enum SkillType {
	PASSIVE,     # 지속 효과
	ACTIVE,      # 능동 사용
	TRIGGERED,   # 특정 조건에서 발동
	TERRAIN,     # 지형 상호작용
	AURA         # 주변 영향
}

# 스킬 대상 타입
enum TargetType {
	SELF,        # 자신
	SINGLE,      # 단일 대상
	AOE,         # 광역
	LINE,        # 직선
	CROSS,       # 십자
	ALLIES,      # 아군
	ENEMIES      # 적군
}

# 개별 스킬 데이터
class Skill:
	var id: String
	var name: String
	var description: String
	var skill_type: SkillType
	var target_type: TargetType
	var range: int
	var area_size: int
	var mp_cost: int
	var cooldown: int
	var element: EnemyData.ElementType
	var effects: Array = []
	
	func _init(skill_id: String):
		id = skill_id

# 스킬 데이터베이스
static var skills: Dictionary = {}

# 스킬 데이터베이스 초기화
static func initialize_skills():
	_create_nature_skills()
	_create_animal_skills()
	_create_object_skills()
	_create_undead_skills()
	_create_demon_skills()
	_create_elemental_skills()

# 자연계 스킬들
static func _create_nature_skills():
	# 나무 융합
	var tree_fusion = Skill.new("나무_융합")
	tree_fusion.name = "나무 융합"
	tree_fusion.description = "숲 지형에서 나무와 융합하여 은신하고 체력을 회복한다."
	tree_fusion.skill_type = SkillType.ACTIVE
	tree_fusion.target_type = TargetType.SELF
	tree_fusion.mp_cost = 15
	tree_fusion.cooldown = 3
	tree_fusion.element = EnemyData.ElementType.NATURE
	tree_fusion.effects = [
		{"type": "stealth", "duration": 2, "condition": "forest_terrain"},
		{"type": "heal", "amount": 20, "condition": "forest_terrain"}
	]
	skills["나무_융합"] = tree_fusion
	
	# 메아리 생성
	var echo_create = Skill.new("메아리_생성")
	echo_create.name = "메아리 생성"
	echo_create.description = "산이나 동굴에서 메아리를 만들어 적을 혼란시킨다."
	echo_create.skill_type = SkillType.ACTIVE
	echo_create.target_type = TargetType.AOE
	echo_create.range = 4
	echo_create.area_size = 2
	echo_create.mp_cost = 12
	echo_create.cooldown = 2
	echo_create.element = EnemyData.ElementType.WIND
	echo_create.effects = [
		{"type": "confusion", "duration": 2, "chance": 0.7},
		{"type": "damage", "amount": 15, "damage_type": "sonic"}
	]
	skills["메아리_생성"] = echo_create
	
	# 돌풍
	var gust_wind = Skill.new("돌풍")
	gust_wind.name = "돌풍"
	gust_wind.description = "강력한 바람을 일으켜 적을 밀어내고 데미지를 준다."
	gust_wind.skill_type = SkillType.ACTIVE
	gust_wind.target_type = TargetType.LINE
	gust_wind.range = 5
	gust_wind.area_size = 1
	gust_wind.mp_cost = 20
	gust_wind.cooldown = 3
	gust_wind.element = EnemyData.ElementType.WIND
	gust_wind.effects = [
		{"type": "damage", "amount": 25, "element": "wind"},
		{"type": "knockback", "distance": 2},
		{"type": "terrain_effect", "effect_type": "wind_current", "duration": 3}
	]
	skills["돌풍"] = gust_wind

# 동물계 스킬들
static func _create_animal_skills():
	# 둔갑술
	var transformation = Skill.new("둔갑술")
	transformation.name = "둔갑술"
	transformation.description = "다른 모습으로 변신하여 적을 속인다."
	transformation.skill_type = SkillType.ACTIVE
	transformation.target_type = TargetType.SELF
	transformation.mp_cost = 25
	transformation.cooldown = 5
	transformation.element = EnemyData.ElementType.DARK
	transformation.effects = [
		{"type": "stealth", "duration": 3},
		{"type": "stat_boost", "stat": "dex", "amount": 10, "duration": 3},
		{"type": "illusion", "duration": 3}
	]
	skills["둔갑술"] = transformation
	
	# 물 공격
	var water_attack = Skill.new("물_공격")
	water_attack.name = "물 공격"
	water_attack.description = "물줄기를 발사하여 적을 공격한다. 하천에서 위력이 증가한다."
	water_attack.skill_type = SkillType.ACTIVE
	water_attack.target_type = TargetType.SINGLE
	water_attack.range = 3
	water_attack.mp_cost = 10
	water_attack.cooldown = 1
	water_attack.element = EnemyData.ElementType.WATER
	water_attack.effects = [
		{"type": "damage", "amount": 30, "element": "water"},
		{"type": "wet_status", "duration": 2},
		{"type": "bonus_damage", "amount": 15, "condition": "river_terrain"}
	]
	skills["물_공격"] = water_attack
	
	# 끌어당기기
	var pull_attack = Skill.new("끌어당기기")
	pull_attack.name = "끌어당기기"
	pull_attack.description = "적을 자신 쪽으로 끌어당겨 익사시키려 한다."
	pull_attack.skill_type = SkillType.ACTIVE
	pull_attack.target_type = TargetType.SINGLE
	pull_attack.range = 2
	pull_attack.mp_cost = 15
	pull_attack.cooldown = 2
	pull_attack.element = EnemyData.ElementType.WATER
	pull_attack.effects = [
		{"type": "pull", "distance": 2},
		{"type": "grapple", "duration": 1},
		{"type": "drowning_attempt", "condition": "water_terrain"}
	]
	skills["끌어당기기"] = pull_attack

# 쓰쿠모가미 스킬들  
static func _create_object_skills():
	# 매혹 선율
	var charm_melody = Skill.new("매혹_선율")
	charm_melody.name = "매혹 선율"
	charm_melody.description = "아름다운 선율로 적을 매혹하여 조종한다."
	charm_melody.skill_type = SkillType.ACTIVE
	charm_melody.target_type = TargetType.AOE
	charm_melody.range = 4
	charm_melody.area_size = 3
	charm_melody.mp_cost = 30
	charm_melody.cooldown = 4
	charm_melody.element = EnemyData.ElementType.NONE
	charm_melody.effects = [
		{"type": "charm", "duration": 2, "chance": 0.6},
		{"type": "stat_debuff", "stat": "res", "amount": -5, "duration": 3},
		{"type": "sound_amplify", "condition": "cave_terrain"}
	]
	skills["매혹_선율"] = charm_melody
	
	# 현 채찍
	var string_whip = Skill.new("현_채찍")
	string_whip.name = "현 채찍"
	string_whip.description = "고토의 현을 채찍처럼 사용하여 적을 공격한다."
	string_whip.skill_type = SkillType.ACTIVE
	string_whip.target_type = TargetType.LINE
	string_whip.range = 4
	string_whip.mp_cost = 8
	string_whip.cooldown = 1
	string_whip.element = EnemyData.ElementType.NONE
	string_whip.effects = [
		{"type": "damage", "amount": 20, "damage_type": "physical"},
		{"type": "bind", "duration": 1, "chance": 0.3},
		{"type": "silence", "duration": 2, "chance": 0.4}
	]
	skills["현_채찍"] = string_whip

# 언데드계 스킬들
static func _create_undead_skills():
	# 원념 화염
	var grudge_flame = Skill.new("원념_화염")
	grudge_flame.name = "원념 화염"
	grudge_flame.description = "원한이 담긴 푸른 불꽃으로 적의 정신을 태운다."
	grudge_flame.skill_type = SkillType.ACTIVE
	grudge_flame.target_type = TargetType.SINGLE
	grudge_flame.range = 5
	grudge_flame.mp_cost = 20
	grudge_flame.cooldown = 2
	grudge_flame.element = EnemyData.ElementType.FIRE
	grudge_flame.effects = [
		{"type": "damage", "amount": 35, "element": "fire"},
		{"type": "curse", "duration": 3},
		{"type": "fear", "duration": 2, "chance": 0.5},
		{"type": "mp_burn", "amount": 10}
	]
	skills["원념_화염"] = grudge_flame
	
	# 공포 유발
	var fear_inducing = Skill.new("공포_유발")
	fear_inducing.name = "공포 유발"
	fear_inducing.description = "섬뜩한 모습으로 적들에게 공포를 심어준다."
	fear_inducing.skill_type = SkillType.ACTIVE
	fear_inducing.target_type = TargetType.AOE
	fear_inducing.range = 3
	fear_inducing.area_size = 2
	fear_inducing.mp_cost = 15
	fear_inducing.cooldown = 3
	fear_inducing.element = EnemyData.ElementType.DARK
	fear_inducing.effects = [
		{"type": "fear", "duration": 3, "chance": 0.8},
		{"type": "stat_debuff", "stat": "atk", "amount": -8, "duration": 3},
		{"type": "movement_penalty", "amount": -1, "duration": 3}
	]
	skills["공포_유발"] = fear_inducing

# 악마계 스킬들
static func _create_demon_skills():
	# 철봉 강타
	var iron_club_smash = Skill.new("철봉_강타")
	iron_club_smash.name = "철봉 강타"
	iron_club_smash.description = "거대한 철봉으로 적을 내려쳐 큰 데미지를 준다."
	iron_club_smash.skill_type = SkillType.ACTIVE
	iron_club_smash.target_type = TargetType.SINGLE
	iron_club_smash.range = 2
	iron_club_smash.mp_cost = 20
	iron_club_smash.cooldown = 2
	iron_club_smash.element = EnemyData.ElementType.NONE
	iron_club_smash.effects = [
		{"type": "damage", "amount": 60, "damage_type": "physical"},
		{"type": "knockback", "distance": 2},
		{"type": "stun", "duration": 1, "chance": 0.4},
		{"type": "armor_break", "amount": 10, "duration": 3}
	]
	skills["철봉_강타"] = iron_club_smash
	
	# 지옥 화염
	var hell_fire = Skill.new("지옥_화염")
	hell_fire.name = "지옥 화염"
	hell_fire.description = "지옥의 불꽃을 소환하여 광역을 불태운다."
	hell_fire.skill_type = SkillType.ACTIVE
	hell_fire.target_type = TargetType.AOE
	hell_fire.range = 4
	hell_fire.area_size = 3
	hell_fire.mp_cost = 35
	hell_fire.cooldown = 4
	hell_fire.element = EnemyData.ElementType.FIRE
	hell_fire.effects = [
		{"type": "damage", "amount": 45, "element": "fire"},
		{"type": "burn", "duration": 3, "damage": 8},
		{"type": "terrain_change", "to": "burning", "duration": 5},
		{"type": "bonus_damage", "amount": 20, "condition": "volcano_terrain"}
	]
	skills["지옥_화염"] = hell_fire
	
	# 포효
	var roar = Skill.new("포효")
	roar.name = "포효"
	roar.description = "무시무시한 포효로 적들을 위축시킨다."
	roar.skill_type = SkillType.ACTIVE
	roar.target_type = TargetType.AOE
	roar.range = 6
	roar.area_size = 4
	roar.mp_cost = 15
	roar.cooldown = 3
	roar.element = EnemyData.ElementType.NONE
	roar.effects = [
		{"type": "fear", "duration": 2, "chance": 0.9},
		{"type": "stat_debuff", "stat": "def", "amount": -10, "duration": 4},
		{"type": "interrupt", "chance": 1.0},
		{"type": "sound_wave", "damage": 10}
	]
	skills["포효"] = roar

# 원소계 공통 스킬들
static func _create_elemental_skills():
	# 화염 저항
	var fire_resistance = Skill.new("화염_저항")
	fire_resistance.name = "화염 저항"
	fire_resistance.description = "화염 속성 공격에 대한 저항력을 갖는다."
	fire_resistance.skill_type = SkillType.PASSIVE
	fire_resistance.target_type = TargetType.SELF
	fire_resistance.element = EnemyData.ElementType.FIRE
	fire_resistance.effects = [
		{"type": "resistance", "element": "fire", "amount": 50}
	]
	skills["화염_저항"] = fire_resistance
	
	# 자연 치유
	var nature_healing = Skill.new("자연_치유")
	nature_healing.name = "자연 치유"
	nature_healing.description = "자연 지형에서 매 턴 체력이 회복된다."
	nature_healing.skill_type = SkillType.PASSIVE
	nature_healing.target_type = TargetType.SELF
	nature_healing.element = EnemyData.ElementType.NATURE
	nature_healing.effects = [
		{"type": "regeneration", "amount": 5, "condition": "forest_terrain"},
		{"type": "regeneration", "amount": 3, "condition": "mountain_terrain"}
	]
	skills["자연_치유"] = nature_healing

# 스킬 가져오기
static func get_skill(skill_id: String) -> Skill:
	if skills.is_empty():
		initialize_skills()
	return skills.get(skill_id, null)

# 타입별 스킬 목록 가져오기
static func get_skills_by_type(type: SkillType) -> Array[Skill]:
	if skills.is_empty():
		initialize_skills()
	
	var result: Array[Skill] = []
	for skill in skills.values():
		if skill.skill_type == type:
			result.append(skill)
	return result

# 원소별 스킬 목록 가져오기
static func get_skills_by_element(element: EnemyData.ElementType) -> Array[Skill]:
	if skills.is_empty():
		initialize_skills()
	
	var result: Array[Skill] = []
	for skill in skills.values():
		if skill.element == element:
			result.append(skill)
	return result
