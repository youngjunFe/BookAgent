import express from 'express';
import fetch from 'node-fetch';
import cors from 'cors';

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => res.status(200).send('ok'));

app.post('/generate-review', async (req, res) => {
  try {
    const chat = String(req.body?.chat_history || '');
    const title = String(req.body?.book_title || '책');

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      return res.status(200).type('text/plain').send(fallback(title));
    }

    const sysPrompt =
      '당신은 독서 모임을 위한 발제문을 구조적으로 작성하는 도우미입니다.\n' +
      '입력된 대화 요약과 책 제목을 참고하여 6~12문장 분량의 발제문을 한국어로 작성하세요.\n' +
      '마지막에는 토론 질문 3개를 불릿으로 제시하세요.';

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
