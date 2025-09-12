// Vercel 서버리스 함수 - 책 검색 API
export default async function handler(req, res) {
  // CORS 헤더 설정
  res.setHeader('Access-Control-Allow-Credentials', false);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // OPTIONS 요청 처리
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { query } = req.query;
    if (!query) {
      return res.status(400).json({ error: 'Query parameter is required' });
    }

    const clientId = process.env.NAVER_CLIENT_ID || 'pXWwOhZQKs1Z2e6DgpYx';
    const clientSecret = process.env.NAVER_CLIENT_SECRET || 'n_OwRWYfjC';

    console.log('📚 Book search request:', { query });

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
    console.log('📚 Books found:', naverData.items?.length || 0);

    // 응답 데이터 변환
    const books = naverData.items.map((item) => ({
      title: item.title.replace(/<[^>]*>/g, ''), // HTML 태그 제거
      author: item.author.replace(/<[^>]*>/g, ''),
      publisher: item.publisher || '',
      image: item.image || '',
      description: item.description?.replace(/<[^>]*>/g, '') || '',
      isbn: item.isbn || '',
      link: item.link || '',
    }));

    res.status(200).json({
      success: true,
      total: naverData.total,
      books: books,
    });
  } catch (error) {
    console.error('❌ Book search error:', error);
    res.status(500).json({
      success: false,
      error: 'Book search failed',
      message: error.message,
    });
  }
}
