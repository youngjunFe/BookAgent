-- 🔥 긴급 RLS 정책 수정 (400 오류 해결용)
-- 일단 모든 사용자가 접근 가능하도록 임시 수정

BEGIN;

-- 1. 모든 기존 정책 완전 삭제
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'reviews' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON reviews';
    END LOOP;
END $$;

-- 2. RLS 비활성화 (임시)
ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;

-- 3. user_id 컬럼이 NULL인 데이터 확인
SELECT COUNT(*) as null_user_id_count FROM reviews WHERE user_id IS NULL;

-- 4. 현재 사용자 확인 (테스트용)
SELECT 
  auth.uid() as current_user_id,
  COUNT(*) as total_reviews
FROM reviews;

-- 5. RLS 다시 활성화
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- 6. 매우 관대한 임시 정책 (테스트용)
CREATE POLICY "temp_allow_all" ON reviews FOR ALL USING (true);

-- 7. 테스트 후 적용할 올바른 정책 (주석 처리)
/*
DROP POLICY "temp_allow_all" ON reviews;

CREATE POLICY "reviews_user_policy" ON reviews 
  FOR ALL USING (
    CASE 
      WHEN auth.uid() IS NULL THEN false
      WHEN user_id IS NULL THEN false  
      ELSE auth.uid() = user_id
    END
  );
*/

COMMIT;

-- 확인
SELECT 'SUCCESS: 임시 RLS 수정 완료 - 모든 사용자 접근 허용' as result;
