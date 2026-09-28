import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdater {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentBuildNumber = int.parse(packageInfo.buildNumber);

      DocumentSnapshot configDoc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_info')
          .get();

      if (!configDoc.exists) return;

      final data = configDoc.data() as Map<String, dynamic>;
      
      int latestBuildNumber = (data['latestBuildNumber'] as num?)?.toInt() ?? 1;
      String latestVersionName = data['latestVersion'] ?? '1.0.0';
      String apkUrl = data['apkUrl'] ?? '';
      bool forceUpdate = data['forceUpdate'] ?? false;
      String releaseNotes = data['releaseNotes'] ?? 'Nayi features ke sath naya update aagaya hai!';

      if (latestBuildNumber > currentBuildNumber && apkUrl.isNotEmpty) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            latestVersionName,
            releaseNotes,
            apkUrl,
            forceUpdate,
          );
        }
      }
    } catch (e) {
      debugPrint("Update Check Error: $e");
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String latestVersion,
    String releaseNotes,
    String apkUrl,
    bool forceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.system_update, color: Color(0xFF1A237E)),
                const SizedBox(width: 10),
                Text('Update Available v$latestVersion', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(releaseNotes, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later', style: TextStyle(color: Colors.grey)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                onPressed: () async {
                  final Uri url = Uri.parse(apkUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
