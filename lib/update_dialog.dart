import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog {
  static const String playStoreUrl =
      "https://play.google.com/store/apps/details?id=com.nfl.livescore";

  /// Checks for a new version on the Play Store and shows dialog if needed
  static Future<void> checkForUpdate(BuildContext context) async {
    final newVersion = NewVersionPlus(
      androidId: "com.nfl.livescore", // 👈 Must match your appId in Play Console
    );

    try {
      final status = await newVersion.getVersionStatus();
      if (status != null && status.canUpdate) {
        // ✅ Show dialog only if a newer version is available
        _showUpdateDialog(context);
      }
    } catch (e) {
      debugPrint("⚠️ Version check failed: $e");
    }
  }

  /// Internal method to show the update dialog
  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // user must choose
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Text(
                  "Update Available",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "A newer version of this app is available. Please update to enjoy the latest features.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final Uri url = Uri.parse(playStoreUrl);
                        if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          throw Exception('Could not launch $url');
                        }
                      },
                      child: const Text("Update Now"),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Later"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
