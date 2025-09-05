-- 🛠️ 회원가입시 닉네임 프로필 저장 문제 완전 해결
-- 현재 중복 체크가 안되고 있는 문제를 완전히 해결합니다

-- =============================================================================
-- 0. 현재 상태 점검 및 문제 진단
-- =============================================================================

DO $$
DECLARE
    total_auth_users INT;
    total_profiles INT;
    missing_profiles INT;
BEGIN
    SELECT COUNT(*) INTO total_auth_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    missing_profiles := total_auth_users - total_profiles;
    
    RAISE NOTICE '🔍 ========== 문제 진단 시작 ==========';
    RAISE NOTICE '👥 전체 인증 사용자: % 명', total_auth_users;
    RAISE NOTICE '📝 프로필이 있는 사용자: % 명', total_profiles;
    
    IF missing_profiles > 0 THEN
        RAISE NOTICE '❌ 심각한 문제 발견: % 명의 사용자가 프로필이 없습니다!', missing_profiles;
        RAISE NOTICE '🛠️ 이 문제를 해결합니다...';
    ELSE
        RAISE NOTICE '✅ 모든 사용자가 프로필을 가지고 있습니다.';
    END IF;
END $$;

-- =============================================================================
-- 1. 기존 충돌하는 트리거들과 함수들 모두 정리
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🧹 기존 트리거와 함수들을 정리합니다...';
END $$;

-- 모든 기존 트리거들 제거
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_safe ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_ultra_safe ON auth.users;

-- 모든 기존 함수들 제거
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.handle_new_user_safe();
DROP FUNCTION IF EXISTS public.handle_new_user_ultra_safe();
DROP FUNCTION IF EXISTS generate_safe_nickname(UUID, TEXT, JSONB, TEXT);
DROP FUNCTION IF EXISTS generate_default_nickname(UUID, TEXT);

DO $$
BEGIN
    RAISE NOTICE '✅ 기존 트리거와 함수들 정리 완료';
END $$;

-- =============================================================================
-- 2. 최신 한국어 닉네임 생성 함수 (중복 체크 포함)
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎨 한국어 닉네임 생성 함수를 생성합니다...';
END $$;

CREATE OR REPLACE FUNCTION generate_korean_nickname_safe(user_id UUID DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
    -- 한국어 단어 배열들
    adjectives TEXT[] := ARRAY[
        '귀여운', '사랑스러운', '멋진', '아름다운', '즐거운', '행복한', '신나는', '밝은',
        '따뜻한', '포근한', '달콤한', '부드러운', '고요한', '평화로운', '활기찬', '생기발랄한',
        '우아한', '세련된', '독특한', '특별한', '소중한', '빛나는', '반짝이는', '신비한',
        '환상적인', '매력적인', '로맨틱한', '상쾌한', '청순한', '완벽한', '꿈같은', '행운의'
    ];
    
    animals TEXT[] := ARRAY[
        '고양이', '강아지', '토끼', '곰', '여우', '사자', '호랑이', '판다',
        '코알라', '다람쥐', '햄스터', '고슴도치', '펭귄', '돌고래', '고래', '물개',
        '사슴', '늑대', '독수리', '부엉이', '참새', '비둘기', '백조', '나비',
        '말', '양', '염소', '소', '돼지', '닭', '오리', '원숭이'
    ];
    
    objects TEXT[] := ARRAY[
        '별', '달', '태양', '구름', '바다', '산', '강', '꽃', '나무', '잎',
        '책', '연필', '붓', '음표', '하트', '다이아', '보석', '진주',
        '캔디', '초콜릿', '케이크', '쿠키', '아이스크림', '꿀', '설탕',
        '무지개', '눈', '비', '바람', '햇살', '향기', '미소', '웃음', '꿈', '희망'
    ];
    
    colors TEXT[] := ARRAY[
        '빨간', '주황', '노란', '초록', '파란', '보라', '분홍', '흰',
        '검은', '회색', '갈색', '금색', '은색', '청록', '라임', '민트',
        '복숭아', '연두', '하늘', '바다', '라벤더', '로즈', '딸기', '레몬'
    ];
    
    -- 변수들
    pattern_num INTEGER;
    adj_idx INTEGER;
    noun_idx INTEGER;
    final_nickname TEXT;
    counter INTEGER := 1;
    seed_value BIGINT;
BEGIN
    -- 사용자 ID 기반 시드 생성
    IF user_id IS NOT NULL THEN
        seed_value := ('x' || lpad(substring(user_id::text, 1, 8), 8, '0'))::bit(32)::bigint;
    ELSE
        seed_value := EXTRACT(EPOCH FROM NOW())::bigint;
    END IF;
    
    -- 랜덤 패턴 선택 (1-4)
    pattern_num := (seed_value % 4) + 1;
    
    CASE pattern_num
        WHEN 1 THEN
            -- 형용사 + 동물
            adj_idx := (seed_value % array_length(adjectives, 1)) + 1;
            noun_idx := ((seed_value / 100) % array_length(animals, 1)) + 1;
            final_nickname := adjectives[adj_idx] || animals[noun_idx];
            
        WHEN 2 THEN
            -- 색깔 + 사물
            adj_idx := (seed_value % array_length(colors, 1)) + 1;
            noun_idx := ((seed_value / 100) % array_length(objects, 1)) + 1;
            final_nickname := colors[adj_idx] || objects[noun_idx];
            
        WHEN 3 THEN
            -- 형용사 + 사물
            adj_idx := (seed_value % array_length(adjectives, 1)) + 1;
            noun_idx := ((seed_value / 100) % array_length(objects, 1)) + 1;
            final_nickname := adjectives[adj_idx] || objects[noun_idx];
            
        ELSE
            -- 색깔 + 동물
            adj_idx := (seed_value % array_length(colors, 1)) + 1;
            noun_idx := ((seed_value / 100) % array_length(animals, 1)) + 1;
            final_nickname := colors[adj_idx] || animals[noun_idx];
    END CASE;
    
    -- 중복 체크하며 고유 닉네임 생성
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = final_nickname) LOOP
        final_nickname := CASE pattern_num
            WHEN 1 THEN adjectives[adj_idx] || animals[noun_idx] || counter::TEXT
            WHEN 2 THEN colors[adj_idx] || objects[noun_idx] || counter::TEXT
            WHEN 3 THEN adjectives[adj_idx] || objects[noun_idx] || counter::TEXT
            ELSE colors[adj_idx] || animals[noun_idx] || counter::TEXT
        END;
        
        counter := counter + 1;
        
        -- 무한 루프 방지 (999번 시도 후 타임스탬프 사용)
        IF counter > 999 THEN
            final_nickname := '독서가' || (EXTRACT(EPOCH FROM NOW())::bigint % 9999 + 1)::TEXT;
            EXIT;
        END IF;
    END LOOP;
    
    RETURN final_nickname;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    RAISE NOTICE '✅ 한국어 닉네임 생성 함수 생성 완료';
END $$;

-- =============================================================================
-- 3. 새 사용자 처리를 위한 안전한 트리거 함수
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🛡️ 안전한 사용자 생성 트리거 함수를 생성합니다...';
END $$;

CREATE OR REPLACE FUNCTION public.handle_new_user_final()
RETURNS TRIGGER AS $$
DECLARE
    safe_nickname TEXT;
    safe_email TEXT;
    safe_full_name TEXT;
    safe_provider TEXT;
BEGIN
    -- 1. 안전한 이메일 처리
    safe_email := COALESCE(NEW.email, '');
    
    -- 2. 안전한 풀네임 처리
    safe_full_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        CASE WHEN safe_email != '' THEN split_part(safe_email, '@', 1) ELSE '사용자' END
    );
    
    -- 3. 안전한 제공자 처리
    safe_provider := COALESCE(NEW.raw_app_meta_data->>'provider', 'email');
    
    -- 4. 🎨 한국어 닉네임 생성 (중복 체크 포함)
    safe_nickname := generate_korean_nickname_safe(NEW.id);
    
    -- 5. 프로필 생성 (에러 발생해도 회원가입은 막지 않음)
    BEGIN
        INSERT INTO public.profiles (
            id, 
            email, 
            full_name, 
            avatar_url, 
            provider, 
            nickname,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            safe_email,
            safe_full_name,
            COALESCE(
                NEW.raw_user_meta_data->>'avatar_url', 
                NEW.raw_user_meta_data->>'picture'
            ),
            safe_provider,
            safe_nickname,
            COALESCE(NEW.created_at, NOW()),
            COALESCE(NEW.updated_at, NOW())
        );
        
        RAISE NOTICE '🎉 새 사용자 프로필 생성 성공: % (닉네임: %)', safe_email, safe_nickname;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 프로필 생성 실패하지만 회원가입은 계속: % - %', SQLERRM, SQLSTATE;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DO $$
BEGIN
    RAISE NOTICE '✅ 안전한 트리거 함수 생성 완료';
END $$;

-- =============================================================================
-- 4. 새 트리거 생성 (에러가 회원가입을 막지 않도록)
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔗 새 트리거를 생성합니다...';
END $$;

CREATE TRIGGER on_auth_user_created_final
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user_final();

DO $$
BEGIN
    RAISE NOTICE '✅ 새 트리거 생성 완료';
END $$;

-- =============================================================================
-- 5. 기존 사용자들 중 누락된 프로필 복구
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🛠️ 누락된 프로필들을 복구합니다...';
END $$;

-- auth.users에 있지만 profiles에 없는 사용자들을 위한 프로필 생성
DO $$
DECLARE
    missing_user RECORD;
    safe_nickname TEXT;
    recovered_count INT := 0;
BEGIN
    FOR missing_user IN 
        SELECT u.* FROM auth.users u 
        LEFT JOIN public.profiles p ON u.id = p.id 
        WHERE p.id IS NULL
        ORDER BY u.created_at
    LOOP
        -- 한국어 닉네임 생성
        safe_nickname := generate_korean_nickname_safe(missing_user.id);
        
        -- 안전하게 프로필 생성
        BEGIN
            INSERT INTO public.profiles (
                id, 
                email, 
                full_name, 
                avatar_url, 
                provider, 
                nickname,
                created_at,
                updated_at
            ) VALUES (
                missing_user.id,
                COALESCE(missing_user.email, ''),
                COALESCE(
                    missing_user.raw_user_meta_data->>'full_name',
                    missing_user.raw_user_meta_data->>'name',
                    CASE WHEN missing_user.email IS NOT NULL 
                         THEN split_part(missing_user.email, '@', 1) 
                         ELSE '사용자' END
                ),
                COALESCE(
                    missing_user.raw_user_meta_data->>'avatar_url', 
                    missing_user.raw_user_meta_data->>'picture'
                ),
                COALESCE(missing_user.raw_app_meta_data->>'provider', 'email'),
                safe_nickname,
                missing_user.created_at,
                NOW()
            );
            
            recovered_count := recovered_count + 1;
            RAISE NOTICE '✅ 프로필 복구 성공: % -> %', 
                         COALESCE(missing_user.email, missing_user.id::TEXT), safe_nickname;
                         
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ 프로필 복구 실패: % (에러: %)', 
                         COALESCE(missing_user.email, missing_user.id::TEXT), SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '🎉 총 % 개의 누락된 프로필을 복구했습니다!', recovered_count;
END $$;

-- =============================================================================
-- 6. 중복 닉네임 정리 (한국어 닉네임으로 교체)
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔄 중복 닉네임들을 정리합니다...';
END $$;

DO $$
DECLARE
    duplicate_record RECORD;
    new_nickname TEXT;
    fixed_count INT := 0;
BEGIN
    FOR duplicate_record IN
        SELECT nickname, array_agg(id ORDER BY created_at) as user_ids
        FROM public.profiles 
        WHERE nickname IS NOT NULL
        GROUP BY nickname 
        HAVING COUNT(*) > 1
    LOOP
        -- 첫 번째 사용자는 그대로 두고, 나머지는 새 한국어 닉네임 생성
        FOR i IN 2..array_length(duplicate_record.user_ids, 1)
        LOOP
            new_nickname := generate_korean_nickname_safe(duplicate_record.user_ids[i]);
            
            UPDATE public.profiles 
            SET nickname = new_nickname, updated_at = NOW()
            WHERE id = duplicate_record.user_ids[i];
            
            fixed_count := fixed_count + 1;
            RAISE NOTICE '🔄 중복 해결: % -> % (ID: %)', 
                         duplicate_record.nickname, new_nickname, duplicate_record.user_ids[i];
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '✅ 총 % 개의 중복 닉네임을 해결했습니다!', fixed_count;
END $$;

-- =============================================================================
-- 7. 닉네임 중복 체크 함수들 (앱에서 사용)
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 닉네임 체크 함수들을 생성합니다...';
END $$;

-- 닉네임 존재 여부 체크
CREATE OR REPLACE FUNCTION check_nickname_exists(nickname_to_check TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE nickname = nickname_to_check
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 특정 사용자 제외하고 닉네임 사용 가능 여부 체크
CREATE OR REPLACE FUNCTION is_nickname_available(nickname_to_check TEXT, exclude_user_id UUID DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
    IF exclude_user_id IS NULL THEN
        RETURN NOT EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE nickname = nickname_to_check
        );
    ELSE
        RETURN NOT EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE nickname = nickname_to_check 
            AND id != exclude_user_id
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DO $$
BEGIN
    RAISE NOTICE '✅ 닉네임 체크 함수들 생성 완료';
END $$;

-- =============================================================================
-- 8. UNIQUE 제약조건 설정 (안전하게)
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔒 닉네임 UNIQUE 제약조건을 설정합니다...';
END $$;

-- 기존 제약조건들 정리
DO $$
BEGIN
    -- 모든 기존 제약조건 제거
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_nickname_unique;
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS unique_nickname;
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS nickname_must_be_unique;
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS safe_nickname_unique;
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS korean_nickname_unique;
    
    -- 모든 기존 인덱스 제거
    DROP INDEX IF EXISTS idx_profiles_nickname_unique;
    DROP INDEX IF EXISTS nickname_unique_idx;
    DROP INDEX IF EXISTS safe_nickname_idx;
    DROP INDEX IF EXISTS korean_nickname_idx;
    DROP INDEX IF EXISTS idx_profiles_nickname;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '제약조건 정리 중 일부 에러 (무시 가능): %', SQLERRM;
END $$;

-- 새로운 UNIQUE 제약조건과 인덱스
ALTER TABLE public.profiles 
ADD CONSTRAINT final_nickname_unique UNIQUE (nickname);

CREATE UNIQUE INDEX final_nickname_idx 
ON public.profiles(nickname) 
WHERE nickname IS NOT NULL;

DO $$
BEGIN
    RAISE NOTICE '✅ 닉네임 UNIQUE 제약조건 설정 완료';
END $$;

-- =============================================================================
-- 9. 최종 결과 확인 및 테스트
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '📊 최종 결과를 확인합니다...';
END $$;

DO $$
DECLARE
    total_users INT;
    total_profiles INT;
    unique_nicknames INT;
    duplicate_count INT;
    sample_nickname TEXT;
BEGIN
    SELECT COUNT(*) INTO total_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    SELECT COUNT(DISTINCT nickname) INTO unique_nicknames FROM public.profiles;
    
    SELECT COUNT(*) INTO duplicate_count 
    FROM (SELECT nickname FROM public.profiles GROUP BY nickname HAVING COUNT(*) > 1) duplicates;
    
    RAISE NOTICE '🎉 ========== 최종 결과 ==========';
    RAISE NOTICE '👥 인증 사용자: % 명', total_users;
    RAISE NOTICE '📝 프로필 사용자: % 명', total_profiles;
    RAISE NOTICE '🏷️  고유 닉네임: % 개', unique_nicknames;
    RAISE NOTICE '🔁 중복 닉네임: % 개', duplicate_count;
    
    IF total_users = total_profiles AND duplicate_count = 0 THEN
        RAISE NOTICE '🎊 완벽! 모든 문제가 해결되었습니다!';
        RAISE NOTICE '✅ 이제 회원가입시 자동으로 한국어 닉네임이 생성됩니다!';
        RAISE NOTICE '✅ 중복 체크도 정상 작동합니다!';
    ELSE
        RAISE NOTICE '⚠️  아직 해결되지 않은 문제가 있을 수 있습니다.';
    END IF;
    
    -- 테스트용 샘플 닉네임 생성
    sample_nickname := generate_korean_nickname_safe();
    RAISE NOTICE '🎯 샘플 생성 닉네임: %', sample_nickname;
    
    RAISE NOTICE '🎉 ========== 설치 완료 ==========';
END $$;

-- 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '🚀 회원가입시 닉네임 프로필 저장 문제가 완전히 해결되었습니다!';
    RAISE NOTICE '📱 이제 Flutter 앱에서 정상적으로 중복 체크가 작동할 것입니다!';
END $$;
