-- 🔍 실시간 트리거 작동 상태 확인 및 강제 수정
-- 왜 profiles 테이블에 데이터가 추가되지 않는지 정확히 진단

-- =============================================================================
-- 1. 현재 트리거 상태 정확히 확인
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 ========== 현재 트리거 상태 점검 시작 ==========';
END $$;

-- auth.users 테이블의 트리거들 확인
SELECT 
    '현재 auth.users 테이블 트리거들' as 상태,
    trigger_name as 트리거명,
    event_manipulation as 이벤트타입,
    action_timing as 실행타이밍,
    action_statement as 함수호출
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND trigger_schema = 'auth';

-- =============================================================================
-- 2. 트리거 함수 존재 여부 확인
-- =============================================================================

DO $$
DECLARE
    function_exists BOOLEAN := FALSE;
    trigger_exists BOOLEAN := FALSE;
BEGIN
    -- 함수 존재 여부 확인
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'handle_new_user_simple' 
        AND routine_schema = 'public'
    ) INTO function_exists;
    
    -- 트리거 존재 여부 확인
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'on_auth_user_created_simple'
        AND event_object_table = 'users'
        AND trigger_schema = 'auth'
    ) INTO trigger_exists;
    
    RAISE NOTICE '📋 함수 존재 여부: %', CASE WHEN function_exists THEN '✅ 존재함' ELSE '❌ 없음' END;
    RAISE NOTICE '📋 트리거 존재 여부: %', CASE WHEN trigger_exists THEN '✅ 존재함' ELSE '❌ 없음' END;
    
    IF NOT function_exists THEN
        RAISE NOTICE '🚨 심각한 문제: 트리거 함수가 존재하지 않습니다!';
    END IF;
    
    IF NOT trigger_exists THEN
        RAISE NOTICE '🚨 심각한 문제: 트리거가 존재하지 않습니다!';
    END IF;
END $$;

-- =============================================================================
-- 3. profiles 테이블 구조 및 RLS 정책 확인
-- =============================================================================

-- profiles 테이블 컬럼 확인
SELECT 
    '현재 profiles 테이블 구조' as 테이블정보,
    column_name as 컬럼명,
    data_type as 타입,
    is_nullable as 널허용여부,
    column_default as 기본값
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- RLS 정책 확인
SELECT 
    '현재 profiles RLS 정책들' as 정책정보,
    policyname as 정책명,
    cmd as 명령타입,
    permissive as 허용여부,
    roles as 적용역할,
    qual as 조건
FROM pg_policies 
WHERE tablename = 'profiles' 
AND schemaname = 'public';

-- =============================================================================
-- 4. 현재 데이터 상태 확인
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
    
    RAISE NOTICE '📊 현재 데이터 상황:';
    RAISE NOTICE '  - auth.users: % 명', auth_count;
    RAISE NOTICE '  - profiles: % 명', profile_count;
    RAISE NOTICE '  - 누락된 프로필: % 명', missing_count;
    
    IF missing_count > 0 THEN
        RAISE NOTICE '🚨 %명의 사용자가 프로필이 없습니다! 트리거가 작동하지 않고 있어요!', missing_count;
    END IF;
END $$;

-- =============================================================================
-- 5. 최근 가입한 사용자들 상세 확인
-- =============================================================================

SELECT 
    '최근 가입자들의 프로필 상태' as 구분,
    u.email as 이메일,
    u.created_at as 가입일시,
    u.raw_app_meta_data->>'provider' as 제공자,
    CASE 
        WHEN p.id IS NULL THEN '❌ 프로필 전혀 없음'
        WHEN p.nickname IS NULL THEN '⚠️ 닉네임 없음'  
        ELSE '✅ 정상: ' || p.nickname
    END as 프로필상태
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id  
ORDER BY u.created_at DESC
LIMIT 5;

-- =============================================================================
-- 6. 강제로 트리거 다시 생성 (확실한 방법)
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 ========== 강제 트리거 재생성 시작 ==========';
END $$;

-- 모든 기존 트리거 완전 제거
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_safe ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_ultra_safe ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_final ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_simple ON auth.users CASCADE;

-- 모든 기존 함수 완전 제거
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_safe() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_ultra_safe() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_final() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_simple() CASCADE;
DROP FUNCTION IF EXISTS public.generate_simple_nickname(UUID) CASCADE;

DO $$
BEGIN
    RAISE NOTICE '✅ 모든 기존 트리거와 함수 완전 제거됨';
END $$;

-- =============================================================================
-- 7. 매우 간단한 테스트용 트리거 생성 (디버깅 강화)
-- =============================================================================

-- 초간단 닉네임 생성 함수
CREATE OR REPLACE FUNCTION public.create_test_nickname()
RETURNS TEXT AS $$
BEGIN
    RETURN '테스트유저' || floor(random() * 9999 + 1)::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 초간단 트리거 함수 (최대한 단순화)
CREATE OR REPLACE FUNCTION public.test_new_user_trigger()
RETURNS TRIGGER AS $$
DECLARE
    simple_nickname TEXT;
BEGIN
    -- 강력한 디버깅 로그
    RAISE NOTICE '🚨🚨🚨 트리거 실행! 사용자: %, 이메일: %', NEW.id, COALESCE(NEW.email, 'null');
    
    -- 간단한 닉네임 생성
    simple_nickname := create_test_nickname();
    RAISE NOTICE '🎯🎯🎯 생성된 닉네임: %', simple_nickname;
    
    -- 프로필 삽입 시도 (매우 간단한 형태)
    BEGIN
        INSERT INTO public.profiles (id, email, nickname, created_at, updated_at)
        VALUES (
            NEW.id, 
            COALESCE(NEW.email, 'unknown@example.com'),
            simple_nickname,
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '✅✅✅ 프로필 생성 성공! 이메일: %, 닉네임: %', NEW.email, simple_nickname;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌❌❌ 프로필 생성 실패! 에러 코드: %, 메시지: %', SQLSTATE, SQLERRM;
        RAISE NOTICE '📋 시도한 데이터: id=%, email=%, nickname=%', NEW.id, NEW.email, simple_nickname;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 테스트 트리거 생성
CREATE TRIGGER test_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.test_new_user_trigger();

DO $$
BEGIN
    RAISE NOTICE '🔥🔥🔥 새 테스트 트리거 생성 완료! 이제 회원가입 테스트해보세요!';
    RAISE NOTICE '📢 회원가입하면 🚨🚨🚨 메시지들이 나타날 겁니다!';
END $$;
