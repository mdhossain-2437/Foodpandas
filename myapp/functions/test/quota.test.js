const assert = require('node:assert/strict');
const { describe, test } = require('node:test');

const { consumeDailyQuota } = require('../ai/quota');

function fakeDb(initial = {}) {
  const store = new Map(Object.entries(initial));
  const db = {
    collection: (name) => ({ doc: (id) => ({ path: `${name}/${id}` }) }),
    runTransaction: async (update) => update({
      get: async (ref) => ({ exists: store.has(ref.path), data: () => store.get(ref.path) }),
      set: (ref, value) => store.set(ref.path, value),
    }),
  };
  return { db, store };
}

const now = new Date('2026-11-09T10:00:00Z');

describe('consumeDailyQuota', () => {
  test('starts a new daily counter', async () => {
    const { db, store } = fakeDb();
    const result = await consumeDailyQuota(db, 'user-1', { limit: 3, now });

    assert.deepEqual(result, { day: '2026-11-09', remaining: 2 });
    assert.equal(store.get('aiUsage/user-1').count, 1);
  });

  test('counts requests within the same UTC day', async () => {
    const { db, store } = fakeDb({ 'aiUsage/user-1': { day: '2026-11-09', count: 1 } });
    const result = await consumeDailyQuota(db, 'user-1', { limit: 3, now });

    assert.equal(result.remaining, 1);
    assert.equal(store.get('aiUsage/user-1').count, 2);
  });

  test('resets the counter on a new day', async () => {
    const { db } = fakeDb({ 'aiUsage/user-1': { day: '2026-11-08', count: 3 } });
    const result = await consumeDailyQuota(db, 'user-1', { limit: 3, now });

    assert.equal(result.remaining, 2);
  });

  test('rejects requests once the limit is reached', async () => {
    const { db, store } = fakeDb({ 'aiUsage/user-1': { day: '2026-11-09', count: 3 } });

    await assert.rejects(
      consumeDailyQuota(db, 'user-1', { limit: 3, now }),
      (error) => error.code === 'resource-exhausted',
    );
    assert.equal(store.get('aiUsage/user-1').count, 3);
  });
});
