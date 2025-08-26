-- 🚨🚨🚨🚨🚨 최종 핵폭탄급 데이터베이스 보안 수정 🚨🚨🚨🚨🚨
-- 이 스크립트는 모든 보안 문제를 완전히 해결합니다
-- ⚠️⚠️⚠️ 모든 기존 데이터가 삭제됩니다! ⚠️⚠️⚠️

BEGIN;

-- 1. 모든 테이블 완전 초기화
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS ebooks CASCADE;  
DROP TABLE IF EXISTS reading_goals CASCADE;

-- 2. 테이블 재생성 (user_id 필수 포함)
CREATE TABLE reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    book_title TEXT NOT NULL,
    book_author TEXT,
    book_cover TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    background_image TEXT,
    tags TEXT[] DEFAULT '{}',
    mood TEXT,
    quotes TEXT[] DEFAULT '{}',
    chat_history TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ebooks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    author TEXT,
    cover_url TEXT,
    description TEXT,
    isbn TEXT,
    publisher TEXT,
    published_date DATE,
    genre TEXT,
    current_page INTEGER DEFAULT 0,
    total_pages INTEGER,
    progress REAL DEFAULT 0.0,
    status TEXT NOT NULL DEFAULT 'want_to_read',
    added_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    last_read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reading_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    target_count INTEGER NOT NULL,
    current_count INTEGER DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    goal_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. RLS 강제 활성화
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_goals ENABLE ROW LEVEL SECURITY;

-- 4. 최강 RLS 정책 (모든 작업에서 user_id 필수)
-- reviews 정책
CREATE POLICY "ULTIMATE_reviews_select" ON reviews 
  FOR SELECT USING (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

CREATE POLICY "ULTIMATE_reviews_insert" ON reviews 
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

CREATE POLICY "ULTIMATE_reviews_update" ON reviews 
  FOR UPDATE USING (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

CREATE POLICY "ULTIMATE_reviews_delete" ON reviews 
  FOR DELETE USING (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

-- ebooks 정책
CREATE POLICY "ULTIMATE_ebooks_select" ON ebooks 
  FOR SELECT USING (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

CREATE POLICY "ULTIMATE_ebooks_insert" ON ebooks 
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

CREATE POLICY "ULTIMATE_ebooks_update" ON ebooks 
  FOR UPDATE USING (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

CREATE POLICY "ULTIMATE_ebooks_delete" ON ebooks 
  FOR DELETE USING (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

-- reading_goals 정책
CREATE POLICY "ULTIMATE_goals_select" ON reading_goals 
  FOR SELECT USING (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

CREATE POLICY "ULTIMATE_goals_insert" ON reading_goals 
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

CREATE POLICY "ULTIMATE_goals_update" ON reading_goals 
  FOR UPDATE USING (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

CREATE POLICY "ULTIMATE_goals_delete" ON reading_goals 
  FOR DELETE USING (
    auth.uid() IS NOT NULL 
    AND user_id IS NOT NULL 
    AND auth.uid() = user_id
  );

-- 5. 인덱스 생성 (성능 향상)
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_status ON reviews(status);
CREATE INDEX idx_ebooks_user_id ON ebooks(user_id);
CREATE INDEX idx_ebooks_status ON ebooks(status);  
CREATE INDEX idx_reading_goals_user_id ON reading_goals(user_id);

-- 6. 함수: 현재 사용자 확인
CREATE OR REPLACE FUNCTION check_user_auth()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION '사용자 인증이 필요합니다';
    END IF;
    
    IF TG_OP = 'INSERT' THEN
        NEW.user_id = auth.uid();
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.user_id != auth.uid() THEN
            RAISE EXCEPTION '본인의 데이터만 수정할 수 있습니다';
        END IF;
        NEW.user_id = auth.uid(); -- user_id 변경 방지
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. 트리거 설정 (이중 보안)
CREATE TRIGGER reviews_auth_trigger
    BEFORE INSERT OR UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION check_user_auth();

CREATE TRIGGER ebooks_auth_trigger
    BEFORE INSERT OR UPDATE ON ebooks
    FOR EACH ROW EXECUTE FUNCTION check_user_auth();

CREATE TRIGGER reading_goals_auth_trigger
    BEFORE INSERT OR UPDATE ON reading_goals
    FOR EACH ROW EXECUTE FUNCTION check_user_auth();

-- 8. achievements 테이블은 공통 데이터 (읽기만 허용)
CREATE TABLE IF NOT EXISTS achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    condition_type TEXT NOT NULL,
    condition_value INTEGER,
    badge_color TEXT DEFAULT 'gold',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "PUBLIC_achievements_select" ON achievements FOR SELECT USING (true);

COMMIT;

-- 최종 확인
DO $$
BEGIN
    RAISE NOTICE '🚨🚨🚨🚨🚨 최종 핵폭탄급 보안 수정 완료! 🚨🚨🚨🚨🚨';
    RAISE NOTICE '✅ 모든 테이블 재생성 완료';
    RAISE NOTICE '✅ user_id 필수 제약조건 적용';
    RAISE NOTICE '✅ 최강 RLS 정책 적용';
    RAISE NOTICE '✅ 트리거 기반 이중 보안 적용';
    RAISE NOTICE '✅ 100% 사용자별 데이터 격리 보장';
    RAISE NOTICE '⚠️ 모든 기존 데이터가 삭제되었습니다';
    RAISE NOTICE '🎯 이제 앱을 재시작하고 새로운 계정으로 테스트하세요!';
END $$;
