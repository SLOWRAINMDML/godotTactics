extends AcceptDialog
class_name ClassChangeDialog

signal class_changed(character, new_class)

@onready var character_info_label: Label = $VBox/CharacterInfo
@onready var current_class_label: Label = $VBox/CurrentClass
@onready var available_classes_list: ItemList = $VBox/AvailableClasses
@onready var class_details_label: RichTextLabel = $VBox/ClassDetails
@onready var confirm_button: Button = $VBox/ConfirmButton

var target_character: Character = null
var available_classes: Array = []

func _ready():
	title = "클래스 체인지"
	set_min_size(Vector2(400, 500))
	
	# 신호 연결
	available_classes_list.item_selected.connect(_on_class_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirmed.connect(_on_dialog_confirmed)

func show_for_character(character: Character):
	target_character = character
	update_character_info()
	find_available_classes()
	popup_centered()

func update_character_info():
	if not target_character:
		return
	
	character_info_label.text = "%s (Lv.%d)" % [target_character.character_name, target_character.level]
	current_class_label.text = "현재 클래스: %s" % target_character.current_class

func find_available_classes():
	available_classes.clear()
	available_classes_list.clear()
	
	if not target_character:
		return
	
	var character_data = {
		"class": target_character.current_class,
		"aptitude": target_character.aptitudes,
		"level": target_character.level
	}
	
	# 모든 클래스 확인
	for class_name in GameData.CLASSES:
		if class_name != target_character.current_class:
			if GameData.can_class_change(character_data, class_name):
				available_classes.append(class_name)
				available_classes_list.add_item(class_name)
	
	if available_classes.size() == 0:
		available_classes_list.add_item("전직 가능한 클래스가 없습니다")
		available_classes_list.set_item_disabled(0, true)
		confirm_button.disabled = true
	else:
		confirm_button.disabled = false

func _on_class_selected(index: int):
	if index >= 0 and index < available_classes.size():
		var selected_class = available_classes[index]
		show_class_details(selected_class)

func show_class_details(class_name: String):
	var class_data = GameData.CLASSES[class_name]
	
	var details = "[b]%s[/b]\n\n" % class_name
	details += "[color=yellow]무기:[/color] %s\n\n" % ", ".join(class_data["weapons"])
	details += "[color=green]스킬:[/color] %s\n\n" % ", ".join(class_data["skills"])
	
	# 필요 적성 표시
	if class_data["aptitude"].size() > 0:
		details += "[color=orange]필요 적성:[/color]\n"
		for aptitude in class_data["aptitude"]:
			var required_grade = class_data["aptitude"][aptitude]
			var current_grade = target_character.aptitudes.get(aptitude, "D")
			var color = "green" if GameData.is_aptitude_sufficient(current_grade, required_grade) else "red"
			details += "- %s: %s (보유: [color=%s]%s[/color])\n" % [aptitude, required_grade, color, current_grade]
		details += "\n"
	
	# 성장률 표시
	details += "[color=cyan]성장률:[/color]\n"
	for stat in class_data["stat_growth"].keys():
		var growth_rate = class_data["stat_growth"][stat]
		var percentage = int(growth_rate * 100)
		details += "- %s: %d%%\n" % [stat, percentage]
	
	class_details_label.text = details

func _on_confirm_pressed():
	var selected_index = available_classes_list.get_selected_items()
	if selected_index.size() > 0:
		var class_index = selected_index[0]
		if class_index < available_classes.size():
			var new_class = available_classes[class_index]
			target_character.change_class(new_class)
			emit_signal("class_changed", target_character, new_class)
			hide()

func _on_dialog_confirmed():
	# AcceptDialog의 확인 버튼이 눌렸을 때
	pass 