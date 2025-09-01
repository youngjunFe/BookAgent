-- 🚀 빠른 닉네임 문제 해결 스크립트
-- 기존 제약조건 충돌 없이 안전하게 실행

-- =============================================================================
-- 1. 기존 사용자들을 profiles 테이블에 추가 (누락된 부분)
-- =============================================================================

-- auth.users에 있지만 profiles에 없는 사용자들을 찾아서 추가
INSERT INTO public.profiles (id, email, full_name, provider, nickname, created_at, updated_at)
SELECT 
    u.id,
    u.email,
    COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', split_part(u.email, '@', 1)) as full_name,
    u.raw_app_meta_data->>'provider' as provider,
    -- 고유 닉네임 생성 (이메일 기반 + 랜덤 숫자)
    split_part(u.email, '@', 1) || (EXTRACT(EPOCH FROM u.created_at)::bigint % 10000)::text as nickname,
    u.created_at,
    u.updated_at
FROM auth.users u
WHERE u.id NOT IN (SELECT id FROM public.profiles WHERE id IS NOT NULL)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- 2. NULL 닉네임 처리 (혹시 있다면)
-- =============================================================================

-- nickname이 NULL이거나 빈 문자열인 사용자들 처리
UPDATE public.profiles 
SET nickname = email || (EXTRACT(EPOCH FROM created_at)::bigint % 10000)::text,
    updated_at = NOW()
WHERE nickname IS NULL OR nickname = '';

-- =============================================================================
-- 3. 중복 닉네임 정리
-- =============================================================================

-- 중복된 닉네임들을 고유하게 만들기
DO $$
DECLARE
    duplicate_record RECORD;
    counter INT;
    new_nickname TEXT;
    user_id UUID;
BEGIN
    -- 중복된 닉네임을 가진 사용자들 처리
    FOR duplicate_record IN
        SELECT nickname, array_agg(id ORDER BY created_at) as user_ids
        FROM public.profiles 
        WHERE nickname IS NOT NULL
        GROUP BY nickname 
        HAVING COUNT(*) > 1
    LOOP
        counter := 1;
        
        -- 첫 번째 사용자는 그대로 두고, 나머지는 숫자를 추가
        FOR i IN 2..array_length(duplicate_record.user_ids, 1)
        LOOP
            user_id := duplicate_record.user_ids[i];
            counter := counter + 1;
            
            -- 새로운 고유 닉네임 생성
            new_nickname := duplicate_record.nickname || counter::TEXT;
            
            -- 이 닉네임도 중복인지 계속 확인
            WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = new_nickname) LOOP
                counter := counter + 1;
                new_nickname := duplicate_record.nickname || counter::TEXT;
            END LOOP;
            
            -- 업데이트 실행
            UPDATE public.profiles 
            SET nickname = new_nickname, updated_at = NOW()
            WHERE id = user_id;
            
            RAISE NOTICE '✅ 중복 닉네임 수정: % -> % (사용자: %)', 
                         duplicate_record.nickname, new_nickname, user_id;
        END LOOP;
    END LOOP;
END $$;

-- =============================================================================
-- 4. 안전한 제약조건 추가 (기존 것 체크 후)
-- =============================================================================

-- 기존 제약조건들 안전하게 제거
DO $$
BEGIN
    -- 제약조건 제거 (있다면)
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'profiles' AND constraint_name = 'profiles_nickname_unique'
    ) THEN
        ALTER TABLE public.profiles DROP CONSTRAINT profiles_nickname_unique;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'profiles' AND constraint_name = 'unique_nickname'
    ) THEN
        ALTER TABLE public.profiles DROP CONSTRAINT unique_nickname;
    END IF;
    
    -- 인덱스 제거 (있다면)
    DROP INDEX IF EXISTS idx_profiles_nickname_unique;
    DROP INDEX IF EXISTS idx_profiles_nickname;
END $$;

-- 새로운 UNIQUE 제약조건 추가 (고유 이름 사용)
ALTER TABLE public.profiles 
ADD CONSTRAINT nickname_must_be_unique UNIQUE (nickname);

-- 성능을 위한 인덱스 생성
CREATE UNIQUE INDEX nickname_unique_idx 
ON public.profiles(nickname) 
WHERE nickname IS NOT NULL;

-- =============================================================================
-- 5. 향후 자동 프로필 생성을 위한 트리거 (기존 것 체크 후)
-- =============================================================================

-- 기존 트리거와 함수 제거
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS nickname_validation_trigger ON public.profiles;
DROP FUNCTION IF EXISTS check_nickname_before_update();
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 새 사용자 자동 프로필 생성 함수
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    generated_nickname TEXT;
    counter INT := 1;
BEGIN
    -- 기본 닉네임 생성 (이메일 + 타임스탬프)
    generated_nickname := split_part(NEW.email, '@', 1) || (EXTRACT(EPOCH FROM NOW())::bigint % 10000)::text;
    
    -- 중복 체크하며 고유 닉네임 생성
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = generated_nickname) LOOP
        counter := counter + 1;
        generated_nickname := split_part(NEW.email, '@', 1) || counter::text;
        
        IF counter > 9999 THEN
            generated_nickname := 'user' || substring(NEW.id::TEXT, 1, 8);
            EXIT;
        END IF;
    END LOOP;
    
    -- 프로필 생성
    INSERT INTO public.profiles (id, email, full_name, avatar_url, provider, nickname)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture'),
        NEW.raw_app_meta_data->>'provider',
        generated_nickname
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 생성
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 6. 결과 확인
-- =============================================================================

-- 현재 상태 출력
DO $$
DECLARE
    total_users INT;
    total_profiles INT;
    unique_nicknames INT;
    duplicate_count INT;
BEGIN
    SELECT COUNT(*) INTO total_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    SELECT COUNT(DISTINCT nickname) INTO unique_nicknames FROM public.profiles;
    
    SELECT COUNT(*) INTO duplicate_count 
    FROM (
        SELECT nickname 
        FROM public.profiles 
        GROUP BY nickname 
        HAVING COUNT(*) > 1
    ) duplicates;
    
    RAISE NOTICE '🎉========================================🎉';
    RAISE NOTICE '✅ 닉네임 시스템 설정 완료!';
    RAISE NOTICE '📊 결과:';
    RAISE NOTICE '  - 인증 사용자 수: %', total_users;
    RAISE NOTICE '  - 프로필 사용자 수: %', total_profiles;
    RAISE NOTICE '  - 고유 닉네임 수: %', unique_nicknames;
    RAISE NOTICE '  - 중복 닉네임 수: %', duplicate_count;
    
    IF total_users = total_profiles AND duplicate_count = 0 THEN
        RAISE NOTICE '🎯 모든 사용자가 고유한 닉네임을 가지고 있습니다!';
    ELSE
        RAISE NOTICE '⚠️  일부 문제가 있을 수 있습니다. 수동 확인 필요.';
    END IF;
    
    RAISE NOTICE '✅ 데이터베이스 레벨 UNIQUE 제약조건 활성화됨';
    RAISE NOTICE '✅ 새 사용자 자동 프로필 생성 트리거 활성화됨';
    RAISE NOTICE '🎉========================================🎉';
END $$;

-- 최종 확인을 위한 조회
SELECT 
    'profiles 테이블 현황' as status,
    COUNT(*) as total_count,
    COUNT(DISTINCT nickname) as unique_nicknames
FROM public.profiles
UNION ALL
SELECT 
    '중복 닉네임 존재 여부' as status,
    0 as total_count,
    COUNT(*) as unique_nicknames
FROM (
    SELECT nickname 
    FROM public.profiles 
    GROUP BY nickname 
    HAVING COUNT(*) > 1
) duplicates;
