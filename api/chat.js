module.exports = async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { message = '', context = '', systemPrompt: customPrompt, bookTitle, bookAuthor } = req.body || {};
    const userMessage = String(message);
    const chatContext = String(context);

    console.log('🔥 Chat request:', { 
      userMessage, 
      hasContext: !!chatContext, 
      hasCustomPrompt: !!customPrompt,
      bookTitle,
      promptLength: customPrompt?.length || 0
    });

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.log('No OpenAI API key, returning fallback');
      return res.status(200).json({ reply: getFallbackResponse(userMessage) });
    }

    // 클라이언트에서 전달한 프롬프트 사용 (우선순위)
    const systemPrompt = customPrompt || (
      '당신은 친근하고 지식이 풍부한 독서 도우미입니다. ' +
      '사용자와 자연스럽게 대화하며 책에 대해 이야기하세요. ' +
      '발제문이 아닌 일반적인 대화 형식으로 응답하고, ' +
      '책 추천, 독서 경험 공유, 책 내용 토론 등을 도와주세요.'
    );

    console.log('🔥 사용 중인 시스템 프롬프트:', systemPrompt.substring(0, 100) + '...');

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
    const content = data?.choices?.[0]?.message?.content || getFallbackResponse(userMessage);

    console.log('🔥 Chat response generated:', content.substring(0, 100) + '...');
    res.setHeader('Access-Control-Allow-Origin', '*');
    return res.status(200).json({ reply: content });
  } catch (error) {
    console.error('Chat function error:', error);
    res.setHeader('Access-Control-Allow-Origin', '*');
    return res.status(200).json({ reply: getFallbackResponse(req.body?.message || '') });
  }
};

function getFallbackResponse(userMessage) {
  if (userMessage.includes('안녕') || userMessage.includes('하이')) {
    return '안녕하세요! 어떤 책에 대해 이야기해보고 싶으신가요? 📚';
  } else if (userMessage.includes('책') || userMessage.includes('소설')) {
    return '흥미로운 선택이네요! 그 책에서 가장 인상 깊었던 부분은 무엇인가요?';
  } else {
    return '정말 좋은 관점이네요! 더 자세히 말씀해주시면 함께 이야기해볼 수 있을 것 같아요.';
  }
}
