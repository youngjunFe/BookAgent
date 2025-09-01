-- 📋 완전한 Supabase 설정 + 닉네임 기능 SQL 스크립트
-- 이 파일 하나로 모든 설정이 완료됩니다!

-- =============================================================================
-- 1. 기본 profiles 테이블 생성 (필수)
-- =============================================================================

-- 사용자 프로필 테이블 (auth.users와 연동)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  provider TEXT,
  nickname TEXT UNIQUE, -- 🆕 닉네임 컬럼 추가
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- 2. 인덱스 생성 (성능 최적화)
-- =============================================================================

-- 닉네임 검색 최적화를 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_profiles_nickname 
ON public.profiles(nickname);

-- 이메일 검색 최적화를 위한 인덱스  
CREATE INDEX IF NOT EXISTS idx_profiles_email 
ON public.profiles(email);

-- =============================================================================
-- 3. RLS (Row Level Security) 설정
-- =============================================================================

-- RLS 활성화
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 기존 정책들 삭제 (중복 방지)
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own nickname" ON public.profiles;

-- 사용자는 자신의 프로필만 조회 가능
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- 사용자는 자신의 프로필만 수정 가능
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- =============================================================================
-- 4. 닉네임 생성 및 관리 함수들
-- =============================================================================

-- 기본 닉네임 생성 함수
CREATE OR REPLACE FUNCTION generate_default_nickname(user_id UUID, user_email TEXT)
RETURNS TEXT AS $$
DECLARE
    base_nickname TEXT;
    final_nickname TEXT;
    counter INT := 1;
BEGIN
    -- 이메일에서 @ 앞부분을 기본 닉네임으로 사용
    base_nickname := split_part(user_email, '@', 1);
    
    -- 숫자나 특수문자 제거, 한글/영문만 유지
    base_nickname := regexp_replace(base_nickname, '[^가-힣a-zA-Z]', '', 'g');
    
    -- 너무 짧으면 '독서가'로 대체
    IF length(base_nickname) < 2 THEN
        base_nickname := '독서가';
    END IF;
    
    -- 너무 길면 8자로 자름
    IF length(base_nickname) > 8 THEN
        base_nickname := left(base_nickname, 8);
    END IF;
    
    final_nickname := base_nickname;
    
    -- 중복 체크하며 숫자 추가
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE nickname = final_nickname) LOOP
        final_nickname := base_nickname || counter::TEXT;
        counter := counter + 1;
        
        -- 무한 루프 방지
        IF counter > 9999 THEN
            final_nickname := base_nickname || substring(user_id::TEXT, 1, 4);
            EXIT;
        END IF;
    END LOOP;
    
    RETURN final_nickname;
END;
$$ LANGUAGE plpgsql;

-- 닉네임 중복 체크 함수
CREATE OR REPLACE FUNCTION check_nickname_exists(nickname_to_check TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE nickname = nickname_to_check
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 닉네임 유효성 검사 함수
CREATE OR REPLACE FUNCTION is_nickname_available(nickname_to_check TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- 기본 유효성 검사
    IF nickname_to_check IS NULL OR length(trim(nickname_to_check)) < 2 OR length(trim(nickname_to_check)) > 20 THEN
        RETURN FALSE;
    END IF;
    
    -- 중복 검사
    RETURN NOT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE nickname = trim(nickname_to_check)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 닉네임 업데이트 함수
CREATE OR REPLACE FUNCTION update_user_nickname(user_id UUID, new_nickname TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    nickname_exists BOOLEAN;
BEGIN
    -- 현재 사용자가 아닌 다른 사용자가 이미 사용하는 닉네임인지 확인
    SELECT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE nickname = new_nickname AND id != user_id
    ) INTO nickname_exists;
    
    IF nickname_exists THEN
        RETURN FALSE; -- 이미 사용 중인 닉네임
    END IF;
    
    -- 닉네임 업데이트
    UPDATE public.profiles 
    SET nickname = new_nickname, updated_at = NOW()
    WHERE id = user_id;
    
    RETURN TRUE; -- 성공
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 5. 새 사용자 프로필 자동 생성 트리거
-- =============================================================================

-- 새 사용자 등록 시 자동으로 프로필 생성하는 함수 (닉네임 포함)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    generated_nickname TEXT;
BEGIN
    -- 기본 닉네임 생성
    generated_nickname := generate_default_nickname(NEW.id, NEW.email);
    
    INSERT INTO public.profiles (id, email, full_name, avatar_url, provider, nickname)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture'),
        NEW.app_metadata->>'provider',
        generated_nickname
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 기존 트리거 삭제 후 다시 생성
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 6. 기존 사용자들을 위한 데이터 마이그레이션
-- =============================================================================

-- 기존 사용자들 중 nickname이 없는 경우 자동 생성
DO $$
DECLARE
    user_record RECORD;
    generated_nickname TEXT;
BEGIN
    FOR user_record IN 
        SELECT id, email FROM public.profiles WHERE nickname IS NULL OR nickname = ''
    LOOP
        generated_nickname := generate_default_nickname(user_record.id, user_record.email);
        UPDATE public.profiles 
        SET nickname = generated_nickname, updated_at = NOW()
        WHERE id = user_record.id;
    END LOOP;
END $$;

-- =============================================================================
-- 7. Storage 설정 (책 커버 이미지용)
-- =============================================================================

-- Storage 버킷 생성 (이미 있다면 무시됨)
INSERT INTO storage.buckets (id, name, public)
VALUES ('book-covers', 'book-covers', true)
ON CONFLICT (id) DO NOTHING;

-- Storage 정책 설정
DROP POLICY IF EXISTS "Public read access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete access" ON storage.objects;

-- 읽기 정책 (모든 사용자가 이미지 볼 수 있도록)
CREATE POLICY "Public read access" ON storage.objects 
FOR SELECT USING (bucket_id = 'book-covers');

-- 업로드 정책 (인증된 사용자만 업로드)
CREATE POLICY "Authenticated upload access" ON storage.objects 
FOR INSERT WITH CHECK (bucket_id = 'book-covers' AND auth.role() = 'authenticated');

-- 삭제 정책 (인증된 사용자만 삭제)
CREATE POLICY "Authenticated delete access" ON storage.objects 
FOR DELETE USING (bucket_id = 'book-covers' AND auth.role() = 'authenticated');

-- =============================================================================
-- 8. 실행 완료 메시지
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎉========================================🎉';
    RAISE NOTICE '✅ 완전한 Supabase + 닉네임 설정이 완료되었습니다!';
    RAISE NOTICE '🎯 추가된 기능:';
    RAISE NOTICE '  - profiles 테이블 생성 (기본 구조)';
    RAISE NOTICE '  - nickname 컬럼 추가 (UNIQUE 제약조건)';
    RAISE NOTICE '  - 자동 닉네임 생성 시스템';
    RAISE NOTICE '  - 닉네임 중복 체크 및 유효성 검사';
    RAISE NOTICE '  - 새 사용자 등록 시 자동 프로필 생성';
    RAISE NOTICE '  - 기존 사용자들에게 닉네임 자동 할당';
    RAISE NOTICE '  - RLS 보안 정책 설정';
    RAISE NOTICE '  - Storage 버킷 및 정책 설정';
    RAISE NOTICE '🚀 이제 앱에서 닉네임 기능을 사용할 수 있습니다!';
    RAISE NOTICE '🎉========================================🎉';
END $$;
