-- 🚨 긴급 닉네임 중복 방지 강화 스크립트
-- 현재 중복된 닉네임들을 정리하고 강력한 제약조건을 추가합니다

-- =============================================================================
-- 1. 현재 중복된 닉네임 상황 파악
-- =============================================================================

-- 중복된 닉네임 조회
DO $$
BEGIN
    RAISE NOTICE '🔍 현재 중복된 닉네임 상황:';
END $$;

-- 중복된 닉네임 목록 표시
SELECT nickname, COUNT(*) as duplicate_count 
FROM public.profiles 
WHERE nickname IS NOT NULL 
GROUP BY nickname 
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- =============================================================================
-- 2. 중복된 닉네임 정리 (자동으로 고유하게 만들기)
-- =============================================================================

DO $$
DECLARE
    duplicate_record RECORD;
    counter INT;
    new_nickname TEXT;
BEGIN
    RAISE NOTICE '🔧 중복된 닉네임들을 정리하고 있습니다...';
    
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
        FOREACH new_nickname IN ARRAY duplicate_record.user_ids[2:array_upper(duplicate_record.user_ids, 1)]
        LOOP
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
            WHERE id = duplicate_record.user_ids[counter - 1];
            
            RAISE NOTICE '✅ 사용자 % 닉네임 변경: % -> %', 
                         duplicate_record.user_ids[counter - 1], 
                         duplicate_record.nickname, 
                         new_nickname;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '🎉 중복 닉네임 정리 완료!';
END $$;

-- =============================================================================
-- 3. 강력한 UNIQUE 제약조건 추가
-- =============================================================================

-- 기존 제약조건 제거 (있다면)
DO $$
BEGIN
    -- 기존 unique 제약조건 제거
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'profiles' AND constraint_name = 'unique_nickname'
    ) THEN
        ALTER TABLE public.profiles DROP CONSTRAINT unique_nickname;
        RAISE NOTICE '🗑️ 기존 unique_nickname 제약조건 제거됨';
    END IF;
    
    -- 기존 인덱스 제거
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'profiles' AND indexname = 'idx_profiles_nickname'
    ) THEN
        DROP INDEX IF EXISTS idx_profiles_nickname;
        RAISE NOTICE '🗑️ 기존 닉네임 인덱스 제거됨';
    END IF;
END $$;

-- 새로운 강력한 UNIQUE 제약조건 추가
ALTER TABLE public.profiles 
ADD CONSTRAINT profiles_nickname_unique UNIQUE (nickname);

-- 성능 최적화를 위한 인덱스 생성
CREATE UNIQUE INDEX idx_profiles_nickname_unique 
ON public.profiles(nickname) 
WHERE nickname IS NOT NULL;

-- =============================================================================
-- 4. NULL 닉네임 처리 (혹시 있다면)
-- =============================================================================

-- nickname이 NULL인 사용자들에게 자동 닉네임 할당
DO $$
DECLARE
    null_user RECORD;
    generated_nickname TEXT;
    counter INT := 1;
BEGIN
    FOR null_user IN 
        SELECT id, email FROM public.profiles WHERE nickname IS NULL OR nickname = ''
    LOOP
        -- 기본 닉네임 생성
        generated_nickname := '독서가' || counter::TEXT;
        
        -- 중복 확인 및 고유 닉네임 생성
        WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = generated_nickname) LOOP
            counter := counter + 1;
            generated_nickname := '독서가' || counter::TEXT;
        END LOOP;
        
        -- 업데이트
        UPDATE public.profiles 
        SET nickname = generated_nickname, updated_at = NOW()
        WHERE id = null_user.id;
        
        RAISE NOTICE '✅ NULL 닉네임 사용자 % 에게 닉네임 할당: %', null_user.email, generated_nickname;
        counter := counter + 1;
    END LOOP;
END $$;

-- =============================================================================
-- 5. NOT NULL 제약조건 추가 (닉네임 필수화)
-- =============================================================================

-- nickname 컬럼을 NOT NULL로 변경
ALTER TABLE public.profiles 
ALTER COLUMN nickname SET NOT NULL;

-- =============================================================================
-- 6. 강화된 RLS 정책 업데이트
-- =============================================================================

-- 기존 정책 삭제
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- 새로운 강화된 정책 생성
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND nickname IS NOT NULL 
    AND length(trim(nickname)) >= 2 
    AND length(trim(nickname)) <= 20
  );

-- =============================================================================
-- 7. 닉네임 업데이트 트리거 함수 (추가 보안)
-- =============================================================================

-- 닉네임 업데이트 시 추가 검증을 위한 트리거 함수
CREATE OR REPLACE FUNCTION check_nickname_before_update()
RETURNS TRIGGER AS $$
BEGIN
    -- 닉네임이 NULL이거나 빈 문자열인 경우 차단
    IF NEW.nickname IS NULL OR trim(NEW.nickname) = '' THEN
        RAISE EXCEPTION '닉네임은 필수입니다';
    END IF;
    
    -- 길이 검증
    IF length(trim(NEW.nickname)) < 2 OR length(trim(NEW.nickname)) > 20 THEN
        RAISE EXCEPTION '닉네임은 2-20자 사이여야 합니다';
    END IF;
    
    -- 중복 검증 (자기 자신 제외)
    IF EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE nickname = NEW.nickname AND id != NEW.id
    ) THEN
        RAISE EXCEPTION '이미 사용 중인 닉네임입니다: %', NEW.nickname;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 기존 트리거 제거 후 새로 생성
DROP TRIGGER IF EXISTS nickname_validation_trigger ON public.profiles;
CREATE TRIGGER nickname_validation_trigger
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION check_nickname_before_update();

-- =============================================================================
-- 8. 완료 확인 및 상태 점검
-- =============================================================================

DO $$
DECLARE
    total_users INT;
    unique_nicknames INT;
    duplicate_count INT;
BEGIN
    -- 전체 사용자 수
    SELECT COUNT(*) INTO total_users FROM public.profiles;
    
    -- 고유 닉네임 수
    SELECT COUNT(DISTINCT nickname) INTO unique_nicknames FROM public.profiles;
    
    -- 중복 닉네임 수
    SELECT COUNT(*) INTO duplicate_count 
    FROM (
        SELECT nickname 
        FROM public.profiles 
        GROUP BY nickname 
        HAVING COUNT(*) > 1
    ) duplicates;
    
    RAISE NOTICE '🎉========================================🎉';
    RAISE NOTICE '✅ 닉네임 중복 방지 강화 완료!';
    RAISE NOTICE '📊 상태 요약:';
    RAISE NOTICE '  - 전체 사용자 수: %', total_users;
    RAISE NOTICE '  - 고유 닉네임 수: %', unique_nicknames;
    RAISE NOTICE '  - 중복 닉네임 수: %', duplicate_count;
    
    IF duplicate_count = 0 THEN
        RAISE NOTICE '🎯 모든 닉네임이 고유합니다!';
    ELSE
        RAISE NOTICE '⚠️  아직 중복이 있습니다. 수동 확인 필요.';
    END IF;
    
    RAISE NOTICE '🔒 추가된 보안 기능:';
    RAISE NOTICE '  - 데이터베이스 레벨 UNIQUE 제약조건';
    RAISE NOTICE '  - NOT NULL 제약조건';
    RAISE NOTICE '  - 업데이트 전 검증 트리거';
    RAISE NOTICE '  - 강화된 RLS 정책';
    RAISE NOTICE '🎉========================================🎉';
END $$;

-- 최종 중복 확인
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 중복된 닉네임 없음'
        ELSE '❌ 아직 중복된 닉네임 존재: ' || COUNT(*)::TEXT || '개'
    END as final_status
FROM (
    SELECT nickname 
    FROM public.profiles 
    GROUP BY nickname 
    HAVING COUNT(*) > 1
) duplicates;
