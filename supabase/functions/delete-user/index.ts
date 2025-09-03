// Edge Function: 사용자 완전 삭제
// 경로: supabase/functions/delete-user/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 요청에서 사용자 정보 추출
    const { user_id } = await req.json()

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: 'user_id is required' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Authorization 헤더에서 JWT 토큰 확인
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Supabase 클라이언트 생성 (서비스 역할 키 사용)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // 요청자가 삭제하려는 사용자와 같은 사용자인지 확인
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (userError || !user || user.id !== user_id) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: can only delete your own account' }),
        { 
          status: 403, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log(`🗑️ [delete-user] 사용자 삭제 시작: ${user.email} (${user_id})`)

    // 1단계: 관련 테이블에서 사용자 데이터 삭제
    const tables = ['reviews', 'reading_goals', 'ebooks', 'achievements', 'profiles']
    
    for (const table of tables) {
      try {
        const { error: deleteError } = await supabaseAdmin
          .from(table)
          .delete()
          .eq(table === 'profiles' ? 'id' : 'user_id', user_id)

        if (deleteError) {
          console.log(`⚠️ [delete-user] ${table} 테이블 삭제 실패 (테이블 없음?): ${deleteError.message}`)
        } else {
          console.log(`✅ [delete-user] ${table} 테이블 데이터 삭제 완료`)
        }
      } catch (tableError) {
        console.log(`⚠️ [delete-user] ${table} 테이블 에러: ${tableError}`)
      }
    }

    // 2단계: Authentication에서 실제 사용자 계정 삭제
    try {
      const { error: authDeleteError } = await supabaseAdmin.auth.admin.deleteUser(user_id)

      if (authDeleteError) {
        console.log(`❌ [delete-user] Auth 계정 삭제 실패: ${authDeleteError.message}`)
        return new Response(
          JSON.stringify({ 
            success: false, 
            error: `Authentication 계정 삭제 실패: ${authDeleteError.message}` 
          }),
          { 
            status: 500, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      console.log(`🎉 [delete-user] 완전한 계정 삭제 성공: ${user.email}`)

      return new Response(
        JSON.stringify({ 
          success: true, 
          message: '계정이 완전히 삭제되었습니다',
          deleted_user_id: user_id,
          deleted_email: user.email
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )

    } catch (authError) {
      console.log(`❌ [delete-user] Auth 삭제 예외: ${authError}`)
      
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `계정 삭제 중 오류 발생: ${authError}` 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

  } catch (error) {
    console.log(`❌ [delete-user] 전체 에러: ${error}`)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: `삭제 처리 중 오류: ${error}` 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
