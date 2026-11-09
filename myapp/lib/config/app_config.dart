/// Build-time configuration supplied with `--dart-define` or
/// `--dart-define-from-file`. Every value has a production-safe default.
abstract final class AppConfig {
  /// Routes Auth, Firestore and Functions to the local Firebase Emulator Suite.
  static const useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
  );

  /// Emulator host; use `10.0.2.2` for the Android emulator.
  static const firebaseEmulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  /// Activates Firebase App Check. Register the app's attestation providers in
  /// the Firebase console first, then enforce on the server.
  static const enableAppCheck = bool.fromEnvironment('ENABLE_APP_CHECK');

  /// reCAPTCHA Enterprise site key used by App Check on the web.
  static const appCheckWebRecaptchaSiteKey = String.fromEnvironment(
    'APP_CHECK_WEB_RECAPTCHA_SITE_KEY',
  );

  /// Web Push certificate (VAPID) key for Firebase Cloud Messaging on the web.
  static const fcmVapidKey = String.fromEnvironment('FCM_VAPID_KEY');
}
