# -----------------------------------------------------------------------------
# [후임자를 위한 안내]
#
# ClassChangeDialog.gd (클래스 체인지 대화상자)
#
# [역할]
# 이 스크립트는 캐릭터의 클래스(직업)를 변경할 때 사용되는 UI 대화상자를 제어합니다.
# Godot의 내장 `AcceptDialog` 노드를 상속받아 커스텀 UI 로직을 구현했습니다.
#
# [주요 기능]
# 1. 전직 가능 클래스 표시: 특정 캐릭터가 전직할 수 있는 클래스 목록을 보여줍니다.
# 2. 클래스 정보 제공: 선택한 클래스의 상세 정보(요구 조건, 스킬, 성장률 등)를 표시합니다.
# 3. 전직 실행: 플레이어의 확인을 받아 캐릭터의 클래스를 실제로 변경합니다.
#
# [Godot 학습 팁: 내장 UI 노드 확장]
# - Godot는 다양한 UI 노드(Button, Label, Panel 등)를 제공합니다.
# - 이 스크립트처럼 `AcceptDialog`와 같은 기존 노드를 `extends` 키워드로 상속받으면,
#   기본적인 창 기능(예: 닫기 버튼, 타이틀)을 그대로 사용하면서 필요한 기능만
#   추가하여 손쉽게 복잡한 UI를 만들 수 있습니다.
# - `RichTextLabel`은 BBCode를 사용하여 텍스트의 일부만 색상을 바꾸거나 굵게 만드는 등
#   다채로운 텍스트 표현이 가능합니다. `show_class_details` 함수에서 그 사용법을 확인해보세요.
# -----------------------------------------------------------------------------
extends AcceptDialog
class_name ClassChangeDialog

# 클래스 변경이 완료되었을 때 발생하는 시그널
signal class_changed(character, new_class)

# [UI 노드 참조]
# 이 대화상자 씬 내부에 있는 UI 요소들에 대한 참조입니다.
@onready var character_info_label: Label = $VBox/CharacterInfo
@onready var current_class_label: Label = $VBox/CurrentClass
@onready var available_classes_list: ItemList = $VBox/AvailableClasses
@onready var class_details_label: RichTextLabel = $VBox/ClassDetails
@onready var confirm_button: Button = $VBox/ConfirmButton

# [상태 변수]
var target_character: Character = null # 클래스 체인지를 시도할 캐릭터 객체
var available_classes: Array = []      # 전직 가능한 클래스 이름 목록

# Godot 엔진이 이 노드를 씬 트리에 추가할 때 자동으로 호출하는 내장 함수입니다.
func _ready():
	title = "클래스 체인지"
	set_min_size(Vector2(400, 500))
	
	# UI 요소들의 시그널을 이 스크립트의 함수와 연결합니다.
	available_classes_list.item_selected.connect(_on_class_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirmed.connect(_on_dialog_confirmed) # AcceptDialog의 기본 'OK' 버튼 시그널

## 특정 캐릭터에 대한 클래스 체인지 대화상자를 엽니다.
## @param character: 전직시킬 대상 캐릭터
func show_for_character(character: Character):
	target_character = character
	update_character_info()
	find_available_classes()
	popup_centered() # 대화상자를 화면 중앙에 표시

## 대화상자 상단의 캐릭터 정보를 업데이트합니다.
func update_character_info():
	if not target_character:
		return
	
	character_info_label.text = "%s (Lv.%d)" % [target_character.character_name, target_character.level]
	current_class_label.text = "현재 클래스: %s" % target_character.current_class

## 대상 캐릭터가 전직할 수 있는 모든 클래스를 찾아서 목록에 표시합니다.
func find_available_classes():
	available_classes.clear()
	available_classes_list.clear()
	
	if not target_character:
		return
	
	# 캐릭터의 현재 데이터를 Dictionary 형태로 만듭니다.
	var character_data = {
		"class": target_character.current_class,
		"aptitude": target_character.aptitudes,
		"level": target_character.level
	}
	
	# GameData에 정의된 모든 클래스를 순회하며 전직 가능 여부를 확인합니다.
	for class_name in GameData.CLASSES:
		if class_name != target_character.current_class:
			# GameData의 규칙에 따라 전직 가능한지 확인합니다.
			if GameData.can_class_change(character_data, class_name):
				available_classes.append(class_name)
				available_classes_list.add_item(class_name)
	
	# 전직 가능한 클래스가 없으면 메시지를 표시하고 확인 버튼을 비활성화합니다.
	if available_classes.size() == 0:
		available_classes_list.add_item("전직 가능한 클래스가 없습니다")
		available_classes_list.set_item_disabled(0, true)
		confirm_button.disabled = true
	else:
		confirm_button.disabled = false

## `available_classes_list`에서 항목을 선택했을 때 호출됩니다.
func _on_class_selected(index: int):
	if index >= 0 and index < available_classes.size():
		var selected_class = available_classes[index]
		show_class_details(selected_class)

## 선택된 클래스의 상세 정보를 `class_details_label`에 표시합니다.
func show_class_details(class_name: String):
	var class_data = GameData.CLASSES[class_name]
	
	# RichTextLabel의 BBCode를 사용하여 텍스트 서식을 꾸밉니다.
	var details = "[b]%s[/b]\n\n" % class_name
	details += "[color=yellow]무기:[/color] %s\n\n" % ", ".join(class_data["weapons"])
	details += "[color=green]스킬:[/color] %s\n\n" % ", ".join(class_data["skills"])
	
	# 필요 적성 조건을 표시합니다.
	if class_data["aptitude"].size() > 0:
		details += "[color=orange]필요 적성:[/color]\n"
		for aptitude in class_data["aptitude"]:
			var required_grade = class_data["aptitude"][aptitude]
			var current_grade = target_character.aptitudes.get(aptitude, "D")
			# 조건 충족 여부에 따라 텍스트 색상을 다르게 표시합니다.
			var color = "green" if GameData.is_aptitude_sufficient(current_grade, required_grade) else "red"
			details += "- %s: %s (보유: [color=%s]%s[/color])\n" % [aptitude, required_grade, color, current_grade]
		details += "\n"
	
	# 성장률 정보를 표시합니다.
	details += "[color=cyan]성장률:[/color]\n"
	for stat in class_data["stat_growth"].keys():
		var growth_rate = class_data["stat_growth"][stat]
		var percentage = int(growth_rate * 100)
		details += "- %s: %d%%\n" % [stat, percentage]
	
	class_details_label.bbcode_text = details

## '확인' 버튼을 눌렀을 때 호출됩니다.
func _on_confirm_pressed():
	var selected_items = available_classes_list.get_selected_items()
	if selected_items.size() > 0:
		var class_index = selected_items[0]
		if class_index < available_classes.size():
			var new_class = available_classes[class_index]
			# 캐릭터의 클래스를 실제로 변경합니다.
			target_character.change_class(new_class)
			# 클래스 변경이 완료되었음을 외부에 알립니다.
			emit_signal("class_changed", target_character, new_class)
			hide() # 대화상자를 닫습니다.

## AcceptDialog의 기본 'OK' 버튼이 눌렸을 때 호출됩니다. (현재는 사용하지 않음)
func _on_dialog_confirmed():
	pass 