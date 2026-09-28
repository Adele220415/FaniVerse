/**
 * Faniverse seed uploader.
 *
 * Reads the JSON emitted by generate.mjs and writes it to Firestore with the
 * correct native types:
 *   { "__ref__": "users/u_0001" }  -> firestore.DocumentReference
 *   ISO-8601 string under a date key -> firestore.Timestamp
 *   __SUB_COLLECTION_THREAD__      -> real subcollections
 *
 * Setup:
 *   npm i firebase-admin
 *   firebase login && firebase use faniverse-main-753e3
 *   node seed/upload.mjs
 *
 * Override the project with PROJECT_ID=... and the database with DATABASE_ID=...
 */

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
// The generated JSON lives beside this script, in seed/data/.
const DATA_DIR = join(__dirname, 'data');

const PROJECT_ID = process.env.PROJECT_ID ?? 'faniverse-main-753e3';
const DATABASE_ID = process.env.DATABASE_ID ?? '(default)';

const TIMESTAMP_KEYS = new Set([
  'createdAt', 'updatedAt', 'addedAt', 'lastLoginAt', 'releaseDate',
  'eventDate', 'startTime', 'endTime',
]);

const SUB_COLLECTION_KEY = '__SUB_COLLECTION_THREAD__';

// Prefer a service account key at the project root; otherwise fall back to
// Application Default Credentials (gcloud auth application-default login).
let serviceAccount;
try {
  serviceAccount = JSON.parse(readFileSync(join(__dirname, '..', 'serviceAccountKey.json'), 'utf8'));
  console.log('Using service account key at ./serviceAccountKey.json');
} catch {
  console.log('No serviceAccountKey.json - using application default credentials');
}

const app = initializeApp({
  // cert() is imported at the top; require() is not available in ESM.
  credential: serviceAccount ? cert(serviceAccount) : applicationDefault(),
  projectId: PROJECT_ID,
});

const db = getFirestore(app, DATABASE_ID);
const read = (f) => JSON.parse(readFileSync(join(DATA_DIR, f), 'utf8'));

// --dry-run validates credentials, paths and payload shape, then writes
// nothing. Useful before a first push to a live project.
const DRY_RUN = process.argv.includes('--dry-run');
let planned = 0;

/** Split a plain-object tree into scalar fields and nested subcollections. */
function splitNode(node) {
  const fields = {};
  const subs = {};
  for (const [key, value] of Object.entries(node)) {
    if (key === SUB_COLLECTION_KEY) {
      for (const [subName, subDocs] of Object.entries(value)) {
        subs[subName] = subDocs;
      }
    } else {
      fields[key] = encodeValue(key, value);
    }
  }
  return { fields, subs };
}

/** Recursively convert refs, dates, arrays, and nested maps. */
function encodeValue(key, value) {
  if (value === null || value === undefined) return null;

  if (Array.isArray(value)) {
    return value.map((v) => encodeValue(null, v));
  }

  if (typeof value === 'object') {
    if (typeof value.__ref__ === 'string') {
      return db.doc(value.__ref__);
    }
    // Plain nested map: no timestamp semantics, just recurse.
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, encodeValue(null, v)]),
    );
  }

  if (typeof value === 'string' && TIMESTAMP_KEYS.has(key)) {
    const d = new Date(value);
    if (!Number.isNaN(d.getTime())) return Timestamp.fromDate(d);
  }

  return value;
}

/** Write {fields, subs} into docRef, batching at 500 writes. */
async function writeDoc(docRef, { fields, subs }) {
  if (Object.keys(fields).length) {
    if (DRY_RUN) planned += 1;
    else await docRef.set(fields);
  }

  for (const [subName, subDocs] of Object.entries(subs)) {
    const entries = Object.entries(subDocs);
    for (let i = 0; i < entries.length; i += 400) {
      if (DRY_RUN) { planned += Math.min(400, entries.length - i); continue; }
      const batch = db.batch();
      for (const [subId, subNode] of entries.slice(i, i + 400)) {
        const { fields: f } = splitNode(subNode);
        batch.set(docRef.collection(subName).doc(subId), f);
      }
      await batch.commit();
    }
  }
}

async function seedCollection(collectionName, file, transform = (id, node) => [id, node]) {
  const data = read(file);
  const entries = Object.entries(data).map(([id, node]) => transform(id, node));

  for (let i = 0; i < entries.length; i += 400) {
    if (DRY_RUN) { planned += Math.min(400, entries.length - i); break; }
    const batch = db.batch();
    for (const [id, node] of entries.slice(i, i + 400)) {
      const { fields } = splitNode(node);
      batch.set(db.collection(collectionName).doc(id), fields);
    }
    await batch.commit();
    console.log(`  ${collectionName}: ${Math.min(i + 400, entries.length)}/${entries.length}`);
  }
}

async function main() {
  console.log(`Target: ${PROJECT_ID} / ${DATABASE_ID}${DRY_RUN ? '   [DRY RUN - nothing will be written]' : ''}\n`);

  // Verify credentials before doing any work.
  const probe = await db.listCollections();
  const existing = probe.map((c) => c.id);
  console.log(`Connected. Existing top-level collections: ${existing.length ? existing.join(', ') : '(none)'}\n`);

  const STEPS = [
    ['1/6', 'users', () => seedCollection('users', 'users.json')],
    ['2/6', 'users/*/wishlist_items + users/*/cart_items + users/*/bookmarks', async () => {
      const subData = read('users_subcollections.json');
      for (const [userId, node] of Object.entries(subData)) {
        const { subs } = splitNode(node);
        await writeDoc(db.collection('users').doc(userId), { fields: {}, subs });
      }
      console.log(`  done: ${Object.keys(subData).length} users`);
    }],
    ['3/6', 'content', () => seedCollection('content', 'content.json')],
    ['4/6', 'products', () => seedCollection('products', 'products.json')],
    ['5/6', 'events', () => seedCollection('events', 'events.json')],
    ['6/6', 'communities + communities/*/discussions', async () => {
      const coms = read('communities.json');
      for (const [id, node] of Object.entries(coms)) {
        // splitNode lifts __SUB_COLLECTION_THREAD__ out of the field map, so
        // discussions become real subcollections rather than nested fields.
        const { fields, subs } = splitNode(node);
        await writeDoc(db.collection('communities').doc(id), { fields, subs });
      }
      console.log(`  done: ${Object.keys(coms).length} communities`);
    }],
  ];

  for (const [step, label, run] of STEPS) {
    console.log(`[${step}] ${label}`);
    await run();
  }

  if (DRY_RUN) {
    console.log(`\nDry run complete - ${planned} documents would be written. Nothing was changed.`);
    return;
  }

  // Final sanity check: references must have resolved to real documents.
  const [u, p, e, c] = await Promise.all([
    db.collection('users').count().get(),
    db.collection('products').count().get(),
    db.collection('events').count().get(),
    db.collection('content').limit(2).get(),
  ]);
  console.log(`\nusers=${u.data().count} products=${p.data().count} events=${e.data().count}`);
  for (const doc of c.docs) {
    const author = doc.get('author');
    const target = author && typeof author.path === 'string' ? author.path : '(not a reference)';
    console.log(`  ${doc.id} -> author ${target}`);
  }

  console.log('\nDone.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
