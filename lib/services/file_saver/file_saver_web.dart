import 'dart:js_interop';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web implementation for saving/downloading exported files.
Future<String?> saveFileToDisk({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  try {
    final result = await FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: bytes,
    );
    if (result != null) return result;
  } catch (e) {
    debugPrint('FilePicker.saveFile on web had issue, using direct blob download: $e');
  }

  try {
    final jsBytes = bytes.toJS;
    final blobParts = [jsBytes].toJS;
    final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
    return fileName;
  } catch (e) {
    debugPrint('Direct blob download failed: $e');
    return null;
  }
}
