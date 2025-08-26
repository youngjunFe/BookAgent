-- 🔒 최종 보안 문제 해결 - 사용자별 데이터 완전 격리
-- "모든 계정에서 발제문이 공유되는 문제" 해결

-- 1. 현재 정책 상태 확인
SELECT 
  tablename,
  policyname,
  cmd,
  qual as "사용 조건"
FROM pg_policies 
WHERE tablename = 'reviews';

-- 2. 위험한 "temp_allow_all" 정책 제거
DROP POLICY IF EXISTS "temp_allow_all" ON reviews;

-- 3. 모든 기존 정책 완전 정리
DROP POLICY IF EXISTS "reviews_select_policy" ON reviews;
DROP POLICY IF EXISTS "reviews_insert_policy" ON reviews;
DROP POLICY IF EXISTS "reviews_update_policy" ON reviews;
DROP POLICY IF EXISTS "reviews_delete_policy" ON reviews;

-- 4. 데이터 확인 (각 사용자별로 데이터가 있는지)
SELECT 
  user_id,
  COUNT(*) as 발제문_개수,
  array_agg(title) as 제목들
FROM reviews 
GROUP BY user_id
ORDER BY user_id;

-- 5. 올바른 보안 정책 재설정
CREATE POLICY "strict_user_select" ON reviews 
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND 
    user_id IS NOT NULL AND 
    auth.uid() = user_id
  );

CREATE POLICY "strict_user_insert" ON reviews 
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND 
    user_id IS NOT NULL AND 
    auth.uid() = user_id
  );

CREATE POLICY "strict_user_update" ON reviews 
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND 
    user_id IS NOT NULL AND 
    auth.uid() = user_id
  );

CREATE POLICY "strict_user_delete" ON reviews 
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND 
    user_id IS NOT NULL AND 
    auth.uid() = user_id
  );

-- 6. RLS 활성화 확인
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- 7. 테스트: 현재 로그인한 사용자만의 데이터 조회
SELECT 
  '현재 사용자 전용 데이터 조회:' as 테스트,
  COUNT(*) as 내_발제문_개수
FROM reviews 
WHERE auth.uid() = user_id;

-- 8. 성공 메시지
SELECT '🔒 보안 정책 완전 재설정 완료! 이제 각 사용자는 자신의 데이터만 볼 수 있습니다.' as result;
