// Verifies the DEPLOYED Firestore rules the way a real client hits them.
//
// The Flutter tests use firebase-admin, which bypasses security rules entirely,
// so they cannot catch a missing or mis-scoped rule. This script signs in a
// throwaway account through the public Auth API and then talks to Firestore
// over REST with that user's ID token, so every request is evaluated against
// the live rules.
//
//   node tool/verify-rules.mjs
//
// The throwaway user and anything it creates are deleted at the end.
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
let credential = applicationDefault();
const keyPath = join(ROOT, 'serviceAccountKey.json');
if (existsSync(keyPath)) credential = cert(JSON.parse(readFileSync(keyPath, 'utf8')));

const PROJECT = process.env.PROJECT_ID ?? 'faniverse-main-753e3';
const API_KEY = process.env.FIREBASE_API_KEY ?? 'AIzaSyD2Px3l1RfMaj4AkILdcIcZN5WawX8CRWA';
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

const app = initializeApp({ credential, projectId: PROJECT });
const auth = getAuth(app);
const db = getFirestore(app);

let failures = 0;
const check = (condition, message) => {
  console.log(`  ${condition ? 'PASS' : 'FAIL'}  ${message}`);
  if (!condition) failures++;
};

async function firestore(path, { method = 'GET', token, body } = {}) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json = {};
  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = { raw: text };
  }
  return { status: res.status, json };
}

const stamp = Date.now();
const email = `rules-check-${stamp}@example.com`;
const password = `Rules${stamp}aA1!`;
const OTHER = 'u_0001';

let createdUser;
let idToken;
let myUid;
const cleanupIds = { products: [], events: [] };
// Declared out here because the finally block needs it, and the try block
// where it is written may not have been reached.
const notifId = `save_rules-check-target`;

try {
  // --- sign a throwaway user in through the public API -------------------
  createdUser = await auth.createUser({ email, password, displayName: 'Rules Check' });
  myUid = createdUser.uid;

  const signIn = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  const signInJson = await signIn.json();
  idToken = signInJson.idToken;
  check(Boolean(idToken), `signed in as ${myUid} (status ${signIn.status})`);
  if (!idToken) throw new Error('cannot continue without an ID token');

  // --- reads the app depends on ------------------------------------------
  console.log('\n=== reads ===');
  for (const collection of ['products', 'events', 'content', 'users']) {
    const res = await firestore(`/${collection}?pageSize=1`, { token: idToken });
    check(res.status === 200, `read ${collection} -> ${res.status}`);
  }

  // --- merchandise: create, ownership scoping, delete --------------------
  console.log('\n=== merchandise ===');
  const mine = await firestore('/products', {
    method: 'POST',
    token: idToken,
    body: { fields: { name: { stringValue: 'Rules Check Tee' }, sellerId: { stringValue: myUid } } },
  });
  check(mine.status === 200, `create own product -> ${mine.status}`);
  if (mine.json.name) cleanupIds.products.push(mine.json.name.split('/').pop());

  const forged = await firestore('/products', {
    method: 'POST',
    token: idToken,
    body: {
      fields: {
        name: { stringValue: 'Forged' },
        // Claiming someone else's sellerId must be rejected.
        sellerId: { stringValue: OTHER },
      },
    },
  });
  check(forged.status === 403, `create product for another user is denied -> ${forged.status}`);

  if (cleanupIds.products.length) {
    const id = cleanupIds.products[0];
    const del = await firestore(`/products/${id}`, { method: 'DELETE', token: idToken });
    check(del.status === 200, `delete own product -> ${del.status}`);
    cleanupIds.products.length = 0;
  }

  // --- events: same shape ------------------------------------------------
  console.log('\n=== events ===');
  const myEvent = await firestore('/events', {
    method: 'POST',
    token: idToken,
    body: {
      fields: {
        title: { stringValue: 'Rules Check Meetup' },
        organizerId: { stringValue: myUid },
      },
    },
  });
  check(myEvent.status === 200, `create own event -> ${myEvent.status}`);
  if (myEvent.json.name) cleanupIds.events.push(myEvent.json.name.split('/').pop());

  const forgedEvent = await firestore('/events', {
    method: 'POST',
    token: idToken,
    body: { fields: { title: { stringValue: 'Forged' }, organizerId: { stringValue: OTHER } } },
  });
  check(forgedEvent.status === 403, `create event for another organizer is denied -> ${forgedEvent.status}`);

  if (cleanupIds.events.length) {
    const id = cleanupIds.events[0];
    const del = await firestore(`/events/${id}`, { method: 'DELETE', token: idToken });
    check(del.status === 200, `delete own event -> ${del.status}`);
    cleanupIds.events.length = 0;
  }

  // --- the save-notification regression ---------------------------------
  // The notification id is derived from (type, actor, target), so saving a
  // post twice writes over an existing document. That is an update, and it was
  // denied before the rules were widened.
  console.log('\n=== notifications (save twice) ===');
  const notifPath = `/users/${OTHER}/notifications/${notifId}`;
  const payload = {
    fields: {
      type: { stringValue: 'save' },
      actorUid: { stringValue: myUid },
      actorName: { stringValue: 'Rules Check' },
      contentId: { stringValue: 'target' },
    },
  };

  const first = await firestore(notifPath, { method: 'PATCH', token: idToken, body: payload });
  check(first.status === 200, `first save notification -> ${first.status}`);

  const second = await firestore(notifPath, { method: 'PATCH', token: idToken, body: payload });
  check(second.status === 200, `re-save same notification (was PERMISSION_DENIED) -> ${second.status}`);

  const forgedNotif = await firestore(`/users/${OTHER}/notifications/forged`, {
    method: 'PATCH',
    token: idToken,
    body: { fields: { type: { stringValue: 'save' }, actorUid: { stringValue: 'someone_else' } } },
  });
  check(forgedNotif.status === 403, `forged notification is denied -> ${forgedNotif.status}`);

  // --- is there anything to show? ----------------------------------------
  // The sections read products/events by owner. Empty collections are
  // indistinguishable from a broken feature, so confirm the seeded data is
  // actually there and carries a real owner uid.
  console.log('\n=== seeded data ===');
  const products = await db.collection('products').limit(50).get();
  const events = await db.collection('events').limit(50).get();
  check(products.size > 0, `products collection has data (${products.size})`);
  check(events.size > 0, `events collection has data (${events.size})`);

  const productOwners = products.docs.map((d) => d.get('sellerId')).filter(Boolean);
  const eventOwners = events.docs.map((d) => d.get('organizerId')).filter(Boolean);
  check(
    productOwners.length === products.size && productOwners.every((o) => typeof o === 'string' && o.length > 0),
    `every product has a sellerId (${productOwners.length}/${products.size})`,
  );
  check(
    eventOwners.length === events.size && eventOwners.every((o) => typeof o === 'string' && o.length > 0),
    `every event has an organizerId (${eventOwners.length}/${events.size})`,
  );

  // A user who has both should see both on their profile.
  const withBoth = productOwners.find((owner) => eventOwners.includes(owner));
  check(Boolean(withBoth), `at least one user has both merchandise and events (${withBoth ?? 'none'})`);
} catch (e) {
  console.error('\nverification aborted:', e);
  failures++;
} finally {
  // --- clean up after ourselves -----------------------------------------
  for (const [collection, ids] of Object.entries(cleanupIds)) {
    for (const id of ids) {
      try {
        await firestore(`/${collection}/${id}`, { method: 'DELETE', token: idToken });
      } catch {
        /* best effort */
      }
    }
  }

  // The notification test writes into a *seeded* user's inbox, because that is
  // the only way to prove the actor (not the recipient) may write it. The
  // throwaway account cannot delete it - the rules give deletion to the
  // recipient - so this uses the admin path, which bypasses rules.
  const notifRef = db.collection('users').doc(OTHER).collection('notifications').doc(notifId);
  if ((await notifRef.get()).exists) {
    await notifRef.delete();
    console.log(`cleanup: removed the test notification from ${OTHER}'s inbox`);
  }

  if (createdUser) await auth.deleteUser(myUid).catch(() => {});
  console.log('cleanup: throwaway user removed');
}

console.log(failures === 0 ? '\nAll rule checks passed.' : `\n${failures} check(s) failed.`);
process.exit(failures === 0 ? 0 : 1);
