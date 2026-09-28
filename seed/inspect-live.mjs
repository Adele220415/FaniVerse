/**
 * Inspect the live Firestore project before seeding.
 *
 * Read-only. Reports existing collections, document counts, any ID
 * collisions with the generated seed data, and existing subcollections.
 *
 *   node seed/inspect-live.mjs
 */

import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const PROJECT_ID = process.env.PROJECT_ID ?? 'faniverse-main-753e3';

let credential = applicationDefault();
const keyPath = join(ROOT, 'serviceAccountKey.json');
if (existsSync(keyPath)) {
  credential = cert(JSON.parse(readFileSync(keyPath, 'utf8')));
  console.log('Credential: serviceAccountKey.json');
} else {
  console.log('Credential: application default');
}

const db = getFirestore(initializeApp({ credential, projectId: PROJECT_ID }));

const load = (f) => {
  const p = join(__dirname, 'data', f);
  return existsSync(p) ? Object.keys(JSON.parse(readFileSync(p, 'utf8'))) : [];
};
const seedUsers = load('users.json');
const seedContent = load('content.json');

const cols = await db.listCollections();
console.log(`Project: ${PROJECT_ID}`);
console.log(`Top-level collections: ${cols.length ? cols.map((c) => c.id).join(', ') : '(none)'}\n`);

for (const col of cols) {
  const snap = await col.get();
  const ids = snap.docs.map((d) => d.id);
  const collisions = ids.filter((id) => seedUsers.includes(id) || seedContent.includes(id));

  console.log(`=== ${col.id} : ${snap.size} documents ===`);
  console.log(`  collisions with seed IDs: ${collisions.length ? `${collisions.length} (${collisions.slice(0, 5).join(', ')})` : 'none'}`);

  for (const doc of snap.docs.slice(0, 3)) {
    const fields = Object.keys(doc.data());
    console.log(`  - ${doc.id}  [${fields.length} fields: ${fields.slice(0, 7).join(', ')}${fields.length > 7 ? ', ...' : ''}]`);
  }
  if (snap.size > 3) console.log(`  ... and ${snap.size - 3} more`);

  let subCount = 0;
  for (const doc of snap.docs) {
    const subs = await doc.ref.listCollections();
    if (subs.length) {
      subCount++;
      if (subCount <= 2) console.log(`  subcollections under ${doc.id}: ${subs.map((s) => s.id).join(', ')}`);
    }
  }
  if (subCount > 2) console.log(`  (and ${subCount - 2} more docs with subcollections)`);
  console.log('');
}

console.log(`Seed would write: ${seedUsers.length} users, ${seedContent.length} content, plus 3 subcollections under each user.`);
console.log('Seed IDs are namespaced (u_0001.., c_00001..) so real app users are not overwritten.');
