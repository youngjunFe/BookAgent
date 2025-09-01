-- 🗑️ 삭제된 사용자 데이터 정리 및 재가입 활성화
-- Supabase에서 삭제한 계정의 잔여 데이터 제거

-- =============================================================================
-- 1. 고아 데이터 식별 및 정리
-- =============================================================================

-- auth.users에는 없지만 profiles에는 남아있는 데이터 찾기
DO $$
DECLARE
    orphan_count INT;
    orphan_record RECORD;
BEGIN
    -- 고아 데이터 개수 확인
    SELECT COUNT(*) INTO orphan_count 
    FROM public.profiles p 
    WHERE p.id NOT IN (
        SELECT COALESCE(u.id, '00000000-0000-0000-0000-000000000000'::uuid) 
        FROM auth.users u
    );
    
    RAISE NOTICE '🔍 발견된 고아 프로필 데이터: % 개', orphan_count;
    
    -- 고아 데이터 상세 정보 출력
    FOR orphan_record IN 
        SELECT id, email, nickname, provider, created_at
        FROM public.profiles p 
        WHERE p.id NOT IN (
            SELECT COALESCE(u.id, '00000000-0000-0000-0000-000000000000'::uuid) 
            FROM auth.users u
        )
    LOOP
        RAISE NOTICE '🗑️ 삭제 예정: % (%) - 닉네임: %, 생성일: %', 
                     orphan_record.email, 
                     orphan_record.provider,
                     orphan_record.nickname,
                     orphan_record.created_at;
    END LOOP;
END $$;

-- =============================================================================
-- 2. 고아 데이터 안전하게 삭제
-- =============================================================================

-- 관련 테이블들에서도 함께 정리 (있다면)
DO $$
DECLARE
    deleted_count INT := 0;
BEGIN
    -- reviews 테이블에서 고아 데이터 삭제 (있다면)
    DELETE FROM public.reviews 
    WHERE user_id NOT IN (
        SELECT COALESCE(u.id, '00000000-0000-0000-0000-000000000000'::uuid) 
        FROM auth.users u
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    IF deleted_count > 0 THEN
        RAISE NOTICE '🗑️ reviews 테이블에서 % 개 고아 데이터 삭제', deleted_count;
    END IF;
    
    -- reading_goals 테이블에서 고아 데이터 삭제 (있다면)
    DELETE FROM public.reading_goals 
    WHERE user_id NOT IN (
        SELECT COALESCE(u.id, '00000000-0000-0000-0000-000000000000'::uuid) 
        FROM auth.users u
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    IF deleted_count > 0 THEN
        RAISE NOTICE '🗑️ reading_goals 테이블에서 % 개 고아 데이터 삭제', deleted_count;
    END IF;
    
    -- ebooks 테이블에서 고아 데이터 삭제 (있다면)
    DELETE FROM public.ebooks 
    WHERE user_id NOT IN (
        SELECT COALESCE(u.id, '00000000-0000-0000-0000-000000000000'::uuid) 
        FROM auth.users u
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    IF deleted_count > 0 THEN
        RAISE NOTICE '🗑️ ebooks 테이블에서 % 개 고아 데이터 삭제', deleted_count;
    END IF;
END $$;

-- 마지막으로 profiles 테이블에서 고아 데이터 삭제
DO $$
DECLARE
    deleted_count INT := 0;
BEGIN
    DELETE FROM public.profiles 
    WHERE id NOT IN (
        SELECT COALESCE(u.id, '00000000-0000-0000-0000-000000000000'::uuid) 
        FROM auth.users u
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '🗑️ profiles 테이블에서 % 개 고아 데이터 삭제 완료', deleted_count;
END $$;

-- =============================================================================
-- 3. 이메일 중복 방지를 위한 부분 유니크 인덱스 생성
-- =============================================================================

-- 기존 인덱스들 정리
DROP INDEX IF EXISTS korean_nickname_partial_idx;
DROP INDEX IF EXISTS korean_nickname_idx;
DROP INDEX IF EXISTS safe_nickname_idx;
DROP INDEX IF EXISTS nickname_unique_idx;
DROP INDEX IF EXISTS idx_profiles_nickname;

-- 이메일 중복 방지 인덱스 (NULL 제외)
CREATE UNIQUE INDEX profiles_email_unique_idx 
ON public.profiles(email) 
WHERE email IS NOT NULL AND email != '';

-- 닉네임 중복 방지 인덱스 (NULL 제외)
CREATE UNIQUE INDEX profiles_nickname_unique_idx 
ON public.profiles(nickname) 
WHERE nickname IS NOT NULL AND nickname != '';

RAISE NOTICE '✅ 이메일 및 닉네임 중복 방지 인덱스 생성 완료';

-- =============================================================================
-- 4. 더 안전한 사용자 생성 트리거 (중복 처리 강화)
-- =============================================================================

-- 기존 트리거 제거
DROP TRIGGER IF EXISTS on_auth_user_created_safe ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user_safe() CASCADE;

-- 중복 처리가 강화된 초안전 트리거
CREATE OR REPLACE FUNCTION public.handle_new_user_ultra_safe()
RETURNS TRIGGER AS $$
DECLARE
    safe_nickname TEXT;
    safe_email TEXT;
    attempt_count INT := 1;
    base_nickname TEXT;
BEGIN
    RAISE NOTICE '👤 새 사용자 프로필 생성 시작: %', NEW.email;
    
    -- 이메일 안전 처리
    safe_email := COALESCE(NEW.email, '');
    
    -- 1. 기존 같은 이메일 프로필이 있는지 확인하고 제거
    IF safe_email != '' THEN
        DELETE FROM public.profiles WHERE email = safe_email;
        IF FOUND THEN
            RAISE NOTICE '🗑️ 기존 같은 이메일 프로필 삭제: %', safe_email;
        END IF;
    END IF;
    
    -- 2. 안전한 닉네임 생성
    BEGIN
        IF safe_email != '' THEN
            base_nickname := split_part(safe_email, '@', 1);
            base_nickname := regexp_replace(base_nickname, '[^가-힣a-zA-Z0-9]', '', 'g');
        ELSE
            base_nickname := 'user';
        END IF;
        
        IF length(base_nickname) < 2 THEN
            base_nickname := 'user';
        END IF;
        
        IF length(base_nickname) > 10 THEN
            base_nickname := left(base_nickname, 10);
        END IF;
        
        safe_nickname := base_nickname;
        
        -- 중복 체크 및 해결
        WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = safe_nickname) AND attempt_count <= 1000 LOOP
            safe_nickname := base_nickname || attempt_count::TEXT;
            attempt_count := attempt_count + 1;
        END LOOP;
        
        -- 그래도 중복이면 UUID 기반
        IF EXISTS (SELECT 1 FROM public.profiles WHERE nickname = safe_nickname) THEN
            safe_nickname := 'user' || substring(NEW.id::TEXT, 1, 8);
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        safe_nickname := 'user' || substring(NEW.id::TEXT, 1, 8);
        RAISE NOTICE '⚠️ 닉네임 생성 실패, UUID 기반 사용: %', safe_nickname;
    END;
    
    -- 3. 프로필 생성 (모든 에러 처리)
    BEGIN
        INSERT INTO public.profiles (
            id, email, full_name, avatar_url, provider, nickname, created_at, updated_at
        ) VALUES (
            NEW.id,
            safe_email,
            COALESCE(
                NEW.raw_user_meta_data->>'full_name',
                NEW.raw_user_meta_data->>'name',
                CASE WHEN safe_email != '' THEN split_part(safe_email, '@', 1) ELSE '사용자' END
            ),
            COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture'),
            COALESCE(NEW.raw_app_meta_data->>'provider', 'email'),
            safe_nickname,
            COALESCE(NEW.created_at, NOW()),
            COALESCE(NEW.updated_at, NOW())
        );
        
        RAISE NOTICE '✅ 사용자 프로필 생성 성공: % (닉네임: %)', safe_email, safe_nickname;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 프로필 생성 실패하지만 회원가입은 계속: % - %', SQLERRM, SQLSTATE;
        -- 에러가 발생해도 회원가입 자체는 막지 않음
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 새로운 초안전 트리거 생성
CREATE TRIGGER on_auth_user_created_ultra_safe
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user_ultra_safe();

-- =============================================================================
-- 5. 수동으로 누락된 프로필 복구
-- =============================================================================

-- auth.users에는 있지만 profiles에는 없는 사용자들 처리
INSERT INTO public.profiles (id, email, full_name, provider, nickname, created_at, updated_at)
SELECT 
    u.id,
    COALESCE(u.email, ''),
    COALESCE(
        u.raw_user_meta_data->>'full_name',
        u.raw_user_meta_data->>'name',
        CASE WHEN u.email IS NOT NULL THEN split_part(u.email, '@', 1) ELSE '사용자' END
    ),
    COALESCE(u.raw_app_meta_data->>'provider', 'email'),
    -- 간단한 닉네임 (중복 시 자동으로 숫자 추가됨)
    COALESCE(
        split_part(u.email, '@', 1),
        'user'
    ) || substring(u.id::TEXT, 1, 4),
    COALESCE(u.created_at, NOW()),
    COALESCE(u.updated_at, NOW())
FROM auth.users u
WHERE u.id NOT IN (SELECT COALESCE(id, '00000000-0000-0000-0000-000000000000'::uuid) FROM public.profiles)
ON CONFLICT (email) DO NOTHING
ON CONFLICT (nickname) DO NOTHING;

-- =============================================================================
-- 6. 최종 상태 보고
-- =============================================================================

DO $$
DECLARE
    auth_count INT;
    profile_count INT;
    missing_count INT;
BEGIN
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    SELECT COUNT(*) INTO profile_count FROM public.profiles;
    
    SELECT COUNT(*) INTO missing_count
    FROM auth.users u 
    WHERE u.id NOT IN (SELECT COALESCE(id, '00000000-0000-0000-0000-000000000000'::uuid) FROM public.profiles);
    
    RAISE NOTICE '🧹========================================🧹';
    RAISE NOTICE '✅ 삭제된 사용자 데이터 정리 완료!';
    RAISE NOTICE '📊 정리 후 상태:';
    RAISE NOTICE '  - auth.users: % 명', auth_count;
    RAISE NOTICE '  - profiles: % 명', profile_count;
    RAISE NOTICE '  - 누락 프로필: % 명', missing_count;
    
    RAISE NOTICE '🔧 적용된 수정사항:';
    RAISE NOTICE '  - 고아 데이터 완전 삭제';
    RAISE NOTICE '  - 이메일/닉네임 중복 방지 강화';
    RAISE NOTICE '  - 초안전 재가입 트리거 적용';
    RAISE NOTICE '  - 기존 이메일과의 충돌 자동 해결';
    
    IF missing_count = 0 THEN
        RAISE NOTICE '🎯 이제 카카오 재가입이 정상 작동합니다!';
    ELSE
        RAISE NOTICE '⚠️ % 명의 프로필 생성 재시도 필요', missing_count;
    END IF;
    
    RAISE NOTICE '🧹========================================🧹';
END $$;
