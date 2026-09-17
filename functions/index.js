const { onRequest } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

initializeApp();
const db = getFirestore();
const auth = getAuth();

const ROLE_ADMIN = 'admin';
const COLLECTIONS = {
  users: 'users',
  auditLogs: 'auditLogs',
};
const ACTIONS = {
  userDelete: 'USER_DELETE',
};

/**
 * Permanently delete a user account (admin-only).
 *
 * This is the only place the app can truly free a mis-created email: the
 * Flutter client SDK cannot delete an arbitrary user's Firebase Auth credential
 * (`User.delete()` works only for the signed-in user), so the deletion runs
 * with the Admin SDK here.
 *
 * Transport: the Flutter app POSTs a JSON body `{ "uid": "<targetUid>" }`
 * with the ADMIN's Firebase ID token in `Authorization: Bearer <idToken>`.
 * The function verifies that token with the Admin SDK, then:
 *   1. Enforces that the caller is an authenticated ADMIN.
 *   2. Guards against self-deletion and deleting the last admin.
 *   3. Revokes the target's Firebase Auth credential -> frees the email.
 *   4. Removes the `users/{uid}` Firestore document so the account disappears
 *      from management lists.
 *   5. Appends a best-effort audit log entry (beyond client rules).
 *
 * Related domain records (pets, appointments, medical records) are left intact
 * in keeping with the "never delete medical records" constraint; once the Auth
 * credential is revoked nobody can sign in as that user, so the records become
 * inert.
 */
exports.deleteUser = onRequest(async (req, res) => {
  // CORS (browser-based auth is out of scope but harmless to allow).
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.status(204).end();
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed.' });
    return;
  }

  try {
    // 0. Verify the caller's ID token -> know who is acting.
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!token) {
      res.status(401).json({ error: 'Sign in to perform this action.' });
      return;
    }
    let decoded;
    try {
      decoded = await auth.verifyIdToken(token);
    } catch (e) {
      res.status(401).json({ error: 'Invalid or expired session.' });
      return;
    }
    const callerUid = decoded.uid;

    // 1. Authorization: caller must be an active ADMIN.
    const callerDoc = await db.collection(COLLECTIONS.users).doc(callerUid).get();
    if (!callerDoc.exists || callerDoc.data().role !== ROLE_ADMIN) {
      res.status(403).json({ error: 'Admins only.' });
      return;
    }

    // 2. Validate the target.
    const body = req.body && typeof req.body === 'object' ? req.body : {};
    const targetUid = body.uid;
    if (typeof targetUid !== 'string' || targetUid.length === 0) {
      res.status(400).json({ error: 'Missing user uid.' });
      return;
    }
    if (targetUid === callerUid) {
      res.status(409).json({ error: 'You cannot delete your own account.' });
      return;
    }

    const targetRef = db.collection(COLLECTIONS.users).doc(targetUid);
    const targetDoc = await targetRef.get();
    if (!targetDoc.exists) {
      res.status(404).json({ error: 'User not found.' });
      return;
    }
    const target = targetDoc.data();

    // 3. Guard: cannot delete the last admin.
    if (target.role === ROLE_ADMIN) {
      const admins = await db
        .collection(COLLECTIONS.users)
        .where('role', '==', ROLE_ADMIN)
        .limit(2)
        .get();
      if (admins.size <= 1) {
        res.status(409).json({ error: 'Cannot delete the last admin account.' });
        return;
      }
    }

    // 4. Revoke the Auth credential (frees the email) + remove the Firestore doc.
    try {
      await auth.deleteUser(targetUid);
    } catch (e) {
      // If the Auth user is already gone (e.g. deleted out-of-band) we still
      // remove the Firestore doc so the account fully disappears.
      logger.warn('auth.deleteUser failed, continuing with doc removal.', e);
    }
    await targetRef.delete();

    // 5. Audit (best-effort; Admin SDK bypasses client Firestore rules).
    try {
      await db.collection(COLLECTIONS.auditLogs).add({
        userId: typeof callerDoc.data().id === 'number' ? callerDoc.data().id : 0,
        action: ACTIONS.userDelete,
        entityType: 'USER',
        entityId: typeof target.id === 'number' ? `${target.id}` : `${targetUid}`,
        oldValues: { email: target.email || null, role: target.role || null },
        newValues: {},
        createdAt: new Date(),
      });
    } catch (e) {
      logger.warn('Audit log write failed.', e);
    }

    res.status(200).json({ ok: true });
  } catch (e) {
    logger.error('deleteUser failed.', e);
    res.status(500).json({ error: 'Internal error.' });
  }
});