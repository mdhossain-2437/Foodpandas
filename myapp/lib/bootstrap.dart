import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'firebase_options.dart';

/// Initializes Firebase and the services the app depends on in production.
Future<void> initializeFirebaseServices() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _installCrashReporting();
  await _activateAppCheck();
  if (AppConfig.useFirebaseEmulators) await _connectToEmulators();
}

bool get _crashlyticsSupported =>
    !kIsWeb &&
    switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };

void _installCrashReporting() {
  if (!_crashlyticsSupported) return;
  final crashlytics = FirebaseCrashlytics.instance;
  unawaited(crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode));
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(crashlytics.recordError(error, stack, fatal: true));
    return true;
  };
}

Future<void> _activateAppCheck() async {
  if (!AppConfig.enableAppCheck) return;
  final siteKey = AppConfig.appCheckWebRecaptchaSiteKey;
  if (kIsWeb && siteKey.isEmpty) {
    debugPrint(
      'ENABLE_APP_CHECK is set but APP_CHECK_WEB_RECAPTCHA_SITE_KEY is empty; '
      'App Check stays inactive on the web.',
    );
    return;
  }
  await FirebaseAppCheck.instance.activate(
    providerWeb: kIsWeb ? ReCaptchaEnterpriseProvider(siteKey) : null,
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
}

Future<void> _connectToEmulators() async {
  final host = AppConfig.firebaseEmulatorHost;
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

/// Shown instead of the app when Firebase cannot start (for example on a
/// platform without generated Firebase options).
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Food-Pandas',
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              key: const Key('startup-error'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Food-Pandas could not start',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check your connection and reopen the app. If this keeps '
                  'happening, this device may not be supported yet.',
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  SelectableText('$error', textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
