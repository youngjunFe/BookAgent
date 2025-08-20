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
          content:
            '당신은 도서 리뷰와 독서에 도움을 주는 친근한 AI 어시스턴트입니다. 한국어로 답변해주세요.',
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
    const naverResponse = await fetch(`https://openapi.naver.com/v1/search/book.json?query=${encodeURIComponent(query)}&display=10&sort=sim`, {
      method: 'GET',
      headers: {
        'X-Naver-Client-Id': clientId,
        'X-Naver-Client-Secret': clientSecret,
      },
    });

    if (!naverResponse.ok) {
      throw new Error(`Naver API error: ${naverResponse.status}`);
    }

    const naverData = await naverResponse.json();
    
    // 네이버 API 응답을 우리 형식으로 변환
    const books = naverData.items.map(item => ({
      title: item.title.replace(/<[^>]*>/g, ''), // HTML 태그 제거
      author: item.author.replace(/<[^>]*>/g, ''),
      publisher: item.publisher,
      image: item.image || 'https://via.placeholder.com/120x180?text=책',
      description: item.description.replace(/<[^>]*>/g, ''),
      isbn: item.isbn,
      link: item.link
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
        isbn: '9788937460012'
      },
      {
        title: '어린왕자',
        author: '생텍쥐페리',
        publisher: '문학동네',
        image: 'https://via.placeholder.com/120x180?text=어린왕자',
        description: '사랑과 우정, 인생의 의미를 담은 명작',
        isbn: '9788954429818'
      }
    ];

    const filteredBooks = mockBooks.filter(book => 
      book.title.toLowerCase().includes(query.toLowerCase()) ||
      book.author.toLowerCase().includes(query.toLowerCase())
    );

    res.json({ books: filteredBooks });
  }
});

// Review generation endpoint
app.post('/api/generate-review', async (req, res) => {
  try {
    const { bookTitle, content } = req.body || {};

    const response = {
      review: `${bookTitle}에 대한 AI 생성 리뷰: ${content}`,
    };

    res.json(response);
  } catch (error) {
    console.error('Review generation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
