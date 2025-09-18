const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// CORS 설정 - 모든 도메인 허용
app.use(
  cors({
    origin: true, // 모든 도메인 허용
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'Accept',
      'X-Requested-With',
    ],
    credentials: false,
    optionsSuccessStatus: 200,
  })
);

// 추가 CORS 헤더 설정
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization, Accept, X-Requested-With'
  );

  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Preflight 요청 처리
app.options('*', cors());

app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'Book Review API is running!' });
});

// Chat endpoint
app.post('/api/chat', async (req, res) => {
  try {
    const { message = '', context = '', systemPrompt, bookTitle, bookAuthor } = req.body || {};
    const userMessage = String(message);
    const chatContext = String(context);

    console.log('🔥 Chat request:', {
      userMessage: userMessage.substring(0, 100),
      hasContext: !!chatContext,
      hasSystemPrompt: !!systemPrompt,
      bookTitle,
      bookAuthor
    });

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.log('❌ OpenAI API key not found');
      return res.status(401).json({ error: 'OPENAI_API_KEY missing' });
    }

    try {
      // OpenAI API 호출
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: systemPrompt || '당신은 도서 리뷰와 독서에 도움을 주는 친근한 AI 어시스턴트입니다. 한국어로 자연스럽게 대화하듯 답변해주세요.'
            },
            {
              role: 'user',
              content: chatContext
                ? `이전 대화: ${chatContext}\n\n현재 질문: ${userMessage}`
                : userMessage,
            },
          ],
          max_tokens: 500,
          temperature: 0.7,
        }),
      });

      if (!response.ok) {
        console.log(`❌ OpenAI API error: ${response.status}`);
        return res.status(response.status).json({ error: 'OpenAI API error', status: response.status });
      }

      const data = await response.json();
      const aiReply = data?.choices?.[0]?.message?.content || getSmartFallbackResponse(userMessage, bookTitle);

      console.log('✅ Chat response generated:', aiReply.substring(0, 100) + '...');
      res.json({ reply: aiReply });

    } catch (openaiError) {
      console.error('❌ OpenAI API call failed:', openaiError);
      return res.status(502).json({ error: 'Upstream OpenAI error' });
    }

  } catch (error) {
    console.error('❌ Chat API error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

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

  if (message.includes('슬프') || message.includes('아프') || message.includes('우울')) {
    return `그런 감정을 느끼셨군요. ${book}을 읽으면서 마음이 많이 흔들렸을 것 같아요. 어떤 장면에서 특히 그런 감정을 느끼셨나요?`;
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
    `그런 관점에서 ${book}을 바라보셨군요! 다른 독자들은 어떻게 생각할지도 궁금하네요.`,
    `${book}에서 가장 인상 깊었던 순간은 언제였나요? 그 감정을 좀 더 자세히 나눠보실 수 있을까요?`
  ];

  return responses[Math.floor(Math.random() * responses.length)];
}

// Character chat endpoint
app.post('/api/character-chat', async (req, res) => {
  try {
    const { character, message } = req.body || {};

    const response = {
      reply: `${character} 캐릭터로서 답변: ${message}`,
    };

    res.json(response);
  } catch (error) {
    console.error('Character chat error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Naver Book Search endpoint
app.get('/api/search-books', async (req, res) => {
  try {
    const { query } = req.query;
    if (!query) {
      return res.status(400).json({ error: 'Query parameter is required' });
    }

    const clientId = process.env.NAVER_CLIENT_ID || 'pXWwOhZQKs1Z2e6DgpYx';
    const clientSecret = process.env.NAVER_CLIENT_SECRET || 'n_OwRWYfjC';

    // 네이버 도서 검색 API 호출
    const naverResponse = await fetch(
      `https://openapi.naver.com/v1/search/book.json?query=${encodeURIComponent(
        query
      )}&display=10&sort=sim`,
      {
        method: 'GET',
        headers: {
          'X-Naver-Client-Id': clientId,
          'X-Naver-Client-Secret': clientSecret,
        },
      }
    );

    if (!naverResponse.ok) {
      throw new Error(`Naver API error: ${naverResponse.status}`);
    }

    const naverData = await naverResponse.json();

    // 네이버 API 응답을 우리 형식으로 변환
    const books = naverData.items.map((item) => ({
      title: item.title.replace(/<[^>]*>/g, ''), // HTML 태그 제거
      author: item.author.replace(/<[^>]*>/g, ''),
      publisher: item.publisher,
      image: item.image || 'https://via.placeholder.com/120x180?text=책',
      description: item.description.replace(/<[^>]*>/g, ''),
      isbn: item.isbn,
      link: item.link,
    }));

    res.json({ books });
  } catch (error) {
    console.error('Book search error:', error);

    // 에러 시 목 데이터 반환
    const mockBooks = [
      {
        title: '데미안',
        author: '헤르만 헤세',
        publisher: '민음사',
        image: 'https://via.placeholder.com/120x180?text=데미안',
        description: '한 소년의 성장과 자아 발견의 여정을 그린 작품',
        isbn: '9788937460012',
      },
      {
        title: '어린왕자',
        author: '생텍쥐페리',
        publisher: '문학동네',
        image: 'https://via.placeholder.com/120x180?text=어린왕자',
        description: '사랑과 우정, 인생의 의미를 담은 명작',
        isbn: '9788954429818',
      },
    ];

    const filteredBooks = mockBooks.filter(
      (book) =>
        book.title.toLowerCase().includes(query.toLowerCase()) ||
        book.author.toLowerCase().includes(query.toLowerCase())
    );

    res.json({ books: filteredBooks });
  }
});

// Review generation endpoint
app.post('/api/generate-review', async (req, res) => {
  try {
    const { bookTitle, content, chatHistory } = req.body || {};

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error('OpenAI API key not found');
      return res.status(500).json({ error: 'OpenAI API key not configured' });
    }

    // OpenAI API 호출
    const OpenAI = require('openai');
    const openai = new OpenAI({ apiKey });

    const prompt = `다음은 "${bookTitle}"에 대한 독자와 AI의 대화 내용입니다:

${chatHistory || content}

위 대화 내용을 바탕으로 "${bookTitle}"에 대한 깊이 있는 발제문을 작성해주세요. 다음 요소들을 포함해주세요:

1. 책의 핵심 주제와 메시지
2. 독자가 느낀 감동과 깨달음
3. 개인적인 해석과 의미
4. 다른 사람들과 나누고 싶은 생각

발제문은 한국어로 작성하고, 개인적이고 진솔한 톤으로 써주세요.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content:
            '당신은 독서 발제문 작성 전문가입니다. 독자의 감정과 생각을 잘 정리하여 깊이 있는 발제문을 작성해주세요.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      max_tokens: 1500,
      temperature: 0.8,
    });

    const generatedReview =
      completion.choices[0]?.message?.content || '발제문 생성에 실패했습니다.';

    res.json({ review: generatedReview });
  } catch (error) {
    console.error('Review generation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
