# 🎮 Godot 개발 규칙 및 가이드라인 (Godot 4.5 / 3D Isometric SRPG)

## 📋 목표

이 문서는 **Godot 4.5** 엔진을 사용한 **3D 아이소메트릭(Isometric) 전술 SRPG** 프로젝트의 일관성 있고 효율적인 개발을 위한 규칙과 가이드라인을 제시합니다.

---

## 🗂️ 프로젝트 구조 규칙

### 1. **폴더 구조 원칙**

3D 프로젝트의 특성을 반영하여 에셋과 씬 구조를 세분화합니다.

```
프로젝트_루트/
├── scenes/          # 씬 파일들 (.tscn + .gd)
│   ├── ui/         # UI 관련 씬 (HUD, 메뉴 등)
│   ├── maps/       # 전투 맵 및 레벨 씬 (GridMap 포함)
│   ├── units/      # 3D 유닛/캐릭터 씬
│   ├── objects/    # 상호작용 가능한 3D 오브젝트 (상자, 함정 등)
│   └── vfx/        # 시각 효과 (파티클 등)
├── scripts/         # 순수 로직 스크립트들
│   ├── managers/   # 싱글톤 매니저들 (GameManager, TurnManager)
│   ├── data/       # 데이터 클래스들 (Stats, Skills, Items)
│   └── utils/      # 유틸리티 함수들 (Math, Grid, Pathfinding)
├── assets/          # 리소스 파일들
│   ├── models/     # 3D 모델 파일 (.gltf, .glb, .obj)
│   │   ├── characters/
│   │   └── environment/
│   ├── materials/  # 재질 파일 (.tres)
│   ├── textures/   # 텍스처 이미지
│   ├── audio/      # 사운드 파일
│   └── shaders/    # 셰이더 파일 (.gdshader)
├── resources/       # Godot 커스텀 리소스 (.tres, .res)
└── addons/          # 플러그인 및 확장
```

### 2. **파일 명명 규칙**

```
# 씬 파일
BattleMap01.tscn / BattleMap01.gd
HeroUnit.tscn / HeroUnit.gd
Cursor3D.tscn / Cursor3D.gd

# 스크립트 파일  
UnitController.gd     # 클래스명과 동일
TurnManager.gd        # 싱글톤은 Manager 접미사
ItemData.gd           # 데이터는 Data 접미사
GridUtils.gd          # 유틸리티는 Utils 접미사

# 리소스 파일
floor_tile_mat.tres   # 소문자 + 언더스코어
hero_texture_diff.png # 용도 명시 (diffuse, normal, orm 등)
sword_slash.wav
```

---

## 💻 GDScript 코딩 규칙 (3D 대응)

### 1. **클래스 및 변수 명명**

```gdscript
# 클래스명: PascalCase
class_name UnitController extends CharacterBody3D

# 변수명: snake_case
var grid_position: Vector3i  # 3D 그리드 좌표 (x, y, z)
var world_position: Vector3  # 실제 월드 좌표
var movement_speed: float

# 상수: SCREAMING_SNAKE_CASE
const TILE_SIZE: float = 2.0
const GRAVITY: float = 9.8
const MAX_HEIGHT_DIFF: int = 2

# 신호: snake_case
signal unit_moved(unit, from_pos, to_pos)
signal turn_ended(unit)
```

### 2. **타입 힌트 의무화**

Godot 4.x의 성능 이점과 안정성을 위해 3D 타입 힌트를 적극 사용합니다.

```gdscript
# ✅ 올바른 예시
var target_unit: Node3D
var path_points: Array[Vector3] = []
var material_override: StandardMaterial3D
var grid_map: GridMap

func move_to(target_pos: Vector3) -> void:
    pass

# ❌ 잘못된 예시 (타입 힌트 없음)
var target_unit
var path_points = []
func move_to(target_pos):
    pass
```

### 3. **주석 작성 규칙**

```gdscript
## 유닛을 지정된 그리드 좌표로 이동시킵니다.
## @param unit: 이동시킬 유닛 (UnitController)
## @param target_grid_pos: 목표 그리드 좌표 (Vector3i)
## @return: 이동 성공 여부
func move_unit(unit: UnitController, target_grid_pos: Vector3i) -> bool:
    # 이동 가능성 검증
    if not is_valid_position(target_grid_pos):
        push_warning("유효하지 않은 위치: %s" % target_grid_pos)
        return false
    
    # TODO: 점프 또는 사다리 타기 애니메이션 처리 필요
    unit.grid_position = target_grid_pos
    return true
```

---

## 🔧 아키텍처 규칙 (3D Isometric)

### 1. **GridMap 활용**

*   **지형(Terrain)**: `GridMap` 노드를 사용하여 최적화된 3D 타일맵을 구성합니다.
*   **MeshLibrary**: 타일셋은 `MeshLibrary`로 관리하며, 각 타일 아이템은 충돌체(StaticBody3D)와 네비게이션 메쉬(NavigationRegion3D)를 포함해야 합니다.
*   **레이어 관리**: 바닥, 벽, 장식물, 고저차 등을 관리하기 위해 Y축 레이어를 활용하거나 별도의 GridMap을 사용합니다.

### 2. **카메라 설정 (Isometric View)**

*   **Projection**: `Orthogonal` (직교 투영)을 사용하여 원근감을 제거, 정확한 아이소메트릭 뷰를 구현합니다.
*   **Angle**: X축 회전 약 -30도, Y축 회전 45도 (일반적인 아이소메트릭 각도).
*   **Zoom**: 카메라의 `Size` 속성을 조절하여 줌 인/아웃을 구현합니다.

```gdscript
# Camera3D 설정 예시
func setup_isometric_camera():
    projection = Camera3D.PROJECTION_ORTHOGONAL
    rotation_degrees = Vector3(-30, 45, 0)
    size = 10.0 # 줌 레벨 (낮을수록 확대)
```

### 3. **좌표 변환 (Grid <-> World)**

```gdscript
# GridUtils.gd
static func grid_to_world(grid_pos: Vector3i) -> Vector3:
    return Vector3(
        grid_pos.x * TILE_SIZE,
        grid_pos.y * (TILE_SIZE * 0.5), # 높이 보정 (슬랩 등)
        grid_pos.z * TILE_SIZE
    )

static func world_to_grid(world_pos: Vector3) -> Vector3i:
    return Vector3i(
        round(world_pos.x / TILE_SIZE),
        round(world_pos.y / (TILE_SIZE * 0.5)),
        round(world_pos.z / TILE_SIZE)
    )
```

### 4. **입력 처리 (RayCast)**

*   마우스 클릭 시 3D 공간의 타일을 선택하기 위해 `PhysicsRayQueryParameters3D` 또는 `RayCast3D`를 사용합니다.
*   카메라에서 마우스 커서 위치로 레이를 발사하여 `GridMap` 또는 `Unit`과의 충돌 지점을 찾습니다.

---

## ⚡ 성능 최적화 규칙 (3D)

### 1. **렌더링 최적화**

*   **MultiMeshInstance3D**: 숲, 잔디, 바위 등 동일한 메쉬가 다수 반복되는 경우 반드시 `MultiMeshInstance3D`를 사용하여 드로우 콜(Draw Call)을 줄입니다.
*   **Occlusion Culling**: 복잡한 던전이나 실내 맵에서는 가려진 오브젝트를 렌더링하지 않도록 오클루전 컬링을 설정합니다.
*   **LOD (Level of Detail)**: Godot 4.x의 자동 LOD 생성 기능을 활용하여 카메라 거리에 따라 모델 디테일을 조절합니다.

### 2. **물리 및 충돌**

*   **Collision Shape**: 복잡한 `TrimeshCollision` 대신 단순한 `BoxShape3D`, `SphereShape3D`, `CapsuleShape3D`를 우선 사용합니다.
*   **Layer & Mask**: 충돌 레이어와 마스크를 철저히 구분합니다.
    *   Layer 1: 지형 (Terrain)
    *   Layer 2: 유닛 (Unit)
    *   Layer 3: 상호작용 오브젝트 (Interactable)
    *   Layer 4: 시야/센서 (Vision)

### 3. **조명 및 섀도우**

*   **Lightmap**: 정적인 지형(GridMap)에는 `LightmapGI`를 베이크하여 런타임 조명 연산을 최소화합니다.
*   **Shadows**: 모바일 타겟인 경우 실시간 그림자(DirectionalLight3D)의 해상도와 거리를 제한하고, 가능하다면 Blob Shadow(단순 텍스처 그림자)를 사용합니다.

---

## 🐛 디버깅 및 테스트 규칙

### 1. **3D 시각적 디버깅**

*   **DebugDraw**: 이동 경로, 공격 범위, 시야 등을 시각화하기 위해 `ImmediateMesh`나 별도의 디버그용 노드를 사용합니다.
*   **Visible Collision Shapes**: 디버그 메뉴에서 'Visible Collision Shapes'를 켜서 물리 충돌체가 의도대로 설정되었는지 확인합니다.

```gdscript
# 이동 경로 디버그 그리기 예시
func draw_debug_path(points: Array[Vector3]):
    if not OS.is_debug_build(): return
    # ... ImmediateMesh 등을 사용하여 선 그리기 구현
```

### 2. **로깅 규칙**

```gdscript
func move_unit(unit: UnitController, target_pos: Vector3i) -> bool:
    print_rich("[color=blue][INFO][/color] 유닛 이동 시도: %s -> %s" % [unit.name, target_pos])
    
    if not is_valid_position(target_pos):
        print_rich("[color=orange][WARN][/color] 유효하지 않은 위치: %s" % target_pos)
        return false
        
    return true
```

---

## 📦 버전 관리 규칙

### 1. **Git 커밋 메시지**

```
feat: 3D 카메라 줌 기능 구현
fix: 유닛 이동 시 높이 계산 오류 수정
refactor: GridMap 관리 로직 개선
assets: 기사(Knight) 3D 모델 및 애니메이션 추가
docs: 개발 가이드라인 업데이트
```

### 2. **Godot 특화 .gitignore**

```gitignore
# Godot 4.x
.godot/
*.translation
export.cfg
export_presets.cfg

# Mono/C# (사용 시)
.mono/
*.csproj
*.sln

# Import cache
*.import

# OS generated
.DS_Store
Thumbs.db
```

---

## ⚠️ 금지 사항

### 1. **절대 하지 말 것**

```gdscript
# ❌ 하드코딩된 경로
get_node("/root/Main/BattleMap/Unit1")

# ❌ 매 프레임 리소스 로드
func _process(delta):
    var mat = load("res://materials/grass.tres") # 절대 금지

# ❌ 복잡한 물리 연산 남용
# 수백 개의 유닛이 매 프레임 물리 충돌을 체크하지 않도록 주의
```

### 2. **성능 파괴 패턴**

*   **과도한 조명**: 씬에 너무 많은 실시간 옴니 라이트(OmniLight3D)를 배치하지 마십시오. (Forward+ 렌더러라도 비용이 큼)
*   **고해상도 텍스처 남용**: 4K 텍스처는 꼭 필요한 경우(주요 캐릭터 등)에만 사용하고, 배경은 적절히 압축하십시오.
*   **유니크 메쉬 남발**: 가능한 한 메쉬와 재질을 재사용(Instancing)하십시오.

---

이 규칙들을 준수하여 Godot 4.5 기반의 고품질 3D SRPG를 완성해 봅시다! 🚀