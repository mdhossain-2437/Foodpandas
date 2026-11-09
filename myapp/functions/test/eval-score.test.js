const assert = require('node:assert/strict');
const { test } = require('node:test');

const { scoreEvalCase } = require('../scripts/eval-menu-assistant');

const suggestion = (itemId, price) => ({ restaurantId: 'demo-ate-mels', itemId, price });

test('passes when an expected item is suggested within budget', () => {
  const result = { suggestions: [suggestion('turon', 75)] };
  assert.deepEqual(
    scoreEvalCase({ expectAnyOf: ['demo-ate-mels/turon'], maxPrice: 100 }, result),
    { passed: true, failures: [] },
  );
});

test('reports missing expectations, budget overruns and unexpected answers', () => {
  const result = { suggestions: [suggestion('halo-halo', 120)] };
  assert.equal(scoreEvalCase({ expectAnyOf: ['demo-ate-mels/turon'], maxPrice: 100 }, result).failures.length, 2);
  assert.equal(scoreEvalCase({ expectEmpty: true }, result).passed, false);
});
