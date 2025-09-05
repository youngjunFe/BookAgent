-- 🎯 단순하고 확실한 트리거 - API 호출 없이 자동으로
-- Supabase 권한 문제 해결 + 가장 간단한 트리거

-- =============================================================================
-- 1. Supabase 특화 권한 설정부터
-- =============================================================================

-- public 스키마에 대한 권한 확인
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, service_role;

-- auth 스키마 접근 권한 (service_role만)
GRANT USAGE ON SCHEMA auth TO service_role;

-- =============================================================================
-- 2. 기존 트리거 완전 정리
-- =============================================================================

DO $$
BEGIN
    -- 모든 트리거 제거
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
    DROP TRIGGER IF EXISTS on_auth_user_created_safe ON auth.users CASCADE;
    DROP TRIGGER IF EXISTS on_auth_user_created_ultra_safe ON auth.users CASCADE;
    DROP TRIGGER IF EXISTS on_auth_user_created_final ON auth.users CASCADE;
    DROP TRIGGER IF EXISTS on_auth_user_created_simple ON auth.users CASCADE;
    DROP TRIGGER IF EXISTS test_auth_user_created ON auth.users CASCADE;
    DROP TRIGGER IF EXISTS auto_profile_trigger ON auth.users CASCADE;
    
    -- 모든 함수 제거
    DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
    DROP FUNCTION IF EXISTS public.handle_new_user_safe() CASCADE;
    DROP FUNCTION IF EXISTS public.handle_new_user_ultra_safe() CASCADE;
    DROP FUNCTION IF EXISTS public.handle_new_user_final() CASCADE;
    DROP FUNCTION IF EXISTS public.handle_new_user_simple() CASCADE;
    DROP FUNCTION IF EXISTS public.test_new_user_trigger() CASCADE;
    DROP FUNCTION IF EXISTS public.auto_create_profile() CASCADE;
    DROP FUNCTION IF EXISTS public.make_nickname() CASCADE;
    DROP FUNCTION IF EXISTS public.generate_nickname() CASCADE;
    DROP FUNCTION IF EXISTS public.ensure_user_profile() CASCADE;
    
    RAISE NOTICE '✅ 모든 기존 트리거와 함수 제거 완료';
END $$;

-- =============================================================================
-- 3. 매우 단순한 트리거 (권한 문제 최소화)
-- =============================================================================

-- 단순한 트리거 함수 (service_role 권한으로)
CREATE OR REPLACE FUNCTION public.simple_user_handler()
RETURNS TRIGGER 
SECURITY DEFINER -- 함수 소유자(postgres) 권한으로 실행
LANGUAGE plpgsql
AS $$
DECLARE
    new_nick TEXT;
    counter INT := 1;
BEGIN
    -- 기본 닉네임 생성
    new_nick := '독서가' || (1000 + floor(random() * 9000))::TEXT;
    
    -- 중복 체크 (최대 10번 시도)
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = new_nick) AND counter <= 10 LOOP
        new_nick := '독서가' || (1000 + floor(random() * 9000))::TEXT;
        counter := counter + 1;
    END LOOP;
    
    -- 그래도 중복이면 타임스탬프 추가
    IF counter > 10 THEN
        new_nick := '독서가' || (EXTRACT(EPOCH FROM NOW())::BIGINT % 10000)::TEXT;
    END IF;
    
    -- 프로필 생성 (에러 무시)
    BEGIN
        INSERT INTO public.profiles (
            id, 
            email, 
            nickname, 
            full_name,
            provider,
            created_at, 
            updated_at
        ) VALUES (
            NEW.id, 
            COALESCE(NEW.email, 'unknown'), 
            new_nick,
            new_nick,
            COALESCE(NEW.raw_app_meta_data->>'provider', 'email'),
            NOW(), 
            NOW()
        );
    EXCEPTION WHEN OTHERS THEN
        -- 에러 발생해도 회원가입 계속 진행
        NULL;
    END;
    
    RETURN NEW;
END;
$$;

-- 함수에 대한 권한 설정
ALTER FUNCTION public.simple_user_handler() OWNER TO postgres;
GRANT EXECUTE ON FUNCTION public.simple_user_handler() TO service_role;

-- =============================================================================
-- 4. 트리거 생성 (service_role 권한으로)
-- =============================================================================

CREATE TRIGGER simple_profile_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.simple_user_handler();

-- 트리거 소유자 설정
ALTER TRIGGER simple_profile_trigger ON auth.users OWNER TO postgres;

-- =============================================================================
-- 5. 기존 누락 사용자 처리
-- =============================================================================

DO $$
DECLARE
    missing_user RECORD;
    user_nick TEXT;
    fixed_count INT := 0;
BEGIN
    FOR missing_user IN 
        SELECT u.id, u.email, u.created_at, u.raw_app_meta_data
        FROM auth.users u
        LEFT JOIN public.profiles p ON u.id = p.id
        WHERE p.id IS NULL
        ORDER BY u.created_at DESC
    LOOP
        user_nick := '독서가' || (1000 + floor(random() * 9000))::TEXT;
        
        -- 중복 체크
        WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = user_nick) LOOP
            user_nick := '독서가' || (1000 + floor(random() * 9000))::TEXT;
        END LOOP;
        
        -- 프로필 생성
        INSERT INTO public.profiles (
            id, email, nickname, full_name, provider, created_at, updated_at
        ) VALUES (
            missing_user.id,
            COALESCE(missing_user.email, 'unknown'),
            user_nick,
            user_nick, 
            COALESCE(missing_user.raw_app_meta_data->>'provider', 'email'),
            missing_user.created_at,
            NOW()
        );
        
        fixed_count := fixed_count + 1;
    END LOOP;
    
    RAISE NOTICE '🎉 % 명의 누락된 프로필 생성 완료', fixed_count;
END $$;

-- =============================================================================
-- 6. 최종 확인
-- =============================================================================

DO $$
DECLARE
    total_users INT;
    total_profiles INT;
    trigger_exists BOOLEAN;
    function_exists BOOLEAN;
BEGIN
    SELECT COUNT(*) INTO total_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'simple_profile_trigger'
    ) INTO trigger_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'simple_user_handler'
    ) INTO function_exists;
    
    RAISE NOTICE '📊 사용자: % 명, 프로필: % 명', total_users, total_profiles;
    RAISE NOTICE '🔧 트리거: %, 함수: %', 
        CASE WHEN trigger_exists THEN '✅' ELSE '❌' END,
        CASE WHEN function_exists THEN '✅' ELSE '❌' END;
        
    IF total_users = total_profiles AND trigger_exists AND function_exists THEN
        RAISE NOTICE '🎉 완벽! API 호출 없이 자동 프로필 생성 준비 완료!';
    END IF;
END $$;
