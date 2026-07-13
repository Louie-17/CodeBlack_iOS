# CLAUDE.md

CodeBlack iOS 앱 작업 규칙 및 프로젝트 컨텍스트. Claude/에이전트는 이 문서를 무조건 따른다.
(이 문서는 `AGENT.md`와 동일하게 유지한다. 한쪽을 고치면 다른 쪽도 같이 고친다.)

---

## 1. 프로젝트 개요

**CodeBlack** — "응급실 뺑뺑이"를 해결하는 응급 이송 지원 앱.

응급환자 발생 시 구급대원이 수용 가능한 병원을 찾기 위해 여러 병원에 반복 전화하며 골든타임을 놓치는 문제를 해결한다. 앱이 AI로 병원을 추천하고, 환자 정보를 병원에 즉시 전달해 병원 선정 시간을 최소화한다.

**핵심 흐름 (서비스 적용 후):**
환자 발생 → 구급차 탑승 → 앱 실행 → 추천 병원 목록 확인 → 병원 선택 → 환자 정보(음성→텍스트) 전송 → 병원 수락 → 병원으로 이동

---

## 2. 사용자 역할

- **구급대원**: 병원 조회/추천 확인, 환자 상태 음성 입력, 수용 요청 전송, 요청 상태 확인, 수락 병원 길안내.
- **병원 담당자(응급실)**: 들어온 요청 목록/상세 확인, 환자 수용 **수락**.

**중요 도메인 규칙:**
- 병원은 **거절 기능이 없다.** 수락하거나 미응답으로만 남는다. (거절 API 미제공)
- AI가 수용 가능성·거리·병상·장비를 종합해 우선순위(1·2·3순위)를 산정해 요청을 보낸다.
- 한 병원이 수락하면 같은 환자 요청의 **다른 병원 요청은 자동 취소**되고 "이미 다른 병원에서 수락되었습니다."로 표시된다.
- 역할 기반 접근 제어(RBAC): 구급대원 API와 병원 API 권한 분리, 병원 담당자는 자기 병원 요청만 조회 가능.

---

## 3. 핵심 기능 (MVP)

**구급대원(iOS 주요 화면):**
- 로그인 / 내 정보 조회 (미리 등록된 계정, access token 기반)
- 추천 병원 목록 조회 (현재 위치 기준, 정렬: 거리/병상/추천점수)
- 병원 상세 조회 (거리, 병상, 당직, 장비)
- 환자 상태 음성 입력 → STT 텍스트 변환 → 전송 전 확인
- 병원 수용 요청 생성 / 여러 병원 요청 관리
- 요청 현황 조회 + **상태 polling**(실시간 근사)
- 수락 병원 정보 조회 + 길안내(좌표/주소 → 지도 앱 연동)

**병원 담당자:**
- 병원 요청 목록/상세 조회, 환자 수용 수락
- 요청 알림 수신(잠금화면 포함, 응답 전까지 반복 알림), 알림 읽음 처리

**MVP 제외/추후:** 자동 전화(외부 전화 API), 병원 데이터 캐싱.

---

## 4. 기술 스택 & 프로젝트 설정

- **UI**: SwiftUI
- **iOS Deployment Target**: 26.5 / **Swift**: 5.0
- **동시성**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES` → 기본 MainActor 격리 전제. async/await 기반으로 작성한다.
- **Bundle ID**: `codeBlack.CodeBlack` / **Target**: iPhone + iPad
- **현지화**: String Catalog 사용 (`LOCALIZATION_PREFERS_STRING_CATALOGS = YES`) — 하드코딩 문자열 대신 문자열 카탈로그 사용.

**프로젝트 구조:**
```
CodeBlack_iOS/            # git 루트
├─ CLAUDE.md / AGENT.md
├─ CodeBlack/
│  ├─ CodeBlack.xcodeproj
│  └─ CodeBlack/          # 소스 (CodeBlackApp.swift, ContentView.swift, Assets.xcassets ...)
```
현재 앱 코드는 SwiftUI 기본 템플릿 상태다. 기능 명세에 맞춰 구현을 채워 나간다.

---

## 5. 아키텍처 / 코딩 가이드

- **패턴**: MVVM. 화면별 `View` + `@Observable`(또는 `ObservableObject`) ViewModel. 네트워크/도메인 로직은 View에서 분리.
- **네트워킹**: `async/await` + `URLSession` 기반 서비스 계층. 백엔드는 REST + Swagger(OpenAPI) 명세 제공 예정 → DTO는 명세에 맞춰 `Codable`로 정의.
- **인증**: access token 저장은 Keychain. 역할(구급대원/병원)에 따라 라우팅/화면 분기.
- **위치**: `CoreLocation`으로 현재 위도/경도 획득 후 추천 병원 조회에 사용.
- **STT**: `Speech` 프레임워크(SFSpeechRecognizer) + 마이크 권한. 변환 텍스트는 전송 전 사용자 확인 단계 필수.
- **알림**: 병원용 푸시/로컬 알림, 잠금화면 표시, 응답 전 반복 알림.
- **요청 상태**: polling 주기 조회. 상태값 = 대기 / 수락 / 취소 / 미응답.
- **더미 데이터**: 공공 API 연동 전에는 seed/로컬 병원 데이터로 개발·테스트.
- **컨벤션**: 기존 파일의 패턴을 따르고 병렬 컨벤션을 만들지 않는다. 하드코딩 문자열·매직넘버 지양, 값은 명확히 명명.

---

## 6. Git 워크플로 (필수)

- **이슈 생성 금지.** GitHub Issue를 만들지 않는다.
- **PR 생성 금지.** Pull Request를 만들지 않는다. 브랜치 → PR 병합 흐름을 쓰지 않는다.
- **무조건 `main`에 직접 커밋한다.** 별도 feature 브랜치를 만들지 않는다.
- **커밋하면 즉시 푸시한다.** `git commit` 후 항상 `git push origin main`을 같이 실행한다. 커밋만 하고 푸시를 미루지 않는다.

### 표준 커밋 절차
```bash
git add -A
git commit -m "<메시지>"
git push origin main
```

- 작업이 끝나면 위 절차대로 main에 커밋 + 푸시까지 한 번에 완료한다.
- 커밋 메시지는 무엇을/왜 바꿨는지 명확히 쓴다.
- 승인을 구걸하지 않는다. 규칙 범위 내 작업은 바로 실행한다.

---

## 7. 참고 문서 (Notion)

프로젝트 워크스페이스: **CodeBlack** (Notion)
- 프로젝트 기획 문서 — https://www.notion.so/39c4f107a736805f849bd3fec05f9420
- 요구사항 명세서(SRS) — https://www.notion.so/39c4f107a73680e785aaf01b14ec8818
- 사용자 시나리오 / User Flow — https://www.notion.so/39c4f107a7368030a713f7d8187f0962
- 화면 설계서(Wireframe) — https://www.notion.so/39c4f107a73680298658c71d4e33366a
- 기능 명세서 — https://www.notion.so/39c4f107a73680969837d7ef66faad85
- iOS(전공별) — https://www.notion.so/39c4f107a736807f9b2ccabf37b68673

기능/요구사항의 최신 기준은 Notion 문서다. 구현 전 관련 페이지를 확인한다.
