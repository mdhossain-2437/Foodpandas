const { FieldValue } = require('firebase-admin/firestore');
const { HttpsError } = require('firebase-functions/v2/https');

/**
 * Atomically records one AI request for `uid` and rejects it once `limit`
 * requests were made on the current UTC day. Returns the remaining allowance.
 */
async function consumeDailyQuota(db, uid, { limit, now = new Date(), collection = 'aiUsage' }) {
  const day = now.toISOString().slice(0, 10);
  const ref = db.collection(collection).doc(uid);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const data = snapshot.exists ? snapshot.data() : {};
    const used = data.day === day ? Number(data.count) || 0 : 0;
    if (used >= limit) {
      throw new HttpsError(
        'resource-exhausted',
        `You have used all ${limit} assistant requests for today. Try again tomorrow.`,
      );
    }
    transaction.set(ref, { day, count: used + 1, updatedAt: FieldValue.serverTimestamp() });
    return { day, remaining: limit - used - 1 };
  });
}

module.exports = { consumeDailyQuota };
