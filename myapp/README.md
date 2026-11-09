# Food-Pandas

A responsive Flutter ordering experience for neighborhood Filipino food stalls.
Built-in vendor/menu content is sample data; real orders and customer data for
verified Firebase restaurants are managed through trusted Firebase Cloud Functions.

## Project structure

```text
myapp/
├── lib/
│   ├── main.dart             # App shell, ordering UI and verified-checkout gate
│   ├── bootstrap.dart        # Firebase startup, Crashlytics, App Check, emulators
│   ├── config/app_config.dart  # --dart-define build settings
│   ├── firebase_options.dart # FlutterFire platform configuration
│   ├── screens/              # Auth, orders, restaurants, AI assistant pages
│   └── services/             # Firebase-backed services (auth, orders, AI, ...)
├── functions/
│   ├── index.js              # Callable/HTTP/Firestore Cloud Functions
│   ├── ai/                   # Genkit menu assistant, quota, eval dataset
│   ├── catalog/demo-menu.js  # Server-side sample menu (authoritative prices)
│   ├── scripts/              # Live-model eval runner
│   └── test/                 # node:test unit tests
├── firestore.rules           # Firebase customer and restaurant access rules
├── test/
│   └── widget_test.dart      # Ordering, checkout and AI assistant tests
├── web/
│   ├── index.html            # Browser title and app metadata
│   └── manifest.json
├── pubspec.yaml
└── README.md
```

CI (`.github/workflows/ci.yml`) runs `dart format`, `flutter analyze`,
`flutter test`, a web release build, the Functions lint/tests and an Android
release build on every pull request. Dependabot keeps pub, npm and GitHub
Actions dependencies current.

## Run in a browser

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) with web
support and a current Chrome or Edge browser. From this project folder:

```bash
flutter pub get
flutter run -d chrome
```

To create a static web release:

```bash
flutter build web --release
```

The generated site is in `build/web/`. Deploy that folder to a static host. For
hosting under a subpath, pass the matching `--base-href` to `flutter build web`.

## Included screens and flow

- Home landing page with local-stall highlights
- Vendor directory with search and food-category filters
- Vendor menu with add-to-cart actions
- Cart with editable item quantities and delivery estimate
- Validated checkout with a manually entered delivery address, cash on delivery,
  and Xendit GCash/GrabPay/card payments
- Order confirmation and live progress timeline for verified restaurant orders

The cart and sample-preview orders exist only in app memory and reset on
refresh. Food photos load from Unsplash; colored food-themed placeholders
appear if a photo is unavailable.

## Firebase setup (Phase 2)

Phase 2 adds Firebase email/password authentication and Firebase
Authentication's built-in email verification link. Users can browse without
signing in; the app routes the checkout UI only for authenticated,
email-verified accounts. Verification emails are sent directly by Firebase
Authentication, so this flow does not require Cloud Functions, Gmail SMTP
credentials, or the pay-as-you-go Firebase plan. This is not a server-side
order authorization by itself; the `createOrder` Cloud Function also checks
authentication and email verification before saving a real order.

### Configure Phase 2

1. In Firebase Console, enable **Authentication → Email/Password**. Firebase
   sends the built-in verification link to the address used to register. Check
   Firebase Authentication's email templates to customize the message.
2. Configure the missing iOS app options and refresh generated FlutterFire
   configuration (Android and Web are already present):

   ```bash
   flutterfire configure --project=foodpandas-f2e83 --platforms=android,ios,web
   ```

   Keep the generated `GoogleService-Info.plist` in the iOS Runner configuration
   as instructed by FlutterFire. Do not manually fabricate platform options.
3. Build and run from the project root:

   ```bash
   flutter pub get
   flutter run -d chrome
   ```

   To run the Flutter web release build, use `flutter build web --release`.
4. For iOS, finish the generated Firebase setup before running on an iOS device.
   The generated options currently do not include iOS, so `main()` will clearly
   fail initialization there until FlutterFire is configured.

The verification screen sends a link when first opened (and supports resending)
and lets the user refresh their Firebase Authentication status after opening
the link. No numeric code is used.

## Firebase database, restaurant coverage, and notifications

Firebase Authentication provides user identity and Cloud Firestore stores
customer profiles, verified restaurant/menu catalog, orders, notifications,
and device tokens. The `firestore.rules` file restricts customers to their own
profiles, orders, notifications, and device tokens. Orders are created and
priced by the trusted Firebase Cloud Function; the client cannot create or
change order records. Customer GPS coordinates are not requested or saved;
delivery addresses are entered manually.

The in-app Notifications page and **My orders** use Firestore live snapshots.
The `notifyOrderUpdate` Cloud Function creates an in-app notification and sends
push notifications when an order's payment or delivery status changes.

The original built-in stalls and menus are preview content. Their checkout
flow remains available to demonstrate the UI, but it is explicitly labeled
and never creates a Firebase order or notifies a restaurant. Only a branch
loaded from the verified Firebase restaurant catalog is saved as a real order.
Checkout opens an order-details dialog; for saved orders it shows the Firestore
order and live payment/status details. **My orders** lists those saved orders.
If it is empty, sample preview checkouts are not included.

The Restaurants page reads verified, active `restaurants` documents without
requesting the customer's GPS location. Customers enter a delivery address at
checkout. Each branch must include its official address, coordinates, menu and
current prices, verification source, delivery radius, and verified
`deliveryAreas`. Do not mark a branch verified until those details have been
checked with the restaurant or its official ordering channel. Add actual
Jollibee, McDonald's, and local branch/menu records for the target city; this
repository does not invent branch availability or menu prices. No restaurant
will appear until verified documents have been added.

Orders are submitted through the `createOrder` callable Cloud Function. It
checks the authenticated, email-verified user, reloads each active verified
branch and menu item, validates the manually entered delivery address against
the branch's configured `deliveryAreas`, and computes prices and fees from
Firestore. Client writes to `orders` are denied by Firestore rules. Configure
verified neighborhood or service-area names in `deliveryAreas`; orders cannot
be placed for branches without configured service areas.

Restaurant document shape (create documents in the Firestore `restaurants`
collection using the Firebase Console or a trusted administrative script):

```json
{
  "name": "Jollibee",
  "branchName": "<verified branch name>",
  "address": "<verified delivery address>",
  "category": "Fast food",
  "imageUrl": "<approved image URL>",
  "latitude": 0,
  "longitude": 0,
  "deliveryRadiusKm": 0,
  "deliveryAreas": ["<verified service area>"],
  "deliveryFee": 0,
  "verified": false,
  "active": false,
  "verificationSource": "<official source and date>",
  "menu": [
    {
      "id": "<stable-item-id>",
      "name": "<official item name>",
      "description": "<menu description>",
      "category": "<food category>",
      "price": 0,
      "imageUrl": "<approved image URL>"
    }
  ]
}
```

Client writes to `restaurants` are denied by Firestore rules. The `verified`
and `active` fields must remain false until the branch and its service area
are confirmed. The address field remains editable at checkout if the customer
needs to change it. Branch coordinates remain part of the trusted catalog.

Create the Cloud Firestore database in the Firebase Console if it does not
already exist, then deploy the included access rules and indexes from the
project root:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project foodpandas-f2e83
```

### Configure Firebase

1. Install the required Flutter packages and configure the missing iOS Firebase
   app using the project owner account:

   ```powershell
   flutter pub get
   flutterfire configure --project=foodpandas-f2e83 --platforms=android,ios,web
   ```

   `lib/firebase_options.dart` currently has Android and Web entries only.
   The command must register the real iOS bundle ID and generate its options;
   do not fabricate an iOS app ID or `GoogleService-Info.plist`. Until then the
   app shows a "could not start" screen on iOS instead of crashing.

2. In Xcode, enable the Runner target's **Push Notifications** capability and
   **Background Modes → Remote notifications**. In Firebase Console, enable
   Cloud Messaging and upload an APNs authentication key for iOS. For web push,
   create a Web Push certificate and provide its
   public VAPID key when building/running the web app:

   ```powershell
   flutter run -d chrome --dart-define=FCM_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
   flutter build web --release --dart-define=FCM_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
   ```

   Web push requires an HTTPS origin and the included
   `web/firebase-messaging-sw.js` service worker. Without push permission or
   platform credentials, in-app Firebase notifications remain available.

3. Install Firebase CLI, sign in, and deploy the Cloud Functions:

   Before deploying Functions, configure the Firebase, Xendit and AI settings in
   the sections below. Use a project-specific ignored `.env.foodpandas-f2e83`
   file or the Firebase CLI prompt for any configured Firebase function values
   (`AI_MODEL`, `AI_DAILY_REQUEST_LIMIT`, `ENFORCE_APP_CHECK`; press Enter to
   accept the defaults).

   ```powershell
   firebase login
   cd functions
   npm install
   cd ..
   firebase deploy --only functions --project foodpandas-f2e83
   ```

   Cloud Functions deployment requires the Firebase project to use the Blaze
   plan. Functions run on Node.js 24 and are capped at 10 instances each
   (`setGlobalOptions` in `functions/index.js`); raise the cap deliberately
   before launches. Order-status updates are made by a trusted restaurant/admin backend
   using `placed`, `preparing`, `ready_for_pickup`, `out_for_delivery`,
   `delivered`, or `cancelled`; e-wallet orders also use `pending_payment`
   until payment completes. Payment statuses are `pending`, `paid`, `failed`,
   or `refunded`; e-wallet status is updated by the verified Xendit webhook.

### Xendit online checkout

Verified restaurant checkout supports cash on delivery, Xendit e-wallets,
credit/debit cards, and an **All available online methods** option. E-wallet
checkout restricts Xendit's hosted invoice to GCash and GrabPay.
Credit/debit card and **All available online methods** checkout leave Xendit's
`payment_methods` filter unset so the hosted invoice offers the corresponding
channels enabled for the merchant account.
Sample/demo orders remain non-fulfillable. E-wallet is available for sample
checkout only with a Xendit development secret key; the server prices those
items from its own fixed demo catalog, saves a `DEMO-` order for webhook status,
and opens Xendit's sandbox checkout. The server rejects demo payments if a
production key is configured. Card and all-method checkout remain disabled for
sample items. The Xendit secret key is used only by the `createOrder` Cloud
Function; never put it in Flutter code, app build arguments, or source control.

For E-wallet checkout, select **E-wallet** and tap **Place my order**. The
server creates an invoice for that order and the app opens its hosted Xendit
checkout page (in the current browser tab on web to avoid popup blocking).
The `xnd_public_...` key is a client-side publishable key and cannot authorize
server-side invoice creation; configure the Xendit secret key using the
Firebase Functions secret command below instead.

1. Enable the payment channels you want in the Xendit dashboard and use a test
   key while validating in the Xendit test environment. Enable GCash and/or
   GrabPay for the e-wallet checkout option. Xendit presents the enabled wallet
   choices on the hosted invoice after the customer places an e-wallet order.
2. Set both Firebase function secrets from the project root. Firebase CLI will
   prompt for each value; use the callback verification token from the Xendit
   dashboard:

   ```powershell
   firebase functions:secrets:set XENDIT_SECRET_KEY --project foodpandas-f2e83
   firebase functions:secrets:set XENDIT_CALLBACK_TOKEN --project foodpandas-f2e83
   firebase deploy --only functions --project foodpandas-f2e83
   ```

3. Copy the deployed `xenditWebhook` HTTPS URL from the Firebase CLI output into
   Xendit's invoice callback/webhook configuration. Configure the callback
   verification token there to match `XENDIT_CALLBACK_TOKEN`.
4. At verified-restaurant checkout, choose **E-wallet**, **Credit or debit
   card**, or **All available online methods**. The server computes the total
   from the verified restaurant catalog and saves the full order to Firestore
   before requesting the invoice. At sample checkout, choose **E-wallet** to
   open a sandbox invoice priced from the server-side demo catalog; it is not a
   real order and no restaurant will fulfill it. The server rejects sample
   payments unless `XENDIT_SECRET_KEY` is a development key. On successful
   invoice creation, the Xendit invoice ID and payment link are saved onto the
   order. **Continue to payment** opens hosted checkout from order details or
   order history. The order remains pending until the webhook's token, invoice
   ID, order ID, currency, and amount are verified. If invoice creation fails,
   the saved order is marked failed/cancelled and the callable returns its
   order number so it remains visible in **My orders**. Xendit `FAILED` or
   `EXPIRED` callbacks also mark payment failed and cancel the unpaid order.
   The customer receives a notification when payment or delivery status
   changes. Do not manually set an online order to paid.

Use separate test and live credentials, and do not enable live payments until
the merchant account and callback configuration have been verified.

5. Run the widget tests and build the supported targets after configuring the
   SDKs and keys:

   ```powershell
   flutter test
   flutter build apk --release
   flutter build web --release --dart-define=FCM_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
   ```

   Build iOS on macOS after running `flutterfire configure` and installing the
   Apple signing/APNs setup.

Customer profile details are stored in each customer's Firestore
`users/{userId}` document. The profile screen loads and saves email, display
name, mobile number, delivery address, and the last update timestamp. Firestore
rules limit customers to their own profile. Real orders and online payments
require verified Firebase restaurant records and deployed, configured Firebase
Functions. Rider tracking still requires production setup; do not enable live
payments until the merchant and all backend configuration have been verified.

## AI food assistant

The **Ask AI** page lets signed-in, email-verified customers describe a craving
("something sour and soupy under ₱200") and get dishes they can add to the
cart. It is the first AI feature and sets the pattern for later ones:

- **Server-side only.** The Flutter app calls the `menuAssistant` callable;
  the Gemini API key never reaches the client. The function runs a
  [Genkit](https://genkit.dev) flow (`functions/ai/menu-assistant.js`) with the
  Gemini Developer API.
- **Grounded output.** The model only sees the verified Firestore catalog plus
  the sample menu, must answer with a typed schema, and every suggestion is
  checked against the catalog. Unknown items are dropped and names/prices
  always come from the catalog, never from the model. Sample items are
  labeled in the UI.
- **Guardrails.** Input is length-limited and stripped of prompt delimiters,
  the system prompt treats the request as untrusted, each user gets
  `AI_DAILY_REQUEST_LIMIT` requests per UTC day (counted in the server-only
  `aiUsage` collection), and the function honors `ENFORCE_APP_CHECK`.
- **Observability.** Every call logs model, prompt version, latency, proposed
  vs. grounded suggestion counts and token usage to Cloud Logging.
- **Evaluation.** `functions/ai/evals/menu-assistant.dataset.json` holds golden
  queries (including off-menu and prompt-injection cases). Run them against the
  live model before changing the prompt or model, and bump `PROMPT_VERSION`
  when the prompt changes.

Setup:

```shell
# Create a key in Google AI Studio, then store it as a Functions secret.
firebase functions:secrets:set GEMINI_API_KEY --project foodpandas-f2e83
firebase deploy --only functions:menuAssistant --project foodpandas-f2e83
```

`AI_MODEL` defaults to the stable `gemini-3.6-flash`. Pin stable model IDs and
check the [Gemini deprecation schedule](https://ai.google.dev/gemini-api/docs/deprecations)
before a model is retired. Local development:

```shell
cd functions
npm test                          # unit tests with a fake model, no network
GEMINI_API_KEY=... npm run eval:ai  # live-model eval (optionally -- --model <id>)
```

## Production operations

### Build-time settings

Pass these with `--dart-define` (or `--dart-define-from-file`):

| Setting | Purpose |
| --- | --- |
| `FCM_VAPID_KEY` | Web Push certificate key for web notifications |
| `ENABLE_APP_CHECK=true` | Activates Firebase App Check (Play Integrity, App Attest, reCAPTCHA Enterprise) |
| `APP_CHECK_WEB_RECAPTCHA_SITE_KEY` | reCAPTCHA Enterprise site key for App Check on the web |
| `USE_FIREBASE_EMULATORS=true` | Uses the local Auth/Firestore/Functions emulators |
| `FIREBASE_EMULATOR_HOST` | Emulator host (`10.0.2.2` from the Android emulator) |

### App Check rollout

1. Register Play Integrity (Android), App Attest/DeviceCheck (iOS) and a
   reCAPTCHA Enterprise key (web) under **App Check** in the Firebase console.
2. Ship builds with `--dart-define=ENABLE_APP_CHECK=true` (plus the web site
   key) and watch the App Check request metrics.
3. Once most traffic is verified, set `ENFORCE_APP_CHECK=true` for the
   Functions and redeploy; `createOrder` and `menuAssistant` then reject
   unverified clients.

### Crash reporting

Firebase Crashlytics records uncaught Flutter and platform errors on Android,
iOS and macOS release builds (collection is off in debug builds). Startup
failures, such as a platform without Firebase options, show an explanatory
screen instead of a blank app.

### Android release

- **Application ID.** `com.example.myapp` cannot be published on Google Play.
  Choose the final ID, register it as a new Android app in Firebase, replace
  `android/app/google-services.json`, and update `applicationId`/`namespace`
  in `android/app/build.gradle.kts`.
- **Signing.** Create an upload keystore and the git-ignored
  `android/key.properties`:

  ```properties
  storePassword=<store password>
  keyPassword=<key password>
  keyAlias=upload
  storeFile=/absolute/path/to/upload-keystore.jks
  ```

  Without it, release builds fall back to debug signing (fine for local
  testing, rejected by Google Play).

### Web hosting

`firebase.json` serves `build/web` from Firebase Hosting with an SPA rewrite,
security headers and no-cache headers for the app shell, so new releases load
immediately:

```shell
flutter build web --release --dart-define=FCM_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
firebase deploy --only hosting --project foodpandas-f2e83
```

### Local emulators

```shell
firebase emulators:start --only auth,firestore,functions
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true
```
