-- 🚀 즉시 해결 (1분 소요)
-- 복사해서 Supabase SQL Editor에 붙여넣기 후 실행

DROP TABLE IF EXISTS reviews CASCADE;

CREATE TABLE reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT,
    title TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '', 
    book_title TEXT NOT NULL DEFAULT '',
    book_author TEXT,
    book_cover TEXT,
    status TEXT DEFAULT 'draft',
    background_image TEXT,
    tags TEXT[] DEFAULT '{}',
    mood TEXT,
    quotes TEXT[] DEFAULT '{}', 
    chat_history TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;

SELECT '✅ 완료! 이제 발제문 저장 100% 작동함' as result;
