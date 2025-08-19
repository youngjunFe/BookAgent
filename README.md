# 📚 북클럽 - AI 기반 독서 관리 앱

Flutter로 개발된 종합적인 독서 관리 및 AI 상호작용 앱입니다.

## 🎯 프로젝트 개요

북클럽은 독서를 더욱 즐겁고 의미있게 만들어주는 AI 기반 독서 관리 플랫폼입니다. 사용자는 AI와 대화하며 발제문을 작성하고, 전자책을 읽고, 독서 목표를 설정하여 체계적으로 독서 습관을 관리할 수 있습니다.

## ✨ 주요 기능

### 🤖 AI 채팅 시스템

- **지능형 대화**: GPT 기반 AI와 자연스러운 대화
- **발제문 생성**: AI 도움으로 독서 후 발제문 자동 생성
- **캐릭터 채팅**: 책 속 등장인물과의 가상 대화
- **대화 히스토리**: 모든 대화 내용 저장 및 검색

### 📖 나의 서재

- **발제문 관리**: AI와 작성한 발제문 편집 및 저장
- **전자책 라이브러리**: 개인 전자책 컬렉션 관리
- **읽기 진행률**: 실시간 독서 진행률 추적
- **통합 관리**: 발제문과 전자책을 한 곳에서 관리

### 🎯 독서 목표 & 성취 시스템

- **다양한 목표 유형**: 일간/주간/월간/연간/연속독서/페이지/시간
- **진행률 추적**: 실시간 목표 달성률 시각화
- **배지 시스템**: 7가지 카테고리의 성취 배지
- **독서 통계**: 상세한 개인 독서 분석

### 📱 직관적 UI/UX

- **모던 디자인**: Material Design 3 기반
- **다크/라이트 테마**: 사용자 선호에 따른 테마 선택
- **반응형 레이아웃**: 다양한 화면 크기 지원
- **부드러운 애니메이션**: 자연스러운 화면 전환

## 🏗️ 프로젝트 구조

```
lib/
├── core/                           # 핵심 설정 및 상수
│   ├── constants/
│   │   ├── app_colors.dart        # 색상 정의
│   │   └── app_strings.dart       # 문자열 상수
│   └── theme/
│       └── app_theme.dart         # 앱 테마 설정
│
├── shared/                         # 공통 위젯 및 유틸리티
│   └── widgets/
│       └── main_navigation.dart   # 하단 네비게이션
│
├── features/                       # 기능별 모듈
│   ├── home/                      # 홈 화면
│   │   └── presentation/
│   │       └── home_page.dart
│   │
│   ├── chat/                      # AI 채팅 시스템
│   │   ├── models/
│   │   │   ├── chat_message.dart
│   │   │   └── character.dart
│   │   └── presentation/
│   │       ├── ai_chat_page.dart
│   │       └── character_selection_page.dart
│   │
│   ├── library/                   # 나의 서재
│   │   └── presentation/
│   │       ├── library_page.dart
│   │       └── ebook_tab.dart
│   │
│   ├── review/                    # 발제문 관리
│   │   └── presentation/
│   │       └── review_creation_page.dart
│   │
│   ├── ebook/                     # 전자책 기능
│   │   ├── models/
│   │   │   └── ebook.dart
│   │   └── presentation/
│   │       ├── ebook_reader_page.dart
│   │       ├── add_book_page.dart
│   │       └── book_management_page.dart
│   │
│   └── reading_goals/             # 독서 목표 시스템
│       ├── models/
│       │   ├── reading_goal.dart
│       │   ├── achievement.dart
│       │   └── reading_stats.dart
│       └── presentation/
│           ├── reading_goals_page.dart
│           ├── goal_creation_page.dart
│           ├── achievements_page.dart
│           └── stats_page.dart
│
└── main.dart                      # 앱 진입점
```

## 🎨 주요 화면

### 🏠 홈 화면

- **퀵 액션 카드**: 주요 기능 바로가기
- **AI와 리뷰 작성**: 대화형 발제문 생성
- **전자책 읽기**: 개인 서재로 바로 이동
- **독서 목표**: 목표 설정 및 현황 확인
- **등장인물과 대화**: 캐릭터 채팅 기능

### 💬 AI 채팅

- **스마트 대화**: 책에 대한 깊이 있는 토론
- **발제문 도움**: 구조화된 발제문 작성 지원
- **실시간 응답**: 자연스러운 대화 플로우
- **대화 저장**: 모든 대화 내용 자동 보관

### 📚 나의 서재

- **발제문 탭**: AI와 작성한 발제문 관리
- **전자책 탭**: 개인 전자책 라이브러리
- **통합 검색**: 발제문과 책을 한 번에 검색
- **상태별 필터링**: 진행 상황별 분류

### 🎯 독서 목표

- **목표 설정**: 다양한 유형의 독서 목표
- **진행률 시각화**: 실시간 달성률 표시
- **성취 배지**: 7가지 카테고리 28개 배지
- **상세 통계**: 월별/장르별 독서 분석

## 🔧 기술 스택

### Frontend

- **Flutter**: 크로스 플랫폼 앱 개발
- **Dart**: 주 개발 언어
- **Material Design 3**: 모던 UI 디자인

### Architecture

- **Feature-First Architecture**: 기능별 모듈 구조
- **Presentation Layer**: UI 및 상태 관리
- **Model Layer**: 데이터 모델 정의

### State Management

- **Provider**: 상태 관리 (추후 구현 예정)
- **Local Storage**: 로컬 데이터 저장

## 🎨 디자인 시스템

### 색상 팔레트

```dart
// Primary Colors
primary: Color(0xFF6366F1)      // 인디고 블루
secondary: Color(0xFF8B5CF6)    // 보라색

// Surface Colors
background: Color(0xFFFAFAFA)   // 라이트 그레이
surface: Color(0xFFFFFFFF)      // 화이트
cardColor: Color(0xFFF8F9FA)    // 카드 배경

// Text Colors
textPrimary: Color(0xFF1F2937)   // 다크 그레이
textSecondary: Color(0xFF6B7280) // 미디엄 그레이
textHint: Color(0xFF9CA3AF)      // 라이트 그레이
```

### 타이포그래피

- **Pretendard**: 한글 최적화 폰트
- **다양한 크기**: Headline, Title, Body, Caption
- **적절한 행간**: 가독성 최적화

## 📋 구현된 기능 상세

### 1. AI 채팅 시스템

```dart
// 메시지 모델
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
}

// 캐릭터 모델
class Character {
  final String id;
  final String name;
  final String description;
  final String book;
  final String personality;
  final String avatarUrl;
}
```

### 2. 전자책 관리

```dart
// 전자책 모델
class EBook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final List<String> content;
  final int currentPage;
  final int totalPages;
  final double progress;
  final DateTime? lastReadAt;
  final DateTime addedAt;
}
```

### 3. 독서 목표 시스템

```dart
// 독서 목표 모델
class ReadingGoal {
  final String id;
  final String title;
  final GoalType type;
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
}

// 성취 배지 모델
class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final bool isUnlocked;
  final DateTime? unlockedAt;
}
```

## 🎯 주요 성취 배지

### 📚 이정표 배지

- **첫 번째 책**: 첫 완독 축하
- **독서 입문자**: 5권 완독
- **독서 마니아**: 10권 완독

### 🔥 연속 독서 배지

- **꾸준한 독서가**: 7일 연속
- **독서 마스터**: 30일 연속

### ⚡ 특별 성취 배지

- **스피드 리더**: 하루 100페이지
- **장르 탐험가**: 5개 장르 완주
- **월간 챌린저**: 월 목표 달성

## 🚀 주요 특징

### 🎨 사용자 경험

- **직관적 네비게이션**: 하단 탭 기반 구조
- **일관된 디자인**: 전체적으로 통일된 UI
- **반응형 레이아웃**: 다양한 디바이스 지원
- **접근성 고려**: 스크린 리더 지원

### 📊 데이터 시각화

- **진행률 바**: 읽기 진도 시각화
- **통계 차트**: 독서 패턴 분석
- **배지 시스템**: 성취 현황 표시
- **스트릭 표시**: 연속 독서일 강조

### 🔄 상태 관리

- **실시간 동기화**: 읽기 진도 자동 저장
- **오프라인 지원**: 로컬 데이터 저장
- **백업 기능**: 데이터 손실 방지

## 📱 지원 플랫폼

- **Web**: Chrome, Safari, Firefox
- **Mobile**: iOS, Android (Flutter 호환)
- **Desktop**: Windows, macOS, Linux (Flutter 호환)

## 🛠️ 설치 및 실행

### 필수 조건

- Flutter SDK 3.0+
- Dart 3.0+
- Chrome 브라우저 (웹 실행시)

### 실행 방법

```bash
# 의존성 설치
flutter pub get

# 웹에서 실행
flutter run -d chrome

# 모바일에서 실행
flutter run

# 빌드
flutter build web
flutter build apk
flutter build ios
```

## 🎮 사용법

### 1. 첫 시작

1. 앱 실행 후 홈 화면 확인
2. "AI와 리뷰 작성" 또는 "독서 목표" 선택
3. 첫 번째 목표 설정 또는 AI와 대화 시작

### 2. AI와 발제문 작성

1. "AI와 리뷰 작성" 카드 클릭
2. 읽은 책에 대해 AI와 대화
3. AI 도움으로 발제문 구조화
4. 완성된 발제문 저장

### 3. 전자책 읽기

1. "나의 서재" 탭 이동
2. "전자책" 탭 선택
3. 책 추가 또는 기존 책 선택
4. 읽기 진행률 자동 추적

### 4. 독서 목표 설정

1. "독서 목표" 카드 클릭
2. 목표 유형 선택 (월간, 연간 등)
3. 목표값 설정
4. 진행률 실시간 확인

## 🎯 향후 계획

### 📈 단기 계획

- [ ] 오프라인 모드 강화
- [ ] 푸시 알림 시스템
- [ ] 소셜 기능 추가
- [ ] 책 추천 알고리즘

### 🚀 장기 계획

- [ ] AI 음성 대화
- [ ] AR/VR 독서 경험
- [ ] 멀티플레이어 독서 게임
- [ ] 출판사 연동

## 💡 기여 방법

1. 이 저장소를 포크합니다
2. 새로운 기능 브랜치를 생성합니다
3. 변경사항을 커밋합니다
4. 브랜치에 푸시합니다
5. Pull Request를 생성합니다

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 🤝 연락처

- 프로젝트 관리자: [GitHub Profile]
- 이슈 제보: [GitHub Issues]
- 기능 제안: [GitHub Discussions]

---

<div align="center">

**📚 읽기를 통해 성장하는 여정, 북클럽과 함께하세요! 🚀**

Made with ❤️ and Flutter

</div>
# Force redeploy
# Force redeploy to apply OPENAI_API_KEY
# Force deployment #오후
# Fix Vercel deployment #오후
