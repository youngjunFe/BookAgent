import { createClient } from '@supabase/supabase-js';

// Supabase 설정
const supabaseUrl = process.env.SUPABASE_URL || 'https://bssiddbhnuguloktqsmy.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzc2lkZGJobnVndWxva3Rxc215Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjMwODM4MDQsImV4cCI6MjAzODY1OTgwNH0.Zt8c_TqAzPuGNF4QHpOzDNgfAaXQJO3Uo8bAKbPXCkM';

const supabase = createClient(supabaseUrl, supabaseKey);

// DB에서 설정값 가져오기
async function getConfigWithDefault(key, defaultValue) {
  try {
    const { data, error } = await supabase
      .from('admin_configs')
      .select('config_value')
      .eq('config_key', key)
      .eq('is_active', true)
      .single();

    if (error) {
      console.log(`❌ 설정 로드 실패 (${key}):`, error.message);
      return defaultValue;
    }

    console.log(`✅ 설정 로드 성공 (${key}): ${data.config_value?.substring(0, 50)}...`);
    return data.config_value || defaultValue;
  } catch (e) {
    console.log(`❌ 설정 로드 에러 (${key}):`, e.message);
    return defaultValue;
  }
}

export default async function handler(req, res) {
  // CORS 설정
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { message = '', context = '', bookTitle, bookAuthor } = req.body || {};
    const userMessage = String(message);
    const chatContext = String(context);

    console.log('🔥 Vercel Chat request:', { 
      userMessage, 
      hasContext: !!chatContext, 
      bookTitle
    });

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.log('No OpenAI API key, returning fallback');
      return res.status(200).json({ reply: getFallbackResponse(userMessage) });
    }

    // 🔥 DB에서 직접 AI 채팅 프롬프트 가져오기
    const systemPrompt = await getConfigWithDefault(
      'ai_chat_prompt',
      '당신은 친근하고 지식이 풍부한 독서 도우미입니다.'
    );

    console.log('🔥 Vercel - DB에서 가져온 시스템 프롬프트:', systemPrompt.substring(0, 100) + '...');

    const userPrompt = chatContext 
      ? `이전 대화:\n${chatContext}\n\n사용자: ${userMessage}`
      : `사용자: ${userMessage}`;

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 500,
      }),
    });

    if (!response.ok) {
      console.log('OpenAI API error:', response.status);
      return res.status(200).json({ reply: getFallbackResponse(userMessage) });
    }

    const data = await response.json();
    const content = data?.choices?.[0]?.message?.content || getFallbackResponse(userMessage);
    
    console.log('🔥 Vercel Chat response generated:', content.substring(0, 100) + '...');
    return res.status(200).json({ reply: content });

  } catch (error) {
    console.error('Vercel Chat function error:', error);
    return res.status(200).json({ reply: getFallbackResponse(req.body?.message || '') });
  }
}

function getFallbackResponse(userMessage) {
  if (userMessage.includes('안녕') || userMessage.includes('하이')) {
    return '안녕하세요! 어떤 책에 대해 이야기해보고 싶으신가요? 📚';
  } else if (userMessage.includes('책') || userMessage.includes('소설')) {
    return '흥미로운 선택이네요! 그 책에서 가장 인상 깊었던 부분은 무엇인가요?';
  } else {
    return '정말 좋은 관점이네요! 더 자세히 말씀해주시면 함께 이야기해볼 수 있을 것 같아요.';
  }
}
