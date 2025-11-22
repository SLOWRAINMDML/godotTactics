extends Node3D
class_name Character

signal character_died(character)
signal health_changed(character, new_health, max_health)
signal skill_learned(character, skill_name)
signal class_changed(character, new_class)

# 기본 캐릭터 정보
var character_name: String = ""
var character_id: String = ""
var current_class: String = "Soldier"
var level: int = 1
var experience: int = 0

# 스탯
var base_stats: Dictionary = {
	"STR": 10, "DEF": 10, "DEX": 10, 
	"AGI": 10, "INT": 10, "RES": 10
}
var current_stats: Dictionary = {}
var stat_growth: Dictionary = {}

# 적성
var aptitudes: Dictionary = {
	"Sword": "C", "Lance": "C", "Bow": "C",
	"Staff": "C", "Magic": "C"
}

# 전투 상태
var max_health: int = 50
var current_health: int = 50
var max_mana: int = 20
var current_mana: int = 20

# 위치 및 이동
# 위치 및 이동
var grid_position: Vector2i = Vector2i.ZERO
var move_range: int = 10
# var has_moved: bool = false # Replaced by AP
# var has_acted: bool = false # Replaced by AP

# Action Points
var max_ap: int = 2
var current_ap: int = 2

# 스킬 및 장비
var learned_skills: Array = []
var equipped_weapon: String = ""
var equipment: Dictionary = {}

# 상태이상
var status_effects: Dictionary = {}

# 진영 (플레이어/적군)
var is_player_controlled: bool = true

# 시각적 표현
var sprite: Sprite3D
var health_bar: ProgressBar  
var name_label: Label3D # Changed to Label3D for 3D scene

func _ready():
	print("Character._ready() called for: ", character_name)
	# 초기 스탯 계산
	calculate_current_stats()
	# Visual setup moved to initialize_character to ensure proper order

func setup_visuals():
	print("Setting up visuals for: ", character_name)
	if not sprite:
		sprite = Sprite3D.new()
		add_child(sprite)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.pixel_size = 0.002 # Much smaller for 1024x1024 texture
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.position.y = 1.0 # Character height
		sprite.modulate = Color.WHITE # Ensure full visibility
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		sprite.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Load texture based on ID or Class
		load_texture()
		
		# Verify sprite has texture
		if sprite.texture:
			print("Sprite texture set: ", sprite.texture.get_size())
		else:
			print("ERROR: Sprite texture is null!")
		
		print("Sprite created and texture loaded")

	if not name_label:
		name_label = Label3D.new()
		add_child(name_label)
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_label.position.y = 3.0 # Higher above sprite
		name_label.text = character_name
		name_label.font_size = 48 # Larger font
		name_label.modulate = Color.WHITE
		name_label.outline_modulate = Color.BLACK
		name_label.outline_size = 4
		print("Label created for: ", character_name)

func load_texture():
	var texture_path = "res://assets/textures/sprites/"
	var file_name = ""
	
	# Map IDs/Classes to filenames
	match character_id:
		"kodama": file_name = "kodama.png"
		"nekomata": file_name = "nekomata.png"
		_:
			# If no ID match, try class
			match current_class:
				"Gunner", "Posu": file_name = "posu.png"
				"Spearman", "Salsu": file_name = "salsu.png"
				"Archer", "Gungsu": file_name = "gungsu.png"
				_: file_name = "posu.png" # Default
	
	if file_name != "":
		var full_path = texture_path + file_name
		print("Attempting to load texture: ", full_path)
		
		# Try ResourceLoader first
		if ResourceLoader.exists(full_path):
			var loaded_texture = ResourceLoader.load(full_path)
			if loaded_texture:
				sprite.texture = loaded_texture
				print("Texture loaded via ResourceLoader: ", full_path)
				return
			else:
				print("ResourceLoader returned null for: ", full_path)
		
		# Fallback: Try direct Image loading
		if FileAccess.file_exists(full_path):
			var img = Image.new()
			var err = img.load(full_path)
			if err == OK:
				var tex = ImageTexture.create_from_image(img)
				sprite.texture = tex
				print("Texture loaded via Image: ", full_path, " size: ", img.get_size())
			else:
				print("Failed to load image, error: ", err)
		else:
			print("Texture file not found: ", full_path)

# 캐릭터 데이터로 초기화
func initialize_character(data: Dictionary):
	character_name = data.get("name", "Unknown")
	character_id = data.get("id", "")
	current_class = data.get("class", "Soldier")
	level = data.get("level", 1)
	
	# 스탯 설정
	if "stats" in data:
		base_stats = data["stats"].duplicate()
	
	# 적성 설정
	if "aptitude" in data:
		aptitudes.merge(data["aptitude"])
	
	# 스킬 설정
	if "skills" in data:
		learned_skills = data["skills"].duplicate()
	
	# 위치 설정
	if "position" in data:
		grid_position = data["position"]
		print("DEBUG: ", character_name, "의 grid_position 설정됨: ", grid_position)
	
	# 턴 상태 초기화
	current_ap = max_ap
	
	calculate_current_stats()
	calculate_health_mana()
	
	# Visual update
	setup_visuals()
	update_visual()
	
	print(character_name, " 캐릭터가 초기화되었습니다. 위치: ", grid_position)

func calculate_current_stats():
	current_stats = base_stats.duplicate()
	
	# 클래스 보너스 적용
	if GameData.CLASSES.has(current_class):
		var class_data = GameData.CLASSES[current_class]
		stat_growth = class_data["stat_growth"]
	
	# 레벨에 따른 스탯 증가 (성장률 기반)
	for stat in base_stats:
		var growth = stat_growth.get(stat, 0.5)
		var level_bonus = int((level - 1) * growth * 2)  # 레벨당 평균 2 증가
		current_stats[stat] = base_stats[stat] + level_bonus
	
	# Calculate Max AP based on DEX
	# Default 2. DEX 15+ -> 3, DEX 25+ -> 4
	max_ap = 2
	if current_stats["DEX"] >= 25:
		max_ap = 4
	elif current_stats["DEX"] >= 15:
		max_ap = 3

func calculate_health_mana():
	# 체력과 마나 계산
	max_health = 30 + current_stats["DEF"] * 2 + level * 3
	max_mana = 10 + current_stats["INT"] + level
	
	# 현재 체력/마나가 최대치를 넘지 않도록
	current_health = min(current_health, max_health)
	current_mana = min(current_mana, max_mana)

func level_up():
	level += 1
	
	# 스탯 성장
	for stat in base_stats:
		var growth_rate = stat_growth.get(stat, 0.5)
		if randf() < growth_rate:
			base_stats[stat] += 1
			print(character_name, "의 ", stat, " 증가!")
	
	calculate_current_stats()
	calculate_health_mana()
	
	# 새로운 스킬 학습 가능성 확인
	check_new_skills()
	
	print(character_name, " 레벨업! 레벨 ", level)
	update_visual()

func check_new_skills():
	if GameData.CLASSES.has(current_class):
		var class_data = GameData.CLASSES[current_class]
		for skill in class_data["skills"]:
			if not skill in learned_skills:
				# 레벨이나 특정 조건을 만족하면 스킬 학습
				if level >= 5 or randf() < 0.3:  # 30% 확률 또는 레벨 5 이상
					learn_skill(skill)

func learn_skill(skill_name: String):
	if not skill_name in learned_skills:
		learned_skills.append(skill_name)
		emit_signal("skill_learned", self, skill_name)
		print(character_name, "이(가) ", skill_name, " 스킬을 배웠습니다!")

# 클래스 체인지 시도
func attempt_class_change(target_class: String) -> bool:
	var character_data = {
		"class": current_class,
		"aptitude": aptitudes,
		"level": level
	}
	
	if GameData.can_class_change(character_data, target_class):
		change_class(target_class)
		return true
	else:
		print(character_name, "은(는) ", target_class, "로 전직할 수 없습니다.")
		return false

func change_class(new_class: String):
	var old_class = current_class
	current_class = new_class
	
	# 새로운 클래스의 스킬들을 학습 가능 목록에 추가
	if GameData.CLASSES.has(new_class):
		var class_data = GameData.CLASSES[new_class]
		for skill in class_data["skills"]:
			if not skill in learned_skills:
				learned_skills.append(skill)
				print(character_name, "이(가) 클래스 체인지로 ", skill, " 스킬을 습득했습니다!")
	
	# 스탯 재계산
	calculate_current_stats()
	calculate_health_mana()
	
	# Update texture for new class
	load_texture()
	
	emit_signal("class_changed", self, new_class)
	print(character_name, "이(가) ", old_class, "에서 ", new_class, "로 전직했습니다!")

# 데미지 받기
func take_damage(damage: int, damage_type: String = "Physical"):
	var actual_damage = damage
	
	# 상태이상 효과 적용
	if "MagicShield" in status_effects and damage_type == "Magic":
		actual_damage = int(actual_damage * 0.5)
		print("마법 보호막이 데미지를 감소시켰습니다!")
	
	current_health -= actual_damage
	current_health = max(0, current_health)
	
	emit_signal("health_changed", self, current_health, max_health)
	
	# Visual feedback (flash red)
	if sprite:
		sprite.modulate = Color(1, 0, 0)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.3)
	
	print(character_name, "이(가) ", actual_damage, " 데미지를 받았습니다. (", current_health, "/", max_health, ")")
	
	if current_health <= 0:
		die()

# 치유
func heal(amount: int):
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	
	var healed_amount = current_health - old_health
	if healed_amount > 0:
		emit_signal("health_changed", self, current_health, max_health)
		# Visual feedback (flash green)
		if sprite:
			sprite.modulate = Color(0, 1, 0)
			var tween = create_tween()
			tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.3)
			
		print(character_name, "이(가) ", healed_amount, " 체력을 회복했습니다.")

# 사망 처리
func die():
	print(character_name, "이(가) 쓰러졌습니다...")
	emit_signal("character_died", self)
	# 시각적 효과나 애니메이션 추가 가능
	queue_free()

# 스킬 사용
func use_skill(skill_name: String, target_position: Vector2i, battle_grid) -> bool:
	if not skill_name in learned_skills:
		print(character_name, "은(는) ", skill_name, " 스킬을 모릅니다.")
		return false
	
	var skill_data = GameData.SKILLS.get(skill_name)
	if not skill_data:
		print("스킬 데이터 없음: ", skill_name)
		return false

	var mana_cost = skill_data.get("mana_cost", 0)
	
	if current_mana < mana_cost:
		print("마나가 부족합니다!")
		return false
	
	# 사거리 확인
	var distance = grid_position.distance_to(target_position)
	if distance > skill_data["range"]:
		print("사거리가 부족합니다!")
		return false
	
	# 마나 소모
	current_mana -= mana_cost
	
	# 스킬 효과 적용
	apply_skill_effect(skill_name, target_position, battle_grid)
	
	current_ap -= 1
	print("Action used. Remaining AP: ", current_ap)
	return true

func apply_skill_effect(skill_name: String, target_position: Vector2i, battle_grid):
	var skill_data = GameData.SKILLS.get(skill_name)
	# var terrain_name = battle_grid.get_terrain_at_position(target_position)
	
	print(character_name, "이(가) ", skill_name, " 스킬을 사용했습니다!")
	
	# 지형 변화 효과
	if skill_data and skill_data.get("effect") == "CreateBurningGround":
		battle_grid.change_terrain(target_position, "BurningGround")

# 이동
func move_to(new_position: Vector2i, battle_grid) -> bool:
	print(character_name, " 이동 시도: ", grid_position, " -> ", new_position)
	
	if current_ap < 1:
		print("AP가 부족합니다!")
		return false
	
	var reachable_tiles = battle_grid.get_reachable_tiles(grid_position, move_range)
	
	if not new_position in reachable_tiles:
		print("이동할 수 없는 위치입니다! ", new_position, " not in ", reachable_tiles)
		return false
	
	var old_position = grid_position
	grid_position = new_position
	current_ap -= 1
	print("Move used. Remaining AP: ", current_ap)
	
	# 시각적 이동 (3D)
	var world_pos: Vector3 = battle_grid.grid_to_world(grid_position)
	
	# Smooth movement using Tween
	var tween = create_tween()
	tween.tween_property(self, "position", world_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	print(character_name, "이(가) ", old_position, "에서 ", new_position, "로 이동했습니다.")
	return true

# 턴 시작 시 리셋 (GameManager에서 호출)
func start_turn():
	current_ap = max_ap
	print(character_name, " Turn Start! AP: ", current_ap)
	
	# 상태이상 처리
	process_status_effects()

func process_status_effects():
	# 상태이상 효과 처리 및 지속시간 감소
	for effect in status_effects.keys():
		status_effects[effect] -= 1
		if status_effects[effect] <= 0:
			status_effects.erase(effect)
			print(character_name, "의 ", effect, " 효과가 해제되었습니다.")

func add_status_effect(effect_name: String, duration: int = 3):
	status_effects[effect_name] = duration
	print(character_name, "에게 ", effect_name, " 효과가 적용되었습니다.")

func update_visual():
	if name_label:
		name_label.text = character_name + " Lv." + str(level)

# 적성 등급 개선 (훈련, 경험 등으로)
func improve_aptitude(weapon_type: String):
	var current_grade = aptitudes.get(weapon_type, "D")
	var grades = ["D", "C", "B", "A", "S"]
	var current_index = grades.find(current_grade)
	
	if current_index < grades.size() - 1 and randf() < 0.1:  # 10% 확률
		var new_grade = grades[current_index + 1]
		aptitudes[weapon_type] = new_grade
		print(character_name, "의 ", weapon_type, " 적성이 ", new_grade, "로 향상되었습니다!")
