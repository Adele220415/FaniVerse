/**
 * Real-image pool fetcher for the Faniverse seed data.
 *
 * Fetches ONE pool of photos per category, caches it to disk, and lets
 * generate.mjs assign from the pool deterministically. This keeps us at
 * ~12 HTTP requests per full run instead of one per document, which matters
 * because free tiers are rate limited (Pexels 200/hr, Unsplash 50/hr).
 *
 * Config (via .env or shell):
 *   IMAGE_PROVIDER = pexels | unsplash | picsum   (default: auto-detect)
 *   PEXELS_API_KEY     = ...
 *   UNSPLASH_ACCESS_KEY = ...
 *   IMAGE_POOL_SIZE    = 30                      (default)
 *
 * A pool entry is a size-agnostic record, not a URL:
 *   { base, photographer, photographerUrl, sourceUrl }
 * `sized(entry, w, h)` renders it at the dimensions a given field needs, so a
 * portrait cover and a 1600x400 banner can come from the same photo.
 *
 * ATTRIBUTION: Pexels does not mandate credit but asks for it; Unsplash
 * requires it. generate.mjs writes data/IMAGE_CREDITS.md from the pool so
 * attribution is satisfied mechanically rather than by hand.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const CACHE_PATH = join(__dirname, '.cache', 'image-pools.json');

// Topical search terms per category, so an anime cover gets anime art rather
// than a random landscape photo.
export const SEARCH_TERMS = {
  anime: ['anime cosplay', 'anime convention', 'manga illustration'],
  donghua: ['chinese ink painting', 'chinese temple art', 'chinese calligraphy art'],
  manga: ['manga comic art', 'japanese comics', 'comic panel art'],
  manhua: ['chinese temple', 'chinese pagoda art', 'oriental illustration'],
  manhwa: ['kpop concert', 'korean fashion portrait', 'seoul street art'],
  comics: ['comic book art', 'graphic novel', 'pop art comic'],
  gaming: ['gaming setup', 'arcade games', 'video game controller'],
  'e-sports': ['esports', 'gaming competition', 'stadium crowd lights'],
  music: ['concert stage', 'recording studio', 'vinyl records'],
  movies: ['cinema', 'film projector', 'movie theater'],
  books: ['open book', 'bookshelf library', 'stacked books'],
};

// Not a content category - only used for cart line-item thumbnails.
export const MERCH_TERMS = ['anime figure collection', 'vinyl record player', 'art book'];

/** Minimal .env loader so generate.mjs works without an --env-file flag. */
function loadEnv() {
  const path = join(__dirname, '.env');
  if (!existsSync(path)) return;
  for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (!m) continue;
    const value = m[2].replace(/^["']|["']$/g, '');
    if (process.env[m[1]] === undefined) process.env[m[1]] = value;
  }
}

const poolSize = () => Number(process.env.IMAGE_POOL_SIZE ?? 30);

const provider = () => {
  const forced = process.env.IMAGE_PROVIDER?.toLowerCase();
  if (forced) return forced;
  if (process.env.PEXELS_API_KEY) return 'pexels';
  if (process.env.UNSPLASH_ACCESS_KEY) return 'unsplash';
  return 'picsum';
};

/** Which provider is actually in use, after .env has been loaded. */
export const currentProvider = provider;

/** Render a pool entry at a given size, cropping to fill. */
export function sized(entry, w, h) {
  if (!entry) return '';
  if (entry.source === 'picsum') return `${entry.base}/${w}/${h}`;
  return `${entry.base}?auto=compress&cs=tinysrgb&fit=crop&w=${w}&h=${h}`;
}

async function fetchJson(url, headers) {
  const res = await fetch(url, { headers, signal: AbortSignal.timeout(20_000) });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText}`);
  return res.json();
}

async function searchPexels(term, count) {
  const url = `https://api.pexels.com/v1/search?query=${encodeURIComponent(term)}`
    + `&per_page=${count}&orientation=portrait`;
  const data = await fetchJson(url, { Authorization: process.env.PEXELS_API_KEY });
  return (data.photos ?? []).map((p) => ({
    // Strip the src query string - sized() appends its own sizing params.
    base: `${p.src.original.split('?')[0]}`,
    photographer: p.photographer ?? 'Unknown',
    photographerUrl: p.photographer_url ?? 'https://www.pexels.com',
    sourceUrl: p.url ?? 'https://www.pexels.com',
  }));
}

async function searchUnsplash(term, count) {
  const url = `https://api.unsplash.com/search/photos?query=${encodeURIComponent(term)}`
    + `&per_page=${count}&orientation=portrait&content_filter=high`;
  const data = await fetchJson(url, { Authorization: `Client-ID ${process.env.UNSPLASH_ACCESS_KEY}` });
  return (data.results ?? []).map((p) => ({
    base: p.urls?.raw?.split('?')[0],
    photographer: p.user?.name ?? 'Unknown',
    photographerUrl: p.user?.links?.html ?? 'https://unsplash.com',
    sourceUrl: p.links?.html ?? 'https://unsplash.com',
  })).filter((e) => e.base);
}

/** picsum fallback keeps generate.mjs working with no key at all. */
function picsumPool(tag, count) {
  return Array.from({ length: count }, (_, i) => ({
    base: `https://picsum.photos/seed/${tag}-${i + 1}`,
    photographer: null,
    photographerUrl: null,
    sourceUrl: 'https://picsum.photos',
  }));
}

async function fetchPool(terms, tag) {
  const p = provider();
  const count = poolSize();

  if (p === 'picsum') return picsumPool(tag, count);

  const fn = p === 'unsplash' ? searchUnsplash : searchPexels;
  for (const term of terms) {
    try {
      const entries = await fn(term, count);
      if (entries.length) return entries;
      console.warn(`  ! ${p} returned nothing for "${term}"`);
    } catch (err) {
      console.warn(`  ! ${p} failed for "${term}": ${err.message}`);
    }
  }
  return null;
}

/**
 * Returns { [categoryOrTag]: entry[] }. Cached on disk; failures are not
 * cached so a later run with a working key re-fetches.
 */
export async function buildImagePools() {
  loadEnv();

  const cache = existsSync(CACHE_PATH)
    ? JSON.parse(readFileSync(CACHE_PATH, 'utf8'))
    : {};

  const p = provider();
  console.log(`Image provider: ${p}`
    + (p === 'picsum' ? '  (no API key found - set PEXELS_API_KEY in seed/.env)' : ''));

  const targets = { ...SEARCH_TERMS, merch: MERCH_TERMS };
  const pools = {};
  let fetched = 0;

  for (const [key, terms] of Object.entries(targets)) {
    // A cached pool is only usable if it came from the provider we asked for.
    const cached = cache[key];
    if (Array.isArray(cached) && cached.length && cached[0]?.base) {
      if (p === 'picsum' || cached[0].source === p || cached[0].photographer) {
        pools[key] = cached;
        continue;
      }
    }
    const entries = await fetchPool(terms, key);
    if (entries) {
      pools[key] = entries;
      cache[key] = entries;
      fetched++;
    } else {
      console.warn(`  ! falling back to picsum for "${key}"`);
      pools[key] = picsumPool(key, poolSize());
    }
  }

  if (fetched) {
    mkdirSync(dirname(CACHE_PATH), { recursive: true });
    writeFileSync(CACHE_PATH, JSON.stringify(cache, null, 2));
    console.log(`  cached ${fetched} new pool(s) -> seed/.cache/image-pools.json`);
  } else {
    console.log('  all pools served from cache');
  }

  return pools;
}
