-- 🚀 가장 간단하고 안전한 최종 수정 스크립트
-- 복잡한 문법 없이 확실하게 문제 해결

-- =============================================================================
-- 1. 모든 문제 원인 제거 (깔끔하게 정리)
-- =============================================================================

-- 모든 기존 트리거와 함수 완전 제거
DROP TRIGGER IF EXISTS on_auth_user_created_ultra_safe ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_safe ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS nickname_validation_trigger ON public.profiles;

DROP FUNCTION IF EXISTS public.handle_new_user_ultra_safe() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_safe() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS check_nickname_before_update() CASCADE;
DROP FUNCTION IF EXISTS generate_korean_nickname(uuid) CASCADE;
DROP FUNCTION IF EXISTS generate_safe_nickname(uuid, text, jsonb, text) CASCADE;
DROP FUNCTION IF EXISTS generate_default_nickname(uuid, text) CASCADE;

-- 모든 제약조건 제거
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS korean_nickname_unique;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_nickname_unique;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS unique_nickname;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS nickname_must_be_unique;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS safe_nickname_unique;

-- 모든 인덱스 제거
DROP INDEX IF EXISTS profiles_email_unique_idx;
DROP INDEX IF EXISTS profiles_nickname_unique_idx;
DROP INDEX IF EXISTS korean_nickname_partial_idx;
DROP INDEX IF EXISTS korean_nickname_idx;
DROP INDEX IF EXISTS safe_nickname_idx;
DROP INDEX IF EXISTS nickname_unique_idx;
DROP INDEX IF EXISTS idx_profiles_nickname;

-- =============================================================================
-- 2. 고아 데이터 완전 삭제 (문제의 근본 원인 제거)
-- =============================================================================

-- profiles 테이블에서 auth.users에 없는 데이터 모두 삭제
DELETE FROM public.profiles 
WHERE id NOT IN (SELECT id FROM auth.users);

-- =============================================================================
-- 3. 가장 간단한 프로필 생성 (에러 없음 보장)
-- =============================================================================

-- auth.users에 있지만 profiles에 없는 사용자들 간단하게 추가
INSERT INTO public.profiles (id, email, full_name, nickname)
SELECT 
    u.id,
    u.email,
    split_part(u.email, '@', 1),
    split_part(u.email, '@', 1) || substring(u.id::text, 1, 6)
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- =============================================================================
-- 4. 아무 트리거도 생성하지 않음 (에러 방지)
-- =============================================================================

-- 트리거 없이 수동으로만 관리
-- 회원가입 시 앱에서 직접 프로필 생성하도록 변경

-- =============================================================================
-- 5. 최종 확인
-- =============================================================================

-- 간단한 상태 확인
SELECT 
    'auth.users 사용자 수: ' || COUNT(*)::text as auth_count
FROM auth.users
UNION ALL
SELECT 
    'profiles 사용자 수: ' || COUNT(*)::text as profile_count  
FROM public.profiles
UNION ALL
SELECT 
    '누락 프로필 수: ' || COUNT(*)::text as missing_count
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;
