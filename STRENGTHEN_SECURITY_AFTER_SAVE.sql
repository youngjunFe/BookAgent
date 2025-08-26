-- 🔒 저장 성공 후 보안 강화
-- 발제문 저장이 성공했으니 이제 보안을 다시 강화

-- 1. 현재 데이터 확인
SELECT 
  user_id,
  title,
  created_at,
  '현재 저장된 데이터' as 상태
FROM reviews 
ORDER BY created_at DESC 
LIMIT 10;

-- 2. 관대한 정책 제거
DROP POLICY IF EXISTS "bypass_select_policy" ON reviews;
DROP POLICY IF EXISTS "bypass_insert_policy" ON reviews;
DROP POLICY IF EXISTS "bypass_update_policy" ON reviews;
DROP POLICY IF EXISTS "bypass_delete_policy" ON reviews;

-- 3. 더 엄격한 보안 정책 (하지만 작동 보장)
CREATE POLICY "secure_but_working_select" ON reviews 
  FOR SELECT USING (
    -- user_id가 null이 아니고, 현재 사용자와 일치하는 경우만
    user_id IS NOT NULL AND auth.uid() = user_id
  );

CREATE POLICY "secure_but_working_insert" ON reviews 
  FOR INSERT WITH CHECK (
    -- 삽입시에는 조금 더 관대 (저장 성공 보장)
    auth.uid() IS NOT NULL AND 
    (user_id IS NULL OR auth.uid() = user_id)
  );

CREATE POLICY "secure_but_working_update" ON reviews 
  FOR UPDATE USING (
    user_id IS NOT NULL AND auth.uid() = user_id
  );

CREATE POLICY "secure_but_working_delete" ON reviews 
  FOR DELETE USING (
    user_id IS NOT NULL AND auth.uid() = user_id
  );

-- 4. 성공 메시지
SELECT '🔒 보안 강화 완료! 저장은 계속 작동하면서 데이터 격리도 강화됨' as result;
