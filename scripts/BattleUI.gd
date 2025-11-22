extends CanvasLayer

@onready var turn_label: Label = $TurnLabel
@onready var action_label: Label = $ActionLabel

func _ready():
	print("BattleUI ready")
	
	# Connect buttons
	$EndTurnButton.pressed.connect(_on_end_turn_pressed)
	$AttackButton.pressed.connect(_on_attack_pressed)
	
	update_turn_info("전투 준비 완료!")

func _on_battle_started():
	update_turn_info("Battle Started!")

func _on_turn_advanced(character):
	var info = "Turn: " + character.character_name
	if character.is_player_controlled:
		info += " (Player)"
	else:
		info += " (Enemy)"
	update_turn_info(info)

func _on_unit_selected(unit):
	if unit:
		var info = "Selected: " + unit.character_name + "\n"
		info += "HP: " + str(unit.current_health) + "/" + str(unit.max_health) + "\n"
		info += "MP: " + str(unit.current_mana) + "/" + str(unit.max_mana) + "\n"
		info += "Class: " + unit.current_class
		if action_label:
			action_label.text = info
	else:
		if action_label:
			action_label.text = "No selection"

func _on_end_turn_pressed():
	print("End Turn button pressed!")
	update_turn_info("턴 종료 버튼이 눌렸습니다")
	if action_label:
		action_label.text = "다음 턴으로 이동..."

func _on_attack_pressed():
	print("Attack button pressed!")
	update_turn_info("공격 모드 활성화")
	if action_label:
		action_label.text = "공격할 대상을 선택하세요"

func _on_log_message(text):
	if action_label:
		action_label.text = text

func _on_battle_ended():
	update_turn_info("Battle Ended")

func update_turn_info(text: String):
	if turn_label:
		turn_label.text = text
