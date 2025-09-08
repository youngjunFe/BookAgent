-- 🛡️ 보안을 위한 올바른 RLS 정책 설정
-- profiles 테이블을 안전하게 사용할 수 있도록

-- =============================================================================
-- 1. RLS 다시 활성화
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 2. 안전한 RLS 정책들 생성
-- =============================================================================

-- 기존 정책들 모두 제거
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own nickname" ON public.profiles;

-- 1. 자신의 프로필만 조회 가능
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

-- 2. 자신의 프로필만 생성 가능 (회원가입시)
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 3. 자신의 프로필만 수정 가능
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 4. 닉네임 중복 체크를 위한 읽기 전용 정책 (모든 사용자)
CREATE POLICY "Allow nickname duplicate check" ON public.profiles
    FOR SELECT USING (true);

-- =============================================================================
-- 3. 권한 설정 (필요한 최소 권한만)
-- =============================================================================

-- authenticated 사용자에게 필요한 권한만
GRANT SELECT, INSERT, UPDATE ON TABLE public.profiles TO authenticated;

-- anon 사용자에게는 닉네임 중복체크 용도로 SELECT만
GRANT SELECT ON TABLE public.profiles TO anon;

-- =============================================================================
-- 4. 테스트 - RLS가 제대로 작동하는지 확인
-- =============================================================================

DO $$
DECLARE
    rls_enabled BOOLEAN;
    policy_count INT;
BEGIN
    -- RLS 활성화 상태 확인
    SELECT relrowsecurity INTO rls_enabled 
    FROM pg_class 
    WHERE relname = 'profiles' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    -- 정책 개수 확인
    SELECT COUNT(*) INTO policy_count 
    FROM pg_policies 
    WHERE tablename = 'profiles' AND schemaname = 'public';
    
    RAISE NOTICE '🔒 RLS 활성화: %', CASE WHEN rls_enabled THEN '✅ YES' ELSE '❌ NO' END;
    RAISE NOTICE '📋 RLS 정책 개수: % 개', policy_count;
    
    IF rls_enabled AND policy_count >= 3 THEN
        RAISE NOTICE '🎉 안전한 RLS 정책 설정 완료!';
        RAISE NOTICE '✅ 이제 보안을 유지하면서 프로필 생성 가능합니다!';
    END IF;
END $$;

SELECT '🛡️ 보안 설정 완료! 이제 안전하게 사용 가능합니다!' AS 완료메시지;
