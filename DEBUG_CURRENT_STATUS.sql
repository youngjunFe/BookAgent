-- 🔍 현재 데이터베이스 상태 정확히 진단하기
-- 트리거가 제대로 작동하지 않는 문제 해결

-- =============================================================================
-- 1. 현재 활성화된 트리거들 확인
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 ========== 현재 트리거 상태 점검 ==========';
END $$;

SELECT 
    'auth.users 테이블의 트리거들' as 구분,
    trigger_name as 트리거명,
    event_manipulation as 이벤트,
    action_timing as 타이밍,
    action_statement as 실행함수
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND trigger_schema = 'auth'
ORDER BY trigger_name;

-- =============================================================================
-- 2. 현재 함수들 확인
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 ========== 현재 함수 상태 점검 ==========';
END $$;

SELECT 
    'public 스키마의 사용자 관련 함수들' as 구분,
    routine_name as 함수명,
    routine_type as 타입
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name LIKE '%user%' OR routine_name LIKE '%nickname%')
ORDER BY routine_name;

-- =============================================================================
-- 3. 현재 사용자 및 프로필 데이터 현황
-- =============================================================================

DO $$
DECLARE
    total_auth_users INT;
    total_profiles INT;
    profiles_with_nickname INT;
    missing_profiles INT;
BEGIN
    SELECT COUNT(*) INTO total_auth_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    SELECT COUNT(*) INTO profiles_with_nickname FROM public.profiles WHERE nickname IS NOT NULL AND nickname != '';
    missing_profiles := total_auth_users - total_profiles;
    
    RAISE NOTICE '📊 ========== 현재 데이터 현황 ==========';
    RAISE NOTICE '👥 전체 auth.users: % 명', total_auth_users;
    RAISE NOTICE '📝 전체 profiles: % 명', total_profiles;
    RAISE NOTICE '🏷️  닉네임 보유: % 명', profiles_with_nickname;
    RAISE NOTICE '❌ 누락된 프로필: % 명', missing_profiles;
    
    IF missing_profiles > 0 THEN
        RAISE NOTICE '🚨 심각한 문제: 트리거가 작동하지 않고 있습니다!';
    END IF;
END $$;

-- =============================================================================
-- 4. 최근 생성된 사용자들의 프로필 상태 확인
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 ========== 최근 사용자들 상태 ==========';
END $$;

SELECT 
    '최근 가입한 사용자들의 프로필 상태' as 구분,
    u.email as 이메일,
    u.created_at as 가입일시,
    CASE 
        WHEN p.id IS NULL THEN '❌ 프로필 없음'
        WHEN p.nickname IS NULL OR p.nickname = '' THEN '⚠️ 닉네임 없음'
        ELSE '✅ 정상: ' || p.nickname
    END as 프로필상태
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
ORDER BY u.created_at DESC
LIMIT 10;

-- =============================================================================
-- 5. 트리거 함수가 실제로 존재하는지 확인
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 ========== 트리거 함수 존재 여부 확인 ==========';
END $$;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'handle_new_user_final' AND routine_schema = 'public') 
        THEN '✅ handle_new_user_final 함수 존재'
        ELSE '❌ handle_new_user_final 함수 없음'
    END as 함수상태;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'generate_korean_nickname_safe' AND routine_schema = 'public') 
        THEN '✅ generate_korean_nickname_safe 함수 존재'
        ELSE '❌ generate_korean_nickname_safe 함수 없음'
    END as 닉네임생성함수상태;
