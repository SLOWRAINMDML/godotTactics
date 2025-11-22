# 📋 개발 규칙 및 가이드라인

## 5.1. GDScript 코딩 규칙
-   **명명 규칙**: 클래스는 `PascalCase`, 변수/함수/신호는 `snake_case`, 상수는 `SCREAMING_SNAKE_CASE`.
-   **타입 힌트**: 모든 변수, 함수 매개변수, 반환값에 타입 힌트를 의무적으로 사용.
-   **주석**: 복잡한 함수 상단에는 목적, 매개변수, 반환값에 대한 설명을 명시. `##` 사용.
-   **오류 처리**: `assert`와 `push_error`를 적절히 사용하고, 조기 반환(early return) 패턴으로 코드 가독성 확보.

## 5.2. 아키텍처 규칙
-   **싱글톤**: `GameManager`, `GameData` 등 전역 상태를 관리하는 용도로만 제한적으로 사용.
-   **신호(Signal)**: 다른 노드 트리나 계층 간의 통신(느슨한 결합)을 위해 사용. (예: `BattleGrid`의 타일 클릭 -> `BattleScene`에서 처리)
-   **의존성**: 하드코딩된 경로(`get_node("/root/...")`) 사용을 금지하고, `@onready`나 의존성 주입을 통해 참조.

## 5.3. 다국어 지원 시스템 (i18n)
-   **번역 시스템 아키텍처**: 
    -   **LocalizationManager.gd** (싱글톤): 전역 언어 설정 및 번역 관리
    -   **TranslationService.gd**: 로컬 서버 연동을 통한 번역 처리 및 캐시 관리 (별도 구현 예정)
    -   **CSVTranslationLoader.gd**: CSV 파일 기반 번역 데이터 로드/저장
-   **데이터 구조**:
    ```gdscript
    # translations/ui_text.csv
    key,ko,en,ja,zh_CN
    "ui.menu.start_game","게임 시작","Start Game","ゲーム開始","开始游戏"
    "skill.fireball.name","파이어볼","Fireball","ファイアボール","火球术"
    "skill.fireball.desc","화염 마법으로 적을 공격합니다","Attack enemies with fire magic","炎魔法で敵を攻撃する","用火焰魔法攻击敌人"
    ```
-   **AI 번역 통합**: 로컬 서버 연동 방식으로 구현 예정 (별도 프로젝트)
-   **실시간 언어 변경**: 게임 중에도 언어를 즉시 전환 가능
-   **폰트 시스템**: 언어별 최적화된 폰트 자동 로드 (한글, 일본어, 중국어 등)

## 5.4. 버전 관리 (Git)
-   **커밋 메시지**: `feat:`, `fix:`, `refactor:`, `docs:` 등의 접두사를 사용하여 커밋의 목적을 명확히 함.
-   **브랜치 전략**: `main`(릴리즈), `develop`(개발 통합), `feature/*`(기능 개발) 브랜치를 사용.
-   **.gitignore**: Godot 프로젝트에 특화된 `.godot/`, `.import/` 폴더 등을 반드시 포함. 