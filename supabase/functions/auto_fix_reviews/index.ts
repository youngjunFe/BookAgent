// 자동 테이블 생성 및 RLS 비활성화 함수
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { supabaseClient } = await import('../_shared/supabase.ts')
    
    // 1. RLS 비활성화
    await supabaseClient.rpc('exec_sql', {
      sql: 'ALTER TABLE IF EXISTS reviews DISABLE ROW LEVEL SECURITY;'
    })

    // 2. 테이블 생성/수정
    await supabaseClient.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS reviews (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id TEXT,
          title TEXT DEFAULT '',
          content TEXT DEFAULT '',
          book_title TEXT DEFAULT '',
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
      `
    })

    return new Response(
      JSON.stringify({ success: true, message: '자동 수정 완료' }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
