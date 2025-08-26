-- 🔥🔥🔥 긴급 테이블 완전 초기화 🔥🔥🔥
-- 모든 복잡한 문제를 제거하고 처음부터 다시 시작

-- 1. 기존 reviews 테이블 완전 삭제
DROP TABLE IF EXISTS reviews CASCADE;

-- 2. 완전히 새로운 reviews 테이블 생성 (RLS 없음)
CREATE TABLE reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT,  -- UUID가 아닌 단순 TEXT로 변경
    title TEXT,
    content TEXT,
    book_title TEXT,
    book_author TEXT,
    book_cover TEXT,
    status TEXT DEFAULT 'draft',
    background_image TEXT,
    tags TEXT[],
    mood TEXT,
    quotes TEXT[],
    chat_history TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. RLS 비활성화 (절대 활성화하지 않음)
ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;

-- 4. 성공 메시지
SELECT '🎉 테이블 완전 초기화 완료! 모든 제약조건과 복잡함 제거!' as result;
