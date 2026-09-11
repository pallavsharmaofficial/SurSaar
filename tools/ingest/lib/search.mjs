// Finds candidate chord-sheet pages for a query.
//
// Providers:
//   - "sources": query each allow-listed site's own search page (default)
//   - "ddg": DuckDuckGo HTML results, filtered to allow-listed hosts
//   - "url": a URL was given explicitly – no search
// Only hosts present in sources.json are ever fetched, so the operator
// controls which sites are used and can honour their terms of service.

import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));

export async function loadSources(file = path.join(here, '..', 'sources.json')) {
  const json = JSON.parse(await readFile(file, 'utf8'));
  return json.sources || [];
}

export function isAllowed(url, sources) {
  try {
    const host = new URL(url).hostname.replace(/^www\./, '');
    return sources.some((s) => host === s.host || host.endsWith('.' + s.host));
  } catch {
    return false;
  }
}

async function robotsAllows(url, fetchImpl) {
  try {
    const u = new URL(url);
    const res = await fetchImpl(`${u.origin}/robots.txt`);
    if (!res.ok) return true;
    const text = await res.text();
    let applies = false;
    for (const raw of text.split('\n')) {
      const line = raw.trim();
      if (/^user-agent:/i.test(line)) applies = /\*\s*$/.test(line);
      else if (applies && /^disallow:/i.test(line)) {
        const p = line.split(':')[1].trim();
        if (p && u.pathname.startsWith(p)) return false;
      }
    }
    return true;
  } catch {
    return true;
  }
}

export async function fetchPage(url, { fetchImpl = fetch, userAgent = 'SurSaarIngest/1.0 (+https://github.com/pallavsharmaofficial/SurSaar)' } = {}) {
  if (!(await robotsAllows(url, fetchImpl))) {
    throw new Error(`robots.txt disallows ${url}`);
  }
  const res = await fetchImpl(url, { headers: { 'user-agent': userAgent, accept: 'text/html,text/plain' } });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  return res.text();
}

export async function searchCandidates(query, { sources, provider = process.env.SURSAAR_SEARCH_PROVIDER || 'sources', fetchImpl = fetch, limit = 5 } = {}) {
  const q = `${query} guitar chords`;
  const results = [];
  if (provider === 'ddg') {
    const html = await (await fetchImpl(`https://html.duckduckgo.com/html/?q=${encodeURIComponent(q)}`, {
      headers: { 'user-agent': 'Mozilla/5.0 SurSaarIngest/1.0' },
    })).text();
    const re = /<a[^>]+class="result__a"[^>]+href="([^"]+)"/g;
    let m;
    while ((m = re.exec(html)) && results.length < limit * 3) {
      let href = m[1];
      const uddg = /[?&]uddg=([^&]+)/.exec(href);
      if (uddg) href = decodeURIComponent(uddg[1]);
      if (isAllowed(href, sources)) results.push(href);
    }
  } else {
    for (const s of sources) {
      if (!s.searchPathTemplate) continue;
      const url = `https://${s.host}${s.searchPathTemplate.replace('{query}', encodeURIComponent(query))}`;
      try {
        const html = await fetchPage(url, { fetchImpl });
        const re = /href="([^"]+)"/g;
        let m;
        while ((m = re.exec(html)) && results.length < limit * 3) {
          const href = new URL(m[1], url).toString();
          if (isAllowed(href, sources) && /chord/i.test(href) && !results.includes(href)) results.push(href);
        }
      } catch (err) {
        console.warn(`[search] ${s.host}: ${err.message}`);
      }
    }
  }
  return results.slice(0, limit);
}
