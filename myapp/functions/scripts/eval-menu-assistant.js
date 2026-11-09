// Scores the menu assistant against the live Gemini model on a golden dataset.
// Usage: GEMINI_API_KEY=... npm run eval:ai [-- --model <gemini-model-id>]
const dataset = require('../ai/evals/menu-assistant.dataset.json');
const { demoMenu } = require('../catalog/demo-menu');
const {
  PROMPT_VERSION,
  buildMenuCatalog,
  defineMenuAssistantFlow,
  normalizeQuery,
} = require('../ai/menu-assistant');

function scoreEvalCase(testCase, result) {
  const ids = result.suggestions.map((s) => `${s.restaurantId}/${s.itemId}`);
  const failures = [];
  if (testCase.expectEmpty && ids.length > 0) {
    failures.push(`expected no suggestions, got ${ids.join(', ')}`);
  }
  if (testCase.expectAnyOf && !ids.some((id) => testCase.expectAnyOf.includes(id))) {
    failures.push(`expected one of ${testCase.expectAnyOf.join(', ')}, got ${ids.join(', ') || 'nothing'}`);
  }
  if (typeof testCase.maxPrice === 'number') {
    const overBudget = result.suggestions.filter((s) => s.price > testCase.maxPrice);
    if (overBudget.length > 0) {
      failures.push(`over budget: ${overBudget.map((s) => `${s.itemId} ₱${s.price}`).join(', ')}`);
    }
  }
  return { passed: failures.length === 0, failures };
}

async function main() {
  if (!process.env.GEMINI_API_KEY) {
    console.log('Skipped: set GEMINI_API_KEY to evaluate the menu assistant against the live model.');
    return;
  }
  const modelFlag = process.argv.indexOf('--model');
  const modelName = modelFlag > -1 ? process.argv[modelFlag + 1] : process.env.AI_MODEL || 'gemini-3.6-flash';
  const { genkit } = require('genkit');
  const { googleAI } = require('@genkit-ai/google-genai');
  const ai = genkit({ plugins: [googleAI()] });
  const catalog = buildMenuCatalog({ demoMenu });
  const flow = defineMenuAssistantFlow(ai, {
    model: googleAI.model(modelName),
    loadCatalog: async () => catalog,
  });

  let passed = 0;
  for (const testCase of dataset) {
    const startedAt = Date.now();
    let score;
    try {
      score = scoreEvalCase(testCase, await flow({ query: normalizeQuery(testCase.query) }));
    } catch (error) {
      score = { passed: false, failures: [`error: ${error.message}`] };
    }
    if (score.passed) passed += 1;
    const status = score.passed ? 'PASS' : 'FAIL';
    console.log(`${status} ${Date.now() - startedAt}ms  ${testCase.query}`);
    for (const failure of score.failures) console.log(`     ${failure}`);
  }
  console.log(`\n${passed}/${dataset.length} passed (model ${modelName}, ${PROMPT_VERSION})`);
  process.exitCode = passed === dataset.length ? 0 : 1;
}

module.exports = { scoreEvalCase };

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
