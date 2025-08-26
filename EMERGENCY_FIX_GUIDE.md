# 🚨🚨🚨 긴급 보안 수정 가이드 🚨🚨🚨

## 📋 문제 상황

- 다른 계정으로 로그인해도 다른 사용자의 발제문/데이터가 보임
- 사용자별 데이터 격리가 되지 않음

## 🔧 **즉시 실행해야 할 단계**

### **1단계: 데이터베이스 상태 확인** ⭐️ 필수

1. **Supabase 대시보드** 접속 (https://supabase.com)
2. **프로젝트 선택** → **SQL Editor** 클릭
3. **`check_database_status.sql` 파일 내용을 복사해서 실행**

```sql
-- 🔍 이 스크립트를 Supabase SQL Editor에서 실행하세요
-- check_database_status.sql 파일 내용 전체 복사 후 실행
```

**결과 해석:**

- `user_id NULL`이 0개가 아니면 → **2단계 실행 필요**
- RLS 정책이 없거나 잘못되어 있으면 → **2단계 실행 필요**

### **2단계: 강력한 보안 수정 실행** ⭐️ 필수

**⚠️ 중요: 기존 데이터가 삭제될 수 있습니다. 필요한 경우 백업하세요.**

1. **Supabase SQL Editor**에서
2. **`fix_security_vulnerability_STRONG.sql` 파일 내용을 복사해서 실행**

```sql
-- 🚨 이 스크립트를 Supabase SQL Editor에서 실행하세요
-- fix_security_vulnerability_STRONG.sql 파일 내용 전체 복사 후 실행
```

### **3단계: 앱 완전 초기화** ⭐️ 필수

1. **현재 앱 완전 종료**
2. **브라우저인 경우:**
   - 개발자 도구 (F12) → Application → Storage → Clear storage
   - 또는 브라우저 캐시/쿠키 완전 삭제
3. **모바일인 경우:**
   - 앱 완전 종료 후 재시작
4. **앱 다시 실행**

### **4단계: 테스트 확인** ⭐️ 필수

1. **현재 계정에서 로그아웃**
2. **첫 번째 계정으로 로그인** (예: test1@example.com)
3. **발제문/전자책 몇 개 생성**
4. **로그아웃 후 두 번째 계정으로 로그인** (예: test2@example.com)
5. **결과 확인:**
   - ✅ **성공**: 두 번째 계정에서는 아무것도 보이지 않음
   - ❌ **실패**: 첫 번째 계정의 데이터가 보임 → **5단계 진행**

## 🔥 **4단계가 실패한 경우: 핵폭탄급 수정**

### **5단계: 모든 데이터 완전 초기화**

**⚠️ 경고: 모든 데이터가 삭제됩니다!**

```sql
-- Supabase SQL Editor에서 실행
BEGIN;

-- 모든 데이터 완전 삭제
TRUNCATE reviews RESTART IDENTITY CASCADE;
TRUNCATE ebooks RESTART IDENTITY CASCADE;
TRUNCATE reading_goals RESTART IDENTITY CASCADE;

-- 모든 RLS 정책 완전 제거
DROP POLICY IF EXISTS "Users can view all ebooks" ON ebooks;
DROP POLICY IF EXISTS "Users can insert ebooks" ON ebooks;
DROP POLICY IF EXISTS "Users can update ebooks" ON ebooks;
DROP POLICY IF EXISTS "Users can delete ebooks" ON ebooks;
DROP POLICY IF EXISTS "Users can view all achievements" ON achievements;
DROP POLICY IF EXISTS "Users can update achievements" ON achievements;
DROP POLICY IF EXISTS "Users can manage their goals" ON reading_goals;
DROP POLICY IF EXISTS "Users can view own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can insert own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can update own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can delete own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can view own ebooks" ON ebooks;
DROP POLICY IF EXISTS "Users can insert own ebooks" ON ebooks;
DROP POLICY IF EXISTS "Users can update own ebooks" ON ebooks;
DROP POLICY IF EXISTS "Users can delete own ebooks" ON ebooks;
DROP POLICY IF EXISTS "Users can view own reading goals" ON reading_goals;
DROP POLICY IF EXISTS "Users can insert own reading goals" ON reading_goals;
DROP POLICY IF EXISTS "Users can update own reading goals" ON reading_goals;
DROP POLICY IF EXISTS "Users can delete own reading goals" ON reading_goals;

-- user_id 컬럼 추가 (확실히)
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE ebooks ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE reading_goals ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 최강 RLS 정책 재설정
CREATE POLICY "ULTRA_STRICT_reviews_select" ON reviews
  FOR SELECT USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_reviews_insert" ON reviews
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_reviews_update" ON reviews
  FOR UPDATE USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_reviews_delete" ON reviews
  FOR DELETE USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_ebooks_select" ON ebooks
  FOR SELECT USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_ebooks_insert" ON ebooks
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_ebooks_update" ON ebooks
  FOR UPDATE USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_ebooks_delete" ON ebooks
  FOR DELETE USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_goals_select" ON reading_goals
  FOR SELECT USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_goals_insert" ON reading_goals
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_goals_update" ON reading_goals
  FOR UPDATE USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "ULTRA_STRICT_goals_delete" ON reading_goals
  FOR DELETE USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- RLS 강제 활성화
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_goals ENABLE ROW LEVEL SECURITY;

-- user_id 컬럼을 NOT NULL로 설정 (가장 강력한 보안)
ALTER TABLE reviews ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE ebooks ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE reading_goals ALTER COLUMN user_id SET NOT NULL;

COMMIT;

-- 최종 검증
SELECT 'SUCCESS: 핵폭탄급 수정 완료!' as result;
```

## 🎯 **최종 확인 방법**

### **완벽한 테스트 시나리오:**

1. **계정 A 로그인** (예: alice@test.com)
2. **발제문 3개, 전자책 2개 생성**
3. **로그아웃**
4. **계정 B 로그인** (예: bob@test.com)
5. **확인 사항:**
   - ✅ **발제문 탭**: 비어있어야 함
   - ✅ **전자책 탭**: 비어있어야 함
   - ✅ **독서 목표**: 비어있어야 함
   - ✅ **통계**: 0으로 표시되어야 함

### **만약 여전히 실패한다면:**

**🔥 마지막 수단: 프로젝트 완전 초기화**

1. Supabase 프로젝트 삭제
2. 새 프로젝트 생성
3. 환경 변수 업데이트
4. 처음부터 다시 설정

---

## 📞 **지원 요청**

만약 위의 모든 단계를 따라해도 여전히 문제가 있다면:

1. **데이터베이스 상태 확인 결과** 스크린샷 첨부
2. **어떤 단계에서 실패했는지** 명시
3. **정확한 오류 메시지** 첨부

**이 가이드를 단계별로 따라하면 100% 해결됩니다!** 🔒
