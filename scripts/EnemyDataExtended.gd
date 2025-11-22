class_name EnemyDataExtended
extends EnemyData

# Force reload


# 확장 적 데이터베이스 초기화
static func initialize_extended_database():
	_create_more_spirit_yokai()
	_create_more_animal_yokai()
	_create_more_object_yokai()
	_create_elemental_yokai()
	_create_legendary_yokai()

# 추가 정령계 요괊들
static func _create_more_spirit_yokai():
	# 야마와라와 - 산동자
	var yamawarawa = Enemy.new("yamawarawa")
	yamawarawa.name = "야마와라와"
	yamawarawa.description = "산에 사는 외눈의 아이 요괊. 나무를 깎는 일을 돕거나 방해한다."
	yamawarawa.enemy_type = EnemyType.YOKAI_SPIRIT
	yamawarawa.size = EnemySize.SMALL
	yamawarawa.level = 4
	yamawarawa.hp = 35
	yamawarawa.mp = 30
	yamawarawa.atk = 18
	yamawarawa.def = 15
	yamawarawa.dex = 22
	yamawarawa.res = 20
	yamawarawa.mov = 4
	yamawarawa.jump = 2
	yamawarawa.primary_element = ElementType.NATURE
	yamawarawa.resistances[ElementType.NATURE] = 40
	yamawarawa.resistances[ElementType.EARTH] = 25
	yamawarawa.special_abilities = ["산악_이동", "나무_가공", "외눈_시야"]
	yamawarawa.passive_skills = ["산악_적응", "나무_친화"]
	yamawarawa.active_skills = ["나무_던지기", "산_메아리", "민첩_회피"]
	yamawarawa.terrain_preferences = {"Mountain": -2, "Forest": -1}
	yamawarawa.exp_reward = 28
	yamawarawa.gold_reward = 18
	yamawarawa.item_drops = ["산_열매", "나무_조각", "외눈_구슬"]
	yamawarawa.drop_rates = [0.8, 0.6, 0.2]
	enemies["yamawarawa"] = yamawarawa
	
	# 야마우바 - 산할멈
	var yamauba = Enemy.new("yamauba")
	yamauba.name = "야마우바"
	yamauba.description = "산 깊숙이 사는 늙은 여자 요괊. 때로는 도움을 주기도 하지만 위험한 존재다."
	yamauba.enemy_type = EnemyType.YOKAI_SPIRIT
	yamauba.size = EnemySize.MEDIUM
	yamauba.level = 9
	yamauba.hp = 95
	yamauba.mp = 75
	yamauba.atk = 30
	yamauba.def = 25
	yamauba.dex = 18
	yamauba.res = 40
	yamauba.mov = 3
	yamauba.jump = 2
	yamauba.primary_element = ElementType.NATURE
	yamauba.secondary_element = ElementType.DARK
	yamauba.resistances[ElementType.NATURE] = 60
	yamauba.resistances[ElementType.DARK] = 45
	yamauba.special_abilities = ["산신_권능", "양면성", "생명_조작"]
	yamauba.passive_skills = ["산_지배", "날씨_예측", "재생능력"]
	yamauba.active_skills = ["산_가호", "저주_시전", "생명_흡수"]
	yamauba.terrain_preferences = {"Mountain": -2, "Forest": -1, "Cave": -1}
	yamauba.exp_reward = 65
	yamauba.gold_reward = 50
	yamauba.item_drops = ["산신_부적", "야마우바_머리카락", "신비_열매"]
	yamauba.drop_rates = [0.6, 0.8, 0.3]
	enemies["yamauba"] = yamauba

# 추가 동물계 요괊들
static func _create_more_animal_yokai():
	# 다누키 - 너구리 요괊
	var tanuki = Enemy.new("tanuki")
	tanuki.name = "다누키"
	tanuki.description = "둔갑술에 능한 너구리 요괊. 큰 음낭으로 여러 가지 변신을 한다."
	tanuki.enemy_type = EnemyType.YOKAI_ANIMAL
	tanuki.size = EnemySize.SMALL
	tanuki.level = 6
	tanuki.hp = 50
	tanuki.mp = 60
	tanuki.atk = 20
	tanuki.def = 22
	tanuki.dex = 25
	tanuki.res = 28
	tanuki.mov = 4
	tanuki.jump = 2
	tanuki.primary_element = ElementType.NONE
	tanuki.resistances[ElementType.DARK] = 30
	tanuki.special_abilities = ["둔갑술", "음낭_변형", "해학_기질"]
	tanuki.passive_skills = ["변신", "속임수", "행운"]
	tanuki.active_skills = ["팔첩_만들기", "다누키_둔갑", "배_두드리기"]
	tanuki.terrain_preferences = {"Forest": -1, "Plain": 0}
	tanuki.exp_reward = 40
	tanuki.gold_reward = 30
	tanuki.item_drops = ["다누키_털", "변신_잎사귀", "행운_부적"]
	tanuki.drop_rates = [0.7, 0.5, 0.3]
	enemies["tanuki"] = tanuki
	
	# 가와우소 - 수달 요괊
	var kawauso = Enemy.new("kawauso")
	kawauso.name = "가와우소"
	kawauso.description = "강에 사는 수달 요괊. 아름다운 여성으로 변신하여 사람을 홀린다."
	kawauso.enemy_type = EnemyType.YOKAI_ANIMAL
	kawauso.size = EnemySize.SMALL
	kawauso.level = 5
	kawauso.hp = 45
	kawauso.mp = 45
	kawauso.atk = 24
	kawauso.def = 20
	kawauso.dex = 30
	kawauso.res = 25
	kawauso.mov = 5
	kawauso.jump = 2
	kawauso.primary_element = ElementType.WATER
	kawauso.resistances[ElementType.WATER] = 50
	kawauso.resistances[ElementType.ICE] = 25
	kawauso.special_abilities = ["변신술", "물고기_제사", "수중_이동"]
	kawauso.passive_skills = ["수영", "미인_변신", "민첩성"]
	kawauso.active_skills = ["유혹", "물_조작", "미끄러짐"]
	kawauso.terrain_preferences = {"River": -2, "Swamp": -1}
	kawauso.exp_reward = 35
	kawauso.gold_reward = 25
	kawauso.item_drops = ["수달_털", "변신_기름", "강_진주"]
	kawauso.drop_rates = [0.8, 0.4, 0.3]
	enemies["kawauso"] = kawauso

# 추가 쓰쿠모가미들
static func _create_more_object_yokai():
	# 비와보쿠보쿠 - 비파 요괊
	var biwa_bokuboku = Enemy.new("biwa_bokuboku")
	biwa_bokuboku.name = "비와보쿠보쿠"
	biwa_bokuboku.description = "잊힌 명기 비파가 변한 쓰쿠모가미. 눈먼 승려의 모습을 하고 있다."
	biwa_bokuboku.enemy_type = EnemyType.YOKAI_OBJECT
	biwa_bokuboku.size = EnemySize.MEDIUM
	biwa_bokuboku.level = 7
	biwa_bokuboku.hp = 55
	biwa_bokuboku.mp = 80
	biwa_bokuboku.atk = 20
	biwa_bokuboku.def = 25
	biwa_bokuboku.dex = 18
	biwa_bokuboku.res = 45
	biwa_bokuboku.mov = 2
	biwa_bokuboku.jump = 0
	biwa_bokuboku.primary_element = ElementType.NONE
	biwa_bokuboku.resistances[ElementType.HOLY] = 35
	biwa_bokuboku.special_abilities = ["음악_치유", "영혼_진혼", "맹목_감지"]
	biwa_bokuboku.passive_skills = ["음향_증폭", "영적_연주", "맹목_극복"]
	biwa_bokuboku.active_skills = ["진혼곡", "비파_타격", "음파_방어"]
	biwa_bokuboku.terrain_preferences = {"Cave": -1, "Plain": 0}
	biwa_bokuboku.exp_reward = 45
	biwa_bokuboku.gold_reward = 40
	biwa_bokuboku.item_drops = ["비파_현", "승려_염주", "음악_두루마리"]
	biwa_bokuboku.drop_rates = [0.8, 0.5, 0.4]
	enemies["biwa_bokuboku"] = biwa_bokuboku
	
	# 고소데노테 - 기모노 소매의 손
	var kosode_no_te = Enemy.new("kosode_no_te")
	kosode_no_te.name = "고소데노테"
	kosode_no_te.description = "유녀의 원념이 깃든 기모노. 소매에서 창백한 손이 뻗어나온다."
	kosode_no_te.enemy_type = EnemyType.YOKAI_OBJECT
	kosode_no_te.size = EnemySize.MEDIUM
	kosode_no_te.level = 8
	kosode_no_te.hp = 60
	kosode_no_te.mp = 70
	kosode_no_te.atk = 25
	kosode_no_te.def = 18
	kosode_no_te.dex = 20
	kosode_no_te.res = 35
	kosode_no_te.mov = 3
	kosode_no_te.jump = 0
	kosode_no_te.primary_element = ElementType.DARK
	kosode_no_te.secondary_element = ElementType.NONE
	kosode_no_te.resistances[ElementType.DARK] = 50
	kosode_no_te.resistances[ElementType.PHYSICAL] = 30
	kosode_no_te.special_abilities = ["유녀_원념", "소매_공격", "화대_갈망"]
	kosode_no_te.passive_skills = ["원념", "부유", "슬픈_매력"]
	kosode_no_te.active_skills = ["원념_손길", "슬픔_전파", "자유_갈망"]
	kosode_no_te.terrain_preferences = {"Plain": 0}
	kosode_no_te.exp_reward = 55
	kosode_no_te.gold_reward = 45
	kosode_no_te.item_drops = ["기모노_조각", "원념_구슬", "유녀_머리핀"]
	kosode_no_te.drop_rates = [0.9, 0.6, 0.3]
	enemies["kosode_no_te"] = kosode_no_te

# 원소계 요괊들
static func _create_elemental_yokai():
	# 기쓰네비 - 여우불
	var kitsunebi = Enemy.new("kitsunebi")
	kitsunebi.name = "기쓰네비"
	kitsunebi.description = "여우들이 만들어내는 신비한 불꽃. 행렬을 이루며 사람을 홀린다."
	kitsunebi.enemy_type = EnemyType.YOKAI_NATURE
	kitsunebi.size = EnemySize.SMALL
	kitsunebi.level = 6
	kitsunebi.hp = 30
	kitsunebi.mp = 90
	kitsunebi.atk = 28
	kitsunebi.def = 12
	kitsunebi.dex = 35
	kitsunebi.res = 50
	kitsunebi.mov = 6
	kitsunebi.jump = 999  # 부유
	kitsunebi.primary_element = ElementType.FIRE
	kitsunebi.secondary_element = ElementType.DARK
	kitsunebi.resistances[ElementType.FIRE] = 80
	kitsunebi.resistances[ElementType.PHYSICAL] = 60
	kitsunebi.weaknesses[ElementType.WATER] = 100
	kitsunebi.special_abilities = ["부유", "여우불_조작", "미혹_행렬"]
	kitsunebi.passive_skills = ["불꽃_면역", "부유", "환상_생성"]
	kitsunebi.active_skills = ["여우불_비", "미혹_행렬", "불꽃_순간이동"]
	kitsunebi.terrain_preferences = {"Forest": -1, "Plain": 0}
	kitsunebi.exp_reward = 40
	kitsunebi.gold_reward = 35
	kitsunebi.item_drops = ["여우불_정수", "환상_가루", "신비_불씨"]
	kitsunebi.drop_rates = [0.7, 0.5, 0.4]
	enemies["kitsunebi"] = kitsunebi
	
	# 쓰루베비 - 두레박 불
	var tsurubebi = Enemy.new("tsurubebi")
	tsurubebi.name = "쓰루베비"
	tsurubebi.description = "나무에서 내려오는 푸른 불덩이. 두레박처럼 위아래로 움직인다."
	tsurubebi.enemy_type = EnemyType.YOKAI_NATURE
	tsurubebi.size = EnemySize.SMALL
	tsurubebi.level = 5
	tsurubebi.hp = 25
	tsurubebi.mp = 60
	tsurubebi.atk = 22
	tsurubebi.def = 10
	tsurubebi.dex = 30
	tsurubebi.res = 35
	tsurubebi.mov = 4
	tsurubebi.jump = 999  # 부유
	tsurubebi.primary_element = ElementType.FIRE
	tsurubebi.secondary_element = ElementType.NATURE
	tsurubebi.resistances[ElementType.FIRE] = 70
	tsurubebi.resistances[ElementType.PHYSICAL] = 50
	tsurubebi.special_abilities = ["부유", "수직_이동", "길막기"]
	tsurubebi.passive_skills = ["부유", "나무_친화", "야간_활동"]
	tsurubebi.active_skills = ["두레박_드롭", "푸른_불꽃", "길_차단"]
	tsurubebi.terrain_preferences = {"Forest": -2, "Mountain": -1}
	tsurubebi.exp_reward = 32
	tsurubebi.gold_reward = 25
	tsurubebi.item_drops = ["푸른_불씨", "나무_정수", "신비_로프"]
	tsurubebi.drop_rates = [0.8, 0.4, 0.3]
	enemies["tsurubebi"] = tsurubebi

# 전설급 요괊들
static func _create_legendary_yokai():
	# 조로구모 - 거미 요괊
	var jorougumo = Enemy.new("jorougumo")
	jorougumo.name = "조로구모"
	jorougumo.description = "아름다운 여성으로 변신하는 거대한 거미 요괊. 비파로 남자를 유혹한다."
	jorougumo.enemy_type = EnemyType.YOKAI_ANIMAL
	jorougumo.size = EnemySize.LARGE
	jorougumo.level = 15
	jorougumo.hp = 180
	jorougumo.mp = 120
	jorougumo.atk = 45
	jorougumo.def = 35
	jorougumo.dex = 38
	jorougumo.res = 40
	jorougumo.mov = 5
	jorougumo.jump = 3
	jorougumo.primary_element = ElementType.POISON
	jorougumo.secondary_element = ElementType.DARK
	jorougumo.resistances[ElementType.POISON] = 80
	jorougumo.resistances[ElementType.DARK] = 60
	jorougumo.weaknesses[ElementType.FIRE] = 80
	jorougumo.special_abilities = ["거미줄_조작", "미인_변신", "독_분비"]
	jorougumo.passive_skills = ["거미_감각", "독_면역", "변신술"]
	jorougumo.active_skills = ["거미줄_덫", "독_물기", "유혹_연주"]
	jorougumo.terrain_preferences = {"Cave": -2, "Forest": -1, "Web": -3}
	jorougumo.exp_reward = 120
	jorougumo.gold_reward = 100
	jorougumo.item_drops = ["조로구모_실", "독_샘", "비파_조각", "미인_가면"]
	jorougumo.drop_rates = [0.9, 0.7, 0.5, 0.2]
	enemies["jorougumo"] = jorougumo
	
	# 지리즈카카이오 - 쓰레기더미의 왕
	var chirizuka_kaiou = Enemy.new("chirizuka_kaiou")
	chirizuka_kaiou.name = "지리즈카카이오"
	chirizuka_kaiou.description = "모든 쓰쿠모가미들의 왕. 버려진 물건들로 이루어진 관을 쓰고 있다."
	chirizuka_kaiou.enemy_type = EnemyType.YOKAI_OBJECT
	chirizuka_kaiou.size = EnemySize.HUGE
	chirizuka_kaiou.level = 20
	chirizuka_kaiou.hp = 300
	chirizuka_kaiou.mp = 200
	chirizuka_kaiou.atk = 55
	chirizuka_kaiou.def = 60
	chirizuka_kaiou.dex = 25
	chirizuka_kaiou.res = 70
	chirizuka_kaiou.mov = 2
	chirizuka_kaiou.jump = 1
	chirizuka_kaiou.primary_element = ElementType.DARK
	chirizuka_kaiou.resistances[ElementType.DARK] = 70
	chirizuka_kaiou.resistances[ElementType.PHYSICAL] = 50
	chirizuka_kaiou.resistances[ElementType.FIRE] = 40
	chirizuka_kaiou.special_abilities = ["쓰쿠모가미_지배", "물건_조작", "왕의_위엄"]
	chirizuka_kaiou.passive_skills = ["왕_오라", "재생", "물질_지배"]
	chirizuka_kaiou.active_skills = ["쓰레기_폭풍", "쓰쿠모가미_소환", "왕의_명령"]
	chirizuka_kaiou.terrain_preferences = {"Plain": 0}
	chirizuka_kaiou.exp_reward = 200
	chirizuka_kaiou.gold_reward = 150
	chirizuka_kaiou.item_drops = ["왕의_관", "쓰쿠모가미_정수", "고대_유물", "버려진_보물"]
	chirizuka_kaiou.drop_rates = [0.3, 0.8, 0.6, 0.4]
	enemies["chirizuka_kaiou"] = chirizuka_kaiou

# 확장 데이터베이스 통합 함수
static func get_all_enemies() -> Dictionary:
	var all_enemies = EnemyData.enemies.duplicate()
	all_enemies.merge(enemies)
	return all_enemies

# 난이도별 적 그룹 가져오기
static func get_enemy_group_by_difficulty(difficulty: String) -> Array[String]:
	match difficulty:
		"easy":
			return ["kodama", "yamabiko", "yamawarawa", "tsurubebi"]
		"normal":
			return ["nekomata", "kappa", "tanuki", "kawauso", "kitsunebi"]
		"hard":
			return ["kotofurunushi", "biwa_bokuboku", "kosode_no_te", "tengu", "sogenbi"]
		"expert":
			return ["yamauba", "oni", "jorougumo"]
		"boss":
			return ["chirizuka_kaiou"]
		_:
			return []

# 지형별 추천 적 목록
static func get_enemies_for_terrain(terrain: String) -> Array[String]:
	match terrain:
		"Forest":
			return ["kodama", "yamawarawa", "tanuki", "tsurubebi", "kitsunebi"]
		"Mountain":
			return ["yamabiko", "yamawarawa", "yamauba", "tengu"]
		"River", "Swamp":
			return ["kappa", "kawauso"]
		"Cave":
			return ["biwa_bokuboku", "jorougumo"]
		"Volcano":
			return ["oni", "sogenbi"]
		"Plain":
			return ["nekomata", "kosode_no_te", "chirizuka_kaiou"]
		_:
			return [] 