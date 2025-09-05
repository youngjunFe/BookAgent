-- 🔍 현재 데이터베이스 상태 점검 스크립트
-- 트리거, 함수, 테이블 상태를 모두 확인

-- =============================================================================
-- 1. 현재 활성화된 트리거들 확인
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 ========== 현재 트리거 상태 점검 ==========';
END $$;

-- auth.users 테이블의 모든 트리거 조회
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    trigger_schema,
    event_object_table
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND trigger_schema = 'auth'
ORDER BY trigger_name;

-- =============================================================================
-- 2. 현재 함수들 확인
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '📋 ========== 현재 함수 상태 점검 ==========';
END $$;

-- public 스키마의 닉네임 관련 함수들
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%nickname%' 
OR routine_name LIKE '%user%'
ORDER BY routine_name;

-- =============================================================================
-- 3. profiles 테이블 상태 확인
-- =============================================================================

DO $$
DECLARE
    total_auth_users INT;
    total_profiles INT;
    profiles_with_nickname INT;
    profiles_without_nickname INT;
    unique_nicknames INT;
    duplicate_nicknames INT;
BEGIN
    -- 기본 통계
    SELECT COUNT(*) INTO total_auth_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    SELECT COUNT(*) INTO profiles_with_nickname FROM public.profiles WHERE nickname IS NOT NULL AND nickname != '';
    SELECT COUNT(*) INTO profiles_without_nickname FROM public.profiles WHERE nickname IS NULL OR nickname = '';
    SELECT COUNT(DISTINCT nickname) INTO unique_nicknames FROM public.profiles WHERE nickname IS NOT NULL;
    
    -- 중복 닉네임 개수
    SELECT COUNT(*) INTO duplicate_nicknames FROM (
        SELECT nickname FROM public.profiles 
        WHERE nickname IS NOT NULL 
        GROUP BY nickname 
        HAVING COUNT(*) > 1
    ) duplicates;
    
    RAISE NOTICE '📊 ========== 현재 데이터 현황 ==========';
    RAISE NOTICE '👥 전체 인증 사용자: % 명', total_auth_users;
    RAISE NOTICE '📝 프로필이 있는 사용자: % 명', total_profiles;
    RAISE NOTICE '🏷️  닉네임이 있는 사용자: % 명', profiles_with_nickname;
    RAISE NOTICE '❌ 닉네임이 없는 사용자: % 명', profiles_without_nickname;
    RAISE NOTICE '🎯 고유 닉네임 개수: % 개', unique_nicknames;
    RAISE NOTICE '🔁 중복된 닉네임 그룹: % 개', duplicate_nicknames;
    
    IF total_auth_users > total_profiles THEN
        RAISE NOTICE '⚠️  문제 발견: auth.users에 있지만 profiles에 없는 사용자가 % 명 있습니다!', (total_auth_users - total_profiles);
    END IF;
    
    IF profiles_without_nickname > 0 THEN
        RAISE NOTICE '⚠️  문제 발견: 닉네임이 없는 사용자가 % 명 있습니다!', profiles_without_nickname;
    END IF;
    
    IF duplicate_nicknames > 0 THEN
        RAISE NOTICE '⚠️  문제 발견: 중복된 닉네임이 % 그룹 있습니다!', duplicate_nicknames;
    END IF;
END $$;

-- =============================================================================
-- 4. 누락된 프로필 사용자들 상세 조회
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 ========== 누락된 프로필 상세 조회 ==========';
END $$;

-- auth.users에 있지만 profiles에 없는 사용자들
SELECT 
    'auth.users에 있지만 profiles에 없음' as issue,
    u.id,
    u.email,
    u.created_at,
    u.raw_app_meta_data->>'provider' as provider
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
ORDER BY u.created_at DESC
LIMIT 10;

-- =============================================================================
-- 5. 중복 닉네임 상세 조회
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 ========== 중복 닉네임 상세 조회 ==========';
END $$;

-- 중복된 닉네임들과 해당 사용자들
SELECT 
    nickname,
    COUNT(*) as duplicate_count,
    array_agg(email ORDER BY created_at) as emails,
    array_agg(id ORDER BY created_at) as user_ids
FROM public.profiles 
WHERE nickname IS NOT NULL
GROUP BY nickname 
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, nickname
LIMIT 20;

-- =============================================================================
-- 6. RLS 정책 확인
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔒 ========== RLS 정책 확인 ==========';
END $$;

-- profiles 테이블의 RLS 정책들
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- =============================================================================
-- 7. 최근 생성된 사용자들 상태 확인
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '📅 ========== 최근 사용자 상태 ==========';
END $$;

-- 최근 7일간 생성된 사용자들의 프로필 상태
SELECT 
    u.email,
    u.created_at as auth_created,
    p.nickname,
    p.created_at as profile_created,
    CASE 
        WHEN p.id IS NULL THEN '❌ 프로필 없음'
        WHEN p.nickname IS NULL OR p.nickname = '' THEN '⚠️ 닉네임 없음'
        ELSE '✅ 정상'
    END as status
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE u.created_at > NOW() - INTERVAL '7 days'
ORDER BY u.created_at DESC
LIMIT 20;

RAISE NOTICE '🏁 ========== 점검 완료 ==========';
