# 카카오 로그인 설정 가이드

## 1. 카카오 개발자 콘솔 설정

### 1.1 애플리케이션 생성

1. [카카오 개발자 콘솔](https://developers.kakao.com/) 접속
2. **내 애플리케이션** → **애플리케이션 추가하기**
3. 앱 이름: `독서 리뷰 앱` (또는 원하는 이름)
4. 회사명 입력 후 **저장**

### 1.2 플랫폼 설정

1. **플랫폼** → **Web 플랫폼 등록**
2. **사이트 도메인** 추가:
   ```
   http://localhost:3000
   http://localhost:57333
   https://your-domain.com (배포 시)
   ```

### 1.3 카카오 로그인 활성화

1. **제품 설정** → **카카오 로그인**
2. **활성화 설정** ON
3. **OpenID Connect 활성화** ON (선택사항)

### 1.4 Redirect URI 설정

1. **제품 설정** → **카카오 로그인** → **Redirect URI**
2. **Redirect URI 등록** 클릭
3. 다음 URL들을 추가:

#### 🌐 웹 환경 (현재 상황)

```
# 로컬 개발
http://localhost:3000/auth/kakao/callback
http://localhost:57333/auth/kakao/callback

# Supabase를 사용하는 경우
https://bssiddbhnuguloktqsmy.supabase.co/auth/v1/callback

# 배포 시
https://your-domain.com/auth/kakao/callback
```

#### 📱 모바일 앱 (나중에 필요시)

```
com.example.bookreviewapp://kakao/callback
```

### 1.5 동의항목 설정

1. **제품 설정** → **카카오 로그인** → **동의항목**
2. 필수 동의항목 설정:
   - **닉네임** (필수)
   - **이메일** (선택 → 필수로 변경)

## 2. REST API 키 복사

1. **앱 설정** → **앱 키**
2. **REST API 키** 복사 (JavaScript 키도 복사)

## 3. Supabase 카카오 Provider 설정

### 3.1 Supabase 대시보드

1. Supabase 프로젝트 → **Authentication** → **Providers**
2. **Kakao** 찾아서 활성화 토글
3. 설정 정보 입력:
   - **Client ID**: 카카오 REST API 키
   - **Client Secret**: (카카오는 보통 필요 없음, 비워두거나 REST API 키와 동일)

### 3.2 Redirect URL 확인

Supabase에서 제공하는 Redirect URL:

```
https://bssiddbhnuguloktqsmy.supabase.co/auth/v1/callback
```

## 4. .env 파일 업데이트

```env
# Supabase 설정
SUPABASE_URL=https://bssiddbhnuguloktqsmy.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# 카카오 OAuth
KAKAO_REST_API_KEY=your-kakao-rest-api-key
KAKAO_JAVASCRIPT_KEY=your-kakao-javascript-key

# AI Agent 설정
AGENT_BASE_URL=https://book-agent.vercel.app
OPENAI_API_KEY=your-openai-api-key
```

## 5. Flutter 앱 코드 업데이트

### 5.1 Supabase를 사용한 카카오 로그인

```dart
// 카카오 로그인
Future<AuthResult> signInWithKakao() async {
  try {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: kIsWeb ? null : 'com.example.bookreviewapp://kakao/callback',
    );

    if (kIsWeb) {
      // 웹에서는 리다이렉트됨
      return AuthResult.success(UserInfo(
        id: 'pending',
        name: 'Kakao User',
        email: 'pending@kakao.com',
        provider: 'kakao',
      ));
    }

    // 모바일에서는 결과 확인
    final user = currentUser;
    if (user != null) {
      return AuthResult.success(_convertToUserInfo(user));
    } else {
      return AuthResult.error('카카오 로그인에 실패했습니다.');
    }
  } catch (error) {
    return AuthResult.error('카카오 로그인에 실패했습니다: $error');
  }
}
```

## 6. 빠른 테스트 방법

Supabase에서 카카오를 지원하지 않는 경우, 대안:

### 6.1 카카오 REST API 직접 사용

```dart
Future<AuthResult> signInWithKakao() async {
  const kakaoAuthUrl = 'https://kauth.kakao.com/oauth/authorize'
      '?client_id=YOUR_REST_API_KEY'
      '&redirect_uri=http://localhost:57333/auth/kakao/callback'
      '&response_type=code';

  // 웹에서 새 창으로 카카오 로그인 페이지 열기
  html.window.open(kakaoAuthUrl, '_blank');

  // 콜백 처리 로직 추가
}
```

### 6.2 임시 더미 로그인 (현재 상태)

카카오 버튼 클릭 시 임시 계정으로 로그인하여 플로우 테스트

## 7. 문제 해결

### 자주 발생하는 오류:

- **redirect_uri_mismatch**: 카카오 콘솔의 Redirect URI 확인
- **invalid_client**: REST API 키 확인
- **insufficient_scope**: 동의항목 설정 확인

### 디버그:

브라우저 개발자 도구에서 네트워크 탭으로 OAuth 요청 확인

