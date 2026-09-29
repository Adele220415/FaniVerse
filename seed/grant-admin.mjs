/**
 * Provision the single admin account.
 *
 * The app has exactly two roles: `fan` and `admin`. The admin is identified by
 * its email address, but the role itself is written HERE, out-of-band, using
 * the Admin SDK which bypasses Firestore rules.
 *
 * That indirection is the point. Firestore rules pin `role` on every
 * client-side update, so the app cannot promote anyone - not even a screen
 * built specifically to do it. If the role were ever set from the client, the
 * whole model collapses: the credential that grants admin would be sitting in
 * the binary.
 *
 *   node seed/grant-admin.mjs --write
 *
 * Dry-run by default, matching the other scripts in this folder.
 *
 * Idempotent. Re-running updates the password and the user document but never
 * creates a second admin: it looks the account up by uid first and only
 * creates one if no account already holds the admin role.
 */

import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const PROJECT_ID = process.env.PROJECT_ID ?? 'faniverse-main-753e3';
const WRITE = process.argv.includes('--write');

const ADMIN_EMAIL = 'adminpage@faniverse.com';

// Override rather than commit it. The value below is the initial password; set
// ADMIN_PASSWORD in the environment to rotate it without editing a tracked file.
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'VerseFan1';
const ADMIN_NAME = process.env.ADMIN_NAME ?? 'Faniverse Admin';

let credential = applicationDefault();
const keyPath = join(ROOT, 'serviceAccountKey.json');
if (existsSync(keyPath)) {
  credential = cert(JSON.parse(readFileSync(keyPath, 'utf8')));
  console.log('Credential: serviceAccountKey.json');
} else {
  console.log('Credential: application default');
}

const app = initializeApp({ credential, projectId: PROJECT_ID });
const auth = getAuth(app);
const db = getFirestore(app);

/** Must match UserModel.deriveUsername. */
const deriveUsername = (name, uid) => {
  const base = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
  const safe = base || 'user';
  const suffix = uid.length <= 4 ? uid : uid.slice(0, 4);
  return `${safe}_${suffix}`;
};

/** Must match UserModel.defaultProfileImage. */
const defaultProfileImage = (uid) => `https://i.pravatar.cc/300?u=${uid}`;

/**
 * Finds the uid of an account that already holds the admin role.
 *
 * The check is on the document's `role`, not on the email, so a demoted
 * adminpage@faniverse.com does not block creating a new admin - and so a second
 * admin cannot be created by accident if the address was already reused for an
 * ordinary account.
 */
async function findExistingAdminUid() {
  const snap = await db.collection('users').where('role', '==', 'admin').limit(2).get();
  if (snap.empty) return null;
  if (snap.size > 1) {
    console.warn(
      `WARNING: ${snap.size} accounts already hold the admin role. ` +
        'Resolve this in the Firestore console before continuing.',
    );
  }
  return snap.docs[0].id;
}

async function main() {
  const existingAdminUid = await findExistingAdminUid();

  // Prefer the already-privileged account, so re-running never promotes a
  // second one. Fall back to a lookup by the admin email.
  let uid = existingAdminUid;
  if (uid) {
    const doc = await db.collection('users').doc(uid).get();
    const record = await auth.getUser(uid).catch(() => null);
    console.log(`Found existing admin: ${record?.email ?? doc.id} (${uid})`);
  } else {
    const byEmail = await auth.getUserByEmail(ADMIN_EMAIL).catch(() => null);
    if (byEmail) {
      uid = byEmail.uid;
      console.log(`Found account for ${ADMIN_EMAIL} (${uid}); promoting it`);
    }
  }

  if (!WRITE) {
    console.log('\nDry run. Nothing was written. Re-run with --write to apply:');
    console.log('  node seed/grant-admin.mjs --write');
    return;
  }

  if (!uid) {
    console.log(`Creating ${ADMIN_EMAIL} ...`);
    const created = await auth.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      displayName: ADMIN_NAME,
      emailVerified: true,
    });
    uid = created.uid;
  } else {
    // The email is written here as well as the password. The admin is located
    // by uid (from the Firestore role) or by email, and either path can land on
    // an account registered under a different address - which leaves Auth and
    // the user document disagreeing. Setting it explicitly makes this script
    // converge on ADMIN_EMAIL instead of only fixing half the record.
    //
    // If ADMIN_EMAIL is already held by a *different* uid, updateUser throws
    // EMAIL_EXISTS and the script exits rather than silently merging two
    // accounts. That is the intended outcome: it needs a human to decide which
    // record keeps the address.
    console.log(`Updating password and email for ${ADMIN_EMAIL} ...`);
    await auth.updateUser(uid, {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      displayName: ADMIN_NAME,
      emailVerified: true,
    });
  }

  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  const existing = snap.exists ? snap.data() : {};

  // The full 12-field shape, matching UserModel.toJson. A user document that is
  // missing fields is what the legacy backfill script exists to fix, and
  // anything reading this one expects all of them.
  await ref.set(
    {
      uid,
      name: ADMIN_NAME,
      email: ADMIN_EMAIL,
      username: existing.username || deriveUsername(ADMIN_NAME, uid),
      profileImage: existing.profileImage || defaultProfileImage(uid),
      bio: existing.bio ?? '',
      // An admin manages the catalogue, so they are not a fan of a particular
      // fandom. An empty list also keeps them out of the
      // "select 3 categories" onboarding gate on next sign-in.
      categories: existing.categories ?? [],
      role: 'admin',
      isActive: true,
      createdAt: existing.createdAt ?? FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      lastLoginAt: existing.lastLoginAt ?? FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log(`\nAdmin ready: ${ADMIN_EMAIL} (${uid})`);
  console.log('Next: firebase deploy --only firestore:rules');
}

main().catch((err) => {
  console.error('grant-admin failed:', err);
  process.exit(1);
});
