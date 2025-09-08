# 🚨 Supabase + Flutter 프로필 생성 문제 해결 요청

## 📋 현재 문제 상황

### 🔍 **핵심 문제**

- Flutter 웹앱에서 회원가입 성공 후 `profiles` 테이블에 사용자 프로필이 생성되지 않음
- 회원가입은 정상적으로 `auth.users`에 저장됨
- `profiles` 테이블에만 데이터가 추가되지 않아 닉네임 중복 체크가 무의미함

### 💻 **기술 스택**

- **Frontend**: Flutter Web (Dart 3.8.1, Flutter 3.32.8)
- **Backend**: Supabase (PostgreSQL + Auth)
- **인증**: Supabase Auth (이메일/OAuth)
- **데이터베이스**: PostgreSQL with RLS

### 🔧 **시도했던 해결책들 (모두 실패)**

1. **DB 트리거 방식**: `CREATE TRIGGER ... AFTER INSERT ON auth.users` → 작동하지 않음
2. **RPC 함수 방식**: `_client.rpc('ensure_user_profile')` → API 호출 문제
3. **재시도 로직**: 3번까지 재시도 → 여전히 실패
4. **타이밍 대기**: 1-1.5초 대기 후 처리 → 지연 현상만 해결
5. **권한 설정**: `GRANT ALL` 및 `SECURITY DEFINER` → 여전히 안됨

## 🎯 **원하는 최종 결과**

### ✅ **필수 기능**

1. **회원가입시 자동 프로필 생성**: `auth.users` → `profiles` 테이블에 동시 생성
2. **닉네임 자동 생성**: 랜덤한 한국어 닉네임 (예: `독서가1234`, `귀여운고양이`)
3. **중복 방지**: 같은 닉네임 방지 시스템
4. **실시간 반영**: 회원가입 즉시 프로필 확인 가능

### 📊 **profiles 테이블 구조**

```sql
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT,
    nickname TEXT UNIQUE,
    full_name TEXT,
    provider TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
```

### 📱 **현재 Flutter 코드 (간소화 버전)**

```dart
// 이메일 회원가입
Future<AuthResult> signUpWithEmail(String email, String password) async {
  final response = await _client.auth.signUp(email: email, password: password);

  if (response.user != null) {
    // 여기서 profiles 테이블에 INSERT해야 함
    final nickname = 'ㅊㅊㅊ독서가${DateTime.now().millisecondsSinceEpoch % 10000}';

    await _client.from('profiles').insert({
      'id': response.user!.id,
      'email': response.user!.email,
      'nickname': nickname,
      'full_name': nickname,
      'provider': 'email',
    });

    return AuthResult.success(_convertToUserInfo(response.user!));
  }
}
```

## 🚨 **의심되는 원인들**

### 1️⃣ **RLS (Row Level Security) 정책 문제**

- `authenticated` 역할이 `profiles` 테이블에 INSERT 권한 없음
- RLS 정책이 새 사용자의 프로필 생성을 차단

### 2️⃣ **Supabase 클라이언트 설정 문제**

- 클라이언트가 올바른 권한으로 요청하지 않음
- 세션 상태나 인증 토큰 문제

### 3️⃣ **테이블 제약조건 문제**

- UNIQUE 제약조건이나 NOT NULL 제약으로 INSERT 실패
- Foreign Key 제약조건 문제

### 4️⃣ **비동기 처리 문제**

- 회원가입 완료 전에 프로필 생성 시도
- 사용자 세션이 완전히 설정되기 전에 API 호출

## 🔧 **테스트 가능한 해결책 후보들**

### 방법 1: **RLS 정책 수정**

```sql
-- profiles 테이블 RLS 정책 확인 및 수정
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
```

### 방법 2: **서비스 역할 사용**

```dart
// anon key 대신 service_role key 사용하여 권한 우회
```

### 방법 3: **Edge Function 사용**

```typescript
// Supabase Edge Function으로 서버사이드에서 프로필 생성
```

### 방법 4: **트리거 디버깅**

```sql
-- 트리거가 실제로 실행되는지 로깅으로 확인
CREATE OR REPLACE FUNCTION log_trigger_execution() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO debug_logs (message, created_at) VALUES ('Trigger executed for user: ' || NEW.id, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## 💡 **즉시 확인할 사항들**

1. **Supabase 대시보드 → Authentication → Settings**: RLS 정책 확인
2. **Database → Tables → profiles**: 테이블 구조 및 제약조건 확인
3. **SQL Editor**: 수동 INSERT 테스트로 권한 문제 확인
4. **브라우저 개발자 도구**: 네트워크 탭에서 실제 API 요청/응답 확인

## ❓ **핵심 질문**

**가장 간단한 방법으로 Flutter 웹에서 Supabase profiles 테이블에 회원가입과 동시에 사용자 프로필을 생성하는 확실한 방법은 무엇인가요?**

---

**이 프롬프트를 다른 AI에게 복사해서 물어보세요! 더 나은 해결책을 제시해줄 것입니다.** 🚀
