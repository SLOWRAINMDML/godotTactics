# 🎮 Godot 개발 규칙 및 가이드라인

## 📋 목표

이 문서는 Godot 4.4 엔진을 사용한 전술 SRPG 프로젝트의 일관성 있고 효율적인 개발을 위한 규칙과 가이드라인을 제시합니다.

---

## 🗂️ 프로젝트 구조 규칙

### 1. **폴더 구조 원칙**

```
프로젝트_루트/
├── scenes/          # 씬 파일들 (.tscn + .gd)
│   ├── ui/         # UI 관련 씬
│   ├── battle/     # 전투 관련 씬
│   └── menu/       # 메뉴 관련 씬
├── scripts/         # 순수 로직 스크립트들
│   ├── managers/   # 싱글톤 매니저들
│   ├── data/       # 데이터 클래스들
│   └── utils/      # 유틸리티 함수들
├── assets/          # 리소스 파일들
│   ├── sprites/    # 스프라이트 이미지
│   ├── audio/      # 사운드 파일
│   └── fonts/      # 폰트 파일
├── resources/       # Godot 리소스 파일들 (.tres, .res)
└── addons/          # 플러그인 및 확장
```

### 2. **파일 명명 규칙**

```
# 씬 파일
BattleScene.tscn / BattleScene.gd
MainMenu.tscn / MainMenu.gd
CharacterInfoUI.tscn / CharacterInfoUI.gd

# 스크립트 파일
Character.gd          # 클래스명과 동일
GameManager.gd        # 싱글톤은 Manager 접미사
GameData.gd          # 데이터는 Data 접미사
BattleUtils.gd       # 유틸리티는 Utils 접미사

# 리소스 파일
knight_idle.png      # 소문자 + 언더스코어
fireball_effect.tres # 소문자 + 언더스코어
```

---

## 💻 GDScript 코딩 규칙

### 1. **클래스 및 변수 명명**

```gdscript
# 클래스명: PascalCase
class_name BattleManager
class_name CharacterData

# 변수명: snake_case
var character_name: String
var max_health: int
var is_player_controlled: bool

# 상수: SCREAMING_SNAKE_CASE
const MAX_LEVEL: int = 99
const DEFAULT_MOVE_RANGE: int = 3

# 신호: snake_case
signal character_selected(character)
signal battle_ended(victory)

# 함수명: snake_case
func calculate_damage(attacker: Character, defender: Character) -> int:
func get_valid_move_positions() -> Array[Vector2i]:
```

### 2. **타입 힌트 의무화**

```gdscript
# ✅ 올바른 예시
var character_list: Array[Character] = []
var grid_position: Vector2i = Vector2i.ZERO
var terrain_data: Dictionary = {}

func move_character(character: Character, target_pos: Vector2i) -> bool:
    return true

# ❌ 잘못된 예시 (타입 힌트 없음)
var character_list = []
var grid_position = Vector2i.ZERO

func move_character(character, target_pos):
    return true
```

### 3. **주석 작성 규칙**

```gdscript
# 함수 상단에 목적과 매개변수 설명
## 캐릭터를 지정된 위치로 이동시킵니다.
## @param character: 이동시킬 캐릭터
## @param target_pos: 목표 그리드 위치
## @return: 이동 성공 여부
func move_character(character: Character, target_pos: Vector2i) -> bool:
    # 이동 가능성 검증
    if not is_valid_position(target_pos):
        print("유효하지 않은 위치: ", target_pos)
        return false

    # TODO: 이동 애니메이션 추가 필요
    character.grid_position = target_pos
    return true
```

### 4. **오류 처리 규칙**

```gdscript
# 조기 반환 패턴 사용
func attack_target(attacker: Character, target: Character) -> bool:
    # 조건 검증
    if not attacker:
        push_error("공격자가 null입니다")
        return false

    if not target:
        push_error("대상이 null입니다")
        return false

    if attacker.current_health <= 0:
        print("죽은 캐릭터는 공격할 수 없습니다")
        return false

    # 실제 로직 실행
    var damage = calculate_damage(attacker, target)
    target.take_damage(damage)
    return true
```

---

## 🔧 아키텍처 규칙

### 1. **싱글톤 사용 지침**

```gdscript
# 전역 상태 관리만 싱글톤으로 사용
# - GameManager: 게임 상태 및 턴 관리
# - GameData: 정적 데이터 저장
# - AudioManager: 사운드 관리 (추후 추가)
# - SaveManager: 저장/불러오기 (추후 추가)

# ✅ 적절한 싱글톤 사용
GameManager.start_battle(player_chars, enemy_chars)
var class_data = GameData.CLASSES["Knight"]

# ❌ 부적절한 싱글톤 사용 (개별 캐릭터 데이터)
CharacterManager.elena.take_damage(10)  # 이렇게 하지 말 것
```

### 2. **신호(Signal) 사용 규칙**

```gdscript
# 신호는 느슨한 결합을 위해서만 사용
# 직접적인 참조가 가능한 경우 함수 호출 우선

# ✅ 올바른 신호 사용 (계층 간 통신)
signal character_died(character)
signal tile_clicked(grid_pos, terrain_name)
signal battle_ended(victory)

# 신호 연결은 _ready()에서
func _ready():
    character.character_died.connect(_on_character_died)
    battle_grid.tile_clicked.connect(_on_tile_clicked)

# ❌ 부적절한 신호 사용 (같은 클래스 내부)
signal _internal_calculation_done()  # 내부 처리에는 신호 사용 금지
```

### 3. **의존성 관리**

```gdscript
# 의존성 주입 패턴 사용
class_name BattleController

var battle_grid: BattleGrid
var game_manager: GameManager

# 생성자에서 의존성 주입
func _init(grid: BattleGrid, manager: GameManager):
    battle_grid = grid
    game_manager = manager

# ❌ 하드코딩된 의존성
func attack():
    GameManager.calculate_damage()  # 직접 참조 금지
    get_node("/root/BattleGrid")    # 절대 경로 금지
```

---

## 🎨 UI 개발 규칙

### 1. **UI 구조 및 명명**

```gdscript
# UI 노드 명명 규칙
CharacterInfoPanel/
├── NameLabel          # 역할 + 타입
├── HealthBar
├── StatsContainer/
│   ├── StrLabel
│   ├── DefLabel
│   └── AgiLabel
└── ActionButtons/
    ├── MoveButton
    ├── AttackButton
    └── SkillButton
```

### 2. **UI 업데이트 패턴**

```gdscript
# UI 업데이트는 전용 함수로 분리
func update_character_info(character: Character):
    if not character:
        hide_character_info()
        return

    name_label.text = character.character_name
    health_bar.value = character.current_health
    health_bar.max_value = character.max_health

    # 스탯 업데이트
    str_label.text = "STR: %d" % character.current_stats["STR"]
    def_label.text = "DEF: %d" % character.current_stats["DEF"]

# 데이터 변경 시 즉시 UI 업데이트
func _on_character_selected(character: Character):
    selected_character = character
    update_character_info(character)
    update_action_buttons(character)
```

---

## ⚡ 성능 최적화 규칙

### 1. **프레임당 처리량 제한**

```gdscript
# 매 프레임 실행되는 _process()에서 무거운 작업 금지
func _process(delta):
    # ✅ 가벼운 작업만
    handle_input()
    update_camera_position(delta)

    # ❌ 무거운 작업 금지
    # generate_entire_map()        # 맵 전체 생성 금지
    # calculate_all_pathfinding()  # 전체 경로 계산 금지

# 무거운 작업은 필요할 때만 호출
func _on_character_selected(character: Character):
    calculate_move_range(character)  # 선택 시에만 계산
```

### 2. **메모리 관리**

```gdscript
# 노드 생성 시 적절한 해제 보장
func create_highlight_tile(position: Vector2i) -> ColorRect:
    var highlight = ColorRect.new()
    highlight.color = Color.GREEN
    add_child(highlight)

    # 참조 저장으로 나중에 해제 가능
    highlighted_tiles[position] = highlight
    return highlight

func clear_highlights():
    for pos in highlighted_tiles:
        highlighted_tiles[pos].queue_free()
    highlighted_tiles.clear()
```

### 3. **리소스 로딩 최적화**

```gdscript
# 리소스는 미리 로드하여 캐싱
var preloaded_sprites: Dictionary = {}

func _ready():
    # 게임 시작 시 필요한 리소스 미리 로드
    preloaded_sprites["knight"] = preload("res://assets/sprites/knight.png")
    preloaded_sprites["mage"] = preload("res://assets/sprites/mage.png")

# ❌ 매번 로드하는 패턴 금지
func update_character_sprite(character: Character):
    # var sprite = load("res://assets/sprites/" + character.class_name + ".png")  # 금지
    var sprite = preloaded_sprites[character.class_name.to_lower()]  # 권장
```

---

## 🐛 디버깅 및 테스트 규칙

### 1. **로깅 규칙**

```gdscript
# 로그 레벨 구분
func move_character(character: Character, target_pos: Vector2i) -> bool:
    print_rich("[color=blue][INFO][/color] 캐릭터 이동 시도: %s -> %s" % [character.character_name, target_pos])

    if not is_valid_position(target_pos):
        print_rich("[color=orange][WARN][/color] 유효하지 않은 위치: %s" % target_pos)
        return false

    if has_obstacle(target_pos):
        print_rich("[color=red][ERROR][/color] 장애물 존재: %s" % target_pos)
        return false

    print_rich("[color=green][SUCCESS][/color] 이동 완료: %s" % character.character_name)
    return true
```

### 2. **디버그 모드 구분**

```gdscript
# 디버그 전용 코드는 조건부로 실행
const DEBUG_MODE: bool = true

func _ready():
    if DEBUG_MODE:
        create_debug_ui()
        show_grid_coordinates()
        enable_dev_commands()

func _input(event):
    if DEBUG_MODE and event is InputEventKey:
        if event.keycode == KEY_F1 and event.pressed:
            toggle_debug_info()
        elif event.keycode == KEY_F2 and event.pressed:
            generate_test_scenario()
```

### 3. **예외 상황 대비**

```gdscript
# 모든 배열 접근 시 범위 확인
func get_character_at_position(pos: Vector2i) -> Character:
    if pos.x < 0 or pos.x >= grid_width or pos.y < 0 or pos.y >= grid_height:
        return null

    for character in all_characters:
        if character.grid_position == pos:
            return character

    return null

# null 체크 필수
func select_character(character: Character):
    if not character:
        print("선택할 캐릭터가 없습니다")
        return

    if not character.is_player_controlled:
        print("적 캐릭터는 선택할 수 없습니다")
        return

    # 정상 처리 로직
    selected_character = character
    update_ui()
```

---

## 📦 버전 관리 규칙

### 1. **Git 커밋 메시지**

```
feat: 새로운 기능 추가
fix: 버그 수정
refactor: 코드 리팩토링
style: 코드 스타일 변경
docs: 문서 수정
test: 테스트 추가/수정
chore: 기타 작업

예시:
feat: 캐릭터 클래스 체인지 시스템 구현
fix: 타일 클릭 좌표 변환 오류 수정
refactor: GameManager 싱글톤 구조 개선
```

### 2. **브랜치 전략**

```
main         # 안정된 릴리즈 버전
develop      # 개발 중인 기능들 통합
feature/*    # 새로운 기능 개발
hotfix/*     # 긴급 버그 수정
release/*    # 릴리즈 준비
```

### 3. **Godot 특화 .gitignore**

```gitignore
# Godot 파일들
.godot/
.import/
export.cfg
export_presets.cfg

# 빌드 결과물
*.tmp
*.exe
*.pck
*.zip

# OS 파일들
.DS_Store
Thumbs.db
```

---

## 🚀 배포 및 빌드 규칙

### 1. **빌드 전 체크리스트**

```
□ 모든 씬이 정상 로드되는지 확인
□ 콘솔에 에러 메시지가 없는지 확인
□ 모든 리소스가 올바르게 연결되었는지 확인
□ 메모리 누수가 없는지 확인
□ 다양한 해상도에서 UI가 정상 작동하는지 확인
```

### 2. **최적화 설정**

```gdscript
# project.godot 권장 설정
[application]
config/name="Tactics SRPG"
run/main_scene="res://scenes/MainMenu.tscn"

[rendering]
renderer/rendering_method="mobile"  # 2D 게임 권장
textures/canvas_textures/default_texture_filter=0  # 픽셀아트용

[physics]
common/enable_pause_aware_picking=true
```

---

## 📚 학습 및 참고 자료

### 1. **필수 Godot 문서**
- [GDScript 스타일 가이드](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [신호(Signal) 사용법](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- [씬 구조 설계](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scene_organization.html)

### 2. **프로젝트 참고 패턴**
- 싱글톤 패턴: GameManager, GameData
- 옵저버 패턴: Signal 기반 이벤트 처리
- 컴포넌트 패턴: Character 클래스 구조
- MVC 패턴: UI와 로직 분리

---

## ⚠️ 금지 사항

### 1. **절대 하지 말 것**
```gdscript
# ❌ 하드코딩된 경로
get_node("/root/Main/BattleScene/Character1")

# ❌ 전역 변수 남용
var global_selected_character  # 싱글톤 없이 전역 변수 금지

# ❌ 매직 넘버
if character.level > 50:  # 50이 무엇을 의미하는지 불명확

# ❌ 긴 함수 (50줄 이상)
func god_function():  # 모든 것을 처리하는 거대 함수 금지
```

### 2. **성능 파괴 패턴**
```gdscript
# ❌ 무한 루프 위험
while true:
    process_something()  # 탈출 조건 없는 무한 루프

# ❌ 매 프레임 리소스 로드
func _process(delta):
    var texture = load("res://sprite.png")  # 금지

# ❌ 불필요한 노드 생성
for i in range(1000):
    var node = Node2D.new()  # 대량 생성 시 성능 저하
```

---

## 🎓 Godot 엔진 기초 문법 학습 안내 (후임자를 위하여)

이 프로젝트를 처음 접하거나 Godot 엔진이 익숙하지 않은 분들을 위해, 핵심 개념과 학습 자료를 안내합니다.

### 1. **GDScript: 파이썬처럼 쉬운 언어**

Godot의 주요 스크립트 언어인 GDScript는 Python과 매우 유사하여 배우기 쉽습니다. 아래의 기본 문법만 익혀도 프로젝트 코드를 이해하는 데 큰 도움이 됩니다.

- **변수 선언**: `var my_variable = 10`
- **타입 힌트**: `var health: int = 100` (이 프로젝트에서는 타입 힌트를 **필수**로 사용합니다.)
- **함수 선언**: `func my_function(param1: String, param2: int) -> bool:`
- **조건문**: `if`, `elif`, `else` (Python과 동일)
- **반복문**: `for i in range(10):`, `while condition:` (Python과 동일)
- **주석**: `#` 한 줄 주석, `##` 문서 주석

> 📚 **추천 학습 자료**: [GDScript 기초 공식 튜토리얼](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html)

### 2. **노드(Node)와 씬(Scene): 레고 블록처럼 조립하기**

Godot는 '노드'라는 작은 기능 단위들을 조립하여 '씬'을 만드는 방식으로 게임을 개발합니다.

- **노드(Node)**: 게임의 가장 작은 부품입니다. (예: `Sprite2D`는 이미지를, `Label`은 텍스트를, `Button`은 버튼을 표시)
- **씬(Scene)**: 노드들을 나무처럼 계층 구조(Parent-Child)로 조립한 것입니다. 캐릭터 하나, 총알 하나, UI 창 하나가 각각 하나의 씬이 될 수 있습니다.
- **씬 트리(Scene Tree)**: 현재 게임에서 실행 중인 씬과 노드들의 전체 구조를 의미합니다.

> 📚 **추천 학습 자료**: [씬과 노드 공식 튜토리얼](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scenes_and_nodes.html)

### 3. **시그널(Signal): "일이 벌어졌어요!" 라고 알리기**

시그널은 한 노드가 다른 노드에게 특정 이벤트가 발생했음을 알리는 '방송' 시스템입니다. 이를 통해 코드 간의 직접적인 의존성을 줄여 유연한 구조를 만들 수 있습니다.

- **작동 방식**:
  1. **송신자(Emitter)**: 버튼이 눌리거나(`pressed`), 캐릭터가 죽으면(`character_died`) 시그널을 `emit`(발생)합니다.
  2. **수신자(Receiver)**: 다른 노드의 함수를 이 시그널에 `connect`(연결)해 둡니다.
  3. **결과**: 시그널이 발생하면, 연결된 모든 함수들이 자동으로 실행됩니다.

- **우리 프로젝트의 예시**:
  - `BattleGrid.gd`가 타일 클릭 시 `tile_clicked` 시그널을 발생시킵니다.
  - `BattleScene.gd`는 `_on_tile_clicked` 함수를 이 시그널에 연결해 두었다가, 신호를 받으면 타일 클릭에 대한 처리를 합니다.

> 📚 **추천 학습 자료**: [시그널(Signal) 공식 튜토리얼](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)

### 4. **싱글톤(Autoload): 어디서든 접근 가능한 전역 관리자**

`GameManager.gd`와 `GameData.gd`는 싱글톤으로 등록되어 있습니다. 이는 프로젝트 어디에서든 `GameManager.next_turn()` 처럼 직접 접근하여 사용할 수 있는 전역 객체입니다.

- **용도**: 게임의 전체 상태, 공용 데이터, 저장/불러오기 등 여러 씬에 걸쳐 공유되어야 하는 기능을 관리하는 데 사용됩니다.
- **확인 방법**: Godot 에디터의 `프로젝트 > 프로젝트 설정 > Autoload` 탭에서 등록된 싱글톤 목록을 확인할 수 있습니다.

---

이 규칙들을 따라 개발하면 일관성 있고 유지보수하기 쉬운 Godot 프로젝트를 만들 수 있습니다! 🎮
