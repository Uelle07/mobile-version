import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // We only support Android/iOS/Web for this basic setup
    return const FirebaseOptions(
      apiKey: "AIzaSyDw9e9ujAj9XmBjx1reZ41yPZxseVhLcto",
      appId: "1:532150151046:web:ebe42232a75bf375162e07", // Using the web app ID for now
      messagingSenderId: "532150151046",
      projectId: "activity-8-advance-web",
      storageBucket: "activity-8-advance-web.firebasestorage.app",
    );
  }
}
