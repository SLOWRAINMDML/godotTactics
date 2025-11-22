# 🗺️ 맵 에디터 및 스테이지 제작 시스템

## 8.1. 랜덤 맵 생성 및 저장 시스템

### 8.1.1. 맵 데이터 구조
현재 `BattleGrid.gd`의 랜덤 생성 시스템을 확장하여 저장 가능한 형태로 구조화:

```json
{
    "metadata": {
        "stage_id": "stage_001",
        "name": "산악 요새 공방전",
        "description": "험준한 산악 지형에서 벌어지는 요새 탈환 작전",
        "author": "System_Generated",
        "creation_date": "2024-12-29",
        "difficulty": "Normal",
        "estimated_turns": 25,
        "player_spawn_area": {"x": 15, "y": 20, "width": 8, "height": 6},
        "enemy_spawn_area": {"x": 5, "y": 5, "width": 10, "height": 8}
    },
    "victory_conditions": [
        {"type": "eliminate_all_enemies", "required": true},
        {"type": "survive_turns", "turns": 30, "required": false},
        {"type": "protect_unit", "unit_id": "commander", "required": false}
    ],
    "defeat_conditions": [
        {"type": "all_players_defeated", "required": true},
        {"type": "key_unit_death", "unit_id": "commander", "required": false},
        {"type": "turn_limit", "turns": 50, "required": false}
    ],
    "terrain_data": {
        "width": 30,
        "height": 25,
        "default_height": 0,
        "tiles": [
            {"x": 0, "y": 0, "type": "Mountain", "height": 3, "state": "Normal"},
            {"x": 1, "y": 0, "type": "Mountain", "height": 2, "state": "Normal"}
        ]
    },
    "environment": {
        "weather": "Clear",
        "time_of_day": "Day",
        "special_effects": ["HighAltitude", "WindyTerrain"],
        "music_theme": "mountain_battle"
    },
    "enemy_units": [
        {
            "id": "enemy_captain",
            "type": "Elite_Knight",
            "level": 12,
            "position": {"x": 8, "y": 6},
            "equipment": {"weapon": "Silver_Sword", "armor": "Chain_Mail"},
            "ai_behavior": "defensive_leader",
            "special_traits": ["Commander", "Morale_Boost"]
        }
    ],
    "interactive_objects": [
        {
            "id": "supply_chest",
            "type": "Treasure_Chest",
            "position": {"x": 15, "y": 12},
            "contents": ["Health_Potion", "Mana_Potion", "Silver_Coin_50"],
            "activation": "player_proximity"
        }
    ],
    "event_triggers": [
        {
            "id": "reinforcement_wave",
            "trigger": {"type": "turn_number", "turn": 10},
            "action": {"type": "spawn_enemies", "units": ["goblin_squad"], "position": {"x": 2, "y": 2}},
            "description": "10턴에 고블린 정찰대 증원 출현"
        }
    ]
}
```

### 8.1.2. 맵 저장 시스템 구현

```gdscript
# scripts/MapManager.gd (신규 생성)
extends Node
class_name MapManager

signal map_saved(map_path: String)
signal map_loaded(map_data: Dictionary)

const CUSTOM_MAPS_DIR = "user://custom_maps/"
const SYSTEM_MAPS_DIR = "res://maps/system_stages/"

# 현재 랜덤 생성된 맵을 JSON 파일로 저장
func save_current_map(battle_grid: BattleGrid, metadata: Dictionary) -> String:
    var map_data = {}
    
    # 메타데이터 설정
    map_data["metadata"] = {
        "stage_id": generate_stage_id(),
        "name": metadata.get("name", "커스텀 스테이지"),
        "description": metadata.get("description", "플레이어가 생성한 스테이지"),
        "author": metadata.get("author", "Player"),
        "creation_date": Time.get_datetime_string_from_system(),
        "difficulty": metadata.get("difficulty", "Normal"),
        "estimated_turns": metadata.get("estimated_turns", 20)
    }
    
    # 지형 데이터 추출
    map_data["terrain_data"] = extract_terrain_data(battle_grid)
    
    # 파일로 저장
    var file_path = CUSTOM_MAPS_DIR + map_data["metadata"]["stage_id"] + ".json"
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(map_data, "\t"))
        file.close()
        emit_signal("map_saved", file_path)
        return file_path
    else:
        push_error("맵 저장 실패: " + file_path)
        return ""

# BattleGrid에서 지형 정보 추출
func extract_terrain_data(battle_grid: BattleGrid) -> Dictionary:
    var terrain_data = {
        "width": battle_grid.GRID_WIDTH,
        "height": battle_grid.GRID_HEIGHT,
        "default_height": 0,
        "tiles": []
    }
    
    for x in range(battle_grid.GRID_WIDTH):
        for y in range(battle_grid.GRID_HEIGHT):
            if battle_grid.terrain_grid.has(Vector2i(x, y)):
                var tile = battle_grid.terrain_grid[Vector2i(x, y)]
                terrain_data["tiles"].append({
                    "x": x,
                    "y": y,
                    "type": tile["type"],
                    "height": tile["height"],
                    "state": tile.get("state", "Normal")
                })
    
    return terrain_data

# 저장된 맵 불러오기
func load_map(file_path: String) -> Dictionary:
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var parse_result = json.parse(json_string)
        if parse_result == OK:
            var map_data = json.data
            emit_signal("map_loaded", map_data)
            return map_data
        else:
            push_error("JSON 파싱 오류: " + str(parse_result))
    
    return {}

func generate_stage_id() -> String:
    return "custom_" + str(Time.get_unix_time_from_system())
```

## 8.2. 랜덤 맵 즉시 저장 기능

### 8.2.1. BattleScene에 저장 버튼 추가

```gdscript
# BattleScene.gd에 추가할 기능
extends Node2D

@onready var map_manager = MapManager.new()
@onready var save_map_button = Button.new()

func _ready():
    setup_map_save_ui()
    add_child(map_manager)

func setup_map_save_ui():
    save_map_button.text = "이 맵 저장하기"
    save_map_button.size = Vector2(120, 40)
    save_map_button.position = Vector2(10, 10)
    save_map_button.pressed.connect(_on_save_map_pressed)
    add_child(save_map_button)

func _on_save_map_pressed():
    var metadata_dialog = MapMetadataDialog.new()
    metadata_dialog.metadata_confirmed.connect(_on_metadata_confirmed)
    add_child(metadata_dialog)
    metadata_dialog.show()

func _on_metadata_confirmed(metadata: Dictionary):
    var saved_path = map_manager.save_current_map(battle_grid, metadata)
    if saved_path != "":
        show_notification("맵이 저장되었습니다: " + metadata["name"])
```

### 8.2.2. 맵 정보 입력 다이얼로그

```gdscript
# scripts/MapMetadataDialog.gd (신규 생성)
extends AcceptDialog
class_name MapMetadataDialog

signal metadata_confirmed(metadata: Dictionary)

@onready var name_edit: LineEdit
@onready var description_edit: TextEdit
@onready var difficulty_option: OptionButton
@onready var author_edit: LineEdit

func _ready():
    title = "맵 정보 입력"
    setup_ui()

func setup_ui():
    var vbox = VBoxContainer.new()
    
    # 맵 이름
    vbox.add_child(Label.new())
    vbox.get_child(-1).text = "맵 이름:"
    name_edit = LineEdit.new()
    name_edit.placeholder_text = "예: 산악 요새 공방전"
    vbox.add_child(name_edit)
    
    # 맵 설명
    vbox.add_child(Label.new())
    vbox.get_child(-1).text = "맵 설명:"
    description_edit = TextEdit.new()
    description_edit.placeholder_text = "예: 험준한 산악 지형에서 벌어지는..."
    description_edit.custom_minimum_size = Vector2(300, 100)
    vbox.add_child(description_edit)
    
    # 난이도
    vbox.add_child(Label.new())
    vbox.get_child(-1).text = "난이도:"
    difficulty_option = OptionButton.new()
    difficulty_option.add_item("Easy")
    difficulty_option.add_item("Normal")
    difficulty_option.add_item("Hard")
    difficulty_option.selected = 1
    vbox.add_child(difficulty_option)
    
    # 작성자
    vbox.add_child(Label.new())
    vbox.get_child(-1).text = "작성자:"
    author_edit = LineEdit.new()
    author_edit.text = "Player"
    vbox.add_child(author_edit)
    
    add_child(vbox)
    
    confirmed.connect(_on_confirmed)

func _on_confirmed():
    var metadata = {
        "name": name_edit.text if name_edit.text != "" else "무제",
        "description": description_edit.text,
        "difficulty": difficulty_option.get_item_text(difficulty_option.selected),
        "author": author_edit.text
    }
    
    emit_signal("metadata_confirmed", metadata)
    queue_free()
```

## 8.3. 통합 맵 에디터 시스템

### 8.3.1. 맵 에디터 메인 화면

```gdscript
# scenes/MapEditor.gd (신규 생성)
extends Control
class_name MapEditor

signal map_editing_complete(map_data: Dictionary)

@onready var battle_grid: BattleGrid
@onready var toolbar: HBoxContainer
@onready var file_panel: VBoxContainer
@onready var preview_panel: Panel

enum EditMode {
    TERRAIN,
    HEIGHT,
    OBJECTS,
    UNITS
}

var current_edit_mode: EditMode = EditMode.TERRAIN
var selected_terrain_type: String = "Plain"
var selected_height: int = 0
var current_map_data: Dictionary = {}

func _ready():
    setup_editor_ui()
    load_available_maps()

func setup_editor_ui():
    # 도구모음 생성
    create_toolbar()
    
    # 파일 패널 생성
    create_file_panel()
    
    # 미리보기 패널 생성
    create_preview_panel()
    
    # 배틀 그리드 설정
    setup_battle_grid()

func create_toolbar():
    toolbar = HBoxContainer.new()
    
    # 편집 모드 버튼들
    var terrain_btn = Button.new()
    terrain_btn.text = "지형 편집"
    terrain_btn.pressed.connect(func(): set_edit_mode(EditMode.TERRAIN))
    toolbar.add_child(terrain_btn)
    
    var height_btn = Button.new()
    height_btn.text = "높이 편집"
    height_btn.pressed.connect(func(): set_edit_mode(EditMode.HEIGHT))
    toolbar.add_child(height_btn)
    
    # 지형 타입 선택
    var terrain_option = OptionButton.new()
    for terrain_type in ["Plain", "Mountain", "Forest", "Swamp", "Desert", "Volcano", "River"]:
        terrain_option.add_item(terrain_type)
    terrain_option.item_selected.connect(_on_terrain_type_selected)
    toolbar.add_child(terrain_option)
    
    add_child(toolbar)

func set_edit_mode(mode: EditMode):
    current_edit_mode = mode
    update_toolbar_state()

func _on_terrain_type_selected(index: int):
    var terrain_types = ["Plain", "Mountain", "Forest", "Swamp", "Desert", "Volcano", "River"]
    selected_terrain_type = terrain_types[index]
```

## 8.4. 시나리오 연결 시스템

### 8.4.1. ScenarioManager 클래스

```gdscript
# scripts/ScenarioManager.gd (신규 생성)
extends Node
class_name ScenarioManager

const SCENARIOS_DIR = "user://scenarios/"

var scenarios: Dictionary = {}
var current_scenario_id: String = ""
var current_chapter: int = 0

func load_scenario(scenario_id: String) -> bool:
    var file_path = SCENARIOS_DIR + scenario_id + ".json"
    var file = FileAccess.open(file_path, FileAccess.READ)
    
    if file:
        var json_string = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var parse_result = json.parse(json_string)
        if parse_result == OK:
            scenarios[scenario_id] = json.data
            current_scenario_id = scenario_id
            return true
    
    return false

func get_chapter_map(chapter: int) -> String:
    if scenarios.has(current_scenario_id):
        var scenario = scenarios[current_scenario_id]
        if scenario.has("chapters") and chapter < scenario["chapters"].size():
            return scenario["chapters"][chapter]["map_id"]
    
    return ""

func progress_to_next_chapter():
    current_chapter += 1
    var next_map = get_chapter_map(current_chapter)
    if next_map != "":
        GameManager.load_stage(next_map)
        return true
    else:
        # 시나리오 완료
        return false
```

## 8.5. 맵 검증 시스템

### 8.5.1. 플레이 가능성 검증

```gdscript
# scripts/MapValidator.gd (신규 생성)
extends RefCounted
class_name MapValidator

static func validate_map(map_data: Dictionary) -> Dictionary:
    var validation_result = {
        "is_valid": true,
        "warnings": [],
        "errors": []
    }
    
    # 기본 구조 검증
    if not map_data.has("terrain_data"):
        validation_result["errors"].append("지형 데이터가 없습니다")
        validation_result["is_valid"] = false
    
    # 플레이어 스폰 지역 검증
    if not validate_spawn_areas(map_data):
        validation_result["errors"].append("플레이어 스폰 지역이 유효하지 않습니다")
        validation_result["is_valid"] = false
    
    # 경로 검증
    if not validate_pathfinding(map_data):
        validation_result["warnings"].append("일부 지역이 도달 불가능할 수 있습니다")
    
    # 밸런스 검증
    var balance_issues = validate_balance(map_data)
    validation_result["warnings"].extend(balance_issues)
    
    return validation_result

static func validate_spawn_areas(map_data: Dictionary) -> bool:
    var metadata = map_data.get("metadata", {})
    var terrain_data = map_data.get("terrain_data", {})
    
    # 스폰 지역이 실제 맵 범위 내에 있는지 확인
    if metadata.has("player_spawn_area"):
        var spawn_area = metadata["player_spawn_area"]
        if spawn_area["x"] < 0 or spawn_area["y"] < 0:
            return false
        if spawn_area["x"] + spawn_area["width"] > terrain_data["width"]:
            return false
        if spawn_area["y"] + spawn_area["height"] > terrain_data["height"]:
            return false
    
    return true

static func validate_pathfinding(map_data: Dictionary) -> bool:
    # 간단한 연결성 검증 (실제로는 A* 알고리즘 등을 사용)
    return true  # 구현 예정

static func validate_balance(map_data: Dictionary) -> Array:
    var warnings = []
    
    # 지형 다양성 검증
    var terrain_types = {}
    for tile in map_data["terrain_data"]["tiles"]:
        var terrain_type = tile["type"]
        terrain_types[terrain_type] = terrain_types.get(terrain_type, 0) + 1
    
    if terrain_types.size() < 3:
        warnings.append("지형이 단조로울 수 있습니다 (3종류 이상 권장)")
    
    return warnings
```

이제 **완전한 맵 제작 파이프라인**이 구축되어 효율적인 콘텐츠 제작이 가능합니다! 🗺️✨ 