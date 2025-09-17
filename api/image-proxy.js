module.exports = async (req, res) => {
  try {
    const url = (req.query && (req.query.url || req.query.u)) || '';
    if (!url || typeof url !== 'string') {
      res.setHeader('Access-Control-Allow-Origin', '*');
      return res.status(400).json({ error: 'Missing url param' });
    }

    // Allow only http/https
    if (!/^https?:\/\//i.test(url)) {
      res.setHeader('Access-Control-Allow-Origin', '*');
      return res.status(400).json({ error: 'Invalid url' });
    }

    // Fetch the image
    const upstream = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; ImageProxy/1.0)'
      }
    });

    if (!upstream.ok) {
      res.setHeader('Access-Control-Allow-Origin', '*');
      return res.status(upstream.status).json({ error: 'Upstream fetch failed' });
    }

    // Pass through content-type and cache control
    const contentType = upstream.headers.get('content-type') || 'application/octet-stream';
    res.setHeader('Content-Type', contentType);
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cache-Control', 'public, max-age=86400, s-maxage=86400, stale-while-revalidate=604800');

    const arrayBuffer = await upstream.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    return res.status(200).end(buffer);
  } catch (err) {
    console.error('image-proxy error', err);
    res.setHeader('Access-Control-Allow-Origin', '*');
    return res.status(500).json({ error: 'Proxy error' });
  }
};


