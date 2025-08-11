module.exports = async (req, res) => {
  // CORS 헤더 설정
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
    const { chat_history = '', book_title = '책' } = req.body || {};
    const chat = String(chat_history);
    const title = String(book_title);

    console.log('Request received:', { chat, title });

    // OpenAI API 키가 없으면 fallback 메시지 반환
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.log('No OpenAI API key, returning fallback');
      return res.status(200).send(fallback(title));
    }

    const systemPrompt =
      '당신은 독서 모임 발제문 도우미입니다.\n' +
      '입력된 대화 요약과 책 제목을 참고해 6~12문장 한국어 발제문을 작성하고, 마지막에 토론 질문 3개를 불릿으로 제시하세요.';

    const userPrompt = `책 제목: ${title}\n\n대화 요약:\n${chat || '(없음)'}\n`;

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
      }),
    });

    if (!response.ok) {
      console.log('OpenAI API error:', response.status);
      return res.status(200).send(fallback(title));
    }

    const data = await response.json();
    const content = data?.choices?.[0]?.message?.content || fallback(title);

    console.log('Generated content:', content.substring(0, 100) + '...');
    return res.status(200).send(content);
  } catch (error) {
    console.error('Function error:', error);
    const title = req.body?.book_title || '책';
    return res.status(200).send(fallback(title));
  }
};

function fallback(title) {
  return (
    `${title}에 대한 발제문\n\n` +
    '이 작품을 읽으며 인상 깊었던 지점과 질문을 정리해보세요.\n' +
    '1) 핵심 메시지\n2) 인물의 변화\n3) 나의 시선 변화\n4) 함께 토론할 질문 2~3개'
  );
}
