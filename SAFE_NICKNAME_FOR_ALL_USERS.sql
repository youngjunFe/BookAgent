-- 🛡️ 모든 사용자 유형에 안전한 닉네임 생성 스크립트
-- 카카오, 구글, 이메일 사용자 모두 대응

-- =============================================================================
-- 1. 안전한 닉네임 생성 함수 (모든 케이스 대응)
-- =============================================================================

CREATE OR REPLACE FUNCTION generate_safe_nickname(
    user_id UUID,
    user_email TEXT,
    user_metadata JSONB,
    provider TEXT
) RETURNS TEXT AS $$
DECLARE
    base_nickname TEXT;
    final_nickname TEXT;
    counter INT := 1;
BEGIN
    -- 1순위: 사용자 메타데이터에서 닉네임 추출
    IF user_metadata ? 'nickname' AND user_metadata->>'nickname' IS NOT NULL AND trim(user_metadata->>'nickname') != '' THEN
        base_nickname := trim(user_metadata->>'nickname');
        
    -- 2순위: 사용자 메타데이터에서 이름 추출  
    ELSIF user_metadata ? 'name' AND user_metadata->>'name' IS NOT NULL AND trim(user_metadata->>'name') != '' THEN
        base_nickname := trim(user_metadata->>'name');
        
    -- 3순위: full_name 추출
    ELSIF user_metadata ? 'full_name' AND user_metadata->>'full_name' IS NOT NULL AND trim(user_metadata->>'full_name') != '' THEN
        base_nickname := trim(user_metadata->>'full_name');
        
    -- 4순위: 이메일이 있으면 @ 앞부분 사용
    ELSIF user_email IS NOT NULL AND user_email != '' THEN
        base_nickname := split_part(user_email, '@', 1);
        
    -- 5순위: 제공자별 기본 닉네임
    ELSIF provider = 'kakao' THEN
        base_nickname := '카카오유저';
    ELSIF provider = 'google' THEN  
        base_nickname := '구글유저';
    ELSIF provider = 'apple' THEN
        base_nickname := '애플유저';
    ELSE
        base_nickname := '독서가';
    END IF;
    
    -- 특수문자 제거, 한글/영문/숫자만 유지
    base_nickname := regexp_replace(base_nickname, '[^가-힣a-zA-Z0-9]', '', 'g');
    
    -- 너무 짧으면 기본값으로 대체
    IF length(base_nickname) < 2 THEN
        CASE 
            WHEN provider = 'kakao' THEN base_nickname := '카카오유저';
            WHEN provider = 'google' THEN base_nickname := '구글유저';  
            WHEN provider = 'apple' THEN base_nickname := '애플유저';
            ELSE base_nickname := '독서가';
        END CASE;
    END IF;
    
    -- 너무 길면 10자로 자름
    IF length(base_nickname) > 10 THEN
        base_nickname := left(base_nickname, 10);
    END IF;
    
    final_nickname := base_nickname;
    
    -- 중복 체크하며 고유 닉네임 생성
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = final_nickname) LOOP
        final_nickname := base_nickname || counter::TEXT;
        counter := counter + 1;
        
        -- 무한 루프 방지
        IF counter > 9999 THEN
            final_nickname := base_nickname || substring(user_id::TEXT, 1, 6);
            EXIT;
        END IF;
    END LOOP;
    
    RETURN final_nickname;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 2. 기존 사용자들을 profiles 테이블에 안전하게 추가
-- =============================================================================

-- auth.users에 있지만 profiles에 없는 사용자들을 찾아서 추가
INSERT INTO public.profiles (id, email, full_name, provider, nickname, created_at, updated_at)
SELECT 
    u.id,
    u.email,
    COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', 
             CASE WHEN u.email IS NOT NULL THEN split_part(u.email, '@', 1) 
                  ELSE '사용자' END) as full_name,
    COALESCE(u.raw_app_meta_data->>'provider', 'email') as provider,
    -- 안전한 닉네임 생성 함수 사용
    generate_safe_nickname(
        u.id, 
        u.email, 
        COALESCE(u.raw_user_meta_data, '{}'::jsonb), 
        COALESCE(u.raw_app_meta_data->>'provider', 'email')
    ) as nickname,
    u.created_at,
    u.updated_at
FROM auth.users u
WHERE u.id NOT IN (SELECT id FROM public.profiles WHERE id IS NOT NULL)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- 3. NULL이나 빈 닉네임 처리
-- =============================================================================

-- nickname이 NULL이거나 빈 문자열인 기존 사용자들 처리
UPDATE public.profiles p
SET nickname = generate_safe_nickname(
    p.id, 
    p.email, 
    COALESCE((SELECT u.raw_user_meta_data FROM auth.users u WHERE u.id = p.id), '{}'::jsonb),
    COALESCE(p.provider, 'email')
),
updated_at = NOW()
WHERE nickname IS NULL OR nickname = '';

-- =============================================================================
-- 4. 중복 닉네임 정리 (기존 중복이 있다면)
-- =============================================================================

DO $$
DECLARE
    duplicate_record RECORD;
    counter INT;
    new_nickname TEXT;
    user_id UUID;
BEGIN
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
            
            new_nickname := duplicate_record.nickname || counter::TEXT;
            
            WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = new_nickname) LOOP
                counter := counter + 1;
                new_nickname := duplicate_record.nickname || counter::TEXT;
            END LOOP;
            
            UPDATE public.profiles 
            SET nickname = new_nickname, updated_at = NOW()
            WHERE id = user_id;
            
            RAISE NOTICE '✅ 중복 해결: % -> % (ID: %)', 
                         duplicate_record.nickname, new_nickname, user_id;
        END LOOP;
    END LOOP;
END $$;

-- =============================================================================
-- 5. 안전한 제약조건 및 트리거 설정
-- =============================================================================

-- 기존 제약조건들 안전하게 제거
DO $$
BEGIN
    -- 각종 제약조건 제거
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'profiles' AND constraint_name = 'profiles_nickname_unique') THEN
        ALTER TABLE public.profiles DROP CONSTRAINT profiles_nickname_unique;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'profiles' AND constraint_name = 'unique_nickname') THEN
        ALTER TABLE public.profiles DROP CONSTRAINT unique_nickname;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'profiles' AND constraint_name = 'nickname_must_be_unique') THEN
        ALTER TABLE public.profiles DROP CONSTRAINT nickname_must_be_unique;
    END IF;
    
    -- 각종 인덱스 제거
    DROP INDEX IF EXISTS idx_profiles_nickname_unique;
    DROP INDEX IF EXISTS nickname_unique_idx;
    DROP INDEX IF EXISTS idx_profiles_nickname;
END $$;

-- 새로운 UNIQUE 제약조건 (고유 이름)
ALTER TABLE public.profiles 
ADD CONSTRAINT safe_nickname_unique UNIQUE (nickname);

-- 성능 인덱스
CREATE UNIQUE INDEX safe_nickname_idx 
ON public.profiles(nickname) 
WHERE nickname IS NOT NULL;

-- =============================================================================
-- 6. 향후 신규 사용자를 위한 개선된 트리거
-- =============================================================================

-- 기존 트리거 제거
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 모든 사용자 유형을 지원하는 새 사용자 처리 함수
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    generated_nickname TEXT;
BEGIN
    -- 안전한 닉네임 생성 함수 사용
    generated_nickname := generate_safe_nickname(
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
        COALESCE(NEW.raw_app_meta_data->>'provider', 'email')
    );
    
    -- 프로필 생성
    INSERT INTO public.profiles (id, email, full_name, avatar_url, provider, nickname)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 
                CASE WHEN NEW.email IS NOT NULL THEN split_part(NEW.email, '@', 1) 
                     ELSE '사용자' END),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture'),
        COALESCE(NEW.raw_app_meta_data->>'provider', 'email'),
        generated_nickname
    );
    
    RAISE NOTICE '🎉 새 사용자 프로필 생성: % (닉네임: %)', NEW.email, generated_nickname;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 생성
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 7. 테스트 케이스별 결과 확인
-- =============================================================================

DO $$
DECLARE
    total_users INT;
    total_profiles INT;
    unique_nicknames INT;
    duplicate_count INT;
    kakao_users INT;
    google_users INT;
    email_users INT;
BEGIN
    SELECT COUNT(*) INTO total_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    SELECT COUNT(DISTINCT nickname) INTO unique_nicknames FROM public.profiles;
    
    SELECT COUNT(*) INTO duplicate_count 
    FROM (SELECT nickname FROM public.profiles GROUP BY nickname HAVING COUNT(*) > 1) duplicates;
    
    SELECT COUNT(*) INTO kakao_users FROM public.profiles WHERE provider = 'kakao';
    SELECT COUNT(*) INTO google_users FROM public.profiles WHERE provider = 'google';
    SELECT COUNT(*) INTO email_users FROM public.profiles WHERE provider = 'email';
    
    RAISE NOTICE '🎉========================================🎉';
    RAISE NOTICE '✅ 모든 유저 타입 대응 닉네임 시스템 완료!';
    RAISE NOTICE '📊 전체 현황:';
    RAISE NOTICE '  - 인증 사용자: % 명', total_users;
    RAISE NOTICE '  - 프로필 사용자: % 명', total_profiles;
    RAISE NOTICE '  - 고유 닉네임: % 개', unique_nicknames;
    RAISE NOTICE '  - 중복 닉네임: % 개', duplicate_count;
    RAISE NOTICE '📱 제공자별 현황:';
    RAISE NOTICE '  - 카카오: % 명', kakao_users;
    RAISE NOTICE '  - 구글: % 명', google_users;
    RAISE NOTICE '  - 이메일: % 명', email_users;
    
    IF total_users = total_profiles AND duplicate_count = 0 THEN
        RAISE NOTICE '🎯 완벽! 모든 사용자가 고유한 닉네임을 보유!';
    END IF;
    
    RAISE NOTICE '🛡️ 지원하는 케이스:';
    RAISE NOTICE '  - 카카오 닉네임 없음 → "카카오유저1", "카카오유저2"';
    RAISE NOTICE '  - 구글 이메일만 → "이메일아이디1"';
    RAISE NOTICE '  - 애플 이름만 → "이름1"';
    RAISE NOTICE '  - 모든 정보 없음 → "독서가1"';
    RAISE NOTICE '🎉========================================🎉';
END $$;
