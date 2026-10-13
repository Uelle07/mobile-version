import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDw9e9ujAj9XmBjx1reZ41yPZxseVhLcto",
    appId: "1:532150151046:web:ebe42232a75bf375162e07",
    messagingSenderId: "532150151046",
    projectId: "activity-8-advance-web",
    storageBucket: "activity-8-advance-web.firebasestorage.app",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAw0yLAy2x5W6e2vbMf5q8e6cvbgPq3rSs",
    appId: "1:532150151046:android:09c107f33d1a5703162e07",
    messagingSenderId: "532150151046",
    projectId: "activity-8-advance-web",
    storageBucket: "activity-8-advance-web.firebasestorage.app",
  );
}

