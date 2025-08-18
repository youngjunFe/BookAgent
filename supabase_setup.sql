-- Supabase 설정 SQL 스크립트
-- 이 파일을 Supabase 대시보드의 SQL Editor에서 실행하세요

-- 1. ebooks 테이블에 누락된 컬럼들 추가
ALTER TABLE ebooks ADD COLUMN IF NOT EXISTS cover_image_url TEXT;
ALTER TABLE ebooks ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE ebooks ADD COLUMN IF NOT EXISTS genre TEXT DEFAULT '소설';

-- 2. Storage 버킷 생성 (이미 있다면 무시됨)
INSERT INTO storage.buckets (id, name, public)
VALUES ('book-covers', 'book-covers', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage 정책 설정
-- 읽기 정책 (모든 사용자가 이미지 볼 수 있도록)
CREATE POLICY IF NOT EXISTS "Public read access" ON storage.objects 
FOR SELECT USING (bucket_id = 'book-covers');

-- 업로드 정책 (인증된 사용자만 업로드)
CREATE POLICY IF NOT EXISTS "Authenticated upload access" ON storage.objects 
FOR INSERT WITH CHECK (bucket_id = 'book-covers' AND auth.role() = 'authenticated');

-- 삭제 정책 (인증된 사용자만 삭제)
CREATE POLICY IF NOT EXISTS "Authenticated delete access" ON storage.objects 
FOR DELETE USING (bucket_id = 'book-covers' AND auth.role() = 'authenticated');

-- 4. achievements 테이블 생성 (독서 목표용)
CREATE TABLE IF NOT EXISTS achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL, -- 'books_read', 'pages_read', 'reading_time', 'streak'
    category TEXT NOT NULL, -- 'bronze', 'silver', 'gold', 'platinum'
    required_value INTEGER NOT NULL,
    current_value INTEGER DEFAULT 0,
    badge_color TEXT NOT NULL,
    requirement TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. reading_goals 테이블 생성 (독서 목표용)
CREATE TABLE IF NOT EXISTS reading_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    type TEXT NOT NULL, -- 'books', 'pages', 'time'
    target_value INTEGER NOT NULL,
    current_value INTEGER DEFAULT 0,
    deadline DATE,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 기본 achievement 데이터 삽입
INSERT INTO achievements (title, description, type, category, required_value, badge_color, requirement) VALUES
('첫 걸음', '첫 번째 책을 완독하세요', 'books_read', 'bronze', 1, '#CD7F32', '책 1권 완독'),
('독서 애호가', '5권의 책을 완독하세요', 'books_read', 'silver', 5, '#C0C0C0', '책 5권 완독'),
('독서 마스터', '10권의 책을 완독하세요', 'books_read', 'gold', 10, '#FFD700', '책 10권 완독'),
('페이지 터너', '1000페이지를 읽으세요', 'pages_read', 'bronze', 1000, '#CD7F32', '1000페이지 읽기'),
('속독왕', '5000페이지를 읽으세요', 'pages_read', 'silver', 5000, '#C0C0C0', '5000페이지 읽기'),
('독서 연속', '7일 연속 독서하세요', 'streak', 'bronze', 7, '#CD7F32', '7일 연속 독서')
ON CONFLICT (title) DO NOTHING;

-- 7. RLS (Row Level Security) 활성화
ALTER TABLE ebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_goals ENABLE ROW LEVEL SECURITY;

-- 8. RLS 정책 생성
CREATE POLICY IF NOT EXISTS "Users can view all ebooks" ON ebooks FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS "Users can insert ebooks" ON ebooks FOR INSERT WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "Users can update ebooks" ON ebooks FOR UPDATE USING (true);
CREATE POLICY IF NOT EXISTS "Users can delete ebooks" ON ebooks FOR DELETE USING (true);

CREATE POLICY IF NOT EXISTS "Users can view all achievements" ON achievements FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS "Users can update achievements" ON achievements FOR UPDATE USING (true);

CREATE POLICY IF NOT EXISTS "Users can manage their goals" ON reading_goals FOR ALL USING (true);

