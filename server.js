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

    // OpenAI API 호출 (간단한 예시)
    const response = {
      reply: `AI 응답: ${userMessage}에 대한 답변입니다. ${chatContext ? '(컨텍스트 포함)' : ''}`
    };

    res.json(response);
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
