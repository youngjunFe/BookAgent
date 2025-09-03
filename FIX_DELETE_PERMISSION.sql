-- 🔧 탈퇴 기능 수정: profiles 삭제 권한 문제 해결

-- =============================================================================
-- 1. 현재 RLS 정책 확인 및 제거
-- =============================================================================

-- 기존 모든 정책 제거 (삭제 차단 정책 포함)
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own nickname" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;

-- =============================================================================
-- 2. 삭제 허용하는 새로운 정책 생성
-- =============================================================================

-- 조회 정책 (기본)
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- 업데이트 정책 (기본)  
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- 🔑 삭제 정책 (중요!) - 반드시 추가
CREATE POLICY "Users can delete own profile" ON public.profiles
  FOR DELETE USING (auth.uid() = id);

-- 삽입 정책 (신규 가입용)
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================================================
-- 3. 테스트용 강제 삭제 함수 (RLS 우회)
-- =============================================================================

-- RLS를 우회하는 관리자용 삭제 함수
CREATE OR REPLACE FUNCTION force_delete_user_profile(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- RLS 정책을 우회하여 강제 삭제
    DELETE FROM public.profiles WHERE id = user_id;
    
    -- 삭제 확인
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = user_id) THEN
        RAISE NOTICE '✅ 사용자 % 프로필 강제 삭제 완료', user_id;
        RETURN TRUE;
    ELSE
        RAISE NOTICE '❌ 사용자 % 프로필 삭제 실패', user_id;
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 4. 현재 정책 상태 확인
-- =============================================================================

-- 현재 적용된 정책들 출력
SELECT 
    schemaname,
    tablename, 
    policyname,
    cmd as command,
    qual as using_expression,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'profiles'
ORDER BY policyname;

-- =============================================================================
-- 5. 완료 메시지
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔧========================================🔧';
    RAISE NOTICE '✅ profiles 테이블 삭제 권한 수정 완료!';
    RAISE NOTICE '🔑 추가된 정책:';
    RAISE NOTICE '  - SELECT: 자신의 프로필 조회 가능';
    RAISE NOTICE '  - UPDATE: 자신의 프로필 수정 가능';  
    RAISE NOTICE '  - DELETE: 자신의 프로필 삭제 가능 (중요!)';
    RAISE NOTICE '  - INSERT: 새 프로필 생성 가능';
    RAISE NOTICE '🛠️ 추가 도구:';
    RAISE NOTICE '  - force_delete_user_profile(uuid): RLS 우회 강제 삭제';
    RAISE NOTICE '🎯 이제 앱에서 탈퇴가 정상 작동할 것입니다!';
    RAISE NOTICE '🔧========================================🔧';
END $$;
