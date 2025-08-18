# Supabase 인증 설정 가이드

## 1. Supabase 프로젝트 설정

### 환경변수 파일 생성

`assets/env/.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
# Supabase 설정
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# AI Agent 설정
AGENT_BASE_URL=https://book-agent.vercel.app

# OpenAI API 키 (Vercel 함수용)
OPENAI_API_KEY=your-openai-api-key
```

## 2. Supabase 대시보드에서 인증 설정

### 2.1 Google OAuth 설정

1. Supabase 대시보드 → Authentication → Providers
2. Google 제공업체 활성화
3. Google Cloud Console에서 OAuth 2.0 클라이언트 ID 생성:

   - 프로젝트 생성 또는 선택
   - APIs & Services → Credentials
   - OAuth 2.0 Client IDs 생성
   - 웹 애플리케이션 선택
   - 승인된 JavaScript 원본: `http://localhost:3000`, `https://your-domain.com`
   - 승인된 리디렉션 URI: `https://your-project-ref.supabase.co/auth/v1/callback`

4. Supabase에 Client ID와 Client Secret 입력

### 2.2 Apple 로그인 설정 (iOS/macOS)

1. Apple Developer Account 필요
2. Supabase 대시보드에서 Apple 제공업체 활성화
3. Apple Developer Console에서 설정

### 2.3 이메일 인증 설정

1. Supabase 대시보드 → Authentication → Settings
2. "Enable email confirmations" 설정
3. 이메일 템플릿 커스터마이징 (선택사항)

## 3. 사용자 테이블 설정

Supabase SQL Editor에서 다음 쿼리 실행:

```sql
-- 사용자 프로필 테이블 (auth.users와 연동)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  provider TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS 정책 설정
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 프로필만 조회/수정 가능
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- 프로필 자동 생성 트리거
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url, provider)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture'),
    NEW.app_metadata->>'provider'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 생성
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## 4. 테스트 계정 생성

개발용 테스트 계정을 생성하려면:

```sql
-- 테스트 사용자 생성 (개발 환경에서만 사용)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'demo@example.com',
  crypt('password123', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Demo User"}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
);
```

## 5. 앱에서 테스트

1. `.env` 파일에 올바른 Supabase URL과 anon key 입력
2. 앱 실행: `flutter run -d chrome`
3. 로그인 버튼으로 테스트
4. Supabase 대시보드의 Authentication 탭에서 사용자 확인

## 문제 해결

### 일반적인 오류들:

- **Missing SUPABASE_URL**: `.env` 파일 경로와 내용 확인
- **OAuth 에러**: 리디렉션 URI 설정 확인
- **CORS 에러**: Supabase 대시보드에서 허용된 도메인 추가

### 디버깅:

```dart
// 현재 사용자 확인
print('Current user: ${SupabaseAuthService().currentUser}');

// 인증 상태 변경 리스너
SupabaseAuthService().authStateChanges.listen((state) {
  print('Auth state changed: ${state.session?.user?.email}');
});
```

