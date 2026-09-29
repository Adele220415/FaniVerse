/**
 * Backfill users created before the 12-field schema.
 *
 * Registration now writes all 12 fields, but accounts created earlier only
 * have 4. This adds the missing ones without overwriting anything that
 * already exists.
 *
 *   node seed/backfill-users.mjs           # report only
 *   node seed/backfill-users.mjs --write   # apply
 *
 * Mirrors UserModel.fromFirebase defaults in lib/models/user_model.dart.
 * Keep the two in sync.
 */

import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const PROJECT_ID = process.env.PROJECT_ID ?? 'faniverse-main-753e3';
const WRITE = process.argv.includes('--write');

let credential = applicationDefault();
const keyPath = join(ROOT, 'serviceAccountKey.json');
if (existsSync(keyPath)) {
  credential = cert(JSON.parse(readFileSync(keyPath, 'utf8')));
  console.log('Credential: serviceAccountKey.json');
} else {
  console.log('Credential: application default');
}

const db = getFirestore(initializeApp({ credential, projectId: PROJECT_ID }));

const REQUIRED = [
  'uid', 'name', 'email', 'username', 'profileImage', 'bio',
  'categories', 'role', 'isActive', 'createdAt', 'updatedAt', 'lastLoginAt',
];

/** Canonical vocabulary. Must match AppCategories.all and CATEGORIES in
 *  seed/generate.mjs - Firestore arrayContains is case-sensitive. */
const CANON = new Set([
  'anime', 'donghua', 'manga', 'manhua', 'manhwa', 'comics',
  'gaming', 'e-sports', 'music', 'movies', 'books',
]);

/**
 * Lowercase any category that is not already canonical. Earlier app builds
 * stored Title Case ('Music'), which silently breaks arrayContains queries.
 */
const needsNormalise = (cats) =>
  Array.isArray(cats) && cats.some((c) => typeof c === 'string' && c !== c.toLowerCase());

const normalise = (cats) =>
  Array.from(new Set(cats.map((c) => String(c).toLowerCase()).filter((c) => CANON.has(c))));

/** Must match UserModel.deriveUsername. */
const deriveUsername = (name, uid) => {
  const base = String(name ?? '').toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
  return `${base || 'user'}_${String(uid).slice(0, 4)}`;
};

const snapshot = await db.collection('users').get();
console.log(`Scanning ${snapshot.size} user document(s)\n`);

let patched = 0;
let alreadyComplete = 0;

for (const doc of snapshot.docs) {
  const data = doc.data();
  const missing = REQUIRED.filter((f) => !(f in data));
  const patch = {};

  for (const f of missing) {
    switch (f) {
      case 'uid': patch.uid = doc.id; break;
      case 'username': patch.username = deriveUsername(data.name, doc.id); break;
      case 'profileImage': patch.profileImage = `https://i.pravatar.cc/300?u=${doc.id}`; break;
      case 'bio': patch.bio = ''; break;
      // Only fills an ABSENT field, so an account already promoted to admin by
      // seed/grant-admin.mjs is left alone. Legacy values from the old
      // reader/writer/editor/moderator ladder are collapsed to `fan` further
      // down, since those rungs no longer exist.
      case 'role': patch.role = 'fan'; break;
      case 'isActive': patch.isActive = true; break;
      case 'categories': patch.categories = []; break;
      case 'createdAt': patch.createdAt = data.createdAt ?? new Date().toISOString(); break;
      case 'updatedAt': patch.updatedAt = FieldValue.serverTimestamp(); break;
      case 'lastLoginAt': patch.lastLoginAt = FieldValue.serverTimestamp(); break;
    }
  }

  // Normalise legacy Title Case categories even though the field is present.
  if (needsNormalise(data.categories)) {
    patch.categories = normalise(data.categories);
  }

  // Collapse the old reader/writer/editor/moderator ladder onto `fan`.
  //
  // This has to run even for a document that is otherwise full-shape, since
  // those documents are the ones carrying a legacy role. `admin` is passed
  // through untouched - it is the only value that still means something, and
  // rewriting it would demote the real admin. The whitelist is deliberate: any
  // unrecognised value becomes `fan`, so a corrupt role can never fail open.
  if (typeof data.role === 'string' && data.role !== 'fan' && data.role !== 'admin') {
    patch.role = 'fan';
  }

  if (!Object.keys(patch).length) { alreadyComplete++; continue; }

  const catNote = patch.categories ? `  categories: ${JSON.stringify(data.categories)} -> ${JSON.stringify(patch.categories)}` : '';
  console.log(`${doc.id}${catNote}`);
  console.log(`  missing : ${missing.length ? missing.join(', ') : '(none)'}`);
  if (Object.keys(patch).length) {
    console.log(`  patch   : ${Object.entries(patch).map(([k, v]) => `${k}=${JSON.stringify(v)}`).join(', ')}`);
  }

  if (WRITE) {
    await doc.ref.update(patch);
    console.log('  -> written');
  }
  patched++;
}

console.log(`\n${alreadyComplete} already full-shape, ${patched} need backfill.`);
if (!WRITE && patched) {
  console.log('Dry run. Re-run with --write to apply.');
} else if (WRITE) {
  console.log('Done.');
}
