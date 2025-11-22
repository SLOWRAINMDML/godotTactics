class_name EnemyData
extends Resource

# 적 타입 열거형
enum EnemyType {
	YOKAI_SPIRIT,    # 정령계 요괊
	YOKAI_ANIMAL,    # 동물계 요괊
	YOKAI_OBJECT,    # 쓰쿠모가미 (물건 요괊)
	YOKAI_NATURE,    # 자연계 요괊
	YOKAI_UNDEAD,    # 언데드계 요괊
	YOKAI_DEMON      # 악마계 요괊
}

# 속성 열거형
enum ElementType {
	NONE,
	PHYSICAL,
	FIRE,
	WATER,
	WIND,
	EARTH,
	LIGHTNING,
	ICE,
	NATURE,
	HOLY,
	DARK,
	POISON
}

# 적 크기 열거형
enum EnemySize {
	SMALL,   # 1x1
	MEDIUM,  # 2x2
	LARGE,   # 3x3
	HUGE     # 4x4
}

# 개별 적 데이터 구조
class Enemy:
	var id: String
	var name: String
	var description: String
	var enemy_type: EnemyType
	var size: EnemySize
	
	# 기본 능력치
	var level: int
	var hp: int
	var mp: int
	var atk: int
	var def: int
	var dex: int
	var res: int
	var mov: int
	var jump: int
	
	# 속성
	var primary_element: ElementType
	var secondary_element: ElementType = ElementType.NONE
	
	# 속성 저항/취약성 (백분율)
	var resistances: Dictionary = {}
	var weaknesses: Dictionary = {}
	
	# 특수 능력
	var special_abilities: Array = []
	var passive_skills: Array = []
	var active_skills: Array = []
	
	# 지형 선호도 (이동 비용 할인/할증)
	var terrain_preferences: Dictionary = {}
	
	# 전리품
	var exp_reward: int
	var gold_reward: int
	var item_drops: Array = []
	var drop_rates: Array = []
	
	func _init(enemy_id: String):
		id = enemy_id

# 적 데이터베이스
static var enemies: Dictionary = {}

# 데이터베이스 초기화
static func initialize_database():
	_create_spirit_yokai()
	_create_animal_yokai()
	_create_object_yokai()
	_create_nature_yokai()
	_create_undead_yokai()
	_create_demon_yokai()

# 정령계 요괊 생성
static func _create_spirit_yokai():
	# 목매 (코다마) - 나무 정령
	var kodama = Enemy.new("kodama")
	kodama.name = "목매"
	kodama.description = "오래된 나무에 깃든 정령. 나무와 일체화되어 메아리를 만들어낸다."
	kodama.enemy_type = EnemyType.YOKAI_SPIRIT
	kodama.size = EnemySize.MEDIUM
	kodama.level = 3
	kodama.hp = 45
	kodama.mp = 35
	kodama.atk = 15
	kodama.def = 20
	kodama.dex = 12
	kodama.res = 25
	kodama.mov = 2
	kodama.jump = 1
	kodama.primary_element = ElementType.NATURE
	kodama.resistances[ElementType.NATURE] = 50
	kodama.resistances[ElementType.EARTH] = 30
	kodama.weaknesses[ElementType.FIRE] = 100
	kodama.special_abilities = ["나무_융합", "메아리_생성", "자연_치유"]
	kodama.passive_skills = ["숲_은신", "자연_저항"]
	kodama.active_skills = ["뿌리_얽매기", "잎사귀_폭풍"]
	kodama.terrain_preferences = {"Forest": -1, "Plain": 0, "Mountain": 1}
	kodama.exp_reward = 25
	kodama.gold_reward = 15
	kodama.item_drops = ["나무_조각", "정령_가루"]
	kodama.drop_rates = [0.7, 0.3]
	enemies["kodama"] = kodama
	
	# 야마비코 - 메아리 요괊
	var yamabiko = Enemy.new("yamabiko")
	yamabiko.name = "야마비코"
	yamabiko.description = "산속에서 메아리를 만들어내는 개 모습의 요괊. 소리를 되돌려 보낸다."
	yamabiko.enemy_type = EnemyType.YOKAI_SPIRIT
	yamabiko.size = EnemySize.SMALL
	yamabiko.level = 2
	yamabiko.hp = 30
	yamabiko.mp = 40
	yamabiko.atk = 12
	yamabiko.def = 15
	yamabiko.dex = 18
	yamabiko.res = 20
	yamabiko.mov = 4
	yamabiko.jump = 2
	yamabiko.primary_element = ElementType.WIND
	yamabiko.resistances[ElementType.WIND] = 40
	yamabiko.special_abilities = ["메아리_반사", "음파_공격"]
	yamabiko.passive_skills = ["산악_이동", "소음_감지"]
	yamabiko.active_skills = ["메아리_폭발", "혼란_소리"]
	yamabiko.terrain_preferences = {"Mountain": -1, "Cave": -1, "Forest": 0}
	yamabiko.exp_reward = 20
	yamabiko.gold_reward = 12
	yamabiko.item_drops = ["메아리_석", "바람_구슬"]
	yamabiko.drop_rates = [0.6, 0.4]
	enemies["yamabiko"] = yamabiko

# 동물계 요괊 생성
static func _create_animal_yokai():
	# 네코마타 - 고양이 요괊
	var nekomata = Enemy.new("nekomata")
	nekomata.name = "네코마타"
	nekomata.description = "오래 산 고양이가 변한 요괊. 꼬리가 두 갈래로 갈라져 있으며 둔갑술에 능하다."
	nekomata.enemy_type = EnemyType.YOKAI_ANIMAL
	nekomata.size = EnemySize.SMALL
	nekomata.level = 5
	nekomata.hp = 40
	nekomata.mp = 50
	nekomata.atk = 25
	nekomata.def = 18
	nekomata.dex = 28
	nekomata.res = 22
	nekomata.mov = 5
	nekomata.jump = 3
	nekomata.primary_element = ElementType.DARK
	nekomata.resistances[ElementType.DARK] = 35
	nekomata.special_abilities = ["둔갑술", "야행성", "묘족_발톱"]
	nekomata.passive_skills = ["은신", "야간_시야", "민첩성"]
	nekomata.active_skills = ["변신", "할퀴기", "미혹"]
	nekomata.terrain_preferences = {"Plain": 0, "Forest": -1, "Mountain": 0}
	nekomata.exp_reward = 35
	nekomata.gold_reward = 25
	nekomata.item_drops = ["고양이_털", "둔갑_부적", "마력_구슬"]
	nekomata.drop_rates = [0.8, 0.4, 0.2]
	enemies["nekomata"] = nekomata
	
	# 갓파 - 하천 요괊
	var kappa = Enemy.new("kappa")
	kappa.name = "갓파"
	kappa.description = "물속에 사는 요괊. 머리에 물접시가 있고 사람을 물속으로 끌어들인다."
	kappa.enemy_type = EnemyType.YOKAI_ANIMAL
	kappa.size = EnemySize.SMALL
	kappa.level = 4
	kappa.hp = 55
	kappa.mp = 35
	kappa.atk = 22
	kappa.def = 25
	kappa.dex = 20
	kappa.res = 18
	kappa.mov = 3
	kappa.jump = 1
	kappa.primary_element = ElementType.WATER
	kappa.resistances[ElementType.WATER] = 60
	kappa.resistances[ElementType.ICE] = 30
	kappa.weaknesses[ElementType.FIRE] = 50
	kappa.special_abilities = ["수중_전투", "익사_공격", "물접시_약점"]
	kappa.passive_skills = ["수영", "물_치유", "스모_격투"]
	kappa.active_skills = ["물_공격", "끌어당기기", "물_방어막"]
	kappa.terrain_preferences = {"River": -2, "Swamp": -1, "Plain": 1}
	kappa.exp_reward = 30
	kappa.gold_reward = 20
	kappa.item_drops = ["물_구슬", "갓파_껍질", "하천_진주"]
	kappa.drop_rates = [0.7, 0.5, 0.3]
	enemies["kappa"] = kappa

# 쓰쿠모가미 (물건 요괊) 생성
static func _create_object_yokai():
	# 고토후루누시 - 고토 요괊
	var kotofurunushi = Enemy.new("kotofurunushi")
	kotofurunushi.name = "고토후루누시"
	kotofurunushi.description = "오래된 고토가 변한 쓰쿠모가미. 잊힌 명곡을 연주하며 적을 매혹한다."
	kotofurunushi.enemy_type = EnemyType.YOKAI_OBJECT
	kotofurunushi.size = EnemySize.MEDIUM
	kotofurunushi.level = 6
	kotofurunushi.hp = 50
	kotofurunushi.mp = 70
	kotofurunushi.atk = 18
	kotofurunushi.def = 22
	kotofurunushi.dex = 15
	kotofurunushi.res = 35
	kotofurunushi.mov = 2
	kotofurunushi.jump = 0
	kotofurunushi.primary_element = ElementType.NONE
	kotofurunushi.resistances[ElementType.HOLY] = 40
	kotofurunushi.special_abilities = ["음악_매혹", "현_공격", "고대_선율"]
	kotofurunushi.passive_skills = ["음향_증폭", "정신_저항"]
	kotofurunushi.active_skills = ["매혹_선율", "현_채찍", "정적_공간"]
	kotofurunushi.terrain_preferences = {"Plain": 0, "Cave": -1}
	kotofurunushi.exp_reward = 40
	kotofurunushi.gold_reward = 35
	kotofurunushi.item_drops = ["고토_현", "음악_두루마리", "마력_공명석"]
	kotofurunushi.drop_rates = [0.8, 0.5, 0.3]
	enemies["kotofurunushi"] = kotofurunushi

# 자연계 요괊 생성
static func _create_nature_yokai():
	# 텐구 - 산의 요괊
	var tengu = Enemy.new("tengu")
	tengu.name = "텐구"
	tengu.description = "산에 사는 신통력을 가진 요괊. 날개를 가지고 있어 하늘을 자유롭게 날아다닌다."
	tengu.enemy_type = EnemyType.YOKAI_NATURE
	tengu.size = EnemySize.MEDIUM
	tengu.level = 8
	tengu.hp = 80
	tengu.mp = 60
	tengu.atk = 35
	tengu.def = 30
	tengu.dex = 32
	tengu.res = 28
	tengu.mov = 6
	tengu.jump = 999  # 비행 능력
	tengu.primary_element = ElementType.WIND
	tengu.resistances[ElementType.WIND] = 50
	tengu.resistances[ElementType.LIGHTNING] = 30
	tengu.special_abilities = ["비행", "신통력", "산신_권능"]
	tengu.passive_skills = ["비행", "고지대_마스터", "바람_조작"]
	tengu.active_skills = ["돌풍", "급강하_공격", "신숨_불기"]
	tengu.terrain_preferences = {"Mountain": -2, "Forest": -1, "Plain": 0}
	tengu.exp_reward = 60
	tengu.gold_reward = 45
	tengu.item_drops = ["텐구_깃털", "바람_부적", "산신_인장"]
	tengu.drop_rates = [0.9, 0.6, 0.2]
	enemies["tengu"] = tengu

# 언데드계 요괊 생성
static func _create_undead_yokai():
	# 소겐비 - 원념의 불꽃
	var sogenbi = Enemy.new("sogenbi")
	sogenbi.name = "소겐비"
	sogenbi.description = "원한을 품고 죽은 승려의 영혼이 도깨비불로 변한 모습."
	sogenbi.enemy_type = EnemyType.YOKAI_UNDEAD
	sogenbi.size = EnemySize.SMALL
	sogenbi.level = 7
	sogenbi.hp = 35
	sogenbi.mp = 80
	sogenbi.atk = 30
	sogenbi.def = 15
	sogenbi.dex = 25
	sogenbi.res = 40
	sogenbi.mov = 5
	sogenbi.jump = 999  # 부유 능력
	sogenbi.primary_element = ElementType.FIRE
	sogenbi.secondary_element = ElementType.DARK
	sogenbi.resistances[ElementType.FIRE] = 80
	sogenbi.resistances[ElementType.DARK] = 60
	sogenbi.resistances[ElementType.PHYSICAL] = 50
	sogenbi.weaknesses[ElementType.HOLY] = 100
	sogenbi.special_abilities = ["부유", "불꽃_조작", "원념_폭발"]
	sogenbi.passive_skills = ["언데드", "화염_면역", "정신_공격"]
	sogenbi.active_skills = ["원념_화염", "불꽃_비", "공포_유발"]
	sogenbi.terrain_preferences = {"Graveyard": -2, "Cave": -1}
	sogenbi.exp_reward = 50
	sogenbi.gold_reward = 30
	sogenbi.item_drops = ["원념_불씨", "승려_염주", "어둠_정수"]
	sogenbi.drop_rates = [0.8, 0.4, 0.3]
	enemies["sogenbi"] = sogenbi

# 악마계 요괊 생성
static func _create_demon_yokai():
	# 오니 - 지옥의 도깨비
	var oni = Enemy.new("oni")
	oni.name = "오니"
	oni.description = "지옥에서 온 강력한 도깨비. 뿔과 송곳니를 가지고 있으며 무시무시한 힘을 자랑한다."
	oni.enemy_type = EnemyType.YOKAI_DEMON
	oni.size = EnemySize.LARGE
	oni.level = 12
	oni.hp = 150
	oni.mp = 40
	oni.atk = 50
	oni.def = 45
	oni.dex = 15
	oni.res = 30
	oni.mov = 3
	oni.jump = 2
	oni.primary_element = ElementType.FIRE
	oni.secondary_element = ElementType.DARK
	oni.resistances[ElementType.FIRE] = 70
	oni.resistances[ElementType.DARK] = 50
	oni.resistances[ElementType.PHYSICAL] = 30
	oni.weaknesses[ElementType.HOLY] = 80
	oni.special_abilities = ["거대화", "광폭", "지옥_힘"]
	oni.passive_skills = ["무시무시한_존재", "재생", "고통_면역"]
	oni.active_skills = ["철봉_강타", "지옥_화염", "포효"]
	oni.terrain_preferences = {"Volcano": -1, "Cave": -1, "Mountain": 0}
	oni.exp_reward = 100
	oni.gold_reward = 80
	oni.item_drops = ["오니_뿔", "지옥_철", "악마_정수"]
	oni.drop_rates = [0.7, 0.5, 0.3]
	enemies["oni"] = oni

# 특정 적 데이터 가져오기
static func get_enemy(enemy_id: String) -> Enemy:
	if enemies.is_empty():
		initialize_database()
	return enemies.get(enemy_id, null)

# 타입별 적 목록 가져오기
static func get_enemies_by_type(type: EnemyType) -> Array[Enemy]:
	if enemies.is_empty():
		initialize_database()
	
	var result: Array[Enemy] = []
	for enemy in enemies.values():
		if enemy.enemy_type == type:
			result.append(enemy)
	return result

# 레벨 범위별 적 목록 가져오기
static func get_enemies_by_level_range(min_level: int, max_level: int) -> Array[Enemy]:
	if enemies.is_empty():
		initialize_database()
	
	var result: Array[Enemy] = []
	for enemy in enemies.values():
		if enemy.level >= min_level and enemy.level <= max_level:
			result.append(enemy)
	return result
