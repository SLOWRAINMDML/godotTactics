# ⚙️ 기술 설계 및 아키텍처

## 4.1. 프로젝트 파일 구조
```
tactics/
├── scenes/              # 게임 씬 관련 파일 (.tscn, .gd)
│   ├── BattleGrid.gd    # 게임 맵 그리드 시스템
│   ├── BattleScene.gd   # 메인 전투 컨트롤러
│   └── BattleScene.tscn # 전투 씬 레이아웃
├── scripts/             # 게임 로직 스크립트
│   ├── Character.gd     # 캐릭터 클래스 시스템
│   ├── ClassChangeDialog.gd  # 클래스 체인지 UI 로직
│   ├── GameData.gd      # 게임 데이터 저장소 (싱글톤)
│   ├── GameManager.gd   # 게임 상태 관리자 (싱글톤)
│   ├── LocalizationManager.gd  # 다국어 지원 관리자 (싱글톤)
│   ├── TranslationService.gd   # AI 번역 서비스
│   ├── WorldSimulator.gd      # 외부 전장 시뮬레이션 (싱글톤)
│   ├── BattleBarrier.gd       # 결계 시스템 관리
│   └── IntelligenceSystem.gd  # 정보 수집/신선도 관리
├── translations/        # 다국어 번역 파일
│   ├── ui_text.csv      # UI 텍스트 번역
│   ├── skill_data.csv   # 스킬 이름/설명 번역
│   ├── story_dialogue.csv # 스토리 대화 번역
│   └── gemma3_cache/    # AI 번역 캐시 데이터
├── fonts/               # 다국어 폰트 파일
│   ├── korean_font.ttf  # 한글 폰트
│   ├── japanese_font.ttf # 일본어 폰트
│   └── chinese_font.ttf # 중국어 폰트
├── resources/           # Godot 리소스 (.tres, .res)
├── assets/              # 이미지, 오디오, 폰트 등 원본 에셋
└── project.godot        # Godot 프로젝트 설정 파일
```

## 4.2. 주요 클래스 설명

-   **`GameManager.gd` (싱글톤)**
    -   **역할**: 게임의 전체 상태(전투 중, 메뉴 등)와 턴 흐름을 관리하는 중앙 관리자.
    -   **주요 기능**: 전투 시작/종료 처리, `DEX` 기반 턴 순서 계산, 다음 턴으로 진행(`advance_turn`), 데미지 계산 로직 제공.
-   **`GameData.gd` (싱글톤)**
    -   **역할**: 게임의 모든 정적 데이터(클래스, 스킬, 지형 정보 등)를 보관하는 데이터베이스.
    -   **주요 기능**: 코드와 데이터를 분리하여 밸런스 조정이 용이하게 함. 환경 상호작용 규칙 정의.
-   **`BattleScene.gd`**
    -   **역할**: `BattleScene.tscn`에 대한 메인 스크립트로, 실제 전투의 모든 시각적 요소와 사용자 입력을 처리.
    -   **주요 기능**: 캐릭터 생성 및 배치, UI 업데이트(정보창, 버튼), 타일 클릭 및 캐릭터 행동에 대한 결과 처리, 카메라 제어.
-   **`BattleGrid.gd`**
    -   **역할**: 이소메트릭 맵 그리드의 생성과 관리를 담당.
    -   **주요 기능**: 맵 데이터 생성, 화면 좌표<->그리드 좌표 변환, 이동/공격 범위 계산 및 시각적 하이라이트 표시.
-   **`Character.gd`**
    -   **역할**: 게임 내 모든 유닛(아군/적군)의 데이터와 개별 행동을 정의하는 클래스.
    -   **주요 기능**: 스탯 관리, 레벨업 처리, 데미지 수신, 상태(이동 완료, 행동 완료 등) 추적.
-   **`WorldSimulator.gd` (싱글톤)**
    -   **역할**: 플레이어 전투와 병행하여 외부 전장의 상황 변화를 시뮬레이션하는 시스템.
    -   **주요 기능**: 외부 이벤트 타이밍 관리, 정보 신선도 계산, 전투 종료 후 결과 적용.
-   **`BattleBarrier.gd`**  
    -   **역할**: 주인공의 결계 능력을 관리하고 전투 영역을 제한하는 시스템.
    -   **주요 기능**: 결계 크기 선택 UI, MP 소모 계산, 참여 유닛 필터링, 결계 영역 시각화.
-   **`IntelligenceSystem.gd`**
    -   **역할**: 정찰로 획득한 정보의 품질과 유효성을 관리하는 시스템.
    -   **주요 기능**: 정보 수집, 시간 경과에 따른 신뢰도 감소, 정보 기반 전투 보정 계산.

## 4.3. 데이터 구조 예시
게임의 주요 데이터는 `GameData.gd` 내에 딕셔너리 형태로 구조화됩니다.

-   **클래스 데이터 예시**:
    ```gdscript
    "Knight": {
        "required_level": 5,
        "weapons": ["Sword", "Lance", "Shield"],
        "learnable_skills": ["Slash", "Guard", "Charge", "Holy_Strike"],
        "stat_bonus": {"STR": 2, "DEF": 3, "AGI": -1},  # 클래스 착용 시 보너스
        "unlock_condition": "Soldier 레벨 5+ 달성"
    }
    ```
-   **캐릭터 데이터 예시**:
    ```gdscript
    "Elena": {
        "current_class": "Knight", 
        "level": 12,
        "stats": {"STR": 18, "DEF": 14, "AGI": 8, "DEX": 10, "INT": 6, "RES": 9},
        "growth_rates": {"STR": 85, "DEF": 70, "AGI": 45, "DEX": 60, "INT": 30, "RES": 50},
        "learned_skills": ["Slash", "Guard", "Charge", "Heal", "Fire_Magic"],
        "fusion_skills": ["Flame_Sword"],
        "class_history": ["Soldier", "Cleric", "Knight"],
        "skill_experience": {"Slash": 45, "Heal": 23, "Flame_Sword": 8}
    }
    ```
-   **스킬 데이터 예시**:
    ```gdscript
    "Fireball": {
        "type": "Magic", 
        "element": "Fire", 
        "base_power": 22,
        "primary_stat": "INT",
        "secondary_stat": "DEX",
        "range": 3, 
        "mp_cost": 8,
        "effect": "CreateBurningGround",
        "damage_formula": "base_power + (INT * 1.5) + (DEX * 0.3)"
    }
    ``` 