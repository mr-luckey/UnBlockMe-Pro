import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for Android (from `android/app/google-services.json`).
///
/// iOS requires `GoogleService-Info.plist` from the Firebase console — not
/// present in this repo yet. Analytics initializes on Android only until then.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Add GoogleService-Info.plist and regenerate firebase_options.dart.',
        );
      default:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVGX7b2oKcslIe714HogD16FMVY5teGOI',
    appId: '1:628387371691:android:ead88883407095178075ee',
    messagingSenderId: '628387371691',
    projectId: 'unblocked-me-pro',
    storageBucket: 'unblocked-me-pro.firebasestorage.app',
  );
}
