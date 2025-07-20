# -----------------------------------------------------------------------------
# [후임자를 위한 안내]
#
# Character.gd (캐릭터)
#
# [역할]
# 이 스크립트는 게임에 등장하는 모든 유닛(플레이어, 적군)의 데이터와 행동을 정의하는
# 핵심 클래스입니다. 각 캐릭터는 이 스크립트를 기반으로 한 노드(Node)로 씬에 존재하게 됩니다.
#
# [Godot 학습 팁: class_name]
# - `class_name Character` 구문은 이 스크립트를 Godot 엔진에 'Character'라는 새로운 타입으로 등록합니다.
# - 이렇게 등록하면 다른 스크립트에서 `var char: Character` 와 같이 타입 힌트로 사용하거나,
#   `Character.new()` 와 같이 인스턴스를 생성하는 데 사용할 수 있어 코드의 안정성과 가독성을 높입니다.
#
# [상호작용 방식]
# - 데이터 초기화: BattleScene에서 생성될 때 `initialize_character` 함수를 통해
#                  GameData에 정의된 데이터를 받아와 자신의 속성을 설정합니다.
# - 행동: BattleScene의 명령을 받아 `move_to`, `use_skill` 등의 함수를 실행합니다.
# - 상태 변화 알림: 자신의 상태가 변하면(예: 데미지를 받거나, 죽거나, 클래스가 바뀌면)
#                  `signal`을 발생시켜 BattleScene이나 다른 관리자에게 알립니다.
# -----------------------------------------------------------------------------
extends Node2D
class_name Character # 이 스크립트를 "Character"라는 커스텀 타입으로 등록합니다.

# [시그널 정의]
# 이 캐릭터의 상태에 중요한 변화가 생겼을 때 외부에 알리는 신호들입니다.
signal character_died(character) # 캐릭터가 사망했을 때 발생
signal health_changed(character, new_health, max_health) # 체력이 변경되었을 때 발생
signal skill_learned(character, skill_name) # 새로운 스킬을 배웠을 때 발생
signal class_changed(character, new_class) # 클래스가 변경되었을 때 발생

# [기본 캐릭터 정보]
var character_name: String = ""
var character_id: String = "" # 고유 식별자
var current_class: String = "Soldier" # 현재 클래스
var level: int = 1
var experience: int = 0

# [스탯(Stats)]
var base_stats: Dictionary = { # 장비나 버프를 제외한 순수 스탯
	"STR": 10, "DEF": 10, "DEX": 10, 
	"AGI": 10, "INT": 10, "RES": 10
}
var current_stats: Dictionary = {} # 모든 보너스가 적용된 현재 스탯
var stat_growth: Dictionary = {} # 클래스에 따른 레벨업 시 스탯 성장률

# [적성(Aptitudes)]
# 특정 무기나 능력에 대한 재능. 등급이 높을수록 성능이 향상됩니다.
var aptitudes: Dictionary = {
	"Sword": "C", "Lance": "C", "Bow": "C",
	"Staff": "C", "Magic": "C"
}

# [전투 상태]
var max_health: int = 50
var current_health: int = 50
var max_mana: int = 20
var current_mana: int = 20

# [위치 및 이동]
var grid_position: Vector2i = Vector2i.ZERO # BattleGrid 상의 좌표
var move_range: int = 10 # 한 턴에 이동할 수 있는 거리
var has_moved: bool = false # 이번 턴에 이동을 했는지 여부
var has_acted: bool = false # 이번 턴에 공격/스킬 등 행동을 했는지 여부

# [스킬 및 장비]
var learned_skills: Array = [] # 배운 스킬 목록
var equipped_weapon: String = ""
var equipment: Dictionary = {} # 장비 아이템 (투구, 갑옷 등)

# [상태이상]
var status_effects: Dictionary = {} # 현재 걸려있는 상태이상 효과 (예: { "Poison": 3 }) -> 3턴 동안 독 상태

# [진영]
var is_player_controlled: bool = true # 플레이어가 조종하는 캐릭터인지 여부

# [시각적 요소 참조]
# 이 노드들은 BattleScene에서 동적으로 생성되고 자식으로 추가되므로,
# `@onready` 키워드를 사용하지 않습니다.
var sprite: Sprite2D
var health_bar: ProgressBar  
var name_label: Label

# Godot 엔진이 이 노드를 씬 트리에 추가할 때 자동으로 호출하는 내장 함수입니다.
func _ready():
	# 초기 스탯을 계산하고 시각적 요소를 업데이트합니다.
	calculate_current_stats()
	update_visual()
	
	# UI 요소가 존재할 경우 초기화합니다.
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	if name_label:
		name_label.text = character_name

## 캐릭터의 모든 데이터를 초기화하는 함수입니다.
## 주로 BattleScene에서 캐릭터를 생성할 때 호출됩니다.
## @param data: 캐릭터 정보를 담은 Dictionary (GameData의 형식과 유사)
func initialize_character(data: Dictionary):
	character_name = data.get("name", "Unknown")
	character_id = data.get("id", "")
	current_class = data.get("class", "Soldier")
	level = data.get("level", 1)
	
	if "stats" in data:
		base_stats = data["stats"].duplicate() # 원본 데이터를 보호하기 위해 복사해서 사용
	
	if "aptitude" in data:
		aptitudes.merge(data["aptitude"]) # 기존 적성 데이터에 덮어쓰기
	
	if "skills" in data:
		learned_skills = data["skills"].duplicate()
	
	if "position" in data:
		grid_position = data["position"]
		print("DEBUG: ", character_name, "의 grid_position 설정됨: ", grid_position)
	
	# 턴 시작 시 행동 가능하도록 초기화
	has_moved = false
	has_acted = false
	
	# 데이터를 기반으로 최종 스탯과 체력/마나를 계산합니다.
	calculate_current_stats()
	calculate_health_mana()
	update_visual()
	
	print(character_name, " 캐릭터가 초기화되었습니다. 위치: ", grid_position)

## 현재 스탯(current_stats)을 다시 계산합니다.
## 레벨업, 클래스 변경, 장비 교체 등 스탯에 영향을 주는 변화가 있을 때 호출됩니다.
func calculate_current_stats():
	current_stats = base_stats.duplicate()
	
	# 1. 클래스 보너스 적용
	var class_data = GameData.CLASSES[current_class]
	stat_growth = class_data["stat_growth"]
	
	# 2. 레벨에 따른 스탯 증가 (성장률 기반)
	for stat in base_stats:
		var growth = stat_growth.get(stat, 0.5)
		var level_bonus = int((level - 1) * growth * 2) # 레벨당 평균 2씩 증가하도록 계산
		current_stats[stat] = base_stats[stat] + level_bonus

	# 3. TODO: 장비, 버프/디버프에 의한 스탯 변화를 여기에 추가할 수 있습니다.

## 현재 스탯을 기반으로 최대 체력과 마나를 계산합니다.
func calculate_health_mana():
	max_health = 30 + current_stats["DEF"] * 2 + level * 3
	max_mana = 10 + current_stats["INT"] + level
	
	# 현재 체력/마나가 최대치를 넘지 않도록 조정합니다.
	current_health = min(current_health, max_health)
	current_mana = min(current_mana, max_mana)

## 캐릭터를 레벨업시킵니다.
func level_up():
	level += 1
	
	# 스탯 성장: 각 스탯에 대해 성장률 확률에 따라 1씩 증가시킵니다.
	for stat in base_stats:
		var growth_rate = stat_growth.get(stat, 0.5)
		if randf() < growth_rate: # randf()는 0.0 ~ 1.0 사이의 랜덤 실수를 반환
			base_stats[stat] += 1
			print(character_name, "의 ", stat, " 증가!")
	
	calculate_current_stats()
	calculate_health_mana()
	
	# 새로운 스킬을 배울 수 있는지 확인합니다.
	check_new_skills()
	
	print(character_name, " 레벨업! 레벨 ", level)

## 레벨업 시 새로운 스킬을 배울 수 있는지 확인하고 배웁니다.
func check_new_skills():
	var class_data = GameData.CLASSES[current_class]
	for skill in class_data["skills"]:
		if not skill in learned_skills:
			# 특정 레벨에 도달하거나, 낮은 확률로 스킬을 배웁니다.
			if level >= 5 or randf() < 0.3:
				learn_skill(skill)

## 새로운 스킬을 배웁니다.
func learn_skill(skill_name: String):
	if not skill_name in learned_skills:
		learned_skills.append(skill_name)
		emit_signal("skill_learned", self, skill_name) # 외부에 스킬 배웠음을 알림
		print(character_name, "이(가) ", skill_name, " 스킬을 배웠습니다!")

## 클래스 체인지를 시도합니다.
## @param target_class: 전직하려는 클래스 이름
## @return: 전직 성공 여부
func attempt_class_change(target_class: String) -> bool:
	var character_data = {
		"class": current_class,
		"aptitude": aptitudes,
		"level": level
	}
	
	# GameData의 규칙에 따라 전직이 가능한지 확인합니다.
	if GameData.can_class_change(character_data, target_class):
		change_class(target_class)
		return true
	else:
		print(character_name, "은(는) ", target_class, "로 전직할 수 없습니다.")
		return false

## 클래스를 실제로 변경합니다.
func change_class(new_class: String):
	var old_class = current_class
	current_class = new_class
	
	# 새로운 클래스의 스킬들을 배웁니다.
	var class_data = GameData.CLASSES[new_class]
	for skill in class_data["skills"]:
		if not skill in learned_skills:
			learn_skill(skill)
	
	# 스탯을 새로운 클래스에 맞게 다시 계산합니다.
	calculate_current_stats()
	calculate_health_mana()
	
	emit_signal("class_changed", self, new_class) # 외부에 클래스 변경을 알림
	print(character_name, "이(가) ", old_class, "에서 ", new_class, "로 전직했습니다!")

## 데미지를 받는 로직입니다.
## @param damage: 받을 데미지 양
## @param damage_type: 데미지 종류 ("Physical" 또는 "Magic")
func take_damage(damage: int, damage_type: String = "Physical"):
	var actual_damage = damage
	
	# 상태이상 효과(예: 마법 보호막)를 적용합니다.
	if "MagicShield" in status_effects and damage_type == "Magic":
		actual_damage = int(actual_damage * 0.5)
		print("마법 보호막이 데미지를 감소시켰습니다!")
	
	current_health -= actual_damage
	current_health = max(0, current_health) # 체력이 0 미만으로 내려가지 않도록
	
	emit_signal("health_changed", self, current_health, max_health) # 외부에 체력 변경을 알림
	
	if health_bar:
		health_bar.value = current_health
	
	print(character_name, "이(가) ", actual_damage, " 데미지를 받았습니다. (", current_health, "/", max_health, ")")
	
	if current_health <= 0:
		die()

## 체력을 회복합니다.
func heal(amount: int):
	var old_health = current_health
	current_health = min(max_health, current_health + amount) # 최대 체력을 넘지 않도록
	
	var healed_amount = current_health - old_health
	if healed_amount > 0:
		emit_signal("health_changed", self, current_health, max_health)
		if health_bar:
			health_bar.value = current_health
		print(character_name, "이(가) ", healed_amount, " 체력을 회복했습니다.")

## 캐릭터가 사망했을 때의 처리를 담당합니다.
func die():
	print(character_name, "이(가) 쓰러졌습니다...")
	emit_signal("character_died", self) # 외부에 사망 사실을 알림
	# TODO: 여기에 사망 애니메이션, 시각 효과 등을 추가할 수 있습니다.

## 스킬을 사용합니다.
## @param skill_name: 사용할 스킬의 이름
## @param target_position: 스킬을 사용할 대상 타일의 그리드 좌표
## @param battle_grid: 현재 전투의 BattleGrid 참조
## @return: 스킬 사용 성공 여부
func use_skill(skill_name: String, target_position: Vector2i, battle_grid) -> bool:
	if not skill_name in learned_skills:
		print(character_name, "은(는) ", skill_name, " 스킬을 모릅니다.")
		return false
	
	var skill_data = GameData.SKILLS[skill_name]
	var mana_cost = skill_data.get("mana_cost", 0)
	
	if current_mana < mana_cost:
		print("마나가 부족합니다!")
		return false
	
	# 사거리 확인
	var distance = grid_position.distance_to(target_position)
	if distance > skill_data["range"]:
		print("사거리가 부족합니다!")
		return false
	
	current_mana -= mana_cost
	apply_skill_effect(skill_name, target_position, battle_grid)
	
	has_acted = true # 행동을 마쳤음을 표시
	return true

## 스킬의 실제 효과를 적용합니다.
func apply_skill_effect(skill_name: String, target_position: Vector2i, battle_grid):
	var skill_data = GameData.SKILLS[skill_name]
	var terrain_name = battle_grid.get_terrain_at_position(target_position)
	
	print(character_name, "이(가) ", skill_name, " 스킬을 사용했습니다!")
	
	# TODO: 여기에 공격, 버프, 디버프 등 다양한 스킬 효과를 구현합니다.

	# 지형을 변화시키는 효과가 있는 경우, BattleGrid의 함수를 호출합니다.
	if skill_data["effect"] == "CreateBurningGround":
		battle_grid.change_terrain(target_position, "BurningGround")

## 캐릭터를 새로운 위치로 이동시킵니다.
## @param new_position: 이동할 목표 타일의 그리드 좌표
## @param battle_grid: 현재 전투의 BattleGrid 참조
## @return: 이동 성공 여부
func move_to(new_position: Vector2i, battle_grid) -> bool:
	print(character_name, " 이동 시도: ", grid_position, " -> ", new_position)
	
	if has_moved:
		print("이미 이동했습니다!")
		return false
	
	# BattleGrid를 통해 이동 가능한 타일인지 확인합니다.
	var reachable_tiles = battle_grid.get_reachable_tiles(grid_position, move_range)
	if not new_position in reachable_tiles:
		print("이동할 수 없는 위치입니다! ", new_position, " not in ", reachable_tiles)
		return false
	
	var old_position = grid_position
	grid_position = new_position
	has_moved = true # 이동을 마쳤음을 표시
	
	# 시각적 위치 업데이트: 그리드 좌표를 실제 화면(월드) 좌표로 변환합니다.
	var world_pos = battle_grid.grid_to_world(grid_position)
	var height = battle_grid.get_height_at_position(grid_position)
	
	# 최종 위치는 BattleGrid의 원점 + 타일의 월드 좌표 + 높이 오프셋
	var final_pos = battle_grid.position + world_pos
	final_pos.y -= height * 15 # 높이만큼 y좌표를 위로 올려 입체감을 표현
	position = final_pos # Node2D의 position 속성을 변경하여 화면에 실제로 이동시킴
	
	print("새로운 월드 위치: ", position, " (높이: ", height, ")")
	print(character_name, "이(가) ", old_position, "에서 ", new_position, "로 이동했습니다.")
	return true

## 턴이 종료될 때 호출되어 캐릭터의 상태를 초기화합니다.
func end_turn():
	has_moved = false
	has_acted = false
	
	# 턴 기반 상태이상 효과를 처리합니다.
	process_status_effects()

## 턴마다 상태이상 효과를 처리합니다. (지속시간 감소 등)
func process_status_effects():
	for effect in status_effects.keys():
		status_effects[effect] -= 1 # 지속시간 1턴 감소
		if status_effects[effect] <= 0:
			status_effects.erase(effect) # 지속시간이 다 되면 효과 제거
			print(character_name, "의 ", effect, " 효과가 해제되었습니다.")

## 캐릭터에게 새로운 상태이상을 추가합니다.
func add_status_effect(effect_name: String, duration: int = 3):
	status_effects[effect_name] = duration
	print(character_name, "에게 ", effect_name, " 효과가 적용되었습니다.")

## 캐릭터의 시각적 표현(이름표 등)을 업데이트합니다.
func update_visual():
	# BattleScene에서 동적으로 생성된 이름 라벨이 있다면 업데이트합니다.
	if name_label:
		name_label.text = character_name + " Lv." + str(level)

## 훈련, 경험 등을 통해 무기 적성을 향상시킵니다.
func improve_aptitude(weapon_type: String):
	var current_grade = aptitudes.get(weapon_type, "D")
	var grades = ["D", "C", "B", "A", "S"]
	var current_index = grades.find(current_grade)
	
	# 낮은 확률로 적성 등급이 한 단계 상승합니다.
	if current_index < grades.size() - 1 and randf() < 0.1:
		var new_grade = grades[current_index + 1]
		aptitudes[weapon_type] = new_grade
		print(character_name, "의 ", weapon_type, " 적성이 ", new_grade, "로 향상되었습니다!") 
