import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class AppUpdater {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentBuildNumber = int.parse(packageInfo.buildNumber);

      debugPrint("Current Build Number: $currentBuildNumber");

      DocumentSnapshot configDoc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_info')
          .get();

      if (!configDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Update Error: version_info document not found in Firestore!')),
          );
        }
        return;
      }

      final data = configDoc.data() as Map<String, dynamic>;
      
      // Parse numbers safely whether double or int
      int latestBuildNumber = (data['latestBuildNumber'] as num?)?.toInt() ?? 1;
      String latestVersionName = data['latestVersion'] ?? '1.0.0';
      String apkUrl = data['apkUrl'] ?? '';
      bool forceUpdate = data['forceUpdate'] ?? false;
      String releaseNotes = data['releaseNotes'] ?? 'Nayi features ke sath naya update aagaya hai!';

      debugPrint("Latest Build in Firestore: $latestBuildNumber");

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
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('App Up-To-Date! Installed: $currentBuildNumber, Server: $latestBuildNumber')),
          );
        }
      }
    } catch (e) {
      debugPrint("Update Check Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update Fetch Error: $e')),
        );
      }
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String latestVersion,
    String releaseNotes,
    String apkUrl,
    bool forceUpdate,
  ) {
    ValueNotifier<String> downloadProgress = ValueNotifier('0%');
    ValueNotifier<bool> isDownloading = ValueNotifier(false);

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
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(releaseNotes, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 15),
                    ValueListenableBuilder<bool>(
                      valueListenable: isDownloading,
                      builder: (context, downloading, _) {
                        if (!downloading) return const SizedBox();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Downloading Update...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ValueListenableBuilder<String>(
                              valueListenable: downloadProgress,
                              builder: (context, progress, _) {
                                double value = (double.tryParse(progress.replaceAll('%', '')) ?? 0) / 100;
                                return Column(
                                  children: [
                                    LinearProgressIndicator(value: value, backgroundColor: Colors.grey.shade300, color: const Color(0xFF1A237E)),
                                    const SizedBox(height: 4),
                                    Align(alignment: Alignment.centerRight, child: Text(progress, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later', style: TextStyle(color: Colors.grey)),
                ),
              ValueListenableBuilder<bool>(
                valueListenable: isDownloading,
                builder: (context, downloading, _) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                    onPressed: downloading
                        ? null
                        : () {
                            isDownloading.value = true;
                            _startOtaUpdate(apkUrl, downloadProgress, context);
                          },
                    child: Text(downloading ? 'Downloading...' : 'Update Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void _startOtaUpdate(String url, ValueNotifier<String> progressNotifier, BuildContext context) {
    try {
      OtaUpdate().execute(url, destinationFilename: 'app_update.apk').listen(
        (OtaEvent event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              progressNotifier.value = '${event.value}%';
              break;
            case OtaStatus.INSTALLING:
              debugPrint("Installing APK...");
              break;
            default:
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Update status: ${event.status}')),
                );
              }
              break;
          }
        },
      );
    } catch (e) {
      debugPrint("OTA Update Exception: $e");
    }
  }
}
