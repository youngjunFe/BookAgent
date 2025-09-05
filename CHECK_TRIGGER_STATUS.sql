-- 🔍 트리거 상태 실시간 확인
-- 왜 회원가입시 트리거가 작동하지 않는지 정확히 진단

-- =============================================================================
-- 1. 현재 트리거 상태 확인
-- =============================================================================

SELECT '🔍 ========== 현재 트리거 상태 점검 ==========' as 상태점검;

-- auth.users 테이블의 모든 트리거들
SELECT 
    trigger_name as "트리거명",
    event_manipulation as "이벤트",
    action_timing as "타이밍",
    action_statement as "실행함수"
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND trigger_schema = 'auth'
ORDER BY trigger_name;

-- =============================================================================
-- 2. 함수 존재 여부 확인
-- =============================================================================

SELECT '📋 ========== 함수 존재 여부 확인 ==========' as 함수확인;

SELECT 
    routine_name as "함수명",
    routine_type as "타입"
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name = 'auto_create_profile' OR routine_name = 'make_nickname')
ORDER BY routine_name;

-- =============================================================================
-- 3. 트리거와 함수의 정확한 매칭 확인
-- =============================================================================

DO $$
DECLARE
    trigger_exists BOOLEAN;
    function_exists BOOLEAN;
    nickname_func_exists BOOLEAN;
BEGIN
    -- 트리거 존재 확인
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'auto_profile_trigger'
        AND event_object_table = 'users'
        AND trigger_schema = 'auth'
    ) INTO trigger_exists;
    
    -- 메인 함수 존재 확인
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'auto_create_profile'
        AND routine_schema = 'public'
    ) INTO function_exists;
    
    -- 닉네임 생성 함수 존재 확인
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'make_nickname'
        AND routine_schema = 'public'
    ) INTO nickname_func_exists;
    
    RAISE NOTICE '🔧 트리거 존재: %', CASE WHEN trigger_exists THEN '✅ YES' ELSE '❌ NO' END;
    RAISE NOTICE '⚙️ 메인 함수 존재: %', CASE WHEN function_exists THEN '✅ YES' ELSE '❌ NO' END;
    RAISE NOTICE '🎯 닉네임 함수 존재: %', CASE WHEN nickname_func_exists THEN '✅ YES' ELSE '❌ NO' END;
    
    IF NOT trigger_exists THEN
        RAISE NOTICE '🚨 심각한 문제: 트리거가 존재하지 않습니다!';
    END IF;
    
    IF NOT function_exists THEN
        RAISE NOTICE '🚨 심각한 문제: 트리거 함수가 존재하지 않습니다!';
    END IF;
END $$;

-- =============================================================================
-- 4. 데이터 상태 확인
-- =============================================================================

DO $$
DECLARE
    auth_count INT;
    profile_count INT;
    missing_count INT;
BEGIN
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    SELECT COUNT(*) INTO profile_count FROM public.profiles;
    missing_count := auth_count - profile_count;
    
    RAISE NOTICE '📊 ========== 데이터 현황 ==========';
    RAISE NOTICE '👥 auth.users: % 명', auth_count;
    RAISE NOTICE '📝 profiles: % 명', profile_count;
    RAISE NOTICE '❌ 누락: % 명', missing_count;
    
    IF missing_count > 0 THEN
        RAISE NOTICE '🚨 %명이 프로필이 없습니다!', missing_count;
    END IF;
END $$;

-- =============================================================================
-- 5. 트리거가 없다면 강제로 다시 생성
-- =============================================================================

DO $$
DECLARE
    trigger_exists BOOLEAN;
    function_exists BOOLEAN;
BEGIN
    -- 다시 한번 체크
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'auto_profile_trigger'
    ) INTO trigger_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'auto_create_profile'
        AND routine_schema = 'public'
    ) INTO function_exists;
    
    IF NOT function_exists THEN
        RAISE NOTICE '🔧 닉네임 함수 재생성 중...';
        
        -- 닉네임 생성 함수
        EXECUTE 'CREATE OR REPLACE FUNCTION public.make_nickname()
        RETURNS TEXT AS $func$
        BEGIN
            RETURN ''독서가'' || floor(random() * 9999 + 1000)::TEXT;
        END;
        $func$ LANGUAGE plpgsql;';
        
        -- 트리거 함수
        EXECUTE 'CREATE OR REPLACE FUNCTION public.auto_create_profile()
        RETURNS TRIGGER AS $func$
        DECLARE
            user_nickname TEXT;
            attempt_count INTEGER := 0;
        BEGIN
            LOOP
                user_nickname := make_nickname();
                EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE nickname = user_nickname);
                attempt_count := attempt_count + 1;
                EXIT WHEN attempt_count > 10;
            END LOOP;
            
            IF attempt_count > 10 THEN
                user_nickname := ''독서가'' || EXTRACT(EPOCH FROM NOW())::BIGINT::TEXT;
            END IF;
            
            INSERT INTO public.profiles (
                id, email, full_name, nickname, provider, created_at, updated_at
            ) VALUES (
                NEW.id,
                COALESCE(NEW.email, ''unknown''),
                COALESCE(NEW.raw_user_meta_data->>''name'', NEW.raw_user_meta_data->>''full_name'', user_nickname),
                user_nickname,
                COALESCE(NEW.raw_app_meta_data->>''provider'', ''email''),
                COALESCE(NEW.created_at, NOW()),
                NOW()
            );
            
            RETURN NEW;
        EXCEPTION WHEN OTHERS THEN
            RETURN NEW;
        END;
        $func$ LANGUAGE plpgsql SECURITY DEFINER;';
        
        RAISE NOTICE '✅ 함수 재생성 완료';
    END IF;
    
    IF NOT trigger_exists THEN
        RAISE NOTICE '🔧 트리거 재생성 중...';
        
        EXECUTE 'CREATE TRIGGER auto_profile_trigger
            AFTER INSERT ON auth.users
            FOR EACH ROW 
            EXECUTE FUNCTION public.auto_create_profile();';
            
        RAISE NOTICE '✅ 트리거 재생성 완료';
    END IF;
END $$;

-- =============================================================================
-- 6. 최종 재확인
-- =============================================================================

SELECT '🎯 ========== 최종 재확인 ==========' as 최종확인;

-- 트리거 최종 상태
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'auto_profile_trigger')
        THEN '✅ 트리거 정상 존재'
        ELSE '❌ 트리거 여전히 없음'
    END as 트리거상태;

-- 함수 최종 상태  
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'auto_create_profile')
        THEN '✅ 함수 정상 존재'
        ELSE '❌ 함수 여전히 없음'
    END as 함수상태;

SELECT '🚀 이제 탈퇴 후 재가입 테스트해보세요!' as 테스트안내;
