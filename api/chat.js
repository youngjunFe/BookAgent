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
      console.log('No OpenAI API key, using smart fallback');
      return res.status(200).json({ reply: getSmartFallbackResponse(userMessage, bookTitle) });
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

function getSmartFallbackResponse(userMessage, bookTitle) {
  const message = userMessage.toLowerCase();
  const book = bookTitle || '책';
  
  // 인사말
  if (message.includes('안녕') || message.includes('하이') || message.includes('처음')) {
    return `안녕하세요! ${book}에 대해 함께 이야기해봐요. 어떤 부분이 가장 기억에 남으시나요? 📚`;
  }
  
  // 감정 관련
  if (message.includes('감동') || message.includes('좋았') || message.includes('인상')) {
    return `${book}에서 그런 감동을 받으셨군요! 그 장면이나 구절을 더 자세히 설명해주시면 함께 깊이 있게 이야기해볼 수 있을 것 같아요. ✨`;
  }
  
  // 질문이나 궁금증
  if (message.includes('?') || message.includes('궁금') || message.includes('어떻게')) {
    return `좋은 질문이네요! ${book}에 대한 궁금증을 함께 풀어보죠. 어떤 관점에서 접근해보고 싶으신가요? 🤔`;
  }
  
  // 캐릭터나 줄거리 관련
  if (message.includes('주인공') || message.includes('등장인물') || message.includes('줄거리')) {
    return `${book}의 인물들에 대해 이야기해보는 것도 좋겠네요! 어떤 캐릭터가 가장 인상적이었나요? 그 이유도 함께 들려주세요. 👥`;
  }
  
  // 일반적인 응답
  const responses = [
    `${book}에 대한 흥미로운 관점이네요! 더 자세히 들어보고 싶어요.`,
    `정말 좋은 생각이에요! ${book}의 어떤 부분에서 그런 느낌을 받으셨나요?`,
    `${book}을 읽으시면서 느끼신 점들을 더 나눠주시면 함께 이야기해볼 수 있을 것 같아요.`,
    `그런 관점에서 ${book}을 바라보셨군요! 다른 독자들은 어떻게 생각할지도 궁금하네요.`
  ];
  
  return responses[Math.floor(Math.random() * responses.length)];
}

function getFallbackResponse(userMessage) {
  return getSmartFallbackResponse(userMessage, '책');
}
