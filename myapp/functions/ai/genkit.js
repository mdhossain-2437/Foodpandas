const { genkit } = require('genkit');
const { googleAI } = require('@genkit-ai/google-genai');
const logger = require('firebase-functions/logger');

const { defineMenuAssistantFlow } = require('./menu-assistant');

let cached = null;

/**
 * Returns the production menu assistant flow for `modelName`. Genkit is created
 * on first use because the plugin reads GEMINI_API_KEY, which Cloud Functions
 * only injects at request time (not during deploy-time discovery).
 */
function getMenuAssistantFlow({ modelName, loadCatalog }) {
  if (cached?.modelName !== modelName) {
    const ai = genkit({ plugins: [googleAI()] });
    cached = {
      modelName,
      flow: defineMenuAssistantFlow(ai, { model: googleAI.model(modelName), loadCatalog, logger }),
    };
  }
  return cached.flow;
}

module.exports = { getMenuAssistantFlow };
