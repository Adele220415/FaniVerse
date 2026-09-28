/**
 * Verify the generated JSON against the agreed Firestore schemas.
 *
 *   node seed/verify-schema.mjs
 *
 * Read-only, offline. Catches field drift between the spec and the generator
 * without touching Firestore.
 */

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const load = (f) => JSON.parse(readFileSync(join(__dirname, 'data', f), 'utf8'));

const SPEC = {
  events: ['title', 'description', 'imageUrl', 'category', 'location', 'eventDate',
    'startTime', 'endTime', 'organizer', 'organizerId', 'ticketPrice', 'ticketUrl',
    'status', 'capacity', 'attendeesCount', 'createdAt', 'updatedAt'],
  products: ['name', 'description', 'imageUrl', 'images', 'category', 'price', 'currency',
    'stockQuantity', 'size', 'color', 'brand', 'rating', 'reviewsCount', 'sellerId',
    'isAvailable', 'createdAt', 'updatedAt'],
  communities: ['name', 'description', 'imageUrl', 'category', 'createdBy', 'memberCount',
    'createdAt', 'updatedAt'],
};
const DISCUSSION = ['title', 'content', 'authorId', 'likesCount', 'commentsCount',
  'createdAt', 'updatedAt'];

const ownFields = (d) => Object.keys(d).filter((k) => k !== '__SUB_COLLECTION_THREAD__');
let failures = 0;
const pass = (m) => console.log(`  PASS  ${m}`);
const fail = (m) => { console.log(`  FAIL  ${m}`); failures++; };

for (const [col, fields] of Object.entries(SPEC)) {
  const docs = Object.values(load(`${col}.json`));
  console.log(`\n=== ${col}: ${docs.length} docs, spec ${fields.length} fields ===`);

  const wrong = docs.filter((d) => {
    const k = ownFields(d);
    return k.length !== fields.length || !fields.every((f) => k.includes(f));
  });
  if (wrong.length) {
    const d = wrong[0];
    fail(`${wrong.length} docs have the wrong field set`);
    console.log(`      missing: ${fields.filter((f) => !(f in d)).join(', ') || '(none)'}`);
    console.log(`      extra  : ${ownFields(d).filter((x) => !fields.includes(x)).join(', ') || '(none)'}`);
  } else {
    pass(`all ${docs.length} docs match the ${fields.length}-field spec`);
  }

  const counts = new Set(docs.map((d) => ownFields(d).length));
  if (counts.size === 1) pass(`uniform field count (${[...counts][0]})`);
  else fail(`inconsistent field counts: ${[...counts].join(', ')}`);

  const sample = Object.values(load(`${col}.json`))[0];
  for (const f of fields) {
    const v = sample[f];
    const t = v === null ? 'null' : Array.isArray(v) ? `array[${v.length}]` : typeof v;
    const shown = v && typeof v === 'object' && !Array.isArray(v)
      ? JSON.stringify(v)
      : String(v).slice(0, 50);
    console.log(`      ${f.padEnd(15)} ${t.padEnd(11)} ${shown}`);
  }
}

console.log('\n=== communities/*/discussions ===');
const coms = load('communities.json');
let total = 0; let bad = 0; let noSub = 0;
for (const c of Object.values(coms)) {
  const ds = c.__SUB_COLLECTION_THREAD__?.discussions;
  if (!ds) { noSub++; continue; }
  total += Object.keys(ds).length;
  for (const d of Object.values(ds)) {
    if (Object.keys(d).length !== DISCUSSION.length || !DISCUSSION.every((f) => f in d)) bad++;
  }
}
if (noSub) fail(`${noSub} communities have no discussions subcollection`);
else pass(`${Object.keys(coms).length} communities, all have discussions`);
if (bad) fail(`${bad} discussion docs have the wrong field set`);
else pass(`all ${total} discussions match the ${DISCUSSION.length}-field spec`);

console.log('\n=== cart_items -> products integrity ===');
const products = load('products.json');
const subs = load('users_subcollections.json');
let carts = 0; let dangling = 0; let drift = 0;
for (const u of Object.values(subs)) {
  for (const c of Object.values(u.__SUB_COLLECTION_THREAD__.cart_items)) {
    carts++;
    const p = products[c.productId];
    if (!p) dangling++;
    else if (p.name !== c.name || p.price !== c.price) drift++;
  }
}
if (dangling) fail(`${dangling} of ${carts} cart items point at a missing product`);
else pass(`all ${carts} cart items resolve to a real product`);
if (drift) fail(`${drift} cart items have name/price drift from their product`);
else pass('cart name/price match the referenced product');

console.log(`\n${failures === 0 ? 'RESULT: schema OK' : `RESULT: ${failures} FAILURE(S)`}`);
process.exit(failures === 0 ? 0 : 1);
