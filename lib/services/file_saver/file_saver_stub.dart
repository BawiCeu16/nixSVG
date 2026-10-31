import 'dart:typed_data';

/// Stub implementation for non-web and non-io environments.
Future<String?> saveFileToDisk({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('Saving files is not supported on this platform.');
}
