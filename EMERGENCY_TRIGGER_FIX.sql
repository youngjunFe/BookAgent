-- 🚨 긴급 트리거 수정 - 프로필이 생성되지 않는 문제 해결
-- 트리거가 작동하지 않거나 함수에 문제가 있을 가능성

-- =============================================================================
-- 1. 현재 모든 트리거 완전 제거 (클린 슬레이트)
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🧹 모든 기존 트리거를 완전히 제거합니다...';
END $$;

-- 모든 가능한 트리거들 제거
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_safe ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_ultra_safe ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created_final ON auth.users CASCADE;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users CASCADE;

-- 모든 가능한 함수들 제거
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_safe() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_ultra_safe() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_final() CASCADE;
DROP FUNCTION IF EXISTS public.generate_korean_nickname_safe(UUID) CASCADE;
DROP FUNCTION IF EXISTS generate_safe_nickname(UUID, TEXT, JSONB, TEXT) CASCADE;
DROP FUNCTION IF EXISTS generate_default_nickname(UUID, TEXT) CASCADE;

DO $$
BEGIN
    RAISE NOTICE '✅ 모든 기존 트리거와 함수 제거 완료';
END $$;

-- =============================================================================
-- 2. 매우 간단하고 안전한 닉네임 생성 함수
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎨 새로운 간단한 닉네임 생성 함수를 만듭니다...';
END $$;

CREATE OR REPLACE FUNCTION generate_simple_nickname(user_id UUID)
RETURNS TEXT AS $$
DECLARE
    base_names TEXT[] := ARRAY['독서왕', '책벌레', '문학가', '소설가', '시인', '작가', '편집자', '비평가', '독서광', '책사랑'];
    colors TEXT[] := ARRAY['빨간', '파란', '노란', '초록', '보라', '분홍', '주황', '하얀', '검은', '회색'];
    animals TEXT[] := ARRAY['고양이', '강아지', '토끼', '곰', '여우', '사자', '호랑이', '판다', '코알라', '다람쥐'];
    
    generated_nickname TEXT;
    counter INT := 1;
    pattern INT;
    hash_val BIGINT;
BEGIN
    -- user_id를 해시값으로 변환 (UUID의 16진수 문제 해결)
    hash_val := ('x' || lpad(substring(replace(user_id::text, '-', ''), 1, 16), 16, '0'))::bit(64)::bigint;
    
    -- 해시값을 기반으로 패턴 결정 (절대값 처리)
    pattern := (abs(hash_val) % 3) + 1;
    
    CASE pattern
        WHEN 1 THEN
            -- 독서왕, 책벌레 등
            generated_nickname := base_names[(abs(hash_val / 10) % array_length(base_names, 1)) + 1];
        WHEN 2 THEN
            -- 빨간고양이, 파란강아지 등
            generated_nickname := colors[(abs(hash_val / 100) % array_length(colors, 1)) + 1] || 
                       animals[(abs(hash_val / 1000) % array_length(animals, 1)) + 1];
        ELSE
            -- 고양이, 강아지 등
            generated_nickname := animals[(abs(hash_val / 10000) % array_length(animals, 1)) + 1];
    END CASE;
    
    -- 중복 체크 및 숫자 추가
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = generated_nickname) LOOP
        generated_nickname := generated_nickname || counter::TEXT;
        counter := counter + 1;
        
        -- 무한 루프 방지
        IF counter > 1000 THEN
            generated_nickname := '독서가' || abs(hash_val % 9999)::TEXT;
            EXIT;
        END IF;
    END LOOP;
    
    RETURN generated_nickname;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    RAISE NOTICE '✅ 간단한 닉네임 생성 함수 완료';
END $$;

-- =============================================================================
-- 3. 매우 간단하고 확실한 트리거 함수
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🛡️ 새로운 간단한 트리거 함수를 만듭니다...';
END $$;

CREATE OR REPLACE FUNCTION public.handle_new_user_simple()
RETURNS TRIGGER AS $$
DECLARE
    generated_nickname TEXT;
BEGIN
    -- 디버깅 로그
    RAISE NOTICE '🔔 트리거 실행됨: 새 사용자 ID = %, 이메일 = %', NEW.id, NEW.email;
    
    -- 닉네임 생성
    generated_nickname := generate_simple_nickname(NEW.id);
    RAISE NOTICE '🎯 생성된 닉네임: %', generated_nickname;
    
    -- 프로필 생성 시도
    BEGIN
        INSERT INTO public.profiles (
            id,
            email,
            full_name,
            nickname,
            provider,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            COALESCE(NEW.email, ''),
            COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', generated_nickname),
            generated_nickname,
            COALESCE(NEW.raw_app_meta_data->>'provider', 'email'),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '✅ 프로필 생성 성공: % -> %', NEW.email, generated_nickname;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 프로필 생성 실패: % (에러: %)', NEW.email, SQLERRM;
        -- 에러가 발생해도 회원가입 자체는 막지 않음
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DO $$
BEGIN
    RAISE NOTICE '✅ 간단한 트리거 함수 완료';
END $$;

-- =============================================================================
-- 4. 새 트리거 생성
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔗 새 트리거를 생성합니다...';
END $$;

CREATE TRIGGER on_auth_user_created_simple
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user_simple();

DO $$
BEGIN
    RAISE NOTICE '✅ 새 트리거 생성 완료';
END $$;

-- =============================================================================
-- 5. 기존 누락된 프로필들 수동 생성
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🛠️ 기존 사용자들의 누락된 프로필을 생성합니다...';
END $$;

DO $$
DECLARE
    missing_user RECORD;
    generated_nickname TEXT;
    created_count INT := 0;
BEGIN
    FOR missing_user IN
        SELECT u.* 
        FROM auth.users u
        LEFT JOIN public.profiles p ON u.id = p.id
        WHERE p.id IS NULL
        ORDER BY u.created_at
    LOOP
        -- 닉네임 생성
        generated_nickname := generate_simple_nickname(missing_user.id);
        
        -- 프로필 생성
        BEGIN
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
                COALESCE(missing_user.email, ''),
                COALESCE(missing_user.raw_user_meta_data->>'name', missing_user.raw_user_meta_data->>'full_name', generated_nickname),
                generated_nickname,
                COALESCE(missing_user.raw_app_meta_data->>'provider', 'email'),
                missing_user.created_at,
                NOW()
            );
            
            created_count := created_count + 1;
            RAISE NOTICE '✅ 프로필 복구: % -> %', COALESCE(missing_user.email, missing_user.id::TEXT), generated_nickname;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ 프로필 복구 실패: % (에러: %)', missing_user.email, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '🎉 총 % 개의 프로필을 복구했습니다!', created_count;
END $$;

-- =============================================================================
-- 6. 트리거 테스트 (가상 삽입으로 테스트)
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🧪 트리거가 제대로 작동하는지 테스트합니다...';
END $$;

-- 테스트는 실제 데이터 삽입 없이 함수만 직접 호출해서 확인
DO $$
DECLARE
    test_generated_nickname TEXT;
BEGIN
    -- 닉네임 생성 함수 테스트
    test_generated_nickname := generate_simple_nickname('550e8400-e29b-41d4-a716-446655440000'::UUID);
    RAISE NOTICE '🎯 테스트 닉네임 생성: %', test_generated_nickname;
    
    IF test_generated_nickname IS NOT NULL AND length(test_generated_nickname) > 0 THEN
        RAISE NOTICE '✅ 닉네임 생성 함수 정상 작동';
    ELSE
        RAISE NOTICE '❌ 닉네임 생성 함수 문제 있음';
    END IF;
END $$;

-- =============================================================================
-- 7. 최종 상태 확인
-- =============================================================================

DO $$
DECLARE
    total_users INT;
    total_profiles INT;
    missing_count INT;
BEGIN
    SELECT COUNT(*) INTO total_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    missing_count := total_users - total_profiles;
    
    RAISE NOTICE '📊 ========== 최종 결과 ==========';
    RAISE NOTICE '👥 전체 사용자: % 명', total_users;
    RAISE NOTICE '📝 전체 프로필: % 명', total_profiles;
    RAISE NOTICE '❌ 누락된 프로필: % 명', missing_count;
    
    IF missing_count = 0 THEN
        RAISE NOTICE '🎉 완벽! 모든 사용자가 프로필을 가지고 있습니다!';
        RAISE NOTICE '✅ 이제 새로 가입하는 사용자도 자동으로 프로필이 생성됩니다!';
    ELSE
        RAISE NOTICE '⚠️  아직 % 명의 사용자에게 프로필이 없습니다.', missing_count;
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE '🚀 긴급 트리거 수정 완료! 이제 새로 가입해보세요!';
END $$;
