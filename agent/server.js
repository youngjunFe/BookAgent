const express = require('express');
const fetch = require('node-fetch');
const cors = require('cors');
const { getConfigWithDefault } = require('./utils/supabase.js');

const app = express();

// CORS 설정 - 모든 도메인 허용
app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: false,
  })
);

app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => res.status(200).send('ok'));

// AI 채팅 엔드포인트 - DB에서 프롬프트 로드
app.post('/api/chat', async (req, res) => {
  try {
    const {
      message = '',
      context = '',
      bookTitle,
      bookAuthor,
    } = req.body || {};
    const userMessage = String(message);
    const chatContext = String(context);

    console.log('🔥 Chat request:', {
      userMessage,
      hasContext: !!chatContext,
      bookTitle,
    });

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.log('No OpenAI API key, returning fallback');
      return res.status(200).json({ reply: getFallbackResponse(userMessage) });
    }

    // 🔥 DB에서 직접 AI 채팅 프롬프트 가져오기
    const systemPrompt = await getConfigWithDefault(
      'ai_chat_prompt',
      '당신은 친근하고 지식이 풍부한 독서 도우미입니다. ' +
        '사용자와 자연스럽게 대화하며 책에 대해 이야기하세요.'
    );

    console.log(
      '🔥 DB에서 가져온 시스템 프롬프트:',
      systemPrompt.substring(0, 100) + '...'
    );

    const userPrompt = chatContext
      ? `이전 대화:\n${chatContext}\n\n사용자: ${userMessage}`
      : `사용자: ${userMessage}`;

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
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
    const content =
      data?.choices?.[0]?.message?.content || getFallbackResponse(userMessage);

    console.log(
      '🔥 Chat response generated:',
      content.substring(0, 100) + '...'
    );
    return res.status(200).json({ reply: content });
  } catch (error) {
    console.error('Chat function error:', error);
    return res
      .status(200)
      .json({ reply: getFallbackResponse(req.body?.message || '') });
  }
});

function getFallbackResponse(userMessage) {
  if (userMessage.includes('안녕') || userMessage.includes('하이')) {
    return '안녕하세요! 어떤 책에 대해 이야기해보고 싶으신가요? 📚';
  } else if (userMessage.includes('책') || userMessage.includes('소설')) {
    return '흥미로운 선택이네요! 그 책에서 가장 인상 깊었던 부분은 무엇인가요?';
  } else {
    return '정말 좋은 관점이네요! 더 자세히 말씀해주시면 함께 이야기해볼 수 있을 것 같아요.';
  }
}

app.post('/generate-review', async (req, res) => {
  try {
    const chat = String(req.body?.chat_history || '');
    const title = String(req.body?.book_title || '책');

    console.log('🔥 Generate review request:', {
      title,
      chatLength: chat.length,
    });

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      return res.status(200).type('text/plain').send(fallback(title));
    }

    // 🔥 DB에서 직접 감동문 생성 프롬프트 가져오기
    const sysPrompt = await getConfigWithDefault(
      'review_generation_prompt',
      '당신은 독서 모임을 위한 발제문을 구조적으로 작성하는 도우미입니다.\n' +
        '입력된 대화 요약과 책 제목을 참고하여 6~12문장 분량의 발제문을 한국어로 작성하세요.\n' +
        '마지막에는 토론 질문 3개를 불릿으로 제시하세요.'
    );

    console.log(
      '🔥 DB에서 가져온 감동문 생성 프롬프트:',
      sysPrompt.substring(0, 100) + '...'
    );

    const userPrompt = `책 제목: ${title}\n\n대화 요약:\n${chat || '(없음)'}\n`;

    const resp = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: sysPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.7,
      }),
    });

    if (!resp.ok) {
      return res.status(200).type('text/plain').send(fallback(title));
    }
    const data = await resp.json();
    const content = data?.choices?.[0]?.message?.content || fallback(title);
    return res.status(200).type('text/plain').send(content);
  } catch (e) {
    return res
      .status(200)
      .type('text/plain')
      .send(fallback(String(req.body?.book_title || '책')));
  }
});

function fallback(title) {
  return (
    `${title}에 대한 발제문\n\n` +
    '이 작품을 읽으며 인상 깊었던 지점과 질문을 정리해보세요.\n' +
    '1) 핵심 메시지\n2) 인물의 변화\n3) 나의 시선 변화\n4) 함께 토론할 질문 2~3개'
  );
}

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Agent server listening on ${port}`));
