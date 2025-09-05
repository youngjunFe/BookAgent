-- 🚨 핵폭탄급 해결책 - 트리거 대신 RPC 함수 사용
-- Supabase 트리거가 안 되면 직접 함수 호출로 해결

-- =============================================================================
-- 1. 모든 기존 트리거 완전 제거 (트리거는 포기)
-- =============================================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_safe ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_ultra_safe ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_final ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_simple ON auth.users CASCADE;
DROP TRIGGER IF EXISTS test_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users CASCADE;
DROP TRIGGER IF EXISTS auto_profile_trigger ON auth.users CASCADE;

-- 모든 기존 함수들도 제거
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_safe() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_ultra_safe() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_final() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_simple() CASCADE;
DROP FUNCTION IF EXISTS public.test_new_user_trigger() CASCADE;
DROP FUNCTION IF EXISTS public.create_test_nickname() CASCADE;
DROP FUNCTION IF EXISTS public.generate_simple_nickname(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.auto_create_profile() CASCADE;
DROP FUNCTION IF EXISTS public.make_nickname() CASCADE;

-- =============================================================================
-- 2. RPC 함수로 직접 프로필 생성 (Flutter에서 호출)
-- =============================================================================

-- 닉네임 생성 함수
CREATE OR REPLACE FUNCTION public.generate_nickname()
RETURNS TEXT AS $$
DECLARE
    new_nickname TEXT;
    counter INTEGER := 0;
BEGIN
    LOOP
        new_nickname := '독서가' || (floor(random() * 9999) + 1000)::TEXT;
        
        -- 중복 체크
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.profiles WHERE nickname = new_nickname
        );
        
        counter := counter + 1;
        EXIT WHEN counter > 100; -- 무한 루프 방지
    END LOOP;
    
    -- 혹시나 중복이면 타임스탬프 추가
    IF counter > 100 THEN
        new_nickname := '독서가' || EXTRACT(EPOCH FROM NOW())::BIGINT::TEXT;
    END IF;
    
    RETURN new_nickname;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 3. 사용자 프로필 생성/업데이트 RPC 함수 (Flutter에서 직접 호출)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.ensure_user_profile()
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
    current_email TEXT;
    user_nickname TEXT;
    profile_exists BOOLEAN;
    result JSON;
BEGIN
    -- 현재 사용자 ID 가져오기
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false, 
            'error', '로그인이 필요합니다',
            'code', 'NOT_AUTHENTICATED'
        );
    END IF;
    
    -- 현재 사용자 이메일 가져오기
    SELECT email INTO current_email FROM auth.users WHERE id = current_user_id;
    
    -- 프로필 존재 여부 확인
    SELECT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = current_user_id
    ) INTO profile_exists;
    
    IF profile_exists THEN
        -- 이미 프로필이 있으면 기존 닉네임 반환
        SELECT nickname INTO user_nickname FROM public.profiles WHERE id = current_user_id;
        
        RETURN json_build_object(
            'success', true,
            'action', 'profile_exists',
            'nickname', user_nickname,
            'message', '이미 프로필이 존재합니다'
        );
    ELSE
        -- 프로필이 없으면 새로 생성
        user_nickname := generate_nickname();
        
        INSERT INTO public.profiles (
            id,
            email,
            full_name,
            nickname,
            provider,
            created_at,
            updated_at
        ) VALUES (
            current_user_id,
            current_email,
            user_nickname, -- full_name도 닉네임으로
            user_nickname,
            'email', -- 기본 제공자
            NOW(),
            NOW()
        );
        
        RETURN json_build_object(
            'success', true,
            'action', 'profile_created',
            'nickname', user_nickname,
            'message', '새 프로필이 생성되었습니다'
        );
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'code', SQLSTATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 4. 기존 누락된 프로필들 즉시 생성
-- =============================================================================

DO $$
DECLARE
    missing_user RECORD;
    user_nickname TEXT;
    created_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🛠️ 누락된 프로필들을 생성합니다...';
    
    FOR missing_user IN
        SELECT u.* 
        FROM auth.users u
        LEFT JOIN public.profiles p ON u.id = p.id
        WHERE p.id IS NULL
        ORDER BY u.created_at DESC
    LOOP
        -- 닉네임 생성
        user_nickname := '독서가' || (floor(random() * 9999) + 1000)::TEXT;
        
        -- 중복 체크
        WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = user_nickname) LOOP
            user_nickname := '독서가' || (floor(random() * 9999) + 1000)::TEXT;
        END LOOP;
        
        -- 프로필 생성
        INSERT INTO public.profiles (
            id,
            email,
            full_name,
            nickname,
            provider,
            created_at,
            updated_at
        ) VALUES (
            missing_user.id,
            COALESCE(missing_user.email, 'unknown'),
            user_nickname,
            user_nickname,
            COALESCE(missing_user.raw_app_meta_data->>'provider', 'email'),
            COALESCE(missing_user.created_at, NOW()),
            NOW()
        );
        
        created_count := created_count + 1;
        RAISE NOTICE '✅ 프로필 생성: % -> %', missing_user.email, user_nickname;
    END LOOP;
    
    RAISE NOTICE '🎉 총 % 개의 프로필을 생성했습니다!', created_count;
END $$;

-- =============================================================================
-- 5. RLS 정책 설정 (RPC 함수 접근 허용)
-- =============================================================================

-- RPC 함수들에 대한 실행 권한 부여
GRANT EXECUTE ON FUNCTION public.generate_nickname() TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_user_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_nickname() TO anon;
GRANT EXECUTE ON FUNCTION public.ensure_user_profile() TO anon;

-- =============================================================================
-- 6. 최종 상태 확인
-- =============================================================================

DO $$
DECLARE
    auth_count INTEGER;
    profile_count INTEGER;
    missing_count INTEGER;
    rpc_exists BOOLEAN;
BEGIN
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    SELECT COUNT(*) INTO profile_count FROM public.profiles;
    missing_count := auth_count - profile_count;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'ensure_user_profile'
        AND routine_schema = 'public'
    ) INTO rpc_exists;
    
    RAISE NOTICE '🎯 ========== 최종 결과 ==========';
    RAISE NOTICE '👥 전체 사용자: % 명', auth_count;
    RAISE NOTICE '📝 전체 프로필: % 명', profile_count;
    RAISE NOTICE '❌ 누락된 프로필: % 명', missing_count;
    RAISE NOTICE '🔧 RPC 함수 존재: %', CASE WHEN rpc_exists THEN '✅' ELSE '❌' END;
    
    IF missing_count = 0 AND rpc_exists THEN
        RAISE NOTICE '🎉 완벽! RPC 함수 방식으로 전환 완료!';
        RAISE NOTICE '📱 이제 Flutter 앱에서 ensure_user_profile() 함수를 호출하세요!';
    END IF;
END $$;

-- 완료 메시지
SELECT '🚀 RPC 함수 방식으로 전환 완료! 이제 Flutter 코드를 수정해야 합니다!' AS 완료메시지;
