# 📖 단순화된 시나리오 시스템

## 9.1. 시스템 단순화 목표

복잡한 기능들을 제거하고 핵심 기능에만 집중하여 **안정적이고 직관적인** 시나리오 시스템을 구축합니다.

### 9.1.1. 제거된 기능들
- ❌ **선택지 시스템**: 분기 스토리 없음 (선형 진행)
- ❌ **음성 지원**: 텍스트 기반 대화만
- ❌ **복잡한 시퀀스 조합**: 기본 시퀀스만 지원
- ❌ **8명 배치 제한**: 유연한 인원 선택
- ❌ **실시간 전력 평가**: 단순 확인만

### 9.1.2. 핵심 기능들
- ✅ **기본 대화 시스템**: 화자 + 텍스트 + 초상화 + 타이핑 효과
- ✅ **간단한 컷신**: 카메라 이동, 캐릭터 이동
- ✅ **인터미션 관리**: 캐릭터 관리, 상점, 저장, 진행
- ✅ **유연한 캐릭터 배치**: 선택 → 배치 → 제거
- ✅ **직관적인 스토리 에디터**: 대화 + 이벤트 편집

## 9.2. 핵심 대화 시스템

### 9.2.1. DialogueSystem 구현

```gdscript
# scripts/DialogueSystem.gd (신규 생성)
extends Control
class_name DialogueSystem

signal dialogue_complete()
signal dialogue_skipped()

@onready var dialogue_box: Panel
@onready var speaker_label: Label
@onready var text_label: RichTextLabel
@onready var portrait_rect: TextureRect
@onready var continue_button: Button

var current_dialogue_data: Dictionary = {}
var current_line_index: int = 0
var typing_speed: float = 0.05
var is_typing: bool = false

func _ready():
    setup_dialogue_ui()
    visible = false

func setup_dialogue_ui():
    # 대화창 배경
    dialogue_box = Panel.new()
    dialogue_box.size = Vector2(800, 200)
    dialogue_box.position = Vector2(100, 400)
    add_child(dialogue_box)
    
    # 화자 이름
    speaker_label = Label.new()
    speaker_label.position = Vector2(20, 10)
    speaker_label.size = Vector2(200, 30)
    speaker_label.add_theme_font_size_override("font_size", 18)
    dialogue_box.add_child(speaker_label)
    
    # 대화 텍스트
    text_label = RichTextLabel.new()
    text_label.position = Vector2(20, 50)
    text_label.size = Vector2(600, 120)
    text_label.bbcode_enabled = true
    dialogue_box.add_child(text_label)
    
    # 초상화
    portrait_rect = TextureRect.new()
    portrait_rect.position = Vector2(650, 20)
    portrait_rect.size = Vector2(120, 120)
    portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    dialogue_box.add_child(portrait_rect)
    
    # 계속 버튼
    continue_button = Button.new()
    continue_button.text = "계속"
    continue_button.position = Vector2(700, 150)
    continue_button.size = Vector2(80, 30)
    continue_button.pressed.connect(_on_continue_pressed)
    dialogue_box.add_child(continue_button)

func start_dialogue(dialogue_data: Dictionary):
    current_dialogue_data = dialogue_data
    current_line_index = 0
    visible = true
    display_current_line()

func display_current_line():
    if current_line_index >= current_dialogue_data["lines"].size():
        end_dialogue()
        return
    
    var line_data = current_dialogue_data["lines"][current_line_index]
    
    # 화자 설정
    speaker_label.text = line_data.get("speaker", "")
    
    # 초상화 설정
    if line_data.has("portrait"):
        var texture = load("res://assets/portraits/" + line_data["portrait"] + ".png")
        portrait_rect.texture = texture
        portrait_rect.visible = true
    else:
        portrait_rect.visible = false
    
    # 텍스트 타이핑 효과
    start_typing(line_data["text"])

func start_typing(text: String):
    is_typing = true
    text_label.text = ""
    continue_button.visible = false
    
    for i in range(text.length()):
        if not is_typing:  # 스킵된 경우
            text_label.text = text
            break
        
        text_label.text = text.substr(0, i + 1)
        await get_tree().create_timer(typing_speed).timeout
    
    is_typing = false
    continue_button.visible = true

func _input(event):
    if visible and event.is_action_pressed("ui_accept"):
        if is_typing:
            # 타이핑 스킵
            is_typing = false
        else:
            # 다음 대화로
            _on_continue_pressed()

func _on_continue_pressed():
    current_line_index += 1
    display_current_line()

func end_dialogue():
    visible = false
    emit_signal("dialogue_complete")
```

### 9.2.2. 대화 데이터 구조

```json
{
    "dialogue_id": "chapter1_opening",
    "lines": [
        {
            "speaker": "엘레나",
            "text": "드디어 적의 요새가 보이는군요, 대장님.",
            "portrait": "elena_normal"
        },
        {
            "speaker": "주인공",
            "text": "조심스럽게 접근하자. 함정이 있을지도 모른다.",
            "portrait": "protagonist_serious"
        },
        {
            "speaker": "",
            "text": "[적의 함성이 들려온다]",
            "portrait": ""
        }
    ]
}
```

## 9.3. 인터미션 시스템

### 9.3.1. IntermissionSystem 구현

```gdscript
# scripts/IntermissionSystem.gd (신규 생성)
extends Control
class_name IntermissionSystem

signal intermission_complete()
signal battle_preparation_requested()

@onready var character_panel: Panel
@onready var shop_panel: Panel
@onready var save_panel: Panel
@onready var progress_panel: Panel

var available_characters: Array = []
var selected_characters: Array = []

func _ready():
    setup_intermission_ui()

func setup_intermission_ui():
    # 캐릭터 관리 패널
    character_panel = create_character_panel()
    add_child(character_panel)
    
    # 상점 패널
    shop_panel = create_shop_panel()
    add_child(shop_panel)
    
    # 저장 패널
    save_panel = create_save_panel()
    add_child(save_panel)
    
    # 진행 패널
    progress_panel = create_progress_panel()
    add_child(progress_panel)

func create_character_panel() -> Panel:
    var panel = Panel.new()
    panel.size = Vector2(400, 500)
    panel.position = Vector2(50, 50)
    
    var title = Label.new()
    title.text = "캐릭터 관리"
    title.position = Vector2(20, 20)
    panel.add_child(title)
    
    # 캐릭터 목록
    var character_list = ItemList.new()
    character_list.position = Vector2(20, 60)
    character_list.size = Vector2(360, 300)
    character_list.item_selected.connect(_on_character_selected)
    panel.add_child(character_list)
    
    # 클래스 변경 버튼
    var class_change_btn = Button.new()
    class_change_btn.text = "클래스 변경"
    class_change_btn.position = Vector2(20, 380)
    class_change_btn.pressed.connect(_on_class_change_pressed)
    panel.add_child(class_change_btn)
    
    return panel

func create_shop_panel() -> Panel:
    var panel = Panel.new()
    panel.size = Vector2(350, 400)
    panel.position = Vector2(500, 50)
    
    var title = Label.new()
    title.text = "상점"
    title.position = Vector2(20, 20)
    panel.add_child(title)
    
    # 아이템 목록
    var item_list = ItemList.new()
    item_list.position = Vector2(20, 60)
    item_list.size = Vector2(310, 250)
    panel.add_child(item_list)
    
    # 구매 버튼
    var buy_btn = Button.new()
    buy_btn.text = "구매"
    buy_btn.position = Vector2(20, 330)
    buy_btn.pressed.connect(_on_buy_pressed)
    panel.add_child(buy_btn)
    
    return panel

func create_progress_panel() -> Panel:
    var panel = Panel.new()
    panel.size = Vector2(300, 200)
    panel.position = Vector2(500, 500)
    
    var title = Label.new()
    title.text = "진행"
    title.position = Vector2(20, 20)
    panel.add_child(title)
    
    # 다음 전투 버튼
    var next_battle_btn = Button.new()
    next_battle_btn.text = "다음 전투로"
    next_battle_btn.position = Vector2(20, 60)
    next_battle_btn.size = Vector2(120, 40)
    next_battle_btn.pressed.connect(_on_next_battle_pressed)
    panel.add_child(next_battle_btn)
    
    # 저장 버튼
    var save_btn = Button.new()
    save_btn.text = "게임 저장"
    save_btn.position = Vector2(20, 110)
    save_btn.size = Vector2(120, 40)
    save_btn.pressed.connect(_on_save_pressed)
    panel.add_child(save_btn)
    
    return panel

func _on_next_battle_pressed():
    emit_signal("battle_preparation_requested")

func _on_save_pressed():
    GameManager.save_game()
    show_notification("게임이 저장되었습니다")
```

## 9.4. 유연한 캐릭터 배치 시스템

### 9.4.1. BattlePreparation 구현

```gdscript
# scripts/BattlePreparation.gd (신규 생성)
extends Control
class_name BattlePreparation

signal preparation_complete(selected_units: Array)

@onready var available_characters_list: ItemList
@onready var deployed_characters_list: ItemList
@onready var deployment_preview: Control

var available_characters: Array = []
var deployed_characters: Array = []
var max_deployment: int = 12  # 제한 해제

func _ready():
    setup_preparation_ui()

func setup_preparation_ui():
    # 사용 가능한 캐릭터 목록
    available_characters_list = ItemList.new()
    available_characters_list.position = Vector2(50, 50)
    available_characters_list.size = Vector2(300, 400)
    available_characters_list.item_activated.connect(_on_character_double_clicked)
    add_child(available_characters_list)
    
    # 배치된 캐릭터 목록
    deployed_characters_list = ItemList.new()
    deployed_characters_list.position = Vector2(400, 50)
    deployed_characters_list.size = Vector2(300, 400)
    deployed_characters_list.item_activated.connect(_on_deployed_character_double_clicked)
    add_child(deployed_characters_list)
    
    # 조작 버튼들
    create_control_buttons()
    
    # 배치 미리보기
    deployment_preview = Control.new()
    deployment_preview.position = Vector2(750, 50)
    deployment_preview.size = Vector2(300, 400)
    add_child(deployment_preview)

func create_control_buttons():
    var add_btn = Button.new()
    add_btn.text = "→ 추가"
    add_btn.position = Vector2(360, 150)
    add_btn.pressed.connect(_on_add_character)
    add_child(add_btn)
    
    var remove_btn = Button.new()
    remove_btn.text = "← 제거"
    remove_btn.position = Vector2(360, 200)
    remove_btn.pressed.connect(_on_remove_character)
    add_child(remove_btn)
    
    var start_btn = Button.new()
    start_btn.text = "전투 시작"
    start_btn.position = Vector2(360, 400)
    start_btn.size = Vector2(100, 50)
    start_btn.pressed.connect(_on_start_battle)
    add_child(start_btn)

func _on_character_double_clicked(index: int):
    if index < available_characters.size():
        add_character_to_deployment(available_characters[index])

func _on_deployed_character_double_clicked(index: int):
    if index < deployed_characters.size():
        remove_character_from_deployment(deployed_characters[index])

func add_character_to_deployment(character: Dictionary):
    if deployed_characters.size() < max_deployment:
        deployed_characters.append(character)
        refresh_lists()

func remove_character_from_deployment(character: Dictionary):
    deployed_characters.erase(character)
    refresh_lists()

func refresh_lists():
    # 사용 가능한 캐릭터 목록 갱신
    available_characters_list.clear()
    for character in available_characters:
        if character not in deployed_characters:
            available_characters_list.add_item(character["name"] + " (Lv." + str(character["level"]) + ")")
    
    # 배치된 캐릭터 목록 갱신
    deployed_characters_list.clear()
    for character in deployed_characters:
        deployed_characters_list.add_item(character["name"] + " (Lv." + str(character["level"]) + ")")

func _on_start_battle():
    if deployed_characters.size() > 0:
        emit_signal("preparation_complete", deployed_characters)
    else:
        show_notification("최소 1명 이상의 캐릭터를 배치해야 합니다")
```

## 9.5. 직관적인 스토리 에디터

### 9.5.1. StoryEditor 구현

```gdscript
# scripts/StoryEditor.gd (신규 생성)
extends Control
class_name StoryEditor

@onready var dialogue_tree: Tree
@onready var event_list: ItemList
@onready var preview_panel: Control

var current_story_data: Dictionary = {}

func _ready():
    setup_editor_ui()

func setup_editor_ui():
    # 대화 트리 뷰
    dialogue_tree = Tree.new()
    dialogue_tree.position = Vector2(20, 50)
    dialogue_tree.size = Vector2(400, 500)
    dialogue_tree.item_selected.connect(_on_dialogue_selected)
    add_child(dialogue_tree)
    
    # 이벤트 목록
    event_list = ItemList.new()
    event_list.position = Vector2(450, 50)
    event_list.size = Vector2(300, 500)
    add_child(event_list)
    
    # 편집 도구
    create_editing_tools()

func create_editing_tools():
    var add_dialogue_btn = Button.new()
    add_dialogue_btn.text = "대화 추가"
    add_dialogue_btn.position = Vector2(20, 570)
    add_dialogue_btn.pressed.connect(_on_add_dialogue)
    add_child(add_dialogue_btn)
    
    var add_event_btn = Button.new()
    add_event_btn.text = "이벤트 추가"
    add_event_btn.position = Vector2(450, 570)
    add_event_btn.pressed.connect(_on_add_event)
    add_child(add_event_btn)
    
    var save_btn = Button.new()
    save_btn.text = "스토리 저장"
    save_btn.position = Vector2(350, 620)
    save_btn.pressed.connect(_on_save_story)
    add_child(save_btn)

func _on_add_dialogue():
    var dialogue_dialog = DialogueEditDialog.new()
    dialogue_dialog.dialogue_created.connect(_on_dialogue_created)
    add_child(dialogue_dialog)

func _on_dialogue_created(dialogue_data: Dictionary):
    # 대화 트리에 추가
    var root = dialogue_tree.get_root()
    if not root:
        root = dialogue_tree.create_item()
        root.set_text(0, "스토리")
    
    var dialogue_item = dialogue_tree.create_item(root)
    dialogue_item.set_text(0, dialogue_data["speaker"] + ": " + dialogue_data["text"][:20] + "...")
    dialogue_item.set_metadata(0, dialogue_data)
```

## 9.6. 게임 플로우 관리

### 9.6.1. GameFlowManager 구현

```gdscript
# scripts/GameFlowManager.gd (신규 생성)
extends Node
class_name GameFlowManager

enum GameState {
    MAIN_MENU,
    INTERMISSION,
    BATTLE_PREPARATION,
    BATTLE,
    STORY_SEQUENCE,
    GAME_OVER
}

var current_state: GameState = GameState.MAIN_MENU
var current_chapter: int = 1
var story_progress: Dictionary = {}

func change_state(new_state: GameState):
    print("게임 상태 변경: ", GameState.keys()[current_state], " → ", GameState.keys()[new_state])
    current_state = new_state
    
    match new_state:
        GameState.INTERMISSION:
            show_intermission()
        GameState.BATTLE_PREPARATION:
            show_battle_preparation()
        GameState.BATTLE:
            start_battle()
        GameState.STORY_SEQUENCE:
            show_story_sequence()

func show_intermission():
    var intermission = IntermissionSystem.new()
    get_tree().current_scene.add_child(intermission)
    intermission.battle_preparation_requested.connect(func(): change_state(GameState.BATTLE_PREPARATION))

func show_battle_preparation():
    var preparation = BattlePreparation.new()
    get_tree().current_scene.add_child(preparation)
    preparation.preparation_complete.connect(_on_preparation_complete)

func _on_preparation_complete(selected_units: Array):
    GameManager.set_player_units(selected_units)
    change_state(GameState.BATTLE)

func start_battle():
    get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")

func complete_chapter():
    current_chapter += 1
    change_state(GameState.STORY_SEQUENCE)
```

## 9.7. 시스템 장점 요약

### 9.7.1. 개발 효율성
- ✅ **빠른 구현**: 복잡한 기능 제거로 개발 시간 단축
- ✅ **낮은 버그 위험**: 단순한 시스템으로 안정성 향상
- ✅ **쉬운 유지보수**: 직관적인 코드 구조

### 9.7.2. 사용자 경험
- ✅ **직관적 조작**: 캐릭터 선택과 배치가 간단명료
- ✅ **빠른 게임 진행**: 불필요한 선택지나 복잡한 메뉴 없음
- ✅ **안정적 경험**: 단순한 시스템으로 오류 발생 최소화

### 9.7.3. 완전한 통합 시스템 구성

**전체 개발 워크플로우**
```
맵 에디터 시스템 ← → 시나리오 시스템
        ↓                    ↓
1. 랜덤 맵 생성           1. 스토리 에디터에서 대화 생성
2. 마음에 드는 맵 저장    2. 이벤트 시퀀스 편집
3. 세밀한 편집으로 완성   3. 챕터별 스토리 연결
4. 맵 라이브러리 구축     4. 게임 플로우 완성
        ↓                    ↓
        통합된 게임 경험
```

이제 **핵심 기능에 집중한 실용적인 시나리오 시스템**으로 효율적이고 안정적인 게임 개발이 가능합니다! 🎮✨ 