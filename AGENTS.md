# AGENTS.md

Guidance for contributors and AI coding agents working in this repository.

## Layout

- `myapp/`: Flutter app (web and Android; iOS needs `flutterfire configure`),
  Firebase config, Firestore rules.
- `myapp/functions/`: Cloud Functions on Node.js 24 (CommonJS) for ordering,
  Xendit payments, notifications and the AI menu assistant.
- `.github/workflows/ci.yml`: the checks every change must pass.

## Commands

From `myapp/` (Flutter 3.47.x stable):

```shell
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build web --release
```

From `myapp/functions/`:

```shell
npm ci
npm run lint
npm test
npm run eval:ai   # live Gemini eval; needs GEMINI_API_KEY
```

## Invariants

- Never trust client prices or totals. `createOrder` reprices from Firestore
  or `functions/catalog/demo-menu.js`; keep that file in sync with `vendors`
  in `lib/main.dart`.
- Clients cannot write `orders`, `restaurants`, notifications or `aiUsage`.
  Keep `firestore.rules` deny-by-default.
- Secrets (Xendit, Gemini) live in Secret Manager via `defineSecret`. Never put
  keys in Dart code, dart-defines or git.
- Services are injected into `FoodPandasApp` behind interfaces; widget tests
  use fakes, never real Firebase.

## AI engineering conventions

- LLM calls run only in Cloud Functions through Genkit (`functions/ai/`); the
  app calls a callable function.
- Ground every answer: give the model only trusted data, request a zod schema,
  and validate returned IDs against that data before responding
  (`resolveSuggestions`).
- Treat user text as untrusted: length limits, delimiter stripping, and a
  system prompt that ignores embedded instructions.
- Each AI endpoint needs auth, a per-user quota (`ai/quota.js`), App Check
  support (`requireAppCheck`) and structured logs with model, prompt version,
  latency and token usage.
- Bump `PROMPT_VERSION` when a prompt changes, extend
  `ai/evals/*.dataset.json`, and run `npm run eval:ai` before shipping prompt
  or model changes.
- Keep unit tests offline with a fake Genkit model (`ai.defineModel`), as in
  `test/menu-assistant.test.js`.
- Require Genkit lazily inside AI functions so other functions keep fast cold
  starts.
- Select models through the `AI_MODEL` param using stable Gemini IDs, and check
  deprecation dates before upgrading.
