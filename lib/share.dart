import 'package:share_plus/share_plus.dart';

class ShareApp {
  static void shareApp() {
    const String appUrl =
        "https://play.google.com/store/apps/details?id=com.nfl.livescore"; // ✅ Replace with your Play Store link
    const String message =
        "🏈 Check out this awesome NFL League app for live scores, highlights, and more!\n\nDownload here: $appUrl";
    Share.share(message, subject: "NFL League App");
  }
}
