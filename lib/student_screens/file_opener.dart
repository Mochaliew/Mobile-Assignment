import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class FileOpener {
  static const _channel = MethodChannel('asgnmnt/file_opener');

  static String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.mkv')) return 'video/x-matroska';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  static Future<void> open(File file) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('openFile', {
        'path': file.path,
        'mimeType': _mimeType(file.path),
      });
      return;
    }

    await Share.shareXFiles([XFile(file.path)]);
  }

  static Future<List<String>> renderPdfPages(File file) async {
    if (!Platform.isAndroid) return [];

    final pages = await _channel.invokeMethod<List<Object?>>('renderPdf', {
      'path': file.path,
    });
    return pages?.whereType<String>().toList() ?? [];
  }
}
