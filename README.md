# PassGuard - 비밀번호 보안 진단 앱

## 프로젝트 소개

**PassGuard**는 사용자의 비밀번호 보안 수준을 진단하고, 안전한 비밀번호 생성을 도와주는 iOS 앱입니다.

개인이 관리하는 다양한 계정의 비밀번호를 등록하면, 각 비밀번호의 강도·패턴·재사용 여부·변경 주기를 종합 분석하여 0~100점으로 점수화합니다.

## 시연 영상

[![PassGuard 시연 영상](https://img.youtube.com/vi/영상ID/0.jpg)](https://youtu.be/영상ID)

> YouTube 업로드 후 위 링크의 `영상ID`를 실제 YouTube 영상 ID로 교체해주세요.

---

## 1. 프로젝트 수행 목적

- 비밀번호 유출 사고가 빈번한 현실에서, 사용자가 스스로 보안 수준을 점검할 수 있는 도구 제공
- 단순히 "강함/약함"이 아닌, 구체적인 점수와 개선 방안을 제시하여 보안 의식 향상
- 안전한 비밀번호 자동 생성 기능으로 실질적인 보안 강화 지원

## 2. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 플랫폼 | iOS (iPhone) |
| 개발 언어 | Swift |
| 프레임워크 | SwiftUI, SwiftData, CryptoKit |
| 아키텍처 | MVVM (Model-View-ViewModel) |
| 보안 | SHA-256 해시 + iOS Keychain |
| 최소 지원 | iOS 17.0 이상 |

## 3. 주요 기능

### 회원가입 / 로그인
- SHA-256 해싱으로 비밀번호 암호화 저장
- iOS Keychain을 통한 안전한 인증 정보 관리
- 계정 탈퇴 기능 지원

### 홈 대시보드
- 전체 보안 점수 원형 게이지 (0~100점)
- 등록 계정 수, 위험 계정 수, 재사용 계정 수 요약 카드
- 신호등 색상 체계 (빨강/노랑/초록)

### 계정 목록 관리
- 계정별 서비스명, 사용자명, 보안 점수 표시
- 계정 검색 기능
- 상세 화면: 점수 분석, 강도 기준 안내, 경고 및 보완 제안
- 비밀번호 보기/변경/삭제 기능
- 스와이프 삭제 + 상세 화면 삭제 버튼

### 비밀번호 생성기
- 길이 조절 슬라이더 (4~20자)
- 문자 종류 토글 (소문자/대문자/숫자/특수문자) - 최소 1종류 필수
- 빠른 설정 프리셋 (숫자 PIN / 일반 / 최강)
- 혼동 문자 제외 옵션 (l, I, 1, O, 0)
- 패턴 없는 안전한 비밀번호 생성 (최대 50회 재시도)
- 실시간 점수 분석 + 예상 해독 시간 표시
- 클립보드 복사

### 설정
- 비밀번호 변경 주기 알림 (30/60/90일)
- 데이터 내보내기/가져오기 (JSON)
- 모든 데이터 삭제
- 로그아웃 / 계정 탈퇴

## 4. 보안 점수 산정 기준

| 항목 | 점수 범위 | 설명 |
|------|-----------|------|
| 강도 점수 | 0 ~ 60점 | 엔트로피(log₂(문자종류) × 길이) 기반 |
| 변경 주기 | 0 ~ 15점 | 90일 이내 +15 / 180일 이내 +8 / 초과 +0 |
| 패턴 감점 | 최대 -20점 | 사전단어, Leet치환, 키보드패턴, 순차/반복문자, 날짜, 편향, 단어+숫자 |
| 재사용 감점 | -15점 | 다른 계정과 동일 비밀번호 사용 시 |

### 패턴 감지 항목
- 사전 단어 탐지 (100개 이상 단어)
- Leet Speak 치환 감지 (P@ssw0rd → password)
- 키보드 패턴 (qwerty, asdf 등)
- 순차/역순 문자 (abc, 321)
- 반복 문자 (aaa)
- 날짜 형식 (2024, 0101)
- 문자 분포 편향 (한 종류 70% 이상)
- 단어+숫자 조합 (hello123)

## 5. 프로젝트 구조

```
FinalPJ/
├── FinalPJApp.swift              # 앱 진입점
├── ContentView.swift             # 인증 분기 + TabView
├── Item.swift                    # Account 데이터 모델 (SwiftData)
├── KeychainManager.swift         # Keychain CRUD + SHA-256
├── PasswordAnalyzer.swift        # 비밀번호 분석 엔진
├── AuthViewModel.swift           # 로그인/회원가입/탈퇴
├── AccountViewModel.swift        # 계정 CRUD
├── PasswordGeneratorViewModel.swift  # 생성기 로직
├── SettingsViewModel.swift       # 설정 로직
├── LoginView.swift               # 로그인 화면
├── HomeDashboardView.swift       # 홈 대시보드
├── AccountListView.swift         # 계정 목록/상세
├── PasswordGeneratorView.swift   # 비밀번호 생성기
└── SettingsView.swift            # 설정 화면
```

## 6. 기술 스택

| 분류 | 기술 |
|------|------|
| UI | SwiftUI |
| 데이터 저장 | SwiftData (@Model) |
| 보안 저장소 | iOS Keychain Services |
| 해시 | CryptoKit (SHA-256) |
| 상태 관리 | @Observable (Observation 프레임워크) |
| 데이터 교환 | JSON (FileDocument) |
| 아키텍처 | MVVM |

## 7. 실행 방법

1. Xcode 15 이상 설치
2. 이 저장소를 클론: `git clone https://github.com/nulbose/FinalPJ.git`
3. `FinalPJ.xcodeproj` 열기
4. iPhone 시뮬레이터 선택 후 실행 (⌘R)
