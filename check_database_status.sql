-- 🔍 데이터베이스 보안 상태 진단
-- Supabase SQL Editor에서 이 스크립트를 실행하여 현재 상태를 확인하세요

-- 1. 테이블에 user_id 컬럼이 있는지 확인
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name IN ('reviews', 'ebooks', 'reading_goals')
  AND column_name = 'user_id'
ORDER BY table_name;

-- 2. RLS(Row Level Security)가 활성화되어 있는지 확인
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('reviews', 'ebooks', 'reading_goals', 'achievements');

-- 3. 현재 적용된 RLS 정책들 확인
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('reviews', 'ebooks', 'reading_goals', 'achievements')
ORDER BY tablename, policyname;

-- 4. 각 테이블의 데이터 개수와 user_id 상태 확인
DO $$ 
DECLARE
  review_total INTEGER;
  review_null_user INTEGER;
  ebook_total INTEGER;
  ebook_null_user INTEGER;
  goal_total INTEGER;
  goal_null_user INTEGER;
BEGIN
  -- reviews 테이블 확인
  BEGIN
    SELECT COUNT(*) INTO review_total FROM reviews;
    SELECT COUNT(*) INTO review_null_user FROM reviews WHERE user_id IS NULL;
    RAISE NOTICE '📊 REVIEWS 테이블: 전체 %개, user_id NULL %개', review_total, review_null_user;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '❌ REVIEWS 테이블 오류: %', SQLERRM;
  END;
  
  -- ebooks 테이블 확인
  BEGIN
    SELECT COUNT(*) INTO ebook_total FROM ebooks;
    SELECT COUNT(*) INTO ebook_null_user FROM ebooks WHERE user_id IS NULL;
    RAISE NOTICE '📊 EBOOKS 테이블: 전체 %개, user_id NULL %개', ebook_total, ebook_null_user;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '❌ EBOOKS 테이블 오류: %', SQLERRM;
  END;
  
  -- reading_goals 테이블 확인
  BEGIN
    SELECT COUNT(*) INTO goal_total FROM reading_goals;
    SELECT COUNT(*) INTO goal_null_user FROM reading_goals WHERE user_id IS NULL;
    RAISE NOTICE '📊 READING_GOALS 테이블: 전체 %개, user_id NULL %개', goal_total, goal_null_user;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '❌ READING_GOALS 테이블 오류: %', SQLERRM;
  END;
  
  -- 종합 진단
  IF review_null_user > 0 OR ebook_null_user > 0 OR goal_null_user > 0 THEN
    RAISE NOTICE '🚨 문제 발견! user_id가 NULL인 데이터가 있어서 다른 사용자에게 보일 수 있습니다!';
    RAISE NOTICE '🔧 해결책: fix_security_vulnerability_STRONG.sql을 실행하여 NULL 데이터를 정리하세요.';
  ELSE
    RAISE NOTICE '✅ 데이터 상태는 정상입니다. RLS 정책을 확인하세요.';
  END IF;
END $$;

-- 5. 현재 로그인한 사용자 확인 (있다면)
SELECT 
  COALESCE(auth.uid()::text, 'NOT_LOGGED_IN') as current_user_id,
  CASE 
    WHEN auth.uid() IS NULL THEN '❌ 로그인되지 않음'
    ELSE '✅ 로그인됨'
  END as login_status;
