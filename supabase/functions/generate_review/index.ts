// deno-lint-ignore-file no-explicit-any
// Minimal Edge Function to generate a review from chat history + book title
// If OPENAI_API_KEY is set as a function secret, it will try to call OpenAI; otherwise returns a fallback.

interface GenerateBody {
  chat_history?: string;
  book_title?: string;
}

function fallbackContent(bookTitle?: string): string {
  const title = bookTitle && bookTitle.trim().length > 0 ? bookTitle : '책';
  return (
    `${title}에 대한 발제문\n\n` +
    '이 작품을 읽으며 인상 깊었던 지점과 질문을 정리해보세요.\n' +
    '1) 핵심 메시지\n2) 인물의 변화\n3) 나의 시선 변화\n4) 함께 토론할 질문 2~3개'
  );
}

async function tryOpenAI(chat: string, title: string): Promise<string> {
  const apiKey = Deno.env.get('OPENAI_API_KEY');
  if (!apiKey) return fallbackContent(title);

  try {
    const sysPrompt =
      '당신은 독서 모임을 위한 발제문을 구조적으로 작성하는 도우미입니다.\n' +
      '입력된 대화 요약과 책 제목을 참고하여 6~12문장 분량의 발제문을 한국어로 작성하세요.\n' +
      '마지막에는 토론 질문 3개를 불릿으로 제시하세요.';

    const userPrompt = `책 제목: ${title || '알 수 없음'}\n\n대화 요약:\n${
      chat || '(없음)'
    }\n`;

    // Use OpenAI Chat Completions (compatible endpoint). Adjust model as needed.
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

    if (!resp.ok) return fallbackContent(title);
    const data = await resp.json();
    const content = data?.choices?.[0]?.message?.content as string | undefined;
    return content && content.trim().length > 0
      ? content
      : fallbackContent(title);
  } catch (_) {
    return fallbackContent(title);
  }
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const body = (await req.json().catch(() => ({}))) as GenerateBody;
  const chat = body.chat_history ?? '';
  const title = body.book_title ?? '';

  const content = await tryOpenAI(chat, title);
  return new Response(JSON.stringify({ content }), {
    headers: { 'Content-Type': 'application/json' },
  });
});

