# 🚀 바로 로그인 테스트하기

OAuth 설정 없이 바로 테스트할 수 있는 방법들입니다.

## 방법 1: 이메일 회원가입 (가장 간단)

1. **앱 실행 후 로그인 페이지에서:**

   - 아무 이메일 입력 (예: `test@example.com`)
   - 비밀번호 입력 (예: `password123`)
   - "회원가입" 또는 "로그인" 버튼 클릭

2. **Supabase에서 자동으로 계정 생성됨**

## 방법 2: 더미 소셜 로그인

현재 Google/Apple 버튼은 더미 계정으로 연결됩니다:

- **Google 버튼** → `google.demo@example.com`
- **Apple 버튼** → `apple.demo@example.com`
- **Kakao 버튼** → `demo@example.com`

## 방법 3: Supabase 대시보드에서 직접 계정 생성

### 단계:

1. [supabase.com](https://supabase.com) → 프로젝트 선택
2. **Authentication** → **Users** 탭
3. **Add user** 버튼 클릭
4. 이메일/비밀번호 입력하여 사용자 생성

## 현재 상태

✅ **작동하는 것:**

- 이메일 회원가입/로그인
- 더미 소셜 로그인 (버튼은 작동)
- 로그인 상태 유지
- 자동 라우팅 (스플래시 → 인트로 → 로그인 → 홈)

❌ **아직 안 되는 것:**

- 실제 Google OAuth (설정 필요)
- 실제 Apple OAuth (설정 필요)

## 테스트 시나리오

1. **앱 시작** → 스플래시 화면
2. **비로그인 상태** → 인트로 페이지 → 로그인 페이지
3. **아무 이메일로 회원가입** → 홈 화면으로 이동
4. **앱 재시작** → 바로 홈 화면 (로그인 상태 유지)

## 문제 해결

### "Missing SUPABASE_URL" 오류가 나면:

```bash
# .env 파일에 실제 Supabase 정보 입력 필요
# Supabase 대시보드 → Settings → API에서 복사
```

### 이메일 확인 오류가 나면:

- Supabase 대시보드 → Authentication → Settings
- "Enable email confirmations" 비활성화

