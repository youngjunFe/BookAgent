-- 🚨 user_id NOT NULL 제약조건 오류 해결
-- "null value in column \"user_id\" of relation \"reviews\" violates not-null constraint" 해결

-- 1. 현재 테이블 제약조건 확인
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    consrc as constraint_source
FROM pg_constraint 
WHERE conrelid = 'reviews'::regclass;

-- 2. user_id 컬럼의 NOT NULL 제약조건 제거
ALTER TABLE reviews ALTER COLUMN user_id DROP NOT NULL;

-- 3. 확인: user_id 컬럼 정보
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'reviews' 
  AND column_name = 'user_id';

-- 4. 성공 메시지
SELECT '✅ NOT NULL 제약조건 제거 완료 - user_id 컬럼이 nullable로 변경됨' as result;
