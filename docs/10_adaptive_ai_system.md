# 🤖 플레이어 패턴 분석 및 적응형 AI 시스템

## 10.1. 시스템 개요

플레이어의 전투 패턴을 상세히 기록하고 **로컬 서버 연동**을 통해 플레이어의 전략을 분석, 모사하거나 카운터하는 적응형 AI 시스템을 구축합니다. (LLM 통합 부분은 별도 구현 예정)

### 10.1.1. 핵심 목표
- **플레이어 행동 패턴 수집**: 스킬 사용, 이동 패턴, 지형 활용 등 모든 전투 행동 기록
- **패턴 분석**: 로컬 서버를 통한 플레이어 전략 분석 및 특성 파악 (별도 구현 예정)
- **적응형 AI**: 플레이어 패턴을 모사하거나 카운터하는 AI 전략 생성
- **개인화된 도전**: 각 플레이어에게 맞춤형 AI 도전 제공

## 10.2. 전투 로그 수집 시스템

### 10.2.1. 상세 전투 로그 매니저

```gdscript
# scripts/BattleAnalytics.gd (신규 생성)
extends Node
class_name BattleAnalytics

signal pattern_analysis_complete(analysis_data: Dictionary)

const ANALYTICS_DIR = "user://battle_analytics/"
const SESSION_LOG_FILE = "user://battle_analytics/current_session.json"

var current_battle_log: Dictionary = {}
var player_stats: Dictionary = {}
var terrain_usage_patterns: Dictionary = {}

func _ready():
    ensure_analytics_directory()
    initialize_battle_log()

func initialize_battle_log():
    current_battle_log = {
        "session_id": generate_session_id(),
        "stage_id": "",
        "player_id": get_player_identifier(),
        "battle_start_time": Time.get_datetime_string_from_system(),
        "battle_end_time": "",
        "victory": false,
        "turn_count": 0,
        "actions": [],
        "movement_patterns": [],
        "skill_usage": {},
        "terrain_interactions": [],
        "positioning_analysis": {
            "aggressive_moves": 0,
            "defensive_moves": 0,
            "flanking_attempts": 0,
            "retreat_count": 0
        },
        "tactical_preferences": {
            "preferred_range": "unknown",
            "skill_priority": [],
            "terrain_preference": [],
            "risk_tolerance": "medium"
        }
    }

func log_player_action(action_data: Dictionary):
    var detailed_action = {
        "turn": GameManager.current_turn,
        "timestamp": Time.get_unix_time_from_system(),
        "action_type": action_data["type"],
        "character_id": action_data["character_id"],
        "position_before": action_data["position_before"],
        "position_after": action_data.get("position_after", action_data["position_before"]),
        "target_position": action_data.get("target_position", Vector2i(-1, -1)),
        "skill_used": action_data.get("skill_id", ""),
        "damage_dealt": action_data.get("damage", 0),
        "distance_to_target": action_data.get("distance", 0),
        "terrain_from": get_terrain_type(action_data["position_before"]),
        "terrain_to": get_terrain_type(action_data.get("position_after", action_data["position_before"])),
        "height_advantage": action_data.get("height_advantage", false),
        "cover_utilized": action_data.get("cover_used", false)
    }
    
    current_battle_log["actions"].append(detailed_action)
    analyze_action_pattern(detailed_action)

func analyze_movement_pattern(action: Dictionary):
    var movement_data = {
        "turn": action["turn"],
        "from": action["position_before"],
        "to": action["position_after"],
        "distance": action["position_before"].distance_to(action["position_after"]),
        "direction": get_movement_direction(action["position_before"], action["position_after"]),
        "tactical_intent": determine_tactical_intent(action)
    }
    
    current_battle_log["movement_patterns"].append(movement_data)
```

## 10.3. 로컬 서버 연동 시스템 (별도 구현 예정)

### 10.3.1. 패턴 분석 인터페이스

```gdscript
# scripts/PatternAnalysisInterface.gd (신규 생성)
extends Node
class_name PatternAnalysisInterface

signal analysis_complete(analysis_result: Dictionary)
signal strategy_generated(strategy_data: Dictionary)

# 로컬 서버 연동 관련 설정 (별도 구현 예정)
const LOCAL_SERVER_ENDPOINT = "http://localhost:8080/analyze"

var http_request: HTTPRequest
var current_analysis_request: Dictionary = {}

func _ready():
    setup_http_request()

func setup_http_request():
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_analysis_response_received)

# 플레이어 패턴 분석 요청 (로컬 서버 연동 - 별도 구현 예정)
func analyze_player_patterns(battle_logs: Array):
    print("패턴 분석을 위한 로컬 서버 연동 준비 중... (별도 구현 예정)")
    
    # 임시 분석 결과 (실제로는 로컬 서버에서 처리)
    var mock_analysis = {
        "player_type": "aggressive_tactician",
        "preferred_strategy": "frontal_assault",
        "weak_points": ["poor_positioning", "resource_management"],
        "counter_strategies": ["defensive_formation", "resource_pressure"]
    }
    
    emit_signal("analysis_complete", mock_analysis)

func _on_analysis_response_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
    print("로컬 서버로부터 분석 결과 수신 (별도 구현 예정)")
```

## 10.4. 적응형 AI 매니저

### 10.4.1. AdaptiveAIManager 구현

```gdscript
# scripts/AdaptiveAIManager.gd (신규 생성)
extends Node
class_name AdaptiveAIManager

var player_analysis_data: Dictionary = {}
var ai_strategies: Dictionary = {}
var battle_analytics: BattleAnalytics

func _ready():
    battle_analytics = BattleAnalytics.new()
    add_child(battle_analytics)
    
    # 패턴 분석 인터페이스 연결 (별도 구현 예정)
    var pattern_interface = PatternAnalysisInterface.new()
    add_child(pattern_interface)
    pattern_interface.analysis_complete.connect(_on_analysis_complete)

func apply_adaptive_strategy(enemy_units: Array):
    if player_analysis_data.has("player_type"):
        var player_type = player_analysis_data["player_type"]
        
        match player_type:
            "aggressive_tactician":
                apply_defensive_counter_strategy(enemy_units)
            "defensive_player":
                apply_aggressive_pressure_strategy(enemy_units)
            "terrain_specialist":
                apply_mobility_focused_strategy(enemy_units)
            _:
                apply_balanced_strategy(enemy_units)

func apply_defensive_counter_strategy(enemy_units: Array):
    for unit in enemy_units:
        # 방어적 전술 적용
        unit.ai_behavior = "defensive_formation"
        unit.preferred_actions = ["guard", "defensive_skills", "wait"]
        unit.positioning_priority = "high_ground_defensive"

func apply_aggressive_pressure_strategy(enemy_units: Array):
    for unit in enemy_units:
        # 공격적 압박 전술 적용
        unit.ai_behavior = "aggressive_pressure"
        unit.preferred_actions = ["advance", "attack", "flanking"]
        unit.positioning_priority = "offensive_positioning"

func _on_analysis_complete(analysis_data: Dictionary):
    player_analysis_data = analysis_data
    print("플레이어 분석 완료: ", analysis_data["player_type"])
```

## 10.5. 패턴 시각화 도구 (개발자용)

### 10.5.1. PatternViewer 구현

```gdscript
# scripts/PatternViewer.gd (신규 생성)
extends Control
class_name PatternViewer

@onready var pattern_chart: Control
@onready var data_table: ItemList
@onready var export_button: Button

func _ready():
    setup_viewer_ui()

func setup_viewer_ui():
    # 패턴 차트
    pattern_chart = Control.new()
    pattern_chart.size = Vector2(600, 400)
    pattern_chart.position = Vector2(20, 20)
    add_child(pattern_chart)
    
    # 데이터 테이블
    data_table = ItemList.new()
    data_table.size = Vector2(300, 400)
    data_table.position = Vector2(650, 20)
    add_child(data_table)
    
    # 내보내기 버튼
    export_button = Button.new()
    export_button.text = "데이터 내보내기"
    export_button.position = Vector2(20, 450)
    export_button.pressed.connect(_on_export_pressed)
    add_child(export_button)

func load_pattern_data(analytics_data: Dictionary):
    # 패턴 데이터 로드 및 시각화
    display_movement_patterns(analytics_data.get("movement_patterns", []))
    display_skill_usage(analytics_data.get("skill_usage", {}))
    display_terrain_preferences(analytics_data.get("terrain_interactions", []))

func _on_export_pressed():
    # CSV 형태로 패턴 데이터 내보내기
    var csv_data = generate_csv_report()
    save_csv_file(csv_data)
```

## 10.6. 시스템 통합 및 활용

### 10.6.1. 게임 플로우 통합

```gdscript
# BattleScene.gd에 추가할 통합 코드
extends Node2D

@onready var adaptive_ai_manager: AdaptiveAIManager

func _ready():
    # 적응형 AI 매니저 초기화
    adaptive_ai_manager = AdaptiveAIManager.new()
    add_child(adaptive_ai_manager)
    
    # 전투 시작 시 최근 패턴 기반으로 AI 조정
    adjust_ai_based_on_patterns()

func adjust_ai_based_on_patterns():
    # 최근 5게임의 로그 분석
    var recent_logs = load_recent_battle_logs(5)
    if recent_logs.size() >= 3:  # 충분한 데이터가 있을 때만
        adaptive_ai_manager.analyze_and_adapt(recent_logs)

func on_battle_complete():
    # 전투 완료 시 로그 저장
    adaptive_ai_manager.battle_analytics.save_battle_log()
    
    # 패턴 분석 요청 (로컬 서버 연동 - 별도 구현 예정)
    adaptive_ai_manager.request_pattern_analysis()
```

## 10.7. 시스템 효과 및 기대 결과

### 10.7.1. 개인화된 AI 도전
- **학습형 적**: 플레이어의 패턴을 파악하여 점점 더 도전적인 상대로 성장
- **약점 공략**: 플레이어가 자주 사용하지 않는 전술이나 지형 활용 강요
- **다양성 증진**: 항상 같은 전략으로는 승리할 수 없게 만들어 전술적 사고 촉진

### 10.7.2. 데이터 기반 게임 밸런싱
- **실제 플레이 데이터**: 이론적 밸런스가 아닌 실제 플레이어 행동 기반 조정
- **플레이어들이 선호하는 맵/전략 파악**: 인기 있는 콘텐츠와 외면받는 콘텐츠 식별
- **신규 콘텐츠 설계**: 패턴 분석을 통한 새로운 맵, 스킬, 클래스 설계 방향 제시

**이제 플레이어마다 다른 맞춤형 AI 경험을 제공하는 혁신적인 시스템이 완성됩니다!** 🤖✨

*참고: LLM 통합 관련 기능은 로컬 서버 연동으로 별도 구현 예정입니다.* 