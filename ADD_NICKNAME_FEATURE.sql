-- 닉네임 기능 추가 SQL 스크립트
-- Supabase SQL Editor에서 실행하세요

-- 1. profiles 테이블에 nickname 컬럼 추가
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS nickname TEXT UNIQUE;

-- 2. 닉네임에 대한 인덱스 생성 (중복 체크 성능 향상)
CREATE INDEX IF NOT EXISTS idx_profiles_nickname 
ON public.profiles(nickname);

-- 3. 닉네임 중복 방지 정책
ALTER TABLE public.profiles 
ADD CONSTRAINT unique_nickname 
UNIQUE (nickname);

-- 4. 기존 사용자들을 위한 기본 닉네임 생성 함수
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

-- 5. 기존 사용자들에게 기본 닉네임 할당
UPDATE public.profiles 
SET nickname = generate_default_nickname(id, email)
WHERE nickname IS NULL;

-- 6. 새 사용자 등록 시 닉네임 자동 생성을 위한 트리거 함수 업데이트
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

-- 7. 닉네임 업데이트 RLS 정책 추가
CREATE POLICY IF NOT EXISTS "Users can update own nickname" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 8. 닉네임 조회 함수 (중복 체크용)
CREATE OR REPLACE FUNCTION check_nickname_exists(nickname_to_check TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE nickname = nickname_to_check
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. 닉네임 업데이트 함수 (앱에서 사용)
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

-- 10. 사용 가능한 닉네임인지 확인하는 함수
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

-- 실행 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '닉네임 기능이 성공적으로 추가되었습니다!';
    RAISE NOTICE '- profiles 테이블에 nickname 컬럼 추가됨';
    RAISE NOTICE '- 기존 사용자들에게 기본 닉네임 할당됨';
    RAISE NOTICE '- 새 사용자 등록 시 자동 닉네임 생성 활성화됨';
END $$;
