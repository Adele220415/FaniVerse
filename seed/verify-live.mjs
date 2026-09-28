// Post-upload verification against the live database. Read-only.
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
let credential = applicationDefault();
const keyPath = join(ROOT, 'serviceAccountKey.json');
if (existsSync(keyPath)) credential = cert(JSON.parse(readFileSync(keyPath, 'utf8')));

const db = getFirestore(initializeApp({
  credential,
  projectId: process.env.PROJECT_ID ?? 'faniverse-main-753e3',
}));

const ok = (c, m) => console.log(`  ${c ? 'PASS' : 'FAIL'}  ${m}`);

console.log('=== collections ===');
const cols = await db.listCollections();
ok(cols.length === 2, `exactly users + content (got: ${cols.map((c) => c.id).join(', ') || 'none'})`);

const users = await db.collection('users').get();
const content = await db.collection('content').get();
ok(users.size === 50, `50 users (got ${users.size})`);
ok(content.size === 328, `328 content (got ${content.size})`);

console.log('\n=== user document shape ===');
const USER_FIELDS = ['uid','name','email','username','profileImage','bio','categories','role','isActive','createdAt','updatedAt','lastLoginAt'];
const badShape = users.docs.filter((d) => USER_FIELDS.some((f) => !(f in d.data())));
ok(badShape.length === 0, `all users have all 12 fields (${badShape.length} incomplete)`);
const u0 = users.docs[0].data();
console.log('  sample:', JSON.stringify({
  uid: u0.uid, name: u0.name, username: u0.username, role: u0.role, isActive: u0.isActive, categories: u0.categories,
}).slice(0, 160));
console.log('  createdAt is Timestamp?', u0.createdAt?.constructor?.name);

console.log('\n=== reference encoding ===');
let refOk = 0, dangling = 0;
const userIds = new Set(users.docs.map((d) => d.id));
for (const d of content.docs) {
  const a = d.get('author');
  if (a && typeof a.path === 'string' && userIds.has(a.path.split('/').pop())) refOk++;
  else dangling++;
}
ok(dangling === 0, `all author refs resolve to a real user (${refOk} ok, ${dangling} bad)`);
const c0 = content.docs[0].data();
console.log('  creator (should be a string):', JSON.stringify(c0.creator));

console.log('\n=== schemaless union ===');
const CONTENT_FIELDS = 21;
const wrongCount = content.docs.filter((d) => Object.keys(d.data()).length !== CONTENT_FIELDS);
ok(wrongCount.length === 0, `all content docs have ${CONTENT_FIELDS} fields (${wrongCount.length} wrong)`);
const arrayBad = content.docs.filter((d) => !['imageUrl','videoUrl','audioUrl'].every((f) => Array.isArray(d.get(f))));
ok(arrayBad.length === 0, `imageUrl/videoUrl/audioUrl all arrays (${arrayBad.length} bad)`);
const nullMedia = content.docs.filter((d) => [...d.get('imageUrl'), ...d.get('videoUrl'), ...d.get('audioUrl')].some((u) => u === null));
ok(nullMedia.length === 0, `no nulls inside media arrays (${nullMedia.length} bad)`);

console.log('\n=== subcollections ===');
let wl = 0, cart = 0, bm = 0, missingSubs = 0;
for (const d of users.docs) {
  for (const [name, add] of [['wishlist_items', 'wl'], ['cart_items', 'cart'], ['bookmarks', 'bm']]) {
    const s = await d.ref.collection(name).get();
    if (s.empty) missingSubs++; else s.size;
    if (name === 'wishlist_items') wl += s.size;
    if (name === 'cart_items') cart += s.size;
    if (name === 'bookmarks') bm += s.size;
  }
}
ok(missingSubs === 0, `every user has all 3 subcollections (${missingSubs} users missing one)`);
console.log(`  wishlist_items=${wl}  cart_items=${cart}  bookmarks=${bm}`);

console.log('\n=== category vocabulary ===');
const ALLOWED = new Set(['anime','donghua','manga','manhua','manhwa','comics','gaming','e-sports','music','movies','books']);
const seen = new Map(); let off = 0;
for (const d of content.docs) for (const c of d.get('categories') ?? []) {
  seen.set(c, (seen.get(c) ?? 0) + 1);
  if (!ALLOWED.has(c)) off++;
}
ok(off === 0, `all categories in vocabulary (${off} off-vocabulary)`);
ok(seen.size === 11, `all 11 categories present (got ${seen.size})`);

console.log('\n=== prices are numbers, not strings ===');
let priceBad = 0;
for (const d of users.docs.slice(0, 10)) {
  const s = await d.ref.collection('cart_items').get();
  for (const c of s.docs) if (typeof c.get('price') !== 'number') priceBad++;
}
ok(priceBad === 0, `cart price stored as number (${priceBad} bad)`);

console.log('\n=== new collections ===');
const products = await db.collection('products').get();
const events = await db.collection('events').get();
const coms = await db.collection('communities').get();
ok(products.size === 120, `120 products (got ${products.size})`);
ok(events.size === 75, `75 events (got ${events.size})`);
ok(coms.size === 25, `25 communities (got ${coms.size})`);

// field-set conformance
const SPEC = {
  products: 17, events: 17, communities: 8,
};
for (const [name, snap] of [['products', products], ['events', events], ['communities', coms]]) {
  const wrong = snap.docs.filter((d) => Object.keys(d.data()).length !== SPEC[name]);
  ok(wrong.length === 0, `${name}: all docs have ${SPEC[name]} fields (${wrong.length} wrong)`);
}

console.log('\n=== events: references + scheduling ===');
let evRefOk = 0, evStatusBad = 0, evOrderBad = 0;
const now = Date.now();
for (const d of events.docs) {
  const org = d.get('organizer');
  if (org && typeof org.path === 'string' && org.path === `users/${d.get('organizerId')}`) evRefOk++;
  if (d.get('endTime').toDate() <= d.get('startTime').toDate()) evOrderBad++;
  const isPast = d.get('eventDate').toDate().getTime() < now;
  const st = d.get('status');
  if ((st === 'upcoming' && isPast) || ((st === 'completed' || st === 'cancelled') && !isPast)) evStatusBad++;
}
ok(evRefOk === events.size, `all event organizer refs resolve (${evRefOk}/${events.size})`);
ok(evOrderBad === 0, `endTime after startTime on every event (${evOrderBad} bad)`);
ok(evStatusBad === 0, `status agrees with eventDate (${evStatusBad} bad)`);
const ev0 = events.docs[0].data();
console.log('  eventDate type:', ev0.eventDate.constructor.name, '| ticketPrice type:', typeof ev0.ticketPrice);
const free = events.docs.filter((d) => d.get('ticketPrice') === 0);
ok(free.every((d) => d.get('ticketUrl') === null), `free events have no ticketUrl (${free.size} free events)`);

console.log('\n=== products ===');
let availBad = 0, sellerBad = 0, galleryBad = 0;
for (const d of products.docs) {
  if (d.get('isAvailable') !== (d.get('stockQuantity') > 0)) availBad++;
  if (!userIds.has(d.get('sellerId'))) sellerBad++;
  if (typeof d.get('imageUrl') !== 'string' || !Array.isArray(d.get('images'))) galleryBad++;
}
ok(availBad === 0, `isAvailable agrees with stockQuantity (${availBad} bad)`);
ok(sellerBad === 0, `all sellerId values are real users (${sellerBad} bad)`);
ok(galleryBad === 0, `imageUrl string + images array (${galleryBad} bad)`);
ok(products.docs.every((d) => typeof d.get('price') === 'number'), 'price is numeric on all products');

console.log('\n=== communities / discussions ===');
let discTotal = 0, discBad = 0, cbBad = 0, noSub = 0;
for (const d of coms.docs) {
  const createdBy = d.get('createdBy');
  if (!(createdBy && typeof createdBy.path === 'string')) cbBad++;
  const sub = await d.ref.collection('discussions').get();
  if (sub.empty) noSub++;
  discTotal += sub.size;
  for (const s of sub.docs) {
    if (Object.keys(s.data()).length !== 7) discBad++;
    if (!userIds.has(s.get('authorId'))) discBad++;
  }
}
ok(cbBad === 0, `all createdBy are DocumentReferences (${cbBad} bad)`);
ok(noSub === 0, `every community has discussions (${noSub} empty)`);
ok(discBad === 0, `all ${discTotal} discussions have 7 fields and a real authorId (${discBad} bad)`);

console.log('\n=== cart_items -> products ===');
let carts = 0, cartDangling = 0, cartDrift = 0;
const prodMap = new Map(products.docs.map((d) => [d.id, d.data()]));
for (const d of users.docs) {
  const cart = await d.ref.collection('cart_items').get();
  for (const c of cart.docs) {
    carts++;
    const p = prodMap.get(c.get('productId'));
    if (!p) cartDangling++;
    else if (p.name !== c.get('name') || p.price !== c.get('price')) cartDrift++;
  }
}
ok(cartDangling === 0, `all ${carts} cart items resolve to a real product (${cartDangling} dangling)`);
ok(cartDrift === 0, `cart name/price match the product (${cartDrift} drift)`);

console.log('\n=== real (non-seed) users ===');
const seedIds = new Set(Object.keys(JSON.parse(readFileSync(join(__dirname, 'data', 'users.json'), 'utf8'))));
for (const d of users.docs) {
  if (seedIds.has(d.id)) continue;
  const fields = Object.keys(d.data());
  const missing = ['uid','username','profileImage','bio','role','isActive','createdAt','updatedAt','lastLoginAt']
    .filter((f) => !fields.includes(f));
  console.log(`  ${d.id}  [${fields.length} fields]${missing.length ? `  MISSING: ${missing.join(', ')}` : '  full shape'}`);
}

console.log('\nDone.');
