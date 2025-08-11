module.exports = async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader(
      'Access-Control-Allow-Headers',
      'Content-Type, Authorization'
    );
    return res.status(204).end();
  }

  if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

  const chat = String((req.body && req.body.chat_history) || '');
  const title = String((req.body && req.body.book_title) || '책');
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    return res.status(200).type('text/plain').send(fallback(title));
  }

  try {
    const sys =
      '당신은 독서 모임 발제문 도우미입니다.\n' +
      '입력된 대화 요약과 책 제목을 참고해 6~12문장 한국어 발제문을 작성하고, 마지막에 토론 질문 3개를 불릿으로 제시하세요.';
    const user = `책 제목: ${title}\n\n대화 요약:\n${chat || '(없음)'}\n`;

    const r = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: sys },
          { role: 'user', content: user },
        ],
        temperature: 0.7,
      }),
    });

    if (!r.ok) {
      res.setHeader('Access-Control-Allow-Origin', '*');
      return res.status(200).type('text/plain').send(fallback(title));
    }
    const data = await r.json();
    const content =
      (data &&
        data.choices &&
        data.choices[0] &&
        data.choices[0].message &&
        data.choices[0].message.content) ||
      fallback(title);
    res.setHeader('Access-Control-Allow-Origin', '*');
    return res.status(200).type('text/plain').send(content);
  } catch (e) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    return res.status(200).type('text/plain').send(fallback(title));
  }
};

function fallback(title) {
  return (
    `${title}에 대한 발제문\n\n` +
    '이 작품을 읽으며 인상 깊었던 지점과 질문을 정리해보세요.\n' +
    '1) 핵심 메시지\n2) 인물의 변화\n3) 나의 시선 변화\n4) 함께 토론할 질문 2~3개'
  );
}
