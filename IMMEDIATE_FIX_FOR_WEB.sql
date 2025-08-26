-- 🚀 웹 배포 버전용 즉시 수정 스크립트
-- Supabase 대시보드 → SQL Editor에서 실행하세요!

-- 1. 현재 테이블 상태 확인
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'reviews'
  AND column_name = 'user_id';

-- 만약 위 결과가 비어있다면 user_id 컬럼이 없는 것 → 아래 실행

-- 2. user_id 컬럼 추가 (없을 경우에만)
ALTER TABLE reviews 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 3. RLS 활성화
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- 4. 기존 잘못된 정책 제거
DROP POLICY IF EXISTS "Users can view own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can insert own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can update own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can delete own reviews" ON reviews;

-- 5. 올바른 RLS 정책 생성
CREATE POLICY "reviews_select_policy" ON reviews 
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "reviews_insert_policy" ON reviews 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "reviews_update_policy" ON reviews 
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "reviews_delete_policy" ON reviews 
  FOR DELETE USING (auth.uid() = user_id);

-- 6. 기존 데이터에 user_id 설정 (첫 번째 사용자에게 할당)
-- ⚠️ 실제 사용자 ID로 바꿔주세요!
-- UPDATE reviews SET user_id = '[실제_사용자_UUID]' WHERE user_id IS NULL;

-- 또는 기존 데이터 삭제 (새로 시작)
-- DELETE FROM reviews WHERE user_id IS NULL;

-- 7. 확인
SELECT 'SUCCESS: 데이터베이스 수정 완료!' as status;
