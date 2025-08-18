-- 간단한 Supabase 설정 SQL (문법 오류 수정)
-- 이 파일을 Supabase 대시보드의 SQL Editor에서 실행하세요

-- 1. ebooks 테이블에 누락된 컬럼들 추가
ALTER TABLE ebooks ADD COLUMN IF NOT EXISTS cover_image_url TEXT;
ALTER TABLE ebooks ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE ebooks ADD COLUMN IF NOT EXISTS genre TEXT DEFAULT '소설';

-- 2. Storage 버킷 생성 (이미 있다면 무시됨)
INSERT INTO storage.buckets (id, name, public)
VALUES ('book-covers', 'book-covers', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage 정책 설정 (기존 정책이 있으면 삭제 후 생성)
DROP POLICY IF EXISTS "Public read access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete access" ON storage.objects;

-- 읽기 정책
CREATE POLICY "Public read access" ON storage.objects 
FOR SELECT USING (bucket_id = 'book-covers');

-- 업로드 정책  
CREATE POLICY "Authenticated upload access" ON storage.objects 
FOR INSERT WITH CHECK (bucket_id = 'book-covers');

-- 삭제 정책
CREATE POLICY "Authenticated delete access" ON storage.objects 
FOR DELETE USING (bucket_id = 'book-covers');

-- 4. achievements 테이블 생성
CREATE TABLE IF NOT EXISTS achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    category TEXT NOT NULL,
    required_value INTEGER NOT NULL,
    current_value INTEGER DEFAULT 0,
    badge_color TEXT NOT NULL,
    requirement TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. reading_goals 테이블 생성
CREATE TABLE IF NOT EXISTS reading_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID,
    type TEXT NOT NULL,
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

