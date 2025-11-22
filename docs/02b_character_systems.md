# 👥 캐릭터 및 클래스 시스템

## 2.3. 캐릭터 성장 시스템

### 2.3.1. 개인별 성장률 시스템
각 캐릭터는 고유한 성장률을 가지며, 이는 캐릭터의 특성과 잠재력을 결정합니다:

```gdscript
"Elena": {
    "growth_rates": {
        "STR": 85,  # 매우 높음 - 물리 공격에 특화
        "DEF": 70,  # 높음 - 방어력도 우수
        "AGI": 45,  # 보통 - 평균적인 기민함
        "DEX": 60,  # 높음 - 명중률과 회피 준수
        "INT": 30,  # 낮음 - 마법에 취약
        "RES": 50   # 보통 - 마법 저항력 평균
    }
}
```

- **성장률 의미**: 레벨업 시 해당 스탯이 상승할 확률 (%)
- **캐릭터별 특화**: 각 캐릭터마다 다른 성장 경향으로 개성 부여
- **전략적 육성**: 높은 성장률 스탯을 활용하는 클래스로 육성하는 것이 효율적

### 2.3.2. 클래스 시스템
캐릭터는 다양한 클래스로 전직할 수 있으며, 각 클래스는 고유한 특성을 제공합니다:

**기본 클래스:**
- **Soldier (병사)**: 시작 클래스, 균형잡힌 능력치
- **Archer (궁수)**: 원거리 공격 특화, DEX 요구
- **Mage (마법사)**: 마법 공격 특화, INT 요구
- **Cleric (성직자)**: 회복 및 보조 특화, INT/RES 요구

**고급 클래스:**
- **Knight (기사)**: STR/DEF 특화, Soldier Lv.5+ 필요
- **Ranger (레인저)**: DEX/AGI 특화, Archer Lv.5+ 필요
- **Wizard (마법사)**: INT 극특화, Mage Lv.8+ 필요

### 2.3.3. 스킬 습득 및 융합 시스템

#### 기본 스킬 습득
각 클래스에서 레벨업을 통해 새로운 스킬을 습득합니다:

```gdscript
"Knight": {
    "learnable_skills": [
        {"skill": "Slash", "level": 1},
        {"skill": "Guard", "level": 3},
        {"skill": "Charge", "level": 6},
        {"skill": "Holy_Strike", "level": 10}
    ]
}
```

#### 스킬 융합 시스템
서로 다른 클래스의 스킬을 조합하여 강력한 융합 스킬을 생성할 수 있습니다:

**융합 예시: Flame_Sword**
- **필요 스킬**: Slash (물리) + Fire_Magic (마법)
- **최소 레벨**: 8레벨 이상
- **효과**: 물리 공격에 화염 속성 추가
- **특별 효과**: 합성 장소와 캐릭터 스탯에 따라 성능 변화

**장소별 융합 보너스:**
- **대장간**: 물리 융합 스킬의 위력 증가
- **마법사 탑**: 마법 융합 스킬의 MP 소모 감소
- **신전**: 회복/보조 융합 스킬의 효과 범위 증가

## 2.4. 외부 전장 시뮬레이션 시스템

### 2.4.1. WorldSimulator 클래스
플레이어의 전투와 동시에 다른 전장에서 벌어지는 상황을 시뮬레이션합니다:

```gdscript
# scripts/WorldSimulator.gd
extends Node

var external_battles: Array = []
var world_events: Array = []
var time_multiplier: float = 1.0

func simulate_external_battle():
    for battle in external_battles:
        # 매 턴마다 외부 전투 진행
        battle["current_turn"] += 1
        
        # 전투 결과 시뮬레이션
        var result = calculate_battle_outcome(battle)
        if result["is_complete"]:
            process_battle_completion(battle, result)

func calculate_battle_outcome(battle: Dictionary) -> Dictionary:
    # 아군/적군 전력, 지형, 전술 등을 고려한 확률적 계산
    var ally_power = battle["ally_strength"]
    var enemy_power = battle["enemy_strength"]
    var terrain_modifier = battle["terrain_advantage"]
    
    # 시간이 지날수록 전투 격화
    var intensity = min(battle["current_turn"] / 10.0, 1.0)
    
    return {
        "is_complete": battle["current_turn"] >= battle["estimated_duration"],
        "victor": "ally" if ally_power > enemy_power else "enemy",
        "casualties": calculate_casualties(ally_power, enemy_power, intensity)
    }
```

### 2.4.2. 정보 수집 및 신선도 시스템

#### IntelligenceSystem 클래스
정찰을 통해 얻은 정보의 정확성과 유효성을 관리합니다:

```gdscript
# scripts/IntelligenceSystem.gd
extends Node

var intelligence_reports: Array = []
var information_freshness: Dictionary = {}

func collect_intelligence(target_area: String, scout_quality: int) -> Dictionary:
    var report = {
        "area": target_area,
        "timestamp": Time.get_unix_time_from_system(),
        "quality": scout_quality,  # 1-10 스케일
        "reliability": calculate_reliability(scout_quality),
        "data": generate_intelligence_data(target_area, scout_quality)
    }
    
    intelligence_reports.append(report)
    information_freshness[target_area] = report["timestamp"]
    
    return report

func get_information_accuracy(area: String) -> float:
    if not information_freshness.has(area):
        return 0.0  # 정보 없음
    
    var time_elapsed = Time.get_unix_time_from_system() - information_freshness[area]
    var freshness = max(0.0, 1.0 - (time_elapsed / 3600.0))  # 1시간마다 10% 감소
    
    return freshness

func apply_intelligence_bonus(battle_calculation: Dictionary, area: String) -> Dictionary:
    var accuracy = get_information_accuracy(area)
    
    if accuracy > 0.7:  # 신선한 정보
        battle_calculation["player_advantage"] += 0.2
        battle_calculation["critical_chance"] += 0.1
    elif accuracy > 0.3:  # 오래된 정보
        battle_calculation["player_advantage"] += 0.1
    # 정보가 너무 오래되면 보너스 없음
    
    return battle_calculation
```

### 2.4.3. 결계 시스템

#### BattleBarrier 클래스
주인공의 특수 능력으로 전투 영역을 제한하는 결계를 생성합니다:

```gdscript
# scripts/BattleBarrier.gd
extends Node

enum BarrierSize {
    SMALL,   # 10x10, MP 50
    MEDIUM,  # 15x15, MP 100
    LARGE    # 20x20, MP 150
}

var current_barrier: Dictionary = {}
var barrier_active: bool = false

func create_barrier(size: BarrierSize, center_position: Vector2i) -> bool:
    var mp_cost = get_barrier_mp_cost(size)
    
    if GameManager.player_mp >= mp_cost:
        GameManager.player_mp -= mp_cost
        
        current_barrier = {
            "size": size,
            "center": center_position,
            "radius": get_barrier_radius(size),
            "duration": -1,  # 무제한 (전투 종료까지)
            "effects": ["limit_participants", "prevent_reinforcements"]
        }
        
        barrier_active = true
        apply_barrier_effects()
        return true
    
    return false

func get_barrier_mp_cost(size: BarrierSize) -> int:
    match size:
        BarrierSize.SMALL: return 50
        BarrierSize.MEDIUM: return 100
        BarrierSize.LARGE: return 150
        _: return 50

func is_within_barrier(position: Vector2i) -> bool:
    if not barrier_active:
        return true
    
    var distance = current_barrier["center"].distance_to(position)
    return distance <= current_barrier["radius"]

func filter_units_by_barrier(all_units: Array) -> Array:
    if not barrier_active:
        return all_units
    
    var filtered_units = []
    for unit in all_units:
        if is_within_barrier(unit.position):
            filtered_units.append(unit)
    
    return filtered_units
```

## 2.5. 상태 이상 및 환경 상호작용

### 2.5.1. 상태 이상 시스템
다양한 상태 이상이 전투에 전략적 깊이를 더합니다:

**물리적 상태 이상:**
- **독 (Poison)**: 턴마다 HP 감소
- **마비 (Paralysis)**: 액션 포인트 -2
- **출혈 (Bleeding)**: 이동 시 추가 데미지
- **둔화 (Slow)**: 이동력 반감

**마법적 상태 이상:**
- **침묵 (Silence)**: 마법 스킬 사용 불가
- **마나 번 (Mana Burn)**: 턴마다 MP 감소
- **혼란 (Confusion)**: 랜덤한 대상 공격
- **석화 (Petrification)**: 완전히 행동 불가

### 2.5.2. 환경 상호작용
지형과 날씨가 전투에 실질적인 영향을 미칩니다:

**지형 효과:**
- **늪지**: 이동 비용 +1, 화염 스킬 위력 -20%
- **화산 지대**: 화염 스킬 위력 +30%, 얼음 스킬 위력 -50%
- **얼음 동굴**: 얼음 스킬 위력 +30%, 화염 스킬 위력 -30%
- **신성한 땅**: 회복 스킬 효과 +50%, 어둠 스킬 위력 -30%

**날씨 효과:**
- **폭우**: 화염 스킬 위력 -30%, 번개 스킬 위력 +20%
- **눈보라**: 이동력 -1, 시야 범위 감소
- **강풍**: 원거리 공격 명중률 -20%
- **안개**: 모든 공격 명중률 -15%, 은신 효과 증가

이러한 시스템들이 결합되어 **매번 다른 전투 경험**과 **깊이 있는 전략적 사고**를 제공합니다! 🎯✨ 