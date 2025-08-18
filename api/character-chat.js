module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { message = '', characterName = '', context = '' } = req.body || {};

    console.log('Character chat request received:', {
      message,
      characterName,
      context,
    });

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.log('No OpenAI API key for character chat, returning fallback');
      return res
        .status(200)
        .send(fallbackCharacterResponse(message, characterName));
    }

    const systemPrompt = getCharacterSystemPrompt(characterName);

    const messages = [{ role: 'system', content: systemPrompt }];

    if (context) {
      // 이전 대화 내용을 메시지 배열에 추가
      context.split('\n').forEach((line) => {
        if (line.startsWith('사용자: ')) {
          messages.push({ role: 'user', content: line.substring(5) });
        } else if (line.startsWith(characterName + ': ')) {
          messages.push({
            role: 'assistant',
            content: line.substring(characterName.length + 2),
          });
        }
      });
    }
    messages.push({ role: 'user', content: message });

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: messages,
        temperature: 0.8,
        max_tokens: 300,
      }),
    });

    if (!response.ok) {
      console.log(
        'OpenAI Character Chat API error:',
        response.status,
        await response.text()
      );
      return res
        .status(200)
        .send(fallbackCharacterResponse(message, characterName));
    }

    const data = await response.json();
    const content =
      data?.choices?.[0]?.message?.content ||
      fallbackCharacterResponse(message, characterName);

    console.log(
      'Generated character content:',
      content.substring(0, 100) + '...'
    );
    return res.status(200).send(content);
  } catch (error) {
    console.error('Character chat function error:', error);
    return res
      .status(200)
      .send(fallbackCharacterResponse(message, characterName));
  }
};

function getCharacterSystemPrompt(characterName) {
  switch (characterName) {
    case '해리 포터':
      return '당신은 해리 포터입니다. 호그와트 마법학교의 학생이고, 볼드모트와 맞서 싸우는 용감한 마법사입니다. 친근하고 겸손하며, 친구들을 소중히 여깁니다. 마법에 대해 이야기할 때는 흥미롭게, 어려운 상황에 대해서는 용기 있게 대답하세요. 한국어로 자연스럽게 대화하되, 가끔 마법 주문이나 호그와트 관련 용어를 사용해도 좋습니다.';

    case '셜록 홈즈':
      return '당신은 셜록 홈즈입니다. 뛰어난 관찰력과 추리력을 가진 세계 최고의 탐정입니다. 논리적이고 분석적이며, 세세한 부분까지 놓치지 않습니다. 약간 거만할 수 있지만 정의로우며, 미스터리와 사건 해결에 열정적입니다. 한국어로 대화하되, 추리와 관찰에 관한 이야기를 할 때는 특히 자세하고 흥미롭게 설명해주세요.';

    case '엘리자베스 베넷':
      return '당신은 제인 오스틴의 "오만과 편견"의 엘리자베스 베넷입니다. 지적이고 독립적이며, 유머 감각이 뛰어납니다. 사회의 관습에 얽매이지 않고 자신의 의견을 당당히 표현합니다. 사랑과 결혼, 사회적 관습에 대해 깊이 있게 이야기할 수 있으며, 따뜻하면서도 재치 있는 대화를 나눕니다. 한국어로 자연스럽게 대화하세요.';

    case '아라곤':
      return '당신은 반지의 제왕의 아라곤입니다. 곤도르의 왕이 될 운명을 가진 덜네다인 순찰대원이자 용감한 전사입니다. 겸손하고 충성스러우며, 중간계의 평화를 위해 싸웁니다. 리더십이 뛰어나고 동료들을 보호하려는 마음이 강합니다. 모험과 우정, 용기에 대해 이야기할 때 깊이 있고 감동적으로 대답하세요. 한국어로 대화하되, 가끔 중간계 관련 용어를 사용해도 좋습니다.';

    case '김춘삼':
      return '당신은 한국 문학의 김춘삼입니다. 새로운 세상에 대한 꿈과 희망을 가진 인물로, 변화하는 시대 속에서 자신만의 길을 찾아가는 캐릭터입니다. 진솔하고 인간적이며, 때로는 고민에 빠지기도 하지만 결국 앞으로 나아가는 의지를 보입니다. 한국적 정서와 현실적 고민을 바탕으로 따뜻하고 진실한 대화를 나누세요.';

    default:
      return `당신은 "${characterName}"이라는 문학 캐릭터입니다. 이 캐릭터의 성격과 배경에 맞게 대화하며, 독자와 의미 있는 소통을 나누세요. 한국어로 자연스럽게 대화하세요.`;
  }
}

function fallbackCharacterResponse(userMessage, characterName) {
  switch (characterName) {
    case '해리 포터':
      if (userMessage.includes('마법') || userMessage.includes('호그와트')) {
        return '호그와트에서 배운 마법은 정말 놀라워요! 어떤 마법에 대해 더 알고 싶으신가요? ⚡';
      }
      return '흥미로운 이야기네요! 론과 헤르미온느에게도 꼭 들려주고 싶어요. 🪄';

    case '셜록 홈즈':
      return '흥미로운 관찰이군요. 더 자세한 단서가 있다면 들려주시겠습니까? 🔍';

    case '엘리자베스 베넷':
      return '정말 흥미로운 관점이에요! 그에 대한 당신의 생각을 더 자세히 듣고 싶어요. 💭';

    case '아라곤':
      return '지혜로운 말씀입니다. 그런 경험이 우리를 더 강하게 만드는 것 같아요. ⚔️';

    case '김춘삼':
      return '그런 생각을 해보신 거군요. 저도 비슷한 고민을 해본 적이 있어요. 🌟';

    default:
      return '흥미로운 말씀이네요! 더 자세히 이야기해주시겠어요?';
  }
}

