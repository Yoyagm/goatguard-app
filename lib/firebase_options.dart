import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Generated Firebase configuration from google-services.json.
/// Project: goatguard-779bb
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for ${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcHdg_L5wKb8dojDkUhSyqq6WFbyDQTHo',
    appId: '1:617920868765:android:445a7250f157fee0adff74',
    messagingSenderId: '617920868765',
    projectId: 'goatguard-779bb',
    storageBucket: 'goatguard-779bb.firebasestorage.app',
  );
}
