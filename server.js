const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'Book Review API is running!' });
});

// Chat endpoint
app.post('/api/chat', async (req, res) => {
  try {
    const { message = '', context = '' } = req.body || {};
    const userMessage = String(message);
    const chatContext = String(context);

    console.log('Chat request:', { userMessage, hasContext: !!chatContext });

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error('OpenAI API key not found');
      return res.status(500).json({ error: 'OpenAI API key not configured' });
    }

    // OpenAI API 호출
    const OpenAI = require('openai');
    const openai = new OpenAI({ apiKey });

    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: `당신은 도서 리뷰와 독서에 도움을 주는 친근한 AI 어시스턴트입니다. 한국어로 답변해주세요.

[대화 흐름]
- AI는 사용자의 감정을 먼저 묻는 공감형 질문으로 대화를 시작한다. (e.g., "이 책을 덮고 가장 먼저 든 감정이나 생각은 무엇이었나요?") 
- 사용자의 답변에 따라 감정을 인정하고 생각을 확장시키는 꼬리 질문을 1~3회 추가 제시

대화 스타일:
- 공감적이고 따뜻한 톤
- 사용자의 감정과 생각을 깊이 탐구
- 책의 내용과 연결된 개인적 경험 질문
- 짧고 명확한 질문으로 대화 유도`,
        },
        {
          role: 'user',
          content: chatContext
            ? `컨텍스트: ${chatContext}\n\n질문: ${userMessage}`
            : userMessage,
        },
      ],
      max_tokens: 1000,
      temperature: 0.7,
    });

    const aiReply =
      completion.choices[0]?.message?.content ||
      '죄송합니다. 응답을 생성할 수 없습니다.';

    res.json({ reply: aiReply });
  } catch (error) {
    console.error('Chat API error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

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

위 대화 내용을 바탕으로 "${bookTitle}"에 대한 깊이 있는 발제문을 작성해주세요.

[발제문(리뷰) 생성 요구사항]
발제문은 다음 4가지 요소를 반드시 포함해야 합니다:

①핵심 주장: 이 책에 대한 독자의 주요 견해와 해석
②인용구: 책에서 인상 깊었던 구절이나 대화에서 언급된 내용
③토론 질문: 다른 독자들과 나누고 싶은 생각거리나 질문
④제목: 발제문의 핵심을 담은 매력적인 제목

발제문 구조:
- 제목 (창의적이고 감정이 담긴)
- 서론 (독서 경험과 첫인상)
- 본론 (핵심 주장과 개인적 해석, 인용구 포함)
- 결론 (토론 질문과 다른 독자들에게 하고 싶은 말)

톤앤매너: 개인적이고 진솔하며, 감정이 살아있는 한국어로 작성해주세요.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: '당신은 독서 발제문 작성 전문가입니다. 독자의 감정과 생각을 잘 정리하여 깊이 있는 발제문을 작성해주세요.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      max_tokens: 1500,
      temperature: 0.8,
    });

    const generatedReview = completion.choices[0]?.message?.content || '발제문 생성에 실패했습니다.';

    res.json({ review: generatedReview });
  } catch (error) {
    console.error('Review generation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
