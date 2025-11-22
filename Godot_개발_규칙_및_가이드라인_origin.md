# 🎮 Godot 개발 규칙 및 가이드라인 (Godot 4.5 / 3D Isometric SRPG)

## 📋 목표

이 문서는 **Godot 4.5** 엔진을 사용한 **3D 아이소메트릭(Isometric) 전술 SRPG** 프로젝트의 일관성 있고 효율적인 개발을 위한 규칙과 가이드라인을 제시합니다.

---

## 🗂️ 프로젝트 구조 규칙

### 1. **폴더 구조 원칙**

3D 프로젝트에 맞춰 에셋 및 씬 구조를 세분화합니다.

```
프로젝트_루트/
├── scenes/          # 씬 파일들 (.tscn + .gd)
│   ├── ui/         # UI 관련 씬 (2D)
│   ├── maps/       # 전투 맵 씬 (GridMap 포함)
│   ├── units/      # 3D 유닛/캐릭터 씬
│   └── objects/    # 상호작용 가능한 3D 오브젝트
├── scripts/         # 순수 로직 스크립트들
│   ├── managers/   # 싱글톤 매니저들
│   ├── data/       # 데이터 클래스들 (Stats, Skills 등)
│   └── utils/      # 유틸리티 함수들 (Math, Grid 등)
├── assets/          # 리소스 파일들
│   ├── models/     # 3D 모델 파일 (.gltf, .glb, .obj)
│   ├── materials/  # 재질 파일 (.tres)
│   ├── textures/   # 텍스처 이미지
│   ├── audio/      # 사운드 파일
│   └── shaders/    # 셰이더 파일 (.gdshader)
├── resources/       # Godot 커스텀 리소스 (.tres)
└── addons/          # 플러그인 및 확장
```

### 2. **파일 명명 규칙**

```
# 씬 파일
BattleMap01.tscn
HeroUnit.tscn
Cursor3D.tscn

# 스크립트 파일  
UnitController.gd     # 클래스명과 동일
TurnManager.gd        # 싱글톤은 Manager 접미사
ItemData.gd           # 데이터는 Data 접미사
GridUtils.gd          # 유틸리티는 Utils 접미사

# 리소스 파일
floor_tile_mat.tres   # 소문자 + 언더스코어
hero_texture_diff.png # 용도 명시 (diffuse, normal 등)
```

---

## 💻 GDScript 코딩 규칙 (3D 대응)

### 1. **클래스 및 변수 명명**

```gdscript
class_name UnitController extends CharacterBody3D

# 3D 좌표계 사용
var grid_position: Vector3i  # 그리드 좌표는 정수형 3D 벡터 사용 (y는 높이)
var world_position: Vector3  # 실제 월드 좌표

# 상수
const TILE_SIZE: float = 2.0
const GRAVITY: float = 9.8
```

### 2. **타입 힌트 의무화**

3D 관련 타입 힌트를 적극 사용합니다.

```gdscript
# ✅ 올바른 예시
var target_unit: Node3D
var path_points: Array[Vector3] = []
var material_override: StandardMaterial3D

func move_to(target_pos: Vector3) -> void:
    pass

# ❌ 잘못된 예시
var target_unit
var path_points = []
```

### 3. **3D 이동 및 좌표 변환**

아이소메트릭 그리드와 월드 좌표 간의 변환 로직을 명확히 합니다.

```gdscript
## 그리드 좌표를 월드 좌표로 변환합니다.
## @param grid_pos: 그리드 좌표 (Vector3i)
## @return: 월드 좌표 (Vector3)
func grid_to_world(grid_pos: Vector3i) -> Vector3:
    return Vector3(
        grid_pos.x * TILE_SIZE,
        grid_pos.y * (TILE_SIZE * 0.5), # 높이 보정 (필요 시)
        grid_pos.z * TILE_SIZE
    )
```

---

## 🔧 아키텍처 규칙 (3D Isometric)

### 1. **GridMap 활용**

*   **지형(Terrain)**: `GridMap` 노드를 사용하여 맵을 구성합니다.
*   **MeshLibrary**: 타일셋은 `MeshLibrary`로 관리하며, 각 타일의 충돌체(Collision)와 네비게이션 메쉬(Navigation Mesh)를 포함해야 합니다.
*   **레이어**: 바닥, 벽, 장식물 등을 별도의 GridMap 레이어 또는 Y축 높이로 구분하여 관리합니다.

### 2. **카메라 설정 (Isometric View)**

*   **Projection**: `Orthogonal` (직교 투영) 사용. 원근감을 제거하여 정확한 아이소메트릭 뷰 구현.
*   **Angle**: X축 회전 약 -30도, Y축 회전 45도 (일반적인 아이소메트릭 각도).
*   **Size**: 줌 레벨 조절은 카메라의 `Size` 속성을 변경하여 구현.

```gdscript
# Camera3D 설정 예시
func setup_isometric_camera():
    projection = Camera3D.PROJECTION_ORTHOGONAL
    rotation_degrees = Vector3(-30, 45, 0)
    size = 10.0 # 줌 레벨
```

### 3. **입력 처리 (RayCast)**

*   마우스 클릭 시 3D 공간의 타일을 선택하기 위해 `PhysicsRayQueryParameters3D` 또는 `RayCast3D`를 사용합니다.
*   카메라에서 마우스 위치로 레이를 쏘아 교차하는 충돌체(GridMap 또는 유닛)를 감지합니다.

---

## ⚡ 성능 최적화 규칙 (3D)

### 1. **렌더링 최적화**

*   **MultiMeshInstance3D**: 숲, 잔디, 바위 등 동일한 메쉬가 반복되는 경우 반드시 `MultiMeshInstance3D`를 사용하여 드로우 콜(Draw Call)을 줄입니다.
*   **Occlusion Culling**: 복잡한 맵에서는 가려진 오브젝트를 렌더링하지 않도록 오클루전 컬링을 설정합니다.
*   **LOD (Level of Detail)**: 카메라 거리에 따라 모델의 디테일을 조절하는 LOD 기능을 활용합니다 (Godot 4.x 자동 LOD 지원).

### 2. **물리 및 충돌**

*   **Collision Shape**: 복잡한 `TrimeshCollision` 대신 단순한 `BoxShape3D`, `SphereShape3D`, `CapsuleShape3D`를 우선 사용합니다.
*   **Layer & Mask**: 충돌 레이어와 마스크를 철저히 구분하여 불필요한 충돌 연산을 방지합니다.
    *   Layer 1: 지형 (Terrain)
    *   Layer 2: 유닛 (Unit)
    *   Layer 3: 상호작용 오브젝트

### 3. **조명 및 섀도우**

*   **Lightmap**: 정적인 지형에는 `LightmapGI`를 사용하여 런타임 조명 연산을 최소화합니다.
*   **Shadows**: 동적 그림자(DirectionalLight3D)의 해상도와 거리를 적절히 조절합니다. 모바일 타겟인 경우 실시간 그림자를 최소화합니다.

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

---

## 📦 버전 관리 및 협업

*   **LFS (Large File Storage)**: 3D 모델(.gltf, .fbx), 고해상도 텍스처, 오디오 파일은 Git LFS로 관리합니다.
*   **.godot 폴더**: `.godot/` 폴더는 절대 커밋하지 않습니다 (로컬 캐시 및 임포트 데이터).

---

## 🚀 배포 전 체크리스트 (3D)

*   □ **텍스처 압축**: 플랫폼에 맞는 텍스처 압축 형식(VRAM Compression) 확인 (PC: S3TC/BPTC, Mobile: ETC2/ASTC).
*   □ **셰이더 컴파일**: 셰이더 캐싱 전략 확인 (게임 시작 시 렉 방지).
*   □ **해상도 대응**: 다양한 화면 비율에서 UI와 3D 뷰포트가 깨지지 않는지 확인.

---

이 가이드라인은 Godot 4.5 기반의 3D 아이소메트릭 SRPG 프로젝트를 위해 작성되었습니다.