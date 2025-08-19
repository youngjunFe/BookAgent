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
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "당신은 도서 리뷰와 독서에 도움을 주는 친근한 AI 어시스턴트입니다. 한국어로 답변해주세요."
        },
        {
          role: "user",
          content: chatContext ? `컨텍스트: ${chatContext}\n\n질문: ${userMessage}` : userMessage
        }
      ],
      max_tokens: 1000,
      temperature: 0.7
    });

    const aiReply = completion.choices[0]?.message?.content || '죄송합니다. 응답을 생성할 수 없습니다.';

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
      reply: `${character} 캐릭터로서 답변: ${message}`
    };

    res.json(response);
  } catch (error) {
    console.error('Character chat error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Review generation endpoint
app.post('/api/generate-review', async (req, res) => {
  try {
    const { bookTitle, content } = req.body || {};
    
    const response = {
      review: `${bookTitle}에 대한 AI 생성 리뷰: ${content}`
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
