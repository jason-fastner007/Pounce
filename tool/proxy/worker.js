// Minimal CORS proxy for the web build (Cloudflare Worker or similar).
// Call: https://<worker>/?url=<encoded>
//  - SoundCloud API and lyrics sources without CORS (KuGou) via a fixed allow list.
//  - Radio (&radio=1): arbitrary http(s) streams, but only if the server returns audio
//    (fixes "mixed content" for http stations on an https page). Not an open proxy.
const ALLOWED = /^https:\/\/((api-v2|api-mobile|api-auth)\.soundcloud\.com|soundcloud\.com|a-v2\.sndcdn\.com|wave\.sndcdn\.com|mobileservice\.kugou\.com|lyrics\.kugou\.com)\//;
const AUDIO = /^(audio\/|application\/(ogg|vnd\.apple\.mpegurl|x-mpegurl)|video\/mp2t)/i;

export default {
  async fetch(req) {
    const cors = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Accept, Content-Type, Authorization, App-Version, UDID, Range',
      'Access-Control-Expose-Headers': 'Content-Range, Content-Length, icy-name, icy-genre',
    };
    if (req.method === 'OPTIONS') return new Response(null, { headers: cors });

    const params = new URL(req.url).searchParams;
    const target = params.get('url');
    const radio = params.get('radio') === '1';
    if (!target || !(radio ? /^https?:\/\//.test(target) : ALLOWED.test(target))) {
      return new Response('forbidden', { status: 403, headers: cors });
    }
    if (radio && req.method !== 'GET') return new Response('forbidden', { status: 403, headers: cors });

    const headers = { 'User-Agent': 'Mozilla/5.0' };
    for (const h of ['accept', 'content-type', 'authorization', 'app-version', 'udid', 'range']) {
      const v = req.headers.get(h);
      if (v) headers[h] = v;
    }
    const res = await fetch(target, {
      method: req.method,
      headers,
      body: ['POST', 'PUT'].includes(req.method) ? await req.arrayBuffer() : undefined,
    });
    if (radio && !AUDIO.test(res.headers.get('content-type') || '')) {
      return new Response('not audio', { status: 415, headers: cors });
    }
    const out = new Response(res.body, res);
    for (const [k, v] of Object.entries(cors)) out.headers.set(k, v);
    return out;
  },
};
