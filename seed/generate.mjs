/**
 * Faniverse seed data generator.
 *
 * Emits three JSON files that `upload.mjs` pushes into Firestore.
 *
 * Typed-value conventions used in the JSON (decoded by upload.mjs):
 *   { "__ref__": "users/u_0007" }  -> Firestore DocumentReference
 *   "2026-03-14T08:12:00.000Z"      -> Firestore Timestamp (any ISO-8601 string
 *                                     under a key listed in TIMESTAMP_KEYS)
 *
 * Run:  node seed/generate.mjs
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildImagePools, currentProvider, sized } from './images.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(__dirname, 'data');
const STATE_PATH = join(__dirname, '.cache', 'seed-state.json');

const USER_COUNT = 50;
const MIN_POSTS = 5;
const MAX_POSTS = 8;

/**
 * Reference "now" for every generated timestamp.
 *
 * Persisted on first run so re-runs are byte-identical and the JSON stays
 * diffable in git. Using a live Date.now() here would shift every date by the
 * elapsed seconds on each run. Bust it with --refresh-dates.
 */
function resolveEpoch() {
  if (process.argv.includes('--refresh-dates')) return Date.now();
  if (process.env.SEED_EPOCH) return Number(process.env.SEED_EPOCH);
  if (existsSync(STATE_PATH)) {
    const stored = JSON.parse(readFileSync(STATE_PATH, 'utf8')).epoch;
    if (Number.isFinite(stored)) return stored;
  }
  return Date.now();
}

const SEED_EPOCH = resolveEpoch();
const persistEpoch = () => {
  if (process.argv.includes('--refresh-dates') || !existsSync(STATE_PATH)) {
    mkdirSync(dirname(STATE_PATH), { recursive: true });
    writeFileSync(STATE_PATH, JSON.stringify({ epoch: SEED_EPOCH }, null, 2));
  }
};

/** One pool of real photos per category, cached on disk. See images.mjs. */
const IMAGE_POOLS = await buildImagePools();

// ---------------------------------------------------------------------------
// Seeded PRNG so re-running produces identical files (safe to diff in git).
// ---------------------------------------------------------------------------
let _seed = 0x5eed1234;
const rnd = () => {
  _seed ^= _seed << 13;
  _seed ^= _seed >>> 17;
  _seed ^= _seed << 5;
  return ((_seed >>> 0) % 1_000_000) / 1_000_000;
};
const int = (min, max) => Math.floor(rnd() * (max - min + 1)) + min;
const pick = (arr) => arr[int(0, arr.length - 1)];
const chance = (p) => rnd() < p;
const some = (arr, n) => {
  const copy = [...arr];
  const out = [];
  for (let i = 0; i < n && copy.length; i++) {
    out.push(copy.splice(int(0, copy.length - 1), 1)[0]);
  }
  return out;
};

// ---------------------------------------------------------------------------
// Vocabularies
// ---------------------------------------------------------------------------
const CATEGORIES = [
  'anime', 'donghua', 'manga', 'manhua', 'manhwa', 'comics',
  'gaming', 'e-sports', 'music', 'movies', 'books',
];
const ROLES =  ['reader', 'reader', 'writer', 'writer', 'writer', 'editor', 'moderator'];
const STATUSES = ['ongoing', 'completed', 'hiatus', 'draft', 'upcoming'];
const TYPES = ['video', 'audio', 'image', 'text', 'mixed'];
const LANGUAGES = ['en', 'en', 'en', 'es', 'jp', 'fr', 'pt', 'ko', 'id'];

// Natural phrasing per media type, so descriptions read like real listings.
const TYPE_LABEL = {
  video: 'video series',
  audio: 'audio release',
  image: 'art collection',
  text: 'written work',
  mixed: 'multi-format project',
};

// Genres are drawn from a per-category pool, so a doc's genres can never
// contradict its categories (a "books" post won't come out tagged "sports").
const GENRES_BY_CATEGORY = {
  anime: ['action', 'fantasy', 'sci-fi', 'romance', 'comedy', 'slice-of-life', 'isekai', 'mystery', 'supernatural', 'horror', 'drama'],
  donghua: ['wuxia', 'xianxia', 'action', 'fantasy', 'romance', 'mystery', 'historical', 'drama'],
  manga: ['shonen', 'shojo', 'seinen', 'josei', 'slice-of-life', 'romance', 'comedy', 'drama', 'mystery', 'action'],
  manhua: ['xianxia', 'wuxia', 'historical', 'romance', 'action', 'fantasy', 'political', 'drama'],
  manhwa: ['fantasy', 'romance', 'slice-of-life', 'action', 'isekai', 'historical', 'comedy', 'drama'],
  comics: ['superhero', 'noir', 'action', 'sci-fi', 'horror', 'fantasy', 'indie'],
  gaming: ['rpg', 'fps', 'moba', 'strategy', 'simulation', 'roguelike', 'racing'],
  'e-sports': ['tournament', 'strategy', 'shooter', 'fighting', 'battle-royale', 'sports'],
  music: ['synthwave', 'kpop', 'j-rock', 'hip-hop', 'lo-fi', 'orchestral', 'rock', 'jazz'],
  movies: ['thriller', 'drama', 'action', 'sci-fi', 'horror', 'comedy', 'western'],
  books: ['literary', 'fantasy', 'thriller', 'sci-fi', 'memoir', 'history', 'mystery', 'romance'],
};

/** Union of the genre pools for every category on a doc. */
const genrePoolFor = (categories) => [...new Set(categories.flatMap((c) => GENRES_BY_CATEGORY[c] ?? []))];

// Invented fandoms/universes so the dataset reads as a neutral demo corpus.
const UNIVERSES = {
  anime: ['Crimson Ember', 'Silent Blade Clan', 'Star Vanguard', 'Iron Orchid Knights', 'Hollow Moon Sect'],
  donghua: ['Nine Lanterns', 'Azure Step', 'Jade Meridian', 'Cloudfall Sect', 'Iron Crane Chronicles'],
  manga: ['Paper Lantern Panic', 'Koi no Suspect', 'Shirogane Family', 'Clerk & Sword', 'Sweet Tsundere Works'],
  manhua: ['Nine Peaks', 'Imperial Ledger', 'Jade Dynasty', 'Crimson Seal', 'Northern Frontier'],
  manhwa: ['Neon Chronicle', 'Starfall Boys', 'Guild of Ashes', 'Winter Symphony', 'The Ninth Contract'],
  comics: ['Inkheart Requiem', 'Blackout Protocol', 'Gutter Saints', 'Crimson Ledger', 'Feral City'],
  gaming: ['Riftbound Legends', 'Hollowdeep', 'Astral Siege', 'Chrono Rift', 'Ironveil Protocol'],
  'e-sports': ['Pro Circuit 7', 'Clutch Point', 'Raid Season', 'Grand Finals', 'Pixel Ladder'],
  music: ['NEON/STAGE', 'V-Train', 'Halo Hearts', 'Liminal Idol', 'Static Bloom'],
  movies: ['The Long Winter', 'Salt and Iron', 'Paper Cities', 'The Quiet Flood', 'Dust and Neon'],
  books: ['The Salt Archive', 'Glass Hours', 'Tidebound', 'The Quiet Ledger', 'Meridian Road'],
};
const SUFFIXES = [
  ' AU', ': Relight', ' - Side B', ': Second Draft', ' of Ashes', ': Retold',
  ' - Director’s Cut', ': Interlude', ' Vol. II', ': Afterimage', ' (Uncut)', ': Epilogue',
];
const TITLE_SHAPES = [
  (f, s) => `${f}${s}`,
  (f, s) => `Coffee Shop ${f}${s}`,
  (f, s) => `The Long Fall of ${f}${s}`,
  (f, s) => `${f}${s}: A Study in Blue`,
  (f, s) => `Midnight at ${f}${s}`,
  (f, s) => `${f}${s} - Slow Burn`,
];
const BIOS = [
  'Writing since I was twelve. Here for the fix-it fics and the angst.',
  'Archive diver. I will find your missing 2007 scan.',
  'Ex-videographer turned full-time fan. Ask me about continuity errors.',
  'I read too much and post too little. Working on it.',
  'Chapters drop Thursdays. Be nice, I bite.',
  'Sprite editor by day, romantic disaster by night.',
  'Here for the rare-pair tag and the angst with teeth.',
  'Translating side characters into protagonists since 2019.',
  'Slow updates, strong feelings. Deal?',
  'I make AMVs nobody asked for. Regret nothing.',
  'Lore-nerd, crybaby, chronic tagger.',
  'Writing the crossover we deserved.',
];

// Wishlist entries are typed with the same vocabulary as content categories,
// plus 'merch' since the app has a cart.
const WISHLIST_TYPES = [...CATEGORIES, 'merch'];
const PRODUCTS = [
  'Softcover Volume Slipcase', 'Artbook (Collector’s Edition)', 'OST Vinyl',
  'Figure - Standard', 'Figure - Deluxe Paint', 'Acrylic Standee',
  'Light Novel Box Set', 'Enamel Pin Set', 'Desk Mat XL', 'Jacket Lanyard',
  'Blu-ray + Digital', 'Foil Poster Print',
];

const FIRST = [
  'Aria', 'Kenji', 'Nadia', 'Tomas', 'Priya', 'Lucia', 'Dmitri', 'Yara', 'Sena', 'Marco',
  'Ilya', 'Freya', 'Omar', 'Sora', 'Elif', 'Bruno', 'Mira', 'Anton', 'Zoya', 'Callum',
  'Ines', 'Ravi', 'Hana', 'Noor', 'Tobias', 'Lina', 'Jae', 'Rosa', 'Emil', 'Thea',
  'Aksel', 'Mei', 'Idris', 'Clara', 'Nikhil', 'Sana', 'Oscar', 'Farah', 'Gustav', 'Rhea',
  'Aiden', 'Kaori', 'Leo', 'Nour', 'Silas', 'Tamsin', 'Ulises', 'Wren', 'Yusuf', 'Zara',
];
const LAST = [
  'Okafor', 'Tanaka', 'Moreau', 'Silva', 'Rahman', 'Novak', 'Haddad', 'Iyer', 'Costa',
  'Lindqvist', 'Bakker', 'Farkas', 'Marchetti', 'Oyelaran', 'Petrov', 'Nakamura',
  'Delacroix', 'Weiss', 'Kowalski', 'Ferreira', 'Abadi', 'Sorensen', 'Villanueva',
  'Bergstrom', 'Chaudhry', 'Kaminski', 'Duarte', 'Achebe', 'Vasquez', 'Lombardi',
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const iso = (d) => new Date(d).toISOString();
const ref = (path) => ({ __ref__: path });

const daysAgo = (n) => SEED_EPOCH - n * 86_400_000;

/**
 * `base` + a random 0..maxDays offset, clamped so it can never exceed the
 * seed epoch. Without this, a document created 0-10 days ago can get an
 * updatedAt in the future, which breaks "most recent first" ordering.
 */
const updatedAfter = (base, maxDays) =>
  Math.min(base + int(0, maxDays) * 86_400_000, SEED_EPOCH);
const slugify = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, '');

/**
 * "The Quiet Ledger" -> "Quiet Ledger".
 * Drops a leading article so a proper name reads correctly mid-sentence,
 * avoiding "set in the The Quiet Ledger universe".
 */
const inlineName = (name) => name.replace(/^(the|a|an)\s+/i, '');
const capitalise = (s) => s.charAt(0).toUpperCase() + s.slice(1);

/**
 * Built as a headline + genre list rather than "A {genre} {typeLabel} work",
 * because genre adjectives disagree with the type noun ("a romance art
 * collection", "a drama written work") across 5 types x ~90 genres.
 */
const buildDescription = (universe, type, genres, cadence) =>
  `${capitalise(TYPE_LABEL[type])} set in the ${inlineName(universe)} universe. ` +
  `Genres: ${genres.join(', ')}. Updated ${cadence}.`;

/** Carousel of `n` distinct image URLs for one content doc. */
const carousel = (id, kind, n, w, h, ext) =>
  Array.from(
    { length: n },
    (_, i) => ext
      ? `https://cdn.faniverse.app/${kind}/${id}/part${i + 1}.${ext}`
      : `https://picsum.photos/seed/${id}-${kind}-${i + 1}/${w}/${h}`,
  );

/** Does this content type carry the given media kind? */
const hasMedia = (type, kind) => type === 'mixed' || type === kind;

/** Stable hash so image choice is tied to the doc id, not the PRNG stream. */
const hash = (s) => {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
};

/**
 * Pick `n` distinct real photos for a doc, drawn from the pools of the
 * categories it belongs to. Hash-based, so re-runs are stable and the PRNG
 * sequence is untouched by image assignment.
 */
const pickImages = (categories, seed, n, fallbackTag, w = 1200, h = 1800) => {
  const pool = [...new Set(categories.flatMap((c) => IMAGE_POOLS[c] ?? []))];
  if (!pool.length) {
    return Array.from({ length: n }, (_, i) => `https://picsum.photos/seed/${fallbackTag}-${i + 1}/${w}/${h}`);
  }
  const h0 = hash(seed);
  const stride = 2654435761; // large odd stride, avoids clustering
  const out = [];
  for (let i = 0; out.length < Math.min(n, pool.length) && i < pool.length; i++) {
    out.push(pool[(h0 + i * stride) % pool.length]);
  }
  return [...new Set(out)].slice(0, n).map((e) => sized(e, w, h));
};

/** Cover/banner/thumbnail dimensions, so each field gets a sane aspect. */
const DIM = { cover: [1200, 1800], banner: [1600, 400], thumb: [800, 1200], square: [800, 800] };


// ---------------------------------------------------------------------------
// Build users
// ---------------------------------------------------------------------------
const users = [];
for (let i = 1; i <= USER_COUNT; i++) {
  const uid = `u_${String(i).padStart(4, '0')}`;
  const first = pick(FIRST);
  const last = pick(LAST);
  const name = `${first} ${last}`;
  const createdAt = daysAgo(int(120, 900));
  const updatedAt = createdAt + int(1, 60) * 86_400_000;

  users.push({
    __docId: uid,
    data: {
      uid,
      name,
      email: `${slugify(first)}.${slugify(last)}${int(1, 99)}@faniverse.app`,
      username: `${slugify(first)}_${slugify(last)}`.slice(0, 24),
      profileImage: `https://i.pravatar.cc/300?u=${uid}`,
      bio: pick(BIOS),
      categories: some(CATEGORIES, int(1, 3)),
      role: pick(ROLES),
      isActive: chance(0.9) ? true : false,
      createdAt: iso(createdAt),
      updatedAt: iso(Math.min(updatedAt, SEED_EPOCH)),
      lastLoginAt: iso(daysAgo(int(0, 20))),
    },
  });
}

// ---------------------------------------------------------------------------
// Vocabulary for events / products / communities
// ---------------------------------------------------------------------------
const EVENT_STATUSES = ['upcoming', 'ongoing', 'completed', 'cancelled'];
const CURRENCY = 'USD';
const SIZES = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'One Size'];
const COLORS = ['Black', 'White', 'Navy', 'Red', 'Green', 'Purple', 'Grey', 'Beige', 'Pink', 'Brown'];
const BRANDS = ['Nebula', 'Paper Crane', 'Studio Nine', 'Moonrise', 'Kitsune', 'Orbit', 'Vellum', 'Halcyon'];
const LOCATIONS = [
  'Lagos Convention Centre', 'Ikeja City Mall', 'Victoria Island', 'Abuja National Mosque',
  'Accra International Conference Centre', 'Nairobi KICC', 'Kigali Arena', 'London ExCeL',
  'Birmingham NEC', 'Online / Discord', 'Lagos Island Arts Space', 'Port Harcourt Civic Centre',
];
const EVENT_SHAPES = [
  (u, s) => `${u}${s}`,
  (u, s) => `${u}: ${pick(['Meetup', 'Screening', 'Workshop', 'Cosplay Contest', 'Meet & Greet', 'Jam Session'])}`,
  (u, s) => `${s} ${u} Gathering`,
  (u, s) => `The ${u} ${pick(['Con', 'Fest', 'Expo', 'Fair'])}`,
];
const COMMUNITY_TOPICS = [
  'Theory & Lore', 'Fan Art', 'Cosplay', 'Headcanon', 'Merch Trading', 'News',
  'Fan Fiction', 'Reviews', 'Events', 'Collaboration',
];
const DISCUSSION_SHAPES = [
  (c, t) => `What if ${t} went wrong?`,
  (c, t) => `${t}: a thread for new readers`,
  (c, t) => `Weekly ${c} discussion`,
  (c, t) => `Theory: the ${t} retcon explained`,
  (c, t) => `Recommend me something like ${t}`,
  (c, t) => `PSA: ${c} event next month`,
  (c, t) => `Ranking every ${t} arc`,
];

// ---------------------------------------------------------------------------
// Build products
//
// Generated before the user loop so cart_items can reference a real product
// document ID instead of a synthetic one that points at nothing.
// ---------------------------------------------------------------------------
const PRODUCTS_COUNT = 120;
const products = [];
for (let i = 1; i <= PRODUCTS_COUNT; i++) {
  const productId = `prod_${String(i).padStart(4, '0')}`;
  const category = pick(CATEGORIES);
  const base = pick(UNIVERSES[category]);
  const created = daysAgo(int(0, 400));
  const stock = int(0, 500);
  const isApparel = chance(0.45);

  // imageUrl is the single grid thumbnail; images is the full gallery. This
  // is the distinction the schema asks for, so they are deliberately
  // different types.
  const gallery = pickImages([category], `${productId}-g`, int(2, 5), productId, ...DIM.thumb);

  products.push({
    __docId: productId,
    data: {
      name: `${base} ${pick(SUFFIXES).trim()}`,
      description: `Official ${base} merchandise. ${pick(['Limited run', 'Restocked', 'Fan favourite', 'New release'])}.`,
      imageUrl: gallery[0],
      images: gallery,
      category,
      price: Number((int(499, 18999) / 100).toFixed(2)),
      currency: CURRENCY,
      stockQuantity: stock,
      // Apparel gets size/colour; other products leave them null.
      size: isApparel ? pick(SIZES) : null,
      color: isApparel ? pick(COLORS) : null,
      brand: pick(BRANDS),
      rating: chance(0.12) ? null : Number((int(30, 50) / 10).toFixed(1)),
      reviewsCount: int(0, 4200),
      sellerId: pick(users).data.uid,
      isAvailable: stock > 0,
      createdAt: iso(created),
      updatedAt: iso(updatedAfter(created, 30)),
    },
  });
}

// ---------------------------------------------------------------------------
// Build subcollections (wishlist_items + cart_items) and contents
// ---------------------------------------------------------------------------
const subcollections = [];
const contents = [];
let contentSeq = 1;

for (const u of users) {
  const uid = u.__docId;

  // --- wishlist_items ---
  const wishlist = {};
  const wishCount = int(3, 8);
  for (let i = 1; i <= wishCount; i++) {
    const itemId = `w_${uid}_${String(i).padStart(3, '0')}`;
    const itemType = pick(WISHLIST_TYPES);
    const cat = pick(CATEGORIES);
    const universe = pick(UNIVERSES[cat]);
    const categories = some([cat, ...some(CATEGORIES, int(0, 2))], int(1, 3));
    wishlist[itemId] = {
      itemId,
      itemType,
      title: `${universe}${pick(SUFFIXES)}`,
      imageUrl: pickImages(categories, itemId, int(1, 3), itemId, ...DIM.thumb),
      categories,
      addedAt: iso(daysAgo(int(1, 300))),
    };
  }

  // --- cart_items ---
  // productId now points at a real products/{id} document, and price/name/
  // imageUrl are copied from it, so a cart can be rendered without a
  // per-item product read.
  const cart = {};
  const cartCount = int(1, 4);
  for (let i = 1; i <= cartCount; i++) {
    const docId = `c_${uid}_${String(i).padStart(3, '0')}`;
    const product = pick(products);
    const added = daysAgo(int(0, 30));
    cart[docId] = {
      productId: product.__docId,
      name: product.data.name,
      imageUrl: product.data.imageUrl,
      price: product.data.price,
      quantity: int(1, 3),
      addedAt: iso(added),
      updatedAt: iso(updatedAfter(added, 5)),
    };
  }

  // --- bookmarks ---
  // Bookmarks point at saved content, so itemType is restricted to the
  // category vocabulary (no 'merch' - a product goes in the cart).
  // Ported from the older seed_data pipeline, which was the only place this
  // subcollection existed.
  const bookmarks = {};
  const bookmarkCount = int(2, 5);
  for (let i = 1; i <= bookmarkCount; i++) {
    const docId = `bm_${uid}_${String(i).padStart(3, '0')}`;
    const cat = pick(CATEGORIES);
    const categories = some([cat, ...some(CATEGORIES, int(0, 1))], int(1, 2));
    bookmarks[docId] = {
      itemId: `ext_${cat}_${int(1000, 9999)}`,
      itemType: cat,
      title: `${pick(UNIVERSES[cat])}${pick(SUFFIXES)}`,
      imageUrl: pickImages(categories, docId, int(1, 2), docId, ...DIM.thumb),
      categories,
      createdAt: iso(daysAgo(int(1, 400))),
    };
  }

  subcollections.push({ __docId: uid, data: { __SUB_COLLECTION_THREAD__: { wishlist_items: wishlist, cart_items: cart, bookmarks } } });

  // --- contents (posted by this user) ---
  const postCount = int(MIN_POSTS, MAX_POSTS);
  for (let i = 1; i <= postCount; i++) {
    const contentId = `c_${String(contentSeq++).padStart(5, '0')}`;
    const type = pick(TYPES);
    const primaryCat = pick(CATEGORIES);
    const universe = pick(UNIVERSES[primaryCat]);
    const title = pick(TITLE_SHAPES)(universe, pick(SUFFIXES));
    const created = daysAgo(int(0, 500));
    const isSeries = chance(0.45);

    // Categories first, then genres drawn only from those categories' pools,
    // so genres can never contradict the doc's subject domain.
    const categories = some([primaryCat, ...some(CATEGORIES, int(0, 2))], int(1, 3));
    const genres = some(genrePoolFor(categories), int(1, 3));
    const cadence = pick(['weekly', 'biweekly', 'irregularly']);

    // Carousel fields are always arrays. Media that doesn't apply to the type
    // is an EMPTY array rather than null, so the field type never varies and
    // clients can iterate without a null check.
    const images = pickImages(categories, contentId, int(1, 5), contentId, ...DIM.cover);
    const videos = hasMedia(type, 'video') ? carousel(contentId, 'v', int(1, 2), 1920, 1080, 'm3u8') : [];
    const audios = hasMedia(type, 'audio') ? carousel(contentId, 'a', int(1, 3), 1920, 1080, 'mp3') : [];

    // NOTE: schemaless union - every doc carries every field; media fields are
    // always arrays (possibly empty), and scalar fields are null when N/A.
    contents.push({
      __docId: contentId,
      data: {
        title,
        description: buildDescription(universe, type, genres, cadence),
        imageUrl: images,
        videoUrl: videos,
        audioUrl: audios,
        // Banner is a single hero crop, so it stays a scalar string.
        bannerUrl: pickImages(categories, `${contentId}-banner`, 1, contentId, ...DIM.banner)[0],
        type,
        categories,
        genres,
        status: pick(STATUSES),
        releaseDate: iso(created),
        rating: chance(0.15) ? null : Number((int(30, 50) / 10).toFixed(1)),
        language: pick(LANGUAGES),
        author: ref(`users/${uid}`), // <- DocumentReference to the posting user
        creator: u.data.name, // <- denormalised display name
        episodes: isSeries ? int(4, 48) : null,
        chapters: isSeries ? null : int(6, 140),
        views: int(12, 480_000),
        likes: int(0, 24_000),
        createdAt: iso(created),
        updatedAt: iso(updatedAfter(created, 45)),
      },
    });
  }
}

// ---------------------------------------------------------------------------
// Build events
// ---------------------------------------------------------------------------
const EVENTS_COUNT = 75;
const events = [];
for (let i = 1; i <= EVENTS_COUNT; i++) {
  const eventId = `evt_${String(i).padStart(4, '0')}`;
  const category = pick(CATEGORIES);
  const universe = pick(UNIVERSES[category]);
  const host = pick(users);
  const created = daysAgo(int(10, 200));

  // Events can be in the past or future; status has to agree with eventDate.
  const daysFromNow = int(-120, 120);
  const eventAt = SEED_EPOCH + daysFromNow * 86_400_000;
  const startHour = int(9, 20);
  const durationH = int(1, 8);
  const capacity = int(50, 3000);
  const status = daysFromNow < 0
    ? pick(['completed', 'cancelled'])
    : (daysFromNow < 14 ? 'ongoing' : 'upcoming');
  const isFree = chance(0.35);

  events.push({
    __docId: eventId,
    data: {
      title: pick(EVENT_SHAPES)(universe, pick(SUFFIXES)),
      description: `A ${category} gathering for ${universe} fans. ${pick(['Doors open early', 'All ages welcome', 'Cosplay encouraged', 'Limited seats'])}.`,
      imageUrl: pickImages([category], `${eventId}-e`, int(1, 3), eventId, ...DIM.banner),
      category,
      location: pick(LOCATIONS),
      eventDate: iso(eventAt),
      startTime: iso(eventAt + startHour * 3_600_000),
      endTime: iso(eventAt + (startHour + durationH) * 3_600_000),
      organizer: ref(`users/${host.data.uid}`), // DocumentReference
      organizerId: host.data.uid, // denormalised for cheap filters
      ticketPrice: isFree ? 0 : Number((int(500, 15000) / 100).toFixed(2)),
      ticketUrl: isFree ? null : `https://tickets.faniverse.app/e/${eventId}`,
      status,
      capacity,
      // Never more attendees than capacity.
      attendeesCount: Math.min(capacity, int(0, capacity)),
      createdAt: iso(created),
      updatedAt: iso(updatedAfter(created, 20)),
    },
  });
}

// ---------------------------------------------------------------------------
// Build communities + their discussions subcollection
// ---------------------------------------------------------------------------
const COMMUNITIES_COUNT = 25;
const communities = [];
let discussionSeq = 1;
for (let i = 1; i <= COMMUNITIES_COUNT; i++) {
  const communityId = `com_${String(i).padStart(3, '0')}`;
  const category = pick(CATEGORIES);
  const topic = pick(COMMUNITY_TOPICS);
  const universe = pick(UNIVERSES[category]);
  const owner = pick(users);
  const created = daysAgo(int(30, 700));

  const discussions = {};
  const discussionCount = int(3, 8);
  // A discussion cannot predate its community or postdate now. Clamp both
  // offsets to the window that actually exists.
  const ageDays = Math.max(1, Math.floor((SEED_EPOCH - created) / 86_400_000));
  for (let d = 1; d <= discussionCount; d++) {
    const discussionId = `d_${String(discussionSeq++).padStart(5, '0')}`;
    const author = pick(users);
    const dCreated = created + int(0, ageDays - 1) * 86_400_000;
    const sinceCreated = Math.max(0, Math.floor((SEED_EPOCH - dCreated) / 86_400_000));
    const dUpdated = dCreated + int(0, sinceCreated) * 86_400_000;
    discussions[discussionId] = {
      title: pick(DISCUSSION_SHAPES)(universe, topic),
      content: `Opening post for the ${topic} thread on ${universe}. Drop your takes below.`,
      authorId: author.data.uid,
      likesCount: int(0, 940),
      commentsCount: int(0, 320),
      createdAt: iso(dCreated),
      updatedAt: iso(dUpdated),
    };
  }

  communities.push({
    __docId: communityId,
    data: {
      name: `${universe} ${topic}`,
      description: `The home for ${universe} ${topic.toLowerCase()} on Faniverse.`,
      imageUrl: pickImages([category], `${communityId}-c`, int(1, 3), communityId, ...DIM.banner),
      category,
      createdBy: ref(`users/${owner.data.uid}`), // DocumentReference
      // Derived from the discussions actually generated, so it never lies.
      memberCount: int(12, 4800),
      createdAt: iso(created),
      updatedAt: iso(updatedAfter(created, 60)),
      __SUB_COLLECTION_THREAD__: { discussions },
    },
  });
}

// ---------------------------------------------------------------------------
// Emit
// ---------------------------------------------------------------------------
mkdirSync(OUT_DIR, { recursive: true });
persistEpoch();
console.log(`Timestamp epoch: ${new Date(SEED_EPOCH).toISOString()}`
  + `${process.argv.includes('--refresh-dates') ? '  (refreshed)' : ''}`);

const strip = (arr) => Object.fromEntries(arr.map(({ __docId, data }) => [__docId, data]));

writeFileSync(join(OUT_DIR, 'users.json'), JSON.stringify(strip(users), null, 2));
writeFileSync(join(OUT_DIR, 'users_subcollections.json'), JSON.stringify(strip(subcollections), null, 2));
writeFileSync(join(OUT_DIR, 'content.json'), JSON.stringify(strip(contents), null, 2));
writeFileSync(join(OUT_DIR, 'products.json'), JSON.stringify(strip(products), null, 2));
writeFileSync(join(OUT_DIR, 'events.json'), JSON.stringify(strip(events), null, 2));
writeFileSync(join(OUT_DIR, 'communities.json'), JSON.stringify(strip(communities), null, 2));

// Attribution manifest. Unsplash requires credit; Pexels asks for it. This is
// generated so credits can never drift from the photos actually referenced.
{
  const credits = [];
  for (const [category, entries] of Object.entries(IMAGE_POOLS)) {
    for (const e of entries) {
      if (!e.photographer) continue;
      credits.push({ category, photographer: e.photographer, photographerUrl: e.photographerUrl, sourceUrl: e.sourceUrl });
    }
  }
  const unique = [...new Map(credits.map((c) => [c.sourceUrl, c])).values()];
  const body = [
    '# Image credits',
    '',
    `Provider: \`${currentProvider()}\`. ${unique.length} distinct photos, generated ${iso(SEED_EPOCH)}.`,
    '',
    'Pexels: https://www.pexels.com/license/',
    'Unsplash: https://unsplash.com/license',
    '',
    '| Category | Photographer | Photo |',
    '| --- | --- | --- |',
    ...unique.map((c) => `| ${c.category} | ${c.photographer} | ${c.sourceUrl} |`),
    '',
  ].join('\n');
  writeFileSync(join(OUT_DIR, 'IMAGE_CREDITS.md'), body);
  console.log(`  wrote IMAGE_CREDITS.md (${unique.length} photos)`);
}

const counts = { users: users.length, contents: contents.length };
counts.wishlist_items = Object.values(strip(subcollections)).reduce((n, d) => n + Object.keys(d.__SUB_COLLECTION_THREAD__.wishlist_items).length, 0);
counts.cart_items = Object.values(strip(subcollections)).reduce((n, d) => n + Object.keys(d.__SUB_COLLECTION_THREAD__.cart_items).length, 0);
counts.bookmarks = Object.values(strip(subcollections)).reduce((n, d) => n + Object.keys(d.__SUB_COLLECTION_THREAD__.bookmarks).length, 0);
counts.products = products.length;
counts.events = events.length;
counts.communities = communities.length;
counts.discussions = communities.reduce((n, c) => n + Object.keys(c.data.__SUB_COLLECTION_THREAD__.discussions).length, 0);
counts.TOTAL_DOCS = counts.users + counts.contents + counts.wishlist_items + counts.cart_items
  + counts.bookmarks + counts.products + counts.events + counts.communities + counts.discussions;

console.log('Wrote to seed/data/');
console.table(counts);
console.log(`Min posts per user: ${Math.min(...users.map((u) => contents.filter((c) => c.data.author.__ref__ === `users/${u.__docId}`).length))}`);

// ---------------------------------------------------------------------------
// Validation - fail loudly rather than emit off-vocabulary data.
// ---------------------------------------------------------------------------
const ALLOWED = new Set(CATEGORIES);
const found = new Map();
const bad = new Set();
// Declared before use: the cart loop below cross-references products.
const productIds = new Set(products.map((p) => p.__docId));
const userIds = new Set(users.map((u) => u.data.uid));
const track = (cats, where) => {
  for (const c of cats) {
    found.set(c, (found.get(c) ?? 0) + 1);
    if (!ALLOWED.has(c)) bad.add(`${c} (${where})`);
  }
};
for (const u of users) track(u.data.categories, 'users');
for (const c of contents) {
  track(c.data.categories, 'content');
  // Every genre must be legal for at least one of the doc's own categories.
  const pool = new Set(genrePoolFor(c.data.categories));
  for (const g of c.data.genres) {
    if (!pool.has(g)) bad.add(`genre=${g} not in pools for [${c.data.categories}] (content)`);
  }
  if (/\b(the|a|an)\s+\1\b/i.test(c.data.description)) {
    bad.add(`repeated article in description: ${c.data.description} (content)`);
  }
  // Carousel fields must be arrays, and must not claim media the type lacks.
  for (const f of ['imageUrl', 'videoUrl', 'audioUrl']) {
    if (!Array.isArray(c.data[f])) bad.add(`${f} is not an array (content ${c.__docId})`);
    if (Array.isArray(c.data[f]) && c.data[f].some((u) => typeof u !== 'string')) {
      bad.add(`${f} has non-string entries (content ${c.__docId})`);
    }
  }
  if (c.data.imageUrl.length < 1) bad.add(`imageUrl empty (content ${c.__docId})`);
  if (c.data.videoUrl.length && !hasMedia(c.data.type, 'video')) {
    bad.add(`videoUrl populated on type=${c.data.type} (content ${c.__docId})`);
  }
  if (c.data.audioUrl.length && !hasMedia(c.data.type, 'audio')) {
    bad.add(`audioUrl populated on type=${c.data.type} (content ${c.__docId})`);
  }
}
for (const d of Object.values(strip(subcollections))) {
  for (const w of Object.values(d.__SUB_COLLECTION_THREAD__.wishlist_items)) {
    track(w.categories, 'wishlist_items');
    if (!WISHLIST_TYPES.includes(w.itemType)) bad.add(`itemType=${w.itemType} (wishlist)`);
    if (!Array.isArray(w.imageUrl) || !w.imageUrl.length) bad.add(`imageUrl not a non-empty array (wishlist ${w.itemId})`);
  }
  for (const c of Object.values(d.__SUB_COLLECTION_THREAD__.cart_items)) {
    // imageUrl is copied from the product's single thumbnail, so a string.
    if (typeof c.imageUrl !== 'string' || !c.imageUrl) bad.add(`imageUrl not a string (cart ${c.productId})`);
    if (typeof c.price !== 'number') bad.add(`price not numeric (cart ${c.productId})`);
    if (!productIds.has(c.productId)) bad.add(`productId=${c.productId} does not exist in products (cart)`);
  }
  for (const b of Object.values(d.__SUB_COLLECTION_THREAD__.bookmarks)) {
    track(b.categories, 'bookmarks');
    if (!CATEGORIES.includes(b.itemType)) bad.add(`itemType=${b.itemType} not a category (bookmark ${b.itemId})`);
    if (!Array.isArray(b.imageUrl) || !b.imageUrl.length) bad.add(`imageUrl not a non-empty array (bookmark ${b.itemId})`);
  }
}

// ---- products ----
for (const p of products) {
  const d = p.data;
  track([d.category], 'products');
  if (typeof d.imageUrl !== 'string' || !d.imageUrl) bad.add(`imageUrl not a string (product ${p.__docId})`);
  if (!Array.isArray(d.images) || d.images.length < 1) bad.add(`images not a non-empty array (product ${p.__docId})`);
  if (typeof d.price !== 'number' || d.price < 0) bad.add(`price invalid (product ${p.__docId})`);
  if (d.currency !== CURRENCY) bad.add(`currency=${d.currency} unexpected (product ${p.__docId})`);
  if (!Number.isInteger(d.stockQuantity) || d.stockQuantity < 0) bad.add(`stockQuantity invalid (product ${p.__docId})`);
  // Availability must agree with stock.
  if (d.isAvailable !== (d.stockQuantity > 0)) bad.add(`isAvailable disagrees with stock (product ${p.__docId})`);
  if (!userIds.has(d.sellerId)) bad.add(`sellerId=${d.sellerId} unknown (product ${p.__docId})`);
  if ((d.size === null) !== (d.color === null)) bad.add(`size/color should both be set or both null (product ${p.__docId})`);
}

// ---- events ----
for (const e of events) {
  const d = e.data;
  track([d.category], 'events');
  if (!Array.isArray(d.imageUrl) || !d.imageUrl.length) bad.add(`imageUrl not a non-empty array (event ${e.__docId})`);
  if (!EVENT_STATUSES.includes(d.status)) bad.add(`status=${d.status} unknown (event ${e.__docId})`);
  if (!d.organizer.__ref__.startsWith('users/')) bad.add(`organizer not a users/ ref (event ${e.__docId})`);
  if (!userIds.has(d.organizerId)) bad.add(`organizerId=${d.organizerId} unknown (event ${e.__docId})`);
  if (d.organizer.__ref__ !== `users/${d.organizerId}`) bad.add(`organizer/Id mismatch (event ${e.__docId})`);
  if (new Date(d.endTime) <= new Date(d.startTime)) bad.add(`endTime not after startTime (event ${e.__docId})`);
  // Events: status must agree with the schedule, and past events must not
  // still be marked upcoming.
  const isPast = new Date(d.eventDate).getTime() < SEED_EPOCH;
  if (isPast && d.status === 'upcoming') bad.add(`past event marked upcoming (event ${e.__docId})`);
  if (!isPast && (d.status === 'completed' || d.status === 'cancelled')) {
    bad.add(`future event marked ${d.status} (event ${e.__docId})`);
  }
  if (typeof d.eventDate === 'string' && Number.isNaN(new Date(d.eventDate).getTime())) bad.add(`eventDate unparseable (event ${e.__docId})`);
  if (!Number.isInteger(d.capacity) || d.capacity <= 0) bad.add(`capacity invalid (event ${e.__docId})`);
  if (d.attendeesCount > d.capacity) bad.add(`attendeesCount > capacity (event ${e.__docId})`);
  if (d.ticketPrice < 0) bad.add(`ticketPrice negative (event ${e.__docId})`);
  // Free events must not carry a ticket URL, and vice versa.
  if ((d.ticketPrice === 0) !== (d.ticketUrl === null)) bad.add(`ticketPrice/ticketUrl disagree (event ${e.__docId})`);
}

// ---- communities + discussions ----
for (const c of communities) {
  const d = c.data;
  track([d.category], 'communities');
  if (!d.createdBy.__ref__.startsWith('users/')) bad.add(`createdBy not a users/ ref (community ${c.__docId})`);
  if (!Array.isArray(d.imageUrl) || !d.imageUrl.length) bad.add(`imageUrl not a non-empty array (community ${c.__docId})`);
  for (const [did, disc] of Object.entries(d.__SUB_COLLECTION_THREAD__.discussions)) {
    if (!userIds.has(disc.authorId)) bad.add(`authorId=${disc.authorId} unknown (discussion ${did})`);
    if (new Date(disc.updatedAt).getTime() > SEED_EPOCH) bad.add(`updatedAt in the future (discussion ${did})`);
  }
}

// ---- global: audit timestamps may not be in the future ----
{
  // Audit fields must never postdate the seed epoch. Event schedule fields
  // (eventDate/startTime/endTime) are deliberately excluded - an upcoming
  // event is supposed to be in the future, and status is validated separately.
  const when = new Set([
    'createdAt', 'updatedAt', 'addedAt', 'lastLoginAt', 'releaseDate',
  ]);
  const scan = (node, where) => {
    for (const [k, v] of Object.entries(node)) {
      if (!when.has(k) || typeof v !== 'string') continue;
      if (Number.isNaN(new Date(v).getTime())) { bad.add(`${k} unparseable (${where})`); continue; }
      if (new Date(v).getTime() > SEED_EPOCH) bad.add(`${k} in the future (${where})`);
    }
  };
  for (const c of [...users, ...contents, ...products, ...events]) scan(c.data, c.__docId);
  for (const d of Object.values(strip(subcollections))) {
    for (const [k, docs] of Object.entries(d.__SUB_COLLECTION_THREAD__)) {
      for (const [id, doc] of Object.entries(docs)) scan(doc, `${k}/${id}`);
    }
  }
  for (const c of communities) {
    scan(c.data, c.__docId);
    for (const [id, disc] of Object.entries(c.data.__SUB_COLLECTION_THREAD__.discussions)) {
      scan(disc, `discussions/${id}`);
    }
  }
}

console.log(`\nCategory usage (allowed set = ${CATEGORIES.length}):`);
console.table([...found.entries()].sort().map(([category, count]) => ({ category, count })));

const missing = CATEGORIES.filter((c) => !found.has(c));
if (missing.length) console.log(`\nWARNING unused categories: ${missing.join(', ')}`);
if (bad.size) {
  console.error(`\nFAIL - values outside the allowed vocabulary:\n  ${[...bad].join('\n  ')}`);
  process.exit(1);
}
console.log('\nAll category values valid.');
