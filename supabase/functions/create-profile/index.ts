import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// 한국어 닉네임 생성 함수
function generateKoreanNickname(): string {
  const adjectives = [
    '귀여운',
    '사랑스러운',
    '멋진',
    '아름다운',
    '즐거운',
    '행복한',
    '신나는',
    '밝은',
    '따뜻한',
    '포근한',
    '달콤한',
    '부드러운',
    '고요한',
    '평화로운',
    '활기찬',
    '생기발랄한',
  ];

  const animals = [
    '고양이',
    '강아지',
    '토끼',
    '곰',
    '여우',
    '사자',
    '호랑이',
    '판다',
    '코알라',
    '다람쥐',
    '햄스터',
    '고슴도치',
    '펭귄',
    '돌고래',
    '고래',
    '물개',
  ];

  const objects = [
    '별',
    '달',
    '태양',
    '구름',
    '바다',
    '산',
    '강',
    '꽃',
    '나무',
    '잎',
    '책',
    '연필',
    '붓',
    '음표',
    '하트',
    '다이아',
    '보석',
    '진주',
  ];

  const colors = [
    '빨간',
    '파란',
    '노란',
    '초록',
    '보라',
    '분홍',
    '주황',
    '하얀',
  ];

  const pattern = Math.floor(Math.random() * 4) + 1;
  let nickname = '';

  switch (pattern) {
    case 1:
      nickname =
        adjectives[Math.floor(Math.random() * adjectives.length)] +
        animals[Math.floor(Math.random() * animals.length)];
      break;
    case 2:
      nickname =
        colors[Math.floor(Math.random() * colors.length)] +
        objects[Math.floor(Math.random() * objects.length)];
      break;
    case 3:
      nickname =
        adjectives[Math.floor(Math.random() * adjectives.length)] +
        objects[Math.floor(Math.random() * objects.length)];
      break;
    default:
      nickname =
        colors[Math.floor(Math.random() * colors.length)] +
        animals[Math.floor(Math.random() * animals.length)];
  }

  return nickname;
}

serve(async (req) => {
  try {
    // CORS 헤더
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers':
        'authorization, x-client-info, apikey, content-type',
    };

    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders });
    }

    // Supabase 클라이언트 생성 (service_role 키 사용)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 요청에서 사용자 정보 가져오기
    const { user_id, email, provider = 'email' } = await req.json();

    if (!user_id || !email) {
      return new Response(
        JSON.stringify({ error: '사용자 ID와 이메일이 필요합니다' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    console.log('프로필 생성 시작:', { user_id, email, provider });

    // 중복 체크 및 고유 닉네임 생성
    let nickname = generateKoreanNickname();
    let counter = 1;

    while (counter <= 10) {
      const { data: existing } = await supabase
        .from('profiles')
        .select('id')
        .eq('nickname', nickname)
        .maybeSingle();

      if (!existing) break; // 중복 없으면 사용

      nickname = generateKoreanNickname() + counter;
      counter++;
    }

    console.log('생성된 닉네임:', nickname);

    // 프로필 생성/업데이트
    const { data, error } = await supabase.from('profiles').upsert({
      id: user_id,
      email: email,
      nickname: nickname,
      full_name: nickname,
      provider: provider,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    if (error) {
      console.error('프로필 생성 실패:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('프로필 생성 성공:', { nickname, user_id });

    return new Response(
      JSON.stringify({
        success: true,
        nickname: nickname,
        message: '프로필이 성공적으로 생성되었습니다',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Edge Function 에러:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});

