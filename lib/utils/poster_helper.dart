import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PosterHelper {
  static Future<void> shareGroupPoster(GlobalKey globalKey, String groupCode, String groupName) async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/group_challenge.png').create();
      await file.writeAsBytes(pngBytes);

      String appDownloadUrl = "https://play.google.com/store/apps/details?id=com.competeme.app";

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "🔥 Join my Study Circle '$groupName' on CompeteMe!\n"
              "🔑 Group Code: $groupCode\n\n"
              "📲 Download CompeteMe App to compete live in Mock Tests: $appDownloadUrl",
      );
    } catch (e) {
      debugPrint("Poster share error: $e");
    }
  }
}
