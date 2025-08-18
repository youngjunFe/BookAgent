# Google OAuth 설정 가이드

## 1. Google Cloud Console 설정

### 1.1 프로젝트 생성
1. [Google Cloud Console](https://console.cloud.google.com/) 이동
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. 프로젝트 이름: `BookReviewApp` (또는 원하는 이름)

### 1.2 OAuth 동의 화면 설정
1. **APIs & Services** → **OAuth consent screen**
2. **External** 선택 (개인 사용자용)
3. 필수 정보 입력:
   - **App name**: `독서 리뷰 앱`
   - **User support email**: 본인 이메일
   - **Developer contact information**: 본인 이메일
4. **Save and Continue**

### 1.3 OAuth 2.0 클라이언트 ID 생성
1. **APIs & Services** → **Credentials**
2. **+ CREATE CREDENTIALS** → **OAuth 2.0 Client IDs**
3. **Application type**: **Web application**
4. **Name**: `BookReviewApp Web Client`
5. **Authorized JavaScript origins** 추가:
   ```
   http://localhost:3000
   http://localhost:57333
   https://your-domain.com (배포 시)
   ```
6. **Authorized redirect URIs** 추가:
   ```
   https://your-supabase-project.supabase.co/auth/v1/callback
   ```
7. **CREATE** 클릭
8. **Client ID**와 **Client Secret** 복사 (나중에 필요)

## 2. Supabase 설정

### 2.1 Google Provider 활성화
1. Supabase 대시보드 → **Authentication** → **Providers**
2. **Google** 토글 활성화
3. 위에서 복사한 정보 입력:
   - **Client ID**: Google에서 생성한 Client ID
   - **Client Secret**: Google에서 생성한 Client Secret
4. **Save** 클릭

### 2.2 Redirect URL 확인
Supabase에서 제공하는 Redirect URL을 복사:
```
https://your-project-ref.supabase.co/auth/v1/callback
```

이 URL을 Google Cloud Console의 **Authorized redirect URIs**에 추가했는지 확인

## 3. .env 파일 업데이트

```env
# Supabase 설정
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Google OAuth (선택사항 - 웹에서는 Supabase가 처리)
GOOGLE_WEB_CLIENT_ID=your-google-client-id.googleusercontent.com

# AI Agent 설정
AGENT_BASE_URL=https://book-agent.vercel.app
OPENAI_API_KEY=your-openai-api-key
```

## 4. 빠른 설정 (테스트용)

바로 테스트하려면:

1. **임시 테스트 계정 생성**:
   - Supabase → Authentication → Users
   - Add user: `test@gmail.com` / `password123`

2. **Google 로그인 버튼 클릭**:
   - 현재는 더미 로그인이지만 플로우 확인 가능

3. **실제 Google OAuth 연결 후**:
   - 실제 Google 계정으로 로그인 가능

## 문제 해결

### 자주 발생하는 오류:
- **redirect_uri_mismatch**: Google Console의 redirect URI 확인
- **access_denied**: OAuth 동의 화면 설정 확인
- **invalid_client**: Client ID/Secret 확인

### 디버그 모드:
```dart
// auth_service.dart에서 로그 확인
debugPrint('Google auth response: $response');
```

